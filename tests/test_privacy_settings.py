import importlib.machinery
import importlib.util
import json
import os
import subprocess
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

    def test_import_preserves_one_private_undo_snapshot(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            exported = root / "settings-export.json"
            undo = root / "settings-undo.json"
            MODULE.export_settings('{"_privacySettingsVersion":1,"showIdle":false}', exported)

            imported = MODULE.import_with_undo(
                '{"_privacySettingsVersion":1,"showIdle":true}', exported, undo
            )

            self.assertFalse(imported["showIdle"])
            self.assertEqual(MODULE.undo_settings(undo)["showIdle"], True)
            self.assertFalse(undo.exists(), "undo must be one-step after successful consumption")
            self.assertEqual(undo.parent.stat().st_mode & 0o777, 0o700)

    def test_failed_import_does_not_replace_existing_undo(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            exported = root / "settings-export.json"
            undo = root / "settings-undo.json"
            MODULE.export_settings('{"_privacySettingsVersion":1,"showIdle":true}', undo)
            exported.write_text("invalid")

            with self.assertRaises(ValueError):
                MODULE.import_with_undo('{"_privacySettingsVersion":1,"showIdle":false}', exported, undo)

            self.assertTrue(MODULE.import_settings(undo)["showIdle"])

    def test_checkpoint_supports_undo_after_reset(self):
        with tempfile.TemporaryDirectory() as directory:
            undo = Path(directory) / "settings-undo.json"
            MODULE.checkpoint_settings('{"_privacySettingsVersion":1,"popupMaxHeight":740}', undo)
            self.assertEqual(MODULE.undo_settings(undo)["popupMaxHeight"], 740)

    def test_cli_export_import_checkpoint_and_undo_lifecycle(self):
        with tempfile.TemporaryDirectory() as directory:
            environment = dict(os.environ, XDG_DATA_HOME=directory)
            current = '{"_privacySettingsVersion":1,"showIdle":true}'
            incoming = '{"_privacySettingsVersion":1,"showIdle":false}'
            exported = subprocess.run([str(ROOT / "privacy-settings"), "export", incoming], env=environment, text=True, capture_output=True)
            self.assertEqual(exported.returncode, 0, exported.stderr)
            imported = subprocess.run([str(ROOT / "privacy-settings"), "import", current], env=environment, text=True, capture_output=True)
            self.assertEqual(json.loads(imported.stdout)["showIdle"], False)
            can_undo = subprocess.run([str(ROOT / "privacy-settings"), "can-undo"], env=environment, text=True, capture_output=True)
            self.assertEqual((can_undo.returncode, can_undo.stdout.strip()), (0, "true"))
            undone = subprocess.run([str(ROOT / "privacy-settings"), "undo"], env=environment, text=True, capture_output=True)
            self.assertEqual(json.loads(undone.stdout)["showIdle"], True)
            self.assertEqual(subprocess.run([str(ROOT / "privacy-settings"), "can-undo"], env=environment, capture_output=True).returncode, 1)

            checkpoint = subprocess.run([str(ROOT / "privacy-settings"), "checkpoint", current], env=environment, text=True, capture_output=True)
            self.assertEqual(checkpoint.returncode, 0, checkpoint.stderr)
            self.assertEqual(subprocess.run([str(ROOT / "privacy-settings"), "can-undo"], env=environment, capture_output=True).returncode, 0)


if __name__ == "__main__": unittest.main()
