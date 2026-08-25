# Contributing

Thanks for helping improve Privacy Devices. User-facing behavior should remain
predictable, local-first, and consistent with Omarchy Shell conventions.

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

Install the checkout through Omarchy when testing integration behavior. Do not
test destructive privacy controls against devices or sessions you cannot
restore.

## Validation

Run the full validation set before submitting a pull request:

```sh
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Service.qml
shellcheck privacy-control privacy-deps privacy-recording privacy-screenshot
node tests/model.test.js
node tests/security.test.js
tidy -errors -quiet docs/index.html docs/404.html
xmllint --noout docs/favicon.svg docs/sitemap.xml
npm ci
npm run build:site
npm run test:site
npx lighthouse http://127.0.0.1:4173/ --only-categories=accessibility
```

See [RELEASING.md](RELEASING.md) for the maintainer release checklist.

## Change expectations

- Preserve compatibility with the manifest schema and Omarchy Shell settings.
- Add or update tests for behavior, parsing, process handling, and security
  boundaries.
- Never include secrets, personal device names, or unredacted diagnostic data.
- Run `tests/run_qml_runtime.sh` in a graphical session to exercise shared model code in the real Quickshell JavaScript engine.
- Document user-visible changes on the Pages site and in `CHANGELOG.md`.
- Keep custom commands clearly identified as unsandboxed user-controlled code.
- Include screenshots for visible interface changes.

## Pull requests

Explain the problem, the chosen behavior, and how you tested it. CI must pass
before merge. Maintainers may ask for changes that keep controls reversible or
reduce privilege and process-management risk.
