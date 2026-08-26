import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root
  property var installs: []

  QtObject {
    id: serviceMock
    function installDependencies(kind) { root.installs = root.installs.concat([kind]) }
  }
  QtObject {
    id: controllerMock
    property color activeThemeColor: Color.accent
    property var privacyService: serviceMock
    function deviceDiagnostic(kind) {
      if (kind !== "location") throw new Error("diagnostics requested for wrong kind")
      return {
        healthStatus:"unavailable",dependenciesReady:false,
        dependencyDescription:"Install GeoClue support",
        rows:[
          {label:"Status",value:"Monitoring unavailable",urgent:true},
          {label:"Backend",value:"GeoClue",urgent:false}
        ]
      }
    }
  }

  DeviceDiagnostics { id: diagnostics; width: 500; controller: controllerMock; kind: "location" }

  function descendant(item, name) {
    if (!item) return null
    if (item.objectName === name) return item
    var children = item.children || []
    for (var index = 0; index < children.length; index++) {
      var found = descendant(children[index], name)
      if (found) return found
    }
    return null
  }

  Component.onCompleted: Qt.callLater(function() {
    var status = descendant(diagnostics, "deviceDiagnosticValue-Status")
    var backend = descendant(diagnostics, "deviceDiagnosticValue-Backend")
    var install = descendant(diagnostics, "deviceDiagnosticsInstallButton")
    if (!status || !backend || !install) throw new Error("device diagnostics are not addressable")
    if (status.text !== "Monitoring unavailable" || String(status.color).toLowerCase() !== String(Color.urgent).toLowerCase()
        || backend.text !== "GeoClue" || !install.visible || install.tooltipText !== "Install GeoClue support")
      throw new Error("device diagnostics did not reflect degraded dependency state")
    install.clicked()
    if (root.installs.length !== 1 || root.installs[0] !== "location")
      throw new Error("dependency install dispatched the wrong device kind")
    console.log("PRIVACY_QML_DEVICE_DIAGNOSTICS_OK")
    Qt.quit()
  })
}
