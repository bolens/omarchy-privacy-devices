import importlib.machinery
import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOADER = importlib.machinery.SourceFileLoader("privacy_menu_entry", str(ROOT / "privacy-menu-entry"))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


class MenuEntryTests(unittest.TestCase):
    def test_install_is_owned_idempotent_and_removable(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "omarchy-menu.jsonc"
            path.write_text('{\n  "existing": {"label":"Keep me"}\n}\n')
            helper = Path("/fixed/privacy-action")
            self.assertEqual(MODULE.update("install", path, helper), "installed")
            once = path.read_text()
            self.assertIn('"privacy-lockdown"', once)
            self.assertIn('/fixed/privacy-action lockdown', once)
            self.assertIn('"existing"', once)
            MODULE.update("install", path, helper)
            self.assertEqual(path.read_text(), once)
            MODULE.update("remove", path, helper)
            removed = path.read_text()
            self.assertNotIn(MODULE.START, removed)
            self.assertIn('"existing"', removed)


if __name__ == "__main__":
    unittest.main()
