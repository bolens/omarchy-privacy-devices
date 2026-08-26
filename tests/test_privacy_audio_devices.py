import importlib.machinery
import importlib.util
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOADER = importlib.machinery.SourceFileLoader("privacy_audio_devices", str(ROOT / "privacy-audio-devices"))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


class AudioDeviceTests(unittest.TestCase):
    def test_normalizes_real_endpoints_and_excludes_monitor_sources(self):
        rows = [
            {"name": "alsa_input.usb_mic", "description": "Desk Mic", "mute": True},
            {"name": "alsa_output.usb.monitor", "description": "Monitor", "mute": False},
        ]
        self.assertEqual(MODULE.normalize(rows, "microphone"), [
            {"id": "alsa_input.usb_mic", "label": "Desk Mic", "muted": True}
        ])

    def test_set_rejects_unknown_target_before_mutation(self):
        calls = []
        def runner(arguments, **_kwargs):
            calls.append(arguments)
            return type("Result", (), {"stdout": json.dumps([{"name": "known", "description": "Known", "mute": False}])})()
        with self.assertRaises(ValueError):
            MODULE.set_muted("microphone", "unknown", True, runner)
        self.assertEqual(len(calls), 1, "unknown identifiers must never reach a mutating pactl call")

    def test_set_uses_exact_allowlisted_name_and_requested_state(self):
        calls = []
        def runner(arguments, **_kwargs):
            calls.append(arguments)
            muted = len(calls) > 1
            return type("Result", (), {"stdout": json.dumps([{"name": "known", "description": "Known", "mute": muted}])})()
        MODULE.set_muted("audio-output", "known", True, runner)
        self.assertEqual(calls[1], ["pactl", "set-sink-mute", "known", "1"])
        self.assertEqual(len(calls), 3, "the helper must verify the observed endpoint state")


if __name__ == "__main__":
    unittest.main()
