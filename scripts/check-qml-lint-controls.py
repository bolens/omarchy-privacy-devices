#!/usr/bin/env python3
"""Prove the real QML gate accepts supported fields and rejects real errors."""

import argparse
import configparser
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

CRITICAL = (
    "ImportFailure",
    "MissingProperty",
    "MissingType",
    "UnresolvedType",
    "UnqualifiedAccess",
    "PropertyOverride",
    "RequiredProperty",
)
BASE_SOURCE = (
    "import QtQuick\nimport qs.Commons as Commons\nItem {\n"
    "  readonly property string knownFont: Commons.Style.font.family\n"
)
CASES = (
    ("Valid.qml", "", None, None),
    (
        "MissingProperty.qml",
        "  thisPropertyCannotExist: true\n",
        "thisPropertyCannotExist",
        ("missing-property",),
    ),
    (
        "MissingNested.qml",
        "  readonly property int invalidFont: Commons.Style.font.thisFontMemberCannotExist\n",
        "thisFontMemberCannotExist",
        ("missing-property",),
    ),
    (
        "MissingType.qml",
        "  property ThisTypeCannotExist invalidObject\n",
        "ThisTypeCannotExist",
        ("import", "missing-type", "unresolved-type"),
    ),
)


def check_policy(policy):
    config = configparser.ConfigParser()
    config.optionxform = str
    config.read_string(policy.read_text())
    if config.get("General", "MaxWarnings") != "0":
        raise ValueError("QML lint policy must reject every warning")
    if any(config.get("Warnings", key, fallback="") != "error" for key in CRITICAL):
        raise ValueError(
            "QML lint policy must retain critical property/type/import errors"
        )
    if any(value == "disable" for value in config["Warnings"].values()):
        raise ValueError("QML lint policy must not disable warning categories")


def check_controls(qmllint, shell_root, policy, tooling_import_root=None):
    check_policy(policy)
    for module in ("Commons", "Ui"):
        if not (shell_root / module / "qmldir").is_file():
            raise ValueError("Prepared Omarchy import metadata is missing")
    with tempfile.TemporaryDirectory(prefix="qml-lint-controls-") as temporary:
        root = Path(temporary)
        shutil.copyfile(policy, root / ".qmllint.ini")
        environment = os.environ.copy()
        environment.update(
            {
                "XDG_CACHE_HOME": str(root / "cache"),
                "QML_DISK_CACHE_PATH": str(root / "qml-cache"),
            }
        )
        for name, extra, identifier, categories in CASES:
            (root / name).write_text(BASE_SOURCE + extra + "}\n")
            import_args = ["-I", str(shell_root)]
            if tooling_import_root is not None:
                if not (tooling_import_root / "Quickshell/qmldir").is_file():
                    raise ValueError("Prepared Quickshell tooling imports are missing")
                import_args = [
                    "--bare",
                    "-I",
                    str(tooling_import_root),
                    "-I",
                    str(shell_root),
                    "-I",
                    "/usr/lib/qt6/qml",
                ]
            argv = [
                str(qmllint),
                *import_args,
                "-i",
                str(shell_root / "Commons/qmldir"),
                "-i",
                str(shell_root / "Ui/qmldir"),
                name,
            ]
            result = subprocess.run(
                argv,
                cwd=root,
                env=environment,
                text=True,
                capture_output=True,
                timeout=60,
                check=False,
            )
            output = result.stdout + "\n" + result.stderr
            if len(output.encode()) > 1024 * 1024:
                raise ValueError("QML lint control output exceeded its bound")
            if identifier is None:
                if result.returncode != 0 or re.search(r"\b(?:Warning|Error):", output):
                    raise ValueError(
                        "QML lint rejected the supported nested font field"
                    )
            elif (
                result.returncode <= 0
                or identifier not in output
                or not any("[" + category + "]" in output for category in categories)
            ):
                raise ValueError(
                    "QML lint did not reject the expected error in " + name
                )
    print(
        "QML lint controls passed: supported nested field; missing property, nested field and type rejected"
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qmllint", type=Path, required=True)
    parser.add_argument("--shell-root", type=Path, required=True)
    parser.add_argument("--policy", type=Path, required=True)
    parser.add_argument(
        "--tooling-import-root",
        type=Path,
        default=os.environ.get("QML_TOOLING_IMPORT_ROOT") or None,
    )
    args = parser.parse_args()
    try:
        check_controls(
            args.qmllint.resolve(),
            args.shell_root.resolve(),
            args.policy.resolve(),
            args.tooling_import_root.resolve()
            if args.tooling_import_root is not None
            else None,
        )
    except (
        ValueError,
        OSError,
        subprocess.TimeoutExpired,
        configparser.Error,
    ) as error:
        parser.exit(1, str(error) + "\n")


if __name__ == "__main__":
    main()
