import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

ColumnLayout {
  id: navigation
  required property var controller
  Layout.fillWidth: true
  spacing: Style.spacing.md

  RowLayout {
    Layout.fillWidth: true
    Button { objectName: "settingsBackButton"; iconText: "󰁍"; tooltipText: "Back"; horizontalPadding: Style.spacing.controlGap; onClicked: navigation.controller.showActivity() }
    Text { Layout.fillWidth: true; text: "Global settings"; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.title; font.weight: Font.DemiBold }
  }

  GridLayout {
    objectName: "settingsPageGrid"
    Layout.fillWidth: true
    columns: navigation.controller.popupWidth === "narrow" ? 2 : 4
    columnSpacing: Style.spacing.sm
    rowSpacing: Style.spacing.sm
    Repeater {
      model: [
        {label:"General",value:"general"},
        {label:"Appearance",value:"appearance"},
        {label:"Alerts",value:"alerts"},
        {label:"Monitoring",value:"monitoring"}
      ]
      delegate: Button {
        required property var modelData
        objectName: "settingsPageButton-" + modelData.value
        Layout.fillWidth: true
        text: modelData.label
        active: navigation.controller.globalSettingsPage === modelData.value
        selected: active
        bordered: true
        fontSize: Style.font.bodySmall
        horizontalPadding: Style.spacing.controlPaddingX
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: navigation.controller.showGlobalSettings(modelData.value, "")
      }
    }
  }
}
