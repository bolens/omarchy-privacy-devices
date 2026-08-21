# Privacy Devices

A unified Omarchy shell widget for microphone capture, audio playback, camera
access, portal screen sharing, screenshots, screen recording, and GeoClue
location access.

## Install

```sh
omarchy plugin add https://github.com/bolens/omarchy-privacy-devices.git --enable
```

Add or move the widget through Setup → Bar, or run:

```sh
omarchy bar move io.github.bolens.privacy-devices --section center
```

## Usage

PipeWire streams are observed reactively through Quickshell. Audio mute controls
prefer PulseAudio's `pactl` interface (including PipeWire's PulseAudio-compatible
server) and fall back to native `wpctl`. GeoClue and known recorder processes
use configurable, bounded fallback polling. Click the widget for per-application
details. Left-click an individual icon to invoke its control, middle-click to
open that item's settings, and right-click to open the activity panel.

Configure the widget through Setup → Plugins or its entry in
`~/.config/omarchy/shell.json`. Available settings include monitored kinds,
display order, idle visibility and opacity, bar presentation, application
exclusions, video-classification keywords, polling intervals, icons, and
active/inactive plus muted/unmuted theme-color roles. Microphone and output
icon colors communicate mute state while the surrounding popup card continues
to communicate activity.

Controllable activity rows in the popup are toggles themselves, covering the
default microphone and audio output plus starting or stopping screen recording.
Preventative controls can block camera access by unloading its configured
kernel module, block location by runtime-masking GeoClue, and block screen
sharing by runtime-masking the Hyprland portal backend. Camera and location
changes request Polkit authorization. Screen-share blocking also suspends other
features supplied by the Hyprland portal backend until re-enabled.

Camera and location blocking intentionally perform privileged system changes.
They use Polkit to unload or load the configured camera kernel module and to
runtime-mask or unmask GeoClue. Screen-share blocking runtime-masks the user's
Hyprland portal service without elevated privileges. All masks are runtime-only
and disappear after reboot.

Dependencies are checked independently for every privacy item. When a requirement
is missing, only that row changes to **Install**; clicking it opens an Omarchy
terminal and installs the smallest package group for that control with
`omarchy pkg add`. All unrelated privacy indicators and controls remain available.

Screen recording can follow Omarchy's current recorder (the default), explicitly
select `gpu-screen-recorder`, select `wf-recorder`, or use custom start/stop
commands plus a process-name substring for activity detection. Dependency checks
and installation follow the selected backend.

The screen-recording item editor exposes that backend selector and the custom
backend fields in context. Microphone and audio-output editors also expose an
`auto`/`pactl`/`wpctl` control preference, while the camera editor exposes its
kernel module. Audio activity detection remains PipeWire-native regardless of
the selected mute-control backend.

The screenshot editor similarly offers Omarchy's smart capture flow, direct
`grim` region capture, `grim` with Satty annotation, Hyprshot, Flameshot, or a
custom command with an optional process substring for activity indication. Its
dependency prompt installs only standard repository packages required by the
selected screenshot backend.

In icon modes each bar icon has an individual activity tooltip. Left-click
toggles a supported control or opens details for status-only items, right-click
always opens the details panel, and middle-click opens per-item settings.

The default video fallback treats an unrecognized active video-input stream as
a screen share. Extend `cameraKeywords` for unusual camera drivers and
`screenShareKeywords` for unusual portal or capture clients.

## Remove

Re-enable any preventative control you want restored before removal, then run:

```sh
omarchy plugin remove io.github.bolens.privacy-devices
```

Runtime service masks clear on reboot. If the camera kernel module remains
unloaded, load it with `sudo modprobe uvcvideo` (or your configured module).

## Development

Validate the plugin with:

```sh
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Service.qml
shellcheck privacy-control privacy-deps privacy-recording privacy-screenshot
node tests/model.test.js
```

## License

MIT
