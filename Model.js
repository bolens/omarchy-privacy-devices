.pragma library

var KINDS = ["microphone", "audio-output", "camera", "screen-share", "screenshot", "screen-recording", "location"]
var SETTINGS_VERSION = 1
var SETTINGS_PAGES = ["general", "appearance", "alerts", "monitoring"]
var SETTINGS_SECTIONS = {
  general: ["behavior"],
  appearance: ["bar-layout", "theme-colors", "status-presentation"],
  alerts: ["notifications"],
  monitoring: ["enhanced-coverage", "fallback-polling", "private-data", "status-legend", "observer-health"]
}

function settingsPage(value) {
  var page = String(value || "general")
  return SETTINGS_PAGES.indexOf(page) >= 0 ? page : "general"
}

function settingsDeepLink(page, section) {
  var requestedPage = String(page || "general")
  var normalizedPage = settingsPage(requestedPage)
  var requestedSection = String(section || "")
  var sections = SETTINGS_SECTIONS[normalizedPage] || []
  return {
    page: normalizedPage,
    section: normalizedPage === requestedPage && sections.indexOf(requestedSection) >= 0 ? requestedSection : ""
  }
}

function settingsScrollPosition(targetY, contentHeight, viewportHeight) {
  var target = Number(targetY)
  var maximum = Math.max(0, Number(contentHeight) - Number(viewportHeight))
  if (!isFinite(target) || !isFinite(maximum)) return 0
  return Math.max(0, Math.min(target, maximum))
}

function boundedPlainText(value, maximumLength) {
  if (typeof value !== "string") return ""
  return Array.from(value.replace(/[\x00-\x1f\x7f]/g, "").trim()).slice(0, maximumLength).join("")
}

