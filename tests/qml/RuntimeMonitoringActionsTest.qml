pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root
  property var actions: []

  QtObject {
    id: serviceMock
    property var selfTestResult: ({status:"idle",text:"Run the self-test to check local privacy monitoring."})
    function clearHistory() { root.actions = root.actions.concat([{name:"clear"}]) }
    function runSelfTest() { root.actions = root.actions.concat([{name:"self-test"}]) }
    function sendTestNotification() { root.actions = root.actions.concat([{name:"alert"}]) }
    function copySelfTest() { root.actions = root.actions.concat([{name:"copy-self-test"}]) }
    function copyDiagnostics(safe) { root.actions = root.actions.concat([{name:"copy-diagnostics",safe:safe}]) }
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
    function monitoringTelemetryText() { return "All observers healthy" }
    function exportSettings() {}
    function importSettings() {}
    function undoSettingsChange() {}
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
    var run = descendant(page, "monitoringRunSelfTestButton")
    var alert = descendant(page, "monitoringSendTestAlertButton")
    var copySelf = descendant(page, "monitoringCopySelfTestButton")
    var copyDiagnostics = descendant(page, "monitoringCopyDiagnosticsButton")
    if (!run || !alert || !copySelf || !copyDiagnostics) throw new Error("monitoring actions are not addressable")
    if (run.text !== "" || run.iconText !== "󰐊" || run.tooltipText !== "Run monitoring self-test"
        || alert.text !== "" || alert.iconText !== "󰂚" || alert.tooltipText !== "Send test alert"
        || copySelf.text !== "" || copySelf.iconText !== "󰆏" || copySelf.tooltipText !== "Copy self-test result"
        || copyDiagnostics.text !== "" || copyDiagnostics.iconText !== "󰆍")
      throw new Error("monitoring actions are not descriptive icon controls")
    if (!run.enabled || !alert.enabled || copySelf.enabled || !copyDiagnostics.enabled)
      throw new Error("monitoring actions did not reflect initial availability")
    serviceMock.selfTestResult = {status:"passed",text:"All checks passed"}
    Qt.callLater(function() {
      if (!copySelf.enabled) throw new Error("completed self-test did not enable copy")
      run.clicked()
      alert.clicked()
      copySelf.clicked()
      copyDiagnostics.clicked()
      if (root.actions.length !== 4 || root.actions[0].name !== "self-test" || root.actions[1].name !== "alert"
          || root.actions[2].name !== "copy-self-test" || root.actions[3].name !== "copy-diagnostics" || root.actions[3].safe !== true)
        throw new Error("monitoring actions dispatched incorrectly or without redaction")
      console.log("PRIVACY_QML_MONITORING_ACTIONS_OK")
      Qt.quit()
    })
  })
}
