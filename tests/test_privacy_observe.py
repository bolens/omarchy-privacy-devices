import importlib.machinery
import importlib.util
import os
import errno
import tempfile
import unittest
import sys
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parent.parent
LOADER = importlib.machinery.SourceFileLoader("privacy_observe", str(ROOT / "privacy-observe"))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


class DirectDeviceObservationTests(unittest.TestCase):
    def process(self, root, pid, name, targets):
        process = root / str(pid)
        (process / "fd").mkdir(parents=True)
        (process / "comm").write_text(name + "\n")
        for index, target in enumerate(targets):
            os.symlink(target, process / "fd" / str(index))

    def test_reports_only_camera_and_capture_handles_and_deduplicates(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.process(root, 100, "browser", ["/dev/video0", "/dev/video0", "/dev/snd/pcmC1D0c", "/dev/snd/pcmC1D0p"])
            self.process(root, 101, "editor", ["/tmp/document"])

            found = MODULE.observations(root, os.getuid())

            self.assertEqual(found, [
                {
                    "kind": "camera", "application": "browser", "device": "/dev/video0",
                    "source": "direct-device", "confidence": "confirmed",
                    "detail": "same-user process 100 holds an open device handle",
                },
                {
                    "kind": "microphone", "application": "browser", "device": "/dev/snd/pcmC1D0c",
                    "source": "direct-device", "confidence": "confirmed",
                    "detail": "same-user process 100 holds an open device handle",
                },
            ])

    def test_process_disappearance_during_scan_is_tolerated(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "404").mkdir()
            self.assertEqual(MODULE.observations(root, os.getuid()), [])

    def test_emit_decision_is_change_or_heartbeat_driven(self):
        previous = [{"kind": "camera", "application": "OBS", "device": "/dev/video0"}]
        same = [dict(previous[0])]
        changed = previous + [{"kind": "microphone", "application": "Recorder", "device": "/dev/snd/pcmC0D0c"}]
        self.assertFalse(MODULE.should_emit(previous, same, now=12.0, last_emit=10.0, heartbeat=5.0))
        self.assertTrue(MODULE.should_emit(previous, same, now=15.0, last_emit=10.0, heartbeat=5.0))
        self.assertTrue(MODULE.should_emit(previous, changed, now=10.1, last_emit=10.0, heartbeat=5.0))

    def test_event_scan_rate_is_explicitly_bounded(self):
        self.assertGreaterEqual(MODULE.MIN_EVENT_SCAN_INTERVAL, 2.0)

    def test_cli_bounds_heartbeat_and_pattern_inputs(self):
        self.assertEqual(MODULE.bounded_heartbeat("nan"), 5.0)
        self.assertEqual(MODULE.bounded_heartbeat("999"), 60.0)
        with patch.object(sys, "argv", ["privacy-observe", "watch-fallbacks", "--recording", "x" * (MODULE.MAX_PROCESS_NAME_CHARS + 1)]):
            self.assertEqual(MODULE.main(), 2)

    def test_process_activity_is_structured_and_matches_literal_or_pattern(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for pid, command in [("10", "gpu-screen-recorder -w screen"), ("11", "grim -g 0,0 10x10 shot.png"), ("12", "unrelated"),
                                 ("13", "python3 /plugin/privacy-observe watch-fallbacks --recording gpu-screen-recorder"),
                                 ("14", "bash -lc pgrep -f ^gpu-screen-recorder")]:
                process = root / pid
                process.mkdir()
                (process / "cmdline").write_bytes(command.replace(" ", "\0").encode() + b"\0")

            state = MODULE.process_activity(root, "gpu-screen-recorder", r"^(grim|slurp|satty)(\s|$)")

            self.assertEqual(state["screen-recording"], ["gpu-screen-recorder"])
            self.assertEqual(state["screenshot"], ["grim"])

    def test_fallback_snapshot_has_versioned_stable_shape(self):
        snapshot = MODULE.fallback_snapshot({"screen-recording": ["Recorder"], "screenshot": []}, healthy=True)
        self.assertEqual(snapshot, {
            "type": "fallback-snapshot", "version": 1, "healthy": True, "code": "ok",
            "activities": {"screen-recording": ["Recorder"], "screenshot": []},
        })

    def test_device_event_wait_parses_relevant_masks_and_retries_interrupts(self):
        events = MODULE.DeviceEvents.__new__(MODULE.DeviceEvents)
        events.fd = 42
        ignored = MODULE.EVENT_HEADER.pack(1, 0, 0, 0)
        relevant = MODULE.EVENT_HEADER.pack(1, MODULE.IN_OPEN, 0, 4) + b"cam\0"
        with patch.object(MODULE.select, "select", return_value=([42], [], [])), \
             patch.object(MODULE.os, "read", side_effect=[OSError(errno.EINTR, "interrupted"), ignored + relevant, BlockingIOError()]):
            self.assertTrue(events.wait(0.5))

    def test_device_event_wait_times_out_without_reading(self):
        events = MODULE.DeviceEvents.__new__(MODULE.DeviceEvents)
        events.fd = 42
        with patch.object(MODULE.select, "select", return_value=([], [], [])), \
             patch.object(MODULE.os, "read") as read:
            self.assertFalse(events.wait(-1))
        read.assert_not_called()


if __name__ == "__main__":
    unittest.main()
