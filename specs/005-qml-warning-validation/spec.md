# Feature Specification: Reliable QML validation and palette compatibility

**Feature Branch**: `codex/qml-ci-warning-cleanup-20261106`

**Created**: 2026-11-06

**Status**: Planned

**Input**: Fix actual CI QML warnings for Privacy Devices, preserve behavior, and make validation deterministic without hiding real errors.

## User Scenarios & Testing

### User Story 1 - Trust the validation result (Priority: P1)

A maintainer can distinguish valid plugin behavior from an actual missing member,
unknown type or invalid binding before merging a change.

**Why this priority**: A quiet log cannot establish correctness when the same gate accepts deliberate mistakes.

**Independent Test**: Validate the maintained source inventory and intentionally invalid controls in the same supported environment.

**Acceptance Scenarios**:

1. Given valid source and its real dependencies, validation completes with no actionable diagnostics.
2. Given a nonexistent member, type or nested theme token, validation fails with a nonzero result and identifies the cause.
3. Given an attempted replacement of an immutable token object, validation fails; a permitted mutable child remains usable.

### User Story 2 - Keep supported runtime behavior (Priority: P1)

A plugin user retains the intended palette and interactions when the supported
runtime evolves, including when a dependency introduces a colliding type name.

**Why this priority**: A source-only pass must not conceal broken runtime palette resolution.

**Independent Test**: Exercise isolated original and updated runtime cases with the same fixture inputs.

**Acceptance Scenarios**:

1. Given the supported older environment, explicit palette resolution preserves the existing result.
2. Given the current environment, the plugin still uses the shell palette and its existing public fields.
3. Given changed theme inputs, values update without replacing token objects or changing their readonly and mutable contracts.
4. Given valid existing interactions, when the compatibility correction is applied, then preserve honest unknown/degraded observations, isolated device fixtures, bounded process ownership and superseded-result rejection.

### User Story 3 - Reproduce the result (Priority: P2)

A maintainer can repeat a check from recorded inputs and obtain a source-bound
result, including a clear failure when those inputs drift.

**Why this priority**: Timing guesses, unknown dependency state and retries cannot justify a merge.

**Independent Test**: Recreate the isolated validation inputs and verify that intentional source drift is rejected.

**Acceptance Scenarios**:

1. Given identical recorded inputs, the same validation and behavior checks apply.
2. Given missing dependencies, unsupported source drift or incomplete setup, the result reports failure or an explicit gap.
3. Given a failed check, diagnosis precedes any new run; unchanged retries do not substitute for proof.

### Edge Cases

- Dependency module discovery differs from physical directory layout.
- A new dependency type shadows a previously valid shell palette name.
- Anonymous token declarations hide real fields from static validation.
- A callback arrives after timeout, replacement or configuration supersession.
- A host or window is absent during component construction.
- A fixture lacks executable permissions or runtime readiness.

## Requirements

### Functional Requirements

- **FR-001**: Diagnose warnings from actual CI inputs and distinguish import/setup defects, real source defects and dependency metadata limitations.
- **FR-002**: Preserve the existing supported source inventory, public runtime API, palette values and behavior boundaries.
- **FR-003**: Reject real missing members, types, nested tokens and invalid readonly assignments with demonstrably failing controls.
- **FR-004**: Remove broad warning hides once their causes are corrected; retain or strengthen existing error checks.
- **FR-005**: Bind dependency compatibility inputs to verified source and fail clearly on unsupported drift.
- **FR-006**: Any temporary validation representation must preserve every real public field, its type, object identity, reactivity and mutability, with isolated runtime comparison evidence.
- **FR-007**: Keep installed vendor files, live desktop state, devices, services, unrelated settings and existing backups outside the change.
- **FR-008**: Preserve process ownership and failure ordering; do not replace completion callbacks to avoid diagnostics.
- **FR-009**: Require actual final-head and genuine-main checks before declaring delivery; report omitted platform or runtime checks accurately.
- **FR-010**: Document dependency refresh, validation and remaining unsupported cases without claiming unverified acceptance.
- **FR-011**: Run strict QML lint, real invalid controls and the complete canonical runtime inventory as required Woodpecker checks, independent of GitHub minutes. Prepare public immutable inputs separately, then validate offline as an ordinary container user with owned display/audio fixtures and no host sockets or devices.
- **FR-012**: Every managed Omarchy plugin must run actual child-client IPC transport checks in Woodpecker through its production handlers, with exact owned-instance selection, observed registration readiness, asserted responses and negative argument handling. Use only in-memory service/widget state and bounded owned helpers; no host IPC or live actions.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Every maintained source target completes with zero actionable diagnostics under the corrected gate.
- **SC-002**: Every deliberately invalid control fails, while all valid controls pass in the same environment.
- **SC-003**: Paired runtime evidence preserves all expected fields and types, all token object identities, readonly failures, permitted writes and reactive results.
- **SC-004**: Supported older and current palette behavior agree for the same inputs.
- **SC-005**: Acceptance evidence names the tested revision and contains no concealed setup failures or unchanged retry loop.
- **SC-006**: Actual final-head and genuine-main Woodpecker jobs execute every registered runtime harness, including the durable palette contract, and reject unexpected warnings, missing markers, setup gaps or incomplete cleanup.
- **SC-007**: Retain App Drawer's twenty-call and Privacy's twenty-three-call transport cases; add one production-handler case for each missing repository. The complete canonical inventory includes both new cases without removing any existing case.

## Assumptions

- The current supported Omarchy baseline remains supported; an unreviewed moving branch cannot silently replace it.
- This work changes repository validation and necessary compatibility fixes; it does not install a desktop, control live devices/services, publish a product release or alter global CI access.
- Diagnostic work and narrow source corrections were prepared before this specification. This specification governs the remaining coordinated compatibility and gate integration and claims no completed runtime acceptance.
