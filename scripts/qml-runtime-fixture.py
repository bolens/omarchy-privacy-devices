#!/usr/bin/env python3
"""Inert; all canonical runtime harnesses in owned offscreen/Wayland fixtures."""
import argparse
import hashlib
import json
import os
import re
import selectors
import shlex
import shutil
import stat
import subprocess
import time
from pathlib import Path

from qml_runtime import headless
from qml_runtime import pipewire as fixture
from qml_runtime.contracts import warning_assessment

# Canonical production-handler transport cases must not bypass their parent gate.
BOOTSTRAP_CASES = {("p2p", "RuntimeIpcTransportTest.qml"), ("mmw", "RuntimeIpcTransportTest.qml")}

def owned_compositor(root, environment, log, tools):
    config = root / "config/labwc"
    config.mkdir()
    for name in ("autostart", "shutdown", "environment", "xinitrc"):
        (config / name).write_text("")
    (config / "rc.xml").write_text("<labwc_config><core><xwaylandPersistence>no</xwaylandPersistence></core></labwc_config>\n")
    (config / "menu.xml").write_text("<openbox_menu/>\n")
    fifo = root / "ready.fifo"
    os.mkfifo(fifo, 0o600)
    descriptor = os.open(fifo, os.O_RDWR | os.O_NONBLOCK)
    startup = shlex.join([tools["python"], str(Path(__file__).resolve()), "--registry-ready", str(fifo)])
    process = subprocess.Popen([tools["labwc"], "--config-dir", str(config), "--startup", startup],
                               env=environment, cwd=root, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    pidfd = os.pidfd_open(process.pid)
    try:
        with selectors.DefaultSelector() as selector:
            selector.register(descriptor, selectors.EVENT_READ, "ready")
            selector.register(pidfd, selectors.EVENT_READ, "exit")
            events = selector.select(timeout=25)
            if not events or any(key.data == "exit" for key, _mask in events):
                raise RuntimeError("Owned compositor did not reach actual protocol readiness")
            payload = os.read(descriptor, 4097)
            assert payload.endswith(b"\n") and len(payload) <= 4096
            ready = json.loads(payload)
            assert ready["ready"] and ready["sync_roundtrip"] and set(ready["protocols"]) == headless.REQUIRED_GLOBALS
            assert re.fullmatch(r"wayland-[0-9]+", ready["display"])
        assert not headless.xwayland_processes()
        return process, ready
    except BaseException:
        headless.stop_owned(process)
        raise
    finally:
        os.close(pidfd)
        os.close(descriptor)


def owned_absence(path, cwd, environment, deadline, quickshell):
    result = subprocess.run([quickshell, "list", "--all", "--json", "--no-color"],
                            cwd=cwd, env=environment, text=True, capture_output=True,
                            timeout=max(0.001, min(3, deadline - time.monotonic())), check=False)
    report = {"exit": result.returncode, "stdout": result.stdout, "stderr": result.stderr,
              "checked_config_path": str(path.resolve())}
    return owned_lifecycle_verdict(0, report, path), report


def owned_lifecycle_verdict(engine_exit, absence, path):
    # The kill CLI races the original engine's natural exit: it can select the
    # instance just before its socket closes. Its response is retained only as
    # diagnostics. The original engine and independent list are authoritative.
    if engine_exit != 0 or not isinstance(absence, dict):
        return False
    if absence.get("checked_config_path") != str(path.resolve()) or absence.get("exit") != 0:
        return False
    raw = (absence["stdout"] + absence["stderr"]).strip()
    try:
        entries = json.loads(absence["stdout"])
        if absence["stderr"].strip():
            return False
        assert isinstance(entries, list) and all(isinstance(row, dict) and isinstance(row.get("config_path"), str) for row in entries)
        return not any(Path(row["config_path"]).resolve() == path.resolve() for row in entries)
    except (ValueError, AssertionError):
        return re.fullmatch(r"(?:INFO:\s*)?No running instances\.", raw) is not None


def harness_verdict(exit_code, timed_out, failure, marker_count):
    return exit_code == 0 and not timed_out and failure is None and marker_count == 1


def owned_session_empty(pid):
    # Read-only check of the private session created for this exact Popen child.
    assert pid > 0
    try:
        os.killpg(pid, 0)
    except ProcessLookupError:
        return True
    except OSError:
        return False
    return False


def fixture_helper_audit(path):
    descriptor = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        info = os.fstat(descriptor)
        assert stat.S_ISREG(info.st_mode) and info.st_uid == os.getuid() and info.st_nlink == 1
        assert stat.S_IMODE(info.st_mode) == 0o600 and 0 < info.st_size <= 16384
        raw = os.read(descriptor, 16385)
        assert len(raw) == info.st_size and raw.endswith(b"\n")
    finally:
        os.close(descriptor)
    rows = [json.loads(line) for line in raw.decode().splitlines()]
    allowed = {"settings-reconcile", "events-list"}
    assert rows and all(isinstance(row, dict) and set(row) == {"operation", "accepted"}
                        and row["accepted"] is True and row["operation"] in allowed for row in rows)
    assert {row["operation"] for row in rows} == allowed
    return rows


def bootstrap_ready_count(output):
    # Wait for a complete, exact console line, never arbitrary output arguments.
    return len(re.findall(rb"(?m)^[ \t]*DEBUG qml: QML_CI_BOOTSTRAP_READY[ \t]*\r?\n", output))


def bootstrap_verdict(result):
    return result["exit"] == 0 and result["stdout"].strip() == "started" and not result["stderr"].strip()


def run_harness(path, marker, cwd, environment, deadline, stop_on_marker=False, quickshell="quickshell", bootstrap_required=False):
    process = subprocess.Popen([quickshell, "--no-color", "--path", str(path)], cwd=cwd,
                               env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               start_new_session=True)
    output = bytearray()
    kill = None
    bootstrap = None
    stop_requested = False
    timed_out = False
    failure = None
    absence = None
    stop = time.monotonic() + deadline
    try:
        with selectors.DefaultSelector() as selector:
            selector.register(process.stdout, selectors.EVENT_READ)
            while selector.get_map():
                remaining = stop - time.monotonic()
                if remaining <= 0:
                    timed_out = True
                    break
                events = selector.select(timeout=remaining)
                if not events:
                    timed_out = True
                    break
                for key, _mask in events:
                    chunk = os.read(key.fileobj.fileno(), 65536)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        break
                    output.extend(chunk)
                    if len(output) > 8 * 1024**2:
                        raise ValueError("Runtime output exceeded bound")
                    marker_seen = re.search(rb"(?:^|\s)" + marker.encode() + rb"(?:\s|$)", output) is not None
                    loaded = b"Configuration Loaded" in output
                    ready_count = bootstrap_ready_count(output)
                    if ready_count > 1:
                        failure = "Duplicate QML bootstrap readiness marker"
                    if loaded and ready_count == 1 and bootstrap is None:
                        command = [quickshell, "ipc", "--path", str(path), "call", "qml-ci-bootstrap", "start"]
                        started = subprocess.run(command, cwd=cwd, env=environment, capture_output=True, text=True,
                                                 timeout=max(0.001, min(3, stop - time.monotonic())), check=False)
                        bootstrap = {"exit": started.returncode, "stdout": started.stdout, "stderr": started.stderr,
                                     "command": command, "after_configuration_loaded": True}
                        if not bootstrap_verdict(bootstrap):
                            failure = "Owned IPC bootstrap did not return its exact readiness response"
                    if stop_on_marker and not stop_requested and marker_seen and loaded:
                        stop_requested = True
                        if process.poll() is None:
                            killed = subprocess.run([quickshell, "kill", "--path", str(path), "--any-display"],
                                                    cwd=cwd, env=environment, capture_output=True, text=True,
                                                    timeout=max(0.001, min(3, stop - time.monotonic())), check=False)
                            kill = {"exit": killed.returncode, "stdout": killed.stdout, "stderr": killed.stderr}
        if not timed_out:
            process.wait(timeout=max(0.001, stop - time.monotonic()))
            if stop_on_marker:
                _absent, absence = owned_absence(path, cwd, environment, stop, quickshell)
                if not owned_lifecycle_verdict(process.returncode, absence, path):
                    failure = "Owned lifecycle was not verified by engine exit and config absence"
    except subprocess.TimeoutExpired as error:
        timed_out = True
        failure = str(error)
    except (ValueError, OSError) as error:
        failure = str(error)
    finally:
        headless.stop_owned(process)
        if process.stdout is not None:
            output.extend(process.stdout.read(8 * 1024**2 + 1))
            process.stdout.close()
    assert len(output) <= 8 * 1024**2
    raw = output.decode(errors="replace")
    matches = re.findall(r"(?:^|\s)" + re.escape(marker) + r"(?=\s|$)", raw)
    ready_count = bootstrap_ready_count(output)
    session_empty = None
    if bootstrap_required or ready_count:
        session_empty = owned_session_empty(process.pid)
        if not session_empty:
            failure = failure or "Owned IPC test session still had child processes"
        if ready_count != 1 or bootstrap is None or not bootstrap_verdict(bootstrap):
            failure = failure or "Owned IPC bootstrap was missing or invalid"
    accepted = harness_verdict(process.returncode, timed_out, failure, len(matches))
    return {"exit": process.returncode, "timed_out": timed_out, "error": failure, "stdout_stderr": raw,
            "marker": marker, "marker_count": len(matches), "accepted": accepted,
            "deadline": deadline, "stop_on_marker": stop_on_marker,
            "kill": kill, "owned_config_absence": absence,
            "ipc_bootstrap": bootstrap, "bootstrap_ready_count": ready_count,
            "owned_bootstrap_session_empty": session_empty, "bootstrap_required": bootstrap_required}


def canonical_contract(checkout, label):
    script = (checkout / "tests/run_qml_runtime.sh").read_text()
    rows = []
    for file, marker, override in re.findall(r"^run_(?:harness|test) (Runtime\w+Test\.qml) (\w+)(?: ([0-9]+))?(?: \|\| failures=1)?$", script, re.M):
        limit = {"app": 8, "p2p": 4, "mmw": 8, "privacy": 12}[label]
        if label == "p2p":
            assert 'limit=${3:-${QML_RUNTIME_LIMIT:-4}}' in script
            if override:
                assert file == "RuntimePluginSmokeTest.qml" and override == "7"
                limit = int(override)
        else:
            assert not override and "timeout " + str(limit) + ' "$quickshell_bin"' in script
        rows.append({"file": file, "marker": marker, "deadline": limit})
    calls = re.findall(r"^[ \t]*run_(?:harness|test)(?:[ \t].*)?$", script, re.M)
    assert rows and len(rows) == len(calls), "Unparsed canonical harness invocation"
    assert len({row["file"] for row in rows}) == len(rows), "Duplicate canonical harness"
    assert len({row["marker"] for row in rows}) == len(rows), "Duplicate canonical marker"
    return rows


def topology(checkout, label):
    """Mirror each actual runner's file selection; never add private imports."""
    script = (checkout / "tests/run_qml_runtime.sh").read_text()
    root_files = [path for path in checkout.iterdir() if path.is_file() and
                  (label in ("p2p", "privacy") or path.suffix in (".qml", ".js"))]
    if label == "mmw":
        assert 'find "$plugin_dir/tests/qml" -type f' in script
        harnesses = list((checkout / "tests/qml").rglob("Runtime*Test.qml"))
    else:
        assert 'find "$plugin_dir/tests/qml" -maxdepth 1 -type f' in script
        harnesses = list((checkout / "tests/qml").glob("Runtime*Test.qml"))
    links = [(path.name, path) for path in root_files + harnesses]
    if label in ("p2p", "privacy"):
        assert 'ln -s -- "$plugin_dir/tests" "$runtime_dir/tests"' in script
        links.append(("tests", checkout / "tests"))
    if label == "p2p":
        assert 'ln -s -- "$plugin_dir/backend" "$runtime_dir/backend"' in script
        links.append(("backend", checkout / "backend"))
    assert len({name for name, _path in links}) == len(links), "Runtime topology has basename collision"
    return links, harnesses


def seed_fixture(root):
    for relative, content in {
        ".local/state/omarchy/current/theme/colors.toml": 'foreground = "#203040"\nbackground = "#101315"\n',
        ".local/state/omarchy/current/theme/shell.toml": "",
        ".config/omarchy/shell.toml": "",
        ".config/fontconfig/fonts.conf": "<fontconfig/>\n",
        ".local/state/omarchy/toggles/hypr/window-no-gaps.lua": "",
    }.items():
        path = root / "home" / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
    for name, content in {
        "hyprctl": '''#!/bin/sh
set -eu
[ "$#" = 3 ] && [ "$1" = -j ] && [ "$2" = getoption ] || exit 91
case "$3" in decoration:rounding|general:gaps_out) ;; *) exit 92;; esac
printf '%s\\n' '{"int":12}'
''',
    }.items():
        path = root / "bin" / name
        path.write_text(content)
        path.chmod(0o700)


def tool_path(value):
    path = Path(value)
    assert path.is_absolute() and path.is_file() and os.access(path, os.X_OK), 'Executable tool required'
    return str(path.resolve(strict=True))


def execute(args):
    assert os.getuid() != 0, 'Runtime fixtures require the configured nonroot CI step user'
    checkout = args.checkout.resolve(strict=True)
    shell = args.prepared_shell.resolve(strict=True)
    assert checkout.is_dir() and shell.is_dir()
    assert all((shell / name).is_dir() for name in ('Commons', 'Ui'))
    assert args.output.is_absolute() and not args.output.exists() and not args.output.is_symlink()
    args.output.mkdir(mode=0o700)
    root = args.output.resolve(strict=True)
    tools = {name: tool_path(getattr(args, name)) for name in ('quickshell', 'labwc', 'python', 'pw_dump', 'pipewire', 'fc_match')}
    catalog = json.loads(args.negative_catalog.read_text())
    assert catalog.get('schema') == 1 and isinstance(catalog.get('cases'), dict)
    actual = canonical_contract(checkout, args.repository)
    required = {name for repo, name in BOOTSTRAP_CASES if repo == args.repository}
    assert required <= {row['file'] for row in actual}, 'Required production IPC transport case is missing'
    links, harnesses = topology(checkout, args.repository)
    assert {row['file'] for row in actual} == {path.name for path in harnesses}, 'Canonical selection omission'
    for name in ('home', 'bin', 'run', 'config', 'config-dirs', 'cache', 'data', 'state', 'tmp'):
        (root / name).mkdir(mode=0o700)
    (root / 'run/quickshell').mkdir(mode=0o700)
    seed_fixture(root)
    env = {'PATH': str(root / 'bin') + ':/usr/bin:/bin', 'LANG': 'C.UTF-8', 'LC_ALL': 'C.UTF-8',
           'HOME': str(root / 'home'), 'HEADLESS_FIXTURE_ROOT': str(root), 'XDG_RUNTIME_DIR': str(root / 'run'),
           'XDG_CONFIG_HOME': str(root / 'config'), 'XDG_CONFIG_DIRS': str(root / 'config-dirs'),
           'XDG_CACHE_HOME': str(root / 'cache'), 'XDG_DATA_HOME': str(root / 'data'),
           'XDG_STATE_HOME': str(root / 'state'), 'XDG_DATA_DIRS': '/usr/share', 'TMPDIR': str(root / 'tmp'),
           'PYTHONDONTWRITEBYTECODE': '1', 'QT_QUICK_BACKEND': 'software', 'QSG_RHI_BACKEND': 'software',
           'QS_DISABLE_CRASH_HANDLER': '1', 'QML_DISK_CACHE_PATH': str(root / 'cache/qml'),
           'DBUS_SESSION_BUS_ADDRESS': 'unix:path=' + str(root / 'run/no-bus'),
           'WLR_BACKENDS': 'headless', 'WLR_RENDERER': 'pixman', 'WLR_HEADLESS_OUTPUTS': '1',
           'WLR_LIBINPUT_NO_DEVICES': '1', 'LABWC_UPDATE_ACTIVATION_ENV': '0', 'OMARCHY_SHELL_ROOT': str(shell)}
    font = subprocess.run([tools['fc_match'], '-f', '%{family[0]}', 'monospace'], env=env,
                          capture_output=True, text=True, timeout=3, check=True)
    assert font.stdout.strip() and not font.stderr.strip(), 'Real font resolver failed'
    runtime = root / 'runtime tree'; runtime.mkdir()
    for name, path in links:
        (runtime / name).symlink_to(path)
    for name in ('Commons', 'Ui'):
        (runtime / name).symlink_to(shell / name)
    records = []
    accepted = True
    compositor = pipewire = None
    x_paths = []
    receipt = root / 'results.json'
    def record(row):
        records.append(row)
        receipt.write_text(json.dumps({'repository': args.repository, 'records': records}, indent=2) + '\n')
        receipt.chmod(0o600)
        print(json.dumps(row), flush=True)
    record({'kind': 'inventory', 'canonical': actual, 'real_font_family': font.stdout.strip(),
            'runner_sha256': hashlib.sha256((checkout / 'tests/run_qml_runtime.sh').read_bytes()).hexdigest()})
    with (root / 'compositor.log').open('w+') as compositor_log, (root / 'pipewire.log').open('w+') as pwlog:
        try:
            assert not headless.xwayland_processes(), 'Expected isolated container PID namespace'
            if args.repository in ('p2p', 'privacy'):
                compositor, ready = owned_compositor(root, env, compositor_log, tools)
                env.update({'WAYLAND_DISPLAY': ready['display'], 'QT_QPA_PLATFORM': 'wayland',
                            'QT_WAYLAND_DISABLE_WINDOWDECORATION': '1'})
                if ready['owned_lazy_x_display'] is not None:
                    number = ready['owned_lazy_x_display'][1:]
                    x_paths = [Path('/tmp/.X11-unix') / ('X' + number), Path('/tmp') / ('.X' + number + '-lock')]
                    assert all(not p.exists() or p.stat().st_uid == os.getuid() for p in x_paths)
                record({'kind': 'actual_wayland_readiness', **ready})
            else:
                env['QT_QPA_PLATFORM'] = 'offscreen'
            if args.repository == 'privacy':
                pwroot = root / 'pipewire'; pwroot.mkdir(mode=0o700)
                pipewire, pwenv, ready = fixture.start(pwroot, Path(__file__).resolve(), pwlog, tools)
                dropin = root / 'config/pipewire/client.conf.d'; dropin.mkdir(parents=True)
                shutil.copy2(pwroot / 'config/pipewire/client.conf.d/ci-registry-only.conf', dropin)
                env.update({key: pwenv[key] for key in ('PIPEWIRE_REMOTE', 'PIPEWIRE_RUNTIME_DIR')})
                record({'kind': 'actual_pipewire_readiness', **ready})
            for row in actual:
                require_audit = args.repository == 'p2p' and row['file'] == 'RuntimeIpcTransportTest.qml'
                audit_path = root / 'run/qml-ipc-helper-audit.jsonl'
                if require_audit:
                    assert not audit_path.exists() and not audit_path.is_symlink(), 'Helper audit must be fresh for this case'
                result = run_harness(runtime / row['file'], row['marker'], checkout, env,
                                     row['deadline'], stop_on_marker=args.repository == 'privacy', quickshell=tools['quickshell'],
                                     bootstrap_required=(args.repository, row['file']) in BOOTSTRAP_CASES)
                if require_audit:
                    try:
                        result['fixture_helper_audit'] = fixture_helper_audit(audit_path)
                    except (OSError, ValueError, AssertionError) as error:
                        result['fixture_helper_audit_error'] = str(error) or type(error).__name__
                        result['error'] = result['error'] or 'Owned IPC helper audit failed'
                        result['accepted'] = False
                result['expected_negative_diagnostics'] = catalog.get('cases', {}).get(args.repository + '/' + row['file'], {})
                result['warnings_accepted'] = warning_assessment(result['stdout_stderr'], checkout, args.repository, row['file'], catalog)
                result['accepted'] &= result['warnings_accepted']
                accepted &= result['accepted']
                # Raw output is always retained, including the exact asserted negative diagnostics.
                (root / (row['file'] + '.log')).write_text(result['stdout_stderr'])
                record({'kind': 'canonical_runtime_harness', 'harness': row['file'], **result})
        except BaseException:
            accepted = False
            raise
        finally:
            try:
                headless.stop_owned(pipewire)
            finally:
                headless.stop_owned(compositor)
            pwlog.seek(0); pwraw = pwlog.read(1024 * 1024 + 1)
            compositor_log.seek(0); compraw = compositor_log.read(1024 * 1024 + 1)
            assert len(pwraw) <= 1024 * 1024 and len(compraw) <= 1024 * 1024
            pwclean = args.repository != 'privacy' or all(not p.exists() for p in (root / 'pipewire/run').iterdir())
            clean = not headless.xwayland_processes() and all(not p.exists() and not p.is_symlink() for p in x_paths)
            accepted &= not pwraw.strip() and not compraw.strip() and pwclean and clean
            record({'kind': 'owned_fixture_cleanup', 'accepted': accepted, 'pipewire_sockets_removed': pwclean,
                    'owned_x_paths_removed': clean, 'pipewire_log': pwraw, 'compositor_log': compraw})
    if not accepted:
        raise RuntimeError('Canonical runtime or owned fixture acceptance failed; raw artifacts retained')
    record({'kind': 'all_canonical_runtime_accepted', 'count': len(actual), 'raw_logs_retained': True})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--execute', action='store_true')
    parser.add_argument('--registry-ready', type=Path, help=argparse.SUPPRESS)
    parser.add_argument('--pipewire-ready', type=Path, help=argparse.SUPPRESS)
    parser.add_argument('--repository', choices=('app', 'p2p', 'mmw', 'privacy'))
    for name in ('checkout', 'prepared-shell', 'output'):
        parser.add_argument('--' + name, type=Path)
    parser.add_argument('--negative-catalog', type=Path, default=Path(__file__).with_name('qml-runtime-warnings.json'))
    for name in ('quickshell', 'labwc', 'python', 'pw-dump', 'pipewire', 'fc-match'):
        parser.add_argument('--' + name)
    args = parser.parse_args()
    os.umask(0o077)
    if args.registry_ready is not None:
        headless.registry_ready(args.registry_ready); return
    if args.pipewire_ready is not None:
        fixture.ready_helper(args.pipewire_ready); return
    if not args.execute:
        print('INERT: no source, QML, compositor, audio or container execution'); return
    required = ('repository', 'checkout', 'prepared_shell', 'output', 'quickshell', 'labwc', 'python', 'pw_dump', 'pipewire', 'fc_match')
    if any(getattr(args, name) is None for name in required):
        parser.error('Explicit repository, existing prepared shell, fresh output and executable tooling paths required')
    execute(args)


if __name__ == '__main__':
    main()
