import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "Model.js" as Model

Item {
  id: root

  property var shell: null
  property var manifest: null
  property var settings: ({})
  property var locationApps: []
  property bool locationActive: false
  property bool recordingActive: false
  property var recordingApps: []
  property bool screenshotActive: false

  readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property var defaultSource: Pipewire.defaultAudioSource
  readonly property var defaultSink: Pipewire.defaultAudioSink
  property bool fallbackMicrophoneMuted: false
  property bool fallbackOutputMuted: false
  property bool cameraAllowed: true
  property bool locationAllowed: true
  property bool screenShareAllowed: true
  property string privacyControlKind: ""
  property var lastProbeExitCodes: ({})
  property var lastControlExitCodes: ({})
  property var previousActivity: ({})
  property bool activityInitialized: false
  property var dependencyReadyMap: ({})
  property var dependencyCheckedMap: ({})
  property var dependencyQueue: []
  property string dependencyCheckKind: ""
  readonly property bool microphoneMuted: fallbackMicrophoneMuted
  readonly property bool outputMuted: fallbackOutputMuted
  readonly property var streamNodes: {
    var result = []
    for (var index = 0; index < nodes.length; index++) {
      var node = nodes[index]
      if (node && node.isStream) result.push(node)
    }
    return result
  }

  function configure(next) {
    settings = next || ({})
    locationTimer.interval = boundedSeconds(settings.locationPollSeconds, 15, 5, 300) * 1000
    recordingTimer.interval = boundedSeconds(settings.recordingPollSeconds, 2, 1, 60) * 1000
    refreshFallbacks()
    refreshDependencies()
  }

  function boundedSeconds(value, fallback, minimum, maximum) {
    var parsed = Number(value)
    if (!isFinite(parsed)) parsed = fallback
    return Math.max(minimum, Math.min(maximum, Math.round(parsed)))
  }

  function enabledKinds() {
    return Model.arraySetting(settings.enabledKinds, Model.KINDS)
  }

  function kindEnabled(kind) {
    return enabledKinds().indexOf(kind) !== -1
  }

  function appsFor(kind) {
    if (kind === "location") return locationApps
    if (kind === "screen-recording") return recordingApps
    if (kind === "screenshot") return screenshotActive ? ["Screenshot tool"] : []
    var result = []
    for (var index = 0; index < streamNodes.length; index++) {
      var node = streamNodes[index]
      if (Model.classifyNode(node, settings) === kind) result.push(Model.appName(node))
    }
    return settings.deduplicateApps === false ? result : Model.unique(result)
  }

  function active(kind) {
    if (!kindEnabled(kind)) return false
    if (kind === "location") return locationActive
    if (kind === "screen-recording") return recordingActive
    if (kind === "screenshot") return screenshotActive
    return appsFor(kind).length > 0
  }

  function controllable(kind) {
    if (kind === "microphone" || kind === "audio-output") return true
    if (Model.arraySetting(settings.blockableKinds, ["camera", "screen-share", "location"]).indexOf(kind) !== -1) return true
    return kind === "screen-recording" || kind === "screenshot"
  }

  function controlEnabled(kind) {
    if (kind === "microphone") return !microphoneMuted
    if (kind === "audio-output") return !outputMuted
    if (kind === "camera") return cameraAllowed
    if (kind === "location") return locationAllowed
    if (kind === "screen-share") return screenShareAllowed
    if (kind === "screen-recording") return recordingActive
    if (kind === "screenshot") return false
    return false
  }

  function controlPending(kind) {
    return privacyControlKind === kind
  }

  function dependenciesReady(kind) {
    return dependencyCheckedMap[kind] !== true || dependencyReadyMap[kind] === true
  }

  function dependencyDescription(kind) {
    if (kind === "microphone" || kind === "audio-output") return "Audio controls require pactl (libpulse) or wpctl"
    if (kind === "camera") return "Camera blocking requires Polkit"
    if (kind === "location") return "Location blocking requires GeoClue and Polkit"
    if (kind === "screen-share") return "Screen sharing requires xdg-desktop-portal-hyprland"
    if (kind === "screenshot") return "Screenshots require grim and slurp"
    if (kind === "screen-recording") return "The selected recording backend is not installed"
    return "No additional dependencies"
  }

  function dependencyHelperPath() {
    return String(Qt.resolvedUrl("privacy-deps")).replace(/^file:\/\//, "")
  }

  function refreshDependencies() {
    if (dependencyCheckProc.running) return
    dependencyQueue = enabledKinds().slice()
    runNextDependencyCheck()
  }

  function runNextDependencyCheck() {
    if (dependencyCheckProc.running || dependencyQueue.length === 0) return
    dependencyCheckKind = dependencyQueue.shift()
    dependencyCheckProc.command = [dependencyHelperPath(), "check", dependencyCheckKind, recordingBackend(), audioControlBackend(), screenshotBackend()]
    dependencyCheckProc.running = true
  }

  function installDependencies(kind) {
    if (dependenciesReady(kind)) return
    Quickshell.execDetached(["omarchy-launch-terminal", dependencyHelperPath(), "install", kind, recordingBackend(), audioControlBackend(), screenshotBackend()])
  }

  function recordingBackend() {
    var backend = String(settings.recordingBackend || "omarchy")
    return ["omarchy", "gpu-screen-recorder", "wf-recorder", "custom"].indexOf(backend) >= 0 ? backend : "omarchy"
  }

  function audioControlBackend() {
    var backend = String(settings.audioControlBackend || "auto")
    return ["auto", "pactl", "wpctl"].indexOf(backend) >= 0 ? backend : "auto"
  }

  function screenshotBackend() {
    var backend = String(settings.screenshotBackend || "omarchy")
    return ["omarchy", "grim", "grim-satty", "hyprshot", "flameshot", "custom"].indexOf(backend) >= 0 ? backend : "omarchy"
  }

  function audioToggleCommand(kind) {
    var pactlTarget = kind === "microphone" ? "source" : "sink"
    var pactlName = kind === "microphone" ? "@DEFAULT_SOURCE@" : "@DEFAULT_SINK@"
    var wpctlName = kind === "microphone" ? "@DEFAULT_AUDIO_SOURCE@" : "@DEFAULT_AUDIO_SINK@"
    if (audioControlBackend() === "pactl") return ["pactl", "set-" + pactlTarget + "-mute", pactlName, "toggle"]
    if (audioControlBackend() === "wpctl") return ["wpctl", "set-mute", wpctlName, "toggle"]
    return ["sh", "-c", "if command -v pactl >/dev/null 2>&1; then exec pactl set-" + pactlTarget + "-mute " + pactlName + " toggle; fi; exec wpctl set-mute " + wpctlName + " toggle"]
  }

  function audioStateCommand(kind) {
    var pactlTarget = kind === "microphone" ? "source" : "sink"
    var pactlName = kind === "microphone" ? "@DEFAULT_SOURCE@" : "@DEFAULT_SINK@"
    var wpctlName = kind === "microphone" ? "@DEFAULT_AUDIO_SOURCE@" : "@DEFAULT_AUDIO_SINK@"
    var pactlProbe = "state=$(pactl get-" + pactlTarget + "-mute " + pactlName + " 2>/dev/null) || exit 12; case \"$state\" in *yes*) exit 10;; *no*) exit 11;; esac"
    var wpctlProbe = "state=$(wpctl get-volume " + wpctlName + " 2>/dev/null) || exit 12; case \"$state\" in *'[MUTED]'*) exit 10;; Volume:*) exit 11;; esac; exit 12"
    if (audioControlBackend() === "pactl") return ["sh", "-c", pactlProbe]
    if (audioControlBackend() === "wpctl") return ["sh", "-c", wpctlProbe]
    return ["sh", "-c", "if command -v pactl >/dev/null 2>&1; then " + pactlProbe + "; fi; " + wpctlProbe]
  }

  function toggleControl(kind) {
    if (kind === "microphone" && !microphoneControlProc.running) {
      fallbackMicrophoneMuted = !fallbackMicrophoneMuted
      microphoneControlProc.command = audioToggleCommand(kind)
      microphoneControlProc.running = true
    }
    else if (kind === "audio-output" && !outputControlProc.running) {
      fallbackOutputMuted = !fallbackOutputMuted
      outputControlProc.command = audioToggleCommand(kind)
      outputControlProc.running = true
    }
    else if ((kind === "camera" || kind === "location" || kind === "screen-share") && !privacyControlProc.running) {
      privacyControlKind = kind
      privacyStateQueue = []
      if (privacyStateProc.running) privacyStateProc.running = false
      setAllowed(kind, !controlEnabled(kind))
      privacyControlProc.command = [helperPath(), "toggle", kind]
      privacyControlProc.running = true
    }
  }

  function helperPath() {
    return String(Qt.resolvedUrl("privacy-control")).replace(/^file:\/\//, "")
  }

  function setAllowed(kind, allowed) {
    if (kind === "camera") cameraAllowed = allowed
    else if (kind === "location") locationAllowed = allowed
    else if (kind === "screen-share") screenShareAllowed = allowed
  }

  function setResult(mapName, kind, exitCode) {
    var source = mapName === "probe" ? lastProbeExitCodes : lastControlExitCodes
    var next = Object.assign({}, source)
    next[kind] = Number(exitCode)
    if (mapName === "probe") lastProbeExitCodes = next
    else lastControlExitCodes = next
  }

  function backendFor(kind) {
    if (kind === "microphone" || kind === "audio-output") return "Audio control: " + audioControlBackend() + "; activity: PipeWire"
    if (kind === "camera") return "UVC USB driver interface binding"
    if (kind === "screen-share") return "xdg-desktop-portal-hyprland user service"
    if (kind === "location") return "GeoClue system service"
    if (kind === "screen-recording") return "Recorder process detection (" + recordingBackend() + ")"
    if (kind === "screenshot") return "Screenshot capture (" + screenshotBackend() + ")"
    return "Status only"
  }

  function diagnostic(kind) {
    var state = controlPending(kind) ? "Pending authorization" : ""
    if (!state && kind === "screenshot") state = "Capture action ready"
    else if (!state && kind === "screen-recording") state = recordingActive ? "Recording" : "Stopped"
    else if (!state && (kind === "microphone" || kind === "audio-output")) state = controlEnabled(kind) ? "Unmuted" : "Muted"
    else if (!state) state = controlEnabled(kind) ? "Allowed" : "Blocked"
    return {
      backend: backendFor(kind),
      active: active(kind),
      apps: appsFor(kind),
      enabled: controlEnabled(kind),
      pending: controlPending(kind),
      dependenciesReady: dependenciesReady(kind),
      dependencyDescription: dependencyDescription(kind),
      controlState: state,
      probeExitCode: lastProbeExitCodes[kind] === undefined ? -1 : lastProbeExitCodes[kind],
      controlExitCode: lastControlExitCodes[kind] === undefined ? -1 : lastControlExitCodes[kind]
    }
  }

  function notify(title, body) {
    Quickshell.execDetached(["notify-send", "--app-name=Omarchy Privacy", "--", Model.autoTextSafe(title), Model.autoTextSafe(body)])
  }

  function checkActivityNotifications() {
    var kinds = enabledKinds()
    var next = {}
    var notifyKinds = Model.arraySetting(settings.notificationKinds, ["microphone", "camera", "screen-share", "screen-recording", "location"])
    for (var index = 0; index < kinds.length; index++) {
      var kind = kinds[index]
      var isActive = active(kind)
      next[kind] = isActive
      if (activityInitialized && settings.notifyOnActivity !== false && isActive && previousActivity[kind] !== true && notifyKinds.indexOf(kind) !== -1) {
        var apps = appsFor(kind)
        notify("Privacy activity started", Model.label(kind) + (apps.length ? ": " + apps.join(", ") : " is active"))
      }
    }
    previousActivity = next
    activityInitialized = true
  }

  function notifyControlResult(kind, exitCode) {
    if (settings.notifyOnControlChanges === false) return
    if (Number(exitCode) === 0) notify("Privacy control updated", Model.label(kind) + " change applied")
    else notify("Privacy control failed", Model.label(kind) + " was not changed")
  }

  function refreshPreventativeControls() {
    if (privacyControlProc.running || privacyControlKind !== "" || privacyStateProc.running) return
    var kinds = Model.arraySetting(settings.blockableKinds, ["camera", "screen-share", "location"])
    privacyStateQueue = kinds.slice()
    runNextPrivacyState()
  }

  property var privacyStateQueue: []
  property string privacyStateKind: ""

  function runNextPrivacyState() {
    if (privacyStateQueue.length === 0 || privacyStateProc.running) return
    privacyStateKind = privacyStateQueue.shift()
    privacyStateProc.command = [helperPath(), "status", privacyStateKind]
    privacyStateProc.running = true
  }

  function refreshMuteState() {
    if (!microphoneStateProc.running) {
      microphoneStateProc.command = audioStateCommand("microphone")
      microphoneStateProc.running = true
    }
    if (!outputStateProc.running) {
      outputStateProc.command = audioStateCommand("audio-output")
      outputStateProc.running = true
    }
  }

  function snapshot() {
    var result = []
    var kinds = enabledKinds()
    for (var index = 0; index < kinds.length; index++) {
      var kind = kinds[index]
      result.push({
        kind: kind,
        label: Model.label(kind),
        active: active(kind),
        apps: appsFor(kind),
        controllable: controllable(kind),
        enabled: controlEnabled(kind),
        pending: controlPending(kind),
        dependenciesReady: dependenciesReady(kind)
      })
    }
    return result
  }

  function refreshFallbacks() {
    refreshPreventativeControls()
    if (kindEnabled("location")) refreshLocation()
    else { locationActive = false; locationApps = [] }
    if (kindEnabled("screen-recording")) refreshRecording()
    else { recordingActive = false; recordingApps = [] }
  }

  function refreshLocation() {
    if (locationProc.running) return
    locationProc.command = ["sh", "-c",
      "inuse=$(timeout 2 busctl get-property org.freedesktop.GeoClue2 /org/freedesktop/GeoClue2/Manager org.freedesktop.GeoClue2.Manager InUse 2>/dev/null || true); "
      + "[ \"$inuse\" = 'b true' ] || { printf 'inactive\\n'; exit; }; printf 'active\\n'; "
      + "for p in $(timeout 2 busctl tree org.freedesktop.GeoClue2 2>/dev/null | sed -n 's,.*\\(/org/freedesktop/GeoClue2/Client/[0-9][0-9]*\\).*,\\1,p'); do "
      + "a=$(timeout 2 busctl get-property org.freedesktop.GeoClue2 \"$p\" org.freedesktop.GeoClue2.Client Active 2>/dev/null || true); [ \"$a\" = 'b true' ] || continue; "
      + "d=$(timeout 2 busctl get-property org.freedesktop.GeoClue2 \"$p\" org.freedesktop.GeoClue2.Client DesktopId 2>/dev/null | cut -d' ' -f2- | tr -d '\"'); "
      + "[ -n \"$d\" ] && printf '%s\\n' \"$d\"; done"]
    locationProc.running = true
  }

  function refreshRecording() {
    if (recordingProc.running) return
    var backend = recordingBackend()
    var processName = backend === "wf-recorder" ? "wf-recorder"
      : backend === "custom" ? String(settings.recordingProcessName || "")
      : "gpu-screen-recorder"
    recordingProc.command = ["sh", "-c",
      "name=$1; [ -n \"$name\" ] || { printf 'inactive\\n'; exit; }; "
      + "ps -eo args= | grep -F -- \"$name\" | grep -v -F -- 'grep -F' >/dev/null "
      + "|| { printf 'inactive\\n'; exit; }; printf 'active\\nScreen recorder\\n'",
      "privacy-recording-probe", processName]
    recordingProc.running = true
  }

  function refreshScreenshot() {
    if (screenshotProc.running) return
    var processName = screenshotBackend() === "custom" ? String(settings.screenshotProcessName || "") : "grim|slurp|satty|hyprpicker|hyprshot|flameshot"
    screenshotProc.command = screenshotBackend() === "custom"
      ? ["sh", "-c", "name=$1; [ -n \"$name\" ] && ps -eo args= | grep -F -- \"$name\" | grep -v -F -- 'grep -F' >/dev/null", "privacy-screenshot-probe", processName]
      : ["sh", "-c", "pgrep -x '" + processName + "' >/dev/null 2>&1"]
    screenshotProc.running = true
  }

  function parseFallback(text, kind) {
    var lines = String(text || "").trim().split("\n")
    var isActive = lines.length > 0 && lines[0] === "active"
    var apps = isActive ? Model.unique(lines.slice(1).filter(Boolean)) : []
    if (kind === "location") { locationActive = isActive; locationApps = apps }
    else { recordingActive = isActive; recordingApps = apps }
  }

  Timer {
    id: locationTimer
    interval: 15000
    repeat: true
    running: root.kindEnabled("location")
    onTriggered: root.refreshLocation()
  }

  Timer {
    interval: 3000
    repeat: true
    running: true
    onTriggered: root.refreshPreventativeControls()
  }

  Timer {
    interval: 1000
    repeat: true
    running: true
    onTriggered: root.checkActivityNotifications()
  }

  Timer {
    interval: 2000
    repeat: true
    running: true
    onTriggered: root.refreshMuteState()
  }

  Timer {
    id: recordingTimer
    interval: 2000
    repeat: true
    running: root.kindEnabled("screen-recording")
    onTriggered: root.refreshRecording()
  }

  Timer {
    interval: 500
    repeat: true
    running: root.kindEnabled("screenshot")
    onTriggered: root.refreshScreenshot()
  }

  Timer {
    interval: 10000
    repeat: true
    running: true
    onTriggered: root.refreshDependencies()
  }

  Process {
    id: locationProc
    onExited: function(exitCode) { root.setResult("probe", "location", exitCode) }
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: function(text) { root.parseFallback(text, "location") } }
  }

  Process {
    id: microphoneStateProc
    onExited: function(exitCode) { root.setResult("probe", "microphone", exitCode); root.fallbackMicrophoneMuted = Model.mutedFromExitCode(exitCode, root.fallbackMicrophoneMuted) }
  }

  Process {
    id: outputStateProc
    onExited: function(exitCode) { root.setResult("probe", "audio-output", exitCode); root.fallbackOutputMuted = Model.mutedFromExitCode(exitCode, root.fallbackOutputMuted) }
  }

  Process {
    id: microphoneControlProc
    onExited: function(exitCode) { root.setResult("control", "microphone", exitCode); root.notifyControlResult("microphone", exitCode); root.refreshMuteState() }
  }

  Process {
    id: outputControlProc
    onExited: function(exitCode) { root.setResult("control", "audio-output", exitCode); root.notifyControlResult("audio-output", exitCode); root.refreshMuteState() }
  }

  Process {
    id: privacyStateProc
    onExited: function(exitCode) {
      root.setResult("probe", root.privacyStateKind, exitCode)
      if (Model.shouldAcceptControlProbe(root.privacyStateKind, root.privacyControlKind))
        root.setAllowed(root.privacyStateKind, Model.mutedFromExitCode(exitCode, root.controlEnabled(root.privacyStateKind)))
      root.runNextPrivacyState()
    }
  }

  Process {
    id: privacyControlProc
    onExited: function(exitCode) {
      var kind = root.privacyControlKind
      root.setResult("control", kind, exitCode)
      root.notifyControlResult(kind, exitCode)
      root.privacyControlKind = ""
      root.refreshPreventativeControls()
    }
  }

  Process {
    id: recordingProc
    onExited: function(exitCode) { root.setResult("probe", "screen-recording", exitCode) }
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: function(text) { root.parseFallback(text, "screen-recording") } }
  }

  Process {
    id: screenshotProc
    onExited: function(exitCode) { root.setResult("probe", "screenshot", exitCode); root.screenshotActive = exitCode === 0 }
  }

  Process {
    id: dependencyCheckProc
    onExited: function(exitCode) {
      var ready = Object.assign({}, root.dependencyReadyMap)
      var checked = Object.assign({}, root.dependencyCheckedMap)
      ready[root.dependencyCheckKind] = exitCode === 0
      checked[root.dependencyCheckKind] = true
      root.dependencyReadyMap = ready
      root.dependencyCheckedMap = checked
      root.runNextDependencyCheck()
    }
  }

  PwObjectTracker {
    objects: root.streamNodes
      .concat(root.defaultSource ? [root.defaultSource] : [])
      .concat(root.defaultSink ? [root.defaultSink] : [])
  }

  IpcHandler {
    target: "privacy-devices"
    function status(): string { return JSON.stringify(root.snapshot()) }
    function refresh(): string { root.refreshFallbacks(); return "ok" }
    function toggle(kind: string): string {
      if (!root.controllable(kind)) return "unsupported"
      root.toggleControl(kind)
      return "ok"
    }
  }

  Component.onCompleted: {
    root.refreshFallbacks()
    root.refreshMuteState()
    root.refreshScreenshot()
    root.refreshDependencies()
  }
}
