# Privacy Devices

A configurable Omarchy Shell widget that combines privacy activity indicators
and controls for microphones, audio output, cameras, location, screen sharing,
screenshots, and screen recording.

[Website and user guide](https://bolens.github.io/omarchy-privacy-devices/) ·
[Community marketplace listing](https://omarchyplugins.com/plugin.html?id=io.github.bolens.privacy-devices) ·
[Documentation](DOCUMENTATION.md) ·
[Get support](SUPPORT.md) ·
[Report an issue](https://github.com/bolens/omarchy-privacy-devices/issues/new/choose)

Contributors: [contributing guide](CONTRIBUTING.md) ·
[architecture](ARCHITECTURE.md) · [security policy](SECURITY.md)

![Privacy Devices activity panel showing live device state and controls](preview.png?v=a96410fcc4f8)

The widget occupies only its privacy-device indicators in the center bar:

![Privacy Devices indicators in their exact bar footprint](docs/bar.png?v=c9e43e041535)

Activity notifications use the detected application icon when available:

![Privacy Devices notification with an application icon](docs/notification.png?v=2230f689ac60)

<details>
<summary>Settings pages</summary>

| General | Appearance |
| --- | --- |
| <img src="docs/general.png?v=a9915049db0c" alt="General settings page" width="360"> | <img src="docs/appearance.png?v=1e9956c90915" alt="Appearance settings page" width="360"> |
| Alerts | Monitoring |
| <img src="docs/alerts.png?v=9f99b155a1a5" alt="Alerts settings page" width="360"> | <img src="docs/monitoring.png?v=fd360918f85f" alt="Monitoring settings page" width="360"> |
| Private data | Observer health |
| <img src="docs/monitoring-private.png?v=05003eb3b807" alt="Private history and settings transfer controls" width="360"> | <img src="docs/monitoring-health.png?v=03aeabb63466" alt="Monitoring status and observer health" width="360"> |
| Individual device settings | Activity history |
| <img src="docs/device.png?v=a3847354b814" alt="Individual privacy-device settings page" width="360"> | <img src="docs/history.png?v=cb1f02bc6dde" alt="Completed privacy activity history view" width="360"> |
| History disabled | |
| <img src="docs/history-disabled.png?v=2040f334bf1b" alt="Activity history disabled state" width="360"> | |

</details>

## Highlights

- Per-application activity, session context, controls, and health for seven
  privacy-device classes.
- Reactive PipeWire monitoring plus optional same-user direct-device coverage.
- Verified mute, recording, camera, location, and screen-sharing controls, plus
  a confirmed privacy lockdown with observed-state undo.
- Per-endpoint microphone and audio-output management on their device settings
  pages, with exact hardware names and verified mute/unmute results.
- Global and per-device appearance, ordering, visibility, backend, and status
  settings.
- App- and device-aware visibility and notification policies, friendly hardware
  labels, private diagnostics, and searchable optional bounded history with
  local today/seven-day summaries.
- Click-through activity notifications, optional rate-limited observer-health
  alerts, and a guided redacted self-test with remediation guidance.
- Allowlisted IPC quick actions for activity, history, diagnostics, lockdown,
  undo, and rescanning, suitable for thin launcher adapters.
- Keyboard navigation throughout the popup and settings.
- Persistent observers and bounded background work, with no network telemetry.

See the [user guide](https://bolens.github.io/omarchy-privacy-devices/#usage)
for supported controls, requirements, configuration, privacy behavior,
troubleshooting, and lifecycle commands.

Notification actions and launchers use the installed `privacy-action` helper.
It accepts only `open-activity [kind]`, `open-history [kind]`,
`open-diagnostics`, `lockdown`, `undo-lockdown`, and `rescan`; no observed
metadata is interpreted as a command.

To add searchable Privacy Devices rows to the Omarchy menu, run the optional,
idempotent adapter from the installed plugin:

```sh
~/.config/omarchy/plugins/io.github.bolens.privacy-devices/privacy-menu-entry install
```

Use `status` to inspect it or `remove` to delete only the entries owned by this
plugin. The lockdown row opens the existing confirmation step; it never changes
device state directly.

## Quick install

```sh
omarchy plugin add https://github.com/bolens/omarchy-privacy-devices.git --enable
```

Add or move the widget through **Setup → Bar**, or run:

```sh
omarchy bar move io.github.bolens.privacy-devices --section center
```

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md), the [validation matrix](TESTING.md), and
[ARCHITECTURE.md](ARCHITECTURE.md). Maintainers can refresh interface images
with the restoring [screenshot workflow](TESTING.md#refreshing-screenshots).

## License

[MIT](LICENSE)
