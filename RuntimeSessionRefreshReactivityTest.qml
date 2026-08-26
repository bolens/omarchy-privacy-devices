import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {
      enabledKinds:["camera"],
      directDeviceMonitoring:true,
      notifyOnActivity:false,
      notifyOnStop:false,
      historyEnabled:false
    }
    service.activityInitialized = true
    service.directObservations = [{kind:"camera", application:"Browser", device:"Camera 1", source:"direct-device", confidence:"confirmed"}]
  }

  Timer {
    interval: 250
    running: true
    onTriggered: {
      if (service.activeSessions.length !== 1 || service.activeSessions[0].application !== "Browser"
          || service.lastSessionRefreshAt <= 0)
        throw new Error("direct observation did not trigger debounced reconciliation")
      service.directObservations = []
    }
  }

  Timer {
    interval: 550
    running: true
    onTriggered: {
      var fixtureSessions = service.activeSessions.filter(function(session) {
        return session.application === "Browser" && session.device === "Camera 1"
      })
      if (fixtureSessions.length || service.recentHistory.length || service.notificationQueue.length)
        throw new Error("removed observation did not reconcile without side effects")
      console.log("PRIVACY_QML_SESSION_REFRESH_REACTIVITY_OK")
      Qt.quit()
    }
  }
}
