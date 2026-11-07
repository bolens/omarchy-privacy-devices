"""Behavior controls for the native repository document gate; no network."""
import contextlib
import importlib.util
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("repository_documents", ROOT / "scripts/check-repository-documents.py")
DOCS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DOCS)


class Contracts(unittest.TestCase):
    def result(self, code, output=""):
        return subprocess.CompletedProcess(["tidy"], code, "", output)

    def test_warning_is_accepted_but_error_and_execution_failure_are_not(self):
        for code in (0, 1):
            with contextlib.redirect_stdout(io.StringIO()):
                DOCS.check_tidy(lambda *args, **kwargs: self.result(code, "Warning: optional hint"))
        for code, output in [(0, "Error: invalid HTML"), (1, "Error: invalid HTML"), (2, ""), (127, ""), (-9, "")]:
            with self.subTest(code=code, output=output), self.assertRaises(RuntimeError), contextlib.redirect_stdout(io.StringIO()):
                DOCS.check_tidy(lambda *args, **kwargs: self.result(code, output))

    def test_missing_built_site_fails_before_any_validator(self):
        with tempfile.TemporaryDirectory() as temporary, patch.object(DOCS, "Path", return_value=Path(temporary) / "absent"):
            with self.assertRaises(RuntimeError):
                DOCS.check_documents("omarchy-app-drawer", run=lambda *a, **k: self.fail("unexpected validator"))

    def test_xml_and_link_failures_propagate(self):
        for failure in ("xmllint", "lychee"):
            calls = []
            def run(command, **kwargs):
                calls.append(command[0])
                if command[0] == failure:
                    raise subprocess.CalledProcessError(1, command)
                return self.result(0)
            with patch.object(Path, "is_file", return_value=True), self.assertRaises(subprocess.CalledProcessError):
                DOCS.check_documents("omarchy-app-drawer", run=run)
            self.assertEqual(calls[-1], failure)

    def test_links_keep_repository_specific_trust_boundaries(self):
        command = DOCS.link_command("omarchy-app-drawer", "lychee")
        self.assertIn("200,204,206,429", command)
        self.assertIn("./**/*.md", command)
        self.assertIn("./_site/**/*.html", command)
        self.assertIn("(^|/)node_modules/", command)
        self.assertTrue(any("(compare|releases/tag)" in value for value in command))
        privacy = DOCS.link_command("omarchy-privacy-devices", "lychee")
        self.assertTrue(any("/compare/" in value for value in privacy))
        self.assertFalse(any("releases/tag" in value for value in privacy))
        with self.assertRaises(ValueError):
            DOCS.link_command("foreign-repository", "lychee")


if __name__ == "__main__":
    unittest.main()
