import contextlib
import io
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parent.parent / "scripts/check-qml-lint-controls.py"
MODULE = {"__name__": "control_fixture", "__file__": str(SOURCE)}
exec(compile(SOURCE.read_text(), str(SOURCE), "exec"), MODULE)


class ControlTests(unittest.TestCase):
    def run_controls(self, mode="expected", weaken_policy=False):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for module in ("Commons", "Ui"):
                (root / module).mkdir()
                (root / module / "qmldir").write_text("module qs." + module + "\n")
            policy = root / ".qmllint.ini"
            policy.write_text(
                "[General]\nMaxWarnings="
                + ("-1" if weaken_policy else "0")
                + "\n[Warnings]\n"
                + "".join(key + "=error\n" for key in MODULE["CRITICAL"])
            )
            observed = []

            def fake(argv, **kwargs):
                cwd = kwargs["cwd"]
                self.assertEqual(
                    (cwd / ".qmllint.ini").read_bytes(), policy.read_bytes()
                )
                self.assertEqual(
                    argv[1:7],
                    [
                        "-I",
                        str(root),
                        "-i",
                        str(root / "Commons/qmldir"),
                        "-i",
                        str(root / "Ui/qmldir"),
                    ],
                )
                self.assertTrue((cwd / argv[-1]).is_file())
                observed.append(cwd)
                case = next(row for row in MODULE["CASES"] if row[0] == argv[-1])
                if mode == "green":
                    return SimpleNamespace(returncode=0, stdout="", stderr="")
                if (
                    mode == "unrelated"
                    or mode == "negative_unrelated"
                    and case[2] is not None
                ):
                    return SimpleNamespace(
                        returncode=255, stdout="", stderr="tool crashed"
                    )
                return SimpleNamespace(
                    returncode=0 if case[2] is None else 255,
                    stdout="",
                    stderr="" if case[2] is None else case[2] + " [" + case[3][0] + "]",
                )

            with (
                patch.object(MODULE["subprocess"], "run", side_effect=fake),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                try:
                    MODULE["check_controls"](Path("/fixture/qmllint"), root, policy)
                finally:
                    self.assertTrue(
                        all(not path.exists() for path in observed),
                        "owned control source directory leaked",
                    )
            return len(observed)

    def test_actual_policy_and_import_arguments_accept_four_controls(self):
        self.assertEqual(self.run_controls(), 4)

    def test_linter_accepting_invalid_input_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "did not reject"):
            self.run_controls("green")

    def test_tool_failure_is_not_mistaken_for_a_negative_control(self):
        with self.assertRaisesRegex(ValueError, "supported nested font"):
            self.run_controls("unrelated")

    def test_unrelated_negative_failure_is_not_accepted(self):
        with self.assertRaisesRegex(ValueError, "did not reject"):
            self.run_controls("negative_unrelated")

    def test_weakened_warning_budget_is_rejected_before_tool_execution(self):
        with self.assertRaisesRegex(ValueError, "every warning"):
            self.run_controls(weaken_policy=True)


if __name__ == "__main__":
    unittest.main()
