# Tasks: Reliable QML validation and palette compatibility

**Input**: [spec.md](spec.md), [plan.md](plan.md), research and validation model.

## Phase 1: Setup

- [x] T001 Record the actual baseline revision and diagnostic limitations in `specs/005-qml-warning-validation/research.md`.
- [x] T002 Freeze reviewed dependency/source identities and compatibility provenance in maintainer-only import preparation metadata.

## Phase 2: Foundational

- [x] T003 Prepare a guarded private vendor palette backport and conditional named token declarations in `scripts/prepare-qml-imports.py`; preserve every actual field body and reject unknown source hashes.
- [x] T004 Wire `scripts/lint-qml` to the actual module contexts and runtime harness topology without dropping source targets.
- [x] T005 Preserve `.gitattributes` release exclusions and actual installed vendor files while integrating maintainer-only preparation.

## Phase 3: User Story 1 — Trust validation (P1)

**Independent test**: The complete actual inventory passes, while real missing member/type/nested token/readonly controls fail.

- [x] T006 [US1] Add executable positive and negative environment/gate regressions in `tests/test_qml_lint.py` before declaring strict acceptance.
- [x] T007 [US1] Repair diagnosed source ownership/type issues in `BarWidget.qml` and affected root components; preserve callback bodies and fallback semantics.
- [x] T008 [US1] Remove broad hides and enforce genuine failing diagnostics in `.qmllint.ini`, then run the full `scripts/lint-qml` inventory and controls.

## Phase 4: User Story 2 — Preserve runtime behavior (P1)

**Independent test**: Older/current palette results and original/named token contracts agree under actual isolated engines.

- [x] T009 [P] [US2] Qualify the existing shell palette in affected root QML and `tests/qml/` using the official upstream namespace-fix basis; retain all values and expressions.
- [x] T010 [US2] Add isolated palette/runtime compatibility coverage to `tests/qml/` and its canonical `tests/run_qml_runtime.sh` inventory.
- [x] T011 [US2] Prove all public fields/types, object identities, readonly slot failures, mutable children and reactive values with actual older/current and original/named engine cases; record evidence here.

## Phase 5: User Story 3 — Reproduce acceptance (P2)

**Independent test**: Source/image identity mismatch fails clearly, and final-head plus genuine-main results identify the accepted inputs.

- [x] T012 [US3] Add changed/missing dependency-source and cleanup/failure-path controls to `tests/test_qml_lint.py`; preserve the validation evidence state rules in `data-model.md`.
- [ ] T013 [US3] Coordinate accepted immutable CI image publication/adoption in `.woodpecker/` and retained `.github/workflows/` consumers, keeping existing protected/ref-scoped publication.

- [ ] T017 [US3] Make `scripts/woodpecker-plugin.sh` and `.woodpecker/plugin.yml` require the complete canonical QML runtime suite through an owned nonroot/offline fixture, including strict warning classification, preparation boundaries and failure controls.

- [ ] T018 [US3] Require actual IPC client transport in the native canonical suite: preserve the existing App Drawer and Privacy cases, add bounded production-handler cases only to P2P Services and Multi-Monitor Workspaces, and verify owned registration, responses, negative arguments and cleanup.

## Phase 6: Delivery

- [x] T014 Update `TESTING.md`, `RELEASING.md` and `CHANGELOG.md` with the supported palette/environment procedure and verified behavior correction.
- [ ] T015 Run full portable, actual QML/engine, site and retained hosted gates on the independently reviewed final head; append exact results here without marking omitted checks complete.
- [ ] T016 Merge normally with fresh expected-head/review/check guards, verify genuine-main and selected Pages behavior, and record the accepted revision here.

## Dependencies and parallel work

T001→T002→T003 establishes source-bound preparation. T004/T005 can follow that shared
foundation independently. US1 strict-policy/test work and US2 consumer qualification
use separate files and can progress in parallel; US1's final full-source acceptance
joins the completed palette compatibility work. US3 image adoption and delivery require
both source and runtime evidence. No publication precedes the required proof.

