import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

ColumnLayout {
  id: page
  required property var controller
  property var sectionItems: ({"bar-layout": barLayoutSettings,"theme-colors": themeColorsSettings,"status-presentation": statusPresentationSettings})
  spacing: Style.spacing.md
  SettingsSurface {
    id: barLayoutSettings
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Bar layout" }
    Dropdown { Layout.fillWidth: true; label: "Bar presentation"; options: ["icons", "active-count", "active-only"]; value: String(page.controller.setting("displayMode", "icons")); onChanged: function(value) { page.controller.persistSettings({displayMode: value}) } }
    NumberField { label: "Icon scale (%)"; from: 75; to: 150; stepSize: 5; value: Math.round(page.controller.barIconScale * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({barIconScale: Number(value) / 100}) } }
    IntegerSetting { controller: page.controller; settingKey: "barItemSpacing"; label: "Space between bar items"; minimum: 0; maximum: 12; fallback: 0 }
    IntegerSetting { controller: page.controller; settingKey: "barItemPadding"; label: "Bar item padding"; minimum: 2; maximum: 12; fallback: 5 }
    NumberField { label: "Default idle opacity (%)"; from: 10; to: 100; stepSize: 5; value: Math.round(Number(page.controller.setting("idleOpacity", 0.45)) * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({idleOpacity: Number(value) / 100}) } }
  }
  SettingsSurface {
    id: themeColorsSettings
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Theme colors" }
    Dropdown { Layout.fillWidth: true; label: "Active"; options: ["bar-active", "urgent", "accent", "foreground"]; value: String(page.controller.setting("activeColorRole", "bar-active")); onChanged: function(value) { page.controller.persistSettings({activeColorRole: value}) } }
    Dropdown { Layout.fillWidth: true; label: "Inactive"; options: ["muted", "foreground", "accent"]; value: String(page.controller.setting("inactiveColorRole", "muted")); onChanged: function(value) { page.controller.persistSettings({inactiveColorRole: value}) } }
    Dropdown { Layout.fillWidth: true; label: "Disabled"; options: ["urgent", "muted", "accent", "foreground", "bar-active"]; value: String(page.controller.setting("disabledColorRole", "urgent")); onChanged: function(value) { page.controller.persistSettings({disabledColorRole: value}) } }
    NumberField { label: "Disabled opacity (%)"; from: 25; to: 100; stepSize: 5; value: Math.round(page.controller.disabledOpacity * 100); foreground: Color.popups.text; accent: page.controller.activeThemeColor; fontFamily: Style.font.family; onModified: function(value) { page.controller.persistSettings({disabledOpacity: Number(value) / 100}) } }
  }
  SettingsSurface {
    id: statusPresentationSettings
    accent: page.controller.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Status presentation" }
    Dropdown { Layout.fillWidth: true; label: "Bar status markers"; options: ["symbols", "letters", "custom", "off"]; value: page.controller.statusMarkerMode; onChanged: function(value) { page.controller.persistSettings({statusMarkerMode: value}) } }
    Dropdown { Layout.fillWidth: true; label: "Marker position"; options: ["after", "before"]; value: page.controller.barMarkerPosition; onChanged: function(value) { page.controller.persistSettings({barMarkerPosition: value}) } }
    PrivacyMarkerGlyphEditor { visible: page.controller.statusMarkerMode === "custom"; controller: page.controller; settingKey: "barActiveMarkerIcon"; label: "Active marker icon"; fallback: "●" }
    PrivacyMarkerGlyphEditor { visible: page.controller.statusMarkerMode === "custom"; controller: page.controller; settingKey: "barDisabledMarkerIcon"; label: "Disabled marker icon"; fallback: "⊘" }
    PrivacyMarkerGlyphEditor { visible: page.controller.statusMarkerMode === "custom"; controller: page.controller; settingKey: "barPendingMarkerIcon"; label: "Verifying marker icon"; fallback: "…" }
    PrivacyMarkerGlyphEditor { visible: page.controller.statusMarkerMode === "custom"; controller: page.controller; settingKey: "barDegradedMarkerIcon"; label: "Degraded marker icon"; fallback: "!" }
    PrivacySettingToggle { controller: page.controller; settingKey: "showBarActiveMarker"; label: "Show active status marker"; description: "Show the active marker beside active device icons in the bar." }
    PrivacySettingToggle { controller: page.controller; settingKey: "showBarDisabledMarker"; label: "Show disabled status marker"; description: "Show the disabled marker beside blocked or muted device icons in the bar." }
    PrivacySettingToggle { controller: page.controller; settingKey: "showBarPendingMarker"; label: "Show verifying status marker"; description: "Show the verifying marker while a control action is pending." }
    PrivacySettingToggle { controller: page.controller; settingKey: "showBarDegradedMarker"; label: "Show degraded status marker"; description: "Show the degraded marker when a monitoring source is unhealthy." }
    Dropdown { Layout.fillWidth: true; label: "Popup state pills"; options: ["filled", "outline", "minimal"]; value: page.controller.statePillStyle; onChanged: function(value) { page.controller.persistSettings({statePillStyle: value}) } }
    Dropdown { Layout.fillWidth: true; label: "Popup density"; options: ["comfortable", "compact"]; value: page.controller.popupDensity; onChanged: function(value) { page.controller.persistSettings({popupDensity: value}) } }
    PrivacySettingToggle { controller: page.controller; settingKey: "showStatePills"; label: "Show state pills"; description: "Keep textual state visible beside each popup row." }
    PrivacySettingToggle { controller: page.controller; settingKey: "showSessionCounts"; label: "Show popup session counts"; description: "Display a badge when several sessions share a popup item." }
    PrivacySettingToggle { controller: page.controller; settingKey: "showBarSessionCounts"; label: "Show bar session counts"; description: "Append a count when several sessions share a bar item." }
    PrivacySettingToggle { controller: page.controller; settingKey: "animatePending"; label: "Animate verification"; description: "Pulse pending bar items until observed state confirms the action." }
    IntegerSetting { controller: page.controller; settingKey: "popupMaxHeight"; label: "Popup maximum height"; minimum: 360; maximum: 900; fallback: 620; stepSize: 20 }
  }
}
