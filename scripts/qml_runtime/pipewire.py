"""Owned PipeWire server/real registry readiness, without hardware or host audio."""
import codecs
import hashlib
import json
import os
import selectors
import stat
import subprocess
from pathlib import Path

from .headless import stop_owned

REMOTE = "pipewire-ci"


class JsonArrays:
    def __init__(self):
        self.buffer = ""
        self.total = 0
        self.decoder = json.JSONDecoder()
        self.utf8 = codecs.getincrementaldecoder("utf-8")()

    def feed(self, data):
        self.total += len(data)
        if self.total > 4 * 1024**2:
            raise ValueError("PipeWire registry output exceeded bound")
        self.buffer += self.utf8.decode(data)
        output = []
        while self.buffer.strip():
            self.buffer = self.buffer.lstrip()
            try:
                value, end = self.decoder.raw_decode(self.buffer)
            except json.JSONDecodeError:
                break
            if not isinstance(value, list) or not all(isinstance(row, dict) and isinstance(row.get("id"), int) for row in value):
                raise ValueError("Invalid actual pw-dump registry shape")
            output.append(value)
            self.buffer = self.buffer[end:]
        return output


def assert_no_hardware(rows):
    assert all(row.get("type") not in ("PipeWire:Interface:Node", "PipeWire:Interface:Device") for row in rows)


def ready_helper(fifo):
    assert os.getuid() != 0, "Runtime fixtures require a nonroot caller"
    root = Path(os.environ["PIPEWIRE_FIXTURE_ROOT"]).resolve(strict=True)
    assert root.stat().st_uid == os.getuid() and stat.S_IMODE(root.stat().st_mode) == 0o700
    assert Path(os.environ["XDG_RUNTIME_DIR"]) == root / "run"
    assert os.environ["PIPEWIRE_REMOTE"] == REMOTE and os.environ["PIPEWIRE_RUNTIME_DIR"] == str(root / "run")
    assert fifo == root / "pipewire-ready.fifo" and not fifo.is_symlink()
    info = fifo.stat()
    assert stat.S_ISFIFO(info.st_mode) and info.st_uid == os.getuid() and stat.S_IMODE(info.st_mode) == 0o600
    result = subprocess.run([os.environ["QML_TOOL_PW_DUMP"], "--no-colors", "--remote", REMOTE], text=True,
                            capture_output=True, check=False, timeout=10)
    assert result.returncode == 0 and not result.stderr.strip()
    assert len(result.stdout.encode()) < 4 * 1024**2
    rows = json.loads(result.stdout)
    assert isinstance(rows, list) and any(row.get("type") == "PipeWire:Interface:Core" for row in rows)
    assert_no_hardware(rows)
    registry = root / "initial-registry.json"
    assert not registry.exists() and not registry.is_symlink()
    registry.write_text(result.stdout)
    registry.chmod(0o600)
    payload = (json.dumps({"ready": True, "actual_pw_dump_core_sync": True, "remote": REMOTE,
                           "registry_sha256": hashlib.sha256(registry.read_bytes()).hexdigest(),
                           "object_count": len(rows), "stderr": result.stderr}) + "\n").encode()
    assert len(payload) <= 4096
    descriptor = os.open(fifo, os.O_WRONLY | os.O_NONBLOCK)
    try:
        assert os.write(descriptor, payload) == len(payload)
    finally:
        os.close(descriptor)


