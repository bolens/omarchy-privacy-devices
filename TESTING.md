# Testing

Tests are organized around stable behavior boundaries rather than QML internals.

## Fast behavior suite

```sh
node tests/model.test.js
node tests/controls.test.js
node tests/sessions.test.js
node tests/settings.test.js
node tests/runtime.test.js
node tests/security.test.js
node tests/release.test.js
python3 -m unittest discover -s tests -p 'test_*.py'
shellcheck privacy-control privacy-deps privacy-recording privacy-screenshot
```

The JavaScript suites cover classification, settings sanitation, normalized
sessions, control transitions, visual-state policy, manifest/UI contracts,
runtime process topology, and static security invariants. Python tests execute
the helpers against temporary state and fake commands so privileged services,
devices, screenshots, and recordings are never modified.

The release metadata test keeps the manifest, changelog comparison links,
issue template, and tag-validation workflow synchronized.

## QML and plugin validation

Validate a clean archive so local dependencies such as `node_modules` are not
mistaken for plugin contents:

```sh
validation_dir=$(mktemp -d)
git archive HEAD | tar -x -C "$validation_dir"
omarchy plugin validate "$validation_dir"
qmllint -I "$OMARCHY_PATH/shell" \
  BarWidget.qml Service.qml SettingsSurface.qml IntegerSetting.qml \
  PrivacyActivityCard.qml
```

In a graphical session, exercise shared JavaScript in the real Quickshell
engine:

```sh
tests/run_qml_runtime.sh
```

## Repository and site checks

```sh
ruby scripts/validate-issue-forms.rb
tidy -errors -quiet docs/index.html docs/404.html
xmllint --noout docs/favicon.svg docs/sitemap.xml
npm ci
npm audit --audit-level=moderate
npm run build:site
npm run test:site
```

CI additionally checks links and requires a Lighthouse accessibility score of
at least 0.95.

## Live verification

After changing monitoring, IPC, settings, controls, or layout:

1. Deploy the changed runtime files to the installed plugin.
2. Restart Omarchy Shell.
3. Confirm the `privacy-devices` and `privacy-devices-settings` IPC targets
   exist.
4. Inspect redacted diagnostics and status for healthy observers, fresh
   heartbeats, expected session counts, and no stuck pending transaction.
5. Review Quickshell logs for plugin-specific errors.
6. Exercise only controls that can be safely restored.

Example read-only checks:

```sh
qs ipc --pid "$shell_pid" call privacy-devices health
qs ipc --pid "$shell_pid" call privacy-devices diagnostics safe
qs ipc --pid "$shell_pid" call privacy-devices status
```

Do not copy unredacted diagnostics into issues or CI logs.
