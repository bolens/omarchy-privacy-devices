import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {notifyOnObserverHealth:false}
    var initial = service.observerHealth
    service.setObserverHealth("direct-device", "healthy", "ok", "")
    if (service.observerHealth !== initial)
      throw new Error("unchanged observer health replaced the state object")

    service.setObserverHealth("direct-device", "degraded", "permission_denied", "denied")
    var degraded = service.observerHealth
    if (degraded === initial || degraded["direct-device"].status !== "degraded"
        || degraded["direct-device"].code !== "permission_denied"
        || Object.keys(service.observerHealthLastNotifiedAt).length !== 0)
      throw new Error("degraded observer health was not published without notification state")
    if (degraded["fallback-observer"].status !== "healthy")
      throw new Error("observer health update mutated another source")

    service.setObserverHealth("direct-device", "healthy", "ok", "")
    if (service.observerHealth === degraded || service.observerHealth["direct-device"].status !== "healthy"
        || service.observerHealth["direct-device"].reason !== "")
      throw new Error("observer recovery was not published")
    service.setObserverHealth("custom-source", "unavailable", "missing", "not installed")
    if (service.observerHealth["custom-source"].source !== "custom-source"
        || service.observerHealth["custom-source"].status !== "unavailable")
      throw new Error("new observer source was not added safely")

    console.log("PRIVACY_QML_OBSERVER_HEALTH_STATE_OK")
    Qt.quit()
  }
}
