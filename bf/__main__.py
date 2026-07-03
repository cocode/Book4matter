"""bf - turn Markdown into a KDP print-ready PDF or a KDP-ready EPUB.

Runs inside the pandoc/typst Docker image. Subcommands:

    bf print  [bookdir] [--pages N] [--keep]
    bf epub   [bookdir] [--no-check]
    bf html   [bookdir]                 (whole book as one HTML page)
    bf html toc [bookdir]               (just the contents, no links)
    bf html chapter NN [bookdir]        (one chapter as an HTML fragment)
    bf import <file.docx> [bookdir] [--no-split] [--force]
    bf impose <file.pdf> [--paper P] [--signature N] [--single] [-o NAME]
"""
import argparse
import base64
import mimetypes
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zlib
from datetime import date
from pathlib import Path

import yaml

TEMPLATES = Path(os.environ.get("BF_TEMPLATES", "/opt/templates"))

MAIN_TYP = '''#import "book.typ": book
#import "_meta.typ": meta
#show: book.with(meta)
#include "_body.typ"
'''

# Imports prepended to the generated _body.typ so raw typst blocks inside
# chapter markdown (e.g. `wrap-content(...)`) and blocks emitted by parts.lua
# (`#part-num.update(N)`, `#unnumbered-next.update(true)`) can find their
# bindings; typst's `#include` does not re-export the outer file's imports.
# book.typ is copied into out/ alongside _body.typ, so the relative import
# resolves.
BODY_PRELUDE = '''#import "@preview/wrap-it:0.1.1": wrap-content
#import "book.typ": part-num, unnumbered-next, section-next, part-text, part-text-next, runin
'''


def die(msg):
    print(f"bf: error: {msg}", file=sys.stderr)
    raise SystemExit(1)


def run(cmd, **kw):
    print("· " + " ".join(str(c) for c in cmd), file=sys.stderr)
    subprocess.run(cmd, check=True, **kw)


def filter_env(cfg):
    """Environment for the EPUB/HTML pandoc lua filters. Carries `part-label`
    (default "Part") via BF_PART_LABEL so epub-parts.lua's auto "Part N" labels
    match whatever the book calls its top-level division on the print divider."""
    return {**os.environ, "BF_PART_LABEL": str(cfg.get("part-label", "Part"))}


