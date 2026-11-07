# omarchy-privacy-devices Spec Kit project guide

[Documentation](../../DOCUMENTATION.md)

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
history. Backfill finished work only when explicitly requested. Label those
specifications as retrospective baselines, record the inspected revision, and map
requirements to source and acceptance evidence. Separate observed behavior from
corrective requirements. Never imply the specification preceded its code or mark
unverified checks complete.

Keep `.specify/templates/`, `.specify/scripts/`, and generated Codex skills under their
integration manifests. Use this guide and the constitution for local customization.
Regenerate managed files through Spec Kit and verify that project-owned memory survives
updates. Follow `RELEASING.md` for push, merge, release or delivery, and recovery.

The retrospective specification register is [specs/README.md](../../specs/README.md).

## Native CI evidence rules

The tested Woodpecker 3.20.1 configuration places `network_mode: none` directly on the step, with server schema support for that compatibility field. A nested Docker backend option did not enforce isolation. Bind acceptance to the actual pipeline container lifecycle, UID 10042, network mode, CPU quota, memory and swap limits, full runtime inventory and cleanup result.

A Docker workflow container must receive its primary network during creation. Attaching that network later can retain resolver configuration from the initial network. Diagnose the container creation contract before changing host or repository DNS settings.

When overriding NPM user and global configurations, use distinct empty private files. Reusing `/dev/null` for both failed with NPM 11. Install locked dependencies during networked preparation, then validate the prepared dependency tree offline without reinstalling it. Remove invocation-owned configuration and cache scratch on success and failure.

Record final-head checks, ordinary merge, genuine-main checks and selected Pages behavior separately in `specs/005-qml-warning-validation/tasks.md`. A successful PR or merge alone does not complete T016. Preserve explicit qualification limits and leave omitted checks open.
