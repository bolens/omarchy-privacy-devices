# Testing

Tests are organized around stable behavior boundaries rather than QML internals.

## Fast behavior suite

```sh
npm test
```

The suites cover model policy, runtime wiring, settings/UI contracts, helpers,
security boundaries, release metadata, documentation, and site assets. Helper
tests use temporary state and fake commands; they do not modify devices or
privileged services.

Runtime contract checks also keep plugin entry points embeddable, helper paths
relocatable, and detached commands argument-safe.

`tests/run_all.sh` is the canonical suite definition used by npm and CI. It
discovers JavaScript and Python tests automatically and checks runtime scripts.

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
  PrivacyActivityCard.qml DeviceSettingsEditor.qml DeviceDiagnostics.qml \
  AudioEndpointSettings.qml \
  Privacy*Settings.qml PrivacySettingsNavigation.qml \
  PrivacyConfirmationController.qml PrivacySettingsTransferController.qml \
  Runtime*.qml
```

In a graphical session, exercise shared JavaScript in the real Quickshell
engine:

```sh
tests/run_qml_runtime.sh
```

This runs shared policy, the assembled plugin, semantic appearance bindings,
rendered bar and activity-card states, per-endpoint audio controls, validated
device/settings deep links, two-step lockdown and undo presentation, user
interaction, device-detail navigation, coalesced settings writes and assembled
rollback, rapid per-device appearance edits, general and alert settings wiring,
bounded integer and marker editors, reactive feedback surfaces, degraded device
diagnostics, monitoring configuration and appearance presentation wiring,
reactive audio-endpoint replacement, guarded card activation, diagnostic
recovery, responsive settings navigation, redacted monitoring actions, subprocess
failure/recovery, guarded activity-policy actions, private-data transfer
controls, in-memory history search, confirmation, and private settings-transfer
behavior in the real QML engine.

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

## Refreshing screenshots

Capture the activity and both history states, exact bar footprint, global
settings, and a device settings page from the live plugin on an otherwise
empty workspace:

```sh
scripts/capture-screenshots --monitor DP-1 --workspace 10
```

The script requires enabled activity history and an empty workspace. It allows
only one capture at a time, discovers the shell through IPC, uses measured
widget geometry, and swaps in bounded example history. It restores the original
shell settings, real history, DND state, and workspace even on failure. Review
images before committing them. Capture fails if restored settings or history do
not exactly match their preserved snapshots. Settings swaps use the shell's
live `reloadConfig` IPC and verify its effective configuration, so capture and
restoration do not restart Quickshell or race a shutting-down process.

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
qs ipc --pid "$shell_pid" call privacy-devices openDetails microphone
qs ipc --pid "$shell_pid" call privacy-devices openSettings appearance
qs ipc --pid "$shell_pid" call privacy-devices openSettingsSection monitoring observer-health
qs ipc --pid "$shell_pid" call privacy-devices-settings openSection monitoring private-data
```

Do not copy unredacted diagnostics into issues or CI logs.

## Related documentation

See the [documentation index](DOCUMENTATION.md),
[contribution expectations](CONTRIBUTING.md), and
[release playbook](RELEASING.md).
