import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {enabledKinds:[], notifyOnControlChanges:false}

    if (!service.startPrivacyPreset({actions:[], skipped:[{kind:"camera", reason:"unavailable"}]}, false)
        || service.privacyPresetState !== "partial" || service.privacyPresetUndoAvailable
        || service.privacyPresetMessage() !== "Privacy preset finished with unavailable or failed controls.")
      throw new Error("unavailable preset did not complete as partial")

    service.privacyPresetState = "applying"
    if (service.startPrivacyPreset({actions:[], skipped:[]}, false))
      throw new Error("concurrent preset start was accepted")
    service.privacyPresetState = "idle"

    if (!service.requestPrivacyLockdown() || service.privacyPresetState !== "succeeded"
        || service.privacyPresetUndoAvailable || service.privacyPresetResults.length !== 5
        || service.privacyPresetPrevious.microphone !== true || service.privacyPresetPrevious.camera !== true
        || service.privacyPresetMessage() !== "Privacy preset verified.")
      throw new Error("unsupported-only lockdown did not complete deterministically")
    for (var index = 0; index < service.privacyPresetResults.length; index++) {
      if (service.privacyPresetResults[index].reason !== "unsupported")
        throw new Error("disabled controls were not recorded as unsupported")
    }
    if (service.restorePrivacyLockdown())
      throw new Error("undo was offered when lockdown changed no controls")

    console.log("PRIVACY_QML_PRIVACY_PRESET_ORCHESTRATION_OK")
    Qt.quit()
  }
}
