import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

ColumnLayout {
  id: page
  required property var controller
  property var sectionItems: ({"enhanced-coverage": enhancedCoverageSettings,"fallback-polling": fallbackPollingSettings,"private-data": privateDataSettings,"status-legend": statusLegendSettings,"observer-health": observerHealthSettings})
  spacing: Style.spacing.md
  SettingsSurface {
    id: enhancedCoverageSettings
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Enhanced coverage" }
    MultiSelect { Layout.fillWidth: true; label: "Preventative controls"; options: page.controller.kindOptions.filter(function(option) { return ["camera", "screen-share", "location"].indexOf(option.value) !== -1 }); values: Model.arraySetting(page.controller.setting("blockableKinds", ["camera", "screen-share", "location"]), []); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onChanged: function(values) { page.controller.persistSettings({blockableKinds: values}) } }
    PrivacySettingToggle { controller: page.controller; settingKey: "directDeviceMonitoring"; fallback: false; label: "Direct-device monitoring"; description: "Inspect same-user V4L2 and ALSA capture handles for applications that bypass PipeWire." }
    PrivacySettingToggle { controller: page.controller; settingKey: "showInferredAttribution"; label: "Show inferred attribution"; description: "Show heuristic application and device names; activity remains visible when disabled." }
    IntegerSetting { controller: page.controller; settingKey: "directDevicePollSeconds"; label: "Direct-device heartbeat, seconds"; minimum: 2; maximum: 60; fallback: 5 }
  }
  SettingsSurface {
    id: fallbackPollingSettings
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Fallback polling" }
    IntegerSetting { controller: page.controller; settingKey: "locationPollSeconds"; label: "Location refresh, seconds"; minimum: 5; maximum: 300; fallback: 15; stepSize: 5 }
    IntegerSetting { controller: page.controller; settingKey: "recordingPollSeconds"; label: "Recorder refresh, seconds"; minimum: 1; maximum: 60; fallback: 2 }
    Text { Layout.fillWidth: true; text: "PipeWire activity remains event-backed. These intervals affect only enhanced and fallback observers."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
  }
  SettingsSurface {
    id: privateDataSettings
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Private data" }
    PrivacySettingToggle { objectName: "historyEnabledToggle"; controller: page.controller; settingKey: "historyEnabled"; fallback: false; label: "Keep recent activity"; description: "Store private metadata for seven days or 100 completed sessions." }
    Button { text: "Clear stored history"; enabled: page.controller.privacyService !== null; onClicked: page.controller.privacyService.clearHistory() }
    Text { Layout.fillWidth: true; text: "Export or restore a versioned settings file stored privately in your user data directory."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    RowLayout {
      Layout.fillWidth: true
      Button { text: "Export settings"; enabled: !page.controller.settingsTransferRunning; onClicked: page.controller.exportSettings() }
      Button { text: "Import settings"; enabled: !page.controller.settingsTransferRunning; onClicked: page.controller.importSettings() }
      Button { text: "Undo last change"; enabled: !page.controller.settingsTransferRunning && page.controller.settingsUndoAvailable; onClicked: page.controller.undoSettingsChange() }
      Item { Layout.fillWidth: true }
    }
    PrivacyMessageSurface { visible: page.controller.settingsTransferStatus !== ""; message: page.controller.settingsTransferStatus; kind: page.controller.settingsTransferStatus.indexOf("failed") !== -1 || page.controller.settingsTransferStatus.indexOf("invalid") !== -1 ? "error" : "info" }
  }
  SettingsSurface {
    id: statusLegendSettings
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Status legend" }
    Text { Layout.fillWidth: true; text: "● Active    ⊘ Disabled    … Verifying    ! Degraded    Idle uses no marker"; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    Text { Layout.fillWidth: true; text: "Color, opacity, text, and markers reinforce each other so status never depends on color alone."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
  }
  SettingsSurface {
    id: observerHealthSettings
    accent: page.controller.monitoringDegraded ? Color.urgent : page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Observer health" }
    Text { Layout.fillWidth: true; text: page.controller.monitoringTelemetryText(); textFormat: Text.PlainText; color: page.controller.monitoringDegraded ? Color.urgent : Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    Button { text: "Copy private diagnostics"; enabled: page.controller.privacyService !== null; tooltipText: "Copy health and timing data with application and device names redacted"; onClicked: page.controller.privacyService.copyDiagnostics(true) }
  }
}
