const fs = require("fs")
const assert = require("node:assert/strict")
const vm = require("vm")
const source = fs.readFileSync(require("path").join(__dirname, "..", "Model.js"), "utf8").replace(/^\.pragma library\s*/, "")
const context = {}
vm.createContext(context)
vm.runInContext(source, context)

function node(mediaClass, name, extra = {}) {
  return {
    ready: true,
    isStream: true,
    properties: Object.assign({"media.class": mediaClass, "application.name": name}, extra)
  }
}

const defaults = {excludedApps: ["cava"], cameraKeywords: ["camera", "v4l2"], screenShareKeywords: ["portal", "screencast"]}
if (context.privacyVisualState({kind: "camera", active: false, controllable: true, controlEnabled: false, health: {status: "healthy"}}) !== "disabled") throw new Error("blocked camera visual state")
if (context.privacyVisualState({kind: "camera", active: true, controllable: true, controlEnabled: false, health: {status: "healthy"}}) !== "blocked-active") throw new Error("blocked active request visual state")
if (context.privacyVisualState({kind: "location", active: false, controllable: true, controlEnabled: true, health: {status: "healthy"}}) !== "idle") throw new Error("available idle visual state")
if (context.privacyVisualState({kind: "screen-recording", active: false, controllable: true, controlEnabled: false, health: {status: "healthy"}}) !== "idle") throw new Error("stopped recording is idle, not disabled")
if (context.privacyVisualState({kind: "camera", active: true, controllable: true, controlEnabled: true, health: {status: "healthy"}}) !== "active") throw new Error("active visual state")
if (context.privacyVisualState({kind: "camera", active: false, controllable: true, controlEnabled: false, health: {status: "degraded"}}) !== "unavailable") throw new Error("health failure takes visual precedence")
if (context.privacyVisualState({kind: "camera", active: false, pending: true, controlEnabled: false, health: {status: "degraded"}}) !== "pending") throw new Error("pending visual state takes precedence")
if (context.privacyStateLabel({kind: "camera", pending: true}) !== "VERIFYING") throw new Error("pending state label")
if (context.privacyStateMarker({kind: "camera", controlEnabled: false}) !== "⊘") throw new Error("disabled state marker")
if (context.privacyStateMarker({kind: "camera", controlEnabled: false}, "letters", true) !== "X") throw new Error("letter status marker")
if (context.privacyStateMarker({kind: "camera", controlEnabled: false}, "off", true) !== "" || context.privacyStateMarker({kind: "camera", controlEnabled: false}, "symbols", false) !== "") throw new Error("status marker suppression")
if (context.privacySessionCount({sessions: [{}, {}]}) !== 2 || context.privacySessionCount({sessions: [{}]}) !== 0) throw new Error("multi-session count badge")
if (context.privacySessionCount({sessions: [{}, {}]}, false) !== 0) throw new Error("multi-session count suppression")
const sanitized = context.sanitizeSettings({showIdle: "yes", popupMaxHeight: 9999, enabledKinds: ["camera", "camera", "bogus"], unknown: "discard"})
if (JSON.stringify(sanitized) !== JSON.stringify({showIdle: true, popupMaxHeight: 900, enabledKinds: ["camera"], _privacySettingsVersion: 1})) throw new Error("settings sanitizer")
const arrayLikeKinds = {0: "camera", 1: "location", length: 2}
assert.deepEqual(JSON.parse(JSON.stringify(context.arraySetting(arrayLikeKinds, context.KINDS))), ["camera", "location"])
assert.deepEqual(JSON.parse(JSON.stringify(context.sanitizeSettings({enabledKinds: arrayLikeKinds}).enabledKinds)), ["camera", "location"])
const hardenedSettings = context.sanitizeSettings({
  idleOpacity: -4,
  displayMode: "invalid",
  notificationSuppressedApps: [" Firefox ", "firefox", "", 42],
  itemIdleOpacity: {camera: 9, bogus: 0.2},
  itemIdleVisibility: {camera: "yes", microphone: true},
  icons: {camera: " 󰄀\nmoretext ", microphone: "\n\t", bogus: "ignored"},
  itemLabels: {camera: "  Camera\nLabel  ", microphone: "\n\t", bogus: "ignored"},
  itemColorRoles: {camera: {active: "accent", blocked: "urgent", inactive: "danger", unexpected: "danger"}, bogus: {active: "urgent"}},
  itemStatusMarkerVisibility: {camera: false, bogus: true},
  disabledOpacity: 0,
  activeOpacity: 4,
  blockedActiveOpacity: 0,
  statusMarkerMode: "invalid",
  statePillStyle: "invalid",
  popupDensity: "invalid",
  showStatePills: "yes",
})
if (hardenedSettings.idleOpacity !== 0.1 || hardenedSettings.displayMode !== "icons") throw new Error("numeric and enum settings bounds")
if (JSON.stringify(hardenedSettings.notificationSuppressedApps) !== JSON.stringify(["Firefox"])) throw new Error("settings string-list normalization")
if (JSON.stringify(hardenedSettings.itemIdleOpacity) !== JSON.stringify({camera: 1})) throw new Error("per-item opacity bounds")
if (JSON.stringify(hardenedSettings.itemIdleVisibility) !== JSON.stringify({camera: false, microphone: true})) throw new Error("per-item boolean normalization")
if (hardenedSettings.icons.camera !== "󰄀moretex" || hardenedSettings.icons.microphone !== undefined || hardenedSettings.icons.bogus !== undefined) throw new Error("per-item icon sanitation")
if (hardenedSettings.itemLabels.camera !== "CameraLabel" || hardenedSettings.itemLabels.microphone !== undefined || hardenedSettings.itemLabels.bogus !== undefined) throw new Error("per-item label sanitation")
if (context.sanitizeSettings({itemLabels: {camera: "C".repeat(200)}}).itemLabels.camera.length !== 128) throw new Error("per-item label bound")
if (JSON.stringify(hardenedSettings.itemColorRoles) !== JSON.stringify({camera: {active: "accent", blocked: "urgent"}})) throw new Error("per-item role allowlist")
if (JSON.stringify(context.sanitizeSettings({itemColorRoles: {camera: {active: "danger"}}}).itemColorRoles) !== "{}") throw new Error("empty per-item role overrides")
if (JSON.stringify(hardenedSettings.itemStatusMarkerVisibility) !== JSON.stringify({camera: false})) throw new Error("per-item marker visibility allowlist")

