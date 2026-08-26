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

  PanelSectionHeader { Layout.fillWidth: true; text: surface.kind === "microphone" ? "Microphone devices" : "Audio output devices" }
  Text { Layout.fillWidth: true; text: "Mute or unmute one hardware endpoint without changing the other devices."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
  Repeater {
    model: surface.service ? surface.service.audioEndpoints(surface.kind) : []
    delegate: RowLayout {
      required property var modelData
      Layout.fillWidth: true
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.xs
        Text { Layout.fillWidth: true; text: modelData.label; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body; elide: Text.ElideRight }
        Text { Layout.fillWidth: true; text: modelData.muted ? "Blocked · muted" : "Allowed · unmuted"; textFormat: Text.PlainText; color: modelData.muted ? Color.urgent : Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
      }
      Button { text: modelData.muted ? "Allow" : "Block"; onClicked: surface.service.setAudioEndpointMuted(surface.kind, modelData.id, !modelData.muted) }
    }
  }
  PrivacyMessageSurface { visible: surface.service && surface.service.audioEndpointMessage !== ""; message: surface.service ? surface.service.audioEndpointMessage : ""; kind: surface.service && surface.service.audioEndpointMessage.indexOf("not") !== -1 ? "error" : "info" }
  Button { text: "Refresh devices"; enabled: surface.service !== null; onClicked: surface.service.refreshAudioEndpoints(surface.kind) }
}
