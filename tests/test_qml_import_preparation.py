import hashlib
from pathlib import Path
import tempfile
import sys
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parent.parent / "scripts/prepare-qml-imports.py"
MODULE = {"__name__": "import_wrapper_fixture", "__file__": str(SOURCE)}
with patch.object(sys, "path", [str(SOURCE.parent), *sys.path]):
    exec(compile(SOURCE.read_text(), str(SOURCE), "exec"), MODULE)


class ImportPreparationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name).resolve()
        self.source = self.root / "original"
        self.source.mkdir()
        self.output = self.root / "prepared"
        names = ["Commons/Style.qml", "Commons/Color.qml"] + [
            "Components/File" + str(n) + ".qml" for n in range(52)
        ]
        names += ["assets/File" + str(n) + ".txt" for n in range(118)] + [
            "helpers/one.sh",
            "helpers/two.sh",
            "helpers/three.sh",
        ]
        self.values = {name: name.encode() for name in names}
        self.profile = {
            "revision": "fixture",
            "palette_upstream": "fixture",
            "files": {},
        }
        counts = {
            name: (37 if index == 53 else 4) for index, name in enumerate(names[:54])
        }
        self.palette = {}
        for name, value in self.values.items():
            path = self.source / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(value)
            executable = name.endswith(".sh")
            path.chmod(0o755 if executable else 0o644)
            after = b"palette:" + value if name in counts else value
            self.palette[value] = (after, counts.get(name, 0))
            self.profile["files"][name] = {
                "bytes": len(value),
                "mode": "100755" if executable else "100644",
                "sha256": hashlib.sha256(value).hexdigest(),
                "git_blob": hashlib.sha1(
                    b"blob " + str(len(value)).encode() + b"\0" + value
                ).hexdigest(),
                "palette_sha256": hashlib.sha256(after).hexdigest(),
                "palette_references": counts.get(name, 0),
            }
        self.previous = {
            name: MODULE[name] for name in ("load_profile", "qualify_palette", "refine")
        }
        MODULE["load_profile"] = lambda: self.profile
        MODULE["qualify_palette"] = lambda value, digest: self.palette[value]
        MODULE["refine"] = lambda name, value, digest: (
            b"named:" + value,
            [{}] * (3 if name == "Style.qml" else 8),
        )

    def tearDown(self):
        MODULE.update(self.previous)
        self.temporary.cleanup()

    def prepare(self):
        return MODULE["prepare"](self.source, self.output)

    def test_complete_source_and_executable_modes_are_preserved(self):
        receipt = self.prepare()
        self.assertEqual(
            (
                receipt["source_files"],
                receipt["palette_files"],
                receipt["palette_references"],
            ),
            (175, 54, 249),
        )
        self.assertEqual(sum(map(len, receipt["named_groups"].values())), 11)
        for name, value in self.values.items():
            self.assertEqual((self.source / name).read_bytes(), value)
            expected = self.palette[value][0]
            if name in ("Commons/Style.qml", "Commons/Color.qml"):
                expected = b"named:" + expected
            self.assertEqual((self.output / name).read_bytes(), expected)
            self.assertEqual(
                bool((self.output / name).stat().st_mode & 0o111), name.endswith(".sh")
            )

    def test_changed_source_rejected_before_output(self):
        (self.source / "Commons/Style.qml").write_bytes(b"wrong source")
        with self.assertRaisesRegex(ValueError, "differs"):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_missing_source_rejected(self):
        (self.source / "Commons/Style.qml").unlink()
        with self.assertRaisesRegex(ValueError, "incomplete"):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_extra_source_rejected(self):
        (self.source / "Extra.qml").write_bytes(b"new")
        with self.assertRaisesRegex(ValueError, "differs"):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_source_link_rejected(self):
        (self.source / "Extra.qml").symlink_to(self.root / "missing")
        with self.assertRaisesRegex(ValueError, "links"):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_executable_mode_drift_rejected(self):
        (self.source / "helpers/one.sh").chmod(0o644)
        with self.assertRaisesRegex(ValueError, "executable mode"):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_existing_output_is_preserved(self):
        self.output.mkdir()
        marker = self.output / "unrelated"
        marker.write_text("retain")
        with self.assertRaisesRegex(ValueError, "new output"):
            self.prepare()
        self.assertEqual(marker.read_text(), "retain")

    def test_source_descendant_output_rejected(self):
        self.output = self.source / "do-not-create"
        with self.assertRaisesRegex(ValueError, "separate"):
            self.prepare()
        self.assertFalse(self.output.exists())

    def test_failed_materialization_removes_only_owned_output(self):
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
        self.assertEqual(
            (self.source / "Commons/Style.qml").read_bytes(),
            self.values["Commons/Style.qml"],
        )

    def test_wrong_transform_output_rejected_before_creation(self):
        MODULE["qualify_palette"] = lambda value, digest: (b"unreviewed transform", 0)
        with self.assertRaisesRegex(ValueError, "Palette backport"):
            self.prepare()
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
