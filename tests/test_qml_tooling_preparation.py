import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parent.parent / "scripts/metadata_profile.py"
MODULE = {"__name__": "metadata_wrapper_fixture", "__file__": str(SOURCE)}
exec(compile(SOURCE.read_text(), str(SOURCE), "exec"), MODULE)


class PreparationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name).resolve()
        self.source = self.root / "installed"
        self.source.mkdir()
        self.values = {
            "quickshell-core.qmltypes": b"core",
            "_Window/quickshell-window.qmltypes": b"window",
            "Wayland/_WlrLayerShell/quickshell-wayland-layershell.qmltypes": b"layer",
            "qmldir": b"module Quickshell\n",
        }
        for name, value in self.values.items():
            target = self.source / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(value)
        self.profile = {
            "name": "synthetic-boundary-fixture",
            "files": {
                name: hashlib.sha256(value).hexdigest()
                for name, value in self.values.items()
            },
            "cpp_header_provenance": {"fixture": True},
        }
        self.previous = {
            name: MODULE[name]
            for name in (
                "verify_packages",
                "load_profile",
                "resolve_core_closure",
                "INPUTS",
            )
        }
        MODULE["verify_packages"] = lambda: None
        MODULE["load_profile"] = lambda: self.profile
        MODULE["INPUTS"] = {
            name: (self.profile["files"][name], [])
            for name in self.values
            if name != "qmldir" and name != "quickshell-core.qmltypes"
        }
        MODULE["resolve_core_closure"] = lambda relative, value, core: (
            b"projected:" + value,
            [],
        )
        self.output = self.root / "prepared"

    def tearDown(self):
        for name, value in self.previous.items():
            MODULE[name] = value
        self.temporary.cleanup()

    def prepare(self):
        return MODULE["prepare_metadata"](self.source, self.output)

    def test_known_source_copied_and_installed_files_remain_exact(self):
        receipt = self.prepare()
        self.assertEqual(receipt["copied_files"], 4)
        self.assertFalse(receipt["installed_metadata_changed"])
        for name, data in self.values.items():
            self.assertEqual((self.source / name).read_bytes(), data)
            self.assertEqual(
                (self.output / "Quickshell" / name).read_bytes(),
                b"projected:" + data if name in MODULE["INPUTS"] else data,
            )
        self.assertEqual(
            json.loads((self.output / "receipt.json").read_text())["profile"],
            self.profile["name"],
        )

    def test_drift_rejected_before_output_creation(self):
        (self.source / "qmldir").write_text("changed")
        with self.assertRaisesRegex(ValueError, "differs"):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_extra_metadata_rejected(self):
        (self.source / "Extra.qml").write_text("Item {}")
        with self.assertRaisesRegex(ValueError, "differs"):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_missing_metadata_rejected(self):
        (self.source / "qmldir").unlink()
        with self.assertRaisesRegex(ValueError, "Incomplete"):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_dangling_metadata_symlink_rejected(self):
        (self.source / "Other.qml").symlink_to(self.root / "missing")
        with self.assertRaisesRegex(ValueError, "link"):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_existing_output_and_its_contents_preserved(self):
        self.output.mkdir()
        marker = self.output / "owned-elsewhere"
        marker.write_text("retain")
        with self.assertRaisesRegex(ValueError, "new directory"):
            self.prepare()
        self.assertEqual(marker.read_text(), "retain")

    def test_dangling_output_symlink_preserved(self):
        target = self.root / "unrelated"
        self.output.symlink_to(target)
        with self.assertRaisesRegex(ValueError, "new directory"):
            self.prepare()
        self.assertTrue(self.output.is_symlink())
        self.assertFalse(target.exists())

    def test_materialization_failure_cleans_only_new_owned_output(self):
        original = Path.write_bytes

        def fail(path, data):
            if path.is_relative_to(self.output):
                raise OSError("fixture disk full")
            return original(path, data)

        with (
            patch.object(Path, "write_bytes", fail),
            self.assertRaisesRegex(OSError, "disk full"),
        ):
            self.prepare()
        self.assertFalse(self.output.exists())
        self.assertEqual((self.source / "qmldir").read_bytes(), self.values["qmldir"])

    def test_source_descendant_output_rejected(self):
        self.output = self.source / "do-not-create"
        with self.assertRaisesRegex(ValueError, "separate"):
            self.prepare()
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
