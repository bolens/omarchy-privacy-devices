"""Private source-bound QML tooling metadata; never changes installed files."""

import hashlib
import json
from pathlib import Path
import re
import shutil
import stat
import subprocess

CORE_SHA256 = "aec65666b60e2f7973ed94b91cc61c1e9c96b36fe2978409a12fdfdb039cdbce"


INPUTS = {
    "_Window/quickshell-window.qmltypes": (
        "0e6f53cac2a93833274b9ac9ba128e56f0b30ba63edc029334e140f710e4a9d7",
        ["Margins", "PopupAnchor"],
    ),
    "Services/Pipewire/quickshell-service-pipewire.qmltypes": (
        "869fbdd4394e71c3c8bb94bdd395a7fa58c8a59e6012bd1e101edadc4b62dcd0",
        ["UntypedObjectModel"],
    ),
    "Wayland/_WlrLayerShell/quickshell-wayland-layershell.qmltypes": (
        "4c07419c958a1be0845753cc235509f18ae69d7480a9b3d49c2ad0b447927c18",
        ["Margins"],
    ),
}


def component_blocks(text):
    result = {}
    cursor = 0
    while True:
        start = text.find("    Component {", cursor)
        if start < 0:
            return result
        index = text.index("{", start)
        depth = 0
        quote = None
        while index < len(text):
            char = text[index]
            if quote:
                if char == "\\":
                    index += 2
                    continue
                if char == quote:
                    quote = None
            elif char in "\"'":
                quote = char
            elif char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    end = index + 1
                    if text[end : end + 1] == "\n":
                        end += 1
                    raw = text[start:end]
                    name = re.search(r'\bname: "([^"]+)"', raw)
                    assert name is not None and name[1] not in result
                    result[name[1]] = (start, end, raw)
                    cursor = end
                    break
            index += 1
        else:
            raise AssertionError("Unterminated installed component metadata")


def resolve_core_closure(relative, data, core):
    expected, _names = INPUTS[relative]
    assert hashlib.sha256(data).hexdigest() == expected
    assert hashlib.sha256(core).hexdigest() == CORE_SHA256
    source_blocks = component_blocks(core.decode())
    names = (
        ["Margins", "PopupAnchor", "Box", "Edges", "PopupAdjustment"]
        if relative.startswith("_Window/")
        else list(_names)
    )
    text = data.decode()
    evidence = []
    for name in names:
        assert name in source_blocks, "Missing actual core component: " + name
        raw = source_blocks[name][2]
        # These are private declarations of existing C++ types, not new QML exports.
        projection, exports = re.subn(r"(?ms)^        exports: \[.*?\]\n", "", raw)
        projection, revisions = re.subn(
            r"(?m)^        exportMetaObjectRevisions: \[[^\n]*\]\n", "", projection
        )
        assert exports == 1 and revisions == 1
        assert projection.count("isCreatable: false") == raw.count("isCreatable: false")
        # Exact upstream headers declare Q_DECLARE_FLAGS(Flags, Enum). Qt's generated
        # metadata omits that typedef because it only sees Q_ENUM_NS(Enum).
        if name in ("Edges", "PopupAdjustment"):
            enum_marker = '        Enum {\n            name: "Enum"\n'
            assert projection.count(enum_marker) == 1
            assert (
                'alias: "Flags"' not in projection and "isFlag: true" not in projection
            )
            projection = projection.replace(
                enum_marker,
                enum_marker + '            alias: "Flags"\n            isFlag: true\n',
                1,
            )
        local = component_blocks(text)
        if name in local:
            begin, end, previous = local[name]
            assert "isTypeOpaque: true" in previous, (
                "Refuse to replace an actual local declaration"
            )
            text = text[:begin] + projection + text[end:]
        else:
            end = text.rfind("}")
            assert end > 0
            text = text[:end] + projection + text[end:]
        assert component_blocks(text)[name][2] == projection
        evidence.append(
            {
                "name": name,
                "actual_core_body_sha256": hashlib.sha256(raw.encode()).hexdigest(),
                "private_body_sha256": hashlib.sha256(projection.encode()).hexdigest(),
                "removed_only_export_bookkeeping": True,
                "cpp_flag_alias_completed": name in ("Edges", "PopupAdjustment"),
                "actual_body": raw,
            }
        )
    return text.encode(), evidence


