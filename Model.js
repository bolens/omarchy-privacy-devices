.pragma library

var KINDS = ["microphone", "audio-output", "camera", "screen-share", "screenshot", "screen-recording", "location"]
var SETTINGS_VERSION = 1

function sanitizeSettings(data) {
  var source = data && typeof data === "object" && !Array.isArray(data) ? data : {}
  var clean = {}, index, key
  var booleans = {showIdle:true, showControls:true, deduplicateApps:true, notifyOnActivity:true, notifyOnStop:false,
    notifyOnControlChanges:true, historyEnabled:false, directDeviceMonitoring:false, showInferredAttribution:true}
  for (key in booleans) if (source[key] !== undefined) clean[key] = typeof source[key] === "boolean" ? source[key] : booleans[key]
  var integers = {directDevicePollSeconds:[2,60,5], locationPollSeconds:[5,300,15], recordingPollSeconds:[1,60,2], popupMaxHeight:[360,900,620]}
  for (key in integers) if (source[key] !== undefined) {
    var bounds = integers[key], parsed = Math.round(Number(source[key]))
    if (!isFinite(parsed)) parsed = bounds[2]
    clean[key] = Math.max(bounds[0], Math.min(bounds[1], parsed))
  }
  if (source.idleOpacity !== undefined) {
    var opacity = Number(source.idleOpacity)
    clean.idleOpacity = Math.max(0.1, Math.min(1, isFinite(opacity) ? opacity : 0.45))
  }
  var kindLists = ["enabledKinds", "order", "notificationKinds", "blockableKinds"]
  for (index = 0; index < kindLists.length; index++) if (Array.isArray(source[kindLists[index]]))
    clean[kindLists[index]] = unique(source[kindLists[index]].filter(function(value) { return KINDS.indexOf(value) >= 0 })).slice(0, KINDS.length)
  var stringLists = ["excludedApps", "hiddenApps", "notificationSuppressedApps", "cameraKeywords", "screenShareKeywords"]
  for (index = 0; index < stringLists.length; index++) if (Array.isArray(source[stringLists[index]]))
    clean[stringLists[index]] = unique(source[stringLists[index]].filter(function(value) { return typeof value === "string" && value.trim() !== "" }).map(function(value) { return value.trim().slice(0, 256) })).slice(0, 256)
  var enums = {displayMode:["icons","active-count","active-only"], recordingBackend:["omarchy","gpu-screen-recorder","wf-recorder","custom"],
    audioControlBackend:["auto","pactl","wpctl"], screenshotBackend:["omarchy","grim","grim-satty","hyprshot","flameshot","custom"],
    activeColorRole:["bar-active","urgent","accent","foreground"], inactiveColorRole:["muted","foreground","accent"],
    mutedColorRole:["urgent","muted","bar-active","accent","foreground"], unmutedColorRole:["foreground","bar-active","accent","muted","urgent"]}
  for (key in enums) if (source[key] !== undefined) clean[key] = enums[key].indexOf(source[key]) >= 0 ? source[key] : enums[key][0]
  var strings = ["screenshotCustomCommand", "screenshotProcessName", "recordingProcessName", "recordingCustomStartCommand", "recordingCustomStopCommand"]
  for (index = 0; index < strings.length; index++) if (source[strings[index]] !== undefined) clean[strings[index]] = String(source[strings[index]] || "").slice(0, 4096)
  var maps = ["icons", "itemColorRoles", "itemIdleOpacity", "itemIdleVisibility", "itemLabels"]
  for (index = 0; index < maps.length; index++) if (source[maps[index]] && typeof source[maps[index]] === "object" && !Array.isArray(source[maps[index]])) {
    var mapName = maps[index], map = {}, keys = Object.keys(source[mapName]).filter(function(value) { return KINDS.indexOf(value) >= 0 }).slice(0, KINDS.length)
    for (var mapIndex = 0; mapIndex < keys.length; mapIndex++) {
      var mapKey = keys[mapIndex], mapValue = source[mapName][mapKey]
      if (mapName === "itemIdleVisibility") map[mapKey] = mapValue === true
      else if (mapName === "itemIdleOpacity") {
        var itemOpacity = Number(mapValue)
        map[mapKey] = Math.max(0.1, Math.min(1, isFinite(itemOpacity) ? itemOpacity : 0.45))
      } else if (mapName === "itemColorRoles") {
        if (!mapValue || typeof mapValue !== "object" || Array.isArray(mapValue)) continue
        var roles = {}, roleNames = ["active", "inactive", "muted", "unmuted"]
        for (var roleIndex = 0; roleIndex < roleNames.length; roleIndex++) if (typeof mapValue[roleNames[roleIndex]] === "string") roles[roleNames[roleIndex]] = mapValue[roleNames[roleIndex]].slice(0, 32)
        map[mapKey] = roles
      } else map[mapKey] = String(mapValue || "").slice(0, 128)
    }
    clean[mapName] = map
  }
  clean._privacySettingsVersion = SETTINGS_VERSION
  return clean
}

