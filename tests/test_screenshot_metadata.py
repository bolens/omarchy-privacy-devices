import importlib.util
from importlib.machinery import SourceFileLoader
import hashlib
import struct
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "scripts" / "update-screenshot-metadata"
SPEC = importlib.util.spec_from_loader("screenshot_metadata", SourceFileLoader("screenshot_metadata", str(SCRIPT)))
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ScreenshotMetadataTests(unittest.TestCase):
    def test_updates_dimensions_from_png_header(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "bar.png").write_bytes(MODULE.PNG_SIGNATURE + b"\0\0\0\rIHDR" + struct.pack(">II", 173, 50))
            html = root / "index.html"
            html.write_text(
                '<img src="bar.png" alt="Bar" width="99" height="99">\n'
                '<img src="bar.png" alt="Bar detail" width="1" height="2">\n'
            )

            MODULE.update(html, root)

            self.assertEqual(
                html.read_text(),
                '<img src="bar.png" alt="Bar" width="173" height="50">\n'
                '<img src="bar.png" alt="Bar detail" width="173" height="50">\n',
            )

    def test_rejects_missing_referenced_asset(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            html = root / "index.html"
            html.write_text('<img src="missing.png" width="1" height="1">')

            with self.assertRaisesRegex(ValueError, "missing screenshot asset"):
                MODULE.update(html, root)

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
