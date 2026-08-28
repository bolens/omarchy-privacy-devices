# Changelog

All notable changes to Privacy Devices are documented here. The project follows
[Semantic Versioning](https://semver.org/).
See the [documentation index](DOCUMENTATION.md) for topic ownership and the
maintainer guides that define release and validation procedures.

## [Unreleased]

### Changed

- Split the main popup's activity, history, and device-settings composition
  into dedicated QML domain views while preserving BarWidget's behavior and
  runtime-test facade.
- Isolate settings commit/rollback and private-transfer orchestration, lazy-load
  device backend editors, and move history helper processes and queues behind a
  dedicated service controller.
- Extract audio-endpoint, privacy-preset, capture-preview, per-device mutation,
  and presentation state machines into focused QML controllers while
  preserving the service and panel facades used by integrations and tests.
- Isolate popup navigation, notification routing, verified control transactions,
  dependency and device-control processes, and persistent observer lifecycles
  behind focused controllers with unchanged public service and panel contracts.
- Use one deterministic QML lint entry point for local and CI validation.
- Share width-driven settings grids across global pages so narrow and wide
  popup presets reflow from configured panel width instead of implicit child
  size.
- Add a repository-safe visual audit mode that retains unique top and bottom
  settings evidence only after monitor-scoped rendering and successful desktop
  restoration checks.

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

- Add locally stored named privacy modes that reapply available device controls
  through the existing verified serial transaction and undo path.
- Add bounded history trends, device/evidence filters, and stable sort modes.
- Add session-only audio-endpoint discovery feedback and a privacy-safe live
  application inspection target for diagnostics and X-Ray-style workflows.

### Changed

- Share retry and heartbeat ownership through a tested observer watchdog.
- Move QML runtime harnesses under `tests/qml/` while preserving installed-root
  import semantics in the live runner.
- Make screenshot capture monitor-specific, fresh for every documented view,
  resistant to blank/duplicate evidence, and independent of optional workspace
  routing plugins.
- Compact history filters into one responsive row and hide idle bar icons by
  default for new installations and global resets.

### Fixed

- Preserve the latest audio-endpoint refresh while another endpoint operation
  is active instead of depending on asynchronous `Process.running` updates.
- Restart reconfigured observers only after confirmed teardown, allow stopped
  observers to re-enable, and serialize dependency/shared-control ownership.
- Replace timing-based QML debounce and observer assertions with event-driven
  completion plus bounded failure deadlines.
- Serialize history writes in request order, retain the newest history reload
  across in-flight work, and publish capture-preview expiry only after its
  transient payload has been cleared.
- Replace fixed-delay settings, confirmation, preview-expiry, verification, and
  session-refresh runtime checks with observed completion signals.
- Wait for the selected monitor's bar instance to acknowledge panel closure and
  the fully rendered destination view before capturing screenshots.
- Prevent superseded GeoClue probes from republishing location activity after
  location monitoring is disabled or reconfigured.
- Claim observer startup ownership synchronously so same-turn configuration
  changes cannot launch or overwrite competing observer processes.
- Retain one final microphone and output-state probe independently while their
  respective subprocess is busy, including post-control verification refreshes.
- Capture a single documentation notification after its pixels differ from a
  fresh monitor baseline instead of sleeping and potentially sending duplicates.
- Select the capture monitor from the launching focused window, with pointer and
  focused-output fallbacks plus an explicit override, then route capture-only
  panel actions to that output's registered bar instance.
- Stop screenshot capture from switching the workspace on one monitor while
  recording another, and restore the selected monitor without overriding the
  user's original pointer/focus context.
- Avoid accepting wallpaper-only crops as populated plugin screenshots.

## [0.7.0] - 2026-08-26

### Added

- Add a confirmed, serial privacy lockdown for service-owned controls with
  verified partial results and a 30-second observed-state undo.
- Add bounded per-device visibility and notification policies plus friendly
  hardware labels.
- Add today and seven-day activity summaries derived from existing opt-in,
  bounded local history without extending retention.
- Add actionable activity/failure notifications and an allowlisted quick-action
  adapter for activity, history, diagnostics, lockdown, undo, and rescanning.
- Add optional transition-only observer-health alerts with per-source rate
  limiting and redacted source/code details.
- Add a guided, non-mutating privacy self-test with private storage permission
  checks, remediation guidance, notification delivery test, and redacted copy.
- Add an optional idempotent Omarchy menu adapter for searchable privacy
  actions, with lockdown routed through the existing confirmation step.
- Add verified per-endpoint block/allow controls for microphones and audio
  outputs on their device settings pages.
- Add validated p2p-style IPC deep links for the main view, individual device
  details, settings pages, and settings sections while retaining legacy routes.

### Changed

- Match new installations to the compact bar presentation with idle device
  icons and activity status markers disabled.
- Keep screenshot capture presentation-neutral while freezing only its sample
  activity and documentation history.
- Use accent for allowed in-use devices, foreground for enabled idle devices,
  muted for disabled devices, and urgent for observable blocked requests by
  default, with global and per-device role overrides and opacity controls for
  every global semantic color.
- Align integer settings with the shell's native bounded number fields and
  consolidate bar-layout controls into a balanced responsive grid.
- Reflow observer-health actions into a balanced responsive grid and present
  self-test output through the shared status surface.
- Describe the requested device state in privacy-control success and failure
  notifications instead of reporting a generic applied change.
- Replace the activity-header lockdown text and separate undo button with one
  compact, state-aware lock/unlock icon and tooltip.

### Fixed

- Prevent failed `grim` captures from leaving partial files that resemble successful screenshots.
- Fail closed on malformed audio metadata, corrupt history encoding, unsafe
  screenshot publication paths, and incomplete owned menu blocks.
- Sanitize location-client labels and make capture recovery independent of the
  caller's working directory.
- Reject invalid zero-sized screenshot metadata before publishing documentation.
- Prevent full-row clicks from activating hidden controls for screenshots or
  devices with unavailable dependencies.
- Preserve zero in bounded integer settings instead of replacing it with the
  field fallback.
- Preserve rapid per-device appearance edits to different fields while settings
  writes are coalesced.
- Describe an observable blocked request consistently in activity cards instead
  of pairing its urgent state with an idle availability message.
- Allow the compact privacy-lockdown control to enter its required confirmation
  state and execute the verified serial lockdown plan.
- Report degraded fallback-observer health in the guided privacy self-test
  instead of silently treating the missing alias as healthy.
- Give active-count summary rows complete pending and dependency state so the
  bar does not emit QML binding warnings while rendering the summary icon.

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

[Unreleased]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.8.1...HEAD
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
