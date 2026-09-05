# omarchy-privacy-devices Spec Kit project guide

Privacy-device observation and explicit control with honest state, bounded subprocesses,
and serialized settings.

Read this guide with `AGENTS.md` and `.specify/memory/constitution.md` before
specifying, planning, or implementing a substantial change. It is project-owned
guidance, not an upstream-managed template.

## Source and ownership map

- `Service.qml`
- `Model.js`
- `PrivacyObserverController.qml`
- `PrivacyControlTransactionController.qml`
- `PrivacySettingsMutationController.qml`
- `privacy-control`
- `TESTING.md`

## Specification and plan decisions

Separate observed evidence from requested device state. Specify unknown, unsupported,
stale, pending, failed, and verified outcomes. Identify confirmation, transaction,
process, observer, settings, and history ownership instead of adding another
coordinator.

## Acceptance evidence

Cover uncertain observations, expired confirmation, failed mutation, verification
timeout, rapid settings writes, stale callbacks, redaction, and recovery. Use fake
device commands and temporary roots; privacy-safe labels require positive evidence.

## Validation and operational limits

```sh
PRIVACY_RUNTIME_TESTS=never npm test
```

Select QML harnesses and scripts/lint-qml when the engine boundary changes. Live camera,
microphone, screen capture, PipeWire, compositor, and privileged helper actions remain
separately authorized. A passing mock test is not evidence that a real device is
disabled.

## Working through Spec Kit

Use Spec Kit for new capabilities, architectural or security-sensitive changes,
migrations, and coordinated changes that need a written contract. Keep narrow fixes,
dependency updates, and prose maintenance in the normal PR workflow.

For a new feature, record observable acceptance criteria in `spec.md`, source ownership
and constitution checks in `plan.md`, and evidence-bearing work in `tasks.md` under the
feature directory created by Spec Kit. Resolve material unknowns before implementation.
Mark tasks complete only after their stated verification, and distinguish completed,
skipped, blocked, and manual checks. Retain completed feature documents as decision
history; do not backfill feature specifications for already finished code.

Keep `.specify/templates/`, `.specify/scripts/`, and generated Codex skills under their
integration manifests. Use this guide and the constitution for local customization.
Regenerate managed files through Spec Kit and verify that project-owned memory survives
updates. Follow `RELEASING.md` for push, merge, release or delivery, and recovery.
