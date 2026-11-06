# Feature Specification: Native site accessibility audit

**Feature Branch**: `codex/woodpecker-plugin-cutover-20261106`
**Created**: 2026-11-06
**Status**: Planned
**Input**: Continue practical GitHub CI migration and make browser startup deterministic.

## User Scenarios & Testing

### User Story 1 - Repeatable site acceptance (Priority: P1)

A maintainer receives an accessibility result from a fixed browser rather than the changing hosted-runner browser.

**Independent Test**: Build the existing site and run its actual accessibility audit in the pinned unprivileged image.

**Acceptance Scenarios**:

1. Given the built site, when its owned HTTP server is listening and the owned browser exposes DevTools, then run the existing accessibility audit and require score exactly 1.
2. Given startup, navigation, or audit failure, when the command terminates, then fail CI and close only its owned processes.

### User Story 2 - Preserve delivery protections (Priority: P2)

A maintainer adopts native browser acceptance without losing existing repository or release validation.

**Independent Test**: Observe an actual final-head native site check before changing hosted selection or protection.

**Acceptance Scenarios**:

1. Given the initial native proposal, when a PR runs, then hosted browser validation remains active.
2. Given a fork PR, when approved validation runs, then it receives no publishing secrets or privileged host access.
3. Given accepted native PR/main evidence and a required site context, ordinary GitHub PR/main runs retain real repository checks and use native browser acceptance.
4. Given a reusable release caller or manual GitHub dispatch, hosted browser validation remains available; reusable defaults and the explicit signed-release input stay true.

### Edge Cases

Missing site, missing browser, malformed report, non-perfect score, browser disconnect, and HTTP startup failure fail the check. Cleanup must not select processes by name or fixed shared ports.

## Requirements

- **FR-001**: Reuse the existing site builder, site tests, locked Lighthouse dependency, and exact score-1 acceptance.
- **FR-002**: Pin public clone, build-toolchain, and Chrome/Puppeteer images by digest.
- **FR-003**: Await server listening and actual browser readiness; use owned ephemeral ports rather than fixed sleeps.
- **FR-004**: Run without privileged mode, extra capabilities, host mounts/socket, or secrets.
- **FR-005**: Serialize site build then browser audit in one bounded workflow; close only owned browser/server resources.
- **FR-006**: Preserve hosted checks and release callers until actual native proof and reviewed protection changes agree.

## Success Criteria

- **SC-001**: An actual native final-head run builds/tests the site and reports accessibility score exactly 1.
- **SC-002**: Missing browser or invalid report produces nonzero status without an unchanged retry loop.
- **SC-003**: PR and genuine-main acceptance evidence identify the exact tested revisions and pipeline results.

## Assumptions

The existing public CI site, fork-approval policy, and Linux amd64 agents remain available. This change does not publish a release, deploy a desktop, or change site content.
