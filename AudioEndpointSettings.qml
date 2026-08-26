import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

SettingsSurface {
  id: surface
  required property var controller
  readonly property var service: controller.privacyService
  readonly property string kind: controller.editingKind

  Layout.fillWidth: true
  accent: controller.activeThemeColor

  RowLayout {
    Layout.fillWidth: true
    PanelSectionHeader { Layout.fillWidth: true; text: surface.kind === "microphone" ? "Microphone devices" : "Audio output devices" }
    Button { objectName: "audioEndpointRefreshButton"; iconText: "󰑓"; tooltipText: "Refresh devices"; horizontalPadding: Style.spacing.controlGap; enabled: surface.service !== null; onClicked: surface.service.refreshAudioEndpoints(surface.kind) }
  }
  Text { Layout.fillWidth: true; text: "Mute or unmute one hardware endpoint without changing the other devices."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
  Repeater {
    model: surface.service ? surface.service.audioEndpoints(surface.kind) : []
    delegate: Rectangle {
      required property var modelData
      objectName: "audioEndpointRow-" + modelData.id
      Layout.fillWidth: true
      implicitHeight: endpointRow.implicitHeight + Style.spacing.md * 2
      radius: Style.cornerRadius
      color: Util.alpha(modelData.muted ? Color.urgent : Color.popups.text, modelData.muted ? 0.08 : 0.035)
      border.width: 1
      border.color: Util.alpha(modelData.muted ? Color.urgent : Color.popups.text, modelData.muted ? 0.3 : 0.12)
      RowLayout {
        id: endpointRow
        anchors.fill: parent
        anchors.margins: Style.spacing.md
        spacing: Style.spacing.md
        Rectangle { implicitWidth: Style.spacing.sm; implicitHeight: implicitWidth; radius: implicitWidth / 2; color: modelData.muted ? Color.urgent : surface.accent }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.spacing.xs
          Text { Layout.fillWidth: true; text: modelData.label; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
          Text { objectName: "audioEndpointStatus-" + modelData.id; Layout.fillWidth: true; text: modelData.muted ? "Blocked · muted" : "Allowed · unmuted"; textFormat: Text.PlainText; color: modelData.muted ? Color.urgent : Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
        }
        Button { objectName: "audioEndpointAction-" + modelData.id; text: modelData.muted ? "Allow" : "Block"; horizontalPadding: Style.spacing.md; onClicked: surface.service.setAudioEndpointMuted(surface.kind, modelData.id, !modelData.muted) }
      }
    }
  }
  PrivacyMessageSurface { visible: surface.service && surface.service.audioEndpointMessage !== ""; message: surface.service ? surface.service.audioEndpointMessage : ""; kind: surface.service && surface.service.audioEndpointMessage.indexOf("not") !== -1 ? "error" : "info" }
}
