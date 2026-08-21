# Privacy Devices

A configurable Omarchy Shell widget that combines privacy activity indicators
and controls for microphones, audio output, cameras, location, screen sharing,
screenshots, and screen recording.

[Website and user guide](https://bolens.github.io/omarchy-privacy-devices/) ·
[Official plugin listing](https://omarchyplugins.com/plugin.html?id=io.github.bolens.privacy-devices) ·
[Report an issue](https://github.com/bolens/omarchy-privacy-devices/issues/new)

![Privacy Devices popup](preview.png)

## Highlights

- Live per-application privacy activity in the bar and popup.
- Inline mute, recording, and preventative privacy controls.
- Configurable activity, ordering, icons, visibility, actions, colors, and
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

```sh
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Service.qml
shellcheck privacy-control privacy-deps privacy-recording privacy-screenshot
node tests/model.test.js
node tests/security.test.js
```

## License

[MIT](LICENSE)
