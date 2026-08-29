# Architecture

## Repository map

- Root QML and `Model.js`: runtime entry points and components. These remain at
  the plugin root because Omarchy resolves manifest entry points and sibling
  imports relative to the installed plugin directory.
- Root `privacy-*` executables: narrowly scoped runtime helpers invoked by the
  QML service. Keeping them beside the entry points preserves relocatable
  `Qt.resolvedUrl(...)` lookup.
- `tests/`: behavior, security, release-metadata, site, and helper tests. Runtime
  QML harnesses live under `tests/qml/` so test-only shell roots cannot be
  mistaken for installed plugin components.
- `scripts/`: maintainer-only build and validation tooling; nothing here is
  called by the installed widget.
- `docs/`: static Pages source and public media.
- `.github/`: contribution forms, dependency policy, and CI/release workflows.
- Root Markdown files: project governance and the maintainer entry points for
  architecture, testing, support, security, and releases.

Generated `_site/`, dependency `node_modules/`, and Python bytecode are ignored
and must never appear in a release archive.

Privacy Devices is a local-first Omarchy Shell plugin with one long-lived
service and one bar presentation. Monitoring state stays centralized so
multiple displays do not duplicate observers or race for IPC ownership.

## Runtime ownership

- `Service.qml` owns monitoring, normalized sessions, control transactions,
  health, notifications, and IPC. It retains stable facade methods while
  delegating bounded state machines to focused controllers.
- `PrivacyHistoryController.qml` owns retained-history helper processes, load
  supersession, and serialized mutations behind the service's stable history
  methods.
- `PrivacyAudioEndpointController.qml` owns endpoint inventory subprocesses and
  refresh supersession. `PrivacyPresetController.qml` owns serialized lockdown
  and named-mode application plus observed-state restore.
- `PrivacyControlTransactionController.qml` owns observed-result verification
  and timeout transitions. `PrivacyControlProcessController.qml` owns the audio
  and preventative command/probe processes, while
  `PrivacyDependencyController.qml` owns dependency scheduling and installation.
- `PrivacyObserverController.qml` owns both persistent observers, retirement and
  restart state, watchdogs, payload acceptance, and source-specific cleanup.
- `PrivacyNotificationController.qml` owns notification coalescing, icon and
  callback validation, action dispatch, and focused popup routing.
- `PrivacyCaptureController.qml` owns capture-preview sessions, per-bar
  presentation registration, and expiry.
- `BarWidget.qml` is the panel coordinator: it projects service state, routes
  user actions, and persists sanitized settings through Omarchy Shell.
- `PrivacyPresentationController.qml` owns bar/device presentation policy and
  semantic text, color, marker, ordering, and tooltip projections.
- `PrivacyDeviceSettingsController.qml` owns sanitized per-device appearance,
  placement, and backend mutations behind the panel's stable facade.
- `PrivacyPopupNavigationController.qml` owns popup modes, deep-link scrolling,
  keyboard selection, singleton request consumption, and layered dismissal.
- `PrivacyActivityHeader.qml` owns the fixed main-view title and actions while
  `PrivacyActivityView.qml` owns the independently scrollable activity body.
  `PrivacyHistoryView.qml` and
  `PrivacyDeviceView.qml` own the three mutually exclusive popup surfaces.
  They receive the panel coordinator as a controller and expose only the few
  controls needed by the existing runtime-test and IPC facade.
- `PrivacyDeviceBackendSettings.qml` owns lazy capture/audio backend editing
  and custom-command validation. `PrivacySettingsController.qml` owns settings
  commit/rollback, coalescing feedback, private transfer, and mutation expiry.
- `Model.js` contains pure classification, normalization, reconciliation,
  health and heartbeat, settings, control-request, observer-recovery,
  history-acceptance, and visual-state policy shared by runtime and tests.
- `PrivacyActivityCard.qml`, `DeviceSettingsEditor.qml`, and
  `DeviceDiagnostics.qml` own reusable device presentation within those
  surfaces. `Privacy*Settings.qml`,
  `PrivacySettingsNavigation.qml`, `PrivacySettingsGrid.qml`, `SettingsSurface.qml`, and
  `IntegerSetting.qml` own the global settings interface.
  Settings field groups use the smaller of configured popup width and allocated
  surface width as their responsive input, so lazy loaders cannot select from
  transient implicit size and half-width cards cannot over-pack controls.
- `PrivacyConfirmationController.qml` and
  `PrivacySettingsTransferController.qml` isolate timed confirmation and
  private import/export/undo state. `PrivacySettingsMutationController.qml`
  coalesces rapid edits and owns persistence feedback.
- `PrivacyMessageSurface.qml` presents shared loading, empty, success, and
  failure states. `PrivacySettingToggle.qml` owns the common boolean-setting
  binding, styling, and persistence contract.
- `PrivacySettingsTransferResult.qml` validates and applies transfer results;
  the process controller owns only subprocess lifecycle.
- `privacy-*` helpers isolate bounded filesystem, process, dependency, capture,
  and privileged-control boundaries.

## Data flow

```text
PipeWire signals ───────────────┐
direct-device observer ────────┤
fallback process observer ─────┼─> Service.qml ─> normalized sessions
GeoClue/control probes ────────┘                       │
                                                     ├─> IPC/diagnostics
Omarchy settings ─> sanitizer ───────────────────────┤
                                                     └─> BarWidget.qml
```

PipeWire is reactive. Direct-device and fallback process monitoring use one
persistent observer each, with heartbeats and bounded restart backoff. A slow
reconciliation pass protects against incomplete backend signals without making
normal operation poll-driven.

## State invariants

