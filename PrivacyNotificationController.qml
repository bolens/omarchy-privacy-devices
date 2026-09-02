pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "Model.js" as Model

Item {
  id: controller
  required property var host

  property var queue: []
  readonly property int maximumQueuedEvents: 100
  readonly property int maximumQueuedEventBytes: 262144
  property bool activityInitialized: false

  function resolvedIcon(name, fallback) {
    var candidates = [Model.notificationIconName(name), Model.notificationIconName(fallback)]
    for (var index = 0; index < candidates.length; index++) {
      var candidate = candidates[index]
      if (candidate && Quickshell.iconPath(candidate, true)) return candidate
    }
    return ""
  }

  function actionHelperPath() {
    return String(Qt.resolvedUrl("privacy-action")).replace(/^file:\/\//, "")
  }

  function action(actionName, argument) {
    return Model.privacyAction(actionName, argument)
  }

  function send(title, body, icon, fallbackIcon, actionName, argument) {
    var command = ["omarchy", "notification", "send", "--app-name", "Privacy Devices"]
    var iconName = resolvedIcon(icon, fallbackIcon)
    if (iconName) command.push("--icon", iconName)
    var callback = action(actionName, argument)
    if (callback) command.push("--exec", actionHelperPath(), callback.name, callback.argument)
    command.push("--urgency", "normal", Model.autoTextSafe(title), Model.autoTextSafe(body))
    Quickshell.execDetached(command)
  }

  function enqueueActivity(phase, session) {
    if (queue.length && queue[0].phase !== phase) flushActivity()
    var next = queue.concat([{phase: phase, kind: session.kind, application: session.application, icon: session.icon}])
    while (next.length > maximumQueuedEvents || queuedEventBytes(next) > maximumQueuedEventBytes) next.shift()
    queue = next
    flushTimer.restart()
  }

  function queuedEventBytes(events) {
    try { return unescape(encodeURIComponent(JSON.stringify(events))).length }
    catch (error) { return Number.POSITIVE_INFINITY }
  }

  function flushActivity() {
    var grouped = Model.coalesceNotificationEvents(queue)
    queue = []
    if (grouped.count > 0) send(grouped.title, grouped.body, grouped.icon, grouped.fallbackIcon,
      grouped.count === 1 ? "open-activity" : "open-history", grouped.kind)
  }

  function notifyControlResult(kind, expectedEnabled, succeeded) {
    if (host.settings.notifyOnControlChanges === false) return
    var result = Model.controlResultNotification(kind, expectedEnabled, succeeded)
    send(result.title, result.body, Model.notificationKindIcon(kind), "security-high-symbolic",
      succeeded === true ? "open-activity" : "open-diagnostics", succeeded === true ? kind : "")
  }

  function requestPopup(view, argument) {
    host.requestedView = view
    host.requestedViewArgument = String(argument || "")
    host.requestedSettingsSection = ""
    host.settingsRequestSerial++
    if (host.anyBarOpen()) return view
    return host.shell && typeof host.shell.summon === "function" && host.shell.summon("io.github.bolens.privacy-devices", "")
      ? view : "unavailable"
  }

  function requestSettings(page, section) {
    var target = Model.settingsDeepLink(page, section)
    host.requestedView = "settings"
    host.requestedSettingsPage = target.page
    host.requestedSettingsSection = target.section
    host.settingsRequestSerial++
    if (!host.anyBarOpen() && (!host.shell || typeof host.shell.summon !== "function"
        || !host.shell.summon("io.github.bolens.privacy-devices", ""))) return "unavailable"
    return target.page + (target.section ? "#" + target.section : "")
  }

  function requestDevice(kind) {
    var target = Model.deviceDeepLink(kind)
    if (String(kind || "") && !target) return "invalid"
    return requestPopup("activity", target)
  }

  function dispatchAction(name, argument) {
    var accepted = Model.privacyAction(name, argument)
    if (!accepted) return "invalid"
    if (accepted.name === "open-activity") return requestPopup("activity", accepted.argument)
    if (accepted.name === "open-history") return requestPopup("history", accepted.argument)
    if (accepted.name === "open-diagnostics") return requestPopup("diagnostics", "")
    if (accepted.name === "lockdown") return requestPopup("lockdown", "")
    if (accepted.name === "undo-lockdown") return host.restorePrivacyLockdown() ? "ok" : "unavailable"
    if (accepted.name === "rescan") {
      host.refreshFallbacks()
      host.refreshDirectDevices()
      host.refreshSessions()
      return "ok"
    }
    return "invalid"
  }

  Timer { id: flushTimer; interval: 400; onTriggered: controller.flushActivity() }
  Timer { interval: 5000; running: true; onTriggered: controller.activityInitialized = true }
}
