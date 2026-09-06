# Agent guidance

[Documentation](DOCUMENTATION.md) maps architecture, deployment, state, and document ownership.

For behavior or architecture changes, read [.specify/memory/constitution.md](.specify/memory/constitution.md)
and the relevant parts of [ARCHITECTURE.md](ARCHITECTURE.md). Use [TESTING.md](TESTING.md) to select and run
checks, and [CONTRIBUTING.md](CONTRIBUTING.md) for commit and contribution requirements. Read
[SECURITY.md](SECURITY.md) before changing detection, control, commands, or trust boundaries.

- Never manipulate live camera, microphone, screen-capture, PipeWire, or compositor state during tests without explicit authorization.
- Treat unknown, pending, unsupported, and degraded observations distinctly; never infer a safe state without evidence.
- Serialize owned settings changes, preserve unrelated configuration, and verify save/reload behavior with regression tests.
- Update QML metadata, properties, defaults, settings UI, IPC, docs, adapters, and tests together.
- Run focused tests and the full local gate; include the QML harness for QML runtime behavior changes. Use visual evidence for screenshot or Pages changes.

## Planning and evidence

Use the [project guide](.specify/memory/project-guide.md) and
[constitution](.specify/memory/constitution.md) for substantial changes. The guide
owns Spec Kit scope, retained history, retrospective requirements, and acceptance
evidence. Prose maintenance uses the normal repository workflow.

## Context and handoffs

- Search before reading. Use bounded source excerpts for exploratory reads over
  350 lines, and inspect required guidance and actual source before editing.
- When delegation is permitted, assign a bounded question or output, paths, and
  check. Return source locations, changes, and verification gaps for final review.
- Keep durable corrections in the [project guide](.specify/memory/project-guide.md)
  or owning contract. Replace superseded advice and read it before reuse.
  Temporary progress belongs in task notes. Preserve existing authority rules.
