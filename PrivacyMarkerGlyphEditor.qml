import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

ColumnLayout {
  id: editor
  required property var controller
  required property string settingKey
  required property string label
  required property string fallback
  Layout.fillWidth: true
  spacing: Style.spacing.xs
  Text { Layout.fillWidth: true; text: editor.label; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
  RowLayout {
    Layout.fillWidth: true
    TextField {
      id: markerEditor
      objectName: "markerGlyphField"
      Layout.fillWidth: true
      text: String(editor.controller.setting(editor.settingKey, editor.fallback))
      maximumLength: 8
      foreground: Color.popups.text
      accent: editor.controller.activeThemeColor
      font.family: Style.font.family
      onAccepted: editor.save()
    }
    Button { objectName: "markerGlyphSaveButton"; iconText: "󰆓"; tooltipText: "Save " + editor.label.toLowerCase(); horizontalPadding: Style.spacing.controlGap; onClicked: editor.save() }
  }
  function save() {
    var update = {}
    update[settingKey] = markerEditor.text
    controller.persistSettings(update)
  }
}
