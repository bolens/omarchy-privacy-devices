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

![Privacy Devices activity panel showing live device state and controls](preview.png?v=f84d6555466d)

The widget occupies only its privacy-device indicators in the center bar:

![Privacy Devices indicators in their exact bar footprint](docs/bar.png?v=6182f50ea001)

Activity notifications use the detected application icon when available:

![Privacy Devices notification with an application icon](docs/notification.png?v=0e44e9479176)

<details>
<summary>Settings pages</summary>

| General | Appearance |
| --- | --- |
| <img src="docs/general.png?v=e09fc51852e5" alt="General settings page" width="360"> | <img src="docs/appearance.png?v=af31fd843a8c" alt="Appearance settings page" width="360"> |
| Alerts | Monitoring |
| <img src="docs/alerts.png?v=079f488a969d" alt="Alerts settings page" width="360"> | <img src="docs/monitoring.png?v=2c3ef53c5f59" alt="Monitoring settings page" width="360"> |
| Private data | Observer health |
| <img src="docs/monitoring-private.png?v=fb0b32ebf4c3" alt="Private history and settings transfer controls" width="360"> | <img src="docs/monitoring-health.png?v=9f7fc4675235" alt="Monitoring status and observer health" width="360"> |
| Individual device settings | Activity history |
| <img src="docs/device.png?v=f7ede64e3607" alt="Individual privacy-device settings page" width="360"> | <img src="docs/history.png?v=c5d4de31a9b3" alt="Completed privacy activity history view" width="360"> |
| History disabled | |
| <img src="docs/history-disabled.png?v=c4e8da3d0e3c" alt="Activity history disabled state" width="360"> | |

</details>

## Highlights

- Per-application activity, session context, controls, and health for seven
  privacy-device classes.
- Reactive PipeWire monitoring plus optional same-user direct-device coverage.
- Verified mute, recording, camera, location, and screen-sharing controls.
- Global and per-device appearance, ordering, visibility, backend, and status
  settings.
- App-aware notifications, private diagnostics, searchable optional bounded
  history, and versioned settings transfer with one-step undo.
- Keyboard navigation throughout the popup and settings.
- Persistent observers and bounded background work, with no network telemetry.

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

See [CONTRIBUTING.md](CONTRIBUTING.md), the [validation matrix](TESTING.md), and
[ARCHITECTURE.md](ARCHITECTURE.md). Maintainers can refresh interface images
with the restoring [screenshot workflow](TESTING.md#refreshing-screenshots).

## License

[MIT](LICENSE)
