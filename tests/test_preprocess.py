"""Fast, repeatable unit tests for the chapter-preprocessing logic.

These cover the novel / no-parts / auto-numbering behaviour that `bf print`
applies before pandoc: heading scanning, heading demotion, the flat-vs-parts
decision, auto-numbered title-less chapters, named sections in a mixed book,
empty-file skipping, the contents/running-head "Chapter N" labelling, and the
`.txt`/`.md` chapter glob.

It is pure Python -- no pandoc, typst, or Docker build -- so it runs in about a
second and can be run again and again. The one dependency is PyYAML (imported by
bf.__main__), which lives in the book4matter image; run it with tests/unit.sh,
which executes this against the working-tree `bf` mounted in the container.
"""
import re
import shutil
import tempfile
import unittest
from pathlib import Path

from bf.__main__ import (
    preprocess_chapters,
    resolve_chapters,
    _scan_levels,
    _demote_md,
    _mark_first_heading,
)


def _first_heading(text):
    """The first ATX heading line of a rewritten chapter, or None."""
    for line in text.splitlines():
        if re.match(r"^#{1,6}(\s|$)", line):
            return line
    return None


class TmpBase(unittest.TestCase):
    def setUp(self):
        self.root = Path(tempfile.mkdtemp(prefix="bf_test_"))
        self.addCleanup(shutil.rmtree, self.root, ignore_errors=True)

    def prep(self, files, **kw):
        """Run preprocess_chapters over an ordered list of (name, content).

        Returns (heads, bodies, show_toc, no_parts) where `heads` is the first
        heading line of each rewritten chapter (in order) and `bodies` the full
        rewritten text of each."""
        indir = self.root / "in"
        indir.mkdir(exist_ok=True)
        outdir = self.root / f"out{len(list(self.root.iterdir()))}"
        outdir.mkdir()
        paths = []
        for name, content in files:
            p = indir / name
            p.write_text(content)
            paths.append(p)
        out_paths, show_toc, no_parts = preprocess_chapters(paths, outdir, **kw)
        bodies = [p.read_text() for p in out_paths]
        heads = [_first_heading(b) for b in bodies]
        return heads, bodies, show_toc, no_parts


class TestScanLevels(unittest.TestCase):
    def test_levels_present(self):
        self.assertEqual(_scan_levels("# a\n## b\n### c"), {1, 2, 3})

    def test_empty_heading_counts(self):
        self.assertEqual(_scan_levels("##"), {2})
        self.assertEqual(_scan_levels("## "), {2})

    def test_hash_without_space_is_not_a_heading(self):
        self.assertEqual(_scan_levels("#nospace"), set())

    def test_setext_is_not_atx(self):
        self.assertEqual(_scan_levels("Title\n=====\n\nbody"), set())

    def test_fence_aware(self):
        self.assertEqual(_scan_levels("```\n# not a heading\n```\n# yes"), {1})

    def test_no_headings(self):
        self.assertEqual(_scan_levels("just some prose\n\nmore prose"), set())


class TestDemote(unittest.TestCase):
    def test_single_level(self):
        self.assertEqual(_demote_md("# a"), "## a")

    def test_whole_hierarchy_shifts(self):
        self.assertEqual(_demote_md("# a\n## b\n### c"), "## a\n### b\n#### c")

    def test_capped_at_six(self):
        self.assertEqual(_demote_md("###### x"), "###### x")

    def test_attribute_block_preserved(self):
        self.assertEqual(_demote_md("## y {.new-page}"), "### y {.new-page}")

    def test_empty_heading(self):
        self.assertEqual(_demote_md("#"), "##")

    def test_fence_content_untouched(self):
        self.assertEqual(
            _demote_md("```\n# no\n```\n# yes"), "```\n# no\n```\n## yes")


class TestMarkFirstHeading(unittest.TestCase):
    def test_marks_only_the_first(self):
        self.assertEqual(
            _mark_first_heading("## a\n## b", "unnumbered"),
            "## a {.unnumbered}\n## b")

    def test_merges_existing_attributes(self):
        self.assertEqual(
            _mark_first_heading("## a {.new-page}", "unnumbered"),
            "## a {.new-page .unnumbered}")

    def test_fence_protected(self):
        self.assertEqual(
            _mark_first_heading("```\n# no\n```\n# yes", "unnumbered"),
            "```\n# no\n```\n# yes {.unnumbered}")

    def test_no_heading_unchanged(self):
        self.assertEqual(
            _mark_first_heading("just prose", "unnumbered"), "just prose")


class TestPureNovel(TmpBase):
    """No headings anywhere: numbered, title-less chapters and no contents."""

    def test_numbered_titleless_no_toc(self):
        heads, _, show_toc, no_parts = self.prep(
            [("01.txt", "Chapter one prose.\n"),
             ("02.txt", "Chapter two prose.\n"),
             ("03.txt", "Chapter three prose.\n")])
        self.assertTrue(no_parts)
        self.assertFalse(show_toc)                 # nothing to list
        self.assertEqual(len(heads), 3)
        # Empty headings -> the template supplies the centered numeral.
        self.assertTrue(all(h == "##" for h in heads), heads)

    def test_single_file_is_chapter_one(self):
        heads, _, show_toc, _ = self.prep([("only.txt", "The whole book.\n")])
        self.assertEqual(heads, ["##"])
        self.assertFalse(show_toc)