function sanitizeSettings(data) {
  var source = data && typeof data === "object" && !Array.isArray(data) ? data : {}
  var clean = {}, index, key
  var booleans = {showIdle:true, showControls:true, deduplicateApps:true, notifyOnActivity:true, notifyOnStop:false,
    notifyOnControlChanges:true, historyEnabled:false, directDeviceMonitoring:false, showInferredAttribution:true,
    showStatePills:true, showSessionCounts:true, showBarSessionCounts:true, animatePending:true,
    showBarActiveMarker:true, showBarDisabledMarker:true, showBarPendingMarker:true, showBarDegradedMarker:true}
  for (key in booleans) if (source[key] !== undefined) clean[key] = typeof source[key] === "boolean" ? source[key] : booleans[key]
  var integers = {directDevicePollSeconds:[2,60,5], locationPollSeconds:[5,300,15], recordingPollSeconds:[1,60,2], popupMaxHeight:[360,900,620], barItemSpacing:[0,12,0], barItemPadding:[2,12,5]}
  for (key in integers) if (source[key] !== undefined) {
    var bounds = integers[key], parsed = Math.round(Number(source[key]))
    if (!isFinite(parsed)) parsed = bounds[2]
    clean[key] = Math.max(bounds[0], Math.min(bounds[1], parsed))
  }
  if (source.idleOpacity !== undefined) {
    var opacity = Number(source.idleOpacity)
    clean.idleOpacity = Math.max(0.1, Math.min(1, isFinite(opacity) ? opacity : 0.45))
  }
  if (source.disabledOpacity !== undefined) {
    var disabledOpacity = Number(source.disabledOpacity)
    clean.disabledOpacity = Math.max(0.25, Math.min(1, isFinite(disabledOpacity) ? disabledOpacity : 1))
  }
  var reals = {barIconScale:[0.75,1.5,1]}
  for (key in reals) if (source[key] !== undefined) {
    var realBounds = reals[key], realValue = Number(source[key])
    if (!isFinite(realValue)) realValue = realBounds[2]
    clean[key] = Math.max(realBounds[0], Math.min(realBounds[1], realValue))
  }
  var kindLists = ["enabledKinds", "order", "notificationKinds", "blockableKinds"]
  for (index = 0; index < kindLists.length; index++) if (Array.isArray(source[kindLists[index]]))
    clean[kindLists[index]] = unique(source[kindLists[index]].filter(function(value) { return KINDS.indexOf(value) >= 0 })).slice(0, KINDS.length)
  var stringLists = ["excludedApps", "hiddenApps", "notificationSuppressedApps", "cameraKeywords", "screenShareKeywords"]
  for (index = 0; index < stringLists.length; index++) if (Array.isArray(source[stringLists[index]]))
    clean[stringLists[index]] = unique(source[stringLists[index]].filter(function(value) { return typeof value === "string" && value.trim() !== "" }).map(function(value) { return value.trim().slice(0, 256) })).slice(0, 256)
  var enums = {displayMode:["icons","active-count","active-only"], statusMarkerMode:["symbols","letters","custom","off"], barMarkerPosition:["after","before"], statePillStyle:["filled","outline","minimal"], popupDensity:["comfortable","compact"], recordingBackend:["omarchy","gpu-screen-recorder","wf-recorder","custom"],
    audioControlBackend:["auto","pactl","wpctl"], screenshotBackend:["omarchy","grim","grim-satty","hyprshot","flameshot","custom"],
    activeColorRole:["bar-active","urgent","accent","foreground"], inactiveColorRole:["muted","foreground","accent"], disabledColorRole:["urgent","muted","accent","foreground","bar-active"],
    mutedColorRole:["urgent","muted","bar-active","accent","foreground"], unmutedColorRole:["foreground","bar-active","accent","muted","urgent"]}
  for (key in enums) if (source[key] !== undefined) clean[key] = enums[key].indexOf(source[key]) >= 0 ? source[key] : enums[key][0]
  var markerGlyphs = {barActiveMarkerIcon:"●", barDisabledMarkerIcon:"⊘", barPendingMarkerIcon:"…", barDegradedMarkerIcon:"!"}
  for (key in markerGlyphs) if (source[key] !== undefined) {
    var glyph = boundedPlainText(source[key], 8)
    clean[key] = glyph || markerGlyphs[key]
  }
  var commands = ["screenshotCustomCommand", "recordingCustomStartCommand", "recordingCustomStopCommand"]
  for (index = 0; index < commands.length; index++) if (source[commands[index]] !== undefined) clean[commands[index]] = String(source[commands[index]] || "").slice(0, 4096)
  var processNames = ["screenshotProcessName", "recordingProcessName"]
  for (index = 0; index < processNames.length; index++) if (source[processNames[index]] !== undefined) clean[processNames[index]] = boundedPlainText(source[processNames[index]], 256)
  var maps = ["icons", "itemColorRoles", "itemIdleOpacity", "itemIdleVisibility", "itemStatusMarkerVisibility", "itemLabels"]
  for (index = 0; index < maps.length; index++) if (source[maps[index]] && typeof source[maps[index]] === "object" && !Array.isArray(source[maps[index]])) {
    var mapName = maps[index], map = {}, keys = Object.keys(source[mapName]).filter(function(value) { return KINDS.indexOf(value) >= 0 }).slice(0, KINDS.length)
    for (var mapIndex = 0; mapIndex < keys.length; mapIndex++) {
      var mapKey = keys[mapIndex], mapValue = source[mapName][mapKey]
      if (mapName === "itemIdleVisibility" || mapName === "itemStatusMarkerVisibility") map[mapKey] = mapValue === true
      else if (mapName === "itemIdleOpacity") {
        var itemOpacity = Number(mapValue)
        map[mapKey] = Math.max(0.1, Math.min(1, isFinite(itemOpacity) ? itemOpacity : 0.45))
      } else if (mapName === "itemColorRoles") {
        if (!mapValue || typeof mapValue !== "object" || Array.isArray(mapValue)) continue
        var roles = {}, roleOptions = {
          active:["bar-active","urgent","accent","foreground"],
          inactive:["muted","foreground","accent"],
          disabled:["urgent","muted","accent","foreground","bar-active"],
          muted:["urgent","muted","bar-active","accent","foreground"],
          unmuted:["foreground","bar-active","accent","muted","urgent"]
        }
        var roleNames = Object.keys(roleOptions)
        for (var roleIndex = 0; roleIndex < roleNames.length; roleIndex++) {
          var roleName = roleNames[roleIndex]
          if (roleOptions[roleName].indexOf(mapValue[roleName]) >= 0) roles[roleName] = mapValue[roleName]
        }
        if (Object.keys(roles).length) map[mapKey] = roles
      } else if (mapName === "icons") {
        var icon = boundedPlainText(mapValue, 8)
        if (icon) map[mapKey] = icon
      } else if (mapName === "itemLabels") {
        var itemLabel = boundedPlainText(mapValue, 128)
        if (itemLabel) map[mapKey] = itemLabel
      }
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

function hasItemOverride(settings, group, kind, field) {
  var map = settings && settings[group]
  if (!map || typeof map !== "object" || Array.isArray(map) || !Object.prototype.hasOwnProperty.call(map, kind)) return false
  if (field === undefined) return true
  var entry = map[kind]
  return entry && typeof entry === "object" && !Array.isArray(entry) && Object.prototype.hasOwnProperty.call(entry, field)
}

function itemOverrideMode(settings, group, kind) {
  if (!hasItemOverride(settings, group, kind)) return "inherit"
  return settings[group][kind] === true ? "show" : "hide"
}

function deviceBackendValidation(kind, settings) {
  var source = settings && typeof settings === "object" ? settings : {}
  if (kind === "screenshot" && source.screenshotBackend === "custom" && !String(source.screenshotCustomCommand || "").trim())
    return {valid: false, message: "Enter a screenshot command."}
  if (kind === "screen-recording" && source.recordingBackend === "custom") {
    if (!String(source.recordingProcessName || "").trim()) return {valid: false, message: "Enter the recorder process name."}
    if (!String(source.recordingCustomStartCommand || "").trim() || !String(source.recordingCustomStopCommand || "").trim())
      return {valid: false, message: "Enter start and stop commands."}
  }
  return {valid: true, message: ""}
}

function privacyVisualState(entry) {
  entry = entry || {}
  if (entry.pending === true) return "pending"
  if (entry.health && entry.health.status && entry.health.status !== "healthy") return "unavailable"
  var disableCapable = ["microphone", "audio-output", "camera", "screen-share", "location"].indexOf(String(entry.kind || "")) >= 0
  if (disableCapable && entry.controlEnabled === false) return "disabled"
  return entry.active === true ? "active" : "idle"
}

function privacyStateLabel(entry) {
  var labels = {pending: "VERIFYING", unavailable: "DEGRADED", disabled: "DISABLED", active: "ACTIVE", idle: "IDLE"}
  return labels[privacyVisualState(entry)] || "IDLE"
}

function privacyStateMarker(entry, mode, visible, customMarkers) {
  if (visible === false || mode === "off") return ""
  var state = privacyVisualState(entry)
  if (mode === "custom") {
    var custom = customMarkers && typeof customMarkers === "object" ? customMarkers : {}
    var customDefaults = {pending: "…", unavailable: "!", disabled: "⊘", active: "●", idle: ""}
    return custom[state] === undefined ? customDefaults[state] || "" : String(custom[state])
  }
  if (mode === "letters") {
    var letters = {pending: "V", unavailable: "!", disabled: "X", active: "A", idle: ""}
    return letters[state] || ""
  }
  var symbols = {pending: "…", unavailable: "!", disabled: "⊘", active: "●", idle: ""}
  return symbols[state] || ""
}

function privacySessionCount(entry, visible) {
  if (visible === false) return 0
  var sessions = entry && Array.isArray(entry.sessions) ? entry.sessions.length : 0
  return sessions > 1 ? sessions : 0
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
    return "screen-share"
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
  var normalized = {
    kind: boundedPlainText(String(value.kind || "unknown"), 64) || "unknown",
    application: boundedPlainText(String(value.application || "Unknown application"), 256) || "Unknown application",
    device: boundedPlainText(String(value.device || "Unknown device"), 512) || "Unknown device",
    source: boundedPlainText(String(value.source || "unknown"), 64) || "unknown",
    confidence: boundedPlainText(String(value.confidence || "inferred"), 32) || "inferred",
    detail: boundedPlainText(String(value.detail || ""), 512),
    icon: notificationIconName(value.icon)
  }
  normalized.id = sessionId(normalized)
  return normalized
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

function invalidateObserverSessions(sessions, source, suppressedSources) {
  var rows = Array.isArray(sessions) ? sessions : []
  var found = false
  for (var index = 0; index < rows.length; index++) {
    if (rows[index].source === source) { found = true; break }
  }
  if (!found) return {active: rows, suppressedSources: suppressedSources || {}, changed: false}
  var suppressed = Object.assign({}, suppressedSources || {})
  suppressed[source] = true
  return {
    active: rows.filter(function(session) { return session.source !== source }),
    suppressedSources: suppressed,
    changed: true
  }
}

function partitionObserverRecoveryStarts(started, suppressedSources) {
  var rows = Array.isArray(started) ? started : []
  var suppressed = suppressedSources || {}
  var notifyable = []
  var recovered = {}
  for (var index = 0; index < rows.length; index++) {
    var session = rows[index]
    if (suppressed[session.source]) recovered[session.source] = true
    else notifyable.push(session)
  }
  var sources = Object.keys(recovered)
  if (!sources.length) return {notifyable: notifyable, suppressedSources: suppressed}
  var remaining = Object.assign({}, suppressed)
  for (index = 0; index < sources.length; index++) delete remaining[sources[index]]
  return {notifyable: notifyable, suppressedSources: remaining}
}

function publishableSessionTransitions(transition, initialized) {
  transition = transition || {}
  return initialized === true
    ? {started: Array.isArray(transition.started) ? transition.started : [], stopped: Array.isArray(transition.stopped) ? transition.stopped : []}
    : {started: [], stopped: []}
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

function controlTransactionTransition(current, event, now) {
  event = event || {}
  var timestamp = Number(now)
  if (event.type === "begin") return {
    status: "applying", expectedEnabled: event.expectedEnabled === true,
    startedAt: timestamp, finishedAt: 0, exitCode: -1, code: "applying"
  }
  if (!current || (current.status !== "applying" && current.status !== "verifying")) return current
  if (event.type === "command" && current.status === "applying") {
    if (Number(event.exitCode) !== 0) return {
      status: "failed", expectedEnabled: current.expectedEnabled === true,
      startedAt: current.startedAt, finishedAt: timestamp,
      exitCode: Number(event.exitCode), code: "command_failed"
    }
    return {
      status: "verifying", expectedEnabled: current.expectedEnabled === true,
      startedAt: current.startedAt, finishedAt: 0, exitCode: 0,
      deadline: timestamp + 5000, code: "verifying"
    }
  }
  if (event.type === "observation" && current.status === "verifying") {
    if (event.valid !== true) return {
      status: "failed", expectedEnabled: current.expectedEnabled === true,
      startedAt: current.startedAt, finishedAt: timestamp,
      exitCode: 12, code: "verification_probe_failed"
    }
    if ((event.enabled === true) !== current.expectedEnabled) return current
    return {
      status: "succeeded", expectedEnabled: current.expectedEnabled === true,
      startedAt: current.startedAt, finishedAt: timestamp,
      exitCode: 0, code: "verified"
    }
  }
  if (event.type === "timeout" && current.status === "verifying" && timestamp >= Number(current.deadline)) return {
    status: "failed", expectedEnabled: current.expectedEnabled === true,
    startedAt: current.startedAt, finishedAt: timestamp,
    exitCode: 14, code: "verification_timeout"
  }
  return current
}

function controlRequestStatus(request) {
  var state = request || {}
  if (state.known !== true) return "unsupported"
  if (state.enabled !== true) return "disabled"
  if (state.serviceOwned !== true) return "unsupported"
  if (state.dependenciesReady !== true) return "unavailable"
  if (state.pending === true || state.processBusy === true) return "busy"
  return "ok"
}

function appendHistory(history, session, now, limits) {
  limits = limits || {}
  var maxEntries = Math.max(1, Number(limits.maxEntries || 100))
  var maxAgeMs = Math.max(1, Number(limits.maxAgeMs || 7 * 24 * 60 * 60 * 1000))
  var cutoff = Number(now) - maxAgeMs
  var seen = {}
  var result = [session].concat(Array.isArray(history) ? history : []).filter(function(entry) {
    entry = entry || {}
    return Number(entry.endedAt || entry.startedAt || 0) >= cutoff
  }).filter(function(entry) {
    var identity = String(entry.id || [entry.kind, entry.application, entry.device, entry.source].join("|"))
      + "\u0000" + String(entry.endedAt || 0)
    if (seen[identity]) return false
    seen[identity] = true
    return true
  })
  return result.slice(0, maxEntries)
}

function historyLoadAccepted(loadGeneration, currentGeneration, enabled) {
  return Number(loadGeneration) === Number(currentGeneration) && enabled === true
}

function freshnessAgeSeconds(timestamp, now) {
  var value = Number(timestamp)
  var current = Number(now)
  if (!(value > 0) || !isFinite(current)) return -1
  return Math.max(0, Math.round((current - value) / 1000))
}

function observerHeartbeatState(lastSeen, startedAt, now, heartbeatSeconds) {
  var heartbeat = Number(heartbeatSeconds)
  if (!isFinite(heartbeat)) heartbeat = 5
  heartbeat = Math.max(1, Math.min(60, heartbeat))
  var threshold = Math.max(15000, heartbeat * 3000)
  var seen = Number(lastSeen)
  var started = Number(startedAt)
  var anchor = Math.max(isFinite(seen) ? seen : 0, isFinite(started) ? started : 0)
  var current = Number(now)
  return {
    stale: !(anchor > 0) || !isFinite(current) || current - anchor > threshold,
    ageSeconds: freshnessAgeSeconds(anchor, current),
    thresholdMilliseconds: threshold
  }
}

function updateObserverHealth(health, source, status, code, reason) {
  var currentHealth = health && typeof health === "object" ? health : {}
  var current = currentHealth[source] || {}
  if (current.status === status && current.code === code && current.reason === reason) return currentHealth
  var next = Object.assign({}, currentHealth)
  next[source] = {status: status, source: source, code: code, reason: reason}
  return next
}

function monitoringTelemetryText(data) {
  if (!data || typeof data !== "object") return "Monitoring telemetry unavailable"
  function age(value) {
    var seconds = Number(value)
    return isFinite(seconds) && seconds >= 0 ? Math.round(seconds) + "s ago" : "waiting"
  }
  function retry(value) {
    var milliseconds = Number(value)
    return isFinite(milliseconds) && milliseconds >= 0 ? Math.round(milliseconds) + "ms" : "unknown"
  }
  var result = "PipeWire: " + (data.pipewireReactive === true ? "reactive" : "unavailable")
    + "\nSession state: " + age(data.lastSessionRefreshAgeSeconds)
    + "\nFallback probes: " + age(data.lastFallbackRefreshAgeSeconds)
    + " · observer " + (data.fallbackObserverRunning === true ? "running" : "retrying")
    + " · heartbeat " + age(data.fallbackObserverHeartbeatAgeSeconds)
    + " · retry " + retry(data.fallbackObserverRetryMilliseconds)
    + "\nDirect-device observer: " + (data.directDeviceEnabled === true
      ? (data.directObserverRunning === true ? "running" : "retrying") : "disabled")
  if (data.directDeviceEnabled === true) result += " · heartbeat " + age(data.directHeartbeatAgeSeconds)
    + " · retry " + retry(data.directObserverRetryMilliseconds)
  return result
}

// Serial subprocess queues share the same supersession rule: finish the active
// probe, discard work derived from stale settings, then rebuild exactly once.
function scheduleProbeRefresh(processBusy, requestedKinds) {
  return {
    queue: processBusy === true ? [] : (Array.isArray(requestedKinds) ? requestedKinds.slice() : []),
    refreshPending: processBusy === true
  }
}

function nextProbeAction(queue, refreshPending, processRunning) {
  var remaining = Array.isArray(queue) ? queue.slice() : []
  var pending = refreshPending === true
  if (processRunning === true) return {action: "wait", kind: "", queue: remaining, refreshPending: pending}
  if (remaining.length > 0) return {action: "probe", kind: remaining.shift(), queue: remaining, refreshPending: pending}
  if (pending) return {action: "refresh", kind: "", queue: remaining, refreshPending: true}
  return {action: "idle", kind: "", queue: remaining, refreshPending: false}
}

function nextNavigationKind(kinds, currentKind, delta) {
  var rows = Array.isArray(kinds) ? kinds : []
  if (!rows.length) return ""
  var current = String(currentKind || "")
  var index = rows.indexOf(current)
  if (index < 0) return String(rows[0] || "")
  var step = Number(delta)
  if (!isFinite(step) || step === 0) return current
  var target = Math.max(0, Math.min(rows.length - 1, index + (step < 0 ? -1 : 1)))
  return String(rows[target] || "")
}

function activationKind(kinds, currentKind) {
  var rows = Array.isArray(kinds) ? kinds : []
  if (!rows.length) return ""
  var current = String(currentKind || "")
  return rows.indexOf(current) >= 0 ? current : String(rows[0] || "")
}

function popupDismissalAction(editingKind, showingGlobalSettings, showingHistory) {
  if (String(editingKind || "") !== "") return "device"
  if (showingGlobalSettings === true) return "settings"
  if (showingHistory === true) return "history"
  return "popup"
}

// Ignore timestamps that naturally advance on every observation. Consumers only
// need a new array when something they render or act upon actually changed.
function sessionsEquivalent(left, right) {
  left = Array.isArray(left) ? left : []
  right = Array.isArray(right) ? right : []
  if (left.length !== right.length) return false
  var previous = {}
  for (var index = 0; index < left.length; index++) previous[String(left[index].id || "")] = left[index]
  var fields = ["kind", "application", "device", "source", "confidence", "detail", "icon"]
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

// While a user scrolls, defer text/session churn but never delay a privacy
// state, health, membership, or order change that affects visible meaning.
function activityCriticalStateEquivalent(left, right) {
  left = Array.isArray(left) ? left : []
  right = Array.isArray(right) ? right : []
  if (left.length !== right.length) return false
  var fields = ["kind", "active", "controlEnabled", "pending"]
  for (var index = 0; index < left.length; index++) {
    var previous = left[index] || {}
    var candidate = right[index] || {}
    for (var fieldIndex = 0; fieldIndex < fields.length; fieldIndex++) {
      var field = fields[fieldIndex]
      if (previous[field] !== candidate[field]) return false
    }
    var previousHealth = previous.health || {}
    var candidateHealth = candidate.health || {}
    if (previousHealth.status !== candidateHealth.status) return false
  }
  return true
}

function deviceDiagnosticPresentation(data) {
  data = data || {}
  var health = data.health || {status: "unavailable", summary: ""}
  var healthStatus = String(health.status || "unavailable")
  var dependenciesReady = data.dependenciesReady === true
  var probeExitCode = Number(data.probeExitCode)
  var controlExitCode = Number(data.controlExitCode)
  var transaction = data.controlTransaction
    ? String(data.controlTransaction.status || "unknown") + " (" + String(data.controlTransaction.code || "unknown") + ")"
    : "None"
  return {
    healthStatus: healthStatus,
    dependenciesReady: dependenciesReady,
    dependencyDescription: String(data.dependencyDescription || ""),
    rows: [
      {label: "Backend", value: String(data.backend || "Unknown"), urgent: false},
      {label: "Dependencies", value: dependenciesReady ? "Ready" : String(data.dependencyDescription || "Missing"), urgent: !dependenciesReady},
      {label: "Monitoring", value: healthStatus + (health.summary ? " · " + String(health.summary) : ""), urgent: healthStatus !== "healthy"},
      {label: "Activity", value: data.active ? "Active" : "Idle", urgent: false},
      {label: "Applications", value: data.apps && data.apps.length ? data.apps.join(", ") : "None detected", urgent: false},
      {label: "Control", value: String(data.controlState || "Unavailable") + " · Transaction: " + transaction, urgent: false},
      {label: "Exit codes", value: "Probe " + (!isFinite(probeExitCode) || probeExitCode < 0 ? "not run" : probeExitCode) + " · Control " + (!isFinite(controlExitCode) || controlExitCode < 0 ? "not used" : controlExitCode), urgent: false}
    ]
  }
}

function itemTooltipAction(entry) {
  entry = entry || {}
  if (entry.dependenciesReady !== true) return "Left click to install requirements"
  if (entry.controllable !== true) return "Left click for details"
  if (entry.kind === "screenshot") return "Left click to take a screenshot"
  if (entry.kind === "screen-recording") return entry.controlEnabled === true
    ? "Left click to stop recording" : "Left click to start recording"
  if (entry.kind === "microphone" || entry.kind === "audio-output") return entry.controlEnabled === true
    ? "Left click to mute" : "Left click to unmute"
  return entry.controlEnabled === true ? "Left click to block" : "Left click to allow"
}

// Appearance and policy edits must not launch subprocess probes. Keep this list
// explicit so only monitoring changes invalidate the operational cache.
function operationalSignature(settings) {
  settings = settings || {}
  var keys = [
    "enabledKinds", "blockableKinds", "directDeviceMonitoring", "directDevicePollSeconds",
    "audioControlBackend", "recordingBackend", "screenshotBackend", "recordingPollSeconds",
    "recordingProcessName", "screenshotProcessName",
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

function historyAgeLabel(endedAt, now) {
  var ageSeconds = Math.max(0, Math.floor((Number(now || Date.now()) - Number(endedAt || 0)) / 1000))
  if (ageSeconds < 60) return "Just now"
  var minutes = Math.floor(ageSeconds / 60)
  if (minutes < 60) return minutes + "m ago"
  var hours = Math.floor(minutes / 60)
  if (hours < 24) return hours + "h ago"
  return Math.floor(hours / 24) + "d ago"
}

function filterHistory(history, query) {
  var rows = Array.isArray(history) ? history : []
  var needle = String(query || "").replace(/[\u0000-\u001f\u007f]/g, " ").trim().toLowerCase().slice(0, 128)
  if (!needle) return rows.slice()
  return rows.filter(function(entry) {
    entry = entry || {}
    return [entry.application, entry.device, entry.source, entry.confidence, label(entry.kind)]
      .map(function(value) { return String(value || "").toLowerCase() })
      .join("\n").indexOf(needle) !== -1
  })
}

function historyPeriodLabel(endedAt, now) {
  var age = Math.max(0, Number(now || Date.now()) - Number(endedAt || 0))
  var day = 24 * 60 * 60 * 1000
  if (age < day) return "Today"
  if (age < 2 * day) return "Yesterday"
  return "Earlier this week"
}

function historyCountLabel(visibleCount, totalCount) {
  var visible = Math.max(0, Math.floor(Number(visibleCount) || 0))
  var total = Math.max(visible, Math.floor(Number(totalCount) || 0))
  if (visible !== total) return visible + " of " + total
  return visible + (visible === 1 ? " entry" : " entries")
}

function coalesceNotificationEvents(events) {
  var rows = Array.isArray(events) ? events : []
  if (!rows.length) return {title: "Privacy activity", body: "", count: 0, icon: "security-high-symbolic"}
  var phase = String(rows[0].phase || "started")
  var byApp = {}, seen = {}, icons = {}, kinds = {}, count = 0
  for (var index = 0; index < rows.length; index++) {
    var event = rows[index] || {}
    var application = String(event.application || "Unknown application")
    var kind = String(event.kind || "")
    var kindLabel = label(kind)
    var icon = notificationIconName(event.icon)
    var key = phase + "\u0000" + application.toLowerCase() + "\u0000" + kindLabel
    if (seen[key]) continue
    seen[key] = true
    if (!byApp[application]) byApp[application] = []
    byApp[application].push(kindLabel)
    if (icon) icons[icon] = true
    if (kind) kinds[kind] = true
    count++
  }
  var lines = Object.keys(byApp).sort().map(function(application) {
    return application + ": " + byApp[application].sort().join(", ")
  })
  var applications = Object.keys(byApp)
  var iconNames = Object.keys(icons)
  var kindNames = Object.keys(kinds)
  var fallbackIcon = kindNames.length === 1 ? notificationKindIcon(kindNames[0]) : "security-high-symbolic"
  var notificationIcon = applications.length === 1 && iconNames.length === 1
    ? iconNames[0]
    : fallbackIcon
  return {title: "Privacy activity " + phase, body: lines.join("\n"), count: count,
    icon: notificationIcon, fallbackIcon: fallbackIcon}
}

function notificationIconName(value) {
  var name = boundedPlainText(String(value || ""), 256)
  return /^[A-Za-z0-9][A-Za-z0-9._-]{0,255}$/.test(name) ? name : ""
}

function notificationKindIcon(kind) {
  var icons = {
    microphone: "audio-input-microphone-symbolic",
    "audio-output": "audio-speakers-symbolic",
    camera: "camera-web-symbolic",
    "screen-share": "video-display-symbolic",
    screenshot: "camera-photo-symbolic",
    "screen-recording": "media-record-symbolic",
    location: "find-location-symbolic"
  }
  return icons[String(kind || "")] || "security-high-symbolic"
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
