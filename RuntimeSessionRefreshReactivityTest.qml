import Quickshell
import QtQuick

ShellRoot {
  id: root
  property int stage: 0
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
    id: reconciliationPoll
    interval: 100
    running: true
    repeat: true
    onTriggered: {
      var fixtureSessions = service.activeSessions.filter(function(session) {
        return session.application === "Browser" && session.device === "Camera 1"
      })
      if (root.stage === 0) {
        if (fixtureSessions.length !== 1 || service.lastSessionRefreshAt <= 0) return
        service.directObservations = []
        root.stage = 1
        return
      }
      if (fixtureSessions.length) return
      if (service.recentHistory.length || service.notificationQueue.length)
        throw new Error("removed observation reconciled with side effects")
      reconciliationPoll.stop()
      console.log("PRIVACY_QML_SESSION_REFRESH_REACTIVITY_OK")
      Qt.quit()
    }
  }
}
