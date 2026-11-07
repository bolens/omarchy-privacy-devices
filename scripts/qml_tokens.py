"""Source-bound named-type experiment; never changes installed vendor files."""

import hashlib
import re

PATTERN = re.compile(
    r"(?ms)^  readonly property QtObject ([a-zA-Z][a-zA-Z0-9]*): QtObject \{\n(.*?)^  \}"
)
EXPECTED = {
    "Style.qml": ("spacing", "font", "bar"),
    "Color.qml": (
        "bar",
        "popups",
        "tooltip",
        "notifications",
        "menu",
        "polkit",
        "lock",
        "imagePicker",
    ),
}


def refine(name, source, expected_sha256):
    assert hashlib.sha256(source).hexdigest() == expected_sha256, (
        "Unsupported vendor source"
    )
    text = source.decode("utf-8")
    groups = []

    def replace(match):
        field, body = match.groups()
        typename = field[0].upper() + field[1:] + "Tokens"
        assert "component " + typename not in text
        groups.append(
            {
                "name": field,
                "type": typename,
                "body_sha256": hashlib.sha256(body.encode()).hexdigest(),
                "fields": re.findall(
                    r"(?m)^    (?:readonly )?property [A-Za-z][A-Za-z0-9]* ([A-Za-z][A-Za-z0-9]*):",
                    body,
                ),
            }
        )
        return (
            "  component "
            + typename
            + ": QtObject {\n"
            + body
            + "  }\n"
            + "  readonly property "
            + typename
            + " "
            + field
            + ": "
            + typename
            + " {}"
        )

    result = PATTERN.sub(replace, text)
    assert tuple(group["name"] for group in groups) == EXPECTED[name]
    assert text.startswith("pragma Singleton\n")
    result = result.replace(
        "pragma Singleton\n", "pragma Singleton\npragma ComponentBehavior: Bound\n", 1
    )
    return result.encode("utf-8"), groups