assert.equal(context.itemOverrideMode({}, "itemIdleVisibility", "camera"), "inherit")
assert.equal(context.itemOverrideMode({itemIdleVisibility: {camera: true}}, "itemIdleVisibility", "camera"), "show")
assert.equal(context.itemOverrideMode({itemIdleVisibility: {camera: false}}, "itemIdleVisibility", "camera"), "hide")
assert.equal(context.hasItemOverride({itemColorRoles: {camera: {active: "accent"}}}, "itemColorRoles", "camera", "active"), true)
assert.equal(context.hasItemOverride({itemColorRoles: {camera: {active: "accent"}}}, "itemColorRoles", "camera", "inactive"), false)

assert.deepEqual(JSON.parse(JSON.stringify(context.deviceBackendValidation("screenshot", {
  screenshotBackend: "custom", screenshotCustomCommand: "", screenshotProcessName: "grim"
}))), {valid: false, message: "Enter a screenshot command."})
assert.deepEqual(JSON.parse(JSON.stringify(context.deviceBackendValidation("screen-recording", {
  recordingBackend: "custom", recordingProcessName: "recorder", recordingCustomStartCommand: "start", recordingCustomStopCommand: ""
}))), {valid: false, message: "Enter start and stop commands."})
assert.equal(context.deviceBackendValidation("screen-recording", {
  recordingBackend: "custom", recordingProcessName: "recorder", recordingCustomStartCommand: "start", recordingCustomStopCommand: "stop"
}).valid, true)
if (hardenedSettings.disabledOpacity !== 0.25 || hardenedSettings.activeOpacity !== 1 || hardenedSettings.blockedActiveOpacity !== 0.1) throw new Error("state opacity bounds")
if (hardenedSettings.statusMarkerMode !== "off" || hardenedSettings.statePillStyle !== "filled" || hardenedSettings.popupDensity !== "comfortable") throw new Error("visual enum defaults")
if (hardenedSettings.showStatePills !== true) throw new Error("visual boolean normalization")
if (context.settingsPage("monitoring") !== "monitoring" || context.settingsPage("unexpected") !== "general") throw new Error("settings page allowlist")
if (context.settingsPage("appearance") !== "appearance") throw new Error("appearance settings page allowlist")
assert.deepEqual(JSON.parse(JSON.stringify(context.privacyAction("open-activity", "camera"))), {name: "open-activity", argument: "camera"})
assert.deepEqual(JSON.parse(JSON.stringify(context.privacyAction("open-history", ""))), {name: "open-history", argument: ""})
assert.equal(context.privacyAction("open-activity", "../../camera"), null, "action arguments must be allowlisted device kinds")
assert.equal(context.privacyAction("run", "rm -rf"), null, "unknown quick actions must be rejected")
if (context.sanitizeSettings({recordingProcessName: "x".repeat(300)}).recordingProcessName.length !== 256) throw new Error("process-name bound")
if (context.sanitizeSettings({recordingProcessName: "  recorder\nname  "}).recordingProcessName !== "recordername") throw new Error("process-name plain-text sanitation")
const deviceSettings = context.sanitizeSettings({
  hiddenDevices: [" Virtual Source ", "virtual source"],
  notificationSuppressedDevices: ["Conference Mic"],
  deviceLabels: {"alsa_input.usb": " Desk microphone ", "__proto__": "unsafe", "": "empty"}
})
assert.deepEqual(Array.from(deviceSettings.hiddenDevices), ["Virtual Source"])
assert.deepEqual(Array.from(deviceSettings.notificationSuppressedDevices), ["Conference Mic"])
assert.deepEqual(JSON.parse(JSON.stringify(deviceSettings.deviceLabels)), {"alsa_input.usb": "Desk microphone"})

