# Tasks: Native site accessibility audit

## Phase 1: Setup and design

- [x] T001 Record acceptance before implementation in spec.md and resolve the template with the repository Spec Kit resolver.
- [x] T002 Record public manifest/runtime provenance and lifetime contracts in research.md, plan.md, and contracts/audit.md.

## Phase 2: User Story1 - Repeatable site acceptance

- [x] T003 [US1] Implement owned server/browser readiness and exact score1 propagation in scripts/audit-site.mjs.
- [x] T004 [US1] Add serial pinned build/audit configuration in .woodpecker/site.yml.
- [x] T005 [US1] Verify missing-input failure and the actual target-site accessibility pipeline; the shared App Drawer canary establishes only the pinned runtime baseline.

## Phase 3: User Story2 - Preserve delivery protections

- [x] T006 [US2] Document the command, retained hosted coverage, image-review responsibility, and adoption gate in TESTING.md and RELEASING.md.
- [x] T007 [US2] Complete ordinary hooks, independent source review, and exact-head native/hosted proof.
- [x] T008 [US2] Merge normally and verify genuine-main pipeline before considering hosted retirement.

## Dependencies and execution

T001/T002 precede implementation. T003/T004 may be prepared independently but T005 requires both. Documentation T006 can proceed alongside the worker probe. T007/T008 remain sequential. First deliver the native proof with hosted checks retained; protection/retirement follows only after verified acceptance.

## Phase 4: Hosted browser handoff

- [x] T009 Preserve reusable release/manual browser coverage and real repository checks in the proposed handoff; cover the selection contract with source regressions.
- [ ] T010 Record accepted native main/protection evidence, independent handoff review and normal hooks before publishing the proposal.
- [ ] T011 Verify exact-head native/hosted checks, merge normally and confirm genuine-main site and Pages acceptance.

## Initial native adoption evidence

Reviewed candidate `3a966f8b7918087c2762cc81b9094b03535aec82` passed ordinary hooks, independent review, hosted
checks and the native plugin/site pair in pipeline `25/7`. The identical merged
main tree `8eeba2c9aef9c2dba1e441018c9bbd13906e1e2f` passed native pipeline `25/8`,
all hosted platform checks and Pages deployment. Native plugin/site contexts are
required with the other protected checks preserved.
