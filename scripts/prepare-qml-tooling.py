#!/usr/bin/env python3
"""Prepare the reviewed private import metadata for the pinned QML CI image."""

import argparse
from pathlib import Path
from metadata_profile import prepare_metadata


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        receipt = prepare_metadata(Path("/usr/lib/qt6/qml/Quickshell"), args.output)
    except (ValueError, OSError) as error:
        parser.exit(1, str(error) + "\n")
    print(
        "Prepared private QML tooling imports ("
        + str(receipt["copied_files"])
        + " verified files)"
    )


if __name__ == "__main__":
    main()