def typst_str(s):
    """Quote/escape a Python value as a Typst string literal.

    Newlines/tabs are escaped (not passed through literally) so a multi-line
    value -- e.g. a stacked `title: "The\\nRotary\\nWaltz"` the title page
    splits on "\\n" -- yields a single, valid Typst string literal."""
    s = (str(s).replace("\\", "\\\\").replace('"', '\\"')
         .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t"))
    return '"' + s + '"'


# --------------------------------------------------------------------- config

def load_config(bookdir):
    """Merge a book's config from book_style.yaml + book_metadata.yaml.

    The style/metadata split is by convention only -- both files are read and
    merged into one dict (metadata wins on the rare key collision). At least one
    of the two must exist."""
    cfg = {}
    found = False
    for name in ("book_style.yaml", "book_metadata.yaml"):
        f = bookdir / name
        if f.exists():
            cfg.update(yaml.safe_load(f.read_text()) or {})
            found = True
    if not found:
        die(f"no book_style.yaml or book_metadata.yaml in {bookdir}")
    return cfg


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


def _norm_asset(path):
    """Root-absolute typst path so image() resolves from the book root, not
    from out/ where the generated .typ files live."""
    p = str(path)
    return p if p.startswith("/") else "/" + p


def render_also_by(cfg):
    """Serialize the optional `also-by:` list into a Typst array of dicts.

    Each entry may set title (required), cover, qr, url; missing fields render
    as `none`. A bare string is treated as a title-only entry."""
    works = cfg.get("also-by") or []
    parts = []
    for w in works:
        if isinstance(w, str):
            w = {"title": w}

        def field(key, asset=False):
            v = w.get(key)
            if v in (None, ""):
                return "none"
            return typst_str(_norm_asset(v) if asset else v)

        parts.append(
            f"(title: {field('title')}, cover: {field('cover', True)}, "
            f"qr: {field('qr', True)}, url: {field('url')})"
        )
    return typst_array_raw(parts)


def typst_array_raw(items):
    """Wrap already-serialized Typst snippets as an array (trailing comma so a
    single-element array isn't read as a parenthesized group)."""
    if not items:
        return "()"
    return "(" + ", ".join(items) + ("," if len(items) == 1 else "") + ")"


def build_date_str(d=None):
    """The build date for the colophon, e.g. "25 June 2026".

    Worded month, no leading zero on the day -- reads as a date a person wrote,
    not a machine timestamp. We avoid strftime's %-d (not portable) and build
    the day from the int so there's no platform-dependent zero padding. %B is
    English under the container's C locale, matching the English colophon prose.
    """
    d = d or date.today()
    return f"{d.day} {d.strftime('%B %Y')}"


def render_meta(cfg, pages, build_id=None, links="print", cover=None):
    w, h = parse_trim(cfg)
    inside, outside, top, bottom = resolve_margins(cfg, pages)
    # Optional full-bleed cover page. `cover` is a book-relative path (or None);
    # _norm_asset makes it root-absolute so typst's image() resolves it from the
    # book root rather than out/. Only the digital `pdf` build passes one -- the
    # print interior omits it (KDP takes the cover as a separate upload).
    cover_typ = typst_str(_norm_asset(cover)) if cover else "none"

    def opt(key):
        v = cfg.get(key)
        return typst_str(v) if v not in (None, "") else "none"

    font_size = cfg.get("font-size", "11pt")
    if isinstance(font_size, (int, float)):
        font_size = f"{font_size}pt"

    indent = str(cfg.get("indent", "all")).lower()
    if indent not in ("all", "standard", "none"):
        die(f"indent must be 'all', 'standard', or 'none' (got {indent!r})")
    toc_depth = int(cfg.get("toc-depth", 2))
    chapter_style = str(cfg.get("chapter-style", "centered")).lower()
    if chapter_style not in ("left", "centered"):
        die(f"chapter-style must be 'left' or 'centered' (got {chapter_style!r})")
    part_style = str(cfg.get("part-style", "classic")).lower()
    if part_style not in ("classic", "fancy"):
        die(f"part-style must be 'classic' or 'fancy' (got {part_style!r})")
    part_label = str(cfg.get("part-label", "Part"))

    build_id_typ = typst_str(build_id) if build_id else "none"

    return (
        "#let meta = (\n"
        f"  title: {typst_str(cfg.get('title', 'Untitled'))},\n"
        f"  subtitle: {opt('subtitle')},\n"
        f"  title-rule: {str(bool(cfg.get('title-rule', False))).lower()},\n"
        f"  authors: {typst_array(authors_list(cfg))},\n"
        f"  publisher: {opt('publisher')},\n"
        f"  rights: {opt('rights')},\n"
        f"  isbn: {opt('isbn')},\n"
        f"  credits: {opt('credits')},\n"
        f"  language: {typst_str(cfg.get('language', 'en'))},\n"
        f"  trim: (width: {w}in, height: {h}in),\n"
        f"  margins: (inside: {inside}in, outside: {outside}in, "
        f"top: {top}in, bottom: {bottom}in),\n"
        f"  font: {typst_str(cfg.get('font', 'Libertinus Serif'))},\n"
        f"  heading-font: {typst_str(cfg.get('heading-font', 'Liberation Sans'))},\n"
        f"  font-size: {font_size},\n"
        f"  indent: {typst_str(indent)},\n"
        f"  toc: {str(bool(cfg.get('toc', True))).lower()},\n"
        f"  toc-depth: {toc_depth},\n"
        f"  running-heads: {str(bool(cfg.get('running-heads', False))).lower()},\n"
        f"  parts-recto: {str(bool(cfg.get('parts-recto', False))).lower()},\n"
        f"  chapters-recto: {str(bool(cfg.get('chapters-recto', False))).lower()},\n"
        f"  chapter-style: {typst_str(chapter_style)},\n"
        f"  part-style: {typst_str(part_style)},\n"
        f"  part-label: {typst_str(part_label)},\n"
        f"  also-by: {render_also_by(cfg)},\n"
        f"  build-id: {build_id_typ},\n"
        # The date this build was produced, worded ("25 June 2026") for the
        # colophon. Always stamped (unlike build-id, which the wrapper supplies).
        f"  build-date: {typst_str(build_date_str())},\n"
        # "live" keeps internal links (TOC/cross-refs) clickable for the digital
        # `pdf` target; "print" drops them so the KDP interior carries no link
        # annotations. book.typ's show-link rule reads this.
        f"  links: {typst_str(links)},\n"
        f"  cover: {cover_typ},\n"
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

def build_print(bookdir, pages=None, keep=False, build_id=None, links="print",
                include_cover=False):
    """Build a PDF from a book directory.

    links="print" (the `print` target) drops internal-link annotations so the
    interior is acceptable to KDP and other publishers that forbid hyperlinks.
    links="live" (the `pdf` target) keeps TOC and cross-reference links
    clickable for a digital PDF, and names the file without the "-interior"
    suffix so the two builds don't overwrite each other in out/.

    include_cover adds the book.yaml `cover:` image as a full-bleed first page.
    The digital `pdf` build sets it; the print interior leaves it off, since KDP
    takes the cover as a separate upload.
    """
    bookdir = bookdir.resolve()
    cfg = load_config(bookdir)
    chapters = resolve_chapters(bookdir, cfg)
    if not chapters:
        die("no chapter .md files found")
    out = bookdir / "out"
    out.mkdir(exist_ok=True)

    cover = cfg.get("cover") if include_cover else None
    if cover and not (bookdir / cover).resolve().exists():
        die(f"cover image not found: {(bookdir / cover).resolve()}")

    shutil.copy(TEMPLATES / "book.typ", out / "book.typ")
    (out / "_meta.typ").write_text(
        render_meta(cfg, pages, build_id=build_id, links=links, cover=cover))
    # parts.lua reads BF_PARTS_RECTO so it can break to the odd page before the
    # front-matter→arabic reset (see its Pandoc filter); an env var is the
    # simplest way to pass a config flag into a lua filter.
    env = {**os.environ, "BF_PARTS_RECTO": "1" if cfg.get("parts-recto") else "0"}
    run(["pandoc", *[str(c) for c in chapters],
         "-f", "markdown", "-t", "typst", "--wrap=preserve",
         # wrap.lua first so it packages its body before parts.lua starts
         # inserting raw `#pagebreak()` blocks between sibling headings; if
         # the order were reversed, a pagebreak would land inside a wrap
         # body and typst rejects pagebreaks inside content blocks.
         f"--lua-filter={TEMPLATES / 'wrap.lua'}",
         f"--lua-filter={TEMPLATES / 'parts.lua'}",
         "-o", str(out / "_body.typ")],
        env=env)
    body_path = out / "_body.typ"
    body_path.write_text(BODY_PRELUDE + body_path.read_text())
    (out / "main.typ").write_text(MAIN_TYP)

    # Name the PDF after the book so a multi-book setup doesn't end up with
    # several files all called interior.pdf. The print interior keeps the
    # "-interior" suffix to match KDP's convention (interior vs cover are
    # submitted separately); the digital `pdf` build uses the bare slug so it
    # sits beside the interior in out/ rather than overwriting it.
    title = cfg.get("title")
    slug = slugify(title) if title else bookdir.name
    suffix = "-interior" if links == "print" else ""
    pdf = out / f"{slug}{suffix}.pdf"
    # Optional per-book font directory. Drop .ttf/.otf files into
    # <bookdir>/fonts/ and reference the family name from book.yaml's `font:` /
    # `heading-font:` keys; typst resolves by family name from --font-path
    # entries plus the system. System fonts are still searched so the build
    # works even with no fonts/ dir.
    typst_cmd = ["typst", "compile", "--root", str(bookdir)]
    fonts_dir = bookdir / "fonts"
    if fonts_dir.is_dir():
        typst_cmd += ["--font-path", str(fonts_dir)]
    typst_cmd += [str(out / "main.typ"), str(pdf)]
    run(typst_cmd)

    if not keep:
        for f in ("book.typ", "_meta.typ", "_body.typ", "main.typ"):
            (out / f).unlink(missing_ok=True)
    print(f"✓ wrote {pdf}")


# ----------------------------------------------------------------------- epub

def _epub_metadata(cfg, build_id=None):
    """Translate book.yaml into the metadata pandoc's EPUB writer expects.

    Pandoc reads `title`, `subtitle`, `author` (string or list), `lang`,
    `publisher`, `rights`, `date`, `identifier`. Our book.yaml uses `language`
    and `year`, so we remap. Anything not set is omitted entirely so pandoc
    doesn't emit empty <dc:*> elements that epubcheck would warn about.
    """
    meta = {}
    # Flatten any title-page line breaks ("\n") -- they belong only on the
    # print title page, not in EPUB <dc:title> metadata.
    if cfg.get("title"):     meta["title"] = str(cfg["title"]).replace("\n", " ")
    if cfg.get("subtitle"):  meta["subtitle"] = cfg["subtitle"]
    authors = authors_list(cfg)
    if authors:              meta["author"] = authors
    if cfg.get("publisher"): meta["publisher"] = cfg["publisher"]
    rights = cfg.get("rights")
    if build_id:
        printing = f"Printing: {build_id}"
        rights = f"{rights} {printing}" if rights else printing
    if rights:               meta["rights"] = rights
    meta["lang"] = cfg.get("language", "en")
    if cfg.get("year"):      meta["date"] = str(cfg["year"])
    isbn = cfg.get("isbn")
    if isbn:
        # `scheme` puts the right onix:identifier-scheme on the <dc:identifier>;
        # without it readers just see an opaque string.
        meta["identifier"] = {"text": str(isbn), "scheme": "ISBN-13"}
    return meta


def build_epub(bookdir, check=True, build_id=None):
    bookdir = bookdir.resolve()
    cfg = load_config(bookdir)
    chapters = resolve_chapters(bookdir, cfg)
    if not chapters:
        die("no chapter .md files found")
    out = bookdir / "out"
    out.mkdir(exist_ok=True)

    meta_path = out / "_epub_meta.yaml"
    meta_path.write_text(yaml.safe_dump(_epub_metadata(cfg, build_id=build_id),
                                        sort_keys=False, allow_unicode=True))

    title = cfg.get("title")
    slug = slugify(title) if title else bookdir.name
    epub = out / f"{slug}.epub"

    cmd = ["pandoc", *[str(c) for c in chapters],
           "-f", "markdown", "-t", "epub3",
           "--wrap=preserve",
           # toc-depth from book_style.yaml (default 2 -> parts + chapters);
           # deeper headings stay in-document but don't clutter the nav.
           "--toc", f"--toc-depth={int(cfg.get('toc-depth', 2))}",
           # epub-wrap rewrites .wrap-right/.wrap-left images into <figure>s
           # with the class on the figure (CSS does the float). epub-parts
           # splits "Part I - Title" headings into two lines and strips
           # print-only heading classes that would otherwise leak into HTML.
           f"--lua-filter={TEMPLATES / 'epub-wrap.lua'}",
           f"--lua-filter={TEMPLATES / 'epub-parts.lua'}",
           f"--css={TEMPLATES / 'epub.css'}",
           f"--metadata-file={meta_path}",
           # Chapters live in bookdir/chapters/ and reference images as
           # ../media/x; resolved from the chapters dir that becomes
           # bookdir/media/x. Also list bookdir itself so absolute-from-root
           # paths and chapter files written at the book root both work.
           f"--resource-path={bookdir / 'chapters'}:{bookdir}",
           "-o", str(epub)]

    cover = cfg.get("cover")
    if cover:
        cover_path = (bookdir / cover).resolve()
        if not cover_path.exists():
            die(f"cover image not found: {cover_path}")
        cmd.insert(-2, f"--epub-cover-image={cover_path}")

    run(cmd, cwd=str(bookdir), env=filter_env(cfg))
    meta_path.unlink(missing_ok=True)

    if check:
        # epubcheck exits non-zero on errors; warnings still print but pass.
        # Run inside the same container so the host doesn't need Java.
        try:
            run(["epubcheck", str(epub)])
        except subprocess.CalledProcessError:
            die(f"epubcheck found errors in {epub}")
    print(f"✓ wrote {epub}")


# ------------------------------------------------------------------------ html

def _html_cmd(chapters, bookdir, *extra):
    """Shared pandoc invocation for the HTML outputs: markdown -> html5 over the
    given chapter files, with the same image resource paths the EPUB build uses
    (chapters reference ../media/x, resolved from the chapters dir)."""
    return ["pandoc", *[str(c) for c in chapters],
            "-f", "markdown", "-t", "html5", "--wrap=preserve",
            f"--resource-path={bookdir / 'chapters'}:{bookdir}",
            *extra]


def build_html(bookdir):
    """Whole book as one standalone HTML page with a clickable table of
    contents. Mirrors the EPUB pipeline (same wrap/parts filters and CSS) but
    targets html5; --section-divs gives every heading a section id so the --toc
    entries link to it. Resources are embedded so the file stands on its own."""
    bookdir = bookdir.resolve()
    cfg = load_config(bookdir)
    chapters = resolve_chapters(bookdir, cfg)
    if not chapters:
        die("no chapter .md files found")
    out = bookdir / "out"
    out.mkdir(exist_ok=True)

    title = cfg.get("title")
    slug = slugify(title) if title else bookdir.name
    html = out / f"{slug}.html"

    cmd = _html_cmd(chapters, bookdir,
                    "--standalone", "--section-divs",
                    "--toc", f"--toc-depth={int(cfg.get('toc-depth', 2))}",
                    f"--lua-filter={TEMPLATES / 'epub-wrap.lua'}",
                    f"--lua-filter={TEMPLATES / 'epub-parts.lua'}",
                    f"--css={TEMPLATES / 'epub.css'}", "--embed-resources",
                    "--metadata", f"title={title or slug}",
                    "--metadata", f"lang={cfg.get('language', 'en')}",
                    "-o", str(html))
    run(cmd, cwd=str(bookdir), env=filter_env(cfg))
    text = html.read_text()
    # Link an optional per-book stylesheet, added AFTER pandoc's embedded styles
    # so its rules win on the cascade. The file is optional: drop a book_style.css
    # next to the page (or have a build script copy one into out/) to theme the
    # site; leave it absent and the page falls back to the embedded epub.css.
    # (`html toc` / `html chapter` emit fragments with no <head>, so no link.)
    head_link = '  <link rel="stylesheet" href="book_style.css" />\n'
    text = text.replace("</head>", head_link + "</head>", 1)
    # Optional cover image as the first thing in the body. Embedded as a data URI
    # so the standalone page (--embed-resources) stays self-contained; centred
    # and height-capped so a tall cover doesn't dominate a wide screen.
    cover = cfg.get("cover")
    if cover:
        cover_path = (bookdir / cover).resolve()
        if not cover_path.exists():
            die(f"cover image not found: {cover_path}")
        mime = mimetypes.guess_type(str(cover_path))[0] or "image/jpeg"
        b64 = base64.b64encode(cover_path.read_bytes()).decode("ascii")
        img = ('<img class="cover" alt="Cover" '
               f'src="data:{mime};base64,{b64}" '
               'style="display:block;margin:1rem auto 2.5rem;'
               'max-width:min(100%,28rem);max-height:90vh;height:auto;" />\n')
        text = re.sub(r"(<body[^>]*>)", lambda m: m.group(1) + "\n" + img,
                      text, count=1)
    html.write_text(text)
    print(f"✓ wrote {html}")


def build_html_toc(bookdir):
    """Just the table of contents, as a link-free HTML fragment for embedding
    on a website (the in-book anchors point nowhere off-site, so toc-list.lua
    drops them). Level-1 headings sit at the top level with level-2 headings
    nested beneath -- the same depth the EPUB/print contents use."""
    bookdir = bookdir.resolve()
    cfg = load_config(bookdir)
    chapters = resolve_chapters(bookdir, cfg)
    if not chapters:
        die("no chapter .md files found")
    out = bookdir / "out"
    out.mkdir(exist_ok=True)

    title = cfg.get("title")
    slug = slugify(title) if title else bookdir.name
    toc = out / f"{slug}-toc.html"

    cmd = _html_cmd(chapters, bookdir,
                    f"--lua-filter={TEMPLATES / 'toc-list.lua'}",
                    "-o", str(toc))
    run(cmd, cwd=str(bookdir))
    print(f"✓ wrote {toc}")


def _pick_chapter(chapters, which):
    """Resolve a `html chapter NN` argument to one chapter file: match the
    leading number in the filename (010-foo.md -> 10), else a 1-based index into
    the chapter list, else an exact filename/stem match."""
    s = str(which).strip()
    if s.isdigit():
        n = int(s)
        for c in chapters:
            m = re.match(r"0*(\d+)", c.name)
            if m and int(m.group(1)) == n:
                return c
        if 1 <= n <= len(chapters):
            return chapters[n - 1]
    for c in chapters:
        if s in (c.name, c.stem):
            return c
    die(f"no chapter matches {which!r}; available: "
        + ", ".join(c.name for c in chapters))


def build_html_chapter(bookdir, which):
    """One chapter as an HTML fragment (no page chrome, no auto Part/Chapter
    label -- that numbering is meaningless out of context). Handy for pulling a
    single chapter into a web page."""
    bookdir = bookdir.resolve()
    cfg = load_config(bookdir)
    chapters = resolve_chapters(bookdir, cfg)
    if not chapters:
        die("no chapter .md files found")
    chapter = _pick_chapter(chapters, which)
    out = bookdir / "out"
    out.mkdir(exist_ok=True)
    html = out / f"{chapter.stem}.html"

    cmd = _html_cmd([chapter], bookdir,
                    "--section-divs",
                    f"--lua-filter={TEMPLATES / 'epub-wrap.lua'}",
                    "-o", str(html))
    run(cmd, cwd=str(bookdir))
    print(f"✓ wrote {html}")


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

    # Stage pandoc's markdown in a temp file (outside the book tree) rather than
    # out/, so importing only ever writes to chapters/ and media/ -- letting the
    # run.sh mount keep the rest of the book read-only. (--extract-media still
    # writes the docx's images into media/, where the build expects them.)
    #
    # `-t markdown-smart` (note the minus): the markdown writer enables the
    # `smart` extension by default, which backslash-escapes literal straight
    # quotes/apostrophes (Don\'t, \"quote\") and rewrites em dashes/ellipses as
    # ASCII (---, ...). Disabling it emits the author's punctuation verbatim as
    # Unicode, which is cleaner to hand-edit and round-trips through the build.
    fd, staging_name = tempfile.mkstemp(prefix="bf_import_", suffix=".md")
    os.close(fd)
    staging = Path(staging_name)
    run(["pandoc", str(docx.resolve()),
         "-f", "docx", "-t", "markdown-smart",
         "--wrap=none", "--markdown-headings=atx",
         "--track-changes=accept", "--extract-media=media",
         "-o", str(staging)],
        cwd=str(bookdir))

    # Pandoc tucks docx images under media/media/; flatten to a single media/.
    _flatten_media(bookdir / "media")

    text = staging.read_text().replace("media/media/", "media/")
    staging.unlink(missing_ok=True)
    text = _rebase_images(text)
    chunks = split_chapters(text) if split else [(None, text.splitlines())]

    # Three-digit, step-of-10 numbering leaves room to slot inserts (a part
    # divider, an appendix, a split-out section) between imported chapters
    # without renumbering the whole set: 010, 020, 030 — insert 015 freely.
    written, n = [], 0
    for title, lines in chunks:
        body = "\n".join(lines).strip() + "\n"
        if title is None:
            name = "000-frontmatter.md"
        else:
            n += 10
            name = f"{n:03d}-{slugify(title)}.md"
        (chapters_dir / name).write_text(body)
        written.append(name)

    media = bookdir / "media"
    n_media = sum(1 for p in media.rglob("*") if p.is_file()) if media.exists() else 0
    print(f"✓ wrote {len(written)} file(s) to {chapters_dir}:")
    for name in written:
        print(f"    {name}")
    if n_media:
        print(f"  extracted {n_media} image(s) to {media} "
              "- ensure ~300 DPI for KDP print")


# ----------------------------------------------------------------------- impose

# Sheet stock, portrait, in PDF points (1 in = 72 pt). A4 is 210×297 mm.
_PAPER = {"letter": (612.0, 792.0), "a4": (595.276, 841.89)}


def _signature_sides(n, sig_pages):
    """Ordered (left_idx, right_idx) source-page pairs, one per printed sheet
    side, for imposing `n` pages into signatures of `sig_pages` pages each.

    A signature is a stack of sheets folded together; each sheet carries 4 pages
    (2 per side). Pages are grouped into signatures of `sig_pages` (a multiple of
    4); the last signature is padded up to a multiple of 4 with blanks (indices
    >= n, which the caller renders as empty cells). Within a signature the
    standard booklet order walks inward from the outermost sheet: each sheet's
    front side is [hi, lo] and its back side is [lo+1, hi-1], so folding and
    nesting the sheets yields straight 1,2,3,… reading order. Sides come out
    front,back,front,back… — the order a duplexer (flip on short edge) wants.
    """
    sides = []
    g = 0
    while g < n:
        p = min(sig_pages, n - g)
        p += (-p) % 4                       # pad this signature to a multiple of 4
        lo, hi = 0, p - 1
        while lo < hi:
            sides.append((g + hi, g + lo))          # front: left=hi,  right=lo
            sides.append((g + lo + 1, g + hi - 1))  # back:  left=lo+1, right=hi-1
            lo += 2
            hi -= 2
        g += p
    return sides


def _compress_streams(writer):
    """Flate-compress every stored-uncompressed stream in `writer`, in place.

    pypdf writes the merged page content -- and the form XObjects it copies from
    the source -- uncompressed, though typst had deflated them. Re-deflating them
    (lossless) shrinks the imposed PDF several-fold: a 43-page interior imposed
    from 363 KB comes back 974 KB uncompressed but 182 KB after this. Streams that
    already carry a /Filter (the embedded fonts and CMaps) are left untouched.

    Uses writer._objects, a semi-internal pypdf list of every indirect object;
    the image pins pypdf, so the attribute is stable here.
    """
    from pypdf.generic import StreamObject, NameObject, NumberObject
    for obj in writer._objects:
        if isinstance(obj, StreamObject) and "/Filter" not in obj:
            packed = zlib.compress(obj.get_data(), 9)   # read raw bytes, then deflate
            obj[NameObject("/Filter")] = NameObject("/FlateDecode")
            obj[NameObject("/Length")] = NumberObject(len(packed))
            obj._data = packed


def impose_pdf(inp, paper="letter", signature=4, single=False,
               margin=0.25, output=None):
    """Impose a PDF 2-up into printable signatures for folding and hand binding.

    Reads any PDF (typically a `bf print` interior) and lays its pages two-up on
    landscape sheets so that, printed double-sided and folded down the middle,
    each group of sheets forms a signature in reading order. Pages stay portrait
    (no rotation) and are scaled to fit their half-sheet cell with a safe
    `margin`, so the tool works whatever the source trim size is. Writes the
    imposed PDF next to the input (or to `output`).
    """
    # Imported here so `bf print/epub/html/import` don't require pypdf to be
    # importable -- only impose does.
    from pypdf import PdfReader, PdfWriter, Transformation

    inp = inp.resolve()
    if not inp.exists():
        die(f"input PDF not found: {inp}")
    try:
        reader = PdfReader(str(inp))
        n = len(reader.pages)
    except Exception as e:                  # not a PDF, encrypted, corrupt, ...
        die(f"cannot read PDF {inp}: {e}")
    if n == 0:
        die(f"{inp} has no pages")

    paper = paper.lower()
    if paper not in _PAPER:
        die(f"unknown paper {paper!r}; use 'letter' or 'a4'")
    pw, ph = _PAPER[paper]
    # Print on the sheet in landscape and fold down the vertical middle: two
    # portrait cells side by side, each half the sheet wide, full sheet tall.
    sheet_w, sheet_h = max(pw, ph), min(pw, ph)
    cell_w = sheet_w / 2.0
    m = float(margin) * 72.0
    if m < 0 or 2 * m >= min(cell_w, sheet_h):
        die(f"--margin {margin} is too large for {paper} half-pages")

    if signature < 1:
        die("--signature must be >= 1")
    # One signature = enough sheets for the whole book, or a fixed count of sheets
    # (4 pages each). `--single` overrides --signature.
    sig_pages = ((n + 3) // 4) * 4 if single else 4 * signature

    sides = _signature_sides(n, sig_pages)

    writer = PdfWriter()
    for left, right in sides:
        sheet = writer.add_blank_page(width=sheet_w, height=sheet_h)
        for cell, idx in ((0, left), (1, right)):
            if idx >= n:
                continue                    # blank padding page -> empty cell
            src = reader.pages[idx]
            w, h = float(src.mediabox.width), float(src.mediabox.height)
            # Scale to fit the cell (minus margins), preserving aspect; centre.
            s = min((cell_w - 2 * m) / w, (sheet_h - 2 * m) / h)
            tx = cell * cell_w + (cell_w - w * s) / 2.0
            ty = (sheet_h - h * s) / 2.0
            sheet.merge_transformed_page(
                src, Transformation().scale(s).translate(tx, ty))

    # The imposed PDF lands in the SAME directory as its input -- so
    # docs/out/x-interior.pdf -> docs/out/x-signatures.pdf. -o overrides just the
    # filename, kept in that directory so it stays inside run.sh's writable mount.
    if output:
        name = output if output.endswith(".pdf") else output + ".pdf"
        pdf = inp.parent / Path(name).name
    else:
        # my-book-interior.pdf -> my-book-signatures.pdf (else just append).
        stem = inp.stem
        if stem.endswith("-interior"):
            stem = stem[: -len("-interior")]
        pdf = inp.parent / f"{stem}-signatures.pdf"

    _compress_streams(writer)   # re-deflate what pypdf would otherwise store raw
    with open(pdf, "wb") as f:
        writer.write(f)

    sheets = len(sides) // 2
    n_sig = 1 if single else -(-n // sig_pages)  # ceil-div signatures
    print(f"✓ wrote {pdf}")
    print(f"  {n} page(s) → {n_sig} signature(s), {sheets} sheet(s), "
          f"{len(sides)} printed side(s) on {paper} "
          f"({sheet_w / 72:.2f}×{sheet_h / 72:.2f} in landscape).")
    print("  Print double-sided (flip on SHORT edge); fold each signature at the "
          "centre, then stack & bind.")


# ------------------------------------------------------------------------ cli

def main(argv=None):
    p = argparse.ArgumentParser(prog="bf",
                                description="Markdown -> KDP print-ready PDF")
    sub = p.add_subparsers(dest="cmd", required=True)

    b = sub.add_parser("print", help="build interior PDF from a book directory")
    b.add_argument("bookdir", nargs="?", default=".",
                   help="book directory (contains book_*.yaml and chapters/)")
    b.add_argument("--pages", type=int, default=None,
                   help="estimated page count, to pick a KDP-appropriate gutter")
    b.add_argument("--keep", action="store_true",
                   help="keep intermediate .typ files in out/")
    b.add_argument("--build-id", default=None,
                   help="printing identifier (e.g. git short hash) shown on copyright page")

    d = sub.add_parser("pdf",
                       help="build a digital PDF (same as print, but TOC and "
                            "footnote links stay clickable)")
    d.add_argument("bookdir", nargs="?", default=".",
                   help="book directory (contains book_*.yaml and chapters/)")
    d.add_argument("--pages", type=int, default=None,
                   help="estimated page count, to pick a KDP-appropriate gutter")
    d.add_argument("--keep", action="store_true",
                   help="keep intermediate .typ files in out/")
    d.add_argument("--build-id", default=None,
                   help="printing identifier (e.g. git short hash) shown on copyright page")

    e = sub.add_parser("epub", help="build an EPUB3 from a book directory")
    e.add_argument("bookdir", nargs="?", default=".",
                   help="book directory (contains book_*.yaml and chapters/)")
    e.add_argument("--no-check", dest="check", action="store_false",
                   help="skip running epubcheck on the result")
    e.add_argument("--build-id", default=None,
                   help="printing identifier appended to rights metadata")

    h = sub.add_parser("html",
                       help="build HTML: whole book, just the TOC, or one chapter")
    h.add_argument("mode", nargs="?", default=None,
                   help="'toc' for a link-free table of contents, 'chapter' for "
                        "a single chapter, or omit for the whole book")
    h.add_argument("rest", nargs="*",
                   help="for 'chapter': the chapter number; then an optional "
                        "bookdir (default: current directory)")
    h.add_argument("--build-id", default=None,
                   help="accepted for wrapper parity (build.sh stamps every "
                        "build); not stamped on web output")

    i = sub.add_parser("import", help="import a .docx into chapters/*.md")
    i.add_argument("docx", help="path to the .docx file")
    i.add_argument("bookdir", nargs="?", default=".", help="target book directory")
    i.add_argument("--no-split", dest="split", action="store_false",
                   help="write one markdown file instead of splitting on H1")
    i.add_argument("--force", action="store_true",
                   help="overwrite an existing non-empty chapters/ directory")

    m = sub.add_parser("impose",
                       help="impose a PDF 2-up into printable signatures for "
                            "folding and hand binding")
    m.add_argument("input", help="path to the PDF to impose (e.g. an interior)")
    m.add_argument("--paper", default="letter",
                   help="sheet paper: 'letter' (default) or 'a4'")
    m.add_argument("--signature", type=int, default=4,
                   help="sheets per signature; each sheet folds to 4 pages "
                        "(default: 4)")
    m.add_argument("--single", action="store_true",
                   help="whole book as one folded booklet (saddle-stitch)")
    m.add_argument("--margin", type=float, default=0.25,
                   help="inches of safe margin inside each half-page cell "
                        "(default: 0.25)")
    m.add_argument("-o", "--output", default=None,
                   help="output filename (written beside the input); "
                        "default: <input>-signatures.pdf")

    args = p.parse_args(argv)
    if args.cmd == "print":
        build_print(Path(args.bookdir), pages=args.pages, keep=args.keep,
                    build_id=args.build_id, links="print", include_cover=False)
    elif args.cmd == "pdf":
        build_print(Path(args.bookdir), pages=args.pages, keep=args.keep,
                    build_id=args.build_id, links="live", include_cover=True)
    elif args.cmd == "epub":
        build_epub(Path(args.bookdir), check=args.check, build_id=args.build_id)
    elif args.cmd == "html":
        mode, rest = args.mode, args.rest
        if mode == "toc":
            build_html_toc(Path(rest[0] if rest else "."))
        elif mode == "chapter":
            if not rest:
                die("usage: bf html chapter NN [bookdir]")
            build_html_chapter(Path(rest[1] if len(rest) > 1 else "."), rest[0])
        else:
            build_html(Path(mode if mode is not None else "."))
    elif args.cmd == "import":
        import_docx(Path(args.docx), Path(args.bookdir),
                    split=args.split, force=args.force)
    else:
        impose_pdf(Path(args.input), paper=args.paper,
                   signature=args.signature, single=args.single,
                   margin=args.margin, output=args.output)


if __name__ == "__main__":
    main()
