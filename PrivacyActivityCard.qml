pragma ComponentBehavior: Bound
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

  function hideApplication() {
    if (!entry.active || entry.apps.length === 0) return false
    controller.addPolicyValue("hiddenApps", entry.apps[0])
    return true
  }

  function hideDevice() {
    if (entry.sessions.length === 0 || !entry.sessions[0].device) return false
    controller.addPolicyValue("hiddenDevices", entry.sessions[0].device)
    return true
  }

  function muteDeviceAlerts() {
    if (entry.sessions.length === 0 || !entry.sessions[0].device) return false
    controller.addPolicyValue("notificationSuppressedDevices", entry.sessions[0].device)
    return true
  }

  function activate(button) {
    controller.selectedKind = entry.kind
    if (button === Qt.MiddleButton) { controller.editingKind = entry.kind; return }
    if (controller.showControls && entry.controllable && entry.kind !== "screenshot"
        && entry.dependenciesReady && !entry.pending) controller.toggleEntry(entry)
  }

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
  activeFocusOnTab: true
  Keys.onReturnPressed: card.activate(Qt.LeftButton)
  Keys.onEnterPressed: card.activate(Qt.LeftButton)
  Keys.onSpacePressed: card.activate(Qt.LeftButton)
  Accessible.role: Accessible.Button
  Accessible.name: entry.label
  Accessible.description: visualState === "unavailable" ? "Monitoring degraded. " + entry.health.summary
    : visualState === "pending" ? "Waiting for observed state confirmation"
    : visualState === "blocked-active" ? "Blocked request observed"
    : visualState === "disabled" ? "Blocked by privacy control"
    : visualState === "active" ? "In use"
    : "Available, not in use"
  Accessible.onPressAction: card.activate(Qt.LeftButton)

  HoverHandler {
    onHoveredChanged: {
      card.hovered = hovered
      if (hovered) card.controller.selectedKind = card.entry.kind
    }
  }

  MouseArea {
    objectName: "activityCardClickArea"
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      card.activate(mouse.button)
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
      Text { text: card.entry.icon; textFormat: Text.PlainText; color: card.controller.itemColor(card.entry); opacity: card.visualState === "idle" ? Math.max(card.controller.itemIdleOpacity(card.entry.kind), card.controller.popupIdleOpacity) : (card.visualState === "disabled" ? card.controller.disabledOpacity : 1); font.family: Style.font.family; font.pixelSize: Style.font.icon * card.itemScale }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.spacing.sm
          Text { Layout.fillWidth: true; text: card.entry.label; textFormat: Text.PlainText; color: Color.popups.text; opacity: card.visualState === "idle" ? card.controller.popupIdleOpacity : 1; font.family: Style.font.family; font.pixelSize: Style.font.body * card.itemScale; font.weight: card.visualState === "active" ? Font.DemiBold : Font.Normal; elide: Text.ElideRight }
          Rectangle {
            objectName: "activitySessionCountBadge"
            visible: card.controller.itemSessionCount(card.entry) > 1
            implicitWidth: sessionCountText.implicitWidth + Style.spacing.sm
            implicitHeight: sessionCountText.implicitHeight + 2
            radius: implicitHeight / 2
            color: Util.alpha(card.controller.itemColor(card.entry), 0.18)
            Text { id: sessionCountText; objectName: "activitySessionCount"; anchors.centerIn: parent; text: String(card.controller.itemSessionCount(card.entry)); textFormat: Text.PlainText; color: card.controller.itemColor(card.entry); font.family: Style.font.family; font.pixelSize: Style.font.caption * card.itemScale; font.weight: Font.DemiBold }
          }
        }
        Text {
          objectName: "activityStateDescription"
          visible: card.visualState !== "idle" || !card.controller.showStatePills
          Layout.fillWidth: true
          text: card.visualState === "unavailable" ? "Monitoring degraded · " + card.entry.health.summary
            : card.visualState === "pending" ? "Waiting for observed state confirmation"
            : card.visualState === "blocked-active" ? "Blocked request observed"
            : card.visualState === "disabled" ? "Blocked by privacy control"
            : card.visualState === "active" ? (card.entry.apps.length ? card.entry.apps.join(", ") : "Activity hidden by policy")
            : "Available · not in use"
          textFormat: Text.PlainText; color: card.visualState === "active" ? Color.popups.text : card.controller.inactiveThemeColor; opacity: card.visualState === "idle" ? card.controller.popupIdleOpacity : 1; font.family: Style.font.family; font.pixelSize: Style.font.caption * card.itemScale; elide: Text.ElideRight
        }
        Text {
          objectName: "activitySessionSummary"
          visible: card.entry.sessions.length > 0
          Layout.fillWidth: true
          property var firstSession: card.entry.sessions.length ? card.entry.sessions[0] : ({})
          text: card.sessionSummary(firstSession)
          textFormat: Text.PlainText; color: Color.muted; opacity: Math.max(0.75, card.controller.popupIdleOpacity); font.family: Style.font.family; font.pixelSize: Style.font.caption * card.itemScale; elide: Text.ElideRight
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
        MenuItem { visible: card.entry.active && card.entry.apps.length > 0; text: "Hide application"; onTriggered: card.hideApplication() }
        MenuItem { visible: card.entry.sessions.length > 0 && Boolean(card.entry.sessions[0].device); text: "Hide device"; onTriggered: card.hideDevice() }
        MenuItem { visible: card.entry.sessions.length > 0 && Boolean(card.entry.sessions[0].device); text: "Mute device alerts"; onTriggered: card.muteDeviceAlerts() }
      }
      Item { visible: card.tiled; Layout.fillWidth: card.tiled }
      Rectangle {
        visible: card.controller.showStatePills
        implicitWidth: stateText.implicitWidth + Style.spacing.md * card.itemScale
        implicitHeight: stateText.implicitHeight + Style.spacing.sm * card.itemScale
        radius: implicitHeight / 2
        color: card.controller.statePillStyle === "filled" ? Util.alpha(card.controller.itemColor(card.entry), 0.14) : "transparent"
        border.width: card.controller.statePillStyle === "minimal" ? 0 : 1
        border.color: Util.alpha(card.controller.itemColor(card.entry), card.controller.statePillStyle === "outline" ? 0.7 : 0.45)
        Text { id: stateText; objectName: "activityStatePillText"; anchors.centerIn: parent; text: !card.entry.dependenciesReady ? "INSTALL" : (card.entry.kind === "screenshot" ? "CAPTURE" : card.controller.itemStateLabel(card.entry)); textFormat: Text.PlainText; color: card.controller.itemColor(card.entry); font.family: Style.font.family; font.pixelSize: Style.font.caption * card.itemScale; font.weight: Font.DemiBold }
      }
      ToggleSwitch { visible: card.controller.showControls && card.entry.controllable && card.entry.kind !== "screenshot" && card.entry.dependenciesReady; checked: card.entry.controlEnabled; busy: card.entry.pending; interactive: false; foreground: Color.popups.text; accent: card.controller.isAudioControl(card.entry) ? (card.entry.controlEnabled ? card.controller.unmutedThemeColor : card.controller.mutedThemeColor) : card.controller.activeThemeColor }
    }
  }
}
