"""The native QML gate must execute offline as an ordinary container user."""
import os
import re
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def step_network_modes(workflow, name):
    """Inspect direct step fields in this repository's fixed workflow layout."""
    blocks = re.split(r"(?m)^  - name: ", workflow)[1:]
    selected = [block for block in blocks if block.splitlines()[0] == name]
    if len(selected) != 1:
        raise ValueError("Expected one named workflow step")
    return [line for line in selected[0].splitlines() if re.match(r"^\s*network_mode:", line)]


class NativeQmlContract(unittest.TestCase):
    def test_runtime_is_mandatory_after_real_static_gate(self):
        script = (ROOT / "scripts/woodpecker-plugin.sh").read_text()
        self.assertIn("scripts/qml-runtime-fixture.py --execute", script)
        if "scripts/lint-qml" in script:
            static_at = script.index("scripts/lint-qml")
        else:
            static_at = script.index("OMARCHY_SKIP_VALIDATE=1 npm test")
            portable = (ROOT / "tests/run_all.sh").read_text()
            if '"$plugin_dir/scripts/lint-qml"' in portable:
                portable = (ROOT / "scripts/lint-qml").read_text()
            self.assertIn('[[ -x "$qmllint_bin" ]] ||', portable)
            self.assertIn('"$qmllint_bin" "${qml_import_args[@]}"', portable)
            self.assertIn("scripts/check-qml-lint-controls.py", portable)
        self.assertLess(static_at, script.index("scripts/qml-runtime-fixture.py --execute"))
        self.assertIn("--prepared-shell \"$OMARCHY_SHELL_ROOT\"", script)
        self.assertIn("--negative-catalog scripts/qml-runtime-warnings.json", script)
        self.assertNotIn("|| true", script)

    def test_offline_nonroot_workflow_preserves_plugin_check(self):
        workflow = (ROOT / ".woodpecker/plugin.yml").read_text()
        self.assertIn("name: prepare", workflow)
        self.assertIn("name: plugin", workflow)
        self.assertIn("user: '10042:10042'", workflow)
        self.assertEqual(step_network_modes(workflow, "plugin"), ["    network_mode: none"])
        self.assertEqual(step_network_modes(workflow, "prepare"), [])
        self.assertIn("woodpecker-plugin.sh --prepare", workflow)
        self.assertIn("woodpecker-plugin.sh --offline", workflow)
        self.assertNotIn("privileged:", workflow)
        self.assertNotIn("/var/run/docker.sock", workflow)

    def test_network_contract_rejects_ignored_nested_backend_key(self):
        workflow = (ROOT / ".woodpecker/plugin.yml").read_text()
        direct = "    network_mode: none\n"
        nested = workflow.replace(direct, "").replace("        user: '10042:10042'\n",
                                                       "        user: '10042:10042'\n        network_mode: none\n")
        self.assertNotEqual(step_network_modes(nested, "plugin"), [direct.rstrip("\n")])
        duplicate = workflow.replace(direct, direct + "        network_mode: none\n")
        self.assertNotEqual(step_network_modes(duplicate, "plugin"), [direct.rstrip("\n")])

    def test_preparation_refuses_existing_tree_without_overwriting(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            script = root / "scripts/woodpecker-plugin.sh"
            script.write_bytes((ROOT / "scripts/woodpecker-plugin.sh").read_bytes())
            bindir = root / "bin"
            bindir.mkdir()
            fakegit = bindir / "git"
            fakegit.write_text("#!/bin/sh\nprintf called > \"$NATIVE_TEST_GIT_CALL\"\nexit 91\n")
            fakegit.chmod(0o700)
            prepared = root / ".woodpecker-qml-input"
            prepared.mkdir()
            sentinel = prepared / "preserve"
            sentinel.write_text("unrelated content")
            result = subprocess.run(["bash", str(script), "--prepare"], text=True, capture_output=True, timeout=3,
                                    env={**os.environ, "PATH": str(bindir) + ":/usr/bin:/bin", "NATIVE_TEST_GIT_CALL": str(root / "git-called")})
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse((root / "git-called").exists(), "existing input must reject before any Git operation")
            self.assertEqual(sentinel.read_text(), "unrelated content")
            self.assertEqual(sorted(path.name for path in prepared.iterdir()), ["preserve"])

    def test_only_exact_ephemeral_input_is_ignored(self):
        self.assertIn("/.woodpecker-qml-input/", (ROOT / ".gitignore").read_text().splitlines())

    def test_public_locked_dependencies_are_prepared_readable_before_offline(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            script = root / "scripts/woodpecker-plugin.sh"
            script.write_bytes((ROOT / "scripts/woodpecker-plugin.sh").read_bytes())
            bindir = root / "bin"
            bindir.mkdir()
            fakegit = bindir / "git"
            fakegit.write_text('#!/bin/sh\nif [ "$1" = init ]; then mkdir -p "$3/.git"; fi\nif [ "$3" = rev-parse ]; then printf "%s\\n" 13f18b2cb7286fb54f87daf571a031aa6af3d8f0; fi\n')
            fakegit.chmod(0o700)
            fakenpm = bindir / "npm"
            fakenpm.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$NATIVE_TEST_NPM_CALL"\nmkdir node_modules\nprintf public > node_modules/readable\n')
            fakenpm.chmod(0o700)
            captured = root / "npm-args"
            result = subprocess.run(["bash", str(script), "--prepare"], text=True, capture_output=True, timeout=3,
                                    umask=0o077, env={**os.environ, "PATH": str(bindir) + ":/usr/bin:/bin", "NATIVE_TEST_NPM_CALL": str(captured)})
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(captured.read_text().splitlines(), ["ci", "--ignore-scripts"])
            self.assertEqual((root / "node_modules/readable").stat().st_mode & 0o777, 0o644)


if __name__ == "__main__":
    unittest.main()
