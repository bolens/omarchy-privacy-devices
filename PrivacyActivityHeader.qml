pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

RowLayout {
  id: header
  required property var controller
  readonly property bool narrow: width < Style.space(440)
  readonly property var privacyService: controller.privacyService
  readonly property alias lockdownActionControl: lockdownButton
  Layout.fillWidth: true

  Text {
    text: "Privacy activity"
    textFormat: Text.PlainText
    color: Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.title
    font.weight: Font.DemiBold
  }
  Item { Layout.fillWidth: true }
  Rectangle {
    visible: !header.narrow
    implicitWidth: statusText.implicitWidth + Style.spacing.md * 2
    implicitHeight: statusText.implicitHeight + Style.spacing.sm
    radius: implicitHeight / 2
    color: Util.alpha(header.controller.monitoringDegraded ? Color.urgent : (header.controller.activeCount > 0 ? header.controller.activeThemeColor : header.controller.inactiveThemeColor), 0.14)
    border.width: 1
    border.color: Util.alpha(header.controller.monitoringDegraded ? Color.urgent : (header.controller.activeCount > 0 ? header.controller.activeThemeColor : header.controller.inactiveThemeColor), 0.32)
    Text {
      id: statusText
      anchors.centerIn: parent
      text: header.controller.monitoringDegraded ? "󰀦  Degraded" : (header.controller.activeCount > 0 ? header.controller.activeCount + " active" : "All idle")
      textFormat: Text.PlainText
      color: header.controller.monitoringDegraded ? Color.urgent : (header.controller.activeCount > 0 ? header.controller.activeThemeColor : header.controller.inactiveThemeColor)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.weight: Font.DemiBold
    }
  }
  Button { iconText: "󰋚"; tooltipText: "Activity history"; horizontalPadding: Style.spacing.controlGap; onClicked: header.controller.showHistory() }
  Button {
    id: lockdownButton
    objectName: "privacyLockdownButton"
    readonly property var presentation: Model.lockdownActionPresentation(
      header.privacyService && header.privacyService.privacyPresetUndoAvailable,
      header.controller.confirmationPending === "lockdown")
    iconText: presentation.icon
    enabled: header.privacyService && header.privacyService.privacyPresetState !== "applying" && header.privacyService.privacyPresetState !== "restoring"
    tooltipText: presentation.tooltip
    horizontalPadding: Style.spacing.controlGap
    onClicked: header.controller.activateLockdownAction()
  }
  Button { iconText: "󰒓"; tooltipText: "Global settings"; horizontalPadding: Style.spacing.controlGap; onClicked: header.controller.showGlobalSettings("general") }
}
