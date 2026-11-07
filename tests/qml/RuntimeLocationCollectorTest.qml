pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  readonly property string fixtureHelper: String(Qt.resolvedUrl("tests/fixtures/privacy-location-delay")).replace(/^file:\/\//, "")
  property bool awaitingResult: false
  Service { id: service; locationHelperOverride: root.fixtureHelper }

  Component.onCompleted: {
    root.awaitingResult = true
    service.configure({enabledKinds:["location"], blockableKinds:["location"], historyEnabled:false, directDeviceMonitoring:false})
    if (!service.locationProbeBusy) throw new Error("location probe did not start its fixture helper")
  }

  Connections {
    target: service
    function onLocationProbeBusyChanged() {
      if (!root.awaitingResult || service.locationProbeBusy) return
      root.awaitingResult = false
      if (!service.locationActive || JSON.stringify(service.locationApps) !== JSON.stringify(["Late Maps"]))
        throw new Error("completed location collector lost its fixture payload")
      console.log("PRIVACY_QML_LOCATION_COLLECTOR_OK")
      Qt.quit()
    }
  }
  Timer { interval: 2000; running: true; onTriggered: { throw new Error("location fixture did not complete") } }
}
