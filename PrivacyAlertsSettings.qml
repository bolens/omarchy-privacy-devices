pragma ComponentBehavior: Bound
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
    MultiSelect { objectName: "alertsNotificationKindsSetting"; Layout.fillWidth: true; label: "Activity notifications"; options: page.controller.kindOptions; values: Model.arraySetting(page.controller.setting("notificationKinds", ["microphone", "camera", "screen-share", "screen-recording", "location"]), []); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onChanged: function(values) { page.controller.persistSettings({notificationKinds: values}) } }
    PrivacySettingsGrid {
      responsiveWidth: Math.min(width, page.controller.configuredPanelWidth !== undefined ? page.controller.configuredPanelWidth : page.width)
      Layout.fillWidth: true
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      PrivacySettingToggle { objectName: "alertsNotifyOnActivityToggle"; controller: page.controller; settingKey: "notifyOnActivity"; label: "Activity started"; description: "Notify when selected activity begins." }
      PrivacySettingToggle { objectName: "alertsNotifyOnStopToggle"; controller: page.controller; settingKey: "notifyOnStop"; fallback: false; label: "Activity stopped"; description: "Notify when activity ends, including duration." }
      PrivacySettingToggle { objectName: "alertsNotifyOnControlChangesToggle"; Layout.columnSpan: page.controller.popupWidth === "wide" ? 2 : 1; controller: page.controller; settingKey: "notifyOnControlChanges"; label: "Control results"; description: "Notify when privacy-control changes succeed or fail." }
      PrivacySettingToggle { objectName: "alertsNotifyOnObserverHealthToggle"; Layout.columnSpan: page.controller.popupWidth === "wide" ? 2 : 1; controller: page.controller; settingKey: "notifyOnObserverHealth"; fallback: false; label: "Observer health"; description: "Notify once when an observer degrades or recovers; repeated changes are rate limited." }
    }
    Text { Layout.fillWidth: true; text: "Mute alerts for exact application names"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    RowLayout {
      Layout.fillWidth: true
      TextField { id: suppressedAppsEditor; objectName: "alertsSuppressedAppsEditor"; Layout.fillWidth: true; text: Model.arraySetting(page.controller.setting("notificationSuppressedApps", []), []).join(", "); placeholderText: "Firefox, OBS"; foreground: Color.popups.text; accent: page.controller.activeThemeColor; font.family: Style.font.family; onAccepted: page.controller.persistSettings({notificationSuppressedApps: page.controller.commaList(text)}) }
      Button { objectName: "alertsSaveSuppressedAppsButton"; iconText: "󰆓"; tooltipText: "Save muted applications"; horizontalPadding: Style.spacing.controlGap; bordered: true; background: Util.alpha(page.controller.activeThemeColor, 0.06); onClicked: page.controller.persistSettings({notificationSuppressedApps: page.controller.commaList(suppressedAppsEditor.text)}) }
    }
    RowLayout {
      Layout.fillWidth: true
      Text { Layout.fillWidth: true; text: "Check notification delivery without changing activity or controls."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
      Button { objectName: "alertsSendTestButton"; iconText: "󰂚"; tooltipText: "Send test notification"; horizontalPadding: Style.spacing.controlGap; bordered: true; background: Util.alpha(page.controller.activeThemeColor, 0.06); enabled: page.controller.privacyService !== null; onClicked: page.controller.privacyService.sendTestNotification() }
    }
  }
}
