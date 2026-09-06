"""CLI contracts for local development image adapters."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("development_container", Path(__file__).resolve().parents[1] / "scripts" / "development-container.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class DevelopmentContainerTests(unittest.TestCase):
    def test_preserves_command_arguments_and_checkout_spaces(self):
        for engine in ("docker", "podman", "apple"):
            with self.subTest(engine=engine):
                args = ["python3", "-c", "print('$HOME; a b')"]
                cmd = MODULE.command(engine, "run", Path("/tmp/repo with spaces"), args)
                self.assertEqual(cmd[-3:], args)
                self.assertIn("type=bind,source=/tmp/repo with spaces,target=/workspace", cmd)
                self.assertNotIn("--tty", cmd)

    def test_podman_preserves_user_mapping(self):
        self.assertIn("--userns=keep-id", MODULE.command("podman", "run", Path("/tmp/repo")))
        self.assertNotIn("--userns=keep-id", MODULE.command("docker", "run", Path("/tmp/repo")))

    def test_engine_archive_loading(self):
        for engine in ("docker", "podman", "apple"):
            cmd = MODULE.command(engine, "load", Path("/tmp/repo"))
            self.assertEqual(cmd[0], "container" if engine == "apple" else engine)
            self.assertEqual(cmd[1:4], ["image", "load", "--input"])

    @patch.object(MODULE.shutil, "which", return_value="/fixture/docker")
    @patch.object(MODULE.subprocess, "run")
    def test_child_failure_is_returned(self, run, _which):
        run.return_value.returncode = 19
        self.assertEqual(MODULE.main(["run", "docker", "--", "false"]), 19)

    @patch.object(MODULE.shutil, "which", return_value=None)
    def test_missing_engine_fails_before_running(self, _which):
        with self.assertRaises(SystemExit) as result:
            MODULE.main(["run", "docker"])
        self.assertEqual(result.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
