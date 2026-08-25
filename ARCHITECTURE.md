# Architecture

## Repository map

- Root QML and `Model.js`: runtime entry points and components. These remain at
  the plugin root because Omarchy resolves manifest entry points and sibling
  imports relative to the installed plugin directory.
- Root `privacy-*` executables: narrowly scoped runtime helpers invoked by the
  QML service. Keeping them beside the entry points preserves relocatable
  `Qt.resolvedUrl(...)` lookup.
- `tests/`: behavior, security, release-metadata, site, and helper tests.
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
  health, history coordination, notifications, and IPC.
- `BarWidget.qml` renders service state, routes user actions, and persists
  sanitized settings through Omarchy Shell.
- `Model.js` contains pure classification, normalization, reconciliation,
  health, settings, and visual-state policy shared by runtime and tests.
- `PrivacyActivityCard.qml`, `DeviceSettingsEditor.qml`,
  `DeviceDiagnostics.qml`, `SettingsSurface.qml`, and `IntegerSetting.qml`
  contain reusable presentation components without monitoring ownership.
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
- Service IPC owns only headless state controls; capture actions remain with
  the focused bar, and rejected requests return an explicit result.
- A pending control retains its verification probe if monitoring settings
  change, while superseded background probe queues are coalesced.
- Pending controls retain the last observed state rather than presenting an
  optimistic result.
- Settings are allowlisted, bounded, and versioned before reaching runtime;
  IPC pages and direct helper arguments are validated again at their ingress.
- History and exported settings use private directories, exclusive temporary
  files, atomic replacement, bounded reads, and load-time sanitation.
- History operations serialize read-modify-write transactions, and generation
  checks prevent asynchronous loads from crossing clear/disable boundaries.
- Session metadata is stripped of control characters and bounded before it is
  used for identity, rendering, IPC, notifications, or persistence.
- Diagnostics are redacted by default and bounded before clipboard transfer.
- Disabled, active, idle, pending, and degraded presentation derives from the
  shared visual-state policy rather than independent QML conditions.

## Security boundaries

Camera, location, and portal controls cross privileged or service-management
boundaries only through fixed helper commands. Custom capture and recording
commands are explicitly user-controlled and are never inferred from observed
process text. Recorder stopping validates PID ownership and executable identity.

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
- Run animation timers only while their corresponding pending state exists.
- Bound scans, retries, stored entries, payload sizes, and rendered history.

Changes that weaken these constraints require focused tests and live
Quickshell verification.

## Related documentation

See the [documentation index](DOCUMENTATION.md), canonical
[validation matrix](TESTING.md), and [security policy](SECURITY.md).
