# Agent guidance

Read `.specify/memory/constitution.md`, `SECURITY.md`, `ARCHITECTURE.md`, `TESTING.md`, and `CONTRIBUTING.md` when present.

- Never manipulate live camera, microphone, screen-capture, PipeWire, or compositor state during tests without explicit authorization.
- Treat unknown, pending, unsupported, and degraded observations distinctly; never infer a safe state without evidence.
- Serialize owned settings changes, preserve unrelated configuration, and verify save/reload behavior with regression tests.
- Update QML metadata, properties, defaults, settings UI, IPC, docs, adapters, and tests together.
- Run focused tests, the QML harness, and the full local gate; use visual evidence for screenshot or Pages changes.
