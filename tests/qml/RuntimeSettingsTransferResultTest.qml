pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  property var events: []
  QtObject {
    id: mockController
    function persistSettings(settings) { root.events = root.events.concat([{kind:"persist",settings:settings}]) }
    function resetGlobalSettings() { root.events = root.events.concat([{kind:"reset"}]) }
  }
  PrivacySettingsTransferResult { id: result; controller: mockController }
  Component.onCompleted: {
    if (!result.apply("export", "exported") || result.status !== "Settings exported privately") throw new Error("export result failed")
    if (!result.apply("checkpoint", "checkpointed") || root.events[0].kind !== "reset") throw new Error("checkpoint result failed")
    if (!result.apply("import", '{"_privacySettingsVersion":1,"showIdle":false}') || root.events[1].settings.showIdle !== false) throw new Error("import result failed")
    if (!result.apply("undo", '{"_privacySettingsVersion":1,"showIdle":true}') || root.events[2].settings.showIdle !== true) throw new Error("undo result failed")
    if (result.apply("import", "[]") || result.status !== "Import returned invalid settings") throw new Error("array import was accepted")
    if (result.apply("undo", "invalid") || result.status !== "Undo returned invalid settings") throw new Error("malformed undo was accepted")
    result.fail("fixture failed")
    if (result.status !== "Transfer failed: fixture failed") throw new Error("transfer failure detail was lost")
    console.log("PRIVACY_QML_SETTINGS_TRANSFER_RESULT_OK")
    Qt.quit()
  }
}
