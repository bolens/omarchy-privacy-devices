# Agent guidance

Read `.specify/memory/constitution.md`, `SECURITY.md`, `ARCHITECTURE.md`, `TESTING.md`, and `CONTRIBUTING.md` when present.

- Never manipulate live camera, microphone, screen-capture, PipeWire, or compositor state during tests without explicit authorization.
- Treat unknown, pending, unsupported, and degraded observations distinctly; never infer a safe state without evidence.
- Serialize owned settings changes, preserve unrelated configuration, and verify save/reload behavior with regression tests.
- Update QML metadata, properties, defaults, settings UI, IPC, docs, adapters, and tests together.
- Run focused tests, the QML harness, and the full local gate; use visual evidence for screenshot or Pages changes.

## Spec-driven changes

Use Spec Kit for new capabilities, architecture, security-sensitive behavior,
migrations, and coordinated multi-file changes. Keep narrow fixes, dependency
updates, prose edits, and release housekeeping in the normal repository
workflow unless their risk warrants a written specification. Keep completed
feature directories under `specs/` as decision history; do not backfill them for
finished work.
