// Dynamic boundary for the documented, optional injected bar host protocol.
// Keep shape validation here; consumers use BarHostAccess's typed projections.
function member(receiver, key) {
  if (receiver === null || receiver === undefined) return undefined
  try { return receiver[key] } catch (error) { return undefined }
}

function vertical(host) { return member(host, "vertical") === true }
function barSize(host, fallback) {
  const value = member(host, "barSize")
  return typeof value === "number" && Number.isInteger(value) && value >= 0 && value <= 2147483647 ? value : fallback
}
function color(host, key, fallback) {
  if (["urgent", "foreground", "barForeground"].indexOf(key) < 0) return fallback
  let value = member(host, key)
  if (typeof value === "string") {
    try { value = Qt.color(value) } catch (error) { return fallback }
  }
  if (!value || value.valid !== true) return fallback
  const channels = [value.r, value.g, value.b, value.a]
  if (!channels.every(function(channel) { return typeof channel === "number" && Number.isFinite(channel) && channel >= 0 && channel <= 1 })) return fallback
  return Qt.rgba(value.r, value.g, value.b, value.a)
}
function run(host, command) {
  if (typeof command !== "string" || typeof member(host, "run") !== "function") return false
  host.run(command)
  return true
}
function switchPanel(host, owner, direction) {
  if (typeof member(host, "switchPanelFrom") !== "function" || !owner || (direction !== -1 && direction !== 1)) return false
  return host.switchPanelFrom(owner, direction)
}
function serviceFor(host, moduleName) {
  const shell = member(host, "shell")
  if (typeof moduleName !== "string" || typeof member(shell, "serviceFor") !== "function") return null
  return shell.serviceFor(moduleName)
}
function updateEntry(host, moduleName, entry) {
  const shell = member(host, "shell")
  if (typeof moduleName !== "string" || !entry || typeof entry !== "object" || typeof member(shell, "updateEntryInline") !== "function") return false
  shell.updateEntryInline(moduleName, entry)
  return true
}
function windowScreen(window) {
  const screen = member(window, "screen")
  return screen && Qt.isQtObject(screen) ? screen : null
}
