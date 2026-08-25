# Documentation

This index separates user guidance, contributor contracts, and project policy.
Each topic has one canonical owner so changes can be linked instead of copied.

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

When a change spans topics, update each canonical owner but avoid repeating
procedures or command matrices. Cross-link to the owner instead.
