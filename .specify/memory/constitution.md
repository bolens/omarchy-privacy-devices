# Privacy Devices Constitution

## Core Principles

### I. Evidence-Based Device State
Camera, microphone, and screen-capture state MUST reflect verified system evidence. Unknown, pending, unsupported, and degraded observations MUST NOT be reported as safely disabled.

### II. Explicit, Verified Control
Device mutations require explicit user intent, bounded targets, and post-action verification. Failures MUST preserve honest state and actionable diagnostics without exposing private data.

### III. Deterministic Persistence
Settings writes MUST be serialized, atomic where practical, and limited to owned keys. Save/reload cycles MUST preserve the last successful state without stale callbacks or lost updates.

### IV. Synchronized QML Contracts
Module metadata, properties, defaults, settings UI, IPC, documentation, detection adapters, and tests MUST agree. Unsupported capabilities degrade safely.

### V. Isolated Regression Evidence
Tests MUST use fixtures or isolated runtime roots and MUST NOT manipulate live privacy devices. Regressions require coverage across detection, control, persistence, QML, and history where affected.

## Governance

`SECURITY.md`, `ARCHITECTURE.md`, `TESTING.md`, and `CONTRIBUTING.md` define detailed boundaries. Privacy reductions require approval, regression evidence, and a constitution version update.

**Version**: 1.0.0 | **Ratified**: 2026-09-02 | **Last Amended**: 2026-09-02
