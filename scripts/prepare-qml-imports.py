#!/usr/bin/env python3
"""Prepare reviewed CI-only Omarchy imports without changing installed source."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import stat

from qml_palette import qualify_palette
from qml_tokens import refine

BASE = Path(__file__).resolve().parent


def load_profile():
    profile = json.loads((BASE / "qml-import-profile.json").read_text())
    if (
        profile["revision"] != "13f18b2cb7286fb54f87daf571a031aa6af3d8f0"
        or len(profile["files"]) != 175
    ):
        raise ValueError("Complete supported Omarchy source profile is required")
    return profile


def prepare(source, output):
    source = source.resolve(strict=True)
    if output.exists() or output.is_symlink():
        raise ValueError("Prepared QML imports require a new output directory")
    output = output.resolve()
    if output == source or source in output.parents or output in source.parents:
        raise ValueError("Prepared imports must be separate from original source")
    profile = load_profile()
    expected = profile["files"]
    for name, row in expected.items():
        if (
            Path(name).is_absolute()
            or ".." in Path(name).parts
            or row["mode"] not in ("100644", "100755")
        ):
            raise ValueError("Invalid supported source profile path or mode")
    observed = {}
    for path in source.rglob("*"):
        if path.is_symlink():
            raise ValueError("Omarchy import source must not contain links")
        if path.is_file():
            name = str(path.relative_to(source))
            row = expected.get(name)
            if row is None or path.stat().st_size != row["bytes"]:
                raise ValueError("Omarchy source differs from supported revision")
            if bool(path.stat().st_mode & 0o111) != (row["mode"] == "100755"):
                raise ValueError(
                    "Omarchy source executable mode differs from supported revision"
                )
            data = path.read_bytes()
            blob = hashlib.sha1(
                b"blob " + str(len(data)).encode() + b"\0" + data
            ).hexdigest()
            if (
                hashlib.sha256(data).hexdigest() != row["sha256"]
                or blob != row["git_blob"]
            ):
                raise ValueError("Omarchy source differs from supported revision")
            observed[name] = data
        elif not path.is_dir():
            raise ValueError("Unsupported special file in Omarchy imports")
    if set(observed) != set(expected) or sum(map(len, observed.values())) > 8 * 1024**2:
        raise ValueError("Omarchy import source is incomplete or oversized")
    prepared = observed.copy()
    changed = references = 0
    for name, data in observed.items():
        row = expected[name]
        transformed, count = (
            qualify_palette(data, row["sha256"])
            if Path(name).suffix == ".qml"
            else (data, 0)
        )
        if (
            count != row["palette_references"]
            or hashlib.sha256(transformed).hexdigest() != row["palette_sha256"]
        ):
            raise ValueError("Palette backport differs from reviewed upstream change")
        changed += bool(count)
        references += count
        prepared[name] = transformed
    if (changed, references) != (54, 249):
        raise ValueError("Reviewed palette backport inventory does not match")
    groups = {}
    for filename in ("Style.qml", "Color.qml"):
        name = "Commons/" + filename
        transformed, fields = refine(
            filename, prepared[name], expected[name]["palette_sha256"]
        )
        prepared[name] = transformed
        groups[filename] = fields
    if sum(map(len, groups.values())) != 11:
        raise ValueError("Reviewed token group inventory does not match")
    output.mkdir(mode=0o700)
    identity = output.stat().st_dev, output.stat().st_ino
    try:
        for name, data in prepared.items():
            target = output / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            target.chmod(int(expected[name]["mode"], 8) & 0o777)
        if any(
            hashlib.sha256((source / name).read_bytes()).hexdigest() != row["sha256"]
            for name, row in expected.items()
        ):
            raise ValueError("Original Omarchy source changed during preparation")
        receipt = {
            "source_revision": profile["revision"],
            "palette_upstream": profile["palette_upstream"],
            "source_files": len(prepared),
            "palette_files": changed,
            "palette_references": references,
            "named_groups": groups,
            "original_source_changed": False,
            "prepared_hashes": {
                name: hashlib.sha256(data).hexdigest()
                for name, data in prepared.items()
            },
        }
        (output / "compatibility-receipt.json").write_text(
            json.dumps(receipt, indent=2) + "\n"
        )
    except BaseException:
        info = output.lstat()
        if stat.S_ISDIR(info.st_mode) and (info.st_dev, info.st_ino) == identity:
            shutil.rmtree(output)
        raise
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-shell", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        receipt = prepare(args.source_shell, args.output)
    except (ValueError, OSError) as error:
        parser.exit(1, str(error) + "\n")
    print(
        "Prepared private QML imports ("
        + str(receipt["source_files"])
        + " verified files)"
    )


if __name__ == "__main__":
    main()
