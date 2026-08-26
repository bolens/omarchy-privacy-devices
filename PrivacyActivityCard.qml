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
  readonly property bool tiled: controller.popupGridColumns > 1
  readonly property real itemScale: controller.popupItemScale
  readonly property real verticalPadding: (compact ? Style.spacing.sm : Style.spacing.md) * itemScale
  readonly property bool hasPolicyActions: (entry.active && entry.apps.length > 0)
    || (entry.sessions.length > 0 && Boolean(entry.sessions[0].device))
  readonly property bool hasInlineActions: controller.showStatePills
    || hasPolicyActions
    || (controller.showControls && entry.controllable && entry.kind !== "screenshot" && entry.dependenciesReady)

  function sessionSummary(session) {
    var parts = []
    if (session.device) parts.push(controller.deviceLabel(session.device))
    parts.push(Model.formatDuration(controller.durationNow - Number(session.startedAt || controller.durationNow)))
    if (session.confidence && String(session.confidence).toLowerCase() !== "confirmed") parts.push("Inferred")
    if (entry.sessions.length > 1) parts.push("+" + (entry.sessions.length - 1) + " more")
    return parts.join(" · ")
  }

  Layout.fillWidth: true
  implicitHeight: body.implicitHeight + verticalPadding * 2
  radius: Style.cornerRadius
  color: Util.alpha(controller.itemColor(entry), hovered ? 0.18 : (visualState === "active" ? 0.13 : 0.07))
  border.width: controller.selectedKind === entry.kind ? 2 : 1
  border.color: Util.alpha(controller.itemColor(entry), controller.selectedKind === entry.kind ? 0.8 : (entry.active ? 0.5 : 0.16))

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

  GridLayout {
    id: body
    anchors.fill: parent
    anchors.margins: card.verticalPadding
    columns: card.tiled ? 1 : 2
    columnSpacing: (card.compact ? Style.spacing.sm : Style.spacing.md) * card.itemScale
    rowSpacing: Style.spacing.sm * card.itemScale

    RowLayout {
      Layout.fillWidth: true
      spacing: (card.compact ? Style.spacing.sm : Style.spacing.md) * card.itemScale
      Text { text: entry.icon; textFormat: Text.PlainText; color: controller.itemColor(entry); opacity: card.visualState === "idle" ? Math.max(controller.itemIdleOpacity(entry.kind), controller.popupIdleOpacity) : (card.visualState === "disabled" ? controller.disabledOpacity : 1); font.family: Style.font.family; font.pixelSize: Style.font.icon * card.itemScale }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.spacing.sm
          Text { Layout.fillWidth: true; text: entry.label; textFormat: Text.PlainText; color: Color.popups.text; opacity: card.visualState === "idle" ? controller.popupIdleOpacity : 1; font.family: Style.font.family; font.pixelSize: Style.font.body * card.itemScale; font.weight: card.visualState === "active" ? Font.DemiBold : Font.Normal; elide: Text.ElideRight }
          Rectangle {
            visible: controller.itemSessionCount(entry) > 1
            implicitWidth: sessionCountText.implicitWidth + Style.spacing.sm
            implicitHeight: sessionCountText.implicitHeight + 2
            radius: implicitHeight / 2
            color: Util.alpha(controller.itemColor(entry), 0.18)
            Text { id: sessionCountText; anchors.centerIn: parent; text: String(controller.itemSessionCount(entry)); textFormat: Text.PlainText; color: controller.itemColor(entry); font.family: Style.font.family; font.pixelSize: Style.font.caption * card.itemScale; font.weight: Font.DemiBold }
          }
        }
        Text {
          visible: card.visualState !== "idle" || !controller.showStatePills
          Layout.fillWidth: true
          text: card.visualState === "unavailable" ? "Monitoring degraded · " + entry.health.summary
            : card.visualState === "pending" ? "Waiting for observed state confirmation"
            : card.visualState === "disabled" ? "Blocked by privacy control"
            : card.visualState === "active" ? (entry.apps.length ? entry.apps.join(", ") : "Activity hidden by policy")
            : "Available · not in use"
          textFormat: Text.PlainText; color: card.visualState === "active" ? Color.popups.text : controller.inactiveThemeColor; opacity: card.visualState === "idle" ? controller.popupIdleOpacity : 1; font.family: Style.font.family; font.pixelSize: Style.font.caption * card.itemScale; elide: Text.ElideRight
        }
        Text {
          visible: entry.sessions.length > 0
          Layout.fillWidth: true
          property var firstSession: entry.sessions.length ? entry.sessions[0] : ({})
          text: card.sessionSummary(firstSession)
          textFormat: Text.PlainText; color: Color.muted; opacity: Math.max(0.75, controller.popupIdleOpacity); font.family: Style.font.family; font.pixelSize: Style.font.caption * card.itemScale; elide: Text.ElideRight
        }
      }
    }

    RowLayout {
      visible: card.hasInlineActions
      Layout.fillWidth: card.tiled
      Layout.alignment: Qt.AlignRight
      spacing: Style.spacing.sm * card.itemScale
      Button {
        visible: card.hasPolicyActions
        iconText: "󰇙"
        tooltipText: "More privacy actions"
        horizontalPadding: Style.spacing.controlGap
        onClicked: policyMenu.open()
      }
      Menu {
        id: policyMenu
        MenuItem { visible: entry.active && entry.apps.length > 0; text: "Hide application"; onTriggered: controller.addPolicyValue("hiddenApps", entry.apps[0]) }
        MenuItem { visible: entry.sessions.length > 0 && Boolean(entry.sessions[0].device); text: "Hide device"; onTriggered: controller.addPolicyValue("hiddenDevices", entry.sessions[0].device) }
        MenuItem { visible: entry.sessions.length > 0 && Boolean(entry.sessions[0].device); text: "Mute device alerts"; onTriggered: controller.addPolicyValue("notificationSuppressedDevices", entry.sessions[0].device) }
      }
      Item { visible: card.tiled; Layout.fillWidth: card.tiled }
      Rectangle {
        visible: controller.showStatePills
        implicitWidth: stateText.implicitWidth + Style.spacing.md * card.itemScale
        implicitHeight: stateText.implicitHeight + Style.spacing.sm * card.itemScale
        radius: implicitHeight / 2
        color: controller.statePillStyle === "filled" ? Util.alpha(controller.itemColor(entry), 0.14) : "transparent"
        border.width: controller.statePillStyle === "minimal" ? 0 : 1
        border.color: Util.alpha(controller.itemColor(entry), controller.statePillStyle === "outline" ? 0.7 : 0.45)
        Text { id: stateText; anchors.centerIn: parent; text: !entry.dependenciesReady ? "INSTALL" : (entry.kind === "screenshot" ? "CAPTURE" : controller.itemStateLabel(entry)); textFormat: Text.PlainText; color: controller.itemColor(entry); font.family: Style.font.family; font.pixelSize: Style.font.caption * card.itemScale; font.weight: Font.DemiBold }
      }
      ToggleSwitch { visible: controller.showControls && entry.controllable && entry.kind !== "screenshot" && entry.dependenciesReady; checked: entry.controlEnabled; busy: entry.pending; interactive: false; foreground: Color.popups.text; accent: controller.isAudioControl(entry) ? (entry.controlEnabled ? controller.unmutedThemeColor : controller.mutedThemeColor) : controller.activeThemeColor }
    }
  }
}
