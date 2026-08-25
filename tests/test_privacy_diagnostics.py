import importlib.machinery
import importlib.util
import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parent.parent
LOADER = importlib.machinery.SourceFileLoader("privacy_diagnostics", str(ROOT / "privacy-diagnostics"))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


class DiagnosticCopyTests(unittest.TestCase):
    def test_rejects_unversioned_or_oversized_payloads(self):
        with patch.object(sys, "argv", ["privacy-diagnostics", "{}"]):
            self.assertEqual(MODULE.main(), 2)
        with patch.object(sys, "argv", ["privacy-diagnostics", "x" * (MODULE.MAX_BYTES + 1)]):
            self.assertEqual(MODULE.main(), 2)
        with patch.object(sys, "argv", ["privacy-diagnostics", '{"version":1,"value":NaN}']):
            self.assertEqual(MODULE.main(), 2)

    def test_passes_only_normalized_json_to_wl_copy(self):
        payload = {"version": 1, "redacted": True, "sessions": []}
        with patch.object(sys, "argv", ["privacy-diagnostics", json.dumps(payload)]), patch.object(MODULE.shutil, "which", return_value="/usr/bin/wl-copy"), patch.object(MODULE.os.path, "realpath", return_value="/usr/bin/wl-copy"), patch.object(MODULE.subprocess, "run") as run:
            run.return_value.returncode = 0
            self.assertEqual(MODULE.main(), 0)
        self.assertEqual(run.call_args.args[0], ["/usr/bin/wl-copy"])
        self.assertEqual(json.loads(run.call_args.kwargs["input"]), payload)
        self.assertTrue(run.call_args.kwargs["text"])
        self.assertEqual(run.call_args.kwargs["timeout"], 5)

    def test_fails_closed_when_clipboard_tool_is_missing(self):
        payload = {"version": 1, "redacted": True}
        with patch.object(sys, "argv", ["privacy-diagnostics", json.dumps(payload)]), patch.object(MODULE.shutil, "which", return_value=None), patch.object(MODULE.subprocess, "run") as run:
            self.assertEqual(MODULE.main(), 1)
        run.assert_not_called()

    def test_times_out_a_stuck_clipboard_process(self):
        payload = {"version": 1, "redacted": True}
        with patch.object(sys, "argv", ["privacy-diagnostics", json.dumps(payload)]), \
             patch.object(MODULE.shutil, "which", return_value="/usr/bin/wl-copy"), \
             patch.object(MODULE.subprocess, "run", side_effect=subprocess.TimeoutExpired("wl-copy", 5)):
            self.assertEqual(MODULE.main(), 1)


if __name__ == "__main__":
    unittest.main()
