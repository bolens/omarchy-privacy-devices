# Contributing

Keep changes predictable, local-first, and consistent with Omarchy Shell.

## Before opening a change

- Search existing issues and pull requests.
- Use the issue forms for bugs, detection problems, backend failures, and
  feature requests.
- Keep each pull request focused on one behavior or maintenance concern.
- Discuss large interface or security changes in an issue first.

## Development setup

Use an up-to-date Omarchy Quattro installation with Omarchy Shell, Quickshell,
Hyprland, PipeWire, Node.js, ShellCheck, and `qmllint`.

```sh
git clone https://github.com/bolens/omarchy-privacy-devices.git
cd omarchy-privacy-devices
```

Install the checkout through Omarchy for integration tests. Use only controls
you can safely restore.

## Validation

Run [TESTING.md](TESTING.md) before submitting. Review
[ARCHITECTURE.md](ARCHITECTURE.md) for runtime changes and
[RELEASING.md](RELEASING.md) for releases.

## Change expectations

- Preserve compatibility with the manifest schema and Omarchy Shell settings.
- Add or update tests for behavior, parsing, process handling, and security
  boundaries.
- Never include secrets, personal device names, or unredacted diagnostic data.
- Run the graphical QML test required by [TESTING.md](TESTING.md).
- Document user-visible changes on the Pages site and in `CHANGELOG.md`.
- Keep custom commands clearly identified as unsandboxed user-controlled code.
- Include screenshots for visible interface changes.

## Pull requests

Explain the problem, the chosen behavior, and how you tested it. CI must pass
before merge. Maintainers may ask for changes that keep controls reversible or
reduce privilege and process-management risk.

## Related documentation

See the [documentation index](DOCUMENTATION.md), [security policy](SECURITY.md),
and [code of conduct](CODE_OF_CONDUCT.md).
