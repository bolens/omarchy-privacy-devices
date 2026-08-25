import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

RowLayout {
  id: editor
  required property var controller
  required property string settingKey
  required property string label
  required property string fallback
  Layout.fillWidth: true
  Text { text: editor.label; color: Color.popups.text; font.family: Style.font.family; Layout.preferredWidth: 170 }
  TextField {
    id: markerEditor
    Layout.fillWidth: true
    text: String(editor.controller.setting(editor.settingKey, editor.fallback))
    maximumLength: 8
    foreground: Color.popups.text
    accent: editor.controller.activeThemeColor
    font.family: Style.font.family
    onAccepted: editor.save()
  }
  Button { text: "Save"; onClicked: editor.save() }
  function save() {
    var update = {}
    update[settingKey] = markerEditor.text
    controller.persistSettings(update)
  }
}