function arraySetting(value, fallback) {
  if (Array.isArray(value)) return value.map(function(entry) { return String(entry) })
  if (typeof value === "string") return value.split(",").map(function(entry) { return entry.trim() }).filter(Boolean)
  return fallback.slice()
}

function lowerList(value, fallback) {
  return arraySetting(value, fallback).map(function(entry) { return entry.toLowerCase() })
}

function containsAny(text, terms) {
  var haystack = String(text || "").toLowerCase()
  for (var index = 0; index < terms.length; index++) {
    if (haystack.indexOf(String(terms[index]).toLowerCase()) !== -1) return true
  }
  return false
}

function properties(node) {
  return node && node.ready && node.properties ? node.properties : {}
}

function searchable(node) {
  var props = properties(node)
  return [
    props["application.name"], props["application.process.binary"], props["application.id"],
    props["media.name"], props["media.class"], props["node.name"],
    props["node.description"], props["pipewire.access.portal"], props["portal.access"],
    node ? node.name : "", node ? node.description : "", node ? node.type : ""
  ].filter(Boolean).join(" | ")
}

function appName(node) {
  var props = properties(node)
  return String(props["application.name"] || props["application.process.binary"] || props["application.id"]
    || props["media.name"] || (node && (node.description || node.name)) || "Unknown application")
}

function mediaClass(node) {
  var props = properties(node)
  return String(props["media.class"] || (node && node.type) || "")
}

function isExcluded(name, exclusions) {
  var candidate = String(name || "").toLowerCase()
  for (var index = 0; index < exclusions.length; index++) {
    var exclusion = String(exclusions[index] || "").toLowerCase()
    if (exclusion && candidate.indexOf(exclusion) !== -1) return true
  }
  return false
}

function classifyNode(node, settings) {
  if (!node || !node.isStream) return ""
  var name = appName(node)
  var exclusions = lowerList(settings.excludedApps, ["cava"])
  if (isExcluded(name, exclusions)) return ""

  var klass = mediaClass(node).toLowerCase()
  var search = searchable(node)
  var cameras = lowerList(settings.cameraKeywords, ["camera", "webcam", "v4l2", "libcamera", "kamera"])
  var shares = lowerList(settings.screenShareKeywords, ["portal", "screencast", "screen cast", "screen share", "desktop capture", "monitor"])

  if (klass.indexOf("video") !== -1) {
    if (containsAny(search, cameras)) return "camera"
    if (containsAny(search, shares)) return "screen-share"
    return settings.unknownVideoKind === "camera" ? "camera" : "screen-share"
  }
  if (klass.indexOf("stream/input/audio") !== -1 || (node.isSink === false && node.audio)) return "microphone"
  if (klass.indexOf("stream/output/audio") !== -1 || (node.isSink === true && node.audio)) return "audio-output"
  return ""
}

function unique(values) {
  var result = []
  var seen = {}
  for (var index = 0; index < values.length; index++) {
    var value = String(values[index] || "")
    var key = value.toLowerCase()
    if (!value || seen[key]) continue
    seen[key] = true
    result.push(value)
  }
  return result
}

function normalizedKey(value) {
  return String(value || "").trim().toLowerCase()
}

function sessionId(observation) {
  return JSON.stringify([observation.kind, observation.application, observation.device, observation.source].map(normalizedKey))
}

