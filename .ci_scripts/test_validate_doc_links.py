#!/usr/bin/env python3
"""Offline unit tests for validate_doc_links.py."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import validate_doc_links


class SlugifyTest(unittest.TestCase):
    """Heading text to anchor slug conversion."""

    def test_lowercases_and_hyphenates(self) -> None:
        self.assertEqual(validate_doc_links.slugify("Quick Start"), "quick-start")

    def test_strips_code_spans_and_punctuation(self) -> None:
        self.assertEqual(validate_doc_links.slugify("`just ci` Must Pass!"), "just-ci-must-pass")

    def test_keeps_link_text_only(self) -> None:
        self.assertEqual(validate_doc_links.slugify("[Skills](skills/README.md)"), "skills")


class LinkValidationTest(unittest.TestCase):
    """Link and anchor resolution against a temporary document tree."""

    def setUp(self) -> None:
        self._tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self._tempdir.name).resolve()
        self.addCleanup(self._tempdir.cleanup)

    def write(self, relative: str, text: str) -> Path:
        """Write a document into the temporary tree and return its path."""
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        return path

    def check(self, source: Path, target: str) -> str | None:
        """Validate a single link from the given source document."""
        return validate_doc_links.validate_link(source, self.root, target, {})

    def test_existing_file_link_passes(self) -> None:
        source = self.write("README.md", "# Root\n")
        self.write("docs/README.md", "# Docs\n")
        self.assertIsNone(self.check(source, "docs/README.md"))

    def test_missing_file_link_fails(self) -> None:
        source = self.write("README.md", "# Root\n")
        self.assertIn("does not exist", self.check(source, "docs/missing.md") or "")

    def test_known_anchor_passes(self) -> None:
        source = self.write("README.md", "# Root\n\n## Quick Start\n\nText.\n")
        self.assertIsNone(self.check(source, "#quick-start"))

    def test_unknown_anchor_fails(self) -> None:
        source = self.write("README.md", "# Root\n\n## Quick Start\n\nText.\n")
        self.assertIn("not found", self.check(source, "#slow-start") or "")

    def test_html_anchor_is_recognized(self) -> None:
        source = self.write("README.md", '# Root\n\n<a id="custom-anchor"></a>\n\nText.\n')
        self.assertIsNone(self.check(source, "#custom-anchor"))

    def test_anchor_inside_code_fence_is_ignored(self) -> None:
        source = self.write("README.md", "# Root\n\n```markdown\n## Fenced Heading\n```\n")
        self.assertIn("not found", self.check(source, "#fenced-heading") or "")

    def test_duplicate_headings_get_numbered_anchors(self) -> None:
        source = self.write("README.md", "# Root\n\n## Notes\n\na\n\n## Notes\n\nb\n")
        self.assertIsNone(self.check(source, "#notes"))
        self.assertIsNone(self.check(source, "#notes-1"))

    def test_directory_link_with_anchor_fails(self) -> None:
        source = self.write("README.md", "# Root\n")
        (self.root / "skills").mkdir()
        self.assertIn("directory link", self.check(source, "skills#anchor") or "")

    def test_external_links_are_not_extracted(self) -> None:
        source = self.write("README.md", "# Root\n\n[site](https://example.com/missing)\n")
        self.assertEqual(validate_doc_links.extract_links(source), [])

    def test_links_inside_code_fences_are_not_extracted(self) -> None:
        source = self.write("README.md", "# Root\n\n```text\n[broken](nope.md)\n```\n")
        self.assertEqual(validate_doc_links.extract_links(source), [])


if __name__ == "__main__":
    unittest.main()
