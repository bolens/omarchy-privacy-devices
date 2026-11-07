# Implementation Plan: Reliable QML validation

**Branch**: `codex/qml-ci-warning-cleanup-20261106` | **Date**: 2026-11-06 | **Spec**: [spec.md](spec.md)

## Summary

Correct actual import discovery and source ownership diagnostics, qualify the shell
palette explicitly for older and current Qt, and restore a strict source-bound gate.
A temporary vendor type representation is conditional on real paired engine proof.

## Technical Context

- Existing QML/JavaScript, Bash, Python and repository test suites; no new application dependency.
- Supported Omarchy source remains immutable 13f18b2cb7286fb54f87daf571a031aa6af3d8f0.
- The reviewed candidate uses signed Arch 2026-11-06, Qt 6.12.0 and Quickshell 0.3.2; adopt only its verified immutable image digest after acceptance.
- `scripts/lint-qml and tests/run_all.sh` owns this repo's existing QML inventory. Private staging must mirror actual runtime imports.
- No persistent storage or live host state changes; all proof roots and processes are owned and disposable.
- Current warning/error acceptance, portable behavior, relevant engine cases, negative controls, hosted retained checks and genuine-main proof are required.

## Constitution Check

Honest device state, explicit control, process ownership and supersession remain unchanged; the completed location collector must pass its real output.

Before implementation and after design: preserve the existing runtime/public API,
settings ownership, isolated HOME/XDG/process scope and honest evidence. No devices,
services, desktop reload, product release or installed vendor file is changed.
No constitution exception is proposed. Runtime and delivery acceptance remain pending.

## Project Structure

### Documentation (this feature)

`spec.md`, `plan.md`, `research.md`, `data-model.md`, `quickstart.md`, quality checklist
and evidence-bearing `tasks.md` belong here. Existing history is retained.

### Source Code

- Root QML: explicit Commons palette resolution and diagnosed source fixes.
- Existing lint/test entry points: real module contexts, complete target inventory and strict error policy.
- Maintainer-only import preparation: guarded private vendor copy, official palette namespace backport and conditional named token declarations.
- CI image consumers and release/testing docs: exact accepted image and reproducible refresh procedure.
- Native CI: a public-input preparation step followed by required nonroot, offline portable/static/control/runtime validation. `scripts/qml-runtime-fixture.py` parses the existing canonical runner; its owned compositor and PipeWire helpers use observed protocol readiness, preserve per-harness deadlines and retain raw diagnostics.
- IPC coverage: preserve App Drawer and Privacy's actual child-client cases; add one missing transport case each for P2P and Multi-Monitor Workspaces, using production handlers with mock application state and source-proven initial registration readiness.

**Structure Decision**: Keep runtime files and entry points in their current locations.
Maintainer-only validation entry points do not add an application runtime API.

## Acceptance Sequence

1. Verify actual CI diagnostics and immutable source/image identities.
2. Backport only official palette qualification into a private supported-source copy and qualify owned consumers; preserve all other expressions.
3. Compare older/current palette behavior, then compare unmodified/named token contracts after the same explicit palette compatibility correction.
4. Diagnose the complete source inventory under strict policy, repair actual residuals and demonstrate all invalid controls fail.
5. Require actual offline Woodpecker static/control/runtime jobs and applicable retained checks on the final head. Publish/adopt the reviewed CI image through the existing trusted publisher only after proof.
6. Merge normally with expected-head and required checks; verify genuine main and selected Pages behavior.

## Complexity Tracking

No governance violation. Reject broad disables, fake integer metadata, var/bracket
escapes, altered process completion semantics and unreviewed moving dependencies.
An explicit validated dynamic boundary may project the existing optional QObject
bar-host protocol into typed readonly fields; this does not hide opaque vendor
token members. Its custom/null/malformed hosts, receivers, reactivity and readonly
behavior require real engine proof.
