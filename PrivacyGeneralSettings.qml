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
    PrivacySettingToggle { controller: page.controller; settingKey: "showIdle"; label: "Show idle devices"; description: "Keep enabled privacy-device icons visible while idle." }
    PrivacySettingToggle { controller: page.controller; settingKey: "showControls"; label: "Show privacy controls"; description: "Show inline control switches and enable row actions." }
    PrivacySettingToggle { controller: page.controller; settingKey: "deduplicateApps"; label: "Deduplicate application names"; description: "List an application once when it owns several matching sessions." }
  }
}
