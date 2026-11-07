"""Pure, source-bound negative diagnostic classification; raw logs stay intact."""
import hashlib
import re
from collections import Counter
from pathlib import Path

DIAGNOSTIC = re.compile(r"\b(?:WARN|ERROR|FATAL|CRITICAL)\b", re.I)
FAULT = re.compile(r"TypeError|ReferenceError|SyntaxError|binding loop|Unable to assign|Cannot assign|deprecated", re.I)


def warning_assessment(raw, checkout, repository, harness, catalog):
    if FAULT.search(raw):
        return False
    lines = [line.strip() for line in raw.splitlines() if DIAGNOSTIC.search(line)]
    entry = catalog.get('cases', {}).get(repository + '/' + harness)
    if entry is None:
        return not lines
    source_files = entry.get('source_files', {})
    if not source_files or 'tests/qml/' + harness not in source_files:
        return False
    for name, digest in source_files.items():
        rel = Path(name)
        if rel.is_absolute() or '..' in rel.parts:
            return False
        path = checkout / rel
        if not path.is_file() or path.is_symlink() or hashlib.sha256(path.read_bytes()).hexdigest() != digest:
            return False
    text = (checkout / 'tests/qml' / harness).read_text()
    if not all(value in text for value in entry.get('caller_evidence', [])):
        return False
    if 'expected_qml_messages' in entry:
        messages = []
        for line in lines:
            match = re.fullmatch(r'WARN qml: (.*)', line)
            if match is None:
                return False
            messages.append(match[1])
        return Counter(messages) == Counter(entry['expected_qml_messages'])
    return Counter(lines) == Counter(entry.get('expected_exact_warning_lines', {}))
