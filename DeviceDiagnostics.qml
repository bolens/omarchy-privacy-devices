import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

SettingsSurface {
  id: diagnostics
  required property var controller
  required property string kind
  readonly property var data: controller.deviceDiagnostic(kind)

  Layout.fillWidth: true
  accent: data.healthStatus === "healthy" ? controller.activeThemeColor : Color.urgent

  PanelSectionHeader { Layout.fillWidth: true; text: "Diagnostics" }

  Repeater {
    model: diagnostics.data.rows
    delegate: RowLayout {
      required property var modelData
      Layout.fillWidth: true
      Text {
        Layout.preferredWidth: 110
        text: modelData.label
        textFormat: Text.PlainText
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
      Text {
        Layout.fillWidth: true
        text: modelData.value
        textFormat: Text.PlainText
        color: modelData.urgent ? Color.urgent : Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }
  }

  Button {
    visible: !diagnostics.data.dependenciesReady
    text: "Install requirements"
    tooltipText: diagnostics.data.dependencyDescription
    onClicked: diagnostics.controller.privacyService.installDependencies(diagnostics.kind)
  }
}