- Session identity is derived from kind, application, device, and source.
- Timestamps do not cause consumer churn when visible session data is stable.
- Observer failure invalidates source-owned sessions without recording a real
  stop, and the first uncertain recovery snapshot is not announced as new
  activity.
- Control commands are not successful until an observed state matches the
  requested state; verification has a bounded timeout.
- Per-endpoint audio control re-enumerates PipeWire-Pulse sources or sinks,
  allowlists the exact endpoint name, applies one mute state, and re-reads the
  endpoint before publishing the result.
- Service IPC owns only headless state controls; capture actions remain with
  the focused bar, and rejected requests return an explicit result.
- A pending control retains its verification probe if monitoring settings
  change, while superseded background probe queues are coalesced.
- Dependency and preventative subprocess queues share one FIFO and supersession
  policy, so configuration churn cannot diverge their scheduling behavior.
- Pending controls retain the last observed state rather than presenting an
  optimistic result.
- Audio state probes retain one final per-device refresh while busy, ensuring a
  post-control observation cannot be dropped behind an older poll.
- Process concurrency uses synchronous service-owned operation tokens; QML
  `Process.running` is lifecycle evidence, not an immediate lock.
- Observer command changes retain one restart request and launch it only after
  the retiring process confirms exit.
- Observer ownership is claimed before launch, closing the same-turn window
  before QML publishes the subprocess's lifecycle state.
- Lockdown and named privacy modes serialize existing per-device control
  transactions, record partial failures, and restore only from the observed
  pre-application snapshot.
- Settings are allowlisted, bounded, and versioned before reaching runtime;
  IPC pages and direct helper arguments are validated again at their ingress.
- Rapid settings edits merge before one shell update; submission failures
  restore the previous in-memory settings and remain visible to the user.
- History and exported settings use private directories, exclusive temporary
  files, atomic replacement, bounded reads, and load-time sanitation.
- Settings transfer and one-step undo share a private filesystem lock and sync
  their containing directory before reporting a durable replacement or removal.
- History operations serialize read-modify-write transactions, and generation
  checks prevent asynchronous loads from crossing clear/disable boundaries.
- The service also owns a FIFO for history mutations and retains one pending
  reload while a load is active, preserving the final requested state even
  though QML process lifecycle properties update asynchronously.
- GeoClue snapshots carry the monitoring generation that requested them, so a
  late probe cannot restore location activity after monitoring is disabled.
- Session metadata is stripped of control characters and bounded before it is
  used for identity, rendering, IPC, notifications, or persistence.
- Device visibility, alert suppression, and friendly labels use the same
  normalized session identity policy as application rules.
- History summaries are projections of the existing bounded retained rows;
  they neither extend retention nor create a second data store.
- History trends, filters, and sorting are pure projections of that same store.
- Retained history accepts only bounded past timestamps plus a small clock-skew
  allowance, preventing malformed future records from dominating retention.
- Audio endpoint inventory changes remain bounded in memory for the current
  service session and are never promoted into retained activity history.
- Inspection handoff copies only a bounded live application name. It does not
  retain process identifiers or assume an undocumented cross-plugin IPC API.
- Diagnostics are redacted by default and bounded before clipboard transfer.
- Notification callbacks and launcher adapters share `privacy-action`, whose
  action names and optional device kind are allowlisted before shell IPC.
- `privacy-menu-entry` is an opt-in, idempotent adapter for Omarchy's extension
  file. It atomically owns one marked block and routes lockdown to UI
  confirmation rather than directly invoking controls.
- Observer health alerts publish only healthy/degraded transitions, redact
  details to source and code, and rate-limit each source. The self-test reads
  state without changing controls; notification delivery remains an explicit
  user-triggered test.
- Shared presentation policies own visual state, navigation boundaries, scroll
  deferral, diagnostics, telemetry text, and device-action guidance; QML owns
  composition and input routing. Capture-only settings scrolling remains
  owner- and output-scoped and exposes its rendered top/bottom state rather
  than relying on elapsed time.

## Security boundaries

Camera, location, and portal controls cross privileged or service-management
boundaries only through fixed helper commands. Custom capture and recording
commands are explicitly user-controlled and are never inferred from observed
process text. Recorder stopping validates PID ownership and executable identity.
GeoClue discovery uses fixed `busctl` argument arrays, bounded output, and
per-call timeouts rather than an inline shell pipeline.
Trusted capture helpers and Omarchy commands launch as argument arrays; only
the documented custom-command escape hatch crosses the shell-string boundary.
Audio endpoint names are discovered locally and passed to `pactl` only after
an exact match against a fresh, bounded source/sink inventory.
Notification `--exec` callbacks contain a fixed helper path plus allowlisted
tokens; application and device metadata never enters the callback command.

Monitoring reads metadata only. It never opens camera or microphone devices,
captures media, or sends telemetry over the network.

## Performance constraints

- Keep one service instance and avoid per-monitor observers.
- Prefer reactive signals and persistent observers over repeated subprocesses.
- Derive rendered subsets and normalized settings from shared reactive
  snapshots instead of rebuilding them independently for each consumer.
- Debounce reconciliation and avoid replacing arrays when rendered data is
  equivalent.
- Suspend periodic probes when no enabled device consumes their results, and
  retain one coalesced refresh when configuration changes during a probe.
- `PrivacyObserverWatchdog.qml` owns retry and heartbeat timers consistently;
  observers reject buffered output after retirement.
- Run animation timers only while their corresponding pending state exists.
- Bound scans, retries, stored entries, payload sizes, and rendered history.

Changes that weaken these constraints require focused tests and live
Quickshell verification.

## Related documentation

See the [documentation index](DOCUMENTATION.md), canonical
[validation matrix](TESTING.md), and [security policy](SECURITY.md).
