pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string helper: String(Qt.resolvedUrl("tests/fixtures/privacy-history-delay")).replace(/^file:\/\//, "")
  Service { id: service; historyHelperOverride: root.helper }

  function verify() {
    if (!service.historyLoaded || service.historyLoadBusy) return
    if (service.historyLoadPending || service.recentHistory.length !== 1
        || service.recentHistory[0].application !== "Delayed history")
      throw new Error("superseded history load did not publish only the final enabled generation")
    console.log("PRIVACY_QML_HISTORY_LOAD_SUPERSESSION_OK")
    Qt.quit()
  }

  Connections {
    target: service
    function onHistoryLoadedChanged() { root.verify() }
    function onHistoryLoadBusyChanged() { root.verify() }
  }

  Timer { interval: 2000; running: true; onTriggered: { throw new Error("superseded history load did not settle") } }

  Component.onCompleted: {
    service.configure({enabledKinds:[],historyEnabled:true,directDeviceMonitoring:false})
    if (!service.historyLoadBusy) throw new Error("history load did not acquire synchronous ownership")
    service.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    service.configure({enabledKinds:[],historyEnabled:true,directDeviceMonitoring:false})
    if (!service.historyLoadPending) throw new Error("re-enabled history did not retain a reload behind the stale generation")
  }
}
