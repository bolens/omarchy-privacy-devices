import Quickshell
import QtQuick

ShellRoot {
  id: root
  property int backCount: 0
  property var moves: []

  QtObject {
    id: controllerMock
    property string editingKind: "camera"
    function canMoveItem(kind, delta) {
      return (kind === "camera" && delta === -1) || (kind === "microphone" && delta === 1)
    }
    function moveDeviceEditor(delta) { root.moves = root.moves.concat([delta]) }
  }

  DeviceSettingsEditor {
    id: editor
    width: 500
    controller: controllerMock
    onBackRequested: root.backCount += 1
  }

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
    var back = descendant(editor, "deviceSettingsBackButton")
    var title = descendant(editor, "deviceSettingsTitle")
    var previous = descendant(editor, "deviceSettingsPreviousButton")
    var next = descendant(editor, "deviceSettingsNextButton")
    if (!back || !title || !previous || !next) throw new Error("device settings navigation is not addressable")
    if (title.text !== "Camera settings" || !previous.enabled || next.enabled)
      throw new Error("device settings navigation did not reflect the current boundary")
    previous.clicked()
    back.clicked()
    controllerMock.editingKind = "microphone"
    Qt.callLater(function() {
      if (title.text !== "Microphone settings" || previous.enabled || !next.enabled)
        throw new Error("device settings navigation did not react to device changes")
      next.clicked()
      if (root.backCount !== 1 || root.moves.length !== 2 || root.moves[0] !== -1 || root.moves[1] !== 1)
        throw new Error("device settings navigation dispatched the wrong actions")
      console.log("PRIVACY_QML_DEVICE_SETTINGS_NAVIGATION_OK")
      Qt.quit()
    })
  })
}
