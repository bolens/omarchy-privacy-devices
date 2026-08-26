import os
import subprocess
import tempfile
import time
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

    def test_action_helper_rejects_untrusted_actions_before_ipc(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            environment = self.environment(directory, {"qs": "printf 'called\\n' >\"$TEST_LOG\""})
            result = self.run_helper("privacy-action", "open-activity", "../../camera", environment=environment)
            self.assertEqual(result.returncode, 2)
            self.assertFalse((directory / "calls.log").exists())

    def test_action_helper_skips_invalid_and_unavailable_shells(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            environment = self.environment(directory, {"qs": """
case "$1" in
  list) printf 'Process ID: nope\\nProcess ID: 101\\nProcess ID: 202\\nProcess ID: 303\\n' ;;
  ipc)
    printf '%s\\n' "$*" >>"$TEST_LOG"
    case "$3:$5:$6" in
      101:shell:ping) exit 1 ;;
      202:shell:ping|303:shell:ping) printf 'ok\\n' ;;
      202:privacy-devices:action) printf 'unavailable\\n' ;;
      303:privacy-devices:action) printf 'activity\\n' ;;
    esac
    ;;
esac
"""})
            result = self.run_helper("privacy-action", "open-activity", "camera", environment=environment)
            self.assertEqual(result.returncode, 0, result.stderr)
            calls = (directory / "calls.log").read_text()
            self.assertNotIn("--pid nope", calls)
            self.assertNotIn("--pid 101 call privacy-devices", calls)
            self.assertIn("--pid 202 call privacy-devices action open-activity camera", calls)
            self.assertIn("--pid 303 call privacy-devices action open-activity camera", calls)

    def test_action_helper_reports_no_usable_shell(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            environment = self.environment(directory, {"qs": "case \"$1\" in list) printf 'Process ID: 91\\n';; ipc) printf 'unavailable\\n';; esac"})
            self.assertEqual(
                self.run_helper("privacy-action", "open-diagnostics", environment=environment).returncode,
                1,
            )

    def test_dependency_install_uses_fixed_package_allowlist(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            environment = self.environment(directory, {"omarchy": "printf '%s\\n' \"$*\" >\"$TEST_LOG\""})
            result = self.run_helper("privacy-deps", "install", "screen-recording", "wf-recorder", "auto", "omarchy", environment=environment)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((directory / "calls.log").read_text().strip(), "pkg add wf-recorder slurp")
            self.assertEqual(self.run_helper("privacy-deps", "install", "screen-recording", "unknown", "auto", "omarchy", environment=environment).returncode, 2)

    def test_dependency_install_matrix_uses_only_declared_packages(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            environment = self.environment(directory, {"omarchy": "printf '%s\\n' \"$*\" >\"$TEST_LOG\""})
            cases = [
                (("microphone", "omarchy", "auto", "omarchy"), "pkg add libpulse"),
                (("audio-output", "omarchy", "wpctl", "omarchy"), "pkg add wireplumber"),
                (("camera", "omarchy", "auto", "omarchy"), "pkg add polkit"),
                (("location", "omarchy", "auto", "omarchy"), "pkg add geoclue polkit"),
                (("screen-share", "omarchy", "auto", "omarchy"), "pkg add xdg-desktop-portal-hyprland"),
                (("screenshot", "omarchy", "auto", "grim-satty"), "pkg add grim slurp satty wl-clipboard"),
                (("screenshot", "omarchy", "auto", "hyprshot"), "pkg add hyprshot"),
                (("screenshot", "omarchy", "auto", "flameshot"), "pkg add flameshot grim xdg-desktop-portal-hyprland"),
                (("screen-recording", "gpu-screen-recorder", "auto", "omarchy"), "pkg add gpu-screen-recorder"),
            ]
            for arguments, expected in cases:
                with self.subTest(arguments=arguments):
                    (directory / "calls.log").unlink(missing_ok=True)
                    result = self.run_helper("privacy-deps", "install", *arguments, environment=environment)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual((directory / "calls.log").read_text().strip(), expected)
            (directory / "calls.log").unlink(missing_ok=True)
            custom = self.run_helper("privacy-deps", "install", "screenshot", "omarchy", "auto", "custom", environment=environment)
            self.assertEqual(custom.returncode, 0)
            self.assertIn("provider", custom.stdout)
            self.assertFalse((directory / "calls.log").exists())

    def test_dependency_checks_cover_audio_and_capture_backend_matrices(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            commands = {name: "exit 0" for name in ("pactl", "wpctl", "grim", "slurp", "satty", "wl-copy", "hyprshot", "omarchy-capture-screenshot", "wf-recorder", "gpu-screen-recorder", "omarchy-capture-screenrecording")}
            environment = self.environment(directory, commands)
            environment["PATH"] = str(directory / "bin")
            cases = [
                ("microphone", "omarchy", "auto", "omarchy"),
                ("audio-output", "omarchy", "pactl", "omarchy"),
                ("microphone", "omarchy", "wpctl", "omarchy"),
                ("screenshot", "omarchy", "auto", "omarchy"),
                ("screenshot", "omarchy", "auto", "grim"),
                ("screenshot", "omarchy", "auto", "grim-satty"),
                ("screenshot", "omarchy", "auto", "hyprshot"),
                ("screen-recording", "omarchy", "auto", "omarchy"),
                ("screen-recording", "gpu-screen-recorder", "auto", "omarchy"),
                ("screen-recording", "wf-recorder", "auto", "omarchy"),
                ("screen-recording", "custom", "auto", "omarchy"),
            ]
            for kind, backend, audio_backend, screenshot_backend in cases:
                with self.subTest(kind=kind, backend=backend, audio=audio_backend, screenshot=screenshot_backend):
                    result = self.run_helper("privacy-deps", "check", kind, backend, audio_backend, screenshot_backend, environment=environment)
                    self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(self.run_helper("privacy-deps", "check", "microphone", "omarchy", "invalid", "omarchy", environment=environment).returncode, 1)
            self.assertEqual(self.run_helper("privacy-deps", "check", "screenshot", "omarchy", "auto", "invalid", environment=environment).returncode, 1)

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

    def test_location_toggle_routes_privilege_to_fixed_systemctl_arguments(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            environment = self.environment(directory, {
                "systemctl": "printf 'masked-runtime\\n'",
                "pkexec": "printf '%s\\n' \"$*\" >>\"$TEST_LOG\"",
            })
            result = self.run_helper("privacy-control", "toggle", "location", environment=environment)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((directory / "calls.log").read_text().splitlines(), [
                "/usr/bin/systemctl unmask --runtime geoclue.service",
                "/usr/bin/systemctl start geoclue.service",
            ])

            (directory / "calls.log").unlink()
            second = directory / "second"
            second.mkdir()
            environment = self.environment(second, {
                "systemctl": "printf 'enabled\\n'",
                "pkexec": "printf '%s\\n' \"$*\" >>\"$TEST_LOG\"",
            })
            result = self.run_helper("privacy-control", "toggle", "location", environment=environment)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((second / "calls.log").read_text().strip(),
                             "/usr/bin/systemctl mask --runtime --now geoclue.service")

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

    def test_failed_screenshot_leaves_no_partial_capture(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            pictures = directory / "pictures"
            environment = self.environment(directory, {
                "slurp": "printf '0,0 10x10\\n'",
                "grim": "for last do :; done; touch \"$last\"; exit 9",
            })
            environment["XDG_PICTURES_DIR"] = str(pictures)
            result = self.run_helper("privacy-screenshot", "capture", "grim", environment=environment)
            self.assertEqual(result.returncode, 9)
            self.assertEqual(list(pictures.iterdir()), [], "failed captures must not publish partial images")

    def test_screenshot_uses_localized_xdg_user_directory(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            localized = directory / "Bilder"
            environment = self.environment(directory, {
                "xdg-user-dir": f"printf '%s\\n' '{localized}'",
                "slurp": "printf '0,0 10x10\\n'",
                "grim": "for last do :; done; touch \"$last\"",
                "wl-copy": "cat >/dev/null",
            })
            environment.pop("XDG_PICTURES_DIR", None)
            result = self.run_helper("privacy-screenshot", "capture", "grim", environment=environment)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(len(list(localized.glob("screenshot-*.png"))), 1)

    def test_screenshot_rejects_relative_xdg_user_directory(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            fallback = directory / "home" / "Pictures"
            environment = self.environment(directory, {
                "xdg-user-dir": "printf 'relative/path\\n'",
                "slurp": "printf '0,0 10x10\\n'",
                "grim": "for last do :; done; touch \"$last\"",
                "wl-copy": "cat >/dev/null",
            })
            environment.pop("XDG_PICTURES_DIR", None)
            result = self.run_helper("privacy-screenshot", "capture", "grim", environment=environment)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(len(list(fallback.glob("screenshot-*.png"))), 1)

    def test_screenshot_routes_each_supported_backend_without_shell_strings(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            pictures = directory / "pictures"
            environment = self.environment(directory, {
                "slurp": "printf '1,2 30x40\\n'",
                "grim": "printf 'grim:%s\\n' \"$*\" >>\"$TEST_LOG\"; printf image",
                "satty": "printf 'satty:%s\\n' \"$*\" >>\"$TEST_LOG\"; cat >/dev/null",
                "hyprshot": "printf 'hyprshot:%s\\n' \"$*\" >>\"$TEST_LOG\"",
                "flameshot": "printf 'flameshot:%s:qpa=%s\\n' \"$*\" \"${QT_QPA_PLATFORM:-}\" >>\"$TEST_LOG\"",
            })
            environment["XDG_PICTURES_DIR"] = str(pictures)
            for backend in ("grim-satty", "hyprshot", "flameshot"):
                result = self.run_helper("privacy-screenshot", "capture", backend, environment=environment)
                self.assertEqual(result.returncode, 0, f"{backend}: {result.stderr}")
            calls = (directory / "calls.log").read_text()
            self.assertIn("grim:-g 1,2 30x40 -", calls)
            self.assertRegex(calls, r"satty:--filename - --output-filename .+ --copy-command wl-copy")
            self.assertRegex(calls, r"hyprshot:--freeze -m region -o .+ -f screenshot-")
            self.assertIn("flameshot:gui -p " + str(pictures) + ":qpa=wayland", calls)

    def test_helpers_reject_unsupported_control_and_capture_operations(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            environment = self.environment(directory)
            self.assertEqual(self.run_helper("privacy-control", "status", "unknown", environment=environment).returncode, 12)
            self.assertEqual(self.run_helper("privacy-control", "invalid", "location", environment=environment).returncode, 12)
            self.assertEqual(self.run_helper("privacy-screenshot", "capture", "unknown", environment=environment).returncode, 2)
            runtime = directory / "runtime"
            runtime.mkdir(mode=0o700)
            environment["XDG_RUNTIME_DIR"] = str(runtime)
            self.assertEqual(self.run_helper("privacy-recording", "start", "unknown", environment=environment).returncode, 2)

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

    def test_recorder_uses_localized_xdg_user_directory(self):
        with tempfile.TemporaryDirectory() as raw:
            directory = Path(raw)
            runtime = directory / "runtime"
            runtime.mkdir(mode=0o700)
            localized = directory / "Videos-localized"
            environment = self.environment(directory, {
                "xdg-user-dir": f"printf '%s\\n' '{localized}'",
                "slurp": "printf '0,0 10x10\\n'",
                "wf-recorder": "printf '%s\\n' \"$*\" >\"$TEST_LOG\"",
            })
            environment["XDG_RUNTIME_DIR"] = str(runtime)
            environment.pop("XDG_VIDEOS_DIR", None)
            result = self.run_helper("privacy-recording", "start", "wf-recorder", environment=environment)
            self.assertEqual(result.returncode, 0, result.stderr)
            for _ in range(100):
                if (directory / "calls.log").exists():
                    break
                time.sleep(0.001)
            self.assertIn(str(localized / "screenrecording-"), (directory / "calls.log").read_text())


if __name__ == "__main__":
    unittest.main()
