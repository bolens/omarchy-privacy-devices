import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

ColumnLayout {
  id: page
  required property var controller
  property var sectionItems: ({"behavior": behaviorSettings})
  spacing: Style.spacing.md
  SettingsSurface {
    id: behaviorSettings
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Behavior" }
    MultiSelect { Layout.fillWidth: true; label: "Monitored activity"; options: page.controller.kindOptions; values: Model.arraySetting(page.controller.setting("enabledKinds", Model.KINDS), Model.KINDS); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onChanged: function(values) { page.controller.persistSettings({enabledKinds: values}) } }
    GridLayout {
      Layout.fillWidth: true
      columns: page.controller.popupWidth === "wide" ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      PrivacySettingToggle { controller: page.controller; settingKey: "showIdle"; label: "Show idle devices"; description: "Keep device icons visible while idle." }
      PrivacySettingToggle { controller: page.controller; settingKey: "showControls"; label: "Show privacy controls"; description: "Show inline switches and row actions." }
      PrivacySettingToggle { Layout.columnSpan: page.controller.popupWidth === "wide" ? 2 : 1; controller: page.controller; settingKey: "deduplicateApps"; label: "Deduplicate applications"; description: "List an app once when it owns several sessions." }
    }
  }
}
