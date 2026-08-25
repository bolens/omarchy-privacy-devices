import importlib.machinery
import importlib.util
import json
import fcntl
import math
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
LOADER = importlib.machinery.SourceFileLoader("privacy_history", str(ROOT / "privacy-history"))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


class HistoryTests(unittest.TestCase):
    def entry(self, index, ended_at):
        return {
            "id": str(index), "kind": "microphone", "application": f"App {index}",
            "device": "Mic", "source": "pipewire", "confidence": "confirmed",
            "startedAt": ended_at - 1000, "endedAt": ended_at, "durationMs": 1000,
            "unexpected": "must not persist",
        }

    def test_sanitizes_bounds_orders_and_writes_private_atomic_state(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "plugin" / "history.json"
            now = 1_000_000_000
            entries = [MODULE.sanitize(self.entry(index, now - index)) for index in range(105)]
            MODULE.save(path, MODULE.bounded(entries, now))

            stored = MODULE.load(path)
            self.assertEqual(len(stored), 100)
            self.assertEqual(stored[0]["application"], "App 0")
            self.assertNotIn("unexpected", stored[0])
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            self.assertEqual(path.parent.stat().st_mode & 0o777, 0o700)
            self.assertEqual(list(path.parent.glob(".history-*")), [])

    def test_rejects_entries_without_lifecycle_fields(self):
        with self.assertRaises(ValueError):
            MODULE.sanitize({"kind": "camera", "application": "Browser"})
        invalid_number = self.entry(1, 1_000_000_000)
        invalid_number["endedAt"] = math.nan
        with self.assertRaises(ValueError):
            MODULE.sanitize(invalid_number)

    def test_strips_control_and_direction_override_characters(self):
        entry = self.entry(1, 1_000_000_000)
        entry["application"] = "  Browser\n\u202eevil\u2066  "
        self.assertEqual(MODULE.sanitize(entry)["application"], "Browserevil")

    def test_bounds_persisted_text_and_incoming_batch(self):
        now = 1_000_000_000
        oversized = self.entry(1, now)
        oversized["application"] = "x" * (MODULE.MAX_FIELD_CHARS + 10)
        incoming = [dict(oversized, id=str(index), endedAt=now - index) for index in range(MODULE.MAX_ENTRIES + 5)]
        result = MODULE.append_entries([], incoming, now)

        self.assertEqual(len(result), MODULE.MAX_ENTRIES)
        self.assertEqual(len(result[0]["application"]), MODULE.MAX_FIELD_CHARS)

    def test_load_resanitizes_and_rejects_oversized_state(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "history.json"
            entry = self.entry(1, 1_000_000_000)
            path.write_text(json.dumps([entry]))
            self.assertNotIn("unexpected", MODULE.load(path)[0])

            path.write_text(" " * (MODULE.MAX_FILE_BYTES + 1))
            self.assertEqual(MODULE.load(path), [])

    def test_batches_simultaneous_stops_in_one_ordered_transaction(self):
        now = 1_000_000_000
        older = MODULE.sanitize(self.entry(1, now - 5000))
        simultaneous = [self.entry(2, now - 1000), self.entry(3, now)]

        result = MODULE.append_entries([older], simultaneous, now)

        self.assertEqual([entry["application"] for entry in result], ["App 3", "App 2", "App 1"])

    def test_replayed_entries_are_deduplicated_by_identity_and_end_time(self):
        now = 1_000_000_000
        entry = MODULE.sanitize(self.entry(1, now))

        result = MODULE.append_entries([entry], [dict(entry), dict(entry)], now)

        self.assertEqual(result, [entry])

    def test_state_lock_is_private_and_excludes_concurrent_writers(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "plugin" / "history.json"
            with MODULE.locked(path):
                lock_path = path.parent / ".history.lock"
                self.assertEqual(lock_path.stat().st_mode & 0o777, 0o600)
                with lock_path.open() as contender:
                    with self.assertRaises(BlockingIOError):
                        fcntl.flock(contender.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)

    def test_cli_append_load_and_clear_round_trip(self):
        with tempfile.TemporaryDirectory() as directory:
            environment = dict(os.environ, XDG_STATE_HOME=directory)
            entry = self.entry(7, int(__import__("time").time() * 1000))

            appended = subprocess.run(
                [str(ROOT / "privacy-history"), "append", json.dumps([entry])],
                env=environment, text=True, capture_output=True, check=False,
            )
            self.assertEqual(appended.returncode, 0, appended.stderr)
            loaded = subprocess.run(
                [str(ROOT / "privacy-history"), "load"], env=environment,
                text=True, capture_output=True, check=False,
            )
            self.assertEqual(loaded.returncode, 0, loaded.stderr)
            self.assertEqual(json.loads(loaded.stdout)[0]["application"], "App 7")

            cleared = subprocess.run(
                [str(ROOT / "privacy-history"), "clear"], env=environment,
                text=True, capture_output=True, check=False,
            )
            self.assertEqual(cleared.returncode, 0, cleared.stderr)
            self.assertFalse((Path(directory) / "omarchy-privacy-devices" / "history.json").exists())


if __name__ == "__main__":
    unittest.main()
