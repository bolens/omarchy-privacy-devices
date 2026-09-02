pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root
  property var patches: []

  QtObject {
    id: controllerMock
    property color activeThemeColor: Color.accent
    property var values: ({spacing:7})
    function setting(key, fallback) { return values[key] === undefined ? fallback : values[key] }
    function persistSettings(patch) { root.patches = root.patches.concat([patch]) }
  }

  IntegerSetting {
    id: setting
    width: 400
    controller: controllerMock
    settingKey: "spacing"
    label: "Spacing"
    minimum: 0
    maximum: 12
    fallback: 5
    stepSize: 2
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
    var field = descendant(setting, "integerSettingField")
    if (!field) throw new Error("integer setting field is not addressable")
    if (field.value !== 7 || field.from !== 0 || field.to !== 12 || field.stepSize !== 2)
      throw new Error("integer field did not reflect its setting contract")
    field.modified(0)
    field.modified(99)
    field.modified(-4)
    if (root.patches.length !== 3 || root.patches[0].spacing !== 0
        || root.patches[1].spacing !== 12 || root.patches[2].spacing !== 0)
      throw new Error("integer setting did not preserve zero and clamp boundaries")
    console.log("PRIVACY_QML_INTEGER_SETTING_OK")
    Qt.quit()
  })
}
