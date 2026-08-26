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
const deviceEditor = fs.readFileSync(path.join(root, "DeviceSettingsEditor.qml"), "utf8")
const deviceDiagnostics = fs.readFileSync(path.join(root, "DeviceDiagnostics.qml"), "utf8")
const settingsNavigation = fs.readFileSync(path.join(root, "PrivacySettingsNavigation.qml"), "utf8")
const confirmationController = fs.readFileSync(path.join(root, "PrivacyConfirmationController.qml"), "utf8")
const mutationController = fs.readFileSync(path.join(root, "PrivacySettingsMutationController.qml"), "utf8")
const messageSurface = fs.readFileSync(path.join(root, "PrivacyMessageSurface.qml"), "utf8")
const settingToggle = fs.readFileSync(path.join(root, "PrivacySettingToggle.qml"), "utf8")
const transferResult = fs.readFileSync(path.join(root, "PrivacySettingsTransferResult.qml"), "utf8")
const monitoringSettings = fs.readFileSync(path.join(root, "PrivacyMonitoringSettings.qml"), "utf8")
const audioEndpointSettings = fs.readFileSync(path.join(root, "AudioEndpointSettings.qml"), "utf8")
const globalSettings = ["PrivacyGeneralSettings.qml", "PrivacyAppearanceSettings.qml", "PrivacyAlertsSettings.qml", "PrivacyMonitoringSettings.qml", "PrivacyMarkerGlyphEditor.qml"]
  .map(file => fs.readFileSync(path.join(root, file), "utf8")).join("\n")
const settingsUi = bar + "\n" + globalSettings
const deviceSettings = bar + deviceEditor + deviceDiagnostics
const defaults = manifest.barWidget.defaults
const modelContext = {}
vm.createContext(modelContext)
vm.runInContext(fs.readFileSync(path.join(root, "Model.js"), "utf8").replace(/^\.pragma library\s*/, ""), modelContext)
const schema = new Map(manifest.barWidget.schema.map(entry => [entry.key, entry]))
const globalKeys = [
  "enabledKinds", "showIdle", "displayMode", "showControls", "idleOpacity", "deduplicateApps",
  "notificationKinds", "notifyOnActivity", "notifyOnStop", "notifyOnControlChanges", "notifyOnObserverHealth",
  "notificationSuppressedApps", "historyEnabled", "blockableKinds", "directDeviceMonitoring",
  "directDevicePollSeconds", "showInferredAttribution", "locationPollSeconds", "recordingPollSeconds", "popupMaxHeight",
  "activeColorRole", "inactiveColorRole", "disabledColorRole", "disabledOpacity",
  "statusMarkerMode", "statePillStyle", "popupDensity", "popupLayout", "popupWidth", "popupItemScale", "popupIdleOpacity", "showStatePills", "showSessionCounts", "animatePending",
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
    assert.ok(settingsUi.includes(`{${key}:`) || settingsUi.includes(`{${key}: `) || settingsUi.includes(`settingKey: "${key}"`), `global editor is not wired to persist ${key}`)
  const entry = schema.get(key)
  assert.deepEqual(entry.defaultValue, defaults[key], `schema/default mismatch: ${key}`)
  if (entry.type === "enum") assert.ok(entry.options.includes(entry.defaultValue), `enum default is unavailable: ${key}`)
  if (entry.type === "integer" || entry.type === "number") {
    assert.ok(entry.defaultValue >= entry.min && entry.defaultValue <= entry.max, `numeric default out of bounds: ${key}`)
  }
}

assert.match(settingsNavigation, /value:"appearance"/, "appearance settings need a dedicated page")
assert.match(settingsNavigation, /objectName: "settingsPageButton-" \+ modelData\.value/, "settings tabs must be addressable by runtime interaction tests")
assert.match(bar, /text: "Reset global settings"[\s\S]*?onClicked: root\.requestGlobalSettingsReset\(\)/,
  "the global reset action must use the guarded request path")
