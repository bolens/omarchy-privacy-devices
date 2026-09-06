# Documentation

Privacy-device evidence, verified control, and retained local state.

## Start here

| Need | Owning document |
| --- | --- |
| Use the project | [README.md](README.md) |
| Change the repository | [AGENTS.md](AGENTS.md) |
| Deliver or recover | [RELEASING.md](RELEASING.md) |
| Plan substantial changes | [.specify/memory/project-guide.md](.specify/memory/project-guide.md) |
| Non-negotiable constraints | [.specify/memory/constitution.md](.specify/memory/constitution.md) |

## Architecture

[ARCHITECTURE.md](ARCHITECTURE.md) separates observation, confirmation, mutation, verification,
presentation, and settings ownership. Unknown or unsupported evidence must not appear as safely
disabled. [SECURITY.md](SECURITY.md) owns the privacy boundary and [TESTING.md](TESTING.md) owns
isolated evidence requirements.

## Deployment and recovery

[README](README.md) and the linked user guide own installation and operation.
[RELEASING.md](RELEASING.md) owns plugin delivery and recovery. Device controls and desktop reloads
remain operational actions, separate from validating or installing source.

## Database and state

[Settings mutations](PrivacySettingsMutationController.qml) and [history](privacy-history) have
different owners and lifetimes. Preserve unrelated settings during save and restore. History can
contain sensitive activity, so it is not a fixture or public diagnostic attachment. Keep retention
and history-disabled behavior aligned with the user guide.

## Documentation maintenance

Keep decisions, invariants, failure modes, and recovery requirements in the owning document. Link to
commands, defaults, schemas, and generated catalogs instead of copying them. Change the owner and
affected references together. Update this index when adding or moving a guide, and verify relative
links and heading anchors. Historical specs and audits describe their recorded revision, not current
runtime proof. A topic without an implementation stays explicitly unimplemented.

## Topic guides

## Users

- [README](README.md): project overview, highlights, and quick installation.
- [Website and user guide](https://bolens.github.io/omarchy-privacy-devices/):
  requirements, controls, configuration, privacy behavior, troubleshooting,
  and lifecycle commands.
- [Support](SUPPORT.md): where and how to request help.
- [Security policy](SECURITY.md): private vulnerability reporting and supported
  security scope.
- [Changelog](CHANGELOG.md): released and pending user-visible changes.

## Contributors and maintainers

- [Contributing](CONTRIBUTING.md): development workflow and change expectations.
- [Architecture](ARCHITECTURE.md): repository layout, runtime ownership,
  invariants, security boundaries, and performance constraints.
- [Testing](TESTING.md): canonical validation commands and live verification.
- [Release playbook](RELEASING.md): versioning, publication, verification, and
  recovery.

## Project policy

- [Code of conduct](CODE_OF_CONDUCT.md): community participation standards.
- [License](LICENSE): MIT license terms.

## Documentation ownership

Update the narrowest canonical document and link to it elsewhere:

| Change | Canonical documentation |
| --- | --- |
| Installation, controls, settings, or troubleshooting | Website user guide |
| Current interface screenshots and social preview | `preview.png` and `docs/` media |
| Project summary or headline capabilities | `README.md` |
| Runtime ownership, invariants, or repository structure | `ARCHITECTURE.md` |
| Commands, test coverage, or verification procedure | `TESTING.md` |
| Contribution workflow or pull-request expectations | `CONTRIBUTING.md` |
| Versioning or publication procedure | `RELEASING.md` |
| Security scope, trust boundary, or disclosure process | `SECURITY.md` |
| Support routing or diagnostic-sharing guidance | `SUPPORT.md` |
| User-visible release history | `CHANGELOG.md` |

- [Editor setup](.vscode/README.md)
