import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

ColumnLayout {
  id: page
  required property var controller
  property var sectionItems: ({"behavior": behaviorSettings, "privacy-modes": modesSettings})
  property string newModeName: ""
  spacing: Style.spacing.md
  SettingsSurface {
    id: behaviorSettings
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Behavior" }
    MultiSelect { objectName: "generalEnabledKindsSetting"; Layout.fillWidth: true; label: "Monitored activity"; options: page.controller.kindOptions; values: Model.arraySetting(page.controller.setting("enabledKinds", Model.KINDS), Model.KINDS); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onChanged: function(values) { page.controller.persistSettings({enabledKinds: values}) } }
    PrivacySettingsGrid {
      responsiveWidth: Math.min(width, page.controller.configuredPanelWidth !== undefined ? page.controller.configuredPanelWidth : page.width)
      Layout.fillWidth: true
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      PrivacySettingToggle { objectName: "generalShowIdleToggle"; controller: page.controller; settingKey: "showIdle"; fallback: false; label: "Show idle activity icons"; description: "Keep activity icons visible while idle." }
      PrivacySettingToggle { objectName: "generalShowControlsToggle"; controller: page.controller; settingKey: "showControls"; label: "Show privacy controls"; description: "Show inline switches and row actions." }
      PrivacySettingToggle { objectName: "generalDeduplicateAppsToggle"; Layout.columnSpan: page.controller.popupWidth === "wide" ? 2 : 1; controller: page.controller; settingKey: "deduplicateApps"; label: "Deduplicate applications"; description: "List an app once when it owns several sessions." }
    }
  }
  SettingsSurface {
    id: modesSettings
    Layout.fillWidth: true
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Privacy modes" }
    Text { Layout.fillWidth: true; text: "Save the current allowed or blocked state of each available privacy control, then reapply it as one verified transaction."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    RowLayout {
      Layout.fillWidth: true
      TextField { id: modeNameField; objectName: "privacyModeNameField"; Layout.fillWidth: true; placeholderText: "Mode name"; foreground: Color.popups.text; accent: page.controller.activeThemeColor; font.family: Style.font.family; onTextChanged: page.newModeName = text }
      Button { objectName: "privacyModeSaveButton"; text: "Save current"; enabled: page.newModeName.trim() !== "" && page.controller.privacyService !== null; onClicked: { page.controller.savePrivacyMode(page.newModeName); modeNameField.text = "" } }
    }
    Repeater {
      model: Model.sanitizePrivacyModes(page.controller.setting("privacyModes", []))
      delegate: RowLayout {
        required property var modelData
        required property int index
        Layout.fillWidth: true
        Text { Layout.fillWidth: true; text: modelData.name; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body; font.weight: Font.DemiBold; elide: Text.ElideRight }
        Button { objectName: "privacyModeApply-" + index; text: "Apply"; enabled: page.controller.privacyService && page.controller.privacyService.privacyPresetState !== "applying" && page.controller.privacyService.privacyPresetState !== "restoring"; onClicked: page.controller.privacyService.requestPrivacyMode(modelData) }
        Button { objectName: "privacyModeDelete-" + index; iconText: "󰆴"; tooltipText: "Delete mode"; horizontalPadding: Style.spacing.controlGap; onClicked: page.controller.removePrivacyMode(index) }
      }
    }
  }
}
