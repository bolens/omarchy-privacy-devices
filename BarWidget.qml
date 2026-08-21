import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "io.github.bolens.privacy-devices"

  readonly property var privacyService: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property var configuredOrder: Model.arraySetting(setting("order", []), Model.KINDS)
  readonly property bool showIdle: setting("showIdle", true) === true
  readonly property string displayMode: String(setting("displayMode", "icons"))
  readonly property bool showControls: setting("showControls", true) === true
  readonly property real idleOpacity: Math.max(0.1, Math.min(1, Number(setting("idleOpacity", 0.45))))
  readonly property color activeThemeColor: themeColor(String(setting("activeColorRole", "bar-active")), true)
  readonly property color inactiveThemeColor: themeColor(String(setting("inactiveColorRole", "muted")), false)
  readonly property color mutedThemeColor: themeColor(String(setting("mutedColorRole", "urgent")), true)
  readonly property color unmutedThemeColor: themeColor(String(setting("unmutedColorRole", "foreground")), false)
  readonly property var visibleItems: buildVisibleItems()
  readonly property int activeCount: activeItems().length
  readonly property var barItems: displayMode === "active-count"
    ? [{kind: "summary", label: "Privacy", icon: activeCount > 0 ? "󰒃 " + activeCount : "󰒃", active: activeCount > 0, apps: [], controllable: false, controlEnabled: false}]
    : (displayMode === "active-only" ? activeItems() : visibleItems)
  manageIpc: true
  property string editingKind: ""
  readonly property real openPanelIndicatorWidth: button.labelWidth

  function setting(key, fallback) {
    return settings && settings[key] !== undefined ? settings[key] : fallback
  }

  function syncService() {
    if (privacyService && typeof privacyService.configure === "function") privacyService.configure(settings)
  }

  function item(kind) {
    var apps = privacyService ? privacyService.appsFor(kind) : []
    return {
      kind: kind,
      label: labelFor(kind),
      icon: iconFor(kind),
      active: privacyService ? privacyService.active(kind) : false,
      apps: apps,
      controllable: privacyService ? privacyService.controllable(kind) : false,
      controlEnabled: privacyService ? privacyService.controlEnabled(kind) : false,
      pending: privacyService && typeof privacyService.controlPending === "function" ? privacyService.controlPending(kind) : false,
      dependenciesReady: privacyService && typeof privacyService.dependenciesReady === "function" ? privacyService.dependenciesReady(kind) : true
    }
  }

  function themeColor(role, activeFallback) {
    if (role === "bar-active") return Color.bar.active
    if (role === "urgent") return Color.urgent
    if (role === "accent") return Color.accent
    if (role === "foreground") return bar ? bar.barForeground : Color.foreground
    if (role === "muted") return Color.muted
    return activeFallback ? Color.bar.active : Color.muted
  }

  function controlDescription(entry) {
    if (!entry.dependenciesReady && privacyService) return privacyService.dependencyDescription(entry.kind) + ". Click to install."
    if (entry.pending) return "Waiting for authorization; the device state will be verified when the action finishes"
    if (entry.kind === "microphone") return entry.controlEnabled ? "Input is available; turn off to mute" : "Input is muted; turn on to unmute"
    if (entry.kind === "audio-output") return entry.controlEnabled ? "Output is available; turn off to mute" : "Output is muted; turn on to unmute"
    if (entry.kind === "screen-recording") return entry.controlEnabled ? "Recording is active; turn off to stop" : "Turn on to open the recording picker"
    if (entry.kind === "screenshot") return "Take a screenshot"
    if (entry.kind === "camera") return entry.controlEnabled ? "Camera is allowed; turn off to block the camera driver" : "Camera is blocked; turn on to allow it"
    if (entry.kind === "screen-share") return entry.controlEnabled ? "Screen sharing is allowed; turn off to block the Hyprland portal" : "Screen sharing is blocked; turn on to allow it"
    if (entry.kind === "location") return entry.controlEnabled ? "Location is allowed; turn off to block GeoClue" : "Location is blocked; turn on to allow it"
    return "Status only"
  }

  function diagnosticText(kind) {
    if (!privacyService || typeof privacyService.diagnostic !== "function") return "Diagnostics unavailable"
    var data = privacyService.diagnostic(kind)
    var apps = data.apps && data.apps.length ? data.apps.join(", ") : "None detected"
    var probe = data.probeExitCode < 0 ? "Not run" : String(data.probeExitCode)
    var control = data.controlExitCode < 0 ? "Not used" : String(data.controlExitCode)
    return "Backend: " + data.backend
      + "\nDependencies: " + (data.dependenciesReady ? "Ready" : data.dependencyDescription)
      + "\nActivity: " + (data.active ? "Active" : "Idle")
      + "\nApplications: " + apps
      + "\nControl: " + data.controlState
      + "\nLast probe exit: " + probe
      + " · Last control exit: " + control
  }

  function isAudioControl(entry) {
    return entry.kind === "microphone" || entry.kind === "audio-output"
  }

  function itemColor(entry) {
    var roles = setting("itemColorRoles", {}) || {}
    var override = roles[entry.kind] || {}
    if (isAudioControl(entry)) return entry.controlEnabled
      ? themeColor(String(override.unmuted || setting("unmutedColorRole", "foreground")), false)
      : themeColor(String(override.muted || setting("mutedColorRole", "urgent")), true)
    return entry.active
      ? themeColor(String(override.active || setting("activeColorRole", "bar-active")), true)
      : themeColor(String(override.inactive || setting("inactiveColorRole", "muted")), false)
  }

  function persistSettings(values) {
    var entry = {id: moduleName}
    for (var existing in settings) if (existing !== "id") entry[existing] = settings[existing]
    for (var key in values) entry[key] = values[key]
    settings = entry
    syncService()
    if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function")
      bar.shell.updateEntryInline(moduleName, entry)
  }

  function persistIcon(kind, value) {
    var icons = JSON.parse(JSON.stringify(setting("icons", {}) || {}))
    icons[kind] = String(value || "")
    persistSettings({icons: icons})
  }

  function labelFor(kind) {
    var labels = setting("itemLabels", {}) || {}
    return labels[kind] !== undefined && String(labels[kind]) !== "" ? String(labels[kind]) : Model.label(kind)
  }

  function persistLabel(kind, value) {
    var labels = JSON.parse(JSON.stringify(setting("itemLabels", {}) || {}))
    var text = String(value || "").trim()
    if (text) labels[kind] = text
    else delete labels[kind]
    persistSettings({itemLabels: labels})
  }

  function persistItemColor(kind, state, role) {
    var roles = JSON.parse(JSON.stringify(setting("itemColorRoles", {}) || {}))
    if (!roles[kind]) roles[kind] = {}
    roles[kind][state] = role
    persistSettings({itemColorRoles: roles})
  }

  function itemColorRole(kind, state, fallback) {
    var roles = setting("itemColorRoles", {}) || {}
    return roles[kind] && roles[kind][state] ? String(roles[kind][state]) : fallback
  }

  function moveItem(kind, delta) {
    var order = orderedKinds()
    var index = order.indexOf(kind)
    var target = index + delta
    if (index < 0 || target < 0 || target >= order.length) return
    var swap = order[target]
    order[target] = order[index]
    order[index] = swap
    persistSettings({order: order})
  }

  function itemShowsWhenIdle(kind) {
    var overrides = setting("itemIdleVisibility", {}) || {}
    return overrides[kind] !== undefined ? overrides[kind] === true : showIdle
  }

  function persistItemIdleVisibility(kind, visible) {
    var overrides = JSON.parse(JSON.stringify(setting("itemIdleVisibility", {}) || {}))
    overrides[kind] = visible === true
    persistSettings({itemIdleVisibility: overrides})
  }

  function itemIdleOpacity(kind) {
    var overrides = setting("itemIdleOpacity", {}) || {}
    var value = overrides[kind] !== undefined ? Number(overrides[kind]) : idleOpacity
    return Math.max(0.1, Math.min(1, isFinite(value) ? value : idleOpacity))
  }

  function persistItemIdleOpacity(kind, percent) {
    var overrides = JSON.parse(JSON.stringify(setting("itemIdleOpacity", {}) || {}))
    overrides[kind] = Math.max(10, Math.min(100, Number(percent))) / 100
    persistSettings({itemIdleOpacity: overrides})
  }

  function resetItemSettings(kind) {
    var icons = JSON.parse(JSON.stringify(setting("icons", {}) || {}))
    var roles = JSON.parse(JSON.stringify(setting("itemColorRoles", {}) || {}))
    var visibility = JSON.parse(JSON.stringify(setting("itemIdleVisibility", {}) || {}))
    var opacity = JSON.parse(JSON.stringify(setting("itemIdleOpacity", {}) || {}))
    var labels = JSON.parse(JSON.stringify(setting("itemLabels", {}) || {}))
    delete icons[kind]
    delete roles[kind]
    delete visibility[kind]
    delete opacity[kind]
    delete labels[kind]
    persistSettings({icons: icons, itemColorRoles: roles, itemIdleVisibility: visibility, itemIdleOpacity: opacity, itemLabels: labels})
  }

  function toggleEntry(entry) {
    if (!privacyService || !entry.controllable) return
    if (!entry.dependenciesReady) {
      privacyService.installDependencies(entry.kind)
      return
    }
    if (entry.kind === "screen-recording") {
      var backend = String(setting("recordingBackend", "omarchy"))
      if (backend === "wf-recorder")
        bar.run(privacyService.dependencyHelperPath().replace("privacy-deps", "privacy-recording") + (entry.controlEnabled ? " stop wf-recorder" : " start wf-recorder"))
      else if (backend === "custom") {
        var command = String(setting(entry.controlEnabled ? "recordingCustomStopCommand" : "recordingCustomStartCommand", ""))
        if (command) bar.run(command)
      }
      else if (entry.controlEnabled) bar.run("omarchy-capture-screenrecording --stop-recording")
      else bar.run("omarchy-menu toggle trigger.capture.screenrecord")
      return
    }
    if (entry.kind === "screenshot") {
      var screenshotBackend = String(setting("screenshotBackend", "omarchy"))
      if (screenshotBackend === "custom") {
        var screenshotCommand = String(setting("screenshotCustomCommand", ""))
        if (screenshotCommand) bar.run(screenshotCommand)
      }
      else if (screenshotBackend === "omarchy") bar.run("omarchy-capture-screenshot")
      else bar.run(privacyService.dependencyHelperPath().replace("privacy-deps", "privacy-screenshot") + " capture " + screenshotBackend)
      return
    }
    privacyService.toggleControl(entry.kind)
  }

  function enabled(kind) {
    return privacyService ? privacyService.kindEnabled(kind) : Model.arraySetting(setting("enabledKinds", Model.KINDS), Model.KINDS).indexOf(kind) !== -1
  }

  function orderedKinds() {
    var result = []
    for (var index = 0; index < configuredOrder.length; index++) {
      var kind = configuredOrder[index]
      if (enabled(kind) && result.indexOf(kind) === -1) result.push(kind)
    }
    for (var fallbackIndex = 0; fallbackIndex < Model.KINDS.length; fallbackIndex++) {
      var fallbackKind = Model.KINDS[fallbackIndex]
      if (enabled(fallbackKind) && result.indexOf(fallbackKind) === -1) result.push(fallbackKind)
    }
    return result
  }

  function buildVisibleItems() {
    var result = []
    var kinds = orderedKinds()
    for (var index = 0; index < kinds.length; index++) {
      var entry = item(kinds[index])
      if (entry.active || itemShowsWhenIdle(entry.kind)) result.push(entry)
    }
    return result
  }

  function activeItems() {
    return visibleItems.filter(function(entry) { return entry.active })
  }

  function iconFor(kind) {
    var defaults = {"microphone":"󰍬", "audio-output":"󰓃", "camera":"󰄀", "screen-share":"󰍹", "screenshot":"󰹑", "screen-recording":"󰻂", "location":"󰋽"}
    var icons = setting("icons", {}) || {}
    return icons[kind] !== undefined ? String(icons[kind]) : String(defaults[kind] || "")
  }

  function barText() {
    if (displayMode === "active-count") return activeCount > 0 ? "󰒃 " + activeCount : (showIdle ? "󰒃" : "")
    var items = displayMode === "active-only" ? activeItems() : visibleItems
    return items.map(function(entry) { return entry.icon }).join(" ")
  }

  function tooltip() {
    if (activeCount === 0) return "Privacy devices idle"
    return activeItems().map(function(entry) {
      return entry.label + (entry.apps.length ? ": " + entry.apps.join(", ") : " in use")
    }).join("\n")
  }

  function itemTooltip(entry) {
    if (entry.kind === "summary") return tooltip()
    var state = entry.active
      ? (entry.apps.length ? entry.apps.join(", ") : "In use")
      : "Idle"
    var action = !entry.dependenciesReady
      ? "Left click to install requirements"
      : entry.controllable
      ? (entry.kind === "screenshot"
          ? "Left click to take a screenshot"
          : entry.kind === "screen-recording"
          ? (entry.controlEnabled ? "Left click to stop recording" : "Left click to start recording")
          : root.isAudioControl(entry)
          ? (entry.controlEnabled ? "Left click to mute" : "Left click to unmute")
          : (entry.controlEnabled ? "Left click to block" : "Left click to allow"))
      : "Left click for details"
    return entry.label + " · " + state
      + "\n" + action
      + "\nMiddle click for " + entry.label.toLowerCase() + " settings"
      + "\nRight click for privacy details"
  }

  function pressItem(entry, buttonCode) {
    if (buttonCode === Qt.MiddleButton) {
      if (entry.kind !== "summary") editingKind = entry.kind
      root.open()
      return
    }
    if (buttonCode === Qt.RightButton || entry.kind === "summary" || !entry.controllable) {
      editingKind = ""
      root.toggle()
      return
    }
    root.toggleEntry(entry)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  visible: root.barItems.length > 0

  onSettingsChanged: Qt.callLater(syncService)
  onPrivacyServiceChanged: Qt.callLater(syncService)
  Component.onCompleted: Qt.callLater(syncService)

  Item {
    id: button
    implicitWidth: iconRow.implicitWidth
    implicitHeight: root.bar ? root.bar.barSize : Style.bar.sizeHorizontal
    property real labelWidth: implicitWidth

    Row {
      id: iconRow
      anchors.centerIn: parent
      spacing: 0

      Repeater {
        model: root.barItems
        delegate: WidgetButton {
          required property var modelData
          bar: root.bar
          text: modelData.icon
          active: modelData.active
          dimmed: false
          foreground: root.itemColor(modelData)
          activeColor: root.itemColor(modelData)
          opacity: modelData.active ? 1 : root.itemIdleOpacity(modelData.kind)
          horizontalMargin: modelData.kind === "summary" ? 8.5 : 5
          tooltipText: root.itemTooltip(modelData)
          onPressed: function(buttonCode) { root.pressItem(modelData, buttonCode) }
        }
      }
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: fittedContentWidth(Style.space(440))
    contentHeight: fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { if (bar && typeof bar.switchPanelFrom === "function") bar.switchPanelFrom(root, direction) }

      ColumnLayout {
        id: content
        width: parent.width
        spacing: Style.spacing.md

        RowLayout {
          visible: root.editingKind === ""
          Layout.fillWidth: true
          Text {
            text: "Privacy activity"
            color: Color.popups.text
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.weight: Font.DemiBold
          }
          Item { Layout.fillWidth: true }
          Text {
            text: root.activeCount > 0 ? root.activeCount + " active" : "All idle"
            color: root.activeCount > 0 ? root.activeThemeColor : root.inactiveThemeColor
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
          }
        }

        ColumnLayout {
          visible: root.editingKind !== ""
          Layout.fillWidth: true
          spacing: Style.spacing.md

          RowLayout {
            Layout.fillWidth: true
            Button {
              text: "Back"
              iconText: "󰁍"
              onClicked: root.editingKind = ""
            }
            Text {
              Layout.fillWidth: true
              text: Model.label(root.editingKind) + " settings"
              color: Color.popups.text
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              font.weight: Font.DemiBold
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: previewRow.implicitHeight + Style.spacing.md * 2
            radius: Style.cornerRadius
            color: Util.alpha(root.itemColor(root.item(root.editingKind)), 0.10)
            RowLayout {
              id: previewRow
              anchors.fill: parent
              anchors.margins: Style.spacing.md
              Text {
                text: root.iconFor(root.editingKind)
                color: root.itemColor(root.item(root.editingKind))
                font.family: Style.font.family
                font.pixelSize: Style.font.icon
              }
              Text {
                Layout.fillWidth: true
                text: root.labelFor(root.editingKind)
                color: Color.popups.text
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                font.weight: Font.DemiBold
              }
            }
          }

          PanelSectionHeader {
            Layout.fillWidth: true
            text: "Appearance"
          }

          RowLayout {
            Layout.fillWidth: true
            TextField {
              id: labelEditor
              Layout.fillWidth: true
              placeholderText: "Display label"
              text: root.editingKind ? root.labelFor(root.editingKind) : ""
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistLabel(root.editingKind, text)
            }
            Button {
              text: "Save label"
              onClicked: root.persistLabel(root.editingKind, labelEditor.text)
            }
          }

          RowLayout {
            Layout.fillWidth: true
            TextField {
              id: iconEditor
              Layout.fillWidth: true
              placeholderText: "Icon"
              text: root.editingKind ? root.iconFor(root.editingKind) : ""
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistIcon(root.editingKind, text)
            }
            Button {
              text: "Save icon"
              onClicked: root.persistIcon(root.editingKind, iconEditor.text)
            }
          }

          Dropdown {
            Layout.fillWidth: true
            label: root.isAudioControl({kind: root.editingKind}) ? "Muted color" : "Active color"
            options: ["bar-active", "urgent", "accent", "foreground", "muted"]
            value: root.isAudioControl({kind: root.editingKind})
              ? root.itemColorRole(root.editingKind, "muted", String(root.setting("mutedColorRole", "urgent")))
              : root.itemColorRole(root.editingKind, "active", String(root.setting("activeColorRole", "bar-active")))
            onChanged: function(value) { root.persistItemColor(root.editingKind, root.isAudioControl({kind: root.editingKind}) ? "muted" : "active", value) }
          }

          Dropdown {
            Layout.fillWidth: true
            label: root.isAudioControl({kind: root.editingKind}) ? "Unmuted color" : "Inactive color"
            options: ["bar-active", "urgent", "accent", "foreground", "muted"]
            value: root.isAudioControl({kind: root.editingKind})
              ? root.itemColorRole(root.editingKind, "unmuted", String(root.setting("unmutedColorRole", "foreground")))
              : root.itemColorRole(root.editingKind, "inactive", String(root.setting("inactiveColorRole", "muted")))
            onChanged: function(value) { root.persistItemColor(root.editingKind, root.isAudioControl({kind: root.editingKind}) ? "unmuted" : "inactive", value) }
          }

          NumberField {
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

          PanelSectionHeader {
            Layout.fillWidth: true
            text: "Placement"
          }

          RowLayout {
            Layout.fillWidth: true
            Button {
              text: "Move left"
              onClicked: root.moveItem(root.editingKind, -1)
            }
            Button {
              text: "Move right"
              onClicked: root.moveItem(root.editingKind, 1)
            }
            Item { Layout.fillWidth: true }
          }

          PanelSectionHeader {
            Layout.fillWidth: true
            text: "Behavior"
          }

          Toggle {
            Layout.fillWidth: true
            label: "Show while idle"
            description: "Keep this item visible on the bar when it is not active."
            checked: root.itemShowsWhenIdle(root.editingKind)
            foreground: Color.popups.text
            accent: root.activeThemeColor
            fontFamily: Style.font.family
            onClicked: root.persistItemIdleVisibility(root.editingKind, !checked)
          }

          PanelSectionHeader {
            visible: root.editingKind === "screen-recording" || root.editingKind === "screenshot" || root.isAudioControl({kind: root.editingKind}) || root.editingKind === "camera"
            Layout.fillWidth: true
            text: root.editingKind === "camera" ? "Device control" : "Backend"
          }

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
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          ColumnLayout {
            visible: root.editingKind === "screenshot" && String(root.setting("screenshotBackend", "omarchy")) === "custom"
            Layout.fillWidth: true
            spacing: Style.spacing.sm
            TextField {
              id: customScreenshotCommandEditor
              Layout.fillWidth: true
              placeholderText: "Screenshot command"
              text: String(root.setting("screenshotCustomCommand", ""))
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistSettings({screenshotCustomCommand: text})
            }
            TextField {
              id: customScreenshotProcessEditor
              Layout.fillWidth: true
              placeholderText: "Activity process substring (optional)"
              text: String(root.setting("screenshotProcessName", ""))
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistSettings({screenshotProcessName: text})
            }
            Button {
              text: "Save custom backend"
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
            TextField {
              id: customRecorderProcessEditor
              Layout.fillWidth: true
              placeholderText: "Process command substring"
              text: String(root.setting("recordingProcessName", ""))
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistSettings({recordingProcessName: text})
            }
            TextField {
              id: customRecorderStartEditor
              Layout.fillWidth: true
              placeholderText: "Start command"
              text: String(root.setting("recordingCustomStartCommand", ""))
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistSettings({recordingCustomStartCommand: text})
            }
            TextField {
              id: customRecorderStopEditor
              Layout.fillWidth: true
              placeholderText: "Stop command"
              text: String(root.setting("recordingCustomStopCommand", ""))
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistSettings({recordingCustomStopCommand: text})
            }
            Button {
              text: "Save custom backend"
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
            text: "Auto prefers pactl and falls back to wpctl. This changes mute control only; activity detection remains PipeWire-native."
            color: Color.muted
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }

          RowLayout {
            visible: root.editingKind === "camera"
            Layout.fillWidth: true
            TextField {
              id: cameraModuleEditor
              Layout.fillWidth: true
              placeholderText: "Kernel module"
              text: String(root.setting("cameraKernelModule", "uvcvideo"))
              foreground: Color.popups.text
              accent: root.activeThemeColor
              font.family: Style.font.family
              onAccepted: root.persistSettings({cameraKernelModule: text})
            }
            Button {
              text: "Save module"
              onClicked: root.persistSettings({cameraKernelModule: cameraModuleEditor.text})
            }
          }

          PanelSectionHeader {
            Layout.fillWidth: true
            text: "Diagnostics"
          }

          Button {
            visible: root.editingKind !== "" && privacyService && !privacyService.dependenciesReady(root.editingKind)
            text: "Install requirements"
            tooltipText: privacyService ? privacyService.dependencyDescription(root.editingKind) : ""
            onClicked: privacyService.installDependencies(root.editingKind)
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: diagnosticsText.implicitHeight + Style.spacing.md * 2
            radius: Style.cornerRadius
            color: Util.alpha(Color.popups.text, 0.04)
            Text {
              id: diagnosticsText
              anchors.fill: parent
              anchors.margins: Style.spacing.md
              text: root.diagnosticText(root.editingKind)
              color: Color.muted
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              wrapMode: Text.WordWrap
            }
          }

          PanelSectionHeader {
            Layout.fillWidth: true
            text: "Reset"
          }

          Button {
            text: "Reset item settings"
            tooltipText: "Restore the default label, icon, colors, idle opacity, and idle visibility"
            onClicked: {
              root.resetItemSettings(root.editingKind)
              iconEditor.text = root.iconFor(root.editingKind)
              labelEditor.text = root.labelFor(root.editingKind)
            }
          }
        }

        Repeater {
          visible: root.editingKind === ""
          model: root.orderedKinds().map(function(kind) { return root.item(kind) })
          delegate: Rectangle {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: row.implicitHeight + Style.spacing.md * 2
            radius: Style.cornerRadius
            color: Util.alpha(modelData.active ? root.activeThemeColor : root.inactiveThemeColor, modelData.active ? 0.12 : 0.05)
            border.width: modelData.active ? 1 : 0
            border.color: Util.alpha(root.activeThemeColor, 0.45)

            MouseArea {
              anchors.fill: parent
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: function(mouse) {
                if (mouse.button === Qt.MiddleButton) {
                  root.editingKind = modelData.kind
                  return
                }
                if (root.showControls && modelData.controllable && !modelData.pending) root.toggleEntry(modelData)
              }
            }

            RowLayout {
              id: row
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.margins: Style.spacing.md
              spacing: Style.spacing.md

              Text {
                text: modelData.icon
                color: root.itemColor(modelData)
                opacity: modelData.active ? 1 : root.itemIdleOpacity(modelData.kind)
                font.family: Style.font.family
                font.pixelSize: Style.font.icon
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text {
                  Layout.fillWidth: true
                  text: modelData.label
                  color: Color.popups.text
                  font.family: Style.font.family
                  font.pixelSize: Style.font.body
                  font.weight: modelData.active ? Font.DemiBold : Font.Normal
                }
                Text {
                  Layout.fillWidth: true
                  text: modelData.active ? (modelData.apps.length ? modelData.apps.join(", ") : "In use") : "Idle"
                  color: modelData.active ? Color.popups.text : root.inactiveThemeColor
                  font.family: Style.font.family
                  font.pixelSize: Style.font.caption
                  elide: Text.ElideRight
                }
              }
              Text {
                visible: !root.showControls || !modelData.controllable || modelData.kind === "screenshot" || !modelData.dependenciesReady
                text: !modelData.dependenciesReady ? "INSTALL" : (modelData.kind === "screenshot" ? "CAPTURE" : (modelData.active ? "ACTIVE" : "IDLE"))
                color: root.itemColor(modelData)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.weight: Font.DemiBold
              }

              ToggleSwitch {
                visible: root.showControls && modelData.controllable && modelData.kind !== "screenshot" && modelData.dependenciesReady
                checked: modelData.controlEnabled
                busy: modelData.pending
                interactive: false
                foreground: Color.popups.text
                accent: root.isAudioControl(modelData)
                  ? (modelData.controlEnabled ? root.unmutedThemeColor : root.mutedThemeColor)
                  : root.activeThemeColor
              }
            }
          }
        }

        Text {
          visible: root.editingKind === ""
          Layout.fillWidth: true
          text: "PipeWire activity updates live. Location and recorder detection use bounded fallback polling. Middle-click an item for settings."
          color: Color.muted
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
