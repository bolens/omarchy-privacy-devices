import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string fixtureHelper: String(Qt.resolvedUrl("tests/fixtures/privacy-location-delay")).replace(/^file:\/\//, "")
  Service { id: service; locationHelperOverride: root.fixtureHelper }

  Component.onCompleted: {
    service.configure({enabledKinds:["location"], blockableKinds:["location"], historyEnabled:false, directDeviceMonitoring:false})
    if (!service.locationProbeBusy) throw new Error("location probe did not claim synchronous ownership")
    service.configure({enabledKinds:[], blockableKinds:[], historyEnabled:false, directDeviceMonitoring:false})
  }

  Connections {
    target: service
    function onLocationProbeBusyChanged() {
      if (service.locationProbeBusy) return
      if (service.locationActive || service.locationApps.length)
        throw new Error("superseded location probe republished disabled state")
      console.log("PRIVACY_QML_LOCATION_PROBE_SUPERSESSION_OK")
      Qt.quit()
    }
  }
  Timer { interval: 2000; running: true; onTriggered: { throw new Error("location probe did not settle") } }
}
