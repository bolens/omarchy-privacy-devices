# Testing

Tests are organized around stable behavior boundaries rather than QML internals.

## Fast behavior suite

```sh
npm test
```

The suites cover model policy, runtime wiring, settings/UI contracts, helpers,
security boundaries, release metadata, documentation, issue-form validation,
and isolated site builds. Helper tests cover every selectable capture and
dependency backend with temporary state and fake commands; they do not modify
devices or privileged services. Corrupt state, malformed backend metadata,
unsafe publication paths, recovery relocation, and subprocess failure behavior
are exercised explicitly.

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
scripts/lint-qml
```

The lint entry point discovers every root component and `tests/qml/` harness in
sorted order. CI calls the same script with its pinned Qt executable and
checked-out Omarchy import path.

In a graphical session, exercise shared JavaScript in the real Quickshell
engine:

```sh
tests/run_qml_runtime.sh
```

During iteration, run one registered harness by exact filename:

```sh
QML_RUNTIME_HARNESS=RuntimeKeyboardNavigationTest.qml tests/run_qml_runtime.sh
```

Stress a timing-sensitive focused harness with up to ten clean instances:

```sh
QML_RUNTIME_HARNESS=RuntimePluginSmokeTest.qml QML_RUNTIME_REPEAT=5 tests/run_qml_runtime.sh
```

An unknown filename fails instead of silently running zero tests. Leave the
variables unset for the exhaustive single-pass suite used before commits and
releases. Invalid repeat counts fail instead of weakening the run.

The fast suite verifies that every `Runtime*Test.qml` harness is registered
exactly once and owns one unique success marker, so adding a harness cannot
silently leave it out of the real-engine suite.

Runtime harness sources live under `tests/qml/`; the runner stages them beside
the plugin runtime files so Quickshell exercises the same sibling-import rules
as an installed root plugin. The runner also rejects QML scene warnings and fatal/critical engine
output even when a success marker was emitted, and requires the marker exactly
once at runtime. This prevents late binding errors or repeating completion
timers from being hidden by an otherwise successful assertion path.

Concurrency harnesses advance from observed process, heartbeat, health, and
commit signals. Timers in those harnesses are failure deadlines only; they do
not decide when an asynchronous operation should have completed.
Settings transfer, rollback, confirmation expiry, capture-preview expiry,
verification timeout, and reactive refresh harnesses follow the same rule;
one event-loop deferral is used only when an assertion must run outside the
QML binding stack that emitted its completion signal.

This runs shared policy, the assembled plugin, semantic appearance bindings,
rendered bar and activity-card states, per-endpoint audio controls, validated
device/settings deep links, two-step lockdown and undo presentation, user
interaction, device-detail navigation, coalesced settings writes and assembled
rollback, rapid per-device appearance edits, general and alert settings wiring,
bounded integer and marker editors, reactive feedback surfaces, degraded device
diagnostics, monitoring configuration and appearance presentation wiring,
monitoring telemetry freshness, fallback observation composition, reactive
audio-endpoint replacement, guarded card activation, diagnostic recovery,
reactive session summaries, responsive navigation and lazy loading of every
settings page, race-free polling of asynchronous settings writes and session
reconciliation, mutation feedback lifecycle, transfer request exclusion,
multi-monitor deep-link routing,
current and compatibility IPC dispatch through the live Quickshell transport,
owner-isolated capture lease/state/cleanup behavior,
capture-preview cleanup and automatic expiry, debounced observer-session
reconciliation, validated notification callback routing, reactive policy
eligibility, keyboard selection and device navigation, control-request gating,
layered popup dismissal, observer-health state isolation and per-device health
aggregation, observer-session teardown and recovery suppression, per-device
reset isolation, endpoint feedback transitions,
verification timeouts, privacy-preset orchestration, self-test health aggregation,
lockdown result states, destructive-history
cancellation, rollback retry, external toggle updates, cross-device metadata
coalescing, backend reset completeness, external payload validation and
stale-state cleanup, filtered status projection, diagnostics redaction,
diagnostic backend/state/exit-code projection, backend command selection,
relocatable helper paths and escaped observer arguments, immutable service
state/result mutations, capture-safe bar-session policies, active-count and
attribution tooltip presentation, control-transaction
lifecycle wiring, status-presentation wiring, redacted monitoring actions,
subprocess failure/recovery, guarded activity-policy actions, private-data transfer
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

CI also runs Actionlint and link checks. It requires a Lighthouse accessibility
score of 1.00.

The required CI checks use Omarchy v4.0.1. The weekly compatibility workflow
checks QML imports against v4.0.1 and the current `quattro` branch. A `quattro`
failure reports upcoming incompatibility without blocking supported-version
changes.

## Refreshing screenshots

Capture the activity and both history states, exact bar footprint, global and
privacy-mode settings, and a device settings page from the live plugin on an otherwise
empty workspace:

```sh
scripts/capture-screenshots --monitor DP-1 --workspace 10
```

For a layout-only review, retain each settings page's top and its bottom when
the page has a meaningful scroll range, without changing repository screenshots. Run both supported layout
presets from the terminal whose monitor should be used:

```sh
narrow_audit=$(mktemp -d /tmp/privacy-devices-narrow.XXXXXX)
wide_audit=$(mktemp -d /tmp/privacy-devices-wide.XXXXXX)
scripts/capture-screenshots --panel-width 400 --audit-dir "$narrow_audit"
scripts/capture-screenshots --panel-width 720 --audit-dir "$wide_audit"
```

Audit output directories must be empty and below `/tmp`. Audit mode implies
`--verify`, preserves the repository, enables presentation-only conditional
controls, and publishes the retained evidence only after desktop restoration
and byte-for-byte state postconditions pass. A same-page bottom that is
pixel-identical to its top is omitted; any other repeated evidence fails the
run. The chosen width also selects the
matching narrow, standard, or wide live popup preset; it is not merely a crop.

The script requires enabled activity history and an empty workspace. It allows
only one capture at a time, discovers the shell through IPC, uses measured
widget geometry, and swaps in bounded example history. It restores the original
shell settings, real history, DND state, and workspace even on failure. Review
images before committing them. Capture fails if restored settings or history do
not exactly match their preserved snapshots.
Each panel capture waits for an owner-scoped acknowledgement from the bar on the
selected monitor, including lazy settings-page and section readiness. It does
not infer rendering completion from a successful deep-link reply or fixed wait.
Capture traces its parent process chain to the Hyprland client that launched it,
then falls back to the active window, pointer's containing output, and compositor
focus. `--monitor` remains an explicit override. Panel actions then use the bar
instance registered for that exact output.
Hyprland connector names are treated generically; DisplayPort (`DP-*`), HDMI
(`HDMI-*`), embedded panels (`eDP-*`), DVI, and other safe output names work.
Notification capture similarly sends one toast and polls its crop against a
fresh visual baseline, preventing retry attempts from stacking duplicate toasts.
Every staged view is checked for its expected dimensions and uniqueness before
transactional publication; a partial failure restores replaced assets and
removes assets that did not exist before the run.

Sample settings and sessions use an owner-scoped, expiring
in-memory preview. Capture never swaps the settings file, reloads configuration,
or restarts Quickshell. Audit scrolling is routed to the selected monitor's bar
instance and waits for its rendered scroll acknowledgement before capture.

## Live verification

After changing monitoring, IPC, settings, controls, or layout:

1. Deploy the complete QML/JS runtime with `scripts/deploy-shell-runtime`.
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
