pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

SettingsSurface {
  id: surface

  required property var controller
  readonly property var root: controller || initializingController

  QtObject {
    id: initializingController
    readonly property string editingKind: ""
    readonly property color activeThemeColor: "transparent"
    function setting(_key, fallback) { return fallback }
    function isAudioControl(_entry) { return false }
    function persistSettings(_values) { return false }
  }

  function syncEditors() {
    customScreenshotCommandEditor.text = String(root.setting("screenshotCustomCommand", ""))
    customScreenshotProcessEditor.text = String(root.setting("screenshotProcessName", ""))
    customRecorderProcessEditor.text = String(root.setting("recordingProcessName", ""))
    customRecorderStartEditor.text = String(root.setting("recordingCustomStartCommand", ""))
    customRecorderStopEditor.text = String(root.setting("recordingCustomStopCommand", ""))
  }

  visible: root.editingKind === "screen-recording" || root.editingKind === "screenshot" || root.isAudioControl({kind: root.editingKind})
  Layout.fillWidth: true
  accent: root.activeThemeColor
  PanelSectionHeader { Layout.fillWidth: true; text: "Backend" }

  Dropdown {
  visible: surface.root.editingKind === "screen-recording"
  Layout.fillWidth: true
  label: "Recording backend"
  options: ["omarchy", "gpu-screen-recorder", "wf-recorder", "custom"]
  value: String(surface.root.setting("recordingBackend", "omarchy"))
  onChanged: function(value) { surface.root.persistSettings({recordingBackend: value}) }
}

  Text {
  visible: surface.root.editingKind === "screen-recording"
  Layout.fillWidth: true
  text: "Omarchy follows the system capture command. Explicit and custom choices keep dependency checks and activity detection tied to that backend."
  textFormat: Text.PlainText
  color: Color.muted
  font.family: Style.font.family
  font.pixelSize: Style.font.caption
  wrapMode: Text.WordWrap
}

  Dropdown {
  visible: surface.root.editingKind === "screenshot"
  Layout.fillWidth: true
  label: "Screenshot backend"
  options: ["omarchy", "grim", "grim-satty", "hyprshot", "flameshot", "custom"]
  value: String(surface.root.setting("screenshotBackend", "omarchy"))
  onChanged: function(value) { surface.root.persistSettings({screenshotBackend: value}) }
}

  Text {
  visible: surface.root.editingKind === "screenshot"
  Layout.fillWidth: true
  text: "Omarchy uses its smart flow. Grim and Hyprshot capture regions; Grim + Satty and Flameshot add annotation."
  textFormat: Text.PlainText
  color: Color.muted
  font.family: Style.font.family
  font.pixelSize: Style.font.caption
  wrapMode: Text.WordWrap
}

  ColumnLayout {
  visible: surface.root.editingKind === "screenshot" && String(surface.root.setting("screenshotBackend", "omarchy")) === "custom"
  Layout.fillWidth: true
  spacing: Style.spacing.sm
  property bool dirty: customScreenshotCommandEditor.text !== String(surface.root.setting("screenshotCustomCommand", ""))
    || customScreenshotProcessEditor.text !== String(surface.root.setting("screenshotProcessName", ""))
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
    text: String(surface.root.setting("screenshotCustomCommand", ""))
    maximumLength: 4096
    foreground: Color.popups.text
    accent: surface.root.activeThemeColor
    font.family: Style.font.family
    onAccepted: if (parent.validation.valid) surface.root.persistSettings({screenshotCustomCommand: text, screenshotProcessName: customScreenshotProcessEditor.text})
  }
  Text { Layout.fillWidth: true; text: "Activity process substring (optional)"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
  TextField {
    id: customScreenshotProcessEditor
    Layout.fillWidth: true
    placeholderText: "Activity process substring (optional)"
    text: String(surface.root.setting("screenshotProcessName", ""))
    maximumLength: 256
    foreground: Color.popups.text
    accent: surface.root.activeThemeColor
    font.family: Style.font.family
    onAccepted: if (parent.validation.valid) surface.root.persistSettings({screenshotCustomCommand: customScreenshotCommandEditor.text, screenshotProcessName: text})
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
    onClicked: surface.root.persistSettings({
      screenshotCustomCommand: customScreenshotCommandEditor.text,
      screenshotProcessName: customScreenshotProcessEditor.text
    })
  }
}

  ColumnLayout {
  visible: surface.root.editingKind === "screen-recording" && String(surface.root.setting("recordingBackend", "omarchy")) === "custom"
  Layout.fillWidth: true
  spacing: Style.spacing.sm
  property bool dirty: customRecorderProcessEditor.text !== String(surface.root.setting("recordingProcessName", ""))
    || customRecorderStartEditor.text !== String(surface.root.setting("recordingCustomStartCommand", ""))
    || customRecorderStopEditor.text !== String(surface.root.setting("recordingCustomStopCommand", ""))
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
    text: String(surface.root.setting("recordingProcessName", ""))
    maximumLength: 256
    foreground: Color.popups.text
    accent: surface.root.activeThemeColor
    font.family: Style.font.family
    onAccepted: if (parent.validation.valid) surface.root.persistSettings({recordingProcessName: text, recordingCustomStartCommand: customRecorderStartEditor.text, recordingCustomStopCommand: customRecorderStopEditor.text})
  }
  Text { Layout.fillWidth: true; text: "Start command"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
  TextField {
    id: customRecorderStartEditor
    Layout.fillWidth: true
    placeholderText: "Start command"
    text: String(surface.root.setting("recordingCustomStartCommand", ""))
    maximumLength: 4096
    foreground: Color.popups.text
    accent: surface.root.activeThemeColor
    font.family: Style.font.family
    onAccepted: if (parent.validation.valid) surface.root.persistSettings({recordingProcessName: customRecorderProcessEditor.text, recordingCustomStartCommand: text, recordingCustomStopCommand: customRecorderStopEditor.text})
  }
  Text { Layout.fillWidth: true; text: "Stop command"; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption }
  TextField {
    id: customRecorderStopEditor
    Layout.fillWidth: true
    placeholderText: "Stop command"
    text: String(surface.root.setting("recordingCustomStopCommand", ""))
    maximumLength: 4096
    foreground: Color.popups.text
    accent: surface.root.activeThemeColor
    font.family: Style.font.family
    onAccepted: if (parent.validation.valid) surface.root.persistSettings({recordingProcessName: customRecorderProcessEditor.text, recordingCustomStartCommand: customRecorderStartEditor.text, recordingCustomStopCommand: text})
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
    onClicked: surface.root.persistSettings({
      recordingProcessName: customRecorderProcessEditor.text,
      recordingCustomStartCommand: customRecorderStartEditor.text,
      recordingCustomStopCommand: customRecorderStopEditor.text
    })
  }
}

  Dropdown {
  visible: surface.root.isAudioControl({kind: surface.root.editingKind})
  Layout.fillWidth: true
  label: "Audio control backend"
  options: ["auto", "pactl", "wpctl"]
  value: String(surface.root.setting("audioControlBackend", "auto"))
  onChanged: function(value) { surface.root.persistSettings({audioControlBackend: value}) }
}

  Text {
  visible: surface.root.isAudioControl({kind: surface.root.editingKind})
  Layout.fillWidth: true
  text: "Shared by microphone and audio output. Auto prefers pactl and falls back to wpctl. This changes mute control only; activity detection remains PipeWire-native."
  textFormat: Text.PlainText
  color: Color.muted
  font.family: Style.font.family
  font.pixelSize: Style.font.caption
  wrapMode: Text.WordWrap
  }
}
