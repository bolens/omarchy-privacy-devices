#!/usr/bin/env python3
"""Check that CHANGELOG.md stays concise and reader-facing."""

from __future__ import annotations

import re
import sys
from pathlib import Path

CHANGELOG = Path("CHANGELOG.md")
ALLOWED_GROUPS = {"Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"}
MAX_RELEASE_BULLETS = 12
MAX_BULLET_CHARS = 280
RELEASE_RE = re.compile(r"^## \[(?:Unreleased|\d+\.\d+\.\d+)\](?: - \d{4}-\d{2}-\d{2})?$")
LINK_RE = re.compile(r"^\[(?:Unreleased|\d+\.\d+\.\d+)\]: https://")
PR_RE = re.compile(r"\(#\d+\)")
SCOPE_RE = re.compile(r"^- \*\([^)]*\)\*")


def main() -> int:
    if not CHANGELOG.is_file():
        print("CHANGELOG.md is missing", file=sys.stderr)
        return 1

    lines = CHANGELOG.read_text(encoding="utf-8").splitlines()
    errors: list[str] = []
    release = ""
    group = ""
    bullet_start = 0
    bullet_parts: list[str] = []
    release_bullets: dict[str, int] = {}
    active_releases: list[str] = []
    saw_unreleased = False
    release_heading_count = 0

    def fail(line: int, message: str) -> None:
        errors.append(f"CHANGELOG.md:{line}: {message}")

    if not lines or lines[0] != "# Changelog":
        fail(1, "first line must be '# Changelog'")

    def finish_bullet() -> None:
        nonlocal bullet_start, bullet_parts
        if not bullet_parts:
            return
        text = " ".join(part.strip() for part in bullet_parts)
        if release in active_releases and len(text) > MAX_BULLET_CHARS:
            fail(bullet_start, f"bullet is {len(text)} characters; limit is {MAX_BULLET_CHARS}")
        if release in active_releases and PR_RE.search(text):
            fail(bullet_start, "move PR numbers to GitHub release notes")
        if release in active_releases and SCOPE_RE.search(text):
            fail(bullet_start, "remove Conventional Commit scope markup")
        if release in active_releases and "[skip ci]" in text.lower():
            fail(bullet_start, "remove release-automation commit text")
        bullet_start = 0
        bullet_parts = []

    for number, line in enumerate(lines, 1):
        if line.startswith("## "):
            finish_bullet()
            release_heading_count += 1
            if release_heading_count == 1 and line != "## [Unreleased]":
                fail(number, "first release heading must be '## [Unreleased]'")
            if line == "## [Unreleased]" and saw_unreleased:
                fail(number, "duplicate '## [Unreleased]' heading")
            if not RELEASE_RE.fullmatch(line):
                fail(number, "use '## [version] - YYYY-MM-DD' or '## [Unreleased]'")
            release = line
            group = ""
            release_bullets.setdefault(release, 0)
            if len(active_releases) < 2:
                active_releases.append(release)
            saw_unreleased |= line == "## [Unreleased]"
            continue
        if line.startswith("### "):
            finish_bullet()
            if not release:
                fail(number, "category appears before a release heading")
            group = line[4:]
            if group not in ALLOWED_GROUPS:
                fail(number, f"unsupported category '{group}'")
            continue
        if line.startswith("- "):
            finish_bullet()
            if not release:
                fail(number, "bullet appears before a release heading")
            if not group:
                fail(number, "bullet appears before a changelog category")
            bullet_start = number
            bullet_parts = [line]
            release_bullets[release] = release_bullets.get(release, 0) + 1
            continue
        if bullet_parts and (line.startswith("  ") or not line):
            if line:
                bullet_parts.append(line)
            continue
        finish_bullet()
        if line and release in active_releases and not (line.startswith("[") and "]: " in line):
            fail(number, "active releases may contain only headings, bullets, and indented bullet continuations")

    finish_bullet()
    if not saw_unreleased:
        fail(1, "missing '## [Unreleased]'")
    for heading, count in release_bullets.items():
        if heading in active_releases and count > MAX_RELEASE_BULLETS:
            fail(lines.index(heading) + 1, f"{count} bullets; limit is {MAX_RELEASE_BULLETS}")
    if any(line.startswith("[Unreleased]:") for line in lines):
        for number, line in enumerate(lines, 1):
            if line.startswith("[") and "]: " in line and not LINK_RE.match(line):
                fail(number, "comparison links must use HTTPS")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print("CHANGELOG.md: concise changelog contract passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
