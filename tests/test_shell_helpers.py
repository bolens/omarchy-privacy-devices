import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


class ShellHelperTests(unittest.TestCase):
    def environment(self, directory: Path, commands: dict[str, str] | None = None):
        fake_bin = directory / "bin"
        fake_bin.mkdir()
        for name, body in (commands or {}).items():
            command = fake_bin / name
            command.write_text("#!/bin/sh\nset -eu\n" + body + "\n")
            command.chmod(0o755)
        environment = os.environ.copy()
        environment.update({
            "PATH": f"{fake_bin}:/usr/bin:/bin",
            "HOME": str(directory / "home"),
            "TEST_LOG": str(directory / "calls.log"),
        })
        return environment

    def run_helper(self, name: str, *arguments: str, environment: dict[str, str]):
        return subprocess.run(
            [str(ROOT / name), *arguments], env=environment,
            text=True, capture_output=True, check=False,
        )

    def test_dependency_checks_enforce_backend_requirements(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            environment = self.environment(directory, {"pactl": "exit 0", "grim": "exit 0"})
            environment["PATH"] = str(directory / "bin")
            self.assertEqual(self.run_helper("privacy-deps", "check", "microphone", "omarchy", "auto", "omarchy", environment=environment).returncode, 0)
            self.assertNotEqual(self.run_helper("privacy-deps", "check", "microphone", "omarchy", "unknown", "omarchy", environment=environment).returncode, 0)
            self.assertNotEqual(self.run_helper("privacy-deps", "check", "screenshot", "omarchy", "auto", "grim", environment=environment).returncode, 0, "grim also requires slurp")

    def test_dependency_install_uses_fixed_package_allowlist(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            environment = self.environment(directory, {"omarchy": "printf '%s\\n' \"$*\" >\"$TEST_LOG\""})
            result = self.run_helper("privacy-deps", "install", "screen-recording", "wf-recorder", "auto", "omarchy", environment=environment)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((directory / "calls.log").read_text().strip(), "pkg add wf-recorder slurp")
            self.assertEqual(self.run_helper("privacy-deps", "install", "screen-recording", "unknown", "auto", "omarchy", environment=environment).returncode, 2)

    def test_screen_share_status_and_toggle_preserve_exit_protocol(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            environment = self.environment(directory, {
                "systemctl": "printf '%s\\n' \"$*\" >>\"$TEST_LOG\"; case \"$*\" in *is-enabled*) printf 'masked-runtime\\n';; esac",
            })
            status = self.run_helper("privacy-control", "status", "screen-share", environment=environment)
            self.assertEqual(status.returncode, 11, "masked controls use exit 11")
            toggled = self.run_helper("privacy-control", "toggle", "screen-share", environment=environment)
            self.assertEqual(toggled.returncode, 0, toggled.stderr)
            calls = (directory / "calls.log").read_text()
            self.assertIn("--user unmask --runtime xdg-desktop-portal-hyprland.service", calls)
            self.assertIn("--user start xdg-desktop-portal-hyprland.service", calls)

    def test_grim_capture_routes_geometry_output_and_clipboard(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            pictures = directory / "pictures"
            environment = self.environment(directory, {
                "slurp": "printf '10,20 300x200\\n'",
                "grim": "printf '%s\\n' \"$*\" >\"$TEST_LOG\"; for last do :; done; touch \"$last\"",
                "wl-copy": "printf 'clipboard:%s\\n' \"$*\" >>\"$TEST_LOG\"; cat >/dev/null",
            })
            environment["XDG_PICTURES_DIR"] = str(pictures)
            result = self.run_helper("privacy-screenshot", "capture", "grim", environment=environment)
            self.assertEqual(result.returncode, 0, result.stderr)
            captures = list(pictures.glob("screenshot-*.png"))
            self.assertEqual(len(captures), 1)
            calls = (directory / "calls.log").read_text()
            self.assertIn("-g 10,20 300x200", calls)
            self.assertIn("clipboard:--type image/png", calls)

    def test_screenshot_cancellation_creates_no_file(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            pictures = directory / "pictures"
            environment = self.environment(directory, {"slurp": "exit 1", "grim": "exit 99"})
            environment["XDG_PICTURES_DIR"] = str(pictures)
            result = self.run_helper("privacy-screenshot", "capture", "grim", environment=environment)
            self.assertEqual(result.returncode, 0)
            self.assertEqual(list(pictures.glob("*.png")), [])

    def test_recorder_rejects_unsafe_runtime_directories(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            unsafe = directory / "runtime"
            unsafe.mkdir(mode=0o755)
            environment = self.environment(directory)
            environment["XDG_RUNTIME_DIR"] = str(unsafe)
            self.assertEqual(self.run_helper("privacy-recording", "start", "wf-recorder", environment=environment).returncode, 2)
            environment["XDG_RUNTIME_DIR"] = "relative/runtime"
            self.assertEqual(self.run_helper("privacy-recording", "stop", "wf-recorder", environment=environment).returncode, 2)


if __name__ == "__main__":
    unittest.main()
