const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")

const root = path.join(__dirname, "..")
const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"))
const bar = fs.readFileSync(path.join(root, "BarWidget.qml"), "utf8")
const surface = fs.readFileSync(path.join(root, "SettingsSurface.qml"), "utf8")
const integer = fs.readFileSync(path.join(root, "IntegerSetting.qml"), "utf8")
const activityCard = fs.readFileSync(path.join(root, "PrivacyActivityCard.qml"), "utf8")
const defaults = manifest.barWidget.defaults
const schema = new Map(manifest.barWidget.schema.map(entry => [entry.key, entry]))
const globalKeys = [
  "enabledKinds", "showIdle", "displayMode", "showControls", "idleOpacity", "deduplicateApps",
  "notificationKinds", "notifyOnActivity", "notifyOnStop", "notifyOnControlChanges",
  "notificationSuppressedApps", "historyEnabled", "blockableKinds", "directDeviceMonitoring",
  "directDevicePollSeconds", "showInferredAttribution", "locationPollSeconds", "recordingPollSeconds", "popupMaxHeight",
  "activeColorRole", "inactiveColorRole"
]

for (const key of globalKeys) {
  assert.ok(Object.hasOwn(defaults, key), `global default missing: ${key}`)
  assert.ok(schema.has(key), `global schema missing: ${key}`)
  if (!["enabledKinds", "notificationKinds", "blockableKinds"].includes(key))
    assert.ok(bar.includes(`{${key}:`) || bar.includes(`{${key}: `) || bar.includes(`settingKey: "${key}"`), `global editor is not wired to persist ${key}`)
  const entry = schema.get(key)
  assert.deepEqual(entry.defaultValue, defaults[key], `schema/default mismatch: ${key}`)
  if (entry.type === "enum") assert.ok(entry.options.includes(entry.defaultValue), `enum default is unavailable: ${key}`)
  if (entry.type === "integer" || entry.type === "number") {
    assert.ok(entry.defaultValue >= entry.min && entry.defaultValue <= entry.max, `numeric default out of bounds: ${key}`)
  }
}

assert.match(bar, /showingGlobalSettings/)
assert.match(bar, /GlobalSettingsTab/)
assert.match(bar, /Reset global settings/)
for (const selector of ["Monitored activity", "Activity notifications", "Preventative controls"])
  assert.match(bar, new RegExp(`label:\\s*"${selector}"`), `${selector} must remain configurable`)
assert.match(bar, /ColumnLayout\s*\{\s*id:\s*activityRows[\s\S]*?visible:\s*root\.editingKind === "" && !root\.showingGlobalSettings[\s\S]*?Repeater\s*\{/,
  "activity delegates must be owned by a visual container that hides them on settings pages")
assert.match(bar, /model:\s*root\.editingKind === "" && !root\.showingGlobalSettings\s*\?[\s\S]*?root\.displayedActivityItems[\s\S]*?:\s*\[\]/,
  "settings pages must remove main-widget delegates from the object tree")
assert.match(bar, /delegate:\s*PrivacyActivityCard\s*\{[\s\S]*?entry:\s*modelData[\s\S]*?controller:\s*root/,
  "activity presentation must be isolated in its tested card component")
assert.match(bar, /manageIpc:\s*false/, "per-monitor panels must delegate IPC routing to the singleton service and focused-monitor shell router")
assert.match(bar, /privacyService\.settingsRequestSerial > handledSettingsRequestSerial[\s\S]*?showGlobalSettings\(privacyService\.requestedSettingsPage\)/,
  "the focused widget must consume singleton settings requests")
assert.match(surface, /default property alias content:/, "settings groups need a reusable visual surface")
assert.match(integer, /IntValidator[\s\S]*?bottom:[\s\S]*?top:/, "integer settings must enforce their declared bounds")
assert.match(bar, /Loader\s*\{\s*id:\s*globalSettingsPageLoader[\s\S]*?sourceComponent:[\s\S]*?globalSettingsPage/, "only the active settings page should be instantiated")
assert.match(bar, /SettingsSurface\s*\{/, "settings pages should share consistent surface layout")
assert.match(activityCard, /required property var controller[\s\S]*?property var entry:/, "activity card must expose one deep controller/entry interface")
assert.match(bar, /IntegerSetting\s*\{/, "bounded polling settings should share validated editing behavior")
assert.match(bar, /monitoringTelemetryText\(\)/, "the Monitoring page must expose observer telemetry")
assert.match(bar, /settingsMutationPending/, "settings writes must preserve the open editor across shell config reloads")
assert.match(bar, /Model\.sanitizeSettings\(candidate\)/, "settings writes must pass through the versioned sanitizer")
assert.match(bar, /privacy-settings[\s\S]*?settingsTransferProc/, "settings transfer must use the bounded helper")
assert.match(activityCard, /HoverHandler[\s\S]*?selectedKind/, "hover should track keyboard selection without polling")
assert.match(bar, /!contentFlick\.moving/, "duration refreshes must not churn the layout while the user scrolls")

console.log("global settings contract tests passed")