function normalizeObservation(observation) {
  var value = observation || {}
  return {
    id: sessionId(value),
    kind: String(value.kind || "unknown"),
    application: String(value.application || "Unknown application"),
    device: String(value.device || "Unknown device"),
    source: String(value.source || "unknown"),
    confidence: String(value.confidence || "inferred"),
    detail: String(value.detail || "")
  }
}

function reconcileSessions(previous, observations, now) {
  var timestamp = Number(now)
  var oldById = {}
  var active = []
  var started = []
  var stopped = []
  var index
  previous = Array.isArray(previous) ? previous : []
  observations = Array.isArray(observations) ? observations : []
  for (index = 0; index < previous.length; index++) oldById[String(previous[index].id)] = previous[index]
  var seen = {}
  for (index = 0; index < observations.length; index++) {
    var normalized = normalizeObservation(observations[index])
    if (seen[normalized.id]) continue
    seen[normalized.id] = true
    var prior = oldById[normalized.id]
    normalized.startedAt = prior ? Number(prior.startedAt) : timestamp
    normalized.lastSeenAt = timestamp
    active.push(normalized)
    if (!prior) started.push(normalized)
  }
  for (index = 0; index < previous.length; index++) {
    var old = previous[index]
    if (seen[String(old.id)]) continue
    var ended = {}
    for (var key in old) ended[key] = old[key]
    ended.endedAt = timestamp
    ended.durationMs = Math.max(0, timestamp - Number(old.startedAt === undefined ? timestamp : old.startedAt))
    stopped.push(ended)
  }
  return {active: active, started: started, stopped: stopped}
}

function applicationsForSessions(sessions, kind, deduplicate) {
  var values = (Array.isArray(sessions) ? sessions : []).filter(function(session) {
    return !kind || session.kind === kind
  }).map(function(session) { return session.application })
  return deduplicate === false ? values : unique(values)
}

function policyContains(values, application) {
  var key = normalizedKey(application)
  values = Array.isArray(values) ? values : []
  for (var index = 0; index < values.length; index++) {
    if (normalizedKey(values[index]) === key) return true
  }
  return false
}

function visibleSessions(sessions, policies) {
  policies = policies || {}
  return (Array.isArray(sessions) ? sessions : []).filter(function(session) {
    return !policyContains(policies.hiddenApps, session.application)
  })
}

function filterAttribution(sessions, showInferred) {
  var rows = Array.isArray(sessions) ? sessions : []
  return showInferred === false ? rows.filter(function(session) { return session.confidence === "confirmed" }) : rows.slice()
}

function shouldNotifyForSession(session, policies) {
  policies = policies || {}
  return !policyContains(policies.notificationSuppressedApps, session.application)
}

function aggregateHealth(states) {
  states = Array.isArray(states) ? states : []
  if (!states.length) return {status: "unavailable", codes: ["no_sources"], summary: "No monitoring sources configured"}
  var rank = {healthy: 0, degraded: 1, unavailable: 2}
  var status = "healthy"
  var problems = []
  var codes = []
  for (var index = 0; index < states.length; index++) {
    var state = states[index] || {}
    var candidate = rank[state.status] === undefined ? "degraded" : state.status
    if (rank[candidate] > rank[status]) status = candidate
    if (candidate !== "healthy") problems.push(String(state.source || "monitor") + ": " + String(state.reason || candidate))
    if (candidate !== "healthy") codes.push(String(state.code || "unknown_failure"))
  }
  return {status: status, codes: unique(codes), summary: problems.length ? problems.join("; ") : "All monitoring sources healthy"}
}

function appendHistory(history, session, now, limits) {
  limits = limits || {}
  var maxEntries = Math.max(1, Number(limits.maxEntries || 100))
  var maxAgeMs = Math.max(1, Number(limits.maxAgeMs || 7 * 24 * 60 * 60 * 1000))
  var cutoff = Number(now) - maxAgeMs
  var result = [session].concat(Array.isArray(history) ? history : []).filter(function(entry) {
    return Number(entry.endedAt || entry.startedAt || 0) >= cutoff
  })
  return result.slice(0, maxEntries)
}

