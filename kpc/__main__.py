"""kpc - turn Markdown into a KDP print-ready PDF.

Runs inside the pandoc/typst Docker image. Two subcommands:

    kpc build  [bookdir] [--pages N] [--keep]
    kpc import <file.docx> [bookdir] [--no-split] [--force]
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

TEMPLATES = Path(os.environ.get("KPC_TEMPLATES", "/opt/templates"))

MAIN_TYP = '''#import "book.typ": book
#import "_meta.typ": meta
#show: book.with(meta)
#include "_body.typ"
'''


def die(msg):
    print(f"kpc: error: {msg}", file=sys.stderr)
    raise SystemExit(1)


def run(cmd, **kw):
    print("· " + " ".join(str(c) for c in cmd), file=sys.stderr)
    subprocess.run(cmd, check=True, **kw)


def typst_str(s):
    """Quote/escape a Python value as a Typst string literal."""
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


# --------------------------------------------------------------------- config

def load_config(path):
    if not path.exists():
        die(f"no book.yaml found at {path}")
    return yaml.safe_load(path.read_text()) or {}


def parse_trim(cfg):
    trim = cfg.get("trim", "6x9")
    if isinstance(trim, dict):
        return float(trim["width"]), float(trim["height"])
    m = re.fullmatch(r"\s*([\d.]+)\s*[xX×]\s*([\d.]+)\s*", str(trim))
    if not m:
        die(f"cannot parse trim {trim!r}; use e.g. '6x9' or a width/height mapping")
    return float(m.group(1)), float(m.group(2))


# KDP minimum inside (gutter) margin, by interior page count.
_KDP_GUTTER = [(150, 0.375), (300, 0.5), (500, 0.625), (700, 0.75)]


def default_inside_margin(pages):
    if pages is None:
        return 0.875  # comfortable; safe up to ~500 pages
    for limit, gutter in _KDP_GUTTER:
        if pages <= limit:
            return round(gutter + 0.125, 3)  # breathing room over KDP minimum
    return 0.875


def resolve_margins(cfg, pages):
    m = cfg.get("margins") or {}
    return (
        m.get("inside", default_inside_margin(pages)),
        m.get("outside", 0.625),
        m.get("top", 0.75),
        m.get("bottom", 0.75),
    )


def authors_list(cfg):
    a = cfg.get("author", cfg.get("authors"))
    if a is None:
        return []
    return [a] if isinstance(a, str) else list(a)


def typst_array(items):
    if not items:
        return "()"
    inner = ", ".join(typst_str(i) for i in items)
    return f"({inner},)" if len(items) == 1 else f"({inner})"


def render_meta(cfg, pages):
    w, h = parse_trim(cfg)
    inside, outside, top, bottom = resolve_margins(cfg, pages)

    def opt(key):
        v = cfg.get(key)
        return typst_str(v) if v not in (None, "") else "none"

    font_size = cfg.get("font-size", "11pt")
    if isinstance(font_size, (int, float)):
        font_size = f"{font_size}pt"

    return (
        "#let meta = (\n"
        f"  title: {typst_str(cfg.get('title', 'Untitled'))},\n"
        f"  subtitle: {opt('subtitle')},\n"
        f"  authors: {typst_array(authors_list(cfg))},\n"
        f"  publisher: {opt('publisher')},\n"
        f"  rights: {opt('rights')},\n"
        f"  isbn: {opt('isbn')},\n"
        f"  language: {typst_str(cfg.get('language', 'en'))},\n"
        f"  trim: (width: {w}in, height: {h}in),\n"
        f"  margins: (inside: {inside}in, outside: {outside}in, "
        f"top: {top}in, bottom: {bottom}in),\n"
        f"  font: {typst_str(cfg.get('font', 'Libertinus Serif'))},\n"
        f"  font-size: {font_size},\n"
        f"  toc: {str(bool(cfg.get('toc', True))).lower()},\n"
        ")\n"
    )


def _natural_key(path):
    """Sort key so e.g. chapter2.md sorts before chapter10.md."""
    return [int(t) if t.isdigit() else t.lower()
            for t in re.split(r"(\d+)", path.name)]


def resolve_chapters(bookdir, cfg):
    listed = cfg.get("chapters")
    if listed:
        files = [bookdir / c for c in listed]
        missing = [str(f) for f in files if not f.exists()]
        if missing:
            die("chapter(s) listed in book.yaml not found: " + ", ".join(missing))
        return files
    chdir = bookdir / "chapters"
    if not chdir.is_dir():
        die(f"no chapters/ directory and no 'chapters:' list in book.yaml ({bookdir})")
    # No explicit list -> include every chapters/*.md, in natural filename order.
    return sorted(chdir.glob("*.md"), key=_natural_key)


# ---------------------------------------------------------------------- build

def build(bookdir, pages=None, keep=False):
    bookdir = bookdir.resolve()
    cfg = load_config(bookdir / "book.yaml")
    chapters = resolve_chapters(bookdir, cfg)
    if not chapters:
        die("no chapter .md files found")
    out = bookdir / "out"
    out.mkdir(exist_ok=True)

    shutil.copy(TEMPLATES / "book.typ", out / "book.typ")
    (out / "_meta.typ").write_text(render_meta(cfg, pages))
    run(["pandoc", *[str(c) for c in chapters],
         "-f", "markdown", "-t", "typst", "--wrap=preserve",
         "-o", str(out / "_body.typ")])
    (out / "main.typ").write_text(MAIN_TYP)

    pdf = out / "interior.pdf"
    run(["typst", "compile", "--root", str(bookdir),
         str(out / "main.typ"), str(pdf)])

    if not keep:
        for f in ("book.typ", "_meta.typ", "_body.typ", "main.typ"):
            (out / f).unlink(missing_ok=True)
    print(f"✓ wrote {pdf}")


# --------------------------------------------------------------------- import

_IMG_RE = re.compile(r"(!\[[^\]]*\]\()([^)\s]+)")
_FENCE_RE = re.compile(r"^(`{3,}|~{3,})")
_H1_RE = re.compile(r"^#[ \t]+(.+?)\s*$")


def _rebase_images(text):
    """Make relative image links resolve from chapters/ (one level deeper)."""
    def repl(m):
        pre, path = m.group(1), m.group(2)
        if path.startswith(("/", "http://", "https://", "data:", "../")):
            return m.group(0)
        return pre + "../" + path
    return _IMG_RE.sub(repl, text)


# A markdown image, with an optional trailing {attribute} block.
_IMG_TOKEN = r"!\[[^\]]*\]\([^)]*\)(?:\{[^}]*\})?"


def _split_heading_images(s):
    """Return (heading text without images, [image tokens]) for a heading.

    Microsoft Word can only position an image by embedding it in the Heading 1
    paragraph, so on import we lift any such image out to a figure just below the
    heading. That keeps the chapter filename clean and lets the image typeset
    properly instead of being crammed into the heading line.
    """
    imgs = re.findall(_IMG_TOKEN, s)
    text = re.sub(r"\s+", " ", re.sub(_IMG_TOKEN, "", s)).strip()
    return text, imgs


def split_chapters(text):
    """Split markdown into (title, lines) chunks on each level-1 heading.

    Fence-aware: a `#` inside a fenced code block is never a chapter break.
    Content before the first H1 becomes a (None, lines) chunk. An image embedded
    in a chapter heading (as Word produces) is lifted out to a figure just below
    the heading; a heading that is *only* an image is demoted to a plain figure
    rather than starting a new chapter.
    """
    in_fence = False
    chunks, title, cur = [], None, []
    for line in text.splitlines():
        if _FENCE_RE.match(line):
            in_fence = not in_fence
            cur.append(line)
            continue
        if not in_fence:
            m = _H1_RE.match(line)
            if m:
                heading, imgs = _split_heading_images(m.group(1))
                if heading:                        # real chapter (has title text)
                    if title is not None or any(s.strip() for s in cur):
                        chunks.append((title, cur))
                    title = heading
                    cur = ["# " + heading]
                    for img in imgs:               # lift in-heading images below
                        cur += ["", img]
                    continue
                for img in imgs:                   # image-only heading -> figure
                    cur += [img, ""]
                continue
        cur.append(line)
    if title is not None or any(s.strip() for s in cur):
        chunks.append((title, cur))
    return chunks


def slugify(s):
    s = re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")
    return s[:50] or "section"


def _flatten_media(media):
    """Pandoc extracts docx images to media/media/; collapse to a single media/."""
    nested = media / "media"
    if not nested.is_dir():
        return
    for f in nested.iterdir():
        dest = media / f.name
        if not dest.exists():
            shutil.move(str(f), str(dest))
    if not any(nested.iterdir()):
        nested.rmdir()


def import_docx(docx, bookdir, split=True, force=False):
    if not docx.exists():
        die(f"docx not found: {docx}")
    bookdir = bookdir.resolve()
    chapters_dir = bookdir / "chapters"
    chapters_dir.mkdir(parents=True, exist_ok=True)
    existing = list(chapters_dir.glob("*.md"))
    if existing and not force:
        die(f"{chapters_dir} already has {len(existing)} .md file(s); "
            "pass --force to overwrite")

    (bookdir / "out").mkdir(exist_ok=True)
    run(["pandoc", str(docx.resolve()),
         "-f", "docx", "-t", "markdown",
         "--wrap=none", "--markdown-headings=atx",
         "--track-changes=accept", "--extract-media=media",
         "-o", os.path.join("out", "_import.md")],
        cwd=str(bookdir))

    # Pandoc tucks docx images under media/media/; flatten to a single media/.
    _flatten_media(bookdir / "media")

    text = (bookdir / "out" / "_import.md").read_text().replace("media/media/", "media/")
    text = _rebase_images(text)
    chunks = split_chapters(text) if split else [(None, text.splitlines())]

    written, n = [], 0
    for title, lines in chunks:
        body = "\n".join(lines).strip() + "\n"
        if title is None:
            name = "00-frontmatter.md"
        else:
            n += 1
            name = f"{n:02d}-{slugify(title)}.md"
        (chapters_dir / name).write_text(body)
        written.append(name)

    (bookdir / "out" / "_import.md").unlink(missing_ok=True)

    media = bookdir / "media"
    n_media = sum(1 for p in media.rglob("*") if p.is_file()) if media.exists() else 0
    print(f"✓ wrote {len(written)} file(s) to {chapters_dir}:")
    for name in written:
        print(f"    {name}")
    if n_media:
        print(f"  extracted {n_media} image(s) to {media} "
              "- ensure ~300 DPI for KDP print")


# ------------------------------------------------------------------------ cli

def main(argv=None):
    p = argparse.ArgumentParser(prog="kpc",
                                description="Markdown -> KDP print-ready PDF")
    sub = p.add_subparsers(dest="cmd", required=True)

    b = sub.add_parser("build", help="build interior PDF from a book directory")
    b.add_argument("bookdir", nargs="?", default=".",
                   help="book directory (contains book.yaml, chapters/)")
    b.add_argument("--pages", type=int, default=None,
                   help="estimated page count, to pick a KDP-appropriate gutter")
    b.add_argument("--keep", action="store_true",
                   help="keep intermediate .typ files in out/")

    i = sub.add_parser("import", help="import a .docx into chapters/*.md")
    i.add_argument("docx", help="path to the .docx file")
    i.add_argument("bookdir", nargs="?", default=".", help="target book directory")
    i.add_argument("--no-split", dest="split", action="store_false",
                   help="write one markdown file instead of splitting on H1")
    i.add_argument("--force", action="store_true",
                   help="overwrite an existing non-empty chapters/ directory")

    args = p.parse_args(argv)
    if args.cmd == "build":
        build(Path(args.bookdir), pages=args.pages, keep=args.keep)
    else:
        import_docx(Path(args.docx), Path(args.bookdir),
                    split=args.split, force=args.force)


if __name__ == "__main__":
    main()