const classificationSettings = {
  excludedApps: ["Ignored"],
  cameraKeywords: ["WEBCAM"],
  screenShareKeywords: ["PORTAL"]
}
const classificationPolicy = context.classificationPolicy(classificationSettings)
assert.deepEqual(JSON.parse(JSON.stringify(classificationPolicy)), {
  exclusions: ["ignored"], cameras: ["webcam"], shares: ["portal"]
})
const cameraNode = {isStream: true, ready: true, properties: {
  "application.name": "Calls", "media.class": "Video/Source", "media.name": "USB Webcam"
}}
assert.equal(context.classifyNode(cameraNode, classificationSettings, classificationPolicy), "camera",
  "prepared classification policy preserves keyword matching")
const barAppearance = context.sanitizeSettings({barIconScale: 9, barItemSpacing: -4, barItemPadding: "bad", barMarkerPosition: "sideways", showBarSessionCounts: "yes"})
if (barAppearance.barIconScale !== 1.5 || barAppearance.barItemSpacing !== 0 || barAppearance.barItemPadding !== 5) throw new Error("bar appearance numeric bounds")
if (barAppearance.barMarkerPosition !== "after" || barAppearance.showBarSessionCounts !== true) throw new Error("bar appearance enum and boolean normalization")
const markerVisibility = context.sanitizeSettings({showBarActiveMarker: false, showBarDisabledMarker: 0, showBarPendingMarker: null, showBarDegradedMarker: "no"})
if (markerVisibility.showBarActiveMarker !== false || markerVisibility.showBarDisabledMarker !== true || markerVisibility.showBarPendingMarker !== true || markerVisibility.showBarDegradedMarker !== true) throw new Error("bar status marker boolean normalization")
const customMarkers = context.sanitizeSettings({statusMarkerMode: "custom", barActiveMarkerIcon: " 󰄬 ", barDisabledMarkerIcon: "bad\nvalue", barPendingMarkerIcon: 42, barDegradedMarkerIcon: "123456789"})
if (customMarkers.statusMarkerMode !== "custom" || customMarkers.barActiveMarkerIcon !== "󰄬" || customMarkers.barDisabledMarkerIcon !== "badvalue" || customMarkers.barPendingMarkerIcon !== "…" || customMarkers.barDegradedMarkerIcon !== "12345678") throw new Error("custom marker sanitation")
if (context.privacyStateMarker({active: true}, "custom", true, {active: "@"}) !== "@") throw new Error("custom active marker")
if (context.classifyNode(node("Stream/Input/Audio", "Firefox"), defaults) !== "microphone") throw new Error("microphone classification")
if (context.classifyNode(node("Stream/Output/Audio", "Firefox"), defaults) !== "audio-output") throw new Error("audio output classification")
if (context.classifyNode(node("Stream/Input/Video", "Firefox", {"media.name":"Integrated Camera"}), defaults) !== "camera") throw new Error("camera classification")
if (context.classifyNode(node("Stream/Input/Video", "Firefox", {"pipewire.access.portal":"true"}), defaults) !== "screen-share") throw new Error("screen-share classification")
if (context.classifyNode(node("Stream/Input/Audio", "cava"), defaults) !== "") throw new Error("exclusion")
if (JSON.stringify(context.unique(["Firefox", "firefox", "OBS"])) !== JSON.stringify(["Firefox", "OBS"])) throw new Error("deduplication")
if (!context.volumeMuted("Volume: 1.00 [MUTED]\n")) throw new Error("muted volume parsing")
if (context.volumeMuted("Volume: 1.00\n")) throw new Error("unmuted volume parsing")
if (!context.volumeMuted("Mute: yes\n")) throw new Error("PulseAudio muted parsing")
if (context.volumeMuted("Mute: no\n")) throw new Error("PulseAudio unmuted parsing")
if (context.volumeMuted("")) throw new Error("empty volume parsing")
if (!context.hasVolumeState("Mute: no\n")) throw new Error("PulseAudio state recognition")
if (!context.hasVolumeState("Volume: 1.00\n")) throw new Error("PipeWire state recognition")
if (context.hasVolumeState("")) throw new Error("empty state recognition")
if (!context.mutedFromExitCode(10, false)) throw new Error("muted exit state")
if (context.mutedFromExitCode(11, true)) throw new Error("unmuted exit state")
if (!context.mutedFromExitCode(12, true)) throw new Error("failed probe preserves state")
if (context.shouldAcceptControlProbe("camera", "camera")) throw new Error("pending probe rejection")
if (!context.shouldAcceptControlProbe("location", "camera")) throw new Error("unrelated probe acceptance")
const stableSession = {id: "microphone|firefox|usb mic|pipewire", kind: "microphone", application: "Firefox", device: "USB mic", source: "pipewire", confidence: "confirmed", detail: "capture", startedAt: 10, lastSeenAt: 20}
const refreshedSession = Object.assign({}, stableSession, {lastSeenAt: 30, durationMs: 20})
if (!context.sessionsEquivalent([stableSession], [refreshedSession])) throw new Error("volatile timestamps should not churn session consumers")
if (context.sessionsEquivalent([stableSession], [Object.assign({}, refreshedSession, {detail: "new route"})])) throw new Error("meaningful session changes must propagate")
const baseConfig = {enabledKinds: ["microphone"], locationBackend: "geoclue", directDeviceMonitoring: false}
const cosmeticConfig = Object.assign({}, baseConfig, {displayMode: "active-only", popupMaxHeight: 700})
if (context.operationalSignature(baseConfig) !== context.operationalSignature(cosmeticConfig)) throw new Error("cosmetic settings must not rerun operational probes")
if (context.operationalSignature(baseConfig) === context.operationalSignature(Object.assign({}, baseConfig, {directDeviceMonitoring: true}))) throw new Error("monitoring changes must refresh operational probes")
if (context.operationalSignature(baseConfig) === context.operationalSignature(Object.assign({}, baseConfig, {directDevicePollSeconds: 9}))) throw new Error("observer heartbeat changes must restart the observer")
if (context.operationalSignature(baseConfig) === context.operationalSignature(Object.assign({}, baseConfig, {audioControlBackend: "wpctl"}))) throw new Error("audio backend changes must refresh dependencies")
if (context.operationalSignature(baseConfig) === context.operationalSignature(Object.assign({}, baseConfig, {recordingPollSeconds: 9}))) throw new Error("fallback heartbeat changes must restart the observer")
const degraded = context.aggregateHealth([{status: "degraded", source: "watcher", code: "heartbeat_stale", reason: "late"}])
if (degraded.codes[0] !== "heartbeat_stale") throw new Error("stable health codes must survive aggregation")
const hostileText = '<img src="https://attacker.invalid/pixel"> & camera'
const safeText = context.autoTextSafe(hostileText)
if (/[<>&]/.test(safeText)) throw new Error("shared AutoText metacharacters remain")
if (safeText !== '＜img src="https://attacker.invalid/pixel"＞ ＆ camera') throw new Error("shared AutoText sanitization")
if (context.boundedPlainText("safe\u202eevil\u2066\ntext", 32) !== "safeeviltext") throw new Error("plain-text direction and control sanitation")
if (context.sanitizeSettings({hiddenApps: [" Browser\u202e ", "\n"]}).hiddenApps.join() !== "Browser") throw new Error("settings list plain-text sanitation")
if (!context.historyLoadAccepted(4, 4, true)) throw new Error("current enabled history load accepted")
if (context.historyLoadAccepted(3, 4, true)) throw new Error("stale history load rejected")
if (context.historyLoadAccepted(4, 4, false)) throw new Error("disabled history load rejected")
const historyRows = [
  {kind: "camera", application: "Calls", confidence: "confirmed", endedAt: 9000, durationMs: 500},
  {kind: "microphone", application: "Browser", confidence: "inferred", endedAt: 8000, durationMs: 1500},
  {kind: "camera", application: "Browser", confidence: "confirmed", endedAt: 7000, durationMs: 1000}
]
assert.deepEqual(Array.from(context.filterAndSortHistory(historyRows, {kind: "camera", sort: "duration"}), row => row.durationMs), [1000, 500])
assert.deepEqual(Array.from(context.filterAndSortHistory(historyRows, {confidence: "inferred"}), row => row.kind), ["microphone"])
assert.deepEqual(Array.from(context.filterAndSortHistory(historyRows, {query: "browser", sort: "application"}), row => row.kind), ["microphone", "camera"])
const trend = context.historyTrend(historyRows, 10000, 4000, 4)
assert.equal(trend.total, 3)
assert.equal(trend.maximum, 1)
assert.deepEqual(Array.from(trend.buckets, row => row.count), [0, 1, 1, 1])
const modes = context.sanitizePrivacyModes([
  {name: " Meeting ", controls: {microphone: true, camera: false, screenshot: true}},
  {name: "meeting", controls: {camera: true}},
  {name: "Travel\nmode", controls: {location: false, "audio-output": "no"}},
  {name: "Empty", controls: {}}
])
assert.deepEqual(JSON.parse(JSON.stringify(modes)), [
  {name: "Meeting", controls: {microphone: true, camera: false}},
  {name: "Travelmode", controls: {location: false}}
])
const inventoryChanges = context.deviceInventoryChanges("microphone",
  [{id:"old",label:"Old mic"},{id:"same",label:"Before"}],
  [{id:"new",label:"New mic"},{id:"same",label:"After"}], 1234)
assert.deepEqual(Array.from(inventoryChanges, row => row.change), ["appeared", "renamed", "disappeared"])
assert.equal(inventoryChanges[0].at, 1234)
console.log("model tests passed")
