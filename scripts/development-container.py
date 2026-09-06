#!/usr/bin/env python3
"""Build and run the repository's source-free development image locally."""

import argparse
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys

IMAGE = "localhost/omarchy-privacy-devices-dev:latest"


def command(engine, operation, root, args=(), interactive=False):
    binary = "container" if engine == "apple" else engine
    archive = root / ".devenv" / "containers" / f"{engine}.tar"
    if operation == "load":
        return [binary, "image", "load", "--input", str(archive)]
    result = [binary, "run", "--rm", "--workdir", "/workspace"]
    if interactive:
        result += ["--interactive", "--tty"]
    if engine == "podman":
        result += ["--userns=keep-id"]
    result += ["--user", f"{os.getuid()}:{os.getgid()}"]
    result += ["--mount", f"type=bind,source={root},target=/workspace", IMAGE]
    return result + list(args or ["bash"])


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=["build", "run"])
    parser.add_argument("engine", choices=["docker", "podman", "apple"])
    parser.add_argument("args", nargs=argparse.REMAINDER)
    options = parser.parse_args(argv)
    root = Path(__file__).resolve().parent.parent
    if "," in str(root):
        parser.error("container bind mounts require a checkout path without commas")
    if options.engine == "apple" and sys.platform != "darwin":
        parser.error("Apple container requires macOS; build an OCI image on a Linux builder")
    binary = "container" if options.engine == "apple" else options.engine
    if not shutil.which(binary):
        parser.error(f"{binary} is not installed or is not on PATH")
    args = options.args[1:] if options.args[:1] == ["--"] else options.args
    if options.operation == "build":
        if args:
            parser.error("build does not accept a command")
        if not shutil.which("devenv"):
            parser.error("devenv is required to build the development image")
        machine = {"arm64": "aarch64", "aarch64": "aarch64", "x86_64": "x86_64"}.get(platform.machine())
        if machine is None:
            parser.error("supported image architectures are x86_64 and aarch64")
        archive = root / ".devenv" / "containers" / f"{options.engine}.tar"
        archive.parent.mkdir(parents=True, exist_ok=True)
        transport = "docker-archive" if options.engine == "docker" else "oci-archive"
        result = subprocess.run([
            "devenv", "--system", f"{machine}-linux", "container",
            "--registry", f"{transport}:{archive}:", "copy", "shell",
        ], cwd=root, check=False)
        if result.returncode:
            return result.returncode
        return subprocess.run(command(options.engine, "load", root), check=False).returncode
    return subprocess.run(command(options.engine, "run", root, args, sys.stdin.isatty()), check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