def prepare(root, helper, tools):
    assert root.is_dir() and stat.S_IMODE(root.stat().st_mode) == 0o700
    for name in ("run", "home", "config", "cache", "data", "state"):
        (root / name).mkdir(mode=0o700)
    # Real installed client.conf remains authoritative. This owned drop-in
    # disables features unavailable/unneeded for a no-audio registry fixture.
    dropin = root / "config/pipewire/client.conf.d"
    dropin.mkdir(parents=True)
    (dropin / "ci-registry-only.conf").write_text('''context.properties = {
  module.rt = false
  loop.rt-prio = 0
  context.num-data-loops = 0
  support.dbus = false
  mem.allow-mlock = false
}
''')
    fifo = root / "pipewire-ready.fifo"
    os.mkfifo(fifo, 0o600)
    arguments = json.dumps([str(helper), "--pipewire-ready", str(fifo)])
    config = root / "pipewire-ci.conf"
    config.write_text('''context.properties = {
  core.daemon = true
  core.name = pipewire-ci
  support.dbus = false
  loop.rt-prio = 0
  context.num-data-loops = 0
  mem.allow-mlock = false
}
context.spa-libs = { support.* = support/libspa-support }
context.modules = [
  { name = libpipewire-module-protocol-native }
  { name = libpipewire-module-metadata }
  { name = libpipewire-module-access args = { access.socket = { pipewire-ci = "unrestricted", pipewire-ci-manager = "unrestricted" } } }
]
context.objects = []
context.exec = [
  { path = ''' + json.dumps(tools['python']) + ''' args = ''' + arguments + ''' }
]
''')
    env = {"PATH": "/usr/bin:/bin", "PYTHONDONTWRITEBYTECODE": "1", "LANG": "C.UTF-8", "LC_ALL": "C.UTF-8", "HOME": str(root / "home"),
           "PIPEWIRE_FIXTURE_ROOT": str(root), "PIPEWIRE_RUNTIME_DIR": str(root / "run"), "PIPEWIRE_REMOTE": REMOTE,
           "XDG_RUNTIME_DIR": str(root / "run"), "XDG_CONFIG_HOME": str(root / "config"), "XDG_CACHE_HOME": str(root / "cache"),
           "XDG_DATA_HOME": str(root / "data"), "XDG_STATE_HOME": str(root / "state"), "XDG_DATA_DIRS": "/usr/share",
           "DBUS_SESSION_BUS_ADDRESS": "unix:path=" + str(root / "run/no-session-bus")}
    env["QML_TOOL_PW_DUMP"] = tools["pw_dump"]
    return config, fifo, env


def start(root, helper, log, tools):
    config, fifo, environment = prepare(root, helper, tools)
    descriptor = os.open(fifo, os.O_RDWR | os.O_NONBLOCK)
    process = subprocess.Popen([tools["pipewire"], "--config", str(config)], cwd=root, env=environment,
                               stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
    pidfd = os.pidfd_open(process.pid)
    try:
        with selectors.DefaultSelector() as selector:
            selector.register(descriptor, selectors.EVENT_READ, "ready")
            selector.register(pidfd, selectors.EVENT_READ, "exit")
            events = selector.select(timeout=15)
            if not events or any(key.data == "exit" for key, _mask in events):
                raise RuntimeError("Owned PipeWire failed actual registry readiness")
            payload = os.read(descriptor, 4097)
            assert payload.endswith(b"\n") and len(payload) <= 4096
            ready = json.loads(payload)
            assert ready["ready"] and ready["actual_pw_dump_core_sync"] and ready["remote"] == REMOTE
            registry = root / "initial-registry.json"
            assert registry.is_file() and not registry.is_symlink() and registry.stat().st_uid == os.getuid()
            assert registry.stat().st_size < 4 * 1024**2
            assert hashlib.sha256(registry.read_bytes()).hexdigest() == ready["registry_sha256"]
            ready["objects"] = json.loads(registry.read_text())
            assert len(ready["objects"]) == ready["object_count"]
            assert_no_hardware(ready["objects"])
            for name in (REMOTE, REMOTE + "-manager"):
                socket = root / "run" / name
                assert not socket.is_symlink() and stat.S_ISSOCK(socket.stat().st_mode) and socket.stat().st_uid == os.getuid()
            ready["owned_normal_and_manager_sockets"] = True
        return process, environment, ready
    except BaseException:
        stop_owned(process)
        raise
    finally:
        os.close(pidfd)
        os.close(descriptor)
