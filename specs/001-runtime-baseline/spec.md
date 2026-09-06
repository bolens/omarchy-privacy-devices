# Feature specification: Evidence-based privacy observation and explicit control

**Created**: 2026-09-05
**Status**: Retrospective baseline
**Inspected revision**: `48c76a19cf70068af5dfb96d2166c61d04d07b6f`
**Input**: The owner requested a fleet-wide Spec Kit retrofit and implementation audit.

This retrospective baseline maps the existing plugin architecture and behavioral contracts to their source owners and available acceptance evidence.

This specification records existing contracts after implementation. It does not
claim that the original work followed Spec Kit. New behavior requires a separate
change contract. Existing feature specifications remain authoritative within their
own scope.

## User scenarios and testing

### User story 1: Use the stock-shell feature (P1)

A user interacts with the plugin through its documented bar and settings entry points.

**Acceptance**: Model and contract fixtures preserve the invariants below; source delivery does not replace the running shell.

### User story 2: Recover from change and failure (P2)

Monitor, settings, dependency, or subprocess state changes while the plugin is active.

**Acceptance**: The named failure and lifecycle tests preserve ownership, pending state, and recovery rather than presenting unsupported success.

### User story 3: Maintain the plugin safely (P3)

A maintainer changes a shared behavior or setting.

**Acceptance**: Manifest, model, QML, helpers, docs, and tests remain one contract, with real-engine verification selected for affected QML behavior.

## Requirements

- **FR-001**: Unknown, stale, pending, unsupported, and degraded observations MUST not be labeled safely disabled.
- **FR-002**: Control success MUST require bounded post-action observation matching the request, with honest timeout and partial-failure outcomes.
- **FR-003**: Subprocess and observer ownership MUST serialize operations, bound retries, and reject stale callbacks.
- **FR-004**: Settings and history writes MUST sanitize input, serialize changes, preserve owned state, and use private atomic durable storage.
- **FR-005**: Display, diagnostics, notification, and support paths MUST apply documented text sanitation and redaction.
- **FR-006**: Privileged built-in controls MUST retain fixed paths and allowlists; custom capture commands MUST remain explicitly identified as user-controlled unsandboxed code.

## Success criteria

- **SC-001**: Every requirement has a named source owner and acceptance check in `coverage.md`.
- **SC-002**: The listed native checks pass for the reviewed candidate, with unavailable environments and operational checks recorded separately.
- **SC-003**: Retrofitting preserves existing interfaces and completed specifications. Any confirmed implementation gap is corrected under an explicit requirement before it is marked complete.

## Edge cases and operational limits

Portable fixtures and static QML checks do not prove live compositor, service, device, or rendered interaction behavior. Real-engine harnesses listed in TESTING.md remain required when their runtime boundary changes. This baseline does not authorize installation, live control, stress tests, screenshot capture against the running shell, or marketplace publication.
