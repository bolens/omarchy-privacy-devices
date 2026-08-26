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

    def test_normalize_rejects_unsafe_names_and_sanitizes_bounded_labels(self):
        rows = [
            {"name": "bad name", "description": "Unsafe", "mute": False},
            {"name": "safe", "description": " Desk\n\u202eMic " + "x" * 300, "mute": 1},
            {"name": "fallback", "properties": {"device.description": " Built-in\tAudio "}},
        ] + [{"name": f"extra-{index}"} for index in range(260)]
        devices = MODULE.normalize(rows, "audio-output")
        self.assertEqual(devices[0], {"id": "safe", "label": "DeskMic " + "x" * 248, "muted": False})
        self.assertEqual(devices[1], {"id": "fallback", "label": "Built-inAudio", "muted": False})
        self.assertLessEqual(len(devices), 255, "only the first 256 untrusted rows may be inspected")

    def test_normalize_tolerates_malformed_endpoint_properties(self):
        rows = [
            {"name": "broken-list", "properties": ["not", "a", "mapping"]},
            {"name": "broken-text", "properties": "not a mapping"},
        ]
        self.assertEqual(MODULE.normalize(rows, "audio-output"), [
            {"id": "broken-list", "label": "broken-list", "muted": False},
            {"id": "broken-text", "label": "broken-text", "muted": False},
        ])

    def test_list_uses_the_matching_pactl_inventory(self):
        calls = []
        def runner(arguments, **kwargs):
            calls.append((arguments, kwargs))
            return type("Result", (), {"stdout": "[]"})()
        self.assertEqual(MODULE.list_devices("microphone", runner), [])
        self.assertEqual(calls[0][0], ["pactl", "-f", "json", "list", "sources"])
        self.assertEqual(calls[0][1], {"check": True, "text": True, "capture_output": True, "timeout": 5})
        with self.assertRaises(ValueError):
            MODULE.list_devices("camera", runner)

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

    def test_set_can_unmute_a_source_and_requires_observed_confirmation(self):
        calls = []
        def runner(arguments, **_kwargs):
            calls.append(arguments)
            return type("Result", (), {"stdout": json.dumps([{"name": "known", "mute": True}])})()
        with self.assertRaisesRegex(ValueError, "not verified"):
            MODULE.set_muted("microphone", "known", False, runner)
        self.assertEqual(calls[1], ["pactl", "set-source-mute", "known", "0"])
        self.assertEqual(len(calls), 3)


if __name__ == "__main__":
    unittest.main()
