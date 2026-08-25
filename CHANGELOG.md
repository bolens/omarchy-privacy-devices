# Changelog

All notable changes to Privacy Devices are documented here. The project follows
[Semantic Versioning](https://semver.org/).
See the [documentation index](DOCUMENTATION.md) for topic ownership and the
maintainer guides that define release and validation procedures.

## [Unreleased]

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

### Fixed

- Prevent unsaved device fields and armed shared-reset confirmations from
  carrying across devices, and make global reset cover every bar appearance
  default.

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

[Unreleased]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/bolens/omarchy-privacy-devices/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/bolens/omarchy-privacy-devices/releases/tag/v0.1.1
