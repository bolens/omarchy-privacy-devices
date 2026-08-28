import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

ColumnLayout {
  id: view

  required property var controller
  readonly property var privacyService: controller.privacyService
  readonly property bool active: controller.editingKind === "" && !controller.showingGlobalSettings && !controller.showingHistory
  readonly property alias lockdownActionControl: lockdownButton
  readonly property alias presetFeedbackSurface: presetFeedback

  visible: active
  Layout.fillWidth: true
  spacing: Style.spacing.md

  RowLayout {
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
      implicitWidth: statusText.implicitWidth + Style.spacing.md * 2
      implicitHeight: statusText.implicitHeight + Style.spacing.sm
      radius: implicitHeight / 2
      color: Util.alpha(view.controller.monitoringDegraded ? Color.urgent : (view.controller.activeCount > 0 ? view.controller.activeThemeColor : view.controller.inactiveThemeColor), 0.14)
      border.width: 1
      border.color: Util.alpha(view.controller.monitoringDegraded ? Color.urgent : (view.controller.activeCount > 0 ? view.controller.activeThemeColor : view.controller.inactiveThemeColor), 0.32)
      Text {
        id: statusText
        anchors.centerIn: parent
        text: view.controller.monitoringDegraded ? "󰀦  Degraded" : (view.controller.activeCount > 0 ? view.controller.activeCount + " active" : "All idle")
        textFormat: Text.PlainText
        color: view.controller.monitoringDegraded ? Color.urgent : (view.controller.activeCount > 0 ? view.controller.activeThemeColor : view.controller.inactiveThemeColor)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.weight: Font.DemiBold
      }
    }
    Button {
      iconText: "󰋚"
      tooltipText: "Activity history"
      horizontalPadding: Style.spacing.controlGap
      onClicked: view.controller.showHistory()
    }
    Button {
      id: lockdownButton
      objectName: "privacyLockdownButton"
      readonly property var presentation: Model.lockdownActionPresentation(
        view.privacyService && view.privacyService.privacyPresetUndoAvailable,
        view.controller.confirmationPending === "lockdown")
      iconText: presentation.icon
      enabled: view.privacyService && view.privacyService.privacyPresetState !== "applying" && view.privacyService.privacyPresetState !== "restoring"
      tooltipText: presentation.tooltip
      horizontalPadding: Style.spacing.controlGap
      onClicked: view.controller.activateLockdownAction()
    }
    Button {
      iconText: "󰒓"
      tooltipText: "Global settings"
      horizontalPadding: Style.spacing.controlGap
      onClicked: view.controller.showGlobalSettings("general")
    }
  }

  PrivacyMessageSurface {
    id: presetFeedback
    objectName: "privacyPresetFeedback"
    visible: view.privacyService && view.privacyService.privacyPresetMessage() !== ""
    Layout.fillWidth: true
    message: view.privacyService ? view.privacyService.privacyPresetMessage() : ""
    kind: view.privacyService && view.privacyService.privacyPresetState === "partial" ? "error" : "info"
  }

  GridLayout {
    id: activityRows
    Layout.fillWidth: true
    columns: view.controller.popupGridColumns
    columnSpacing: view.controller.popupDensity === "compact" ? Style.spacing.sm : Style.spacing.md
    rowSpacing: view.controller.popupDensity === "compact" ? Style.spacing.sm : Style.spacing.md
    Repeater {
      // Do not retain main-widget delegates behind a settings/editor page.
      model: view.active ? view.controller.displayedActivityItems : []
      delegate: PrivacyActivityCard {
        required property var modelData
        required property int index
        Layout.columnSpan: view.controller.popupGridColumns === 2 && index === view.controller.displayedActivityItems.length - 1 && view.controller.displayedActivityItems.length % 2 === 1 ? 2 : 1
        entry: modelData
        controller: view.controller
      }
    }
  }

  ColumnLayout {
    visible: Model.arraySetting(view.controller.setting("hiddenApps", []), []).length > 0
    Layout.fillWidth: true
    spacing: Style.spacing.sm
    PanelSectionHeader { Layout.fillWidth: true; text: "Hidden applications" }
    Text { Layout.fillWidth: true; text: Model.arraySetting(view.controller.setting("hiddenApps", []), []).join(", "); textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    Button { text: "Restore all"; onClicked: view.controller.clearPolicy("hiddenApps") }
  }

  ColumnLayout {
    visible: Model.arraySetting(view.controller.setting("hiddenDevices", []), []).length > 0 || Model.arraySetting(view.controller.setting("notificationSuppressedDevices", []), []).length > 0
    Layout.fillWidth: true
    spacing: Style.spacing.sm
    PanelSectionHeader { Layout.fillWidth: true; text: "Device policies" }
    Text { Layout.fillWidth: true; text: "Hidden: " + (Model.arraySetting(view.controller.setting("hiddenDevices", []), []).join(", ") || "None"); textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    Text { Layout.fillWidth: true; text: "Alerts muted: " + (Model.arraySetting(view.controller.setting("notificationSuppressedDevices", []), []).join(", ") || "None"); textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    RowLayout {
      Button { text: "Restore hidden"; onClicked: view.controller.clearPolicy("hiddenDevices") }
      Button { text: "Restore alerts"; onClicked: view.controller.clearPolicy("notificationSuppressedDevices") }
    }
  }

  Text {
    Layout.fillWidth: true
    text: "Keyboard: ↑/↓ select · Enter open · H history · S settings · R refresh · Esc close"
    textFormat: Text.PlainText
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
