"""Exercise the lint entry point's real inventory, import layout and cleanup."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parent.parent


class QmlLintLayoutTests(unittest.TestCase):
    def run_linter(self, failure):
        with tempfile.TemporaryDirectory(prefix="privacy-lint-fixture-") as temporary:
            directory = Path(temporary).resolve()
            omarchy = directory / "omarchy"
            for module in ("Commons", "Ui"):
                target = omarchy / "shell" / module
                target.mkdir(parents=True)
                (target / "qmldir").write_text(f"module qs.{module}\n")
            receipt = directory / "receipt.json"
            linter = directory / "qmllint"
            linter.write_text(f"#!{sys.executable}\n" + r'''
import json
import os
from pathlib import Path
import sys
root = Path.cwd()
arguments = sys.argv[1:]
modules = [arguments[index + 1] for index, value in enumerate(arguments) if value == "-i"]
control = arguments[-1]
controls = {"Valid.qml": None, "MissingProperty.qml": ("thisPropertyCannotExist", "missing-property"),
            "MissingNested.qml": ("thisFontMemberCannotExist", "missing-property"),
            "MissingType.qml": ("ThisTypeCannotExist", "import")}
if control in controls:
    assert modules == [str(Path(os.environ["OMARCHY_PATH"]) / "shell" / module / "qmldir") for module in ("Commons", "Ui")]
    receipt = Path(os.environ["LINT_RECEIPT"])
    observed = json.loads(receipt.read_text())
    observed.setdefault("controls", []).append(control)
    receipt.write_text(json.dumps(observed))
    expected = controls[control]
    if expected is not None:
        assert expected[0] in (root / control).read_text()
        print(expected[0] + " [" + expected[1] + "]", file=sys.stderr)
        sys.exit(255)
    sys.exit(0)
assert modules == [str(Path(os.environ["OMARCHY_PATH"]) / "shell" / module / "qmldir") for module in ("Commons", "Ui")] + [str(root / "qmldir")]
assert (root / "Model.js").is_file()
assert (root / "Service.qml").is_file()
assert (root / ".qmllint.ini").is_file()
targets = [value for value in arguments if value.endswith(".qml")]
assert all((root / target).is_file() for target in targets)
assert all("tests/qml/" not in target for target in targets)
Path(os.environ["LINT_RECEIPT"]).write_text(json.dumps({"cwd": str(root), "targets": targets}))
sys.exit(int(os.environ["LINT_FAILURE"]))
''')
            linter.chmod(0o755)
            environment = os.environ.copy()
            # This fixture owns its complete import tree. Prepared imports from
            # with-qml-imports.sh must not override the fake Omarchy shell.
            for name in ("OMARCHY_SHELL_ROOT", "QML_TOOLING_IMPORT_ROOT", "QML_IMPORT_PATH", "QML2_IMPORT_PATH"):
                environment.pop(name, None)
            environment.update({"QMLLINT": str(linter), "OMARCHY_PATH": str(omarchy),
                                "LINT_RECEIPT": str(receipt), "LINT_FAILURE": str(failure),
                                "TMPDIR": str(directory)})
            result = subprocess.run([str(ROOT / "scripts/lint-qml")], env=environment,
                                    text=True, capture_output=True, check=False)
            self.assertEqual(result.returncode, failure, result.stderr)
            observed = json.loads(receipt.read_text())
            expected = sorted(["./" + path.name for path in ROOT.glob("*.qml")] +
                              ["./tests/qml/" + path.name for path in (ROOT / "tests/qml").glob("*.qml")])
            self.assertEqual(observed["targets"], [Path(path).name if path.startswith("./tests/") else path for path in expected])
            self.assertEqual(observed.get("controls", []), [] if failure else
                             ["Valid.qml", "MissingProperty.qml", "MissingNested.qml", "MissingType.qml"])
            self.assertFalse(Path(observed["cwd"]).exists(), "owned staging directory survives lint completion")

    def test_runtime_import_layout_and_sorted_complete_inventory(self):
        self.run_linter(0)

    def test_linter_failure_propagates_and_cleans_owned_staging(self):
        self.run_linter(37)

    def test_parent_prepared_imports_do_not_escape_into_fixture(self):
        with patch.dict(os.environ, {
            "OMARCHY_SHELL_ROOT": "/unrelated/prepared/shell",
            "QML_TOOLING_IMPORT_ROOT": "/unrelated/prepared/tooling",
            "QML_IMPORT_PATH": "/unrelated/prepared/imports",
            "QML2_IMPORT_PATH": "/unrelated/prepared/imports",
        }):
            self.run_linter(0)
