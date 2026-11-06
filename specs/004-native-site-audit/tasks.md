# Tasks: Native site accessibility audit

## Phase 1: Setup and design

- [x] T001 Record acceptance before implementation in spec.md and resolve the template with the repository Spec Kit resolver.
- [x] T002 Record public manifest/runtime provenance and lifetime contracts in research.md, plan.md, and contracts/audit.md.

## Phase 2: User Story1 - Repeatable site acceptance

- [x] T003 [US1] Implement owned server/browser readiness and exact score1 propagation in scripts/audit-site.mjs.
- [x] T004 [US1] Add serial pinned build/audit configuration in .woodpecker/site.yml.
- [ ] T005 [US1] Verify missing-input failure and the actual target-site accessibility pipeline; the shared App Drawer canary establishes only the pinned runtime baseline.

## Phase 3: User Story2 - Preserve delivery protections

- [x] T006 [US2] Document the command, retained hosted coverage, image-review responsibility, and adoption gate in TESTING.md and RELEASING.md.
- [ ] T007 [US2] Complete ordinary hooks, independent source review, and exact-head native/hosted proof.
- [ ] T008 [US2] Merge normally and verify genuine-main pipeline before considering hosted retirement.

## Dependencies and execution

T001/T002 precede implementation. T003/T004 may be prepared independently but T005 requires both. Documentation T006 can proceed alongside the worker probe. T007/T008 remain sequential. First deliver the native proof with hosted checks retained; protection/retirement follows only after verified acceptance.
