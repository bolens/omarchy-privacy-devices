import importlib.machinery
import importlib.util
import subprocess
import sys
import unittest
from unittest.mock import patch


LOADER = importlib.machinery.SourceFileLoader("privacy_location", "privacy-location")
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


class LocationProbeTests(unittest.TestCase):
    def test_active_clients_are_deduplicated_and_sorted(self):
        responses = {
            ("get-property", MODULE.SERVICE, MODULE.MANAGER_PATH, "org.freedesktop.GeoClue2.Manager", "InUse"): "b true",
            ("tree", MODULE.SERVICE): "├─/org/freedesktop/GeoClue2/Client/2\n└─/org/freedesktop/GeoClue2/Client/1",
        }

        def response(*arguments):
            if arguments[-1] == "Active":
                return "b true"
            if arguments[-1] == "DesktopId":
                return 's "Maps"' if "/1" in arguments[2] else 's "Browser"'
            return responses[arguments]

        with patch.object(MODULE, "busctl", side_effect=response):
            self.assertEqual(MODULE.snapshot(), {
                "type": "location-snapshot", "version": 1, "active": True,
                "applications": ["Browser", "Maps"],
            })

    def test_inactive_manager_avoids_client_enumeration(self):
        with patch.object(MODULE, "busctl", return_value="b false") as busctl:
            self.assertEqual(MODULE.snapshot()["active"], False)
            busctl.assert_called_once()

    def test_busctl_is_bounded_and_never_uses_a_shell(self):
        completed = subprocess.CompletedProcess([], 0, stdout=b"value", stderr=b"")
        with patch.object(MODULE.subprocess, "run", return_value=completed) as run:
            self.assertEqual(MODULE.busctl("tree", MODULE.SERVICE), "value")
        self.assertEqual(run.call_args.args[0], ["busctl", "tree", MODULE.SERVICE])
        self.assertEqual(run.call_args.kwargs["timeout"], 2)
        self.assertNotIn("shell", run.call_args.kwargs)

    def test_probe_failure_returns_structured_inactive_payload(self):
        with patch.object(MODULE, "snapshot", side_effect=subprocess.TimeoutExpired("busctl", 2)), \
             patch.object(sys, "stdout") as stdout:
            self.assertEqual(MODULE.main(), 1)
            self.assertIn('"healthy":false', stdout.write.call_args_list[0].args[0])


if __name__ == "__main__":
    unittest.main()
