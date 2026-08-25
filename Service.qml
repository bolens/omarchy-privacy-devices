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
  property var activeSessions: []
  property var recentHistory: []
  property bool historyLoaded: false
  property bool historyConfigurationInitialized: false
  property var directObservations: []
  property bool directObserverRetiring: false
  property double directObserverLastSeen: 0
  property int directObserverRetryMilliseconds: 1000
  property bool fallbackObserverRetiring: false
  property double fallbackObserverLastSeen: 0
  property int fallbackObserverRetryMilliseconds: 1000
  property string requestedSettingsPage: "general"
  property int settingsRequestSerial: 0
  property var notificationQueue: []
  property var controlTransactions: ({})
  property var observerHealth: ({
    pipewire: {status: "healthy", source: "pipewire", code: "ok", reason: ""},
    "direct-device": {status: "healthy", source: "direct-device", code: "ok", reason: ""}
  })
  property double lastSessionRefreshAt: 0
  property double lastFallbackRefreshAt: 0
  property string operationalConfiguration: ""

  readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property bool pipewireAvailable: Pipewire.nodes !== null && Pipewire.nodes !== undefined
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
  readonly property var observedPipewireSessions: pipewireObservations()

  onObservedPipewireSessionsChanged: scheduleSessionRefresh()
  onLocationAppsChanged: scheduleSessionRefresh()
  onLocationActiveChanged: scheduleSessionRefresh()
  onRecordingAppsChanged: scheduleSessionRefresh()
  onRecordingActiveChanged: scheduleSessionRefresh()
  onScreenshotActiveChanged: scheduleSessionRefresh()
  onDirectObservationsChanged: scheduleSessionRefresh()

  function configure(next) {
    var historyWasEnabled = settings.historyEnabled === true
    var nextSettings = Model.sanitizeSettings(next)
    var nextOperationalConfiguration = Model.operationalSignature(nextSettings)
    var monitoringChanged = nextOperationalConfiguration !== operationalConfiguration
    settings = nextSettings
    locationTimer.interval = boundedSeconds(settings.locationPollSeconds, 15, 5, 300) * 1000
    if (settings.historyEnabled !== true && (!historyConfigurationInitialized || historyWasEnabled)) clearHistory()
    else loadHistory()
    historyConfigurationInitialized = true
    if (monitoringChanged) {
      operationalConfiguration = nextOperationalConfiguration
      refreshFallbacks()
      refreshDependencies()
      refreshDirectDevices()
      refreshFallbackObserver()
    }
  }

  function boundedSeconds(value, fallback, minimum, maximum) {
    var parsed = Number(value)
    if (!isFinite(parsed)) parsed = fallback
    return Math.max(minimum, Math.min(maximum, Math.round(parsed)))
  }

  function regexEscape(value) {
    return String(value || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
  }

  function fallbackObserverCommand() {
    var recording = recordingBackend() === "wf-recorder" ? "wf-recorder"
      : recordingBackend() === "custom" ? String(settings.recordingProcessName || "") : "gpu-screen-recorder"
    var screenshot = screenshotBackend() === "custom"
      ? "^(" + regexEscape(String(settings.screenshotProcessName || "")) + ")(\\s|$)"
      : "^(grim|slurp|satty|hyprpicker|hyprshot|flameshot)(\\s|$)"
    return [String(Qt.resolvedUrl("privacy-observe")).replace(/^file:\/\//, ""), "watch-fallbacks",
      "--heartbeat", String(boundedSeconds(settings.recordingPollSeconds, 2, 1, 60)), "--recording", recording, "--screenshot-pattern", screenshot]
  }

  function refreshFallbackObserver() {
    var needed = kindEnabled("screen-recording") || kindEnabled("screenshot")
    if (!needed) {
      fallbackObserverRetiring = true
      fallbackObserverProc.running = false
      recordingActive = false
      recordingApps = []
      screenshotActive = false
      return
    }
    var desired = fallbackObserverCommand()
    if (fallbackObserverProc.running) {
      if (JSON.stringify(fallbackObserverProc.command) === JSON.stringify(desired)) return
      fallbackObserverRetiring = true
      fallbackObserverProc.running = false
      Qt.callLater(refreshFallbackObserver)
      return
    }
    fallbackObserverRetiring = false
    fallbackObserverProc.command = desired
    fallbackObserverProc.running = true
  }

  function handleFallbackSnapshot(line) {
    try {
      var payload = JSON.parse(String(line || "{}"))
      if (payload.type !== "fallback-snapshot" || payload.version !== 1 || !payload.activities) return
      var recordings = Array.isArray(payload.activities["screen-recording"]) ? payload.activities["screen-recording"] : []
      var screenshots = Array.isArray(payload.activities.screenshot) ? payload.activities.screenshot : []
      recordingApps = recordings
      recordingActive = recordings.length > 0
      verifyControlTransaction("screen-recording", recordingActive, true)
      screenshotActive = screenshots.length > 0
      fallbackObserverLastSeen = Date.now()
      fallbackObserverRetryMilliseconds = 1000
      lastFallbackRefreshAt = fallbackObserverLastSeen
    } catch (error) {}
  }

  function enabledKinds() {
    return Model.arraySetting(settings.enabledKinds, Model.KINDS)
  }

  function kindEnabled(kind) {
    return enabledKinds().indexOf(kind) !== -1
  }

  function appsFor(kind) {
    return Model.applicationsForSessions(attributedSessionsFor(kind), kind, settings.deduplicateApps !== false)
  }

  function policies() {
    return {
      hiddenApps: Model.arraySetting(settings.hiddenApps, []),
      notificationSuppressedApps: Model.arraySetting(settings.notificationSuppressedApps, [])
    }
  }

  function sessionsFor(kind) {
    return activeSessions.filter(function(session) { return !kind || session.kind === kind })
  }

  function visibleSessionsFor(kind) {
    return Model.visibleSessions(sessionsFor(kind), policies())
  }

  function attributedSessionsFor(kind) {
    return Model.filterAttribution(visibleSessionsFor(kind), settings.showInferredAttribution !== false)
  }

  function active(kind) {
    if (!kindEnabled(kind)) return false
    return sessionsFor(kind).length > 0
  }

  function pipewireObservations() {
    var result = []
    for (var index = 0; index < streamNodes.length; index++) {
      var node = streamNodes[index]
      var kind = Model.classifyNode(node, settings)
      if (!kind) continue
      var props = Model.properties(node)
      result.push({
        kind: kind,
        application: Model.appName(node),
        device: String(props["node.target"] || props["device.description"] || props["node.description"] || "PipeWire device"),
        source: "pipewire",
        confidence: kind === "camera" || kind === "screen-share" ? "inferred" : "confirmed",
        detail: String(props["media.name"] || props["node.name"] || "PipeWire stream")
      })
    }
    return result
  }

  function fallbackObservations() {
    var result = []
    var index
    for (index = 0; index < locationApps.length; index++) result.push({kind: "location", application: locationApps[index], device: "GeoClue", source: "geoclue", confidence: "confirmed"})
    if (locationActive && !locationApps.length) result.push({kind: "location", application: "Unknown application", device: "GeoClue", source: "geoclue", confidence: "inferred"})
    for (index = 0; index < recordingApps.length; index++) result.push({kind: "screen-recording", application: recordingApps[index], device: "Desktop", source: "process-probe", confidence: "inferred"})
    if (screenshotActive) result.push({kind: "screenshot", application: "Screenshot tool", device: "Desktop", source: "process-probe", confidence: "inferred"})
    return result
  }

  function refreshSessions() {
    var observations = observedPipewireSessions.concat(fallbackObservations())
    if (settings.directDeviceMonitoring === true) observations = observations.concat(directObservations)
    var now = Date.now()
    if (!activeSessions.length && !observations.length) {
      lastSessionRefreshAt = now
      activityInitialized = true
      return
    }
    var transition = Model.reconcileSessions(activeSessions, observations, now)
    if (!Model.sessionsEquivalent(activeSessions, transition.active)) activeSessions = transition.active
    lastSessionRefreshAt = now
    handleSessionTransitions(transition)
    activityInitialized = true
  }

  function scheduleSessionRefresh() {
    sessionRefreshDebounce.restart()
  }

  function handleSessionTransitions(transition) {
    var notifyKinds = Model.arraySetting(settings.notificationKinds, ["microphone", "camera", "screen-share", "screen-recording", "location"])
    var stoppedForHistory = []
    var index
    if (activityInitialized && settings.notifyOnActivity !== false) {
      for (index = 0; index < transition.started.length; index++) {
        var started = transition.started[index]
        if (notifyKinds.indexOf(started.kind) !== -1 && Model.shouldNotifyForSession(started, policies()))
          enqueueActivityNotification("started", started)
      }
    }
    for (index = 0; index < transition.stopped.length; index++) {
      var stopped = transition.stopped[index]
      if (settings.historyEnabled === true) {
        recentHistory = Model.appendHistory(recentHistory, stopped, Date.now(), {maxEntries: 100, maxAgeMs: 7 * 24 * 60 * 60 * 1000})
        stoppedForHistory.push(stopped)
      }
      if (settings.notifyOnStop === true && notifyKinds.indexOf(stopped.kind) !== -1 && Model.shouldNotifyForSession(stopped, policies()))
        enqueueActivityNotification("stopped", stopped)
    }
    if (stoppedForHistory.length) Quickshell.execDetached([historyHelperPath(), "append", JSON.stringify(stoppedForHistory)])
  }

  function healthFor(kind) {
    var states = []
    if (kind === "microphone" || kind === "audio-output" || kind === "camera" || kind === "screen-share") states.push(pipewireAvailable
      ? {status: "healthy", source: "pipewire", code: "ok", reason: ""}
      : {status: "unavailable", source: "pipewire", code: "backend_unavailable", reason: "PipeWire service is unavailable"})
    if (settings.directDeviceMonitoring === true && (kind === "microphone" || kind === "camera")) states.push(observerHealth["direct-device"])
    if (kind === "location" && !dependenciesReady(kind)) states.push({status: "unavailable", source: "geoclue", code: "dependency_unavailable", reason: dependencyDescription(kind)})
    return Model.aggregateHealth(states.length ? states : [{status: "healthy", source: backendFor(kind), code: "ok", reason: ""}])
  }

  function monitoringDegraded() {
    var kinds = enabledKinds()
    for (var index = 0; index < kinds.length; index++) if (healthFor(kinds[index]).status !== "healthy") return true
    return false
  }

  function monitoringTelemetry() {
    var now = Date.now()
    return {
      pipewireReactive: pipewireAvailable,
      lastSessionRefreshAgeSeconds: lastSessionRefreshAt > 0 ? Math.max(0, Math.round((now - lastSessionRefreshAt) / 1000)) : -1,
      lastFallbackRefreshAgeSeconds: lastFallbackRefreshAt > 0 ? Math.max(0, Math.round((now - lastFallbackRefreshAt) / 1000)) : -1,
      fallbackObserverRunning: fallbackObserverProc.running,
      fallbackObserverHeartbeatAgeSeconds: fallbackObserverLastSeen > 0 ? Math.max(0, Math.round((now - fallbackObserverLastSeen) / 1000)) : -1,
      fallbackObserverRetryMilliseconds: fallbackObserverRetryMilliseconds,
      directDeviceEnabled: settings.directDeviceMonitoring === true,
      directObserverRunning: directDeviceProc.running,
      directHeartbeatAgeSeconds: directObserverLastSeen > 0 ? Math.max(0, Math.round((now - directObserverLastSeen) / 1000)) : -1,
      directObserverRetryMilliseconds: directObserverRetryMilliseconds
    }
  }

  function diagnostics(redact) {
    var rows = activeSessions.map(function(session) {
      return {
        kind: session.kind,
        application: redact ? "redacted" : session.application,
        device: redact ? "redacted" : session.device,
        source: session.source,
        confidence: session.confidence,
        durationMs: Math.max(0, Date.now() - Number(session.startedAt || Date.now()))
      }
    })
    var health = {}
    var kinds = enabledKinds()
    for (var index = 0; index < kinds.length; index++) health[kinds[index]] = healthFor(kinds[index])
    return {version: 1, redacted: redact === true, telemetry: monitoringTelemetry(), health: health, sessions: rows,
      probeExitCodes: lastProbeExitCodes, controlExitCodes: lastControlExitCodes, controlTransactions: controlTransactions}
  }

  function copyDiagnostics(redact) {
    Quickshell.execDetached([String(Qt.resolvedUrl("privacy-diagnostics")).replace(/^file:\/\//, ""), JSON.stringify(diagnostics(redact))])
  }

  function clearHistory() {
    recentHistory = []
    historyLoaded = settings.historyEnabled !== true
    Quickshell.execDetached([historyHelperPath(), "clear"])
  }

  function historyHelperPath() {
    return String(Qt.resolvedUrl("privacy-history")).replace(/^file:\/\//, "")
  }

  function loadHistory() {
    if (historyLoaded || historyLoadProc.running || settings.historyEnabled !== true) return
    historyLoadProc.command = [historyHelperPath(), "load"]
    historyLoadProc.running = true
  }

  function refreshDirectDevices() {
    if (settings.directDeviceMonitoring !== true) {
      directObserverRetiring = true
      directDeviceProc.running = false
      directObservations = []
      directObserverLastSeen = 0
      return
    }
    directObserverRetiring = false
    var desiredCommand = [
      String(Qt.resolvedUrl("privacy-observe")).replace(/^file:\/\//, ""),
      "watch", "--heartbeat", String(boundedSeconds(settings.directDevicePollSeconds, 5, 2, 60))
    ]
    if (directDeviceProc.running) {
      if (JSON.stringify(directDeviceProc.command) === JSON.stringify(desiredCommand)) return
      directObserverRetiring = true
      directDeviceProc.running = false
      Qt.callLater(refreshDirectDevices)
      return
    }
    directDeviceProc.command = desiredCommand
    directDeviceProc.running = true
  }

  function handleDirectDeviceSnapshot(text) {
    try {
      var result = JSON.parse(String(text || "{}"))
      if (result.type !== "snapshot") return
      directObservations = Array.isArray(result.observations) ? result.observations : []
      directObserverLastSeen = Date.now()
      directObserverRetryMilliseconds = 1000
      var next = Object.assign({}, observerHealth)
      next["direct-device"] = result.healthy === false
        ? {status: "degraded", source: "direct-device", code: String(result.code || "observer_unhealthy"), reason: String(result.error || "observer reported unhealthy")}
        : {status: "healthy", source: "direct-device", code: "ok", reason: ""}
      observerHealth = next
    } catch (error) {
      var invalid = Object.assign({}, observerHealth)
      invalid["direct-device"] = {status: "degraded", source: "direct-device", code: "invalid_payload", reason: "invalid observer response"}
      observerHealth = invalid
    }
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
    var transaction = controlTransactions[kind]
    return !!transaction && ["requested", "applying", "verifying"].indexOf(transaction.status) >= 0
  }

  function beginControlTransaction(kind, expectedEnabled) {
    var next = Object.assign({}, controlTransactions)
    next[kind] = Model.controlTransactionTransition(null, {type: "begin", expectedEnabled: expectedEnabled}, Date.now())
    controlTransactions = next
  }

  function beginControlVerification(kind, exitCode) {
    var next = Object.assign({}, controlTransactions)
    var current = next[kind]
    next[kind] = Model.controlTransactionTransition(current, {type: "command", exitCode: exitCode}, Date.now())
    controlTransactions = next
    if (next[kind] && next[kind].status === "failed") notifyControlResult(kind, exitCode)
  }

  function transitionControlTransaction(kind, event, now) {
    var next = Object.assign({}, controlTransactions)
    var current = next[kind]
    var updated = Model.controlTransactionTransition(current, event, now === undefined ? Date.now() : now)
    if (updated === current) return
    next[kind] = updated
    controlTransactions = next
    if (updated && (updated.status === "succeeded" || updated.status === "failed"))
      notifyControlResult(kind, updated.status === "succeeded" ? 0 : updated.exitCode)
  }

  function verifyControlTransaction(kind, observedEnabled, probeValid) {
    transitionControlTransaction(kind, {type: "observation", enabled: observedEnabled, valid: probeValid})
  }

  function beginExternalControl(kind, expectedEnabled) {
    beginControlTransaction(kind, expectedEnabled)
    beginControlVerification(kind, 0)
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
      beginControlTransaction(kind, microphoneMuted)
      microphoneControlProc.command = audioToggleCommand(kind)
      microphoneControlProc.running = true
    }
    else if (kind === "audio-output" && !outputControlProc.running) {
      beginControlTransaction(kind, outputMuted)
      outputControlProc.command = audioToggleCommand(kind)
      outputControlProc.running = true
    }
    else if ((kind === "camera" || kind === "location" || kind === "screen-share") && !privacyControlProc.running) {
      beginControlTransaction(kind, !controlEnabled(kind))
      privacyControlKind = kind
      privacyStateQueue = []
      if (privacyStateProc.running) privacyStateProc.running = false
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
      controlTransaction: controlTransactions[kind] || null,
      health: healthFor(kind),
      sessions: sessionsFor(kind),
      probeExitCode: lastProbeExitCodes[kind] === undefined ? -1 : lastProbeExitCodes[kind],
      controlExitCode: lastControlExitCodes[kind] === undefined ? -1 : lastControlExitCodes[kind]
    }
  }

  function notify(title, body) {
    Quickshell.execDetached([
      "omarchy", "notification", "send",
      "--app-name", "Privacy Devices",
      "--urgency", "normal",
      Model.autoTextSafe(title), Model.autoTextSafe(body)
    ])
  }

  function enqueueActivityNotification(phase, session) {
    if (notificationQueue.length && notificationQueue[0].phase !== phase) flushActivityNotifications()
    notificationQueue = notificationQueue.concat([{phase: phase, kind: session.kind, application: session.application}])
    notificationFlush.restart()
  }

  function flushActivityNotifications() {
    var grouped = Model.coalesceNotificationEvents(notificationQueue)
    notificationQueue = []
    if (grouped.count > 0) notify(grouped.title, grouped.body)
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
        dependenciesReady: dependenciesReady(kind),
        health: healthFor(kind),
        sessions: sessionsFor(kind)
      })
    }
    return result
  }

  function refreshFallbacks() {
    lastFallbackRefreshAt = Date.now()
    refreshPreventativeControls()
    if (kindEnabled("location")) refreshLocation()
    else { locationActive = false; locationApps = [] }
    refreshFallbackObserver()
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
    id: preventativeControlTimer
    interval: 15000
    repeat: true
    running: true
    onTriggered: root.refreshPreventativeControls()
  }

  Timer {
    id: sessionRefreshDebounce
    interval: 150
    repeat: false
    onTriggered: root.refreshSessions()
  }

  // Reactive PipeWire and observer updates do the normal work. This slow pass
  // is only a safety net for backends that mutate without emitting a QML signal.
  Timer {
    interval: 15000
    repeat: true
    running: true
    onTriggered: root.refreshSessions()
  }

  Timer {
    id: directObserverRetry
    interval: root.directObserverRetryMilliseconds
    repeat: false
    onTriggered: root.refreshDirectDevices()
  }

  Timer {
    interval: 5000
    repeat: true
    running: root.settings.directDeviceMonitoring === true
    onTriggered: {
      var heartbeat = root.boundedSeconds(root.settings.directDevicePollSeconds, 5, 2, 60) * 1000
      if (root.directObserverLastSeen > 0 && Date.now() - root.directObserverLastSeen <= Math.max(15000, heartbeat * 3)) return
      var stale = Object.assign({}, root.observerHealth)
      stale["direct-device"] = {status: "degraded", source: "direct-device", code: "heartbeat_stale", reason: "observer heartbeat is stale"}
      root.observerHealth = stale
    }
  }

  Timer {
    interval: 3000
    repeat: true
    running: true
    onTriggered: root.refreshMuteState()
  }

  Timer { id: fallbackObserverRetry; interval: root.fallbackObserverRetryMilliseconds; onTriggered: root.refreshFallbackObserver() }
  Timer { id: notificationFlush; interval: 400; onTriggered: root.flushActivityNotifications() }

  Timer {
    interval: 500
    repeat: true
    running: {
      for (var kind in root.controlTransactions) if (root.controlTransactions[kind].status === "verifying") return true
      return false
    }
    onTriggered: {
      var now = Date.now()
      for (var kind in root.controlTransactions) {
        var transaction = root.controlTransactions[kind]
        if (transaction.status === "verifying" && now >= transaction.deadline)
          root.transitionControlTransaction(kind, {type: "timeout"}, now)
      }
    }
  }

  Timer {
    interval: 300000
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
    onExited: function(exitCode) { root.setResult("probe", "microphone", exitCode); root.fallbackMicrophoneMuted = Model.mutedFromExitCode(exitCode, root.fallbackMicrophoneMuted); root.verifyControlTransaction("microphone", !root.fallbackMicrophoneMuted, exitCode === 10 || exitCode === 11) }
  }

  Process {
    id: outputStateProc
    onExited: function(exitCode) { root.setResult("probe", "audio-output", exitCode); root.fallbackOutputMuted = Model.mutedFromExitCode(exitCode, root.fallbackOutputMuted); root.verifyControlTransaction("audio-output", !root.fallbackOutputMuted, exitCode === 10 || exitCode === 11) }
  }

  Process {
    id: microphoneControlProc
    onExited: function(exitCode) { root.setResult("control", "microphone", exitCode); root.beginControlVerification("microphone", exitCode); root.refreshMuteState() }
  }

  Process {
    id: outputControlProc
    onExited: function(exitCode) { root.setResult("control", "audio-output", exitCode); root.beginControlVerification("audio-output", exitCode); root.refreshMuteState() }
  }

  Process {
    id: privacyStateProc
    onExited: function(exitCode) {
      root.setResult("probe", root.privacyStateKind, exitCode)
      if (Model.shouldAcceptControlProbe(root.privacyStateKind, root.privacyControlKind)) {
        root.setAllowed(root.privacyStateKind, Model.mutedFromExitCode(exitCode, root.controlEnabled(root.privacyStateKind)))
        root.verifyControlTransaction(root.privacyStateKind, root.controlEnabled(root.privacyStateKind), exitCode === 10 || exitCode === 11)
      }
      root.runNextPrivacyState()
    }
  }

  Process {
    id: privacyControlProc
    onExited: function(exitCode) {
      var kind = root.privacyControlKind
      root.setResult("control", kind, exitCode)
      root.beginControlVerification(kind, exitCode)
      root.privacyControlKind = ""
      root.refreshPreventativeControls()
    }
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

  Process {
    id: directDeviceProc
    onExited: function(exitCode) {
      if (root.directObserverRetiring || root.settings.directDeviceMonitoring !== true) return
      var next = Object.assign({}, root.observerHealth)
      next["direct-device"] = {status: "degraded", source: "direct-device", code: "observer_exited", reason: "observer exited with code " + exitCode}
      root.observerHealth = next
      directObserverRetry.interval = root.directObserverRetryMilliseconds
      root.directObserverRetryMilliseconds = Math.min(root.directObserverRetryMilliseconds * 2, 60000)
      directObserverRetry.restart()
    }
    stdout: SplitParser { onRead: function(line) { root.handleDirectDeviceSnapshot(line) } }
  }

  Process {
    id: fallbackObserverProc
    onExited: function(exitCode) {
      if (root.fallbackObserverRetiring || (!root.kindEnabled("screen-recording") && !root.kindEnabled("screenshot"))) return
      root.fallbackObserverRetryMilliseconds = Math.min(root.fallbackObserverRetryMilliseconds * 2, 60000)
      fallbackObserverRetry.restart()
    }
    stdout: SplitParser { onRead: function(line) { root.handleFallbackSnapshot(line) } }
  }

  Process {
    id: historyLoadProc
    onExited: function(exitCode) { root.historyLoaded = exitCode === 0 }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: function(text) {
        try {
          var value = JSON.parse(String(text || "[]"))
          root.recentHistory = Array.isArray(value) ? value : []
        } catch (error) {
          root.recentHistory = []
        }
      }
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
    function sessions(): string { return JSON.stringify(root.activeSessions) }
    function health(): string {
      var result = {}
      var kinds = root.enabledKinds()
      for (var index = 0; index < kinds.length; index++) result[kinds[index]] = root.healthFor(kinds[index])
      return JSON.stringify(result)
    }
    function history(): string { return JSON.stringify(root.recentHistory) }
    function diagnostics(mode: string): string { return JSON.stringify(root.diagnostics(mode !== "unsafe")) }
    function clearHistory(): string { root.clearHistory(); return "ok" }
    function rescan(): string { root.refreshFallbacks(); root.refreshDirectDevices(); root.refreshSessions(); return "ok" }
    function refresh(): string { root.refreshFallbacks(); return "ok" }
    function toggle(kind: string): string {
      if (!root.controllable(kind)) return "unsupported"
      root.toggleControl(kind)
      return "ok"
    }
  }

  IpcHandler {
    target: "privacy-devices-settings"
    function open(page: string): string {
      root.requestedSettingsPage = page || "general"
      root.settingsRequestSerial++
      return root.shell && typeof root.shell.summon === "function" && root.shell.summon("io.github.bolens.privacy-devices", "") ? root.requestedSettingsPage : "unavailable"
    }
  }

  Component.onCompleted: {
    root.refreshFallbacks()
    root.refreshMuteState()
    root.refreshDependencies()
    root.refreshDirectDevices()
    root.refreshFallbackObserver()
    root.refreshSessions()
  }
}
