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
      NumberField { Layout.fillWidth: true; label: "Idle opacity (%)"; from: 10; to: 100; stepSize: 5; value: Math.round(Number(page.controller.setting("idleOpacity", 0.45)) * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({idleOpacity: Number(value) / 100}) } }
    }
  }
  SettingsSurface {
    id: themeColorsSettings
    Layout.fillWidth: true
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Theme colors" }
    GridLayout {
      Layout.fillWidth: true
      columns: themeColorsSettings.width >= Style.space(420) ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      Dropdown { Layout.fillWidth: true; label: "Active"; options: ["bar-active", "urgent", "accent", "foreground"]; value: String(page.controller.setting("activeColorRole", "bar-active")); onChanged: function(value) { page.controller.persistSettings({activeColorRole: value}) } }
      Dropdown { Layout.fillWidth: true; label: "Inactive"; options: ["muted", "foreground", "accent"]; value: String(page.controller.setting("inactiveColorRole", "muted")); onChanged: function(value) { page.controller.persistSettings({inactiveColorRole: value}) } }
      Dropdown { Layout.fillWidth: true; label: "Disabled"; options: ["urgent", "muted", "accent", "foreground", "bar-active"]; value: String(page.controller.setting("disabledColorRole", "urgent")); onChanged: function(value) { page.controller.persistSettings({disabledColorRole: value}) } }
      NumberField { Layout.fillWidth: true; label: "Disabled opacity (%)"; from: 25; to: 100; stepSize: 5; value: Math.round(page.controller.disabledOpacity * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({disabledOpacity: Number(value) / 100}) } }
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
