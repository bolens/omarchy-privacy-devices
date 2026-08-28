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
    customScreenshotCommandEditor.text = String(root.setting("screenshotCustomCommand", ""))
    customScreenshotProcessEditor.text = String(root.setting("screenshotProcessName", ""))
    customRecorderProcessEditor.text = String(root.setting("recordingProcessName", ""))
    customRecorderStartEditor.text = String(root.setting("recordingCustomStartCommand", ""))
    customRecorderStopEditor.text = String(root.setting("recordingCustomStopCommand", ""))
  }

  visible: root.editingKind !== "" && !root.showingGlobalSettings && !root.showingHistory
  onBackRequested: root.editingKind = ""

  PrivacyMessageSurface {
    visible: root.settingsMutationMessage !== ""
    message: root.settingsMutationMessage
    kind: settingsMutationController.status === "failed" ? "error" : (settingsMutationController.status === "saved" ? "success" : "info")
  }

  SettingsSurface {
    Layout.fillWidth: true
    accent: root.itemColor(root.item(root.editingKind))
    PanelSectionHeader { Layout.fillWidth: true; text: "Bar preview" }
    RowLayout {
      id: previewRow
      Layout.fillWidth: true
      Text {
        text: root.barItemText(root.item(root.editingKind))
        textFormat: Text.PlainText
        color: root.itemColor(root.item(root.editingKind))
        font.family: Style.font.family
        font.pixelSize: Style.font.icon
      }
      Text {
        Layout.fillWidth: true
        text: root.labelFor(root.editingKind)
        textFormat: Text.PlainText
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.weight: Font.DemiBold
      }
    }
  }

  AudioEndpointSettings {
    visible: root.isAudioControl({kind: root.editingKind})
    controller: root
  }

  SettingsSurface {
    id: appearanceSurface
    accent: root.activeThemeColor
    property bool labelDirty: labelEditor.text.trim() !== root.labelFor(root.editingKind)
    property bool iconDirty: iconEditor.text !== root.iconFor(root.editingKind)
    PanelSectionHeader { Layout.fillWidth: true; text: "Appearance" }
    Text {
      Layout.fillWidth: true
      text: appearanceSurface.labelDirty || appearanceSurface.iconDirty ? "Unsaved changes" : (root.deviceAppearanceCustomized(root.editingKind) ? "Customized" : "Using global defaults")
      textFormat: Text.PlainText
      color: appearanceSurface.labelDirty || appearanceSurface.iconDirty ? Color.accent : Color.muted
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
    GridLayout {
      Layout.fillWidth: true
      columns: root.popupWidth === "wide" ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.xs
        Text { Layout.fillWidth: true; text: "Display label"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
        RowLayout {
          Layout.fillWidth: true
          TextField { id: labelEditor; Layout.fillWidth: true; placeholderText: "Display label"; text: root.editingKind ? root.labelFor(root.editingKind) : ""; maximumLength: 128; foreground: Color.popups.text; accent: root.activeThemeColor; font.family: Style.font.family; onAccepted: root.persistLabel(root.editingKind, text) }
          Button { text: "Save"; bordered: true; tooltipText: "Save display label"; enabled: appearanceSurface.labelDirty; onClicked: root.persistLabel(root.editingKind, labelEditor.text) }
        }
      }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.spacing.xs
        Text { Layout.fillWidth: true; text: "Device icon"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
        RowLayout {
          Layout.fillWidth: true
          TextField { id: iconEditor; Layout.fillWidth: true; placeholderText: "Icon"; text: root.editingKind ? root.iconFor(root.editingKind) : ""; maximumLength: 8; foreground: Color.popups.text; accent: root.activeThemeColor; font.family: Style.font.family; onAccepted: root.persistIcon(root.editingKind, text) }
          Button { text: "Save"; bordered: true; tooltipText: "Save device icon"; enabled: appearanceSurface.iconDirty; onClicked: root.persistIcon(root.editingKind, iconEditor.text) }
        }
      }
    }

    GridLayout {
      Layout.fillWidth: true
      columns: root.popupWidth === "wide" ? 2 : 1
      columnSpacing: Style.spacing.md
      rowSpacing: Style.spacing.md
      Dropdown {
        Layout.fillWidth: true
        label: "In-use color"
        options: root.deviceColorRoleOptions
        value: root.itemColorOverrideRole(root.editingKind, "active")
        onChanged: function(value) { root.persistItemColor(root.editingKind, "active", value) }
      }
      Dropdown {
        Layout.fillWidth: true
        label: "Idle color"
        options: root.deviceColorRoleOptions
        value: root.itemColorOverrideRole(root.editingKind, "inactive")
        onChanged: function(value) { root.persistItemColor(root.editingKind, "inactive", value) }
      }
      Dropdown {
        Layout.fillWidth: true
        label: "Disabled color"
        options: root.deviceColorRoleOptions
        value: root.itemColorOverrideRole(root.editingKind, "disabled")
        onChanged: function(value) { root.persistItemColor(root.editingKind, "disabled", value) }
      }
      Dropdown {
        visible: root.isPreventativeControl({kind: root.editingKind}) || root.isAudioControl({kind: root.editingKind})
        Layout.fillWidth: true
        label: "Blocked-request color"
        options: root.deviceColorRoleOptions
        value: root.itemColorOverrideRole(root.editingKind, "blocked")
        onChanged: function(value) { root.persistItemColor(root.editingKind, "blocked", value) }
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
        value: Math.round(root.itemIdleOpacity(root.editingKind) * 100)
        foreground: Color.popups.text
        accent: root.activeThemeColor
        fontFamily: Style.font.family
        onModified: function(value) { root.persistItemIdleOpacity(root.editingKind, value) }
      }
      Button {
        text: "Use default"
        enabled: Model.hasItemOverride(root.effectiveSettings, "itemIdleOpacity", root.editingKind)
        onClicked: root.persistItemIdleOpacity(root.editingKind, null)
      }
    }

    Dropdown {
      Layout.fillWidth: true
      label: "Show status markers for this device"
      options: root.deviceVisibilityOptions
      value: root.itemOverrideMode("itemStatusMarkerVisibility", root.editingKind)
      onChanged: function(value) { root.persistItemStatusMarker(root.editingKind, value) }
    }
    RowLayout {
      Layout.fillWidth: true
      Text { Layout.fillWidth: true; text: "Global status-marker rules still apply when this device is set to show."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
      Button { text: "Global marker settings"; onClicked: root.showGlobalSettings("appearance", "status-presentation") }
    }
  }

  SettingsSurface {
    accent: root.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Bar placement" }
    RowLayout {
      Layout.fillWidth: true
      Button {
        text: "Move left"
        enabled: root.canMoveItem(root.editingKind, -1)
        onClicked: root.moveItem(root.editingKind, -1)
      }
      Button {
        text: "Move right"
        enabled: root.canMoveItem(root.editingKind, 1)
        onClicked: root.moveItem(root.editingKind, 1)
      }
      Item { Layout.fillWidth: true }
    }
    Dropdown {
      Layout.fillWidth: true
      label: "Show while idle"
      options: root.deviceVisibilityOptions
      value: root.itemOverrideMode("itemIdleVisibility", root.editingKind)
      onChanged: function(value) { root.persistItemIdleVisibility(root.editingKind, value) }
    }
  }

  SettingsSurface {
    visible: root.editingDevices.length > 0
    Layout.fillWidth: true
    accent: root.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Detected hardware" }
    Repeater {
      model: root.editingDevices
      delegate: ColumnLayout {
        required property string modelData
        Layout.fillWidth: true
        spacing: Style.spacing.xs
        Text { Layout.fillWidth: true; text: modelData; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; elide: Text.ElideMiddle }
        RowLayout {
          Layout.fillWidth: true
          TextField { id: deviceLabelEditor; Layout.fillWidth: true; text: root.deviceLabel(modelData); placeholderText: "Friendly device name"; maximumLength: 128; foreground: Color.popups.text; accent: root.activeThemeColor; font.family: Style.font.family; onAccepted: root.persistDeviceLabel(modelData, text) }
          Button { text: "Save name"; enabled: deviceLabelEditor.text.trim() !== root.deviceLabel(modelData); onClicked: root.persistDeviceLabel(modelData, deviceLabelEditor.text) }
        }
      }
    }
  }

  SettingsSurface {
    visible: root.editingApplications.length > 0
    Layout.fillWidth: true
    accent: root.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Live inspection" }
    Text { Layout.fillWidth: true; text: "Copy a live application target into X-Ray or another process inspector. Process IDs are never added to retained history."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    Repeater {
      model: root.editingApplications
      delegate: RowLayout {
        required property string modelData
        required property int index
        Layout.fillWidth: true
        Text { Layout.fillWidth: true; text: modelData; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body; elide: Text.ElideRight }
        Button { objectName: "inspectionTargetCopy-" + index; iconText: "󰆏"; tooltipText: "Copy inspection target"; horizontalPadding: Style.spacing.controlGap; onClicked: root.privacyService.copyInspectionTarget(modelData) }
      }
    }
    PrivacyMessageSurface { visible: root.privacyService && root.privacyService.inspectionMessage !== ""; message: root.privacyService ? root.privacyService.inspectionMessage : ""; kind: "success" }
  }

  SettingsSurface {
    visible: root.editingKind === "screen-recording" || root.editingKind === "screenshot" || root.isAudioControl({kind: root.editingKind})
    Layout.fillWidth: true
    accent: root.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Backend" }

    Dropdown {
    visible: root.editingKind === "screen-recording"
    Layout.fillWidth: true
    label: "Recording backend"
    options: ["omarchy", "gpu-screen-recorder", "wf-recorder", "custom"]
    value: String(root.setting("recordingBackend", "omarchy"))
    onChanged: function(value) { root.persistSettings({recordingBackend: value}) }
  }

    Text {
    visible: root.editingKind === "screen-recording"
    Layout.fillWidth: true
    text: "Omarchy follows the system capture command. Explicit and custom choices keep dependency checks and activity detection tied to that backend."
    textFormat: Text.PlainText
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

    Dropdown {
    visible: root.editingKind === "screenshot"
    Layout.fillWidth: true
    label: "Screenshot backend"
    options: ["omarchy", "grim", "grim-satty", "hyprshot", "flameshot", "custom"]
    value: String(root.setting("screenshotBackend", "omarchy"))
    onChanged: function(value) { root.persistSettings({screenshotBackend: value}) }
  }

    Text {
    visible: root.editingKind === "screenshot"
    Layout.fillWidth: true
    text: "Omarchy uses its smart flow. Grim and Hyprshot capture regions; Grim + Satty and Flameshot add annotation."
    textFormat: Text.PlainText
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

    ColumnLayout {
    visible: root.editingKind === "screenshot" && String(root.setting("screenshotBackend", "omarchy")) === "custom"
    Layout.fillWidth: true
    spacing: Style.spacing.sm
    property bool dirty: customScreenshotCommandEditor.text !== String(root.setting("screenshotCustomCommand", ""))
      || customScreenshotProcessEditor.text !== String(root.setting("screenshotProcessName", ""))
    property var validation: Model.deviceBackendValidation("screenshot", {
      screenshotBackend: "custom",
      screenshotCustomCommand: customScreenshotCommandEditor.text,
      screenshotProcessName: customScreenshotProcessEditor.text
    })
    Text { Layout.fillWidth: true; text: "Screenshot command"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
    TextField {
      id: customScreenshotCommandEditor
      Layout.fillWidth: true
      placeholderText: "Screenshot command"
      text: String(root.setting("screenshotCustomCommand", ""))
      maximumLength: 4096
      foreground: Color.popups.text
      accent: root.activeThemeColor
      font.family: Style.font.family
      onAccepted: if (parent.validation.valid) root.persistSettings({screenshotCustomCommand: text, screenshotProcessName: customScreenshotProcessEditor.text})
    }
    Text { Layout.fillWidth: true; text: "Activity process substring (optional)"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
    TextField {
      id: customScreenshotProcessEditor
      Layout.fillWidth: true
      placeholderText: "Activity process substring (optional)"
      text: String(root.setting("screenshotProcessName", ""))
      maximumLength: 256
      foreground: Color.popups.text
      accent: root.activeThemeColor
      font.family: Style.font.family
      onAccepted: if (parent.validation.valid) root.persistSettings({screenshotCustomCommand: customScreenshotCommandEditor.text, screenshotProcessName: text})
    }
    Text {
      Layout.fillWidth: true
      text: !parent.validation.valid ? parent.validation.message : (parent.dirty ? "Unsaved changes" : "Saved")
      textFormat: Text.PlainText
      color: !parent.validation.valid ? Color.urgent : (parent.dirty ? Color.accent : Color.muted)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
    Button {
      text: "Save custom backend"
      enabled: parent.dirty && parent.validation.valid
      onClicked: root.persistSettings({
        screenshotCustomCommand: customScreenshotCommandEditor.text,
        screenshotProcessName: customScreenshotProcessEditor.text
      })
    }
  }

    ColumnLayout {
    visible: root.editingKind === "screen-recording" && String(root.setting("recordingBackend", "omarchy")) === "custom"
    Layout.fillWidth: true
    spacing: Style.spacing.sm
    property bool dirty: customRecorderProcessEditor.text !== String(root.setting("recordingProcessName", ""))
      || customRecorderStartEditor.text !== String(root.setting("recordingCustomStartCommand", ""))
      || customRecorderStopEditor.text !== String(root.setting("recordingCustomStopCommand", ""))
    property var validation: Model.deviceBackendValidation("screen-recording", {
      recordingBackend: "custom",
      recordingProcessName: customRecorderProcessEditor.text,
      recordingCustomStartCommand: customRecorderStartEditor.text,
      recordingCustomStopCommand: customRecorderStopEditor.text
    })
    Text { Layout.fillWidth: true; text: "Recorder process name"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
    TextField {
      id: customRecorderProcessEditor
      Layout.fillWidth: true
      placeholderText: "Process command substring"
      text: String(root.setting("recordingProcessName", ""))
      maximumLength: 256
      foreground: Color.popups.text
      accent: root.activeThemeColor
      font.family: Style.font.family
      onAccepted: if (parent.validation.valid) root.persistSettings({recordingProcessName: text, recordingCustomStartCommand: customRecorderStartEditor.text, recordingCustomStopCommand: customRecorderStopEditor.text})
    }
    Text { Layout.fillWidth: true; text: "Start command"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
    TextField {
      id: customRecorderStartEditor
      Layout.fillWidth: true
      placeholderText: "Start command"
      text: String(root.setting("recordingCustomStartCommand", ""))
      maximumLength: 4096
      foreground: Color.popups.text
      accent: root.activeThemeColor
      font.family: Style.font.family
      onAccepted: if (parent.validation.valid) root.persistSettings({recordingProcessName: customRecorderProcessEditor.text, recordingCustomStartCommand: text, recordingCustomStopCommand: customRecorderStopEditor.text})
    }
    Text { Layout.fillWidth: true; text: "Stop command"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
    TextField {
      id: customRecorderStopEditor
      Layout.fillWidth: true
      placeholderText: "Stop command"
      text: String(root.setting("recordingCustomStopCommand", ""))
      maximumLength: 4096
      foreground: Color.popups.text
      accent: root.activeThemeColor
      font.family: Style.font.family
      onAccepted: if (parent.validation.valid) root.persistSettings({recordingProcessName: customRecorderProcessEditor.text, recordingCustomStartCommand: customRecorderStartEditor.text, recordingCustomStopCommand: text})
    }
    Text {
      Layout.fillWidth: true
      text: !parent.validation.valid ? parent.validation.message : (parent.dirty ? "Unsaved changes" : "Saved")
      textFormat: Text.PlainText
      color: !parent.validation.valid ? Color.urgent : (parent.dirty ? Color.accent : Color.muted)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
    Button {
      text: "Save custom backend"
      enabled: parent.dirty && parent.validation.valid
      onClicked: root.persistSettings({
        recordingProcessName: customRecorderProcessEditor.text,
        recordingCustomStartCommand: customRecorderStartEditor.text,
        recordingCustomStopCommand: customRecorderStopEditor.text
      })
    }
  }

    Dropdown {
    visible: root.isAudioControl({kind: root.editingKind})
    Layout.fillWidth: true
    label: "Audio control backend"
    options: ["auto", "pactl", "wpctl"]
    value: String(root.setting("audioControlBackend", "auto"))
    onChanged: function(value) { root.persistSettings({audioControlBackend: value}) }
  }

    Text {
    visible: root.isAudioControl({kind: root.editingKind})
    Layout.fillWidth: true
    text: "Shared by microphone and audio output. Auto prefers pactl and falls back to wpctl. This changes mute control only; activity detection remains PipeWire-native."
    textFormat: Text.PlainText
    color: Color.muted
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
    }
  }

  DeviceDiagnostics { controller: root; kind: root.editingKind }

  SettingsSurface {
    id: resetSurface
    Layout.fillWidth: true
    accent: root.activeThemeColor
    PanelSectionHeader { Layout.fillWidth: true; text: "Reset device appearance" }
    RowLayout {
      Layout.fillWidth: true
      Button {
        text: "Reset device appearance"
        tooltipText: "Restore the default label, icon, colors, idle visibility, idle opacity, and status-marker visibility"
        onClicked: {
          confirmationState.clear()
          root.resetItemSettings(root.editingKind)
          iconEditor.text = root.iconFor(root.editingKind)
          labelEditor.text = root.labelFor(root.editingKind)
        }
      }
      Button {
        visible: root.editingKind === "screen-recording" || root.editingKind === "screenshot" || root.isAudioControl({kind: root.editingKind})
        text: confirmationState.pending === "backend" ? "Confirm shared backend reset" : (root.isAudioControl({kind: root.editingKind}) ? "Reset shared backend" : "Reset backend")
        tooltipText: root.isAudioControl({kind: root.editingKind}) ? "Affects microphone and audio output" : "Restore this device's default backend"
        onClicked: {
          if (root.isAudioControl({kind: root.editingKind}) && !confirmationState.request("backend")) return
          root.resetDeviceBackend(root.editingKind)
          confirmationState.clear()
        }
      }
    }
    Button {
      text: confirmationState.pending === "all" ? "Confirm reset all" : "Reset all device settings"
      onClicked: {
        if (root.isAudioControl({kind: root.editingKind}) && !confirmationState.request("all")) return
        root.resetAllDeviceSettings(root.editingKind)
        iconEditor.text = root.iconFor(root.editingKind)
        labelEditor.text = root.labelFor(root.editingKind)
        confirmationState.clear()
      }
    }
  }
}
