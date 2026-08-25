const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const root = path.join(__dirname, "..")
const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"))
const bar = fs.readFileSync(path.join(root, "BarWidget.qml"), "utf8")
const surface = fs.readFileSync(path.join(root, "SettingsSurface.qml"), "utf8")
const integer = fs.readFileSync(path.join(root, "IntegerSetting.qml"), "utf8")
const activityCard = fs.readFileSync(path.join(root, "PrivacyActivityCard.qml"), "utf8")
const defaults = manifest.barWidget.defaults
const modelContext = {}
vm.createContext(modelContext)
vm.runInContext(fs.readFileSync(path.join(root, "Model.js"), "utf8").replace(/^\.pragma library\s*/, ""), modelContext)
const schema = new Map(manifest.barWidget.schema.map(entry => [entry.key, entry]))
const globalKeys = [
  "enabledKinds", "showIdle", "displayMode", "showControls", "idleOpacity", "deduplicateApps",
  "notificationKinds", "notifyOnActivity", "notifyOnStop", "notifyOnControlChanges",
  "notificationSuppressedApps", "historyEnabled", "blockableKinds", "directDeviceMonitoring",
  "directDevicePollSeconds", "showInferredAttribution", "locationPollSeconds", "recordingPollSeconds", "popupMaxHeight",
  "activeColorRole", "inactiveColorRole", "disabledColorRole", "disabledOpacity",
  "statusMarkerMode", "statePillStyle", "popupDensity", "showStatePills", "showSessionCounts", "animatePending",
  "barIconScale", "barItemSpacing", "barItemPadding", "barMarkerPosition", "showBarSessionCounts",
  "showBarActiveMarker", "showBarDisabledMarker", "showBarPendingMarker", "showBarDegradedMarker"
  , "barActiveMarkerIcon", "barDisabledMarkerIcon", "barPendingMarkerIcon", "barDegradedMarkerIcon"
]

assert.deepEqual(
  JSON.parse(JSON.stringify(modelContext.sanitizeSettings(defaults))),
  Object.assign({}, defaults, {_privacySettingsVersion: 1}),
  "every manifest default must survive the shared settings sanitizer"
)

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
assert.match(bar, /GlobalSettingsTab \{ label: "Appearance"; value: "appearance" \}/, "appearance settings need a dedicated page")
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
assert.match(bar, /settingsRequestSerial <= handledSettingsRequestSerial[\s\S]*?showGlobalSettings\(privacyService\.requestedSettingsPage\)/,
  "the focused widget must consume singleton settings requests")
assert.match(bar, /onSettingsRequestSerialChanged\(\) \{ root\.handleSettingsRequest\(\) \}/,
  "settings IPC page changes must apply while the popup remains open")
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
assert.ok(bar.indexOf("Private data") > bar.indexOf("id: monitoringSettingsPage"), "private storage controls belong on Monitoring")
assert.equal((bar.match(/label: "Keep recent activity"/g) || []).length, 1, "history controls must not be duplicated across settings pages")
assert.equal((bar.match(/text: "Export settings"/g) || []).length, 1, "settings transfer must have one clear home")
assert.match(activityCard, /HoverHandler[\s\S]*?selectedKind/, "hover should track keyboard selection without polling")
assert.match(activityCard, /itemStateLabel\(entry\)/, "every popup row must expose a textual semantic state")
assert.match(bar, /Status legend[\s\S]*?Active[\s\S]*?Disabled[\s\S]*?Verifying[\s\S]*?Degraded/, "monitoring settings must explain non-color status markers")
for (const label of ["Icon scale", "Space between bar items", "Bar item padding", "Bar status markers", "Marker position", "Show active status marker", "Show disabled status marker", "Show verifying status marker", "Show degraded status marker", "Popup state pills", "Popup density", "Show state pills", "Show popup session counts", "Show bar session counts", "Animate verification", "Disabled opacity"])
  assert.match(bar, new RegExp(label), `${label} must be exposed in global visual settings`)
assert.match(bar, /state === "active" \? showBarActiveMarker[\s\S]*?state === "disabled" \? showBarDisabledMarker[\s\S]*?state === "pending" \? showBarPendingMarker[\s\S]*?state === "unavailable" \? showBarDegradedMarker/,
  "bar status classes must have independent marker visibility")
for (const label of ["Active marker icon", "Disabled marker icon", "Verifying marker icon", "Degraded marker icon"])
  assert.match(bar, new RegExp(label), `${label} must be exposed for custom marker mode`)