## Implementation strategy

Deliver correct import discovery and diagnosed narrow source fixes first, then explicit
palette compatibility and validated token declarations. Enable strict final gates only
with their real positive/negative proof. Reuse the accepted immutable candidate for
all checks; inspect failures before any new run. Diagnostic/model prototypes are not
completed runtime acceptance, and no live desktop or product release is part of this list.

## Accepted compatibility evidence, 2026-11-06

The reviewed source-bound palette backport follows official Omarchy
`b83d3df0840504299d3099ebf391eb8110527edd` on supported
`13f18b2cb7286fb54f87daf571a031aa6af3d8f0`. An independent source audit verified
all 175 original blobs against that immutable Git tree, the 54 changed vendor files
against the official change set, and the owned consumer qualifications separately.
All eleven actual token field bodies remain identical.

Both the prior pinned toolchain (`293b0457…`, Qt 6.11.2 / Quickshell 0.3.1) and the
retained unpublished candidate (`94cf69d5…`, Qt 6.12.0 / Quickshell 0.3.2) completed
real paired original/named engine checks. Within each toolchain the complete
snapshots agree: eleven object identities, all 98 public field records per phase,
readonly replacement rejection, mutable palette fields and reactive values.
Static wrong-field and readonly controls also reject invalid input. This proves the
specific vendor representation and palette compatibility, rather than complete
plugin or legacy-bar runtime acceptance. Full source, actual behavior, final-head
and genuine-main delivery tasks remain open.

## Preparation and guard evidence, 2026-11-06

The actual dated Qt 6.12 / Quickshell 0.3.2 candidate passed all four repositories'
source and tooling preparation entry points. Each admitted the complete 175-file
Omarchy profile with its executable modes and the exact 72-file installed metadata
profile. Pure boundary tests reject changed, missing, extra and symlinked inputs,
mode drift, output collisions and unsafe cleanup. An initially incomplete diagnostic
packet was rejected before lint; the corrected packet's complete inventory was
verified against all four source profiles before execution.

All four repositories' real-linter controls passed: the supported nested font field
was accepted, while an invalid property, nested member and type were rejected with
the expected identifiers and categories. These controls do not imply a complete
source or runtime pass. The same actual run still reported residual source/tooling
issues; full source acceptance, all existing runtime harnesses, published-image
admission and final-head/main delivery remain open.

## Accepted strict source evidence, 2026-11-06

The complete strict source gates now pass with exact target inventories and zero
structured diagnostics: App Drawer 8, P2P Services 103, Multi-Monitor Workspaces 6
and Privacy Devices 119. All four real positive/negative controls pass. Structured
results exposed real loop-scope diagnostics that Qt's text logger omitted; the
variables were corrected after scope review, with explicit declarations retained
where later loops previously reused function-scoped variables. Source ownership
and optional-host protocol changes retain their separate behavior checks.

The legacy App Drawer forward-declaration failure was reproduced with minimal
late/early declaration controls. Moving the unchanged ModuleSlot declaration
before its users resolves that toolchain defect; its known Row/Column Loader uses
an Item view for implicit dimensions. The legacy file remains in lint, with no
claim of full legacy-bar runtime coverage. All existing runtime harnesses and
final published-image/PR/main joins remain separate delivery requirements.

## Accepted durable palette contract evidence

The canonical palette harness passed in all four repositories using the actual
published immutable toolchain. Each process exited naturally, emitted its single
marker and produced no Qt warnings. All 87 declared fields and eleven inherited
object names retained their types and original values; the eleven owner objects
kept their identities and readonly slots, child writes remained permitted, and
reactive bindings were restored. An actual Qt color wrapper exposed a live
property reference; taking its string value before mutation made restoration
independent of that reference. The source regression reproduces that failure and
passes with the scalar snapshot. Owned display/audio resources and sockets were
removed with empty logs. Final complete native and IPC inventories remain
separate acceptance requirements.