// Ignore timestamps that naturally advance on every observation. Consumers only
// need a new array when something they render or act upon actually changed.
function sessionsEquivalent(left, right) {
  left = Array.isArray(left) ? left : []
  right = Array.isArray(right) ? right : []
  if (left.length !== right.length) return false
  var previous = {}
  for (var index = 0; index < left.length; index++) previous[String(left[index].id || "")] = left[index]
  var fields = ["kind", "application", "device", "source", "confidence", "detail"]
  for (var nextIndex = 0; nextIndex < right.length; nextIndex++) {
    var candidate = right[nextIndex]
    var existing = previous[String(candidate.id || "")]
    if (!existing) return false
    for (var fieldIndex = 0; fieldIndex < fields.length; fieldIndex++) {
      var field = fields[fieldIndex]
      if (String(existing[field] || "") !== String(candidate[field] || "")) return false
    }
  }
  return true
}

// Appearance and policy edits must not launch subprocess probes. Keep this list
// explicit so only monitoring changes invalidate the operational cache.
function operationalSignature(settings) {
  settings = settings || {}
  var keys = [
    "enabledKinds", "blockableKinds", "directDeviceMonitoring", "directDevicePollSeconds",
    "microphoneBackend", "audioOutputBackend", "cameraBackend", "screenShareBackend",
    "locationBackend", "recordingBackend", "screenshotBackend",
    "locationProcessName", "recordingProcessName", "screenshotProcessName",
    "cameraKeywords", "screenShareKeywords", "excludedApps"
  ]
  var snapshot = {}
  for (var index = 0; index < keys.length; index++) snapshot[keys[index]] = settings[keys[index]]
  return JSON.stringify(snapshot)
}

function formatDuration(milliseconds) {
  var seconds = Math.max(0, Math.floor(Number(milliseconds || 0) / 1000))
  if (seconds < 60) return seconds + "s"
  var minutes = Math.floor(seconds / 60)
  if (minutes < 60) return minutes + "m " + (seconds % 60) + "s"
  return Math.floor(minutes / 60) + "h " + (minutes % 60) + "m"
}

function coalesceNotificationEvents(events) {
  var rows = Array.isArray(events) ? events : []
  if (!rows.length) return {title: "Privacy activity", body: "", count: 0}
  var phase = String(rows[0].phase || "started")
  var byApp = {}, seen = {}, count = 0
  for (var index = 0; index < rows.length; index++) {
    var event = rows[index] || {}
    var application = String(event.application || "Unknown application")
    var kindLabel = label(String(event.kind || ""))
    var key = phase + "\u0000" + application.toLowerCase() + "\u0000" + kindLabel
    if (seen[key]) continue
    seen[key] = true
    if (!byApp[application]) byApp[application] = []
    byApp[application].push(kindLabel)
    count++
  }
  var lines = Object.keys(byApp).sort().map(function(application) {
    return application + ": " + byApp[application].sort().join(", ")
  })
  return {title: "Privacy activity " + phase, body: lines.join("\n"), count: count}
}

// Shared Omarchy bar controls render strings with Text.AutoText. Replace the
// metacharacters that can make attacker-controlled names look like rich text
// before passing them across that boundary. Plugin-owned Text items also set
// Text.PlainText explicitly; this helper is for shared components we cannot
// configure from a plugin.
function autoTextSafe(value) {
  return String(value === undefined || value === null ? "" : value)
    .replace(/&/g, "＆")
    .replace(/</g, "＜")
    .replace(/>/g, "＞")
}

function volumeMuted(output) {
  return /\[MUTED\]|Mute:\s*yes/i.test(String(output || ""))
}

function hasVolumeState(output) {
  return /\[MUTED\]|Volume:|Mute:\s*(yes|no)/i.test(String(output || ""))
}

function mutedFromExitCode(exitCode, previous) {
  if (Number(exitCode) === 10) return true
  if (Number(exitCode) === 11) return false
  return previous === true
}

function shouldAcceptControlProbe(kind, pendingKind) {
  return String(kind || "") !== String(pendingKind || "")
}

function label(kind) {
  if (kind === "microphone") return "Microphone"
  if (kind === "audio-output") return "Audio output"
  if (kind === "camera") return "Camera"
  if (kind === "screen-share") return "Screen sharing"
  if (kind === "screen-recording") return "Screen recording"
  if (kind === "screenshot") return "Screenshot"
  if (kind === "location") return "Location"
  return kind
}
