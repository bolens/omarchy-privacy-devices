"""Minimal source-bound backport of Omarchy b83d3df palette qualification."""

import hashlib
import re


class UnsupportedPaletteSyntax(ValueError):
    pass


def palette_positions(text):
    positions = []
    previous = None
    index = 0
    while index < len(text):
        character = text[index]
        if character.isspace():
            index += 1
            continue
        if text.startswith("//", index):
            end = text.find("\n", index + 2)
            index = len(text) if end < 0 else end
            continue
        if text.startswith("/*", index):
            end = text.find("*/", index + 2)
            if end < 0:
                raise UnsupportedPaletteSyntax("Unterminated comment")
            index = end + 2
            continue
        if character in "\"'`":
            quote = character
            start = index
            index += 1
            while index < len(text):
                if text[index] == "\\":
                    index += 2
                elif text[index] == quote:
                    index += 1
                    break
                else:
                    index += 1
            else:
                raise UnsupportedPaletteSyntax("Unterminated string")
            if quote == "`" and re.search(r"\$\{[^}]*\bColor\s*\.", text[start:index]):
                raise UnsupportedPaletteSyntax(
                    "Palette reference inside template requires explicit review"
                )
            previous = "literal"
            continue
        if character == "/" and (
            previous in (None, "return", "throw", "case") or previous in "=(:,[!&|?{;"
        ):
            index += 1
            in_class = False
            while index < len(text):
                if text[index] == "\\":
                    index += 2
                    continue
                if text[index] == "[":
                    in_class = True
                elif text[index] == "]":
                    in_class = False
                elif text[index] == "/" and not in_class:
                    index += 1
                    while index < len(text) and text[index].isalpha():
                        index += 1
                    break
                index += 1
            else:
                raise UnsupportedPaletteSyntax("Unterminated regex")
            previous = "literal"
            continue
        match = re.match(r"[A-Za-z_$][A-Za-z0-9_$]*", text[index:])
        if match:
            token = match.group()
            end = index + len(token)
            following = end
            while following < len(text) and text[following].isspace():
                following += 1
            if (
                token == "Color"
                and previous != "."
                and following < len(text)
                and text[following] == "."
            ):
                positions.append(index)
            previous = token
            index = end
            continue
        previous = character
        index += 1
    return positions


def qualify_palette(source, expected_sha256):
    assert hashlib.sha256(source).hexdigest() == expected_sha256, (
        "Unsupported source drift"
    )
    text = source.decode("utf-8")
    positions = palette_positions(text)
    if not positions:
        return source, 0
    aliases = re.findall(r"(?m)^import (.+?) as Commons\s*$", text)
    assert all(alias == "qs.Commons" for alias in aliases), (
        "Conflicting Commons namespace"
    )
    assert not re.search(r"\b(?:var|let|const)\s+Commons\b", text), (
        "Conflicting Commons binding"
    )
    for position in reversed(positions):
        text = text[:position] + "Commons." + text[position:]
    if not aliases:
        lines = text.splitlines(keepends=True)
        candidates = [
            i for i, line in enumerate(lines) if line.strip() == "import qs.Commons"
        ]
        if not candidates:
            candidates = [
                i for i, line in enumerate(lines) if line.strip() == "import QtQuick"
            ]
        assert candidates, "Missing reviewed module import insertion point"
        lines.insert(candidates[-1] + 1, "import qs.Commons as Commons\n")
        text = "".join(lines)
    assert not palette_positions(text)
    return text.encode("utf-8"), len(positions)
