# Privacy Devices

A configurable Omarchy Shell widget that combines privacy activity indicators
and controls for microphones, audio output, cameras, location, screen sharing,
screenshots, and screen recording.

[Website and user guide](https://bolens.github.io/omarchy-privacy-devices/) ·
[Official plugin listing](https://omarchyplugins.com/plugin.html?id=io.github.bolens.privacy-devices) ·
[Documentation](DOCUMENTATION.md) ·
[Get support](SUPPORT.md) ·
[Report an issue](https://github.com/bolens/omarchy-privacy-devices/issues/new/choose)

Contributors: [contributing guide](CONTRIBUTING.md) ·
[architecture](ARCHITECTURE.md) · [security policy](SECURITY.md)

![Privacy Devices activity panel showing live device state and controls](preview.png)

The widget occupies only its privacy-device indicators in the center bar:

![Privacy Devices indicators in their exact bar footprint](docs/bar.png)

<details>
<summary>All global settings pages</summary>

| General | Appearance |
| --- | --- |
| <img src="docs/general.png" alt="General settings page" width="360"> | <img src="docs/appearance.png" alt="Appearance settings page" width="360"> |
| Alerts | Monitoring |
| <img src="docs/alerts.png" alt="Alerts settings page" width="360"> | <img src="docs/monitoring.png" alt="Monitoring settings page" width="360"> |

</details>

## Highlights

- Live per-application privacy activity in the bar and popup.
- Session duration, device, detection source, confidence, and monitoring-health details.
- Optional same-user direct camera and microphone device monitoring for applications that bypass PipeWire.
- Optional bounded local history plus independently reversible display and notification policies.
- Four focused global-settings pages for behavior, appearance, alerts, and monitoring.
- Independent bar icon scale, item spacing, padding, status-marker position, session counts, colors, and idle appearance.
- Live observer freshness, mode, heartbeat, and retry diagnostics on the Monitoring settings page.
- One persistent structured observer replaces per-second screenshot and recorder subprocess polling.
- Private-by-default diagnostic export redacts application and device identities.
- Versioned, bounded settings export/import with private file permissions and atomic replacement.
- Control actions remain pending until a state probe verifies the requested result.
- Keyboard navigation: arrows select activity, Enter opens details, `s` opens settings, `r` rescans, and `1`–`4` switch settings tabs.
- Inline mute, recording, and preventative privacy controls.
- Configurable activity, ordering, icons, visibility, actions, semantic status markers, state pills, popup density, pending animation, session counts, disabled appearance, and
  capture backends.
- Local monitoring with no network telemetry.

See the [user guide](https://bolens.github.io/omarchy-privacy-devices/#usage)
for supported controls, requirements, configuration, privacy behavior,
troubleshooting, and lifecycle commands.

## Quick install

```sh
omarchy plugin add https://github.com/bolens/omarchy-privacy-devices.git --enable
```

Add or move the widget through **Setup → Bar**, or run:

```sh
omarchy bar move io.github.bolens.privacy-devices --section center
```

## Development

Start with the [contributing guide](CONTRIBUTING.md). The canonical validation
matrix, including clean-archive, QML runtime, site, and live checks, is in
[TESTING.md](TESTING.md). Review [ARCHITECTURE.md](ARCHITECTURE.md) before
changing runtime ownership or performance constraints.

Maintainers can refresh all live interface images with the safe, restoring
[screenshot workflow](TESTING.md#refreshing-screenshots).

Enhanced monitoring reads same-user `/proc/<pid>/fd` links for open V4L2 and
ALSA capture devices. It never opens devices or reads media. Recent history is
off by default; when enabled, it stores only session metadata under
`$XDG_STATE_HOME/omarchy-privacy-devices`, limited to seven days or 100 entries.
Disabling or clearing history removes the stored file.

Idle probes are deliberately bounded: direct-device monitoring defaults to a
five-second interval, dependency checks run every five minutes, and control
actions trigger immediate verification instead of waiting for the next poll.

## License

[MIT](LICENSE)
