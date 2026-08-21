.pragma library

var KINDS = ["microphone", "audio-output", "camera", "screen-share", "screenshot", "screen-recording", "location"]

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
