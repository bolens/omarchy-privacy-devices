import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

GridLayout {
  id: page
  required property var controller
  property var sectionItems: ({"bar-layout": barLayoutSettings,"theme-colors": themeColorsSettings,"status-presentation": statusPresentationSettings})
  columns: width >= Style.space(650) ? 2 : 1
  columnSpacing: Style.spacing.md
  rowSpacing: Style.spacing.md
  SettingsSurface {
    id: barLayoutSettings
    Layout.fillWidth: true
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Bar layout" }
    GridLayout {
      Layout.fillWidth: true
      columns: barLayoutSettings.width >= Style.space(420) ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      Dropdown { Layout.fillWidth: true; label: "Bar presentation"; options: ["icons", "active-count", "active-only"]; value: String(page.controller.setting("displayMode", "icons")); onChanged: function(value) { page.controller.persistSettings({displayMode: value}) } }
      NumberField { Layout.fillWidth: true; label: "Icon scale (%)"; from: 75; to: 150; stepSize: 5; value: Math.round(page.controller.barIconScale * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({barIconScale: Number(value) / 100}) } }
      IntegerSetting { controller: page.controller; settingKey: "barItemSpacing"; label: "Space between bar items"; minimum: 0; maximum: 12; fallback: 0 }
      IntegerSetting { controller: page.controller; settingKey: "barItemPadding"; label: "Bar item padding"; minimum: 2; maximum: 12; fallback: 5 }
    }
  }
  SettingsSurface {
    id: themeColorsSettings
    Layout.fillWidth: true
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Theme colors" }
    Text { Layout.fillWidth: true; text: "Blocked request applies when an application session remains observable while its device control is blocked. Some backends suppress the request entirely."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    GridLayout {
      Layout.fillWidth: true
      columns: themeColorsSettings.width >= Style.space(420) ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      Dropdown { objectName: "activeColorRoleSetting"; Layout.fillWidth: true; label: "In use"; options: ["accent", "bar-active", "urgent", "foreground", "muted"]; value: String(page.controller.setting("activeColorRole", "accent")); onChanged: function(value) { page.controller.persistSettings({activeColorRole: value}) } }
      NumberField { objectName: "activeOpacitySetting"; Layout.fillWidth: true; label: "In-use opacity (%)"; from: 10; to: 100; stepSize: 5; value: Math.round(Number(page.controller.setting("activeOpacity", 1)) * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({activeOpacity: Number(value) / 100}) } }
      Dropdown { objectName: "inactiveColorRoleSetting"; Layout.fillWidth: true; label: "Enabled and idle"; options: ["foreground", "bar-active", "muted", "accent", "urgent"]; value: String(page.controller.setting("inactiveColorRole", "foreground")); onChanged: function(value) { page.controller.persistSettings({inactiveColorRole: value}) } }
      NumberField { objectName: "idleOpacitySetting"; Layout.fillWidth: true; label: "Enabled-idle opacity (%)"; from: 10; to: 100; stepSize: 5; value: Math.round(Number(page.controller.setting("idleOpacity", 0.45)) * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({idleOpacity: Number(value) / 100}) } }
      Dropdown { objectName: "disabledColorRoleSetting"; Layout.fillWidth: true; label: "Disabled"; options: ["muted", "urgent", "accent", "foreground", "bar-active"]; value: String(page.controller.setting("disabledColorRole", "muted")); onChanged: function(value) { page.controller.persistSettings({disabledColorRole: value}) } }
      NumberField { objectName: "disabledOpacitySetting"; Layout.fillWidth: true; label: "Disabled opacity (%)"; from: 25; to: 100; stepSize: 5; value: Math.round(page.controller.disabledOpacity * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({disabledOpacity: Number(value) / 100}) } }
      Dropdown { objectName: "blockedActiveColorRoleSetting"; Layout.fillWidth: true; label: "Blocked request"; options: ["urgent", "accent", "bar-active", "muted", "foreground"]; value: String(page.controller.setting("blockedActiveColorRole", "urgent")); onChanged: function(value) { page.controller.persistSettings({blockedActiveColorRole: value}) } }
      NumberField { objectName: "blockedActiveOpacitySetting"; Layout.fillWidth: true; label: "Blocked-request opacity (%)"; from: 10; to: 100; stepSize: 5; value: Math.round(Number(page.controller.setting("blockedActiveOpacity", 1)) * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({blockedActiveOpacity: Number(value) / 100}) } }
    }
  }
  SettingsSurface {
    id: statusPresentationSettings
    Layout.fillWidth: true
    Layout.columnSpan: page.columns
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Status presentation" }
    GridLayout {
      Layout.fillWidth: true
      columns: statusPresentationSettings.width >= Style.space(420) ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      Dropdown { Layout.fillWidth: true; label: "Bar status markers"; options: ["symbols", "letters", "custom", "off"]; value: page.controller.statusMarkerMode; onChanged: function(value) { page.controller.persistSettings({statusMarkerMode: value}) } }
      Dropdown { Layout.fillWidth: true; label: "Marker position"; options: ["after", "before"]; value: page.controller.barMarkerPosition; onChanged: function(value) { page.controller.persistSettings({barMarkerPosition: value}) } }
    }
    GridLayout {
      visible: page.controller.statusMarkerMode === "custom"
      Layout.fillWidth: true
      columns: statusPresentationSettings.width >= Style.space(420) ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      PrivacyMarkerGlyphEditor { controller: page.controller; settingKey: "barActiveMarkerIcon"; label: "Active marker icon"; fallback: "●" }
      PrivacyMarkerGlyphEditor { controller: page.controller; settingKey: "barDisabledMarkerIcon"; label: "Disabled marker icon"; fallback: "⊘" }
      PrivacyMarkerGlyphEditor { controller: page.controller; settingKey: "barPendingMarkerIcon"; label: "Verifying marker icon"; fallback: "…" }
      PrivacyMarkerGlyphEditor { controller: page.controller; settingKey: "barDegradedMarkerIcon"; label: "Degraded marker icon"; fallback: "!" }
    }
    GridLayout {
      Layout.fillWidth: true
      columns: statusPresentationSettings.width >= Style.space(600) ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      PrivacySettingToggle { controller: page.controller; settingKey: "showBarActiveMarker"; label: "Active marker"; description: "Mark active device icons." }
      PrivacySettingToggle { controller: page.controller; settingKey: "showBarDisabledMarker"; label: "Disabled marker"; description: "Mark blocked or muted devices." }
      PrivacySettingToggle { controller: page.controller; settingKey: "showBarPendingMarker"; label: "Verifying marker"; description: "Mark controls awaiting confirmation." }
      PrivacySettingToggle { controller: page.controller; settingKey: "showBarDegradedMarker"; label: "Degraded marker"; description: "Mark unhealthy monitoring sources." }
    }
    GridLayout {
      Layout.fillWidth: true
      columns: statusPresentationSettings.width >= Style.space(420) ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      Dropdown { Layout.fillWidth: true; label: "Popup state pills"; options: ["filled", "outline", "minimal"]; value: page.controller.statePillStyle; onChanged: function(value) { page.controller.persistSettings({statePillStyle: value}) } }
      Dropdown { Layout.fillWidth: true; label: "Popup density"; options: ["comfortable", "compact"]; value: page.controller.popupDensity; onChanged: function(value) { page.controller.persistSettings({popupDensity: value}) } }
    }
    GridLayout {
      Layout.fillWidth: true
      columns: statusPresentationSettings.width >= Style.space(420) ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      Dropdown { Layout.fillWidth: true; label: "Popup layout"; options: ["adaptive", "list", "grid"]; value: page.controller.popupLayout; onChanged: function(value) { page.controller.persistSettings({popupLayout: value}) } }
      Dropdown { Layout.fillWidth: true; label: "Popup width"; options: ["narrow", "standard", "wide"]; value: page.controller.popupWidth; onChanged: function(value) { page.controller.persistSettings({popupWidth: value}) } }
      NumberField { Layout.fillWidth: true; label: "Popup item scale (%)"; from: 85; to: 130; stepSize: 5; value: Math.round(page.controller.popupItemScale * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({popupItemScale: Number(value) / 100}) } }
      NumberField { Layout.fillWidth: true; label: "Popup idle visibility (%)"; from: 45; to: 100; stepSize: 5; value: Math.round(page.controller.popupIdleOpacity * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({popupIdleOpacity: Number(value) / 100}) } }
    }
    GridLayout {
      Layout.fillWidth: true
      columns: statusPresentationSettings.width >= Style.space(600) ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      PrivacySettingToggle { controller: page.controller; settingKey: "showStatePills"; label: "State pills"; description: "Show textual state beside popup items." }
      PrivacySettingToggle { controller: page.controller; settingKey: "showSessionCounts"; label: "Popup session counts"; description: "Badge items shared by several sessions." }
      PrivacySettingToggle { controller: page.controller; settingKey: "showBarSessionCounts"; label: "Bar session counts"; description: "Append counts to shared bar items." }
      PrivacySettingToggle { controller: page.controller; settingKey: "animatePending"; label: "Animate verification"; description: "Pulse items awaiting observed confirmation." }
    }
    IntegerSetting { controller: page.controller; settingKey: "popupMaxHeight"; label: "Popup maximum height"; minimum: 360; maximum: 900; fallback: 620; stepSize: 20 }
  }
}
