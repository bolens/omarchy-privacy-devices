import QtQuick
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

  NumberField {
    Layout.fillWidth: true
    label: field.label + " (" + field.minimum + "–" + field.maximum + ")"
    from: field.minimum
    to: field.maximum
    stepSize: field.stepSize
    value: Number(field.controller.setting(field.settingKey, field.fallback))
    foreground: Color.popups.text
    accent: field.controller.activeThemeColor
    fontFamily: Style.font.family
    onModified: function(value) { field.save(value) }
  }
  Text { visible: field.description !== ""; Layout.fillWidth: true; text: field.description; textFormat: Text.PlainText; color: Color.muted; wrapMode: Text.WordWrap; font.family: Style.font.family; font.pixelSize: Style.font.caption }

  function save(candidate) {
    var value = Math.max(minimum, Math.min(maximum, Number(candidate) || fallback))
    var update = {}
    update[settingKey] = value
    controller.persistSettings(update)
  }
}
