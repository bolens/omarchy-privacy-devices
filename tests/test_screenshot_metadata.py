import importlib.util
from importlib.machinery import SourceFileLoader
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
            html.write_text('<img src="bar.png" alt="Bar" width="99" height="99">\n')

            MODULE.update(html, root)

            self.assertEqual(html.read_text(), '<img src="bar.png" alt="Bar" width="173" height="50">\n')

    def test_rejects_missing_referenced_asset(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            html = root / "index.html"
            html.write_text('<img src="missing.png" width="1" height="1">')

            with self.assertRaisesRegex(ValueError, "missing screenshot asset"):
                MODULE.update(html, root)


if __name__ == "__main__":
    unittest.main()