class TestEmptyFiles(TmpBase):
    def test_empty_file_skipped_and_not_numbered(self):
        # Force labels (running heads) so the numbers are visible in the output.
        heads, _, show_toc, _ = self.prep(
            [("01.txt", "First.\n"),
             ("02.txt", "   \n\n  \n"),      # whitespace only -> dropped
             ("03.txt", "Second.\n")],
            running_heads=True)
        self.assertEqual(len(heads), 2)                 # the empty file is gone
        self.assertEqual(heads[0], "## Chapter 1 {.unnumbered}")
        self.assertEqual(heads[1], "## Chapter 2 {.unnumbered}")  # not 3
        self.assertFalse(show_toc)


class TestFlatTitled(TmpBase):
    """Only `#` headings: they are chapters, not parts (auto no-parts)."""

    def test_hash_is_chapter_and_demoted(self):
        heads, _, show_toc, no_parts = self.prep(
            [("a.md", "# Alpha\n\nbody\n"),
             ("b.md", "# Beta\n\nbody\n")])
        self.assertTrue(no_parts)                  # no `##` anywhere
        self.assertTrue(show_toc)                  # titled -> contents
        # `#` demoted to `##` (chapter); all titled -> numbered, so NOT marked
        # unnumbered.
        self.assertEqual(heads, ["## Alpha", "## Beta"])


class TestPartsPreserved(TmpBase):
    """A book that uses `##` keeps the part/chapter hierarchy untouched."""

    def test_parts_not_demoted(self):
        heads, bodies, show_toc, no_parts = self.prep(
            [("a.md", "# Part One\n\n## Chapter\n\nbody\n")])
        self.assertFalse(no_parts)
        self.assertTrue(show_toc)
        self.assertEqual(heads[0], "# Part One")   # still a part
        self.assertIn("## Chapter", bodies[0])     # still a chapter


class TestScenesNeedNoParts(TmpBase):
    """A file that writes `#`=chapter and `##`=scene is ambiguous: it looks
    identical to parts+chapters, so auto-detection treats `#` as a part. The
    author opts into the flat reading with --no-parts, which then demotes the
    whole hierarchy one level."""

    SRC = [("a.md", "# Chapter\n\n## Scene\n\nbody\n")]

    def test_auto_treats_scenes_as_parts(self):
        heads, bodies, _, no_parts = self.prep(self.SRC)
        self.assertFalse(no_parts)                 # `##` present -> parts mode
        self.assertEqual(heads[0], "# Chapter")    # left as written

    def test_no_parts_makes_them_chapter_and_section(self):
        heads, bodies, _, no_parts = self.prep(self.SRC, force_no_parts=True)
        self.assertTrue(no_parts)
        self.assertEqual(heads[0], "## Chapter")   # was a part, now a chapter
        self.assertIn("### Scene", bodies[0])      # was a chapter, now a section


class TestMixed(TmpBase):
    """Titled files among untitled ones become named, un-numbered sections."""

    def test_named_sections_and_numbered_chapters(self):
        heads, _, show_toc, no_parts = self.prep(
            [("00-intro.txt", "# Introduction\n\nwelcome\n"),
             ("01.txt", "First real chapter.\n"),
             ("02.txt", "Second real chapter.\n"),
             ("99-after.txt", "# Afterword\n\nthanks\n")])
        self.assertTrue(no_parts)
        self.assertTrue(show_toc)                  # there are titles to list
        self.assertEqual(heads, [
            "## Introduction {.unnumbered}",       # named, no number
            "## Chapter 1 {.unnumbered}",          # numbered
            "## Chapter 2 {.unnumbered}",          # count skips the sections
            "## Afterword {.unnumbered}",
        ])


class TestTocLabelling(TmpBase):
    """An auto-numbered chapter is labelled only when its title will be read."""

    def test_explicit_toc_labels_numbers(self):
        heads, _, show_toc, _ = self.prep(
            [("01.txt", "body\n"), ("02.txt", "body\n")], toc=True)
        self.assertTrue(show_toc)
        self.assertEqual(heads, ["## Chapter 1 {.unnumbered}",
                                 "## Chapter 2 {.unnumbered}"])

    def test_explicit_toc_false_keeps_empty_headings(self):
        heads, _, show_toc, _ = self.prep(
            [("01.txt", "body\n"), ("02.txt", "body\n")], toc=False)
        self.assertFalse(show_toc)
        self.assertEqual(heads, ["##", "##"])      # elegant numeral opener

    def test_running_heads_label_without_toc(self):
        heads, _, show_toc, _ = self.prep(
            [("01.txt", "body\n")], running_heads=True)
        self.assertFalse(show_toc)                 # still no contents page
        self.assertEqual(heads, ["## Chapter 1 {.unnumbered}"])


class TestResolveChapters(TmpBase):
    def _book(self, names):
        chdir = self.root / "book" / "chapters"
        chdir.mkdir(parents=True)
        for n in names:
            (chdir / n).write_text("body\n")
        return self.root / "book"

    def test_globs_md_and_txt_in_natural_order(self):
        book = self._book(["10.md", "2.txt", "1.md"])
        got = [p.name for p in resolve_chapters(book, {})]
        self.assertEqual(got, ["1.md", "2.txt", "10.md"])

    def test_explicit_list_wins(self):
        book = self._book(["10.md", "2.txt", "1.md"])
        got = [p.name for p in
               resolve_chapters(book, {"chapters": ["chapters/2.txt"]})]
        self.assertEqual(got, ["2.txt"])


if __name__ == "__main__":
    unittest.main()
