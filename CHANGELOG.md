# Changelog

All notable changes to Privacy Devices are documented here. The project follows
[Semantic Versioning](https://semver.org/).
See the [documentation index](DOCUMENTATION.md) for topic ownership and the
maintainer guides that define release and validation procedures.

## [Unreleased]

## [0.9.14] - 2026-09-01

### Added

- Pages now include favicons, touch and install icons, a web manifest, and a 1200x630 social card. Regression tests protect the metadata and image dimensions.

## [0.9.13] - 2026-09-01

### Fixed

- Keep all Pages guide sections visible without requiring scroll-triggered
  JavaScript while retaining intentional hero and interface motion.

## [0.9.12] - 2026-09-01

### Fixed

- Honor injected epoch timestamps in history labels instead of silently
  substituting the wall clock.

## [0.9.11] - 2026-09-01

### Added

- Pages offer selectable dark and light themes.
- Browsers that prefer light mode start with GitHub Light; browsers without a preference keep the default dark theme.

## [0.9.10] - 2026-09-01

### Fixed

- Keep keyboard guidance below the action cards in the Pages usage section at
  mobile, tablet, desktop, and ultrawide widths.
- Ensure all nested cards remain visible when reduced motion is requested.

## [0.9.9] - 2026-09-01

### Fixed

- Tag-triggered releases now receive the pull-request metadata required by path-filtered validation.

## [0.9.8] - 2026-09-01

### Fixed

- Validate complete PNG headers before reading screenshot dimensions in tests.

## [0.9.7] - 2026-09-01

### Fixed

- Preserve QML-backed list settings, including enabled device kinds and privacy
  modes, across sanitization, save, serialization, and reload while rejecting
  malformed or oversized values with a single bounded length snapshot.
- Keep native privacy-mode arrays on the allocation-free sanitization path.
- Require Qt 6 QML tooling, publish plugin module metadata, and gate reliable
  semantic lint errors in local and CI validation.

## [0.9.6] - 2026-08-31

### Added

- Add weekly compatibility checks for Omarchy v4.0.1 and the current
  `quattro` branch.
- Add release artifact attestations and require a 1.00 accessibility score.
- Add Actionlint and an explicit Node.js version to repository CI.
- Add isolated stable and canary compatibility runs that keep the checkout
  read-only.

### Changed

- Align CI, release, dependency, runtime, and archive policies with the
  maintained plugin suite.
- Run canonical QML tests automatically in graphical sessions and improve
  subprocess failure diagnostics.
- Validate staged release payloads before commits and add a read-only live IPC
  redaction and payload probe.
- Stop isolated QML harnesses after their unique success marker while retaining
  timeout and late-error guards.

### Fixed

- Use CI's pinned Omarchy validator in the canonical behavior suite.

## [0.9.5] - 2026-08-29

### Fixed

- Keep popup width stable between views while fitting height to loaded content,
  retaining a useful minimum scroll viewport and the configured maximum without
  leaving large empty regions below short pages.

## [0.9.4] - 2026-08-29

### Fixed

- Isolate fixed popup headers and footers in independently anchored regions so
  no settings content can render beneath or displace them, and settle visual
  audit frames before retaining scroll-boundary evidence.

## [0.9.3] - 2026-08-29

### Fixed

- Keep activity and global-settings popups at the configured dimensions across
  sparse and content-heavy views, preserving a useful scroll viewport without
  layout jumps between settings pages.

## [0.9.2] - 2026-08-29

### Fixed

- Keep global-settings navigation and reset actions fixed around the scrollable
  settings body, and prevent activity header actions from overflowing narrow
  popup layouts.

## [0.9.1] - 2026-08-29

### Fixed

- Keep the activity header and keyboard-help footer visible while the activity
  cards and policy controls scroll independently between them.

## [0.9.0] - 2026-08-28

### Changed

- Split popup views, settings orchestration, helper processes, control
  transactions, observers, and presentation state into focused QML controllers
  while preserving the public service, panel, and runtime-test contracts.
- Use one deterministic QML lint entry point for local and CI validation.
- Share width-driven settings grids across global pages so narrow and wide
  popup presets reflow from configured panel width instead of implicit child
  size.
- Add a repository-safe visual audit mode that retains unique top and bottom
  settings evidence only after monitor-scoped rendering and successful desktop
  restoration checks.
- Replace unambiguous save, transfer, placement, test, copy, and settings
  actions with compact glyph controls while preserving explicit tooltips and
  text for destructive or state-dependent actions.

### Fixed

- Preserve the active privacy preset's saved state and undo metadata when a
  concurrent lockdown or mode request is rejected.

## [0.8.1] - 2026-08-27

### Fixed

- Prefer the monitor containing the terminal or launcher process that started a
  screenshot run before active-window, pointer, and focused-output fallbacks.
- Serialize settings export, import, reset checkpoints, and one-step undo with
  private durable transactions while keeping missing read-only loads inert.
- Reject retained-history timestamps beyond a bounded clock-skew allowance.
- Roll back newly introduced screenshot assets after partial publication,
  validate every published view's dimensions and uniqueness, and reject
  duplicate dimensioned screenshot markup.

## [0.8.0] - 2026-08-27

### Added

- Named privacy modes that reapply available controls through the verified serial transaction and undo path.
- Bounded history trends, device and evidence filters, stable sorting, audio-endpoint feedback, and privacy-safe live application inspection.

### Changed

- Screenshot capture is monitor-specific, uses fresh and distinct evidence, and restores desktop state without optional workspace plugins.
- History filters share one responsive row, and new installations hide idle bar icons by default.
- QML runtime harnesses use installed-root import behavior under `tests/qml/`.

### Fixed

- Endpoint refresh, observer restart, history writes, settings actions, confirmations, previews, and verification use observed completion instead of fixed delays.
- Concurrent observer and endpoint operations retain the latest requested state without stale subprocess results.
- Screenshot capture waits for the selected monitor, rendered view, and changed pixels while rejecting blank or duplicate crops.
- GeoClue probes, notification capture, workspace routing, and desktop restoration cannot republish stale state or disturb another monitor.

## [0.7.0] - 2026-08-26

### Added

- Confirmed serial privacy lockdown with verified partial results and a 30-second undo.
- Per-device visibility, notification, color, opacity, and audio-endpoint control policies.
- Today and seven-day summaries from existing bounded local history.
- Actionable alerts, health monitoring, a privacy self-test, menu actions, and validated deep links.

### Changed

- New installations use a compact bar with idle icons and activity markers disabled.
- Device colors distinguish active, idle, disabled, and blocked states with global and per-device overrides.
- Settings grids and observer-health actions reflow from the configured panel width.

### Fixed

- Lockdown, undo, quick actions, and endpoint controls share verified transaction paths and redacted diagnostics.

## [0.6.0] - 2026-08-26

### Added

- Add adaptive, list, and grid activity layouts with configurable popup width,
  item scale, and idle opacity.
- Add tabbed screenshot explorers to the Pages guide for clearer feature and
  settings discovery.

### Changed

- Make the activity popup and settings surfaces responsive across narrow,
  standard, and wide layouts.
- Reuse normalized PipeWire classification policy across stream nodes to
  reduce reactive refresh work.
- Make screenshot refreshes transactional, hot-reload temporary settings, and
  verify desktop state before publishing captured assets.

### Fixed

- Reload persisted activity history after history is re-enabled.
- Preserve shell, workspace, DND, plugin-settings, and screenshot state across
  successful or interrupted documentation captures.

## [0.5.3] - 2026-08-25

### Changed

- Keep maintainer-only workflows, tests, tooling, and runtime harnesses out of
  release archives while preserving installed and marketplace files.

### Security

- Launch trusted capture helpers and Omarchy commands with argument arrays;
  only explicit user-configured custom commands retain shell semantics.
- Strip text controls and Unicode direction overrides from session, history,
  and imported list metadata, and bound diagnostic clipboard subprocesses.

## [0.5.2] - 2026-08-25

### Fixed

- Content-address README screenshot URLs so GitHub cannot retain stale captures
  after the screenshot workflow refreshes their files.

## [0.5.1] - 2026-08-25

### Fixed

- Center screenshot crops on measured widget geometry and preserve desktop
  padding around both panel edges.

## [0.5.0] - 2026-08-25

### Added

- Add one canonical, auto-discovering behavior-suite runner shared by local npm
  workflows, CI, and contributor documentation.
- Add deep-linked screenshots for private-data and observer-health settings,
  with complete Pages guidance for keyboard use, transfer undo, and diagnostics.
- Add coalesced settings writes, visible save/failure feedback, shared status
  surfaces, and an assembled-plugin QML smoke test.
- Unify global boolean controls and settings-transfer result handling behind
  focused, runtime-tested components.
- Add QML failure and recovery coverage for settings transfer and persistent
  observers.
- Add a private one-step undo for settings imports and global resets.
- Add validated settings deep links with focused section scrolling from disabled
  history and per-device status-marker guidance, plus focused-monitor IPC access.
- Add a dedicated, keyboard-accessible history view with clear disabled,
  loading, and empty states, local search, relative period groups, result
  count pills, confidence provenance, and confirmed clearing.
- Show a verified application or service icon in activity and control-result
  notifications, with safe themed fallbacks.

### Fixed

- Reject generated archives and credential-like tracked content in CI before
  release packaging.
- Cancel pending observer retries on manual recovery and ignore buffered
  snapshots after monitoring is disabled.
- Add real QML interaction coverage for settings navigation, destructive-action
  confirmation, settings transfer, and observer lifecycle state.
- Establish a silent startup activity baseline so restarting Quickshell does
  not re-notify sessions that were already using a privacy device.
- Deduplicate replayed history records in both live and persisted retention.
- Make screenshot refreshes restart-safe and location-independent, capture both
  history states, preserve user history and shell settings, and keep variable
  image dimensions synchronized with the Pages gallery.
- Discover Quickshell from `PATH` in the runtime harness instead of relying on
  a developer-specific installation path.
- Honor vertical bar layouts and the host-provided foreground color contract.
- Resolve localized screenshot and recording directories while rejecting
  unsafe relative paths.

### Security

- Replace inline GeoClue shell probing with structured, bounded `busctl` calls
  using fixed arguments and per-call timeouts.

## [0.4.0] - 2026-08-25

### Added

- Add explicit per-device inheritance, customized-state indicators, adjacent
  navigation, scoped resets, and validated custom-backend save feedback.
- Present device diagnostics as labeled, actionable rows.

### Changed

- Align individual device settings with the global settings structure, clarify
  shared and inherited behavior, and disable unavailable placement actions.
- Reuse normalized runtime policy and device snapshots, suspend background
  probes when their device classes are disabled, and coalesce dependency
  refreshes across in-flight checks.
- Move control acceptance, observer invalidation/recovery, and history-load
  acceptance behind behavior-tested model policies while retaining QML wiring
  contracts.
- Replace heartbeat and observer-health implementation checks with boundary,
  clock-skew, identity, and QML-engine behavior tests backed by shared model
  policies.
- Replace duplicated dependency and preventative probe scheduling with a shared,
  behavior-tested FIFO and refresh-supersession policy.
- Replace the activity footer's implementation notes with a concise keyboard
  command guide whose advertised actions are checked against their handlers.
- Make popup selection, activation, editor navigation, and layered dismissal
  behavior-tested, including empty, stale, and boundary states.
- Behavior-test scroll-deferral semantics and diagnostic row formatting instead
  of relying on QML implementation and unrelated-label searches.
- Behavior-test monitoring telemetry text, expose fallback-observer heartbeat
  and retry timing, and render missing values as stable fallbacks.
- Behavior-test tooltip actions and remove the unused duplicate control-guidance
  implementation from the bar widget.

### Fixed

- Select the first activity row on initial keyboard navigation and prevent Enter
  from opening a selection removed by a reactive update.
- Prevent unsaved device fields and armed shared-reset confirmations from
  carrying across devices, and make global reset cover every bar appearance
  default.
- Clear stale direct-device and capture activity when an observer fails,
  surface fallback observer health, and avoid treating monitoring loss or
  uncertain recovery as genuine activity transitions.
- Reject unsupported, disabled, unavailable, busy, and duplicate control
  requests instead of reporting false success; preserve verification probes
  across concurrent monitoring-setting changes.
- Prevent stale history loads and dependency probes from publishing after
  their configuration is superseded, serialize history helper transactions,
  and bound normalized session metadata before identity or presentation.

### Security

- Apply printable-text and length bounds consistently to imported and edited
  device labels, icons, and process identifiers, and discard empty overrides.

## [0.3.0] - 2026-08-25

### Added

- Add a dedicated Appearance settings page with independent bar icon scale,
  item spacing, padding, status-marker position, and session-count controls.
- Refresh the activity, exact bar footprint, all four settings pages, and
  social-preview screenshots from the live plugin on the primary monitor.
- Establish a canonical documentation index and cross-linked ownership map to
  reduce duplicated maintainer guidance.
- Add independent Appearance settings for active, disabled, verifying, and
  degraded bar-status markers without hiding device icons.
- Add a custom bar-marker mode with sanitized glyph settings for every
  non-idle status.

### Fixed

- Apply settings-page IPC changes while the popup is already open so external
  navigation can switch among every global settings page.

## [0.2.0] - 2026-08-24

### Added

- Replace screenshot and recorder subprocess polling with a persistent structured observer.
- Route settings IPC through the singleton service and Omarchy's focused-monitor panel resolver.
- Coalesce notification bursts and expose explicit control transaction results.
- Add private diagnostic export, inferred-attribution controls, and observer telemetry.
- Extract reusable settings and activity-card components and enforce performance contracts.
- Add configurable semantic icon markers, textual state pills, pending verification feedback, session counts, popup density, per-device marker visibility, and disabled appearance.

- Project website, complete user guide, theme presets, and theme-aware favicon.
- Structured issue forms and repository community guidance.
- Normalized activity sessions with duration, device, source, confidence, and start/stop transitions.
- First-class monitoring health and degraded-state diagnostics.
- Optional same-user direct V4L2 and ALSA capture-handle monitoring.
- Reversible display and notification policies plus bounded, private, opt-in local history.
- Session, health, history, and rescan IPC diagnostics.
- Lower idle process churn through slower dependency, control-state, mute-state, screenshot, and configurable direct-device polling.
- Batched history persistence and allocation-free idle session refreshes.
- Tabbed in-widget global settings with scoped reset, responsive scrolling, and manifest-contract coverage.
- Stable popup settings edits, direct popup IPC, probe invalidation keyed only to monitoring changes, and timestamp-insensitive session updates that avoid needless layout work.
- Prevented main activity-row controls from leaking into global and per-device settings by giving generated delegates a visibility-owning container.
- Replaced constant one-second session polling with debounced reactive reconciliation plus a slow safety pass, and routed alerts through Omarchy's DND-aware notification command.
- Direct-device monitoring now uses a persistent inotify observer with heartbeats, stale-health detection, polling fallback, and bounded restart backoff.

### Changed

- Group private history and settings transfer with monitoring diagnostics so
  global settings have one clear place for private local data.
- Refresh runtime dependency probes when the selected audio backend changes and
  remove stale configuration-signature keys.

### Security

- Allowlist imported visual roles and settings-page IPC targets, bound helper
  arguments and stored fields, reject non-finite JSON values, and re-sanitize
  history when loading it.
- Replace predictable persistence temporary files with private, exclusive,
  atomically replaced files and enforce SHA-pinned external Actions in tests.

## [0.1.1] - 2026-08-21

### Added

- Privacy activity indicators and controls for microphone, audio output,
  camera, location, screen sharing, screenshots, and screen recording.
- Configurable display, notifications, classification, and capture backends.
- Security checks for camera modules, custom commands, paths, and recorder
  process identity.

### Fixed

- Canonical plugin identity and UVC interface binding behavior.

[Unreleased]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.14...HEAD
[0.9.14]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.13...v0.9.14
[0.9.13]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.12...v0.9.13
[0.9.12]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.11...v0.9.12
[0.9.11]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.10...v0.9.11
[0.9.10]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.9...v0.9.10
[0.9.9]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.8...v0.9.9
[0.9.8]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.7...v0.9.8
[0.9.7]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.6...v0.9.7
[0.9.6]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.5...v0.9.6
[0.9.5]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.4...v0.9.5
[0.9.4]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.3...v0.9.4
[0.9.3]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.2...v0.9.3
[0.9.2]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.1...v0.9.2
[0.9.1]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.8.1...v0.9.0
[0.8.1]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.5.3...v0.6.0
[0.5.3]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/bolens/omarchy-privacy-devices/releases/tag/v0.1.1