EXPECTED_PACKAGES = [
    "quickshell 0.3.2-1",
    "qt6-base 6.12.0-3",
    "qt6-declarative 6.12.0-4",
]


def verify_packages():
    try:
        result = subprocess.run(
            ["/usr/bin/pacman", "-Q", "quickshell", "qt6-base", "qt6-declarative"],
            text=True,
            capture_output=True,
            timeout=30,
            check=True,
        )
    except (OSError, subprocess.SubprocessError) as error:
        raise ValueError("Use the pinned Arch QML CI toolchain") from error
    if result.stdout.splitlines() != EXPECTED_PACKAGES:
        raise ValueError("Unsupported QML toolchain version; use the pinned CI image")


def load_profile():
    data = json.loads(Path(__file__).with_name("metadata-profile.json").read_text())
    if data["packages"] != EXPECTED_PACKAGES or len(data["files"]) != 72:
        raise ValueError("The complete reviewed metadata profile is required")
    return data


def prepare_metadata(source, output):
    source = source.resolve(strict=True)
    if output.exists() or output.is_symlink():
        raise ValueError("QML tooling output must be a new directory")
    output = output.resolve()
    if output == source or source in output.parents or output in source.parents:
        raise ValueError("QML tooling output must be separate from installed metadata")
    verify_packages()
    profile = load_profile()
    expected = profile["files"]
    for relative in expected:
        path = Path(relative)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError("Invalid reviewed metadata path")
    observed = {}
    for path in source.rglob("*"):
        selected = path.suffix in (".qmltypes", ".qml", ".js") or path.name == "qmldir"
        if selected and path.is_symlink():
            raise ValueError("Unsupported QML tooling source link")
        if path.is_file() and selected:
            if path.stat().st_size > 2 * 1024**2:
                raise ValueError("Unsupported QML tooling source file")
            relative = str(path.relative_to(source))
            data = path.read_bytes()
            if (
                relative not in expected
                or hashlib.sha256(data).hexdigest() != expected[relative]
            ):
                raise ValueError("QML tooling source differs from the reviewed profile")
            observed[relative] = data
    if (
        set(observed) != set(expected)
        or sum(map(len, observed.values())) > 16 * 1024**2
    ):
        raise ValueError("Incomplete or oversized QML tooling source")
    for relative, (digest, _names) in INPUTS.items():
        if hashlib.sha256(observed[relative]).hexdigest() != digest:
            raise ValueError("Unsupported Quickshell metadata declaration")
    core = observed["quickshell-core.qmltypes"]
    prepared = observed.copy()
    changes = {}
    for relative in INPUTS:
        transformed, evidence = resolve_core_closure(relative, observed[relative], core)
        prepared[relative] = transformed
        changes[relative] = {
            "before_sha256": expected[relative],
            "after_sha256": hashlib.sha256(transformed).hexdigest(),
            "source_components": [
                {key: value for key, value in row.items() if key != "actual_body"}
                for row in evidence
            ],
        }
    # Materialize only verified immutable bytes, after all transforms have succeeded.
    output.mkdir(mode=0o700)
    identity = output.stat().st_dev, output.stat().st_ino
    try:
        for relative, data in prepared.items():
            target = output / "Quickshell" / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        receipt = {
            "profile": profile["name"],
            "packages": EXPECTED_PACKAGES,
            "copied_files": len(prepared),
            "changes": changes,
            "cpp_header_provenance": profile["cpp_header_provenance"],
            "installed_metadata_changed": False,
        }
        if any(
            hashlib.sha256((source / relative).read_bytes()).hexdigest()
            != expected[relative]
            for relative in expected
        ):
            raise ValueError("Installed QML tooling changed during preparation")
        (output / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    except BaseException:
        info = output.lstat()
        if stat.S_ISDIR(info.st_mode) and (info.st_dev, info.st_ino) == identity:
            shutil.rmtree(output)
        raise
    return receipt
