import Quickshell
import QtQuick
import "Model.js" as Model

ShellRoot {
  Component.onCompleted: {
    var raw = {showIdle:"yes", popupMaxHeight:9999, enabledKinds:["camera", "camera", "bogus"], unknown:"discard"}
    var clean = Model.sanitizeSettings(raw)
    if (clean.showIdle !== true || clean.popupMaxHeight !== 900) throw new Error("settings normalization failed")
    if (JSON.stringify(clean.enabledKinds) !== JSON.stringify(["camera"])) throw new Error("kind normalization failed")
    if (clean.unknown !== undefined || clean._privacySettingsVersion !== 1) throw new Error("settings version boundary failed")
    var grouped = Model.coalesceNotificationEvents([{phase:"started",kind:"camera",application:"Browser"},{phase:"started",kind:"camera",application:"Browser"}])
    if (grouped.count !== 1 || grouped.body !== "Browser: Camera") throw new Error("notification coalescing failed")
    var filtered = Model.filterAttribution([{confidence:"confirmed"},{confidence:"inferred"}], false)
    if (filtered.length !== 1 || filtered[0].confidence !== "confirmed") throw new Error("attribution filtering failed")
    console.log("PRIVACY_QML_RUNTIME_OK")
    Qt.quit()
  }
}
