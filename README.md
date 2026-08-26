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

![Privacy Devices activity panel showing live device state and controls](preview.png?v=f9d50318bb07)

The widget occupies only its privacy-device indicators in the center bar:

![Privacy Devices indicators in their exact bar footprint](docs/bar.png?v=17101b1467e6)

Activity notifications use the detected application icon when available:

![Privacy Devices notification with an application icon](docs/notification.png?v=319e2ced4104)

<details>
<summary>Settings pages</summary>

| General | Appearance |
| --- | --- |
| <img src="docs/general.png?v=8d972d485af7" alt="General settings page" width="360"> | <img src="docs/appearance.png?v=68401dafb7fa" alt="Appearance settings page" width="360"> |
| Alerts | Monitoring |
| <img src="docs/alerts.png?v=4281fc1b9600" alt="Alerts settings page" width="360"> | <img src="docs/monitoring.png?v=da4f54f31adb" alt="Monitoring settings page" width="360"> |
| Private data | Observer health |
| <img src="docs/monitoring-private.png?v=126932075bc3" alt="Private history and settings transfer controls" width="360"> | <img src="docs/monitoring-health.png?v=463f15d6cb8f" alt="Monitoring status and observer health" width="360"> |
| Individual device settings | Activity history |
| <img src="docs/device.png?v=9dd0f8c2f262" alt="Individual privacy-device settings page" width="360"> | <img src="docs/history.png?v=9f6198a88b22" alt="Completed privacy activity history view" width="360"> |
| History disabled | |
| <img src="docs/history-disabled.png?v=779cd8c87c75" alt="Activity history disabled state" width="360"> | |

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