assert.match(bar, /function requestGlobalSettingsReset\(\)[\s\S]*?request\("checkpoint"/,
  "the global reset request must preserve an undo point before reset policy")
for (const selector of ["Monitored activity", "Activity notifications", "Preventative controls"])
  assert.match(globalSettings, new RegExp(`label:\\s*"${selector}"`), `${selector} must remain configurable`)
assert.match(bar, /GridLayout\s*\{\s*id:\s*activityRows[\s\S]*?visible:\s*root\.editingKind === "" && !root\.showingGlobalSettings[\s\S]*?Repeater\s*\{/,
  "activity delegates must be owned by a visual container that hides them on settings pages")
assert.match(bar, /model:\s*root\.editingKind === "" && !root\.showingGlobalSettings && !root\.showingHistory\s*\?[\s\S]*?root\.displayedActivityItems[\s\S]*?:\s*\[\]/,
  "settings and history pages must remove main-widget delegates from the object tree")
assert.match(bar, /delegate:\s*PrivacyActivityCard\s*\{[\s\S]*?entry:\s*modelData[\s\S]*?controller:\s*root/,
  "activity presentation must be isolated in its tested card component")
assert.match(bar, /manageIpc:\s*false/, "per-monitor panels must delegate IPC routing to the singleton service and focused-monitor shell router")
assert.match(bar, /settingsRequestSerial <= handledSettingsRequestSerial[\s\S]*?requestedView === "history"[\s\S]*?showHistory\(\)[\s\S]*?showGlobalSettings\(privacyService\.requestedSettingsPage, privacyService\.requestedSettingsSection\)/,
  "the focused widget must consume singleton history and settings requests")
assert.match(bar, /onSettingsRequestSerialChanged\(\) \{ root\.handleSettingsRequest\(\) \}/,
  "settings IPC page changes must apply while the popup remains open")
assert.match(surface, /default property alias content:/, "settings groups need a reusable visual surface")
assert.match(integer, /IntValidator[\s\S]*?bottom:[\s\S]*?top:/, "integer settings must enforce their declared bounds")
assert.match(bar, /Loader\s*\{\s*id:\s*globalSettingsPageLoader[\s\S]*?sourceComponent:[\s\S]*?globalSettingsPage/, "only the active settings page should be instantiated")
assert.match(bar, /function showGlobalSettings\(page, section\)[\s\S]*?Model\.settingsDeepLink\(page, section\)[\s\S]*?pendingSettingsSection = target\.section[\s\S]*?Qt\.callLater\(root\.scrollToSettingsSection\)/,
  "settings navigation must preserve a validated section deep link until layout completes")
assert.match(bar, /function scrollToSettingsSection\(\)[\s\S]*?globalSettingsPageLoader\.item\.sectionItems[\s\S]*?mapToItem\(contentFlick\.contentItem[\s\S]*?Model\.settingsScrollPosition/,
  "deep links must resolve the live lazy-loaded section and clamp its scroll position")
assert.match(bar, /id:\s*globalSettingsPageLoader[\s\S]*?onLoaded:\s*Qt\.callLater\(root\.scrollToSettingsSection\)/,
  "lazy settings pages must complete pending deep links after loading")
assert.match(bar, /History is off[\s\S]*?Open monitoring settings[\s\S]*?showGlobalSettings\("monitoring", "private-data"\)/,
  "disabled history must link directly to its opt-in control")
assert.match(bar, /Global status-marker rules still apply[\s\S]*?Global marker settings[\s\S]*?showGlobalSettings\("appearance", "status-presentation"\)/,
  "per-device marker guidance must link directly to the governing global rules")
assert.match(activityCard, /required property var controller[\s\S]*?property var entry:/, "activity card must expose one deep controller/entry interface")
assert.match(globalSettings, /PanelSectionHeader \{ Layout\.fillWidth: true; text: "Observer health" \}[\s\S]*?text: page\.controller\.monitoringTelemetryText\(\)/,
  "the Monitoring page must render live observer telemetry in its health section")
assert.match(bar, /function monitoringTelemetryText\(\)[\s\S]*?Model\.monitoringTelemetryText\(data\)/,
  "observer telemetry copy must use the behavior-tested formatter")
assert.match(bar, /function commitSettings\(candidate\)[\s\S]*?settingsMutationPending = true[\s\S]*?onOpenedChanged:[\s\S]*?else if \(settingsMutationPending\) Qt\.callLater\(root\.open\)/,
  "settings writes must preserve the open editor across shell config reloads")
assert.match(bar, /function persistSettings\(values\)[\s\S]*?settingsMutationController\.submit\(effectiveSettings, values\)/,
  "settings edits must enter the coalescing mutation boundary")
assert.match(mutationController, /function submit\(current, patch\)[\s\S]*?pending \|\| current[\s\S]*?commitTimer\.restart\(\)/,
  "rapid mutations must merge onto the newest pending settings")
assert.match(mutationController, /function complete\(success, message\)[\s\S]*?"saved"[\s\S]*?"failed"/,
  "settings commits must publish explicit success and failure feedback")
assert.match(messageSurface, /required property string message[\s\S]*?kind === "error"[\s\S]*?Text\.PlainText/,
  "shared status messages must distinguish failures and render literal text")
assert.match(settingToggle, /required property string settingKey[\s\S]*?patch\[settingKey\] = !checked[\s\S]*?controller\.persistSettings\(patch\)/,
  "boolean settings must share one tested persistence contract")
assert.doesNotMatch(globalSettings, /\bToggle\s*\{/,
  "global pages must not duplicate raw toggle styling and persistence wiring")
assert.match(transferResult, /function apply\(mode, payload\)[\s\S]*?!parsed \|\| typeof parsed !== "object" \|\| Array\.isArray\(parsed\)[\s\S]*?Model\.sanitizeSettings\(parsed\)/,
  "transferred settings must reject non-objects and use the canonical sanitizer")
assert.match(bar, /Model\.sanitizeSettings\(candidate\)/, "settings writes must pass through the versioned sanitizer")
assert.match(bar, /privacy-settings[\s\S]*?PrivacySettingsTransferController/, "settings transfer must use the bounded helper controller")
assert.match(monitoringSettings, /text: "Private data"[\s\S]*?text: "Export settings"[\s\S]*?text: "Import settings"[\s\S]*?text: "Undo last change"/,
  "Monitoring must own the complete private settings-transfer workflow")
assert.equal((globalSettings.match(/label: "Keep recent activity"/g) || []).length, 1, "history controls must not be duplicated across settings pages")
assert.equal((globalSettings.match(/text: "Export settings"/g) || []).length, 1, "settings transfer must have one clear home")
assert.match(activityCard, /HoverHandler[\s\S]*?selectedKind/, "hover should track keyboard selection without polling")
assert.match(activityCard, /addPolicyValue\("hiddenDevices"[\s\S]*?addPolicyValue\("notificationSuppressedDevices"/,
  "active device rows must expose visibility and alert policy actions")
assert.match(bar, /function persistDeviceLabel\(device, value\)[\s\S]*?deviceLabels/,
  "friendly device names must persist through the sanitized settings boundary")
assert.match(bar, /Model\.historySummary\([\s\S]*?historySummaryWindow/,
  "history insights must project existing retained rows without separate storage")
assert.match(bar, /text: "Today"[\s\S]*?text: "7 days"[\s\S]*?historySummaryRows/,
  "history must offer bounded today and seven-day summaries")
assert.match(bar, /iconText: privacyService && privacyService\.privacyPresetUndoAvailable \? "󰌿" : "󰌾"[\s\S]*?tooltipText: privacyService && privacyService\.privacyPresetUndoAvailable[\s\S]*?restorePrivacyLockdown\(\)[\s\S]*?requestPrivacyLockdown\(\)/,
  "one compact lock/unlock action must expose lockdown and observed-state undo")
assert.doesNotMatch(bar, /text: "Undo lockdown"/, "lockdown undo must not consume a second text-button row")
assert.match(activityCard, /text: !entry\.dependenciesReady \? "INSTALL" : \(entry\.kind === "screenshot" \? "CAPTURE" : controller\.itemStateLabel\(entry\)\)/,
  "every popup row must expose an explicit install, capture, or tested semantic state")
assert.match(globalSettings, /Status legend[\s\S]*?Active[\s\S]*?Disabled[\s\S]*?Verifying[\s\S]*?Degraded/, "monitoring settings must explain non-color status markers")
for (const label of ["Icon scale", "Space between bar items", "Bar item padding", "Bar status markers", "Marker position", "Active marker", "Disabled marker", "Verifying marker", "Degraded marker", "Popup state pills", "Popup density", "Popup layout", "Popup width", "Popup item scale", "Popup idle visibility", "State pills", "Popup session counts", "Bar session counts", "Animate verification", "Disabled opacity"])
  assert.match(globalSettings, new RegExp(label), `${label} must be exposed in global visual settings`)
assert.match(bar, /state === "active" \? showBarActiveMarker[\s\S]*?state === "disabled" \? showBarDisabledMarker[\s\S]*?state === "pending" \? showBarPendingMarker[\s\S]*?state === "unavailable" \? showBarDegradedMarker/,
  "bar status classes must have independent marker visibility")
for (const label of ["Active marker icon", "Disabled marker icon", "Verifying marker icon", "Degraded marker icon"])
  assert.match(globalSettings, new RegExp(label), `${label} must be exposed for custom marker mode`)
assert.match(globalSettings, /options: \["symbols", "letters", "custom", "off"\]/, "bar marker mode must expose custom glyphs")
assert.match(fs.readFileSync(path.join(root, "PrivacyAppearanceSettings.qml"), "utf8"), /Theme colors[\s\S]*Status presentation/, "visual sections belong on Appearance")
assert.match(fs.readFileSync(path.join(root, "PrivacyAppearanceSettings.qml"), "utf8"), /GridLayout\s*\{[\s\S]*?columns: width >= Style\.space\(650\) \? 2 : 1[\s\S]*?Layout\.columnSpan: page\.columns/,
  "wide appearance settings must pair lightweight sections while keeping status presentation full-width")
assert.match(monitoringSettings, /GridLayout\s*\{[\s\S]*?columns: width >= Style\.space\(650\) \? 2 : 1[\s\S]*?id: privateDataSettings[\s\S]*?Layout\.columnSpan: page\.columns/,
  "wide monitoring settings must pair related sections while keeping private data full-width")
assert.match(bar, /"1234"[\s\S]*?\["general", "appearance", "alerts", "monitoring"\]/, "settings keyboard shortcuts must cover all pages")
assert.match(bar, /var count = Model\.privacySessionCount\(entry, showBarSessionCounts\)/, "bar counts must not depend on popup-count visibility")
assert.match(bar, /Grid\s*\{\s*id:\s*iconGrid[\s\S]*?columns:\s*root\.verticalBar \? 1/,
  "bar items must stack on vertical Omarchy bars")
assert.match(bar, /role === "foreground"[\s\S]*?bar\.foreground/,
  "theme-role fallback must use the documented Omarchy bar foreground")
assert.match(bar, /label: "Show status markers for this device"[\s\S]*?onChanged: function\(value\) \{ root\.persistItemStatusMarker\(root\.editingKind, value\) \}/,
  "per-item marker settings must persist the selected override")
assert.match(bar, /text: "Move left"[\s\S]*?enabled: root\.canMoveItem\(root\.editingKind, -1\)/,
  "device placement must disable unavailable left movement")
assert.match(bar, /text: "Move right"[\s\S]*?enabled: root\.canMoveItem\(root\.editingKind, 1\)/,
  "device placement must disable unavailable right movement")
assert.match(bar, /visible: root\.editingKind !== "" && !root\.showingGlobalSettings[\s\S]*?SettingsSurface\s*\{[\s\S]*?text: "Appearance"/,
  "device appearance must use the shared settings surface")
for (const section of ["Bar placement", "Backend", "Diagnostics", "Reset device appearance"])
  assert.match(deviceSettings, new RegExp(`SettingsSurface\\s*\\{[\\s\\S]*?text: "${section}"`), `${section} must use the shared device settings structure`)
assert.match(bar, /label: "Show status markers for this device"[\s\S]*?Global status-marker rules still apply/,
  "device marker wording must explain its relationship to global rules")
for (const label of ["Bar preview", "Display label", "Device icon"])
  assert.match(bar, new RegExp(`text: "${label}"`), `${label} must remain visible without relying on input placeholders`)
assert.match(bar, /Shared by microphone and audio output/, "shared audio backend scope must be explicit")
assert.match(audioEndpointSettings, /surface\.kind === "microphone" \? "Microphone devices" : "Audio output devices"[\s\S]*?audioEndpoints\(surface\.kind\)/,
  "audio settings pages must enumerate their exact hardware endpoints")
assert.match(audioEndpointSettings, /text: modelData\.muted \? "Allow" : "Block"[\s\S]*?setAudioEndpointMuted\(surface\.kind, modelData\.id, !modelData\.muted\)/,
  "each audio endpoint must expose its own observed block control")
assert.match(bar, /root\.editingKind !== "" && dx !== 0[\s\S]*?root\.moveDeviceEditor\(dx\)/,
  "left and right keys must navigate device editors")
assert.match(bar, /function moveDeviceEditor\(delta\)[\s\S]*?Model\.nextNavigationKind\(order, editingKind, delta\)/,
  "device editor navigation must use behavior-tested boundary handling")
assert.match(deviceEditor, /tooltipText: "Previous device"[\s\S]*?tooltipText: "Next device"/, "device pages must expose accessible adjacent navigation")
assert.match(bar, /text: confirmationState\.pending === "all" \? "Confirm reset all" : "Reset all device settings"[\s\S]*?root\.resetAllDeviceSettings\(root\.editingKind\)/,
  "the complete device reset must invoke its scoped reset policy after confirmation")
assert.match(bar, /confirmationState\.pending === "backend"[\s\S]*?Confirm shared backend reset[\s\S]*?confirmationState\.pending === "all"[\s\S]*?Confirm reset all/,
  "shared audio resets must require an explicit second action")
assert.match(bar, /function syncDeviceEditors\(\)[\s\S]*?labelEditor\.text = root\.labelFor\(editingKind\)[\s\S]*?customRecorderStopEditor\.text/,
  "changing devices must replace every editable field instead of retaining stale input")
assert.match(bar, /onEditingKindChanged:\s*\{[\s\S]*?Qt\.callLater\(syncDeviceEditors\)/,
  "device-editor synchronization must run after every device transition")
assert.match(confirmationController, /guardMilliseconds:\s*5000[\s\S]*?onTriggered: controller\.pending = ""/,
  "shared reset confirmations must expire")

const resetGlobalBody = bar.slice(bar.indexOf("function resetGlobalSettings()"), bar.indexOf("function persistIcon("))
for (const key of [
  "barIconScale", "barItemSpacing", "barItemPadding", "barMarkerPosition", "showBarSessionCounts", "popupLayout", "popupWidth", "popupItemScale", "popupIdleOpacity",
  "showBarActiveMarker", "showBarDisabledMarker", "showBarPendingMarker", "showBarDegradedMarker",
  "barActiveMarkerIcon", "barDisabledMarkerIcon", "barPendingMarkerIcon", "barDegradedMarkerIcon"
]) assert.match(resetGlobalBody, new RegExp(`${key}:`), `global reset must restore ${key}`)
assert.match(bar, /deviceColorRoleOptions:[\s\S]*?value: "inherit", label: "Use global default"/,
  "device color inheritance must use a human-readable option")
assert.match(bar, /deviceVisibilityOptions:[\s\S]*?value: "show", label: "Show"[\s\S]*?value: "hide", label: "Hide"/,
  "device visibility modes must use human-readable options")
assert.match(bar, /function resetDeviceBackend\(kind\)[\s\S]*?Qt\.callLater\(syncDeviceEditors\)/,
  "backend resets must refresh fields whose edit bindings were replaced")
assert.match(bar, /property bool dirty:[\s\S]*?Unsaved changes[\s\S]*?enabled: parent\.dirty/,
  "device text editors must expose dirty state and disable redundant saves")
assert.match(bar, /Model\.deviceBackendValidation\("screenshot"[\s\S]*?enabled: parent\.dirty && parent\.validation\.valid/,
  "custom screenshot settings must validate before saving")
assert.match(bar, /Model\.deviceBackendValidation\("screen-recording"[\s\S]*?enabled: parent\.dirty && parent\.validation\.valid/,
  "custom recording settings must validate before saving")
assert.match(bar, /maximumLength: 4096/, "custom command editors must expose sanitizer-aligned bounds")
assert.match(bar, /id: labelEditor[\s\S]*?maximumLength: 128/, "device label editor must match its persisted bound")
assert.match(bar, /id: iconEditor[\s\S]*?maximumLength: 8/, "device icon editor must match its persisted bound")
assert.match(bar, /function persistIcon\(kind, value\)[\s\S]*?Qt\.callLater[\s\S]*?iconEditor\.text = root\.iconFor\(kind\)/,
  "sanitized icon saves must reconcile the visible field")
assert.match(bar, /function persistLabel\(kind, value\)[\s\S]*?Qt\.callLater[\s\S]*?labelEditor\.text = root\.labelFor\(kind\)/,
  "sanitized label saves must reconcile the visible field")
assert.match(bar, /root\.deviceAppearanceCustomized\(root\.editingKind\) \? "Customized" : "Using global defaults"/,
  "device appearance must identify inherited versus customized state")
assert.match(bar, /DeviceSettingsEditor\s*\{[\s\S]*?controller: root/, "device editor navigation must use a narrow controller interface")
assert.match(deviceDiagnostics, /required property var controller[\s\S]*?required property string kind/, "device diagnostics must expose a narrow controller and device interface")
assert.match(bar, /function deviceDiagnostic\(kind\)[\s\S]*?Model\.deviceDiagnosticPresentation\(privacyService\.diagnostic\(kind\)\)/,
  "diagnostic content must use the behavior-tested presentation policy")
assert.match(deviceDiagnostics, /model: diagnostics\.data\.rows[\s\S]*?text: modelData\.label[\s\S]*?text: modelData\.value/,
  "the diagnostics component must render every tested label/value row")
assert.match(bar, /text: "Reset device appearance"[\s\S]*?default label, icon, colors, idle visibility, idle opacity, and status-marker visibility/,
  "device reset copy must match every reset field")
assert.match(activityCard, /controller\.statePillStyle === "filled"[\s\S]*?controller\.statePillStyle === "minimal"/, "state-pill styles must alter fill and border presentation")
assert.match(activityCard, /controller\.popupDensity === "compact"[\s\S]*?verticalPadding/, "popup density must alter row spacing")
assert.match(activityCard, /id: policyMenu[\s\S]*?Hide application[\s\S]*?Hide device[\s\S]*?Mute device alerts/,
  "row policy actions must live in one compact overflow menu")
assert.match(activityCard, /tooltipText: "More privacy actions"[\s\S]*?policyMenu\.open\(\)/,
  "active rows must expose one discoverable policy affordance")
assert.doesNotMatch(activityCard, /Button \{ visible: entry\.active[\s\S]{0,160}?text: "Hide"/,
  "full policy buttons must not crowd the primary toggle row")
assert.match(activityCard, /visible: card\.visualState !== "idle" \|\| !controller\.showStatePills/,
  "idle cards must not repeat state text already carried by the visible pill")
assert.match(activityCard, /function sessionSummary\(session\)[\s\S]*?session\.device[\s\S]*?formatDuration[\s\S]*?Inferred/,
  "activity summaries must prioritize device, duration, and attribution quality over backend jargon")
assert.match(bar, /Layout\.columnSpan: root\.popupGridColumns === 2[\s\S]*?root\.displayedActivityItems\.length % 2 === 1 \? 2 : 1/,
  "an odd final grid card must consume the otherwise empty column")
assert.match(bar, /running:\s*modelData\.pending && root\.animatePending/, "pending animation must honor its visual setting")
assert.match(bar, /Timer \{[\s\S]*?running: root\.opened[\s\S]*?onTriggered: if \(!contentFlick\.moving\) root\.durationNow = Date\.now\(\)/,
  "the duration timer must pause rendered time updates while the user scrolls")
assert.match(monitoringSettings, /columns: observerHealthSettings\.width >= Style\.space\(360\) \? 2 : 1/,
  "self-test actions must reflow instead of crowding narrow popups")
assert.match(monitoringSettings, /PrivacyMessageSurface[\s\S]*?selfTestResult\.text/,
  "self-test results must use the shared status surface")

console.log("global settings contract tests passed")
