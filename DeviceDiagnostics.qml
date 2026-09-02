pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

SettingsSurface {
  id: diagnostics
  required property var controller
  required property string kind
  readonly property var diagnostic: controller.deviceDiagnostic(kind)

  Layout.fillWidth: true
  accent: diagnostics.diagnostic.healthStatus === "healthy" ? controller.activeThemeColor : Color.urgent

  PanelSectionHeader { Layout.fillWidth: true; text: "Diagnostics" }

  Repeater {
    model: diagnostics.diagnostic.rows
    delegate: RowLayout {
      id: diagnosticRow
      required property var modelData
      Layout.fillWidth: true
      Text {
        objectName: "deviceDiagnosticLabel-" + diagnosticRow.modelData.label
        Layout.preferredWidth: 110
        text: diagnosticRow.modelData.label
        textFormat: Text.PlainText
        color: Color.muted
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
      Text {
        objectName: "deviceDiagnosticValue-" + diagnosticRow.modelData.label
        Layout.fillWidth: true
        text: diagnosticRow.modelData.value
        textFormat: Text.PlainText
        color: diagnosticRow.modelData.urgent ? Color.urgent : Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }
    }
  }

  Button {
    objectName: "deviceDiagnosticsInstallButton"
    visible: !diagnostics.diagnostic.dependenciesReady
    text: "Install requirements"
    tooltipText: diagnostics.diagnostic.dependencyDescription
    onClicked: diagnostics.controller.privacyService.installDependencies(diagnostics.kind)
  }
}
