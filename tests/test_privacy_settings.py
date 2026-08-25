import importlib.machinery
import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOADER = importlib.machinery.SourceFileLoader("privacy_settings", str(ROOT / "privacy-settings"))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


class SettingsTransferTests(unittest.TestCase):
    def test_atomic_private_round_trip(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "settings.json"
            MODULE.export_settings('{"_privacySettingsVersion":1,"showIdle":false}', target)
            self.assertEqual(MODULE.import_settings(target)["showIdle"], False)
            self.assertEqual(target.stat().st_mode & 0o777, 0o600)
            self.assertEqual(list(target.parent.glob(".settings-*")), [])

    def test_rejects_unknown_version_and_oversize(self):
        with self.assertRaises(ValueError): MODULE.validated("{}")
        with self.assertRaises(ValueError): MODULE.validated("[]")
        with self.assertRaises(ValueError): MODULE.validated("not-json")
        with self.assertRaises(ValueError): MODULE.validated('{"_privacySettingsVersion":1,"value":NaN}')
        with self.assertRaises(ValueError): MODULE.validated('{"_privacySettingsVersion":1,"x":"' + "x" * MODULE.MAX_BYTES + '"}')

    def test_import_bounds_file_read(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "settings.json"
            target.write_text("x" * (MODULE.MAX_BYTES + 1))
            with self.assertRaises(ValueError):
                MODULE.import_settings(target)


if __name__ == "__main__": unittest.main()
