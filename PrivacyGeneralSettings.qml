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
    Toggle { Layout.fillWidth: true; label: "Show idle devices"; description: "Keep enabled privacy-device icons visible while idle."; checked: page.controller.setting("showIdle", true) === true; foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onClicked: page.controller.persistSettings({showIdle: !checked}) }
    Toggle { Layout.fillWidth: true; label: "Show privacy controls"; description: "Show inline control switches and enable row actions."; checked: page.controller.setting("showControls", true) === true; foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onClicked: page.controller.persistSettings({showControls: !checked}) }
    Toggle { Layout.fillWidth: true; label: "Deduplicate application names"; description: "List an application once when it owns several matching sessions."; checked: page.controller.setting("deduplicateApps", true) === true; foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onClicked: page.controller.persistSettings({deduplicateApps: !checked}) }
  }
}
