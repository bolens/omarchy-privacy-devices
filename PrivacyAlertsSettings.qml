import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

ColumnLayout {
  id: page
  required property var controller
  property var sectionItems: ({"notifications": notificationSettings})
  spacing: Style.spacing.md
  SettingsSurface {
    id: notificationSettings
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Notifications" }
    MultiSelect { Layout.fillWidth: true; label: "Activity notifications"; options: page.controller.kindOptions; values: Model.arraySetting(page.controller.setting("notificationKinds", ["microphone", "camera", "screen-share", "screen-recording", "location"]), []); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onChanged: function(values) { page.controller.persistSettings({notificationKinds: values}) } }
    PrivacySettingToggle { controller: page.controller; settingKey: "notifyOnActivity"; label: "Activity started"; description: "Notify when selected privacy activity begins." }
    PrivacySettingToggle { controller: page.controller; settingKey: "notifyOnStop"; fallback: false; label: "Activity stopped"; description: "Notify when activity ends and include its duration." }
    PrivacySettingToggle { controller: page.controller; settingKey: "notifyOnControlChanges"; label: "Control results"; description: "Notify when privacy control changes succeed or fail." }
    Text { Layout.fillWidth: true; text: "Applications without alerts (comma-separated exact names)"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    RowLayout {
      Layout.fillWidth: true
      TextField { id: suppressedAppsEditor; Layout.fillWidth: true; text: Model.arraySetting(page.controller.setting("notificationSuppressedApps", []), []).join(", "); placeholderText: "Firefox, OBS"; foreground: Color.popups.text; accent: page.controller.activeThemeColor; font.family: Style.font.family; onAccepted: page.controller.persistSettings({notificationSuppressedApps: page.controller.commaList(text)}) }
      Button { text: "Save"; onClicked: page.controller.persistSettings({notificationSuppressedApps: page.controller.commaList(suppressedAppsEditor.text)}) }
    }
  }
}
