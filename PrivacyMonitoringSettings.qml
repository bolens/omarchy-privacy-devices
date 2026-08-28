import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

GridLayout {
  id: page
  required property var controller
  property var sectionItems: ({"enhanced-coverage": enhancedCoverageSettings,"fallback-polling": fallbackPollingSettings,"private-data": privateDataSettings,"status-legend": statusLegendSettings,"observer-health": observerHealthSettings})
  columns: width >= Style.space(650) ? 2 : 1
  columnSpacing: Style.spacing.md
  rowSpacing: Style.spacing.md
  SettingsSurface {
    id: enhancedCoverageSettings
    Layout.fillWidth: true
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Enhanced coverage" }
    MultiSelect { objectName: "monitoringBlockableKindsSetting"; Layout.fillWidth: true; label: "Preventative controls"; options: page.controller.kindOptions.filter(function(option) { return ["camera", "screen-share", "location"].indexOf(option.value) !== -1 }); values: Model.arraySetting(page.controller.setting("blockableKinds", ["camera", "screen-share", "location"]), []); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onChanged: function(values) { page.controller.persistSettings({blockableKinds: values}) } }
    PrivacySettingsGrid {
      responsiveWidth: Math.min(width, page.controller.configuredPanelWidth !== undefined ? page.controller.configuredPanelWidth : page.width)
      Layout.fillWidth: true
      breakpoint: Style.space(600)
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      PrivacySettingToggle { objectName: "monitoringDirectDeviceToggle"; controller: page.controller; settingKey: "directDeviceMonitoring"; fallback: false; label: "Direct-device monitoring"; description: "Find apps that bypass PipeWire through same-user device handles." }
      PrivacySettingToggle { objectName: "monitoringInferredAttributionToggle"; controller: page.controller; settingKey: "showInferredAttribution"; label: "Show inferred attribution"; description: "Show heuristic app and device names alongside activity." }
    }
    IntegerSetting { controller: page.controller; controlObjectName: "monitoringDirectPollSetting"; settingKey: "directDevicePollSeconds"; label: "Direct-device heartbeat, seconds"; minimum: 2; maximum: 60; fallback: 5 }
  }
  SettingsSurface {
    id: fallbackPollingSettings
    Layout.fillWidth: true
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Fallback polling" }
    PrivacySettingsGrid {
      responsiveWidth: Math.min(width, page.controller.configuredPanelWidth !== undefined ? page.controller.configuredPanelWidth : page.width)
      Layout.fillWidth: true
      breakpoint: Style.space(360)
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      IntegerSetting { controller: page.controller; controlObjectName: "monitoringLocationPollSetting"; settingKey: "locationPollSeconds"; label: "Location interval, s"; minimum: 5; maximum: 300; fallback: 15; stepSize: 5 }
      IntegerSetting { controller: page.controller; controlObjectName: "monitoringRecordingPollSetting"; settingKey: "recordingPollSeconds"; label: "Recorder interval, s"; minimum: 1; maximum: 60; fallback: 2 }
    }
    Text { Layout.fillWidth: true; text: "PipeWire activity remains event-backed. These intervals affect only enhanced and fallback observers."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
  }
  SettingsSurface {
    id: privateDataSettings
    Layout.fillWidth: true
    Layout.columnSpan: page.columns
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Private data" }
    PrivacySettingToggle { objectName: "historyEnabledToggle"; controller: page.controller; settingKey: "historyEnabled"; fallback: false; label: "Keep recent activity"; description: "Store private metadata for seven days or 100 completed sessions." }
    Button { objectName: "privateDataClearHistoryButton"; text: "Clear stored history"; bordered: true; background: Util.alpha(page.controller.activeThemeColor, 0.06); enabled: page.controller.privacyService !== null; onClicked: page.controller.privacyService.clearHistory() }
    Text { Layout.fillWidth: true; text: "Export or restore a versioned settings file stored privately in your user data directory."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.spacing.sm
      Button { objectName: "privateDataExportSettingsButton"; iconText: "󰈇"; tooltipText: "Export settings"; horizontalPadding: Style.spacing.controlGap; bordered: true; background: Util.alpha(page.controller.activeThemeColor, 0.06); enabled: !page.controller.settingsTransferRunning; onClicked: page.controller.exportSettings() }
      Button { objectName: "privateDataImportSettingsButton"; iconText: "󰈆"; tooltipText: "Import the previously exported settings file"; horizontalPadding: Style.spacing.controlGap; bordered: true; background: Util.alpha(page.controller.activeThemeColor, 0.06); enabled: !page.controller.settingsTransferRunning; onClicked: page.controller.importSettings() }
      Button { objectName: "privateDataUndoSettingsButton"; iconText: "󰕌"; tooltipText: enabled ? "Undo the last settings change" : "No previous durable settings snapshot is available"; horizontalPadding: Style.spacing.controlGap; bordered: true; background: Util.alpha(page.controller.activeThemeColor, 0.06); enabled: !page.controller.settingsTransferRunning && page.controller.settingsUndoAvailable; onClicked: page.controller.undoSettingsChange() }
      Item { Layout.fillWidth: true }
    }
    PrivacyMessageSurface { visible: page.controller.settingsTransferStatus !== ""; message: page.controller.settingsTransferStatus; kind: page.controller.settingsTransferStatus.indexOf("failed") !== -1 || page.controller.settingsTransferStatus.indexOf("invalid") !== -1 ? "error" : "info" }
  }
  SettingsSurface {
    id: statusLegendSettings
    Layout.fillWidth: true
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Status legend" }
    Text { Layout.fillWidth: true; text: "● Active    ⊘ Disabled    … Verifying    ! Degraded    Idle uses no marker"; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    Text { Layout.fillWidth: true; text: "Color, opacity, text, and markers reinforce each other so status never depends on color alone."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
  }
  SettingsSurface {
    id: observerHealthSettings
    Layout.fillWidth: true
    accent: page.controller.monitoringDegraded ? Color.urgent : page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Observer health" }
    Text { Layout.fillWidth: true; text: page.controller.monitoringTelemetryText(); textFormat: Text.PlainText; color: page.controller.monitoringDegraded ? Color.urgent : Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.spacing.sm
      Button { objectName: "monitoringRunSelfTestButton"; iconText: "󰐊"; tooltipText: "Run monitoring self-test"; horizontalPadding: Style.spacing.controlGap; bordered: true; background: Util.alpha(page.controller.activeThemeColor, 0.06); enabled: page.controller.privacyService !== null; onClicked: page.controller.privacyService.runSelfTest() }
      Button { objectName: "monitoringSendTestAlertButton"; iconText: "󰂚"; tooltipText: "Send test alert"; horizontalPadding: Style.spacing.controlGap; bordered: true; background: Util.alpha(page.controller.activeThemeColor, 0.06); enabled: page.controller.privacyService !== null; onClicked: page.controller.privacyService.sendTestNotification() }
      Button { objectName: "monitoringCopySelfTestButton"; iconText: "󰆏"; tooltipText: "Copy self-test result"; horizontalPadding: Style.spacing.controlGap; bordered: true; background: Util.alpha(page.controller.activeThemeColor, 0.06); enabled: page.controller.privacyService !== null && page.controller.privacyService.selfTestResult.status !== "idle"; onClicked: page.controller.privacyService.copySelfTest() }
      Button { objectName: "monitoringCopyDiagnosticsButton"; iconText: "󰆍"; tooltipText: "Copy health and timing data with application and device names redacted"; horizontalPadding: Style.spacing.controlGap; bordered: true; background: Util.alpha(page.controller.activeThemeColor, 0.06); enabled: page.controller.privacyService !== null; onClicked: page.controller.privacyService.copyDiagnostics(true) }
      Item { Layout.fillWidth: true }
    }
    PrivacyMessageSurface {
      Layout.fillWidth: true
      visible: page.controller.privacyService !== null
      message: page.controller.privacyService ? page.controller.privacyService.selfTestResult.text : ""
      kind: page.controller.privacyService && page.controller.privacyService.selfTestResult.status === "attention" ? "error" : (page.controller.privacyService && page.controller.privacyService.selfTestResult.status === "passed" ? "success" : "info")
    }
  }
}