assert.match(bar, /options: \["symbols", "letters", "custom", "off"\]/, "bar marker mode must expose custom glyphs")
assert.ok(bar.indexOf("id: appearanceSettingsPage") < bar.indexOf("Theme colors"), "theme controls belong on Appearance")
assert.ok(bar.indexOf("id: appearanceSettingsPage") < bar.indexOf("Status presentation"), "status controls belong on Appearance")
assert.match(bar, /"1234"[\s\S]*?\["general", "appearance", "alerts", "monitoring"\]/, "settings keyboard shortcuts must cover all pages")
assert.match(bar, /var count = Model\.privacySessionCount\(entry, showBarSessionCounts\)/, "bar counts must not depend on popup-count visibility")
assert.match(bar, /persistItemStatusMarker/, "per-item settings must control marker visibility")
assert.match(bar, /function canMoveItem\(kind, delta\)/, "device placement must expose boundary-aware movement")
assert.match(bar, /text: "Move left"[\s\S]*?enabled: root\.canMoveItem\(root\.editingKind, -1\)/,
  "device placement must disable unavailable left movement")
assert.match(bar, /text: "Move right"[\s\S]*?enabled: root\.canMoveItem\(root\.editingKind, 1\)/,
  "device placement must disable unavailable right movement")
assert.match(bar, /visible: root\.editingKind !== "" && !root\.showingGlobalSettings[\s\S]*?SettingsSurface\s*\{[\s\S]*?text: "Appearance"/,
  "device appearance must use the shared settings surface")
for (const section of ["Bar placement", "Backend", "Diagnostics", "Reset device appearance"])
  assert.match(bar, new RegExp(`SettingsSurface\\s*\\{[\\s\\S]*?text: "${section}"`), `${section} must use the shared device settings structure`)
assert.match(bar, /label: "Show status markers for this device"[\s\S]*?Global status-marker rules still apply/,
  "device marker wording must explain its relationship to global rules")
for (const label of ["Bar preview", "Display label", "Device icon"])
  assert.match(bar, new RegExp(`text: "${label}"`), `${label} must remain visible without relying on input placeholders`)
assert.match(bar, /Shared by microphone and audio output/, "shared audio backend scope must be explicit")
assert.match(bar, /function moveDeviceEditor\(delta\)/, "device editor must support adjacent navigation")
assert.match(bar, /root\.editingKind !== "" && dx !== 0[\s\S]*?root\.moveDeviceEditor\(dx\)/,
  "left and right keys must navigate device editors")
assert.match(bar, /text: "Previous device"[\s\S]*?text: "Next device"/, "device pages must expose visible adjacent navigation")
assert.match(bar, /function resetDeviceBackend\(kind\)/, "backend reset must be scoped by device")
assert.match(bar, /text: "Reset all device settings"/, "device pages must offer a complete reset")
assert.match(bar, /property bool dirty:[\s\S]*?Unsaved changes[\s\S]*?enabled: parent\.dirty/,
  "device text editors must expose dirty state and disable redundant saves")
assert.match(bar, /Model\.deviceBackendValidation\("screenshot"[\s\S]*?enabled: parent\.dirty && parent\.validation\.valid/,
  "custom screenshot settings must validate before saving")
assert.match(bar, /Model\.deviceBackendValidation\("screen-recording"[\s\S]*?enabled: parent\.dirty && parent\.validation\.valid/,
  "custom recording settings must validate before saving")
assert.match(bar, /maximumLength: 4096/, "custom command editors must expose sanitizer-aligned bounds")
assert.match(bar, /root\.deviceAppearanceCustomized\(root\.editingKind\) \? "Customized" : "Using global defaults"/,
  "device appearance must identify inherited versus customized state")
assert.match(bar, /text: "Reset device appearance"[\s\S]*?default label, icon, colors, idle visibility, idle opacity, and status-marker visibility/,
  "device reset copy must match every reset field")
assert.match(activityCard, /controller\.statePillStyle === "filled"[\s\S]*?controller\.statePillStyle === "minimal"/, "state-pill styles must alter fill and border presentation")
assert.match(activityCard, /controller\.popupDensity === "compact"[\s\S]*?verticalPadding/, "popup density must alter row spacing")
assert.match(bar, /running:\s*modelData\.pending && root\.animatePending/, "pending animation must honor its visual setting")
assert.match(bar, /!contentFlick\.moving/, "duration refreshes must not churn the layout while the user scrolls")

console.log("global settings contract tests passed")
