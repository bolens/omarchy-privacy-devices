"""The native QML gate must execute offline as an ordinary container user."""
import json
import os
import re
import subprocess
import sys
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

    def prepare_dependencies(self, exit_code):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            script = root / "scripts/woodpecker-plugin.sh"
            script.write_bytes((ROOT / "scripts/woodpecker-plugin.sh").read_bytes())
            bindir = root / "bin"
            bindir.mkdir()
            # Exercise real sparse fetch, immutable revision and blob/working-file
            # verification. Only the copied script uses this disposable supplier.
            supplier = root / "supplier"
            (supplier / "shell").mkdir(parents=True)
            (supplier / "bin").mkdir()
            (supplier / "shell/Fixture.qml").write_text("import QtQuick\nItem {}\n")
            validator = supplier / "bin/omarchy-plugin-validate"
            validator.write_text("#!/bin/sh\necho 'Preparation must not execute this fixture validator' >&2\nexit 99\n")
            validator.chmod(0o755)
            # Git's surrounding pre-commit context must never select the real
            # checkout's index, objects or worktree inside this supplier fixture.
            git_env = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
            git_env.update({"GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1"})
            def fixture_git(*args):
                return subprocess.run(["git", "-C", str(supplier), *args], check=True,
                                      text=True, capture_output=True, timeout=10, env=git_env).stdout.strip()
            fixture_git("init", "--quiet")
            fixture_git("add", "shell", "bin")
            fixture_git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                        "commit", "--quiet", "-m", "Fixture supplier")
            revision = fixture_git("rev-parse", "HEAD")
            source = script.read_text()
            self.assertEqual(source.count("omarchy_revision=13f18b2cb7286fb54f87daf571a031aa6af3d8f0"), 1)
            self.assertEqual(source.count("https://github.com/omacom/omarchy.git"), 1)
            script.write_text(source.replace("omarchy_revision=13f18b2cb7286fb54f87daf571a031aa6af3d8f0",
                                             "omarchy_revision=" + revision)
                              .replace("https://github.com/omacom/omarchy.git", supplier.as_uri()))
            captured = root / "npm-call.json"
            temporary = root / "temporary"
            temporary.mkdir(mode=0o700)
            fakenpm = bindir / "npm"
            fakenpm.write_text(f"#!{sys.executable}\n" + r'''
import json
import os
from pathlib import Path
import stat
import sys
configs = [Path(os.environ[key]) for key in ("NPM_CONFIG_USERCONFIG", "NPM_CONFIG_GLOBALCONFIG")]
assert configs[0] != configs[1] and configs[0].resolve() != configs[1].resolve()
assert not configs[0].samefile(configs[1])
assert configs[0].parent == configs[1].parent
assert stat.S_IMODE(configs[0].parent.stat().st_mode) == 0o700
for path in configs:
    assert path.is_file() and not path.is_symlink()
    assert path.read_bytes() == b"" and stat.S_IMODE(path.stat().st_mode) == 0o600
for key in ("NPM_TOKEN", "NODE_AUTH_TOKEN", "npm_config_registry", "NPM_CONFIG_REGISTRY"):
    assert key not in os.environ
''' + f"Path({str(captured)!r}).write_text(json.dumps({{'args':sys.argv[1:], 'configs':[str(path) for path in configs]}}))\n"
                + ("Path('node_modules').mkdir()\nPath('node_modules/readable').write_text('public')\n" if exit_code == 0 else "")
                + f"sys.exit({exit_code})\n")
            fakenpm.chmod(0o700)
            result = subprocess.run(["bash", str(script), "--prepare"], text=True, capture_output=True, timeout=10,
                                    umask=0o077, env={**git_env, "PATH": str(bindir) + ":/usr/bin:/bin", "TMPDIR": str(temporary),
                                                     "NPM_TOKEN": "ambient-fixture", "NODE_AUTH_TOKEN": "ambient-fixture",
                                                     "NPM_CONFIG_REGISTRY": "https://invalid.example", "npm_config_registry": "https://invalid.example"})
            self.assertEqual(result.returncode, exit_code, result.stderr)
            observed = json.loads(captured.read_text())
            self.assertEqual(observed["args"], ["ci", "--ignore-scripts"])
            self.assertTrue(all(not Path(path).exists() for path in observed["configs"]), "private NPM configs survive invocation")
            self.assertEqual(list(temporary.iterdir()), [], "private NPM home/cache/temp survives invocation")
            if exit_code == 0:
                self.assertEqual((root / "node_modules/readable").stat().st_mode & 0o777, 0o644)

    def test_public_locked_dependencies_are_prepared_readable_before_offline(self):
        self.prepare_dependencies(0)

    def test_failed_npm_preserves_status_and_cleans_private_configuration(self):
        self.prepare_dependencies(37)

    def test_offline_dependencies_are_checked_without_install_or_fetch(self):
        script = (ROOT / "scripts/woodpecker-plugin.sh").read_text()
        offline = script.split("esac\n", 1)[1]
        self.assertIn("run_public_npm ls --all --offline", offline)
        self.assertNotRegex(offline, r"\bnpm (?:ci|install|update|exec|view|fetch)\b")
        self.assertLess(offline.index("run_public_npm ls --all --offline"), offline.index("\ntests/run_all.sh\n"))
        self.assertIn("scripts/lint-qml", offline)
        self.assertIn("scripts/qml-runtime-fixture.py --execute", offline)


if __name__ == "__main__":
    unittest.main()
