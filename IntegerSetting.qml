pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Commons as Commons
import qs.Ui

ColumnLayout {
  id: integerField
  required property var controller
  required property string settingKey
  required property string label
  required property int minimum
  required property int maximum
  required property int fallback
  property int stepSize: 1
  property string description: ""
  property string controlObjectName: "integerSettingField"

  Layout.fillWidth: true
  spacing: Style.spacing.xs

  NumberField {
    objectName: integerField.controlObjectName
    Layout.fillWidth: true
    label: integerField.label + " (" + integerField.minimum + "–" + integerField.maximum + ")"
    from: integerField.minimum
    to: integerField.maximum
    stepSize: integerField.stepSize
    value: Number(integerField.controller.setting(integerField.settingKey, integerField.fallback))
    foreground: Commons.Color.popups.text
    accent: integerField.controller.activeThemeColor
    fontFamily: Style.font.family
    onModified: function(value) { integerField.save(value) }
  }
  Text { visible: integerField.description !== ""; Layout.fillWidth: true; text: integerField.description; textFormat: Text.PlainText; color: Commons.Color.muted; wrapMode: Text.WordWrap; font.family: Style.font.family; font.pixelSize: Style.font.caption }

  function save(candidate) {
    var numeric = Number(candidate)
    var value = Math.max(minimum, Math.min(maximum, isFinite(numeric) ? numeric : fallback))
    var update = {}
    update[settingKey] = value
    controller.persistSettings(update)
  }
}
