import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui

ColumnLayout {
  id: field
  required property var controller
  required property string settingKey
  required property string label
  required property int minimum
  required property int maximum
  required property int fallback
  property int stepSize: 1
  property string description: ""

  Layout.fillWidth: true
  spacing: Style.spacing.xs

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.spacing.sm
    Text { Layout.fillWidth: true; text: field.label + " (" + field.minimum + "–" + field.maximum + ")"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    TextField {
      id: editor
      Layout.preferredWidth: Style.space(92)
      text: String(field.controller.setting(field.settingKey, field.fallback))
      inputMethodHints: Qt.ImhDigitsOnly
      foreground: Color.popups.text
      accent: field.controller.activeThemeColor
      font.family: Style.font.family
      validator: IntValidator { bottom: field.minimum; top: field.maximum }
      onAccepted: field.save()
    }
    Button { text: "Save"; enabled: editor.acceptableInput; onClicked: field.save() }
  }
  Text { visible: field.description !== ""; Layout.fillWidth: true; text: field.description; textFormat: Text.PlainText; color: Color.muted; wrapMode: Text.WordWrap; font.family: Style.font.family; font.pixelSize: Style.font.caption }

  function save() {
    var value = Math.max(minimum, Math.min(maximum, Number(editor.text) || fallback))
    var update = {}
    update[settingKey] = value
    controller.persistSettings(update)
  }
}
