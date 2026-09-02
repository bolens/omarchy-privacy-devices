pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import "Model.js" as Model

Item {
  id: controller
  required property var host

  property string helperOverride: ""
  property var directObservations: []
  property bool directRetiring: false
  property bool directOwned: false
  property bool directRestartPending: false
  property double directLastSeen: 0
  property double directStartedAt: 0
  property int directRetryMilliseconds: 1000
  property bool fallbackRetiring: false
  property bool fallbackOwned: false
  property bool fallbackRestartPending: false
  property double fallbackLastSeen: 0
  property double fallbackStartedAt: 0
  property int fallbackRetryMilliseconds: 1000
  property bool recordingActive: false
  property var recordingApps: []
  property bool screenshotActive: false
  property double lastFallbackRefreshAt: 0

  readonly property bool directRunning: directProcess.running
  readonly property bool fallbackRunning: fallbackProcess.running
  readonly property bool directRetryRunning: directWatchdog.running
  readonly property bool fallbackRetryRunning: fallbackWatchdog.running
  readonly property var directActiveCommand: directProcess.command
  readonly property var fallbackActiveCommand: fallbackProcess.command

  function helperPath() {
    return helperOverride || String(Qt.resolvedUrl("privacy-observe")).replace(/^file:\/\//, "")
  }

  function discardSessions(source) {
    var result = Model.invalidateObserverSessions(host.activeSessions, source, host.suppressedObserverStarts)
    if (!result.changed) return
    host.activeSessions = result.active
    host.suppressedObserverStarts = result.suppressedSources
  }

  function clearDirect() {
    discardSessions("direct-device")
    if (directObservations.length) directObservations = []
    if (directLastSeen !== 0) directLastSeen = 0
  }

  function clearFallback() {
    discardSessions("process-probe")
    if (recordingApps.length) recordingApps = []
    if (recordingActive) recordingActive = false
    if (screenshotActive) screenshotActive = false
    if (fallbackLastSeen !== 0) fallbackLastSeen = 0
  }

  function fallbackCommand() {
    var recording = host.recordingBackend() === "wf-recorder" ? "wf-recorder"
      : host.recordingBackend() === "custom" ? String(host.settings.recordingProcessName || "") : "gpu-screen-recorder"
    var screenshot = host.screenshotBackend() === "custom"
      ? "^(" + host.regexEscape(String(host.settings.screenshotProcessName || "")) + ")(\\s|$)"
      : "^(grim|slurp|satty|hyprpicker|hyprshot|flameshot)(\\s|$)"
    return [helperPath(), "watch-fallbacks", "--heartbeat",
      String(host.boundedSeconds(host.settings.recordingPollSeconds, 2, 1, 60)),
      "--recording", recording, "--screenshot-pattern", screenshot]
  }

  function refreshFallback() {
    var needed = host.kindEnabled("screen-recording") || host.kindEnabled("screenshot")
    if (!needed) {
      fallbackRestartPending = false
      fallbackRetiring = fallbackOwned && fallbackProcess.running
      fallbackWatchdog.stop()
      fallbackProcess.running = false
      if (!fallbackRetiring) fallbackOwned = false
      clearFallback()
      fallbackStartedAt = 0
      fallbackRetryMilliseconds = 1000
      host.setObserverHealth("fallback-observer", "healthy", "ok", "")
      return
    }
    if (fallbackRetiring) { fallbackRestartPending = true; return }
    var desired = fallbackCommand()
    if (fallbackOwned) {
      if (!fallbackProcess.running) { fallbackProcess.command = desired; fallbackStartedAt = Date.now(); return }
      if (JSON.stringify(fallbackProcess.command) === JSON.stringify(desired)) return
      fallbackRestartPending = true
      fallbackRetiring = true
      fallbackProcess.running = false
      return
    }
    fallbackRestartPending = false
    fallbackRetiring = false
    fallbackWatchdog.stop()
    fallbackProcess.command = desired
    fallbackStartedAt = Date.now()
    fallbackOwned = true
    fallbackProcess.running = true
  }

  function acceptFallback(line) {
    if (fallbackRetiring || (!host.kindEnabled("screen-recording") && !host.kindEnabled("screenshot"))) return
    try {
      var payload = JSON.parse(String(line || "{}"))
      if (payload.type !== "fallback-snapshot" || payload.version !== 1 || !payload.activities)
        throw new Error("invalid fallback payload")
      var recordings = Array.isArray(payload.activities["screen-recording"]) ? payload.activities["screen-recording"] : []
      var screenshots = Array.isArray(payload.activities.screenshot) ? payload.activities.screenshot : []
      recordingApps = recordings
      recordingActive = recordings.length > 0
      host.verifyControlTransaction("screen-recording", recordingActive, true)
      screenshotActive = screenshots.length > 0
      fallbackLastSeen = Date.now()
      fallbackRetryMilliseconds = 1000
      lastFallbackRefreshAt = fallbackLastSeen
      host.setObserverHealth("fallback-observer", "healthy", "ok", "")
    } catch (error) {
      clearFallback()
      host.setObserverHealth("fallback-observer", "degraded", "invalid_payload", "invalid observer response")
    }
  }

  function refreshDirect() {
    if (host.settings.directDeviceMonitoring !== true) {
      directRestartPending = false
      directRetiring = directOwned && directProcess.running
      directWatchdog.stop()
      directProcess.running = false
      if (!directRetiring) directOwned = false
      clearDirect()
      directStartedAt = 0
      directRetryMilliseconds = 1000
      host.setObserverHealth("direct-device", "healthy", "ok", "")
      return
    }
    if (directRetiring) { directRestartPending = true; return }
    directWatchdog.stop()
    var desired = [helperPath(), "watch", "--heartbeat",
      String(host.boundedSeconds(host.settings.directDevicePollSeconds, 5, 2, 60))]
    if (directOwned) {
      if (!directProcess.running) { directProcess.command = desired; directStartedAt = Date.now(); return }
      if (JSON.stringify(directProcess.command) === JSON.stringify(desired)) return
      directRestartPending = true
      directRetiring = true
      directProcess.running = false
      return
    }
    directRestartPending = false
    directRetiring = false
    directProcess.command = desired
    directStartedAt = Date.now()
    directOwned = true
    directProcess.running = true
  }

  function acceptDirect(text) {
    if (directRetiring || host.settings.directDeviceMonitoring !== true) return
    try {
      var result = JSON.parse(String(text || "{}"))
      if (result.type !== "snapshot") throw new Error("invalid direct payload")
      directObservations = Array.isArray(result.observations) ? result.observations : []
      directLastSeen = Date.now()
      directRetryMilliseconds = 1000
      if (result.healthy === false)
        host.setObserverHealth("direct-device", "degraded", String(result.code || "observer_unhealthy"), String(result.error || "observer reported unhealthy"))
      else host.setObserverHealth("direct-device", "healthy", "ok", "")
    } catch (error) {
      clearDirect()
      host.setObserverHealth("direct-device", "degraded", "invalid_payload", "invalid observer response")
    }
  }

  PrivacyObserverWatchdog {
    id: directWatchdog
    interval: controller.directRetryMilliseconds
    enabled: controller.host.settings.directDeviceMonitoring === true
    processRunning: directProcess.running
    retiring: controller.directRetiring
    lastSeen: controller.directLastSeen
    startedAt: controller.directStartedAt
    heartbeatSeconds: controller.host.boundedSeconds(controller.host.settings.directDevicePollSeconds, 5, 2, 60)
    onRetryRequested: controller.refreshDirect()
    onHeartbeatStale: {
      controller.clearDirect()
      controller.host.setObserverHealth("direct-device", "degraded", "heartbeat_stale", "observer heartbeat is stale")
    }
  }

  PrivacyObserverWatchdog {
    id: fallbackWatchdog
    interval: controller.fallbackRetryMilliseconds
    enabled: controller.host.kindEnabled("screen-recording") || controller.host.kindEnabled("screenshot")
    processRunning: fallbackProcess.running
    retiring: controller.fallbackRetiring
    lastSeen: controller.fallbackLastSeen
    startedAt: controller.fallbackStartedAt
    heartbeatSeconds: controller.host.boundedSeconds(controller.host.settings.recordingPollSeconds, 2, 1, 60)
    onRetryRequested: controller.refreshFallback()
    onHeartbeatStale: {
      controller.clearFallback()
      controller.host.setObserverHealth("fallback-observer", "degraded", "heartbeat_stale", "fallback observer heartbeat is stale")
    }
  }

  Process {
    id: directProcess
    onExited: function(exitCode) {
      controller.directOwned = false
      if (controller.directRetiring) {
        controller.directRetiring = false
        if (controller.directRestartPending && controller.host.settings.directDeviceMonitoring === true) controller.refreshDirect()
        return
      }
      if (controller.host.settings.directDeviceMonitoring !== true) return
      controller.clearDirect()
      controller.host.setObserverHealth("direct-device", "degraded", "observer_exited", "observer exited with code " + exitCode)
      directWatchdog.interval = controller.directRetryMilliseconds
      controller.directRetryMilliseconds = Math.min(controller.directRetryMilliseconds * 2, 60000)
      directWatchdog.restart()
    }
    stdout: SplitParser { onRead: function(line) { controller.acceptDirect(line) } }
  }

  Process {
    id: fallbackProcess
    onExited: function(exitCode) {
      controller.fallbackOwned = false
      if (controller.fallbackRetiring) {
        controller.fallbackRetiring = false
        if (controller.fallbackRestartPending && (controller.host.kindEnabled("screen-recording") || controller.host.kindEnabled("screenshot"))) controller.refreshFallback()
        return
      }
      if (!controller.host.kindEnabled("screen-recording") && !controller.host.kindEnabled("screenshot")) return
      controller.clearFallback()
      controller.host.setObserverHealth("fallback-observer", "degraded", "observer_exited", "observer exited with code " + exitCode)
      controller.fallbackRetryMilliseconds = Math.min(controller.fallbackRetryMilliseconds * 2, 60000)
      fallbackWatchdog.restart()
    }
    stdout: SplitParser { onRead: function(line) { controller.acceptFallback(line) } }
  }
}
