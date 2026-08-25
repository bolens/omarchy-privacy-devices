import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

Rectangle {
  id: card
  required property var controller
  property var entry: ({kind: "", label: "", icon: "", active: false, apps: [], sessions: [], health: ({status: "healthy", summary: ""})})
  property bool hovered: false
  readonly property string visualState: controller.itemVisualState(entry)
  readonly property bool compact: controller.popupDensity === "compact"
  readonly property real verticalPadding: compact ? Style.spacing.sm : Style.spacing.md

  Layout.fillWidth: true
  implicitHeight: row.implicitHeight + verticalPadding * 2
  radius: Style.cornerRadius
  color: Util.alpha(controller.itemColor(entry), hovered ? 0.16 : (visualState === "active" ? 0.12 : 0.05))
  border.width: controller.selectedKind === entry.kind ? 2 : (entry.active ? 1 : 0)
  border.color: Util.alpha(controller.itemColor(entry), controller.selectedKind === entry.kind ? 0.75 : 0.45)

  HoverHandler {
    onHoveredChanged: {
      card.hovered = hovered
      if (hovered) controller.selectedKind = entry.kind
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      controller.selectedKind = entry.kind
      if (mouse.button === Qt.MiddleButton) { controller.editingKind = entry.kind; return }
      if (controller.showControls && entry.controllable && !entry.pending) controller.toggleEntry(entry)
    }
  }

  RowLayout {
    id: row
    anchors.fill: parent
    anchors.margins: card.verticalPadding
    spacing: card.compact ? Style.spacing.sm : Style.spacing.md
    Text { text: entry.icon; textFormat: Text.PlainText; color: controller.itemColor(entry); opacity: card.visualState === "idle" ? controller.itemIdleOpacity(entry.kind) : (card.visualState === "disabled" ? controller.disabledOpacity : 1); font.family: Style.font.family; font.pixelSize: Style.font.icon }
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 1
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.sm
        Text { Layout.fillWidth: true; text: entry.label; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body; font.weight: card.visualState === "active" ? Font.DemiBold : Font.Normal }
        Rectangle {
          visible: controller.itemSessionCount(entry) > 1
          implicitWidth: sessionCountText.implicitWidth + Style.spacing.sm
          implicitHeight: sessionCountText.implicitHeight + 2
          radius: implicitHeight / 2
          color: Util.alpha(controller.itemColor(entry), 0.18)
          Text { id: sessionCountText; anchors.centerIn: parent; text: String(controller.itemSessionCount(entry)); textFormat: Text.PlainText; color: controller.itemColor(entry); font.family: Style.font.family; font.pixelSize: Style.font.caption; font.weight: Font.DemiBold }
        }
      }
      Text {
        Layout.fillWidth: true
        text: card.visualState === "unavailable" ? "Monitoring degraded · " + entry.health.summary
          : card.visualState === "pending" ? "Waiting for observed state confirmation"
          : card.visualState === "disabled" ? "Blocked by privacy control"
          : card.visualState === "active" ? (entry.apps.length ? entry.apps.join(", ") : "Activity hidden by policy")
          : "Available · not in use"
        textFormat: Text.PlainText; color: card.visualState === "active" ? Color.popups.text : controller.inactiveThemeColor; font.family: Style.font.family; font.pixelSize: Style.font.caption; elide: Text.ElideRight
      }
      Text {
        visible: entry.sessions.length > 0
        Layout.fillWidth: true
        property var firstSession: entry.sessions.length ? entry.sessions[0] : ({})
        text: firstSession.device + " · " + firstSession.source + " · " + firstSession.confidence + " · " + Model.formatDuration(controller.durationNow - Number(firstSession.startedAt || controller.durationNow)) + (entry.sessions.length > 1 ? " · +" + (entry.sessions.length - 1) + " more" : "")
        textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; elide: Text.ElideRight
      }
    }
    Button { visible: entry.active && entry.apps.length > 0; text: "Hide"; tooltipText: "Hide this application from the bar; alerts remain enabled"; onClicked: controller.addPolicyValue("hiddenApps", entry.apps[0]) }
    Rectangle {
      visible: controller.showStatePills
      implicitWidth: stateText.implicitWidth + Style.spacing.md
      implicitHeight: stateText.implicitHeight + Style.spacing.sm
      radius: implicitHeight / 2
      color: controller.statePillStyle === "filled" ? Util.alpha(controller.itemColor(entry), 0.14) : "transparent"
      border.width: controller.statePillStyle === "minimal" ? 0 : 1
      border.color: Util.alpha(controller.itemColor(entry), controller.statePillStyle === "outline" ? 0.7 : 0.45)
      Text { id: stateText; anchors.centerIn: parent; text: !entry.dependenciesReady ? "INSTALL" : (entry.kind === "screenshot" ? "CAPTURE" : controller.itemStateLabel(entry)); textFormat: Text.PlainText; color: controller.itemColor(entry); font.family: Style.font.family; font.pixelSize: Style.font.caption; font.weight: Font.DemiBold }
    }
    ToggleSwitch { visible: controller.showControls && entry.controllable && entry.kind !== "screenshot" && entry.dependenciesReady; checked: entry.controlEnabled; busy: entry.pending; interactive: false; foreground: Color.popups.text; accent: controller.isAudioControl(entry) ? (entry.controlEnabled ? controller.unmutedThemeColor : controller.mutedThemeColor) : controller.activeThemeColor }
  }
}
