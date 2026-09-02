pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    var now = Date.now()
    service.settings = {enabledKinds:[], directDeviceMonitoring:true}
    service.lastSessionRefreshAt = now - 2100
    service.lastFallbackRefreshAt = now - 4300
    service.fallbackObserverLastSeen = now - 1200
    service.directObserverLastSeen = 0
    service.fallbackObserverRetryMilliseconds = 4000
    service.directObserverRetryMilliseconds = 8000

    var telemetry = service.monitoringTelemetry()
    if (telemetry.lastSessionRefreshAgeSeconds < 2 || telemetry.lastSessionRefreshAgeSeconds > 3
        || telemetry.lastFallbackRefreshAgeSeconds < 4 || telemetry.lastFallbackRefreshAgeSeconds > 5
        || telemetry.fallbackObserverHeartbeatAgeSeconds < 1 || telemetry.fallbackObserverHeartbeatAgeSeconds > 2)
      throw new Error("monitoring telemetry did not convert timestamps to bounded ages")
    if (telemetry.directHeartbeatAgeSeconds !== -1 || telemetry.directDeviceEnabled !== true
        || telemetry.fallbackObserverRetryMilliseconds !== 4000 || telemetry.directObserverRetryMilliseconds !== 8000)
      throw new Error("monitoring telemetry lost waiting or retry state")
    if (typeof telemetry.pipewireReactive !== "boolean" || typeof telemetry.fallbackObserverRunning !== "boolean"
        || typeof telemetry.directObserverRunning !== "boolean")
      throw new Error("monitoring telemetry exported unstable runtime types")

    console.log("PRIVACY_QML_MONITORING_TELEMETRY_OK")
    Qt.quit()
  }
}
