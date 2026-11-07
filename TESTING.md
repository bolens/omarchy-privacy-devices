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
checked-out Omarchy import path. It copies harnesses beside the plugin's QML and
JavaScript files in a temporary directory, matching their runtime import layout,
and removes that directory after linting, including failed runs.

In a graphical session, `npm test` also runs the real-engine QML suite when a
usable Wayland session and Quickshell executable are present. To require that
path explicitly:

```sh
PRIVACY_RUNTIME_TESTS=always npm test
```

To skip it while iterating on non-graphical changes:

```sh
PRIVACY_RUNTIME_TESTS=never npm test
```

Run `npm run verify:live` for read-only IPC discovery, redaction, payload, and
invalid-input checks against an installed plugin.

You can still run the QML suite directly:

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
Completion-only harnesses also defer their body through `Qt.callLater` so
Quickshell connects its quit receiver before the test calls `Qt.quit()`. The
command-construction harness disables monitored kinds and asserts that it owns
no observers; separate lifecycle harnesses exercise actual observer processes.

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

## Woodpecker plugin validation

[Woodpecker](https://woodpecker.bolens.dev/repos) runs the plugin archive,
ShellCheck, behavior, strict QML controls and complete canonical headless runtime
suite on pull requests and pushes to `main`. Its pinned toolchain and v4.0.1
imports also serve retained GitHub callers. Preparation runs
`bash scripts/woodpecker-plugin.sh --prepare` to fetch only immutable public
imports. The required `--offline` phase runs as container user 10042 with
networking disabled; test dependencies are already in the image. Neither phase
receives publishing secrets.

Require `ci/woodpecker/pr/plugin` for ordinary pull requests, alongside the
existing Repository, source-lint, and development-environment checks. GitHub
retains full plugin validation for reusable callers by default through the typed
`release_validation` input; the signed-release workflow explicitly enables it.
Ordinary PR and main workflows skip the duplicate hosted plugin jobs.

Repository links, HTML/XML, workflow security, compatibility
canaries, macOS, development-image builds, Pages, and signed release publication
retain their existing GitHub workflows. Native plugin success does not prove live
desktop behavior. No version or release is created by CI.

The pre-push hook defaults to deterministic checks even on a graphical desktop.
Set `PRIVACY_RUNTIME_TESTS=always` explicitly when pushing with an owned graphical
test session. Calling `npm test` directly retains its documented runtime selection.

## Woodpecker site accessibility

The native `site` workflow builds the existing Pages payload, runs its structure
tests, then runs `node scripts/audit-site.mjs` in the pinned official
Puppeteer/Chrome image. It requires an accessibility score exactly 1. The helper
awaits its own loopback HTTP listener and Chrome DevTools readiness, uses ephemeral
ports, and closes only its owned browser, profile, and server. It receives no
secrets or extra host capabilities.

Require `ci/woodpecker/pr/site` alongside the native plugin and existing hosted
checks. Ordinary PR and main runs use the pinned native browser audit; GitHub
continues the site build, structure, HTML/XML, link, and workflow-security checks.
Reusable callers retain hosted browser validation through `release_validation`
with its default `true`; signed releases explicitly enable it. Manual GitHub
workflow dispatch also retains the hosted audit, and Woodpecker supports a manual
site run. Forks still require native approval and receive no publishing secrets.

Publishing and platform checks retain their current workflows. Review the manual
browser-image digest pin alongside the other native image pins; Dependabot does
not update Woodpecker YAML.

## Strict QML import preparation

Inside the qualified CI toolchain, use the same preparation entry point as the
native and retained hosted gates:

```sh
bash scripts/with-qml-imports.sh "$OMARCHY_PATH/shell" bash tests/run_all.sh
```

Use the clean `shell` subtree from Omarchy commit
`13f18b2cb7286fb54f87daf571a031aa6af3d8f0`. The source profile checks every one of
its 175 files, including Git blob hashes and executable modes, before copying it
into an owned temporary directory. It backports the upstream
[`b83d3df` palette qualification](https://github.com/omacom/omarchy/commit/b83d3df0840504299d3099ebf391eb8110527edd)
and gives the eleven existing anonymous token objects named component types.
Every field body and readonly slot is preserved. The installed shell is unchanged.
Unknown source contents fail preparation; the experimental compatibility canary
reports that gap rather than silently adapting an unreviewed upstream revision.

The tooling helper verifies the exact Quickshell/Qt package versions and all 72
Quickshell import files. Its private metadata copy resolves source-backed core
Margins, PopupAnchor, ObjectModel and flag typedefs; installed package files remain unchanged.
`QML_TOOLING_IMPORT_ROOT` selects that copy first with `qmllint --bare` and explicit
system imports. Runtime engines use the real installed package metadata.

The policy rejects warnings. Real-linter controls must accept a supported nested
font field and reject an invalid property, nested field and type with the expected
diagnostic. A successful subprocess with the wrong diagnostic does not pass.
Preparation, source lint and these controls are separate from the explicit QML
runtime suite; a static pass does not prove live desktop behavior. Run runtime
harnesses only with owned HOME/XDG roots and an isolated display appropriate to
the harnesses. Window tests require a real layer-shell compositor, not the
offscreen backend. See the QML warning validation feature's
[acceptance plan](specs/005-qml-warning-validation/plan.md).

If Qt 6.12 `qmllint` fails with empty text output, repeat its exact command with
`--json -` to read the structured diagnostics. Keep the same inputs, policy and
import arguments. Loop-analysis diagnostics can remain in the structured result
when Qt's text output is empty; an empty log never overrides a failing exit code.
Acceptance requires the complete target inventory and zero structured diagnostics.

## Required native QML validation

Woodpecker prepares the immutable public Omarchy source and installs locked site-test
dependencies with `npm ci --ignore-scripts` in its networked first step. It makes
those public inputs readable by the following ordinary container user.
The required plugin step then runs as container user 10042 with networking
disabled. It validates the source and tooling profiles, portable checks, strict
QML lint and real invalid controls before running every harness registered in
`tests/run_qml_runtime.sh` through `scripts/qml-runtime-fixture.py`. Optional
desktop-test selection variables do not skip this owned runtime gate.

Woodpecker 3.x reads `network_mode: none` as a direct step field; placing it
under `backend_options.docker` is ignored by the agent. Docker backend options
retain the ordinary `10042:10042` user. The server must accept the legacy
step-level field in its workflow schema. Verify the actual plugin container has
`HostConfig.NetworkMode=none` and no attached workflow network before claiming
offline acceptance; YAML lint and source assertions alone do not prove this.
Preparation and cloning retain their network access and public immutable inputs.

The fixture uses private HOME/XDG roots, canonical default typography and the
packaged font resolver. Window tests use a software headless compositor; Privacy
tests also use an isolated PipeWire registry without hardware nodes. Protocol
roundtrips establish readiness. Existing harness deadlines and natural exits
remain required; Privacy shutdown also checks the owned configuration is absent.
No host display, audio socket, device, Docker socket or privilege is required.

Each result retains its raw output in CI logs. Only exact, source-bound warnings
from explicitly asserted negative tests may pass; additional Qt, binding, type
or deprecation warnings fail. The palette contract checks all 87 declared token
fields plus eleven inherited object names, stable identities, readonly owners,
permitted child writes and reactive restoration. A missing harness, marker or
cleanup result fails validation.

## Additive native repository checks

The credential-free `repository` workflow adds the existing shared Source lint,
workflow security, changelog, HTML/XML and documentation-link policies on each
PR, main push and manual native run. It builds/tests the site for link discovery;
the separate `site` workflow retains the actual Lighthouse accessibility audit.
Privacy-specific issue-form, release metadata and docs checks remain mandatory
where applicable. Run `bash scripts/woodpecker-repository.sh` in the documented
Linux tooling container to reproduce the public-tool bootstrap and checks.

Existing GitHub requirements remain active during this additive delivery. Do not
retire `Repository` or `lint / Source lint` until exact-head native PR and genuine
main proof is accepted and protected checks are migrated separately. Preserve
`ci.yml`'s reusable release-validation interface and all release, platform and
Pages deployment boundaries. No future pipeline or merge is accepted by this text.

### Native workflow groups and local commands

| Workflow | Group | Local entrypoint | PR status |
|---|---|---|---|
| `plugin.yml` | Portable plugin, strict Qt/QML and owned runtime/IPC | `scripts/woodpecker-plugin.sh --prepare` then `--offline` in its qualified container | `ci/woodpecker/pr/plugin` |
| `site.yml` | Site build/test and real accessibility browser audit | `npm run build:site`, `npm run test:site`, `node scripts/audit-site.mjs` in its qualified browser container | `ci/woodpecker/pr/site` |
| `repository.yml` | Source/workflow policy and document integrity | `scripts/woodpecker-repository.sh --policy` and `--documents`; default `--all` runs both | `ci/woodpecker/pr/repository` (pending delivery proof) |

Workflow filenames own status identity; descriptive kebab-case step names group
checks within each workflow. The new repository group publishes no artifacts or
releases. Existing plugin/site status aliases and separate GitHub release/Pages
authorities stay unchanged. Run local commands from the repository root.
