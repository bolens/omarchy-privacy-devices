import importlib.machinery
import importlib.util
import os
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
            self.assertFalse(path.with_suffix(".json.new").exists())

    def test_rejects_entries_without_lifecycle_fields(self):
        with self.assertRaises(ValueError):
            MODULE.sanitize({"kind": "camera", "application": "Browser"})

    def test_batches_simultaneous_stops_in_one_ordered_transaction(self):
        now = 1_000_000_000
        older = MODULE.sanitize(self.entry(1, now - 5000))
        simultaneous = [self.entry(2, now - 1000), self.entry(3, now)]

        result = MODULE.append_entries([older], simultaneous, now)

        self.assertEqual([entry["application"] for entry in result], ["App 3", "App 2", "App 1"])


if __name__ == "__main__":
    unittest.main()
