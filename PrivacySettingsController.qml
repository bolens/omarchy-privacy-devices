import QtQuick
import "Model.js" as Model

Item {
  id: controller

  required property var host
  property bool mutationPending: false
  readonly property alias mutationControl: mutation
  readonly property alias transferControl: transfer
  readonly property alias transferResult: result
  readonly property string mutationMessage: mutation.status === "saving" ? "Saving changes…"
    : (mutation.status === "saved" ? "Changes applied"
    : (mutation.status === "failed" ? "Settings update failed" + (mutation.detail ? ": " + mutation.detail : "") : ""))

  function persist(values) {
    mutation.submit(host.effectiveSettings, values)
  }

  function commit(candidate) {
    var previous = host.settings
    var clean = Model.sanitizeSettings(candidate)
    var entry = {id: host.moduleName}
    for (var sanitizedKey in clean) entry[sanitizedKey] = clean[sanitizedKey]
    host.settings = entry
    host.syncService()
    mutationPending = true
    mutationGuard.restart()
    try {
      if (!host.bar || !host.bar.shell || typeof host.bar.shell.updateEntryInline !== "function") throw new Error("shell settings API unavailable")
      host.bar.shell.updateEntryInline(host.moduleName, entry)
      mutation.complete(true)
      Qt.callLater(function() { if (!host.opened) host.open() })
    } catch (error) {
      host.settings = previous
      host.syncService()
      mutation.complete(false, String(error && error.message ? error.message : error))
    }
  }

  function requestTransfer(mode, message, payload) {
    result.begin(message)
    if (!transfer.request(mode, payload)) result.begin("Transfer busy")
  }

  function exportSettings() { requestTransfer("export", "Exporting…", Model.sanitizeSettings(host.effectiveSettings)) }
  function importSettings() { requestTransfer("import", "Importing…", Model.sanitizeSettings(host.effectiveSettings)) }
  function undoSettingsChange() { requestTransfer("undo", "Restoring…", {}) }
  function requestGlobalSettingsReset() { requestTransfer("checkpoint", "Saving undo point…", Model.sanitizeSettings(host.effectiveSettings)) }
  function handleTransfer(mode, payload) { result.apply(mode, payload) }

  Timer {
    id: mutationGuard
    interval: 2000
    onTriggered: controller.mutationPending = false
  }

  PrivacySettingsMutationController {
    id: mutation
    onCommitRequested: function(settings) { controller.commit(settings) }
  }

  PrivacySettingsTransferController {
    id: transfer
    helper: String(Qt.resolvedUrl("privacy-settings")).replace(/^file:\/\//, "")
    onSucceeded: function(mode, payload) { controller.handleTransfer(mode, payload) }
    onFailed: function(_mode, detail) { result.fail(detail) }
  }

  PrivacySettingsTransferResult { id: result; controller: controller.host }
}
