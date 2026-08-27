import importlib.util
from importlib.machinery import SourceFileLoader
import hashlib
import struct
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "update-screenshot-metadata"
ROOT = Path(__file__).parents[1]
SPEC = importlib.util.spec_from_loader("screenshot_metadata", SourceFileLoader("screenshot_metadata", str(SCRIPT)))
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ScreenshotMetadataTests(unittest.TestCase):
    def test_published_views_are_distinct_except_preview_mirror(self):
        assets = [ROOT / "preview.png", *sorted((ROOT / "docs").glob("*.png"))]
        by_digest = {}
        for asset in assets:
            digest = hashlib.sha256(asset.read_bytes()).hexdigest()
            by_digest.setdefault(digest, []).append(asset.relative_to(ROOT).as_posix())
        duplicates = [paths for paths in by_digest.values() if len(paths) > 1]
        self.assertEqual(duplicates, [["preview.png", "docs/preview.png"]],
                         "only the intentional marketplace/site preview mirror may repeat")

    def test_updates_one_dimensioned_reference_from_png_header(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "bar.png").write_bytes(MODULE.PNG_SIGNATURE + b"\0\0\0\rIHDR" + struct.pack(">II", 173, 50))
            html = root / "index.html"
            html.write_text(
                '<img src="bar.png" alt="Bar" width="99" height="99">\n'
            )

            MODULE.update(html, root)

            self.assertEqual(
                html.read_text(),
                '<img src="bar.png" alt="Bar" width="173" height="50">\n',
            )

    def test_rejects_duplicate_dimensioned_references(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "bar.png").write_bytes(MODULE.PNG_SIGNATURE + b"\0\0\0\rIHDR" + struct.pack(">II", 173, 50))
            html = root / "index.html"
            html.write_text(
                '<img src="bar.png" alt="Bar" width="99" height="99">\n'
                '<img src="bar.png" alt="Duplicate" width="1" height="2">\n'
            )

            with self.assertRaisesRegex(ValueError, "expected one dimensioned image element"):
                MODULE.update(html, root)

    def test_rejects_missing_referenced_asset(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            html = root / "index.html"
            html.write_text('<img src="missing.png" width="1" height="1">')

            with self.assertRaisesRegex(ValueError, "missing screenshot asset"):
                MODULE.update(html, root)

    def test_rejects_invalid_or_zero_sized_png_headers(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            invalid = root / "invalid.png"
            invalid.write_bytes(b"not a png")
            with self.assertRaisesRegex(ValueError, "not a PNG"):
                MODULE.png_dimensions(invalid)
            zero = root / "zero.png"
            zero.write_bytes(MODULE.PNG_SIGNATURE + b"\0\0\0\rIHDR" + struct.pack(">II", 0, 50))
            with self.assertRaisesRegex(ValueError, "invalid PNG dimensions"):
                MODULE.png_dimensions(zero)

    def test_content_addresses_readme_images_and_replaces_stale_tokens(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            docs = root / "docs"
            docs.mkdir()
            preview = root / "preview.png"
            settings = docs / "general.png"
            preview.write_bytes(b"fresh preview")
            settings.write_bytes(b"fresh settings")
            readme = root / "README.md"
            readme.write_text(
                "![Preview](preview.png)\n"
                '<img src="docs/general.png?v=000000000000" alt="General">\n'
            )

            MODULE.update_readme(readme)

            preview_hash = hashlib.sha256(preview.read_bytes()).hexdigest()[:12]
            settings_hash = hashlib.sha256(settings.read_bytes()).hexdigest()[:12]
            self.assertEqual(
                readme.read_text(),
                f"![Preview](preview.png?v={preview_hash})\n"
                f'<img src="docs/general.png?v={settings_hash}" alt="General">\n',
            )


if __name__ == "__main__":
    unittest.main()
