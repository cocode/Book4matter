"""Unit tests for the tracked-items registry serialization in bf.

These cover `tracked_kinds` and `tracked_typ` -- how `book_metadata.yaml`'s
`tracked:` map is validated and turned into the `meta.tracked` Typst literal and
the BF_TRACKED_KINDS list handed to tracked.lua. The token grammar itself
(`{kind:id}`, `{index:kind}`, ...) lives in tracked.lua and is exercised by the
`tests/tracked` fixture through a real build; these are the fast, pure-Python
checks for the config front end.

Pure Python (PyYAML aside); run with tests/unit.sh.
"""
import unittest

from bf.__main__ import tracked_kinds, tracked_typ


class TrackedKinds(unittest.TestCase):
    def test_absent_and_empty(self):
        self.assertEqual(tracked_kinds({}), [])
        self.assertEqual(tracked_kinds({"tracked": None}), [])

    def test_order_preserved(self):
        cfg = {"tracked": {"exercise": {}, "figure": "Figure", "chart": None}}
        self.assertEqual(tracked_kinds(cfg), ["exercise", "figure", "chart"])

    def test_bad_kind_name_rejected(self):
        for bad in ("Exercise", "my kind", "fig_ure", "1st"):
            with self.assertRaises(SystemExit):
                tracked_kinds({"tracked": {bad: "X"}})

    def test_index_is_reserved(self):
        with self.assertRaises(SystemExit):
            tracked_kinds({"tracked": {"index": "Index"}})

    def test_not_a_map(self):
        with self.assertRaises(SystemExit):
            tracked_kinds({"tracked": ["exercise"]})


class TrackedTyp(unittest.TestCase):
    def test_empty_is_typst_empty_dict(self):
        self.assertEqual(tracked_typ({}), "(:)")

    def test_dict_form(self):
        cfg = {"tracked": {"exercise": {"label": "Exercise"},
                           "figure": {"label": "Figure"}}}
        self.assertEqual(
            tracked_typ(cfg),
            '(exercise: (label: "Exercise"), figure: (label: "Figure"))')

    def test_string_shorthand(self):
        self.assertEqual(
            tracked_typ({"tracked": {"chart": "Chart"}}),
            '(chart: (label: "Chart"))')

    def test_label_defaults_to_capitalized_kind(self):
        # A bare (labelless) kind falls back to its capitalized name.
        self.assertEqual(
            tracked_typ({"tracked": {"table": None}}),
            '(table: (label: "Table"))')

    def test_label_with_quotes_is_escaped(self):
        out = tracked_typ({"tracked": {"figure": {"label": 'The "Big" One'}}})
        self.assertEqual(out, '(figure: (label: "The \\"Big\\" One"))')

    def test_bad_spec_rejected(self):
        with self.assertRaises(SystemExit):
            tracked_typ({"tracked": {"exercise": ["not", "a", "map"]}})


if __name__ == "__main__":
    unittest.main()
