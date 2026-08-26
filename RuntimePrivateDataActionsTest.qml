import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root
  property var actions: []

  QtObject {
    id: serviceMock
    property var selfTestResult: ({status:"idle",text:"Idle"})
    function clearHistory() { root.actions = root.actions.concat(["clear"] ) }
    function runSelfTest() {}
    function sendTestNotification() {}
    function copySelfTest() {}
    function copyDiagnostics(_safe) {}
  }
  QtObject {
    id: controllerMock
    property color activeThemeColor: Color.accent
    property bool monitoringDegraded: false
    property var privacyService: serviceMock
    property var kindOptions: []
    property bool settingsTransferRunning: false
    property bool settingsUndoAvailable: false
    property string settingsTransferStatus: ""
    function setting(_key, fallback) { return fallback }
    function persistSettings(_patch) {}
    function monitoringTelemetryText() { return "Healthy" }
    function exportSettings() { root.actions = root.actions.concat(["export"]) }
    function importSettings() { root.actions = root.actions.concat(["import"]) }
    function undoSettingsChange() { root.actions = root.actions.concat(["undo"]) }
  }

  PrivacyMonitoringSettings { id: page; width: 500; controller: controllerMock }

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
    var clear = descendant(page, "privateDataClearHistoryButton")
    var exportAction = descendant(page, "privateDataExportSettingsButton")
    var importAction = descendant(page, "privateDataImportSettingsButton")
    var undo = descendant(page, "privateDataUndoSettingsButton")
    if (!clear || !exportAction || !importAction || !undo) throw new Error("private-data actions are not addressable")
    if (!clear.enabled || !exportAction.enabled || !importAction.enabled || undo.enabled)
      throw new Error("private-data actions did not reflect initial availability")
    clear.clicked(); exportAction.clicked(); importAction.clicked()
    controllerMock.settingsUndoAvailable = true
    Qt.callLater(function() {
      if (!undo.enabled) throw new Error("available settings undo remained disabled")
      undo.clicked()
      controllerMock.settingsTransferRunning = true
      Qt.callLater(function() {
        if (exportAction.enabled || importAction.enabled || undo.enabled || !clear.enabled)
          throw new Error("private-data actions did not isolate transfer busy state")
        if (root.actions.join(",") !== "clear,export,import,undo")
          throw new Error("private-data actions dispatched incorrectly")
        console.log("PRIVACY_QML_PRIVATE_DATA_ACTIONS_OK")
        Qt.quit()
      })
    })
  })
}
