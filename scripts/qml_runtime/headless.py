#!/usr/bin/env python3
"""Inert by default; owned headless layer-shell readiness and frame experiment."""
import json
import os
import re
import signal
import socket
import stat
import struct
import subprocess
import time
from pathlib import Path

REQUIRED_GLOBALS = {"wl_compositor", "wl_shm", "wl_output", "zwlr_layer_shell_v1"}



def header(object_id, opcode, payload):
    return struct.pack("=II", object_id, ((8 + len(payload)) << 16) | opcode) + payload


def inspect_registry(connection, timeout=10):
    deadline = time.monotonic() + timeout
    connection.sendall(header(1, 1, struct.pack("=I", 2)) + header(1, 0, struct.pack("=I", 3)))
    globals_by_id = {}
    synced = False
    consumed = 0
    def receive_exact(size):
        nonlocal consumed
        data = bytearray()
        while len(data) < size:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError("Wayland registry readiness deadline")
            connection.settimeout(remaining)
            chunk = connection.recv(size - len(data))
            if not chunk:
                raise RuntimeError("Wayland connection closed before readiness")
            data.extend(chunk)
            consumed += len(chunk)
            if consumed > 1024 * 1024:
                raise RuntimeError("Wayland registry response exceeded bound")
        return bytes(data)
    for _event in range(4096):
        object_id, word = struct.unpack("=II", receive_exact(8))
        size, opcode = word >> 16, word & 0xffff
        if size < 8 or size > 65532 or size % 4:
            raise RuntimeError("Invalid Wayland message length")
        payload = receive_exact(size - 8)
        if object_id == 1 and opcode == 0:
            raise RuntimeError("Owned Wayland server reported a protocol error")
        if object_id == 2 and opcode == 0:
            if len(payload) < 12:
                raise RuntimeError("Truncated registry global")
            name, length = struct.unpack_from("=II", payload)
            padded = (length + 3) & ~3
            if not 1 <= length <= 1024 or len(payload) != 12 + padded or payload[8 + length - 1] != 0:
                raise RuntimeError("Invalid registry interface string")
            interface = payload[8:8 + length - 1].decode("ascii")
            version = struct.unpack_from("=I", payload, 8 + padded)[0]
            globals_by_id[name] = (interface, version)
        elif object_id == 2 and opcode == 1:
            if len(payload) != 4:
                raise RuntimeError("Invalid registry removal")
            globals_by_id.pop(struct.unpack("=I", payload)[0], None)
        elif object_id == 3 and opcode == 0:
            if len(payload) != 4:
                raise RuntimeError("Invalid sync callback")
            synced = True
        interfaces = {name: version for name, version in globals_by_id.values()}
        if synced and REQUIRED_GLOBALS <= interfaces.keys():
            if any(interfaces[name] < 1 for name in REQUIRED_GLOBALS):
                raise RuntimeError("Required protocol version is invalid")
            return {name: interfaces[name] for name in sorted(REQUIRED_GLOBALS)}
    raise RuntimeError("Wayland registry event bound exceeded")


def registry_ready(fifo):
    root = Path(os.environ["HEADLESS_FIXTURE_ROOT"]).resolve(strict=True)
    runtime = root / "run"
    assert Path(os.environ["XDG_RUNTIME_DIR"]) == runtime
    assert root.stat().st_uid == os.getuid() and stat.S_IMODE(root.stat().st_mode) == 0o700
    assert fifo.parent == root and fifo.name == "ready.fifo" and not fifo.is_symlink()
    info = fifo.stat()
    assert stat.S_ISFIFO(info.st_mode) and info.st_uid == os.getuid() and stat.S_IMODE(info.st_mode) == 0o600
    try:
        display = os.environ["WAYLAND_DISPLAY"]
        assert re.fullmatch(r"wayland-[0-9]+", display)
        path = runtime / display
        assert not path.is_symlink() and stat.S_ISSOCK(path.stat().st_mode) and path.stat().st_uid == os.getuid()
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
            connection.settimeout(10)
            connection.connect(str(path))
            interfaces = inspect_registry(connection)
        lazy_x_display = os.environ.get("DISPLAY")
        assert lazy_x_display is None or re.fullmatch(r":[0-9]+", lazy_x_display)
        receipt = {"ready": True, "display": display, "protocols": interfaces, "sync_roundtrip": True,
                   "owned_lazy_x_display": lazy_x_display}
    except (AssertionError, OSError, RuntimeError, UnicodeError) as error:
        receipt = {"ready": False, "error": str(error)}
    payload = (json.dumps(receipt) + "\n").encode()
    assert len(payload) <= 4096
    descriptor = os.open(fifo, os.O_WRONLY | os.O_NONBLOCK)
    try:
        assert os.write(descriptor, payload) == len(payload)
    finally:
        os.close(descriptor)


def xwayland_processes():
    result = []
    for path in Path("/proc").glob("[0-9]*/comm"):
        try:
            if path.read_text().strip() == "Xwayland":
                result.append(int(path.parent.name))
        except FileNotFoundError:
            continue
    return result


def stop_owned(process):
    if process is None:
        return
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=3)
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
