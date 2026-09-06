# Agent guidance

Before Spec Kit planning or implementation, read
`.specify/memory/project-guide.md` with the project constitution. It maps
requirements to this repository's source, acceptance evidence, and validation.

For behavior or architecture changes, read `.specify/memory/constitution.md`
and the relevant parts of `ARCHITECTURE.md`. Use `TESTING.md` to select and run
checks, and `CONTRIBUTING.md` for commit and contribution requirements. Read
`SECURITY.md` before changing detection, control, commands, or trust boundaries.

- Never manipulate live camera, microphone, screen-capture, PipeWire, or compositor state during tests without explicit authorization.
- Treat unknown, pending, unsupported, and degraded observations distinctly; never infer a safe state without evidence.
- Serialize owned settings changes, preserve unrelated configuration, and verify save/reload behavior with regression tests.
- Update QML metadata, properties, defaults, settings UI, IPC, docs, adapters, and tests together.
- Run focused tests and the full local gate; include the QML harness for QML runtime behavior changes. Use visual evidence for screenshot or Pages changes.

## Spec-driven changes

Use Spec Kit for new capabilities, architecture, security-sensitive behavior,
migrations, and coordinated multi-file changes. Keep narrow fixes, dependency
updates, prose edits, and release housekeeping in the normal repository
workflow unless their risk warrants a written specification. Keep completed
feature directories under `specs/` as decision history. Backfill finished work
only when explicitly requested. Label those
specifications as retrospective baselines, record the inspected revision, and map
requirements to source and acceptance evidence. Separate observed behavior from
corrective requirements. Never imply the specification preceded its code or mark
unverified checks complete.

## Context and handoffs

- Locate source with targeted searches before reading. For exploratory reads of
  files over 350 lines, select relevant ranges. Read required guidance and actual
  source before edits or correctness claims; summaries do not replace them.
- When delegation is permitted, give each worker one question or concrete output,
  allowed paths, and a check. Return findings with source locations, changed paths,
  and verification gaps. Keep final review with the coordinating agent.
- Record durable user corrections in the [project guide](.specify/memory/project-guide.md)
  or owning contract with scope, reason, and evidence. Replace superseded advice;
  read relevant corrections before reusing assumptions. Keep temporary progress
  in task notes and preserve existing authority rules.
