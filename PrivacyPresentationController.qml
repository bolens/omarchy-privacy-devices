pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons
import "Model.js" as Model

Item {
  id: controller
  required property var host

  function item(kind) {
    var apps = host.privacyService ? host.privacyService.appsFor(kind) : []
    return {
      kind: kind,
      label: host.labelFor(kind),
      icon: iconFor(kind),
      active: host.privacyService ? host.privacyService.active(kind) : false,
      apps: apps,
      controllable: host.privacyService ? host.privacyService.controllable(kind) : false,
      controlEnabled: host.privacyService ? host.privacyService.controlEnabled(kind) : false,
      pending: host.privacyService && typeof host.privacyService.controlPending === "function" ? host.privacyService.controlPending(kind) : false,
      dependenciesReady: host.privacyService && typeof host.privacyService.dependenciesReady === "function" ? host.privacyService.dependenciesReady(kind) : true,
      health: host.privacyService && typeof host.privacyService.healthFor === "function" ? host.privacyService.healthFor(kind) : {status: "healthy", summary: ""},
      sessions: host.privacyService && typeof host.privacyService.attributedSessionsFor === "function" ? host.privacyService.attributedSessionsFor(kind) : []
    }
  }

  function barItem(kind) {
    var entry = item(kind)
    if (!host.privacyService || typeof host.privacyService.barActive !== "function") return entry
    entry.active = host.privacyService.barActive(kind)
    entry.apps = host.privacyService.barAppsFor(kind)
    entry.sessions = host.privacyService.barAttributedSessionsFor(kind)
    return entry
  }

  function themeColor(role, activeFallback) {
    if (role === "bar-active") return Color.bar.active
    if (role === "urgent") return Color.urgent
    if (role === "accent") return Color.accent
    if (role === "foreground") return host.bar ? host.bar.foreground : Color.foreground
    if (role === "muted") return Color.muted
    return activeFallback ? Color.bar.active : Color.muted
  }

  function deviceDiagnostic(kind) {
    if (!host.privacyService || typeof host.privacyService.diagnostic !== "function") return {
      healthStatus: "unavailable", dependenciesReady: true, dependencyDescription: "",
      rows: [{label: "Status", value: "Diagnostics unavailable", urgent: true}]
    }
    return Model.deviceDiagnosticPresentation(host.privacyService.diagnostic(kind))
  }

  function isAudioControl(entry) {
    return entry.kind === "microphone" || entry.kind === "audio-output"
  }

  function isPreventativeControl(entry) {
    return ["camera", "screen-share", "location"].indexOf(entry.kind) >= 0
  }

  function itemVisualState(entry) {
    return Model.privacyVisualState(entry)
  }

  function itemStateLabel(entry) { return Model.privacyStateLabel(entry) }
  function itemStatusMarkerVisible(kind) {
    var visibility = host.setting("itemStatusMarkerVisibility", {}) || {}
    return visibility[kind] === undefined ? true : visibility[kind] === true
  }
  function itemStateMarker(entry) {
    var state = itemVisualState(entry)
    var stateVisible = state === "active" ? host.showBarActiveMarker
      : (state === "disabled" || state === "blocked-active" ? host.showBarDisabledMarker
      : (state === "pending" ? host.showBarPendingMarker
      : (state === "unavailable" ? host.showBarDegradedMarker : true)))
    return Model.privacyStateMarker(entry, host.statusMarkerMode, itemStatusMarkerVisible(entry.kind) && stateVisible, host.customBarMarkers)
  }
  function itemSessionCount(entry) { return Model.privacySessionCount(entry, host.showSessionCounts) }

  function barItemText(entry) {
    var marker = itemStateMarker(entry)
    var count = Model.privacySessionCount(entry, host.showBarSessionCounts)
    var text = entry.icon
    if (marker) text = host.barMarkerPosition === "before" ? marker + " " + text : text + " " + marker
    return text + (count ? " " + String(count) : "")
  }

  function itemColor(entry) {
    var state = itemVisualState(entry)
    if (state === "unavailable") return Color.urgent
    if (state === "pending") return Color.accent
    var roles = host.setting("itemColorRoles", {}) || {}
    var override = roles[entry.kind] || {}
    if (state === "blocked-active") return themeColor(String(override.blocked || host.setting("blockedActiveColorRole", "urgent")), true)
    if (state === "disabled") return themeColor(String(override.disabled || host.setting("disabledColorRole", "muted")), false)
    return state === "active"
      ? themeColor(String(override.active || host.setting("activeColorRole", "accent")), true)
      : themeColor(String(override.inactive || host.setting("inactiveColorRole", "foreground")), false)
  }
  function kindEnabled(kind) {
    return host.privacyService ? host.privacyService.kindEnabled(kind) : Model.arraySetting(host.setting("enabledKinds", Model.KINDS), Model.KINDS).indexOf(kind) !== -1
  }

  function orderedKinds() {
    var result = []
    for (var index = 0; index < host.configuredOrder.length; index++) {
      var kind = host.configuredOrder[index]
      if (kindEnabled(kind) && result.indexOf(kind) === -1) result.push(kind)
    }
    for (var fallbackIndex = 0; fallbackIndex < Model.KINDS.length; fallbackIndex++) {
      var fallbackKind = Model.KINDS[fallbackIndex]
      if (kindEnabled(fallbackKind) && result.indexOf(fallbackKind) === -1) result.push(fallbackKind)
    }
    return result
  }

  function activeItems() {
    return host.activeItemList
  }

  function iconFor(kind) {
    var icons = host.setting("icons", {}) || {}
    return icons[kind] !== undefined ? String(icons[kind]) : defaultIcon(kind)
  }

  function defaultIcon(kind) {
    var defaults = {"microphone":"󰍬", "audio-output":"󰓃", "camera":"󰄀", "screen-share":"󰍹", "screenshot":"󰹑", "screen-recording":"󰻂", "location":"󰋽"}
    return String(defaults[kind] || "")
  }

  function deviceAppearanceCustomized(kind) {
    var labels = host.setting("itemLabels", {}) || {}
    var icons = host.setting("icons", {}) || {}
    return Object.prototype.hasOwnProperty.call(labels, kind)
      || (Object.prototype.hasOwnProperty.call(icons, kind) && String(icons[kind]) !== defaultIcon(kind))
      || Model.hasItemOverride(host.effectiveSettings, "itemColorRoles", kind)
      || Model.hasItemOverride(host.effectiveSettings, "itemIdleVisibility", kind)
      || Model.hasItemOverride(host.effectiveSettings, "itemIdleOpacity", kind)
      || Model.hasItemOverride(host.effectiveSettings, "itemStatusMarkerVisibility", kind)
  }

  function sharedText(value) {
    return Model.autoTextSafe(value)
  }

  function barText() {
    if (host.displayMode === "active-count") return host.activeCount > 0 ? "󰒃 " + host.activeCount : (host.showIdle ? "󰒃" : "")
    var items = host.displayMode === "active-only" ? activeItems() : host.visibleItems
    return items.map(function(entry) { return entry.icon }).join(" ")
  }

  function tooltip() {
    if (host.activeCount === 0) return "Privacy devices idle"
    return activeItems().map(function(entry) {
      return sharedText(entry.label) + (entry.apps.length ? ": " + entry.apps.map(sharedText).join(", ") : " in use")
    }).join("\n")
  }

  function itemTooltip(entry) {
    if (entry.kind === "summary") return tooltip()
    var label = sharedText(entry.label)
    var visualState = itemVisualState(entry)
    var state = itemStateLabel(entry)
    if (visualState === "active" && entry.apps.length) state += " — " + entry.apps.map(sharedText).join(", ")
    else if (visualState === "unavailable" && entry.health.summary) state += " — " + sharedText(entry.health.summary)
    var action = Model.itemTooltipAction(entry)
    return label + " · " + state
      + "\n" + action
      + "\nMiddle click for " + label.toLowerCase() + " settings"
      + "\nRight click for privacy details"
  }

}
