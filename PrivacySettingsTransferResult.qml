import QtQuick
import "Model.js" as Model

QtObject {
  required property var controller
  property string status: ""

  function begin(message) { status = String(message || "") }
  function fail(detail) { status = "Transfer failed" + (detail ? ": " + String(detail) : "") }

  function apply(mode, payload) {
    if (mode === "export") { status = "Settings exported privately"; return true }
    if (mode === "checkpoint") {
      controller.resetGlobalSettings()
      status = "Global settings reset · undo available"
      return true
    }
    if (mode !== "import" && mode !== "undo") return false
    try {
      var parsed = JSON.parse(String(payload || ""))
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("invalid settings")
      controller.persistSettings(Model.sanitizeSettings(parsed))
      status = mode === "undo" ? "Previous settings restored" : "Settings imported"
      return true
    } catch (error) {
      status = mode === "undo" ? "Undo returned invalid settings" : "Import returned invalid settings"
      return false
    }
  }
}
