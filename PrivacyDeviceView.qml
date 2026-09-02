pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

DeviceSettingsEditor {
  id: view

  readonly property var root: controller
  readonly property var confirmationState: controller.confirmationController
  readonly property var settingsMutationController: controller.settingsMutationControl
  readonly property alias labelEditorControl: labelEditor
  readonly property alias iconEditorControl: iconEditor

  function syncEditors() {
    confirmationState.clear()
    if (!root.editingKind) return
    labelEditor.text = root.labelFor(root.editingKind)
    iconEditor.text = root.iconFor(root.editingKind)
    if (backendSettings.item) backendSettings.item.syncEditors()
  }

  visible: root.editingKind !== "" && !root.showingGlobalSettings && !root.showingHistory
  onBackRequested: root.editingKind = ""

  PrivacyMessageSurface {
    visible: view.root.settingsMutationMessage !== ""
    message: view.root.settingsMutationMessage
    kind: view.settingsMutationController.status === "failed" ? "error" : (view.settingsMutationController.status === "saved" ? "success" : "info")
  }

  SettingsSurface {
    Layout.fillWidth: true
    accent: view.root.itemColor(view.root.item(view.root.editingKind))
    PanelSectionHeader { Layout.fillWidth: true; text: "Bar preview" }
    RowLayout {
      id: previewRow
      Layout.fillWidth: true
      Text {
        text: view.root.barItemText(view.root.item(view.root.editingKind))
        textFormat: Text.PlainText
        color: view.root.itemColor(view.root.item(view.root.editingKind))
        font.family: Style.font.family
        font.pixelSize: Style.font.icon
      }
      Text {
        Layout.fillWidth: true
        text: view.root.labelFor(view.root.editingKind)
        textFormat: Text.PlainText
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.weight: Font.DemiBold
      }
    }
  }

  AudioEndpointSettings {
    visible: view.root.isAudioControl({kind: view.root.editingKind})
    controller: view.root
  }

  SettingsSurface {
    id: appearanceSurface
    accent: view.root.activeThemeColor
    property bool labelDirty: labelEditor.text.trim() !== view.root.labelFor(view.root.editingKind)
    property bool iconDirty: iconEditor.text !== view.root.iconFor(view.root.editingKind)
    PanelSectionHeader { Layout.fillWidth: true; text: "Appearance" }
    Text {
      Layout.fillWidth: true
      text: appearanceSurface.labelDirty || appearanceSurface.iconDirty ? "Unsaved changes" : (view.root.deviceAppearanceCustomized(view.root.editingKind) ? "Customized" : "Using global defaults")
      textFormat: Text.PlainText
      color: appearanceSurface.labelDirty || appearanceSurface.iconDirty ? Color.accent : Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
    GridLayout {
      Layout.fillWidth: true
      columns: view.root.popupWidth === "wide" ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.xs
        Text { Layout.fillWidth: true; text: "Display label"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
        RowLayout {
          Layout.fillWidth: true
          TextField { id: labelEditor; Layout.fillWidth: true; placeholderText: "Display label"; text: view.root.editingKind ? view.root.labelFor(view.root.editingKind) : ""; maximumLength: 128; foreground: Color.popups.text; accent: view.root.activeThemeColor; font.family: Style.font.family; onAccepted: view.root.persistLabel(view.root.editingKind, text) }
          Button { objectName: "deviceLabelSaveButton"; iconText: "󰆓"; bordered: true; tooltipText: "Save display label"; horizontalPadding: Style.spacing.controlGap; enabled: appearanceSurface.labelDirty; onClicked: view.root.persistLabel(view.root.editingKind, labelEditor.text) }
        }
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.xs
        Text { Layout.fillWidth: true; text: "Device icon"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
        RowLayout {
          Layout.fillWidth: true
          TextField { id: iconEditor; Layout.fillWidth: true; placeholderText: "Icon"; text: view.root.editingKind ? view.root.iconFor(view.root.editingKind) : ""; maximumLength: 8; foreground: Color.popups.text; accent: view.root.activeThemeColor; font.family: Style.font.family; onAccepted: view.root.persistIcon(view.root.editingKind, text) }
          Button { objectName: "deviceIconSaveButton"; iconText: "󰆓"; bordered: true; tooltipText: "Save device icon"; horizontalPadding: Style.spacing.controlGap; enabled: appearanceSurface.iconDirty; onClicked: view.root.persistIcon(view.root.editingKind, iconEditor.text) }
        }
      }
    }

    GridLayout {
      Layout.fillWidth: true
      columns: view.root.popupWidth === "wide" ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      Dropdown {
        Layout.fillWidth: true
        label: "In-use color"
        options: view.root.deviceColorRoleOptions
        value: view.root.itemColorOverrideRole(view.root.editingKind, "active")
        onChanged: function(value) { view.root.persistItemColor(view.root.editingKind, "active", value) }
      }
      Dropdown {
        Layout.fillWidth: true
        label: "Idle color"
        options: view.root.deviceColorRoleOptions
        value: view.root.itemColorOverrideRole(view.root.editingKind, "inactive")
        onChanged: function(value) { view.root.persistItemColor(view.root.editingKind, "inactive", value) }
      }
      Dropdown {
        Layout.fillWidth: true
        label: "Disabled color"
        options: view.root.deviceColorRoleOptions
        value: view.root.itemColorOverrideRole(view.root.editingKind, "disabled")
        onChanged: function(value) { view.root.persistItemColor(view.root.editingKind, "disabled", value) }
      }
      Dropdown {
        visible: view.root.isPreventativeControl({kind: view.root.editingKind}) || view.root.isAudioControl({kind: view.root.editingKind})
        Layout.fillWidth: true
        label: "Blocked-request color"
        options: view.root.deviceColorRoleOptions
        value: view.root.itemColorOverrideRole(view.root.editingKind, "blocked")
        onChanged: function(value) { view.root.persistItemColor(view.root.editingKind, "blocked", value) }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      NumberField {
        Layout.fillWidth: true
        label: "Idle opacity (%)"
        from: 10
        to: 100
        stepSize: 5
        value: Math.round(view.root.itemIdleOpacity(view.root.editingKind) * 100)
        foreground: Color.popups.text
        accent: view.root.activeThemeColor
        fontFamily: Style.font.family
        onModified: function(value) { view.root.persistItemIdleOpacity(view.root.editingKind, value) }
      }
      Button {
        objectName: "deviceIdleOpacityDefaultButton"
        iconText: "󰑐"
        tooltipText: "Use global idle opacity"
        horizontalPadding: Style.spacing.controlGap
        enabled: Model.hasItemOverride(view.root.effectiveSettings, "itemIdleOpacity", view.root.editingKind)
        onClicked: view.root.persistItemIdleOpacity(view.root.editingKind, null)
      }
    }

    Dropdown {
      Layout.fillWidth: true
      label: "Show status markers for this device"
      options: view.root.deviceVisibilityOptions
      value: view.root.itemOverrideMode("itemStatusMarkerVisibility", view.root.editingKind)
      onChanged: function(value) { view.root.persistItemStatusMarker(view.root.editingKind, value) }
    }
    RowLayout {
      Layout.fillWidth: true
      Text { Layout.fillWidth: true; text: "Global status-marker rules still apply when this device is set to show."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
      Button { objectName: "deviceGlobalMarkerSettingsButton"; iconText: "󰒓"; tooltipText: "Open global marker settings"; horizontalPadding: Style.spacing.controlGap; onClicked: view.root.showGlobalSettings("appearance", "status-presentation") }
    }
  }

  SettingsSurface {
    accent: view.root.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Bar placement" }
    RowLayout {
      Layout.fillWidth: true
      Button {
        objectName: "deviceMoveLeftButton"
        iconText: "󰅁"
        tooltipText: "Move device left"
        horizontalPadding: Style.spacing.controlGap
        enabled: view.root.canMoveItem(view.root.editingKind, -1)
        onClicked: view.root.moveItem(view.root.editingKind, -1)
      }
      Button {
        objectName: "deviceMoveRightButton"
        iconText: "󰅂"
        tooltipText: "Move device right"
        horizontalPadding: Style.spacing.controlGap
        enabled: view.root.canMoveItem(view.root.editingKind, 1)
        onClicked: view.root.moveItem(view.root.editingKind, 1)
      }
      Item { Layout.fillWidth: true }
    }
    Dropdown {
      Layout.fillWidth: true
      label: "Show while idle"
      options: view.root.deviceVisibilityOptions
      value: view.root.itemOverrideMode("itemIdleVisibility", view.root.editingKind)
      onChanged: function(value) { view.root.persistItemIdleVisibility(view.root.editingKind, value) }
    }
  }

  SettingsSurface {
    visible: view.root.editingDevices.length > 0
    Layout.fillWidth: true
    accent: view.root.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Detected hardware" }
    Repeater {
      model: view.root.editingDevices
      delegate: ColumnLayout {
        id: deviceRow
        required property string modelData
        Layout.fillWidth: true
        spacing: Style.spacing.xs
        Text { Layout.fillWidth: true; text: deviceRow.modelData; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; elide: Text.ElideMiddle }
        RowLayout {
          Layout.fillWidth: true
          TextField { id: deviceLabelEditor; Layout.fillWidth: true; text: view.root.deviceLabel(deviceRow.modelData); placeholderText: "Friendly device name"; maximumLength: 128; foreground: Color.popups.text; accent: view.root.activeThemeColor; font.family: Style.font.family; onAccepted: view.root.persistDeviceLabel(deviceRow.modelData, text) }
          Button { objectName: "deviceHardwareNameSave-" + deviceRow.index; iconText: "󰆓"; tooltipText: "Save hardware name"; horizontalPadding: Style.spacing.controlGap; enabled: deviceLabelEditor.text.trim() !== view.root.deviceLabel(deviceRow.modelData); onClicked: view.root.persistDeviceLabel(deviceRow.modelData, deviceLabelEditor.text) }
        }
      }
    }
  }

  SettingsSurface {
    visible: view.root.editingApplications.length > 0
    Layout.fillWidth: true
    accent: view.root.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Live inspection" }
    Text { Layout.fillWidth: true; text: "Copy a live application target into X-Ray or another process inspector. Process IDs are never added to retained history."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    Repeater {
      model: view.root.editingApplications
      delegate: RowLayout {
        id: inspectionRow
        required property string modelData
        required property int index
        Layout.fillWidth: true
        Text { Layout.fillWidth: true; text: inspectionRow.modelData; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body; elide: Text.ElideRight }
        Button { objectName: "inspectionTargetCopy-" + inspectionRow.index; iconText: "󰆏"; tooltipText: "Copy inspection target"; horizontalPadding: Style.spacing.controlGap; onClicked: view.root.privacyService.copyInspectionTarget(inspectionRow.modelData) }
      }
    }
    PrivacyMessageSurface { visible: view.root.privacyService && view.root.privacyService.inspectionMessage !== ""; message: view.root.privacyService ? view.root.privacyService.inspectionMessage : ""; kind: "success" }
  }

  Loader {
    id: backendSettings
    active: view.root.editingKind === "screen-recording" || view.root.editingKind === "screenshot" || view.root.isAudioControl({kind: view.root.editingKind})
    Layout.fillWidth: true
    sourceComponent: Component { PrivacyDeviceBackendSettings { controller: root } }
  }

  DeviceDiagnostics { controller: view.root; kind: view.root.editingKind }

  SettingsSurface {
    id: resetSurface
    Layout.fillWidth: true
    accent: view.root.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Reset device appearance" }
    RowLayout {
      Layout.fillWidth: true
      Button {
        text: "Reset device appearance"
        tooltipText: "Restore the default label, icon, colors, idle visibility, idle opacity, and status-marker visibility"
        onClicked: {
          view.confirmationState.clear()
          view.root.resetItemSettings(view.root.editingKind)
          iconEditor.text = view.root.iconFor(view.root.editingKind)
          labelEditor.text = view.root.labelFor(view.root.editingKind)
        }
      }
      Button {
        visible: view.root.editingKind === "screen-recording" || view.root.editingKind === "screenshot" || view.root.isAudioControl({kind: view.root.editingKind})
        text: view.confirmationState.pending === "backend" ? "Confirm shared backend reset" : (view.root.isAudioControl({kind: view.root.editingKind}) ? "Reset shared backend" : "Reset backend")
        tooltipText: view.root.isAudioControl({kind: view.root.editingKind}) ? "Affects microphone and audio output" : "Restore this device's default backend"
        onClicked: {
          if (view.root.isAudioControl({kind: view.root.editingKind}) && !view.confirmationState.request("backend")) return
          view.root.resetDeviceBackend(view.root.editingKind)
          view.confirmationState.clear()
        }
      }
    }
    Button {
      text: view.confirmationState.pending === "all" ? "Confirm reset all" : "Reset all device settings"
      onClicked: {
        if (view.root.isAudioControl({kind: view.root.editingKind}) && !view.confirmationState.request("all")) return
        view.root.resetAllDeviceSettings(view.root.editingKind)
        iconEditor.text = view.root.iconFor(view.root.editingKind)
        labelEditor.text = view.root.labelFor(view.root.editingKind)
        view.confirmationState.clear()
      }
    }
  }
}
