import Quickshell
import QtQuick
import "Model.js" as Model

ShellRoot {
  Component.onCompleted: {
    var raw = {showIdle:"yes", popupMaxHeight:9999, enabledKinds:["camera", "camera", "bogus"], unknown:"discard"}
    var clean = Model.sanitizeSettings(raw)
    if (clean.showIdle !== true || clean.popupMaxHeight !== 900) throw new Error("settings normalization failed")
    if (JSON.stringify(clean.enabledKinds) !== JSON.stringify(["camera"])) throw new Error("kind normalization failed")
    if (clean.unknown !== undefined || clean._privacySettingsVersion !== 1) throw new Error("settings version boundary failed")
    var grouped = Model.coalesceNotificationEvents([{phase:"started",kind:"camera",application:"Browser"},{phase:"started",kind:"camera",application:"Browser"}])
    if (grouped.count !== 1 || grouped.body !== "Browser: Camera") throw new Error("notification coalescing failed")
    var filtered = Model.filterAttribution([{confidence:"confirmed"},{confidence:"inferred"}], false)
    if (filtered.length !== 1 || filtered[0].confidence !== "confirmed") throw new Error("attribution filtering failed")
    var heartbeat = Model.observerHeartbeatState(0, 1000, 16000, 2)
    if (heartbeat.stale || heartbeat.ageSeconds !== 15) throw new Error("observer heartbeat policy failed")
    var request = Model.controlRequestStatus({known:true,enabled:true,serviceOwned:true,dependenciesReady:true,pending:false,processBusy:false})
    if (request !== "ok") throw new Error("control request policy failed")
    var invalidated = Model.invalidateObserverSessions([{id:"direct",source:"direct-device"},{id:"pipewire",source:"pipewire"}], "direct-device", {})
    if (!invalidated.changed || invalidated.active.length !== 1 || invalidated.active[0].id !== "pipewire")
      throw new Error("observer invalidation policy failed")
    var health = {watcher:{status:"healthy",code:"ok",reason:""}}
    if (Model.updateObserverHealth(health, "watcher", "healthy", "ok", "") !== health)
      throw new Error("observer health identity failed")
    var scheduled = Model.scheduleProbeRefresh(true, ["camera", "location"])
    var nextProbe = Model.nextProbeAction(scheduled.queue, scheduled.refreshPending, false)
    if (nextProbe.action !== "refresh" || nextProbe.queue.length !== 0)
      throw new Error("probe queue policy failed")
    if (Model.nextNavigationKind(["camera", "location"], "", 1) !== "camera")
      throw new Error("popup navigation policy failed")
    if (Model.activationKind(["camera"], "stale") !== "camera")
      throw new Error("popup activation policy failed")
    var stableActivity = {kind:"camera",active:false,controlEnabled:true,pending:false,health:{status:"healthy"}}
    var changedActivity = {kind:"camera",active:true,controlEnabled:true,pending:false,health:{status:"healthy"}}
    if (!Model.activityCriticalStateEquivalent([stableActivity], [stableActivity])
        || Model.activityCriticalStateEquivalent([stableActivity], [changedActivity]))
      throw new Error("presentation deferral policy failed")
    var diagnostic = Model.deviceDiagnosticPresentation({dependenciesReady:true,health:{status:"healthy"},probeExitCode:-1,controlExitCode:-1})
    if (diagnostic.rows.length !== 7 || diagnostic.rows[1].value !== "Ready")
      throw new Error("diagnostic presentation policy failed")
    var telemetry = Model.monitoringTelemetryText({pipewireReactive:true,lastSessionRefreshAgeSeconds:1,lastFallbackRefreshAgeSeconds:2,fallbackObserverRunning:true,fallbackObserverHeartbeatAgeSeconds:1,fallbackObserverRetryMilliseconds:1000,directDeviceEnabled:false})
    if (telemetry.indexOf("Fallback probes: 2s ago · observer running · heartbeat 1s ago · retry 1000ms") < 0)
      throw new Error("monitoring telemetry presentation failed")
    if (Model.itemTooltipAction({kind:"microphone",dependenciesReady:true,controllable:true,controlEnabled:false}) !== "Left click to unmute")
      throw new Error("item tooltip action policy failed")
    console.log("PRIVACY_QML_RUNTIME_OK")
    Qt.quit()
  }
}
