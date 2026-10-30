"""Term markup integration checks; use the existing image's pandoc/typst.

No dependencies are installed. On a host without pandoc these tests skip.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which('pandoc'), 'pandoc is not available')
class TermMarkup(unittest.TestCase):
    def convert(self, source, mode='reflow', target='html', registry='', toc=False):
        result = subprocess.run(
            ['pandoc', '-f', 'markdown', '-t', target,
             '--lua-filter=' + str(ROOT / 'templates/tracked.lua'),
             *(['--standalone', '--toc'] if toc else [])],
            input=source, text=True, capture_output=True,
            env={**os.environ, 'BF_TRACKED_MODE': mode, 'BF_TRACKED': registry})
        if mode == 'reflow' and target == 'html':
            from bf.__main__ import strip_index_ids_from_navigation
            result.stdout = strip_index_ids_from_navigation(result.stdout)
        return result

    def test_front_index_grouping_sort_and_anchors(self):
        result = self.convert('{index:term}\n\n[[zebra]] [[Alpha]] [[alpha]]')
        self.assertEqual(result.returncode, 0, result.stderr)
        html = result.stdout
        self.assertLess(html.index('>Alpha</a>'), html.index('>zebra</a>'))
        for anchor in ('idx-zebra-1', 'idx-alpha-1', 'idx-alpha-2'):
            self.assertIn('id="%s"' % anchor, html)
            self.assertIn('href="#%s"' % anchor, html)
        self.assertEqual(html.count('>Alpha</a>'), 1)
        self.assertNotIn('[[', html)

    def test_code_and_ordinary_mentions_stay_literal(self):
        result = self.convert('practice hold `[[code]]`\n\n```\n[[block]]\n```\n\n{index:term}')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('[[code]]', result.stdout)
        self.assertIn('[[block]]', result.stdout)
        self.assertNotIn('id="idx-', result.stdout)

    def test_emphasis_and_tracked_items_coexist(self):
        result = self.convert('*[[practice hold]]* {exercise:x:def}\n\n{index:term}\n\n{index:exercise}', registry='exercise=Exercise')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('<em><span id="idx-practice-hold-1">practice hold</span></em>', result.stdout)
        self.assertIn('Exercise #1', result.stdout)
        self.assertIn('href="#trk-exercise-x"', result.stdout)

    def test_term_matching_another_heading(self):
        source = '## [[Frame]]\n\n### Frame\n\nAn ordinary [Frame](#frame-1) link.\n\n{index:term}'
        for mode, target in (('reflow', 'html'), ('print', 'typst')):
            with self.subTest(mode=mode):
                result = self.convert(source, mode, target, toc=(mode == 'reflow'))
                self.assertEqual(result.returncode, 0, result.stderr)
                if mode == 'reflow':
                    self.assertEqual(result.stdout.count('id="frame"'), 1)
                    self.assertEqual(result.stdout.count('id="idx-frame-1"'), 1)
                    self.assertIn('<span id="idx-frame-1">Frame</span></h2>', result.stdout)
                    toc = result.stdout.split('</nav>')[0]
                    self.assertNotIn('id="idx-frame-1"', toc)
                    self.assertIn('href="#idx-frame-1">Frame</a>', result.stdout)
                    self.assertIn('href="#frame-1">Frame</a>', result.stdout)
                else:
                    self.assertIn('#termdef("frame", "Frame", "idx-frame-1")', result.stdout)

    def test_slug_collisions_and_repeated_heading_definitions(self):
        source = '# [[practice hold]]\n\n## [[practice-hold]]\n\n## [[Practice Hold]]\n\n{index:term}'
        result = self.convert(source, toc=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        toc = result.stdout.split('</nav>')[0]
        for n in (1, 2, 3):
            anchor = 'idx-practice-hold-%d' % n
            self.assertEqual(result.stdout.count('id="%s"' % anchor), 1)
            self.assertIn('href="#%s"' % anchor, result.stdout)
            self.assertNotIn('id="%s"' % anchor, toc)

    def test_index_alias_grouping_sort_and_outbound_link(self):
        source = ('{index:term}\n\n[[Zebra]] [[Alice]] '
                  '[[Richard Powers|Powers, Richard]] '
                  '[[[R. Powers | Powers, Richard]]](https://www.richardpowers.com)')
        result = self.convert(source)
        self.assertEqual(result.returncode, 0, result.stderr)
        html = result.stdout.replace('\n', ' ')
        self.assertIn('<span id="idx-powers-richard-1">Richard Powers</span>', html)
        self.assertIn('href="https://www.richardpowers.com"><span id="idx-powers-richard-2">R. Powers</span></a>', html)
        self.assertEqual(html.count('>Powers, Richard</a>'), 1)
        self.assertIn('href="#idx-powers-richard-2">2</a>', html)
        self.assertLess(html.index('>Alice</a>'), html.index('>Powers, Richard</a>'))
        self.assertLess(html.index('>Powers, Richard</a>'), html.index('>Zebra</a>'))
        result = self.convert('[[[Richard Powers|Powers, Richard]]](https://www.richardpowers.com)\n\n{index:term}', 'print', 'typst')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('#termdef("powers, richard", "Powers, Richard", "idx-powers-richard-1", display: "Richard Powers")', result.stdout)
        self.assertIn('https://www.richardpowers.com', result.stdout)

    def test_subentries_group_sort_and_keep_heading_and_link_anchors(self):
        source = ('{index:term}\n\n## [[polka hold| Practice hold > polka ]]\n\n'
                  '[[[waltz hold|practice hold>waltz]]](https://example.com)\n\n'
                  '[[Practice hold]] [[another polka hold|Practice hold>polka]]\n\n'
                  '[[Viennese Waltz|Waltz>Viennese]]')
        result = self.convert(source, toc=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        html = result.stdout.replace('\n', ' ')
        self.assertIn('id="idx-practice-hold-polka-1">polka hold</span></h2>', html)
        self.assertIn('href="https://example.com"><span id="idx-practice-hold-waltz-1">waltz hold</span></a>', html)
        self.assertIn('href="#idx-practice-hold-polka-2">2</a>', html)
        self.assertIn('href="#idx-practice-hold-1">Practice hold</a>', html)
        self.assertIn('>polka</a>', html)
        self.assertIn('>waltz</a>', html)
        self.assertLess(html.index('>polka</a>'), html.index('>waltz</a>'))
        self.assertIn('class="index-label">Waltz</span>', html)
        self.assertNotIn('href="#idx-waltz-1"', html)
        self.assertNotIn('id="idx-practice-hold-polka-1"', html.split('</nav>')[0])
        self.assertGreaterEqual(html.count('<ul>'), 3)
        self.assertIn('class="index-leader"', html)
        self.assertIn('class="index-label">↳ ', html)
        self.assertIn('class="index-locations"', html)

    @unittest.skipUnless(shutil.which('typst'), 'typst is not available')
    def test_subentries_build_in_all_formats(self):
        import bf.__main__ as bf
        from unittest.mock import patch
        from pypdf import PdfReader
        import zipfile
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'chapters').mkdir()
            (root / 'book_metadata.yaml').write_text('title: Subentry test\nauthor: Test\n')
            (root / 'book_style.yaml').write_text('toc: true\n')
            (root / 'chapters/01.md').write_text(
                '## [[Practice hold]]\n\nThe general definition.\n\n'
                '## [[polka hold|Practice hold>polka]]\n\n'
                '[[[another hold|Practice hold>polka]]](https://example.com)\n\n'
                '[[Viennese Waltz|Waltz>Viennese]]\n\n'
                '[[[Tempo|Tempo;BPM;Beats per minute]]](https://example.com/tempo)\n\n'
                '## Index {.section}\n\n{index:term}\n')
            with patch.object(bf, 'TEMPLATES', ROOT / 'templates'):
                bf.build_html(root)
                bf.build_epub(root)
                for mode in ('print', 'live'):
                    bf.build_print(root, links=mode)
                    suffix = '' if mode == 'live' else '-interior'
                    reader = PdfReader(root / 'out' / ('subentry-test' + suffix + '.pdf'))
                    index = reader.pages[-1]
                    text = index.extract_text()
                    self.assertIn('Practice hold', text)
                    parent_fonts = []
                    long_horizontal_rules = []
                    path_start = None
                    def inspect_text(value, cm, tm, font, size):
                        if 'Practice hold' in value:
                            parent_fonts.append(str(font.get('/BaseFont', '')))
                    def inspect_drawing(op, args, cm, tm):
                        nonlocal path_start
                        if op == b'm':
                            path_start = tuple(float(v) for v in args)
                        elif op == b'l' and path_start:
                            x, y = (float(v) for v in args)
                            if abs(y - path_start[1]) < 0.1 and abs(x - path_start[0]) > 100:
                                long_horizontal_rules.append((path_start, (x, y)))
                            path_start = (x, y)
                    index.extract_text(visitor_text=inspect_text, visitor_operand_before=inspect_drawing)
                    self.assertTrue(parent_fonts)
                    self.assertFalse(any('bold' in font.lower() for font in parent_fonts), parent_fonts)
                    self.assertFalse(long_horizontal_rules, long_horizontal_rules)
                    self.assertIn('polka', text)
                    self.assertIn('↳', text)
                    self.assertIn('....', text.replace(' ', ''))
                    self.assertIn('Waltz', text)
                    self.assertIn('Viennese', text)
                    self.assertIn('BPM.seeTempo', ''.join(text.split()))
                    self.assertIn('Beatsperminute.seeTempo', ''.join(text.split()))
                    self.assertNotIn('Practice hold>', text)
                    # One parent definition, one deduplicated child page, and
                    # one child below an automatically created, unlinked parent.
                    links = index.get('/Annots', [])
                    self.assertEqual(len(links), 6 if mode == 'live' else 0)
                    if mode == 'live':
                        contents = {p.indirect_reference.idnum for p in reader.pages if 'Contents' in p.extract_text()}
                        for link in links:
                            self.assertNotIn(link.get_object()['/Dest'][0].idnum, contents)
            with zipfile.ZipFile(root / 'out/subentry-test.epub') as archive:
                pages = '\n'.join(archive.read(n).decode() for n in archive.namelist() if n.endswith('.xhtml'))
                self.assertEqual(pages.count('id="idx-practice-hold-polka-1"'), 1)
                self.assertIn('href="https://example.com"', pages)
                self.assertIn('>polka</a>', pages)
                self.assertIn('↳', pages)
                self.assertIn('class="index-leader"', pages)
                self.assertIn('#idx-practice-hold-polka-2"', pages)
                self.assertIn('>Viennese</a>', pages)
                self.assertIn('BPM. <em>see</em>', pages)
                self.assertIn('#idx-tempo-1"', pages)

    @unittest.skipUnless(shutil.which('typst'), 'typst is not available')
    def test_index_continuation_headers_keep_parent_with_child(self):
        from pypdf import PdfReader
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shutil.copy(ROOT / 'templates/book.typ', root / 'book.typ')
            (root / 'test.typ').write_text(
                '#import "book.typ": termdef, termindex, tracked-links\n'
                '#set page(width: 260pt, height: 240pt, margin: 20pt)\n'
                '#set text(font: "Liberation Serif", size: 10pt)\n'
                '#tracked-links.update(true)\n'
                '#termdef("practice hold", "Practice hold", "idx-practice-hold-1")\n'
                '#for i in range(60) { termdef("practice hold>child-" + str(i), '
                '"Child " + str(i), "idx-child-" + str(i), parent: "Practice hold") }\n'
                '#pagebreak()\nINDEX START\n#v(170pt)\n#termindex()\n')
            result = subprocess.run(['typst', 'compile', str(root / 'test.typ'), str(root / 'test.pdf')],
                                    text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn('did not converge', result.stderr)
            reader = PdfReader(root / 'test.pdf')
            start = next(i for i, p in enumerate(reader.pages) if 'INDEX START' in p.extract_text())
            pages = [p.extract_text() for p in reader.pages[start:]]
            groups = [text for text in pages if 'Practice hold' in text]
            self.assertGreaterEqual(len(groups), 3)
            self.assertNotIn('(continued)', groups[0])
            for text in groups:
                self.assertIn('↳', text)
                self.assertIn('Child', text)
                self.assertIn('....', text.replace(' ', ''))
            for text in groups[1:]:
                self.assertIn('Practice hold (continued)', text)
            self.assertNotIn('Practice hold', pages[0])

    def test_see_aliases_sort_deduplicate_and_link_to_definition(self):
        source = ('{index:term}\n\n## [[Tempo|Tempo;BPM;Beats per minute]]\n\n'
                  '[[[speed|Tempo;BPM]]](https://example.com)\n\n'
                  '[[polka hold|Practice hold>polka;Polka grip]]')
        result = self.convert(source, toc=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        html = result.stdout.replace('\n', ' ')
        self.assertEqual(html.count('BPM.'), 1)
        self.assertIn('BPM. <em>see</em> <a href="#idx-tempo-1">Tempo</a>', html)
        self.assertIn('Beats per minute. <em>see</em>', html)
        self.assertIn('Polka grip. <em>see</em> <a href="#idx-practice-hold-polka-1">Practice hold, polka</a>', html)
        self.assertLess(html.index('Beats per minute.'), html.index('BPM.'))
        self.assertIn('id="idx-tempo-1">Tempo</span></h2>', html)
        self.assertIn('href="https://example.com"><span id="idx-tempo-2">speed</span></a>', html)
        self.assertNotIn('id="idx-tempo-1"', html.split('</nav>')[0])
        result = self.convert('[[Tempo|Tempo;BPM]]\n\n{index:term}', 'print', 'typst')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('aliases: ("BPM",)', result.stdout)

    def test_invalid_see_aliases_report_offending_markup(self):
        for source in ('[[Tempo|Tempo;]]', '[[Tempo|Tempo;;BPM]]',
                       '[[Tempo|Tempo;Tempo]]', '[[Tempo|Tempo;Group>child]]',
                       '[[Tempo|Tempo;BPM]] [[BPM]]',
                       '[[BPM]] [[Tempo|Tempo;BPM]]',
                       '[[Tempo|Tempo;BPM]] [[Speed|Speed;BPM]]'):
            with self.subTest(source=source):
                result = self.convert(source)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('offending markup:', result.stderr)

    def test_invalid_and_future_syntax_fail(self):
        for marker in ('[[]]', '[[term:ref]]', '[[term|]]', '[[|entry]]', '[[a|b|c]]', '[[text|>child]]', '[[text|Parent>]]', '[[text|A>B>C]]'):
            with self.subTest(marker=marker):
                result = self.convert(marker)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('tracked.lua:', result.stderr)

    def test_error_reports_original_file_line_and_markup(self):
        from bf.__main__ import tracked_env_vars, preprocess_chapters
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            first, second = root / '01 good.md', root / '02 bad.md'
            first.write_text('# Good\n\n[[valid]]\n')
            second.write_text('An untitled chapter.\n\n[[[Richard Powers|]]](https://www.richardpowers.com)\n')
            scratch = root / 'scratch'
            scratch.mkdir()
            processed, _, _ = preprocess_chapters([first, second], scratch)
            for mode, files in (('reflow', [first, second]), ('print', processed)):
                with self.subTest(mode=mode):
                    result = subprocess.run(
                        ['pandoc', '-f', 'markdown', '-t', 'native',
                         '--lua-filter=' + str(ROOT / 'templates/tracked.lua'),
                         *map(str, files)], text=True, capture_output=True,
                        env={**os.environ, **tracked_env_vars({}, mode, [first, second])})
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(str(second) + ':3', result.stderr)
                    self.assertIn('offending markup: [[Richard Powers|]]', result.stderr)
                    self.assertNotIn(str(scratch), result.stderr)

    def test_error_with_repeated_markup_lists_candidate_locations(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'chapter.md'
            source.write_text('`[[bad|]]`\n\n[[bad|]]\n')
            result = subprocess.run(
                ['pandoc', '-f', 'markdown', '-t', 'native',
                 '--lua-filter=' + str(ROOT / 'templates/tracked.lua'), str(source)],
                text=True, capture_output=True,
                env={**os.environ, 'BF_TRACKED_MODE': 'reflow', 'BF_TRACKED': ''})
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('matching source locations', result.stderr)
            self.assertIn(str(source) + ':1', result.stderr)
            self.assertIn(str(source) + ':3', result.stderr)
            self.assertIn('offending markup: [[bad|]]', result.stderr)

    @unittest.skipUnless(shutil.which('typst'), 'typst is not available')
    def test_pdf_heading_index_omits_contents_and_links_to_body(self):
        from bf.__main__ import build_print
        from pypdf import PdfReader
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'chapters').mkdir()
            (root / 'book_metadata.yaml').write_text('title: Index regression\nauthor: Test\n')
            (root / 'book_style.yaml').write_text('toc: true\n')
            (root / 'chapters/01.md').write_text(
                '## [[Frame]]\n\nBody text.\n\n## [[How Dancers Travel]]\n\nMore body text.\n\n## Index {.section}\n\n{index:term}\n')
            import bf.__main__ as bf
            from unittest.mock import patch
            with patch.object(bf, 'TEMPLATES', ROOT / 'templates'):
                for mode in ('print', 'live'):
                    build_print(root, links=mode)
                    pdf = root / 'out' / ('index-regression.pdf' if mode == 'live' else 'index-regression-interior.pdf')
                    reader = PdfReader(pdf)
                    contents = {p.indirect_reference.idnum for p in reader.pages if 'Contents' in p.extract_text()}
                    self.assertTrue(contents)
                    index = reader.pages[-1]
                    text = index.extract_text()
                    self.assertIn('Frame', text)
                    self.assertRegex(text, r'Frame[. ]+\d')
                    self.assertNotRegex(text, r'Frame[^\n]*,')
                    self.assertNotRegex(text, r'How Dancers[^\n]*,')
                    annotations = index.get('/Annots', [])
                    if mode == 'live':
                        self.assertEqual(len(annotations), 2)
                        for annotation in annotations:
                            target = annotation.get_object()['/Dest'][0]
                            self.assertNotIn(target.idnum, contents)
                    else:
                        self.assertEqual(len(annotations), 0)

    @unittest.skipUnless(shutil.which('typst'), 'typst is not available')
    def test_typst_rejects_duplicate_definition_marker(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shutil.copy(ROOT / 'templates/book.typ', root / 'book.typ')
            (root / 'test.typ').write_text(
                '#import "book.typ": termdef, termindex\n'
                '#termdef("frame", "Frame", "idx-frame-1")\n'
                '#termdef("frame", "Frame", "idx-frame-1")\n'
                '#termindex()\n')
            result = subprocess.run(['typst', 'compile', str(root / 'test.typ'), str(root / 'test.pdf')],
                                    text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Index definition 'Frame' (idx-frame-1) was emitted more than once", result.stderr)

    def test_typst_calls(self):
        result = self.convert('[[practice hold]]\n\n{index:term}', 'print', 'typst')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('#termdef(', result.stdout)
        self.assertIn('#termindex()', result.stdout)
        self.assertIn('idx-practice-hold-1', result.stdout)

    def test_epub_keeps_definition_anchors(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'terms.epub'
            result = subprocess.run(
                ['pandoc', '-f', 'markdown', '-t', 'epub3',
                 '--lua-filter=' + str(ROOT / 'templates/tracked.lua'), '-o', str(output)],
                input='# [[practice hold]]\n\n[[[Richard Powers|Powers, Richard]]](https://www.richardpowers.com)\n\n# Index\n\n{index:term}',
                text=True, capture_output=True,
                env={**os.environ, 'BF_TRACKED_MODE': 'reflow', 'BF_TRACKED': ''})
            self.assertEqual(result.returncode, 0, result.stderr)
            import zipfile
            from bf.__main__ import clean_epub_index_navigation
            clean_epub_index_navigation(output)
            with zipfile.ZipFile(output) as archive:
                pages = '\n'.join(archive.read(n).decode() for n in archive.namelist() if n.endswith('.xhtml'))
            self.assertEqual(pages.count('id="idx-practice-hold-1"'), 1)
            self.assertIn('<span id="idx-practice-hold-1">practice hold</span></h1>', pages)
            self.assertIn('#idx-practice-hold-1"', pages)
            self.assertNotIn('[[practice hold]]', pages)
            self.assertIn('href="https://www.richardpowers.com"', pages)
            self.assertIn('id="idx-powers-richard-1">Richard Powers</span>', pages)
            self.assertIn('#idx-powers-richard-1"', pages)
            self.assertIn('>Powers, Richard</a>', pages)


class IndexAnchorValidation(unittest.TestCase):
    def test_unique_body_anchors_pass(self):
        from bf.__main__ import validate_index_anchors
        validate_index_anchors([('book.html', '<nav><a href="#idx-frame-1">Frame</a></nav>'
                                '<h2><span id="idx-frame-1">Frame</span></h2>'
                                '<p id="idx-frame-2">Another definition</p>')])

    def test_duplicate_error_names_anchor_file_and_lines(self):
        from bf.__main__ import validate_index_anchors
        from contextlib import redirect_stderr
        import io
        errors = io.StringIO()
        with redirect_stderr(errors), self.assertRaises(SystemExit):
            validate_index_anchors([('book.html', '<span id="idx-frame-1">Frame</span>\n'
                                    '<span id="idx-frame-1">Frame</span>')])
        self.assertIn("duplicate index definition anchor 'idx-frame-1'", errors.getvalue())
        self.assertIn('book.html:1', errors.getvalue())
        self.assertIn('book.html:2', errors.getvalue())

    def test_leftover_navigation_anchor_fails_even_without_body_copy(self):
        from bf.__main__ import validate_index_anchors
        from contextlib import redirect_stderr
        import io
        errors = io.StringIO()
        with redirect_stderr(errors), self.assertRaises(SystemExit):
            validate_index_anchors([('book.html', "<nav><span id='idx-frame-1'>Frame</span></nav>")])
        self.assertIn('index definition anchor in navigation', errors.getvalue())
        self.assertIn('(navigation/TOC)', errors.getvalue())

    def test_html_build_rejects_duplicate_after_cleanup(self):
        from bf.__main__ import build_html
        from unittest.mock import patch
        from contextlib import redirect_stderr
        import io
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            def fake_pandoc(cmd, **kwargs):
                Path(cmd[cmd.index('-o') + 1]).write_text(
                    '<nav><span id="idx-frame-1">Frame</span></nav>'
                    '<h2 id="idx-frame-1">Frame</h2><p id="idx-frame-1">Duplicate</p>')
            with patch('bf.__main__.load_config', return_value={'title': 'Book'}), \
                 patch('bf.__main__.resolve_chapters', return_value=[root / 'chapter.md']), \
                 patch('bf.__main__.run', side_effect=fake_pandoc), \
                 redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                build_html(root)

    def test_epub_cleanup_removes_toc_ids_and_preserves_definition(self):
        from bf.__main__ import clean_epub_index_navigation
        import zipfile
        with tempfile.TemporaryDirectory() as directory:
            epub = Path(directory) / 'book.epub'
            with zipfile.ZipFile(epub, 'w') as archive:
                archive.writestr('mimetype', 'application/epub+zip')
                archive.writestr('nav.xhtml', '<nav><span id="idx-frame-1">Frame</span></nav>')
                archive.writestr('chapter.xhtml', '<h2><span id="idx-frame-1">Frame</span></h2>')
            clean_epub_index_navigation(epub)
            with zipfile.ZipFile(epub) as archive:
                self.assertEqual(archive.namelist()[0], 'mimetype')
                self.assertNotIn(b'id="idx-frame-1"', archive.read('nav.xhtml'))
                self.assertIn(b'id="idx-frame-1"', archive.read('chapter.xhtml'))

    def test_epub_rejects_duplicates_within_and_across_chapters(self):
        from bf.__main__ import clean_epub_index_navigation
        from contextlib import redirect_stderr
        import io
        import zipfile
        for split in (False, True):
            with self.subTest(split=split), tempfile.TemporaryDirectory() as directory:
                epub = Path(directory) / 'book.epub'
                markup = '<span id="idx-how-dancers-travel-1">How Dancers Travel</span>'
                with zipfile.ZipFile(epub, 'w') as archive:
                    archive.writestr('chapter1.xhtml', markup if split else markup + '\n' + markup)
                    if split:
                        archive.writestr('chapter2.xhtml', markup)
                errors = io.StringIO()
                with redirect_stderr(errors), self.assertRaises(SystemExit):
                    clean_epub_index_navigation(epub)
                self.assertIn('idx-how-dancers-travel-1', errors.getvalue())
                self.assertIn('book.epub!/chapter1.xhtml:1', errors.getvalue())
                if split:
                    self.assertIn('book.epub!/chapter2.xhtml:1', errors.getvalue())


if __name__ == '__main__':
    unittest.main()
