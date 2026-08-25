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

  Layout.fillWidth: true
  implicitHeight: row.implicitHeight + Style.spacing.md * 2
  radius: Style.cornerRadius
  color: Util.alpha(entry.active ? controller.activeThemeColor : controller.inactiveThemeColor, hovered ? 0.16 : (entry.active ? 0.12 : 0.05))
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
    anchors.margins: Style.spacing.md
    spacing: Style.spacing.md
    Text { text: entry.icon; textFormat: Text.PlainText; color: controller.itemColor(entry); opacity: entry.active ? 1 : controller.itemIdleOpacity(entry.kind); font.family: Style.font.family; font.pixelSize: Style.font.icon }
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 1
      Text { Layout.fillWidth: true; text: entry.label; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body; font.weight: entry.active ? Font.DemiBold : Font.Normal }
      Text { Layout.fillWidth: true; text: entry.health.status !== "healthy" ? "Monitoring " + entry.health.status + " · " + entry.health.summary : entry.active ? (entry.apps.length ? entry.apps.join(", ") : "Activity hidden by policy") : "Idle"; textFormat: Text.PlainText; color: entry.active ? Color.popups.text : controller.inactiveThemeColor; font.family: Style.font.family; font.pixelSize: Style.font.caption; elide: Text.ElideRight }
      Text {
        visible: entry.sessions.length > 0
        Layout.fillWidth: true
        property var firstSession: entry.sessions.length ? entry.sessions[0] : ({})
        text: firstSession.device + " · " + firstSession.source + " · " + firstSession.confidence + " · " + Model.formatDuration(controller.durationNow - Number(firstSession.startedAt || controller.durationNow)) + (entry.sessions.length > 1 ? " · +" + (entry.sessions.length - 1) + " more" : "")
        textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; elide: Text.ElideRight
      }
    }
    Button { visible: entry.active && entry.apps.length > 0; text: "Hide"; tooltipText: "Hide this application from the bar; alerts remain enabled"; onClicked: controller.addPolicyValue("hiddenApps", entry.apps[0]) }
    Text { visible: !controller.showControls || !entry.controllable || entry.kind === "screenshot" || !entry.dependenciesReady; text: !entry.dependenciesReady ? "INSTALL" : (entry.kind === "screenshot" ? "CAPTURE" : (entry.active ? "ACTIVE" : "IDLE")); textFormat: Text.PlainText; color: controller.itemColor(entry); font.family: Style.font.family; font.pixelSize: Style.font.caption; font.weight: Font.DemiBold }
    ToggleSwitch { visible: controller.showControls && entry.controllable && entry.kind !== "screenshot" && entry.dependenciesReady; checked: entry.controlEnabled; busy: entry.pending; interactive: false; foreground: Color.popups.text; accent: controller.isAudioControl(entry) ? (entry.controlEnabled ? controller.unmutedThemeColor : controller.mutedThemeColor) : controller.activeThemeColor }
  }
}
