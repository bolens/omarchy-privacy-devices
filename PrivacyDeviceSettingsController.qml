import QtQuick
import "Model.js" as Model

Item {
  id: controller
  required property var host
  readonly property var root: host

  function persistIcon(kind, value) {
    var icons = JSON.parse(JSON.stringify(host.mutationSetting("icons", {}) || {}))
    icons[kind] = String(value || "")
    host.persistSettings({icons: icons})
    Qt.callLater(function() { if (root.editingKind === kind) host.deviceEditorIconControl.text = root.iconFor(kind) })
  }

  function labelFor(kind) {
    var labels = host.setting("itemLabels", {}) || {}
    return labels[kind] !== undefined && String(labels[kind]) !== "" ? String(labels[kind]) : Model.label(kind)
  }

  function persistLabel(kind, value) {
    var labels = JSON.parse(JSON.stringify(host.mutationSetting("itemLabels", {}) || {}))
    var text = String(value || "").trim()
    if (text) labels[kind] = text
    else delete labels[kind]
    host.persistSettings({itemLabels: labels})
    Qt.callLater(function() { if (root.editingKind === kind) host.deviceEditorLabelControl.text = root.labelFor(kind) })
  }

  function persistItemColor(kind, state, role) {
    var roles = JSON.parse(JSON.stringify(host.mutationSetting("itemColorRoles", {}) || {}))
    if (role === "inherit") {
      if (roles[kind]) {
        delete roles[kind][state]
        if (Object.keys(roles[kind]).length === 0) delete roles[kind]
      }
    } else {
      if (!roles[kind]) roles[kind] = {}
      roles[kind][state] = role
    }
    host.persistSettings({itemColorRoles: roles})
  }

  function persistItemStatusMarker(kind, mode) {
    var visibility = JSON.parse(JSON.stringify(host.mutationSetting("itemStatusMarkerVisibility", {}) || {}))
    if (mode === "inherit") delete visibility[kind]
    else visibility[kind] = mode === "show"
    host.persistSettings({itemStatusMarkerVisibility: visibility})
  }

  function itemColorRole(kind, state, fallback) {
    var roles = host.setting("itemColorRoles", {}) || {}
    return roles[kind] && roles[kind][state] ? String(roles[kind][state]) : fallback
  }

  function itemColorOverrideRole(kind, state) {
    return Model.hasItemOverride(host.effectiveSettings, "itemColorRoles", kind, state)
      ? String(host.setting("itemColorRoles", {})[kind][state]) : "inherit"
  }

  function itemOverrideMode(group, kind) {
    return Model.itemOverrideMode(host.effectiveSettings, group, kind)
  }

  function moveItem(kind, delta) {
    var order = host.orderedKinds()
    var index = order.indexOf(kind)
    var target = index + delta
    if (index < 0 || target < 0 || target >= order.length) return
    var swap = order[target]
    order[target] = order[index]
    order[index] = swap
    host.persistSettings({order: order})
  }

  function canMoveItem(kind, delta) {
    var order = host.orderedKinds()
    var index = order.indexOf(kind)
    return index >= 0 && index + delta >= 0 && index + delta < order.length
  }

  function itemShowsWhenIdle(kind) {
    var overrides = host.setting("itemIdleVisibility", {}) || {}
    return overrides[kind] !== undefined ? overrides[kind] === true : host.showIdle
  }

  function persistItemIdleVisibility(kind, mode) {
    var overrides = JSON.parse(JSON.stringify(host.mutationSetting("itemIdleVisibility", {}) || {}))
    if (mode === "inherit") delete overrides[kind]
    else overrides[kind] = mode === "show"
    host.persistSettings({itemIdleVisibility: overrides})
  }

  function itemIdleOpacity(kind) {
    var overrides = host.setting("itemIdleOpacity", {}) || {}
    var value = overrides[kind] !== undefined ? Number(overrides[kind]) : host.idleOpacity
    return Math.max(0.1, Math.min(1, isFinite(value) ? value : host.idleOpacity))
  }

  function persistItemIdleOpacity(kind, percent) {
    var overrides = JSON.parse(JSON.stringify(host.mutationSetting("itemIdleOpacity", {}) || {}))
    if (percent === null || percent === undefined) delete overrides[kind]
    else overrides[kind] = Math.max(10, Math.min(100, Number(percent))) / 100
    host.persistSettings({itemIdleOpacity: overrides})
  }

  function itemResetValues(kind) {
    var icons = JSON.parse(JSON.stringify(host.mutationSetting("icons", {}) || {}))
    var roles = JSON.parse(JSON.stringify(host.mutationSetting("itemColorRoles", {}) || {}))
    var visibility = JSON.parse(JSON.stringify(host.mutationSetting("itemIdleVisibility", {}) || {}))
    var opacity = JSON.parse(JSON.stringify(host.mutationSetting("itemIdleOpacity", {}) || {}))
    var markerVisibility = JSON.parse(JSON.stringify(host.mutationSetting("itemStatusMarkerVisibility", {}) || {}))
    var labels = JSON.parse(JSON.stringify(host.mutationSetting("itemLabels", {}) || {}))
    delete icons[kind]
    delete roles[kind]
    delete visibility[kind]
    delete opacity[kind]
    delete markerVisibility[kind]
    delete labels[kind]
    return {icons: icons, itemColorRoles: roles, itemIdleVisibility: visibility, itemIdleOpacity: opacity, itemStatusMarkerVisibility: markerVisibility, itemLabels: labels}
  }

  function resetItemSettings(kind) {
    host.persistSettings(itemResetValues(kind))
    Qt.callLater(host.syncDeviceEditors)
  }

  function deviceBackendDefaults(kind) {
    if (kind === "screenshot") return {screenshotBackend: "omarchy", screenshotCustomCommand: "", screenshotProcessName: ""}
    if (kind === "screen-recording") return {recordingBackend: "omarchy", recordingProcessName: "", recordingCustomStartCommand: "", recordingCustomStopCommand: ""}
    if (host.isAudioControl({kind: kind})) return {audioControlBackend: "auto"}
    return {}
  }

  function resetDeviceBackend(kind) {
    host.persistSettings(deviceBackendDefaults(kind))
    Qt.callLater(host.syncDeviceEditors)
  }

  function resetAllDeviceSettings(kind) {
    var values = itemResetValues(kind)
    var backend = deviceBackendDefaults(kind)
    for (var key in backend) values[key] = backend[key]
    host.persistSettings(values)
    Qt.callLater(host.syncDeviceEditors)
  }

}
