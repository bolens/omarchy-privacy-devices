pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  Service { id: service }
  property bool completed: false

  function verifyExpiry() {
    if (completed || service.capturePreviewActive) return
    completed = true
    if (service.capturePreviewHistory.length || service.capturePreviewSessions.length
        || service.capturePreviewBarSessions.length || Object.keys(service.capturePreviewSettings).length
        || !service.captureHistoryPresentationEnabled || service.capturePreviewOwner !== ""
        || service.capturePreviewExpiresAt !== 0)
      throw new Error("expired capture preview was not fully cleared")
    console.log("PRIVACY_QML_CAPTURE_PREVIEW_EXPIRY_OK")
    Qt.quit()
  }

  Component.onCompleted: {
    service.capturePreviewHistory = [{kind:"camera", application:"Preview"}]
    service.capturePreviewSessions = [{kind:"camera", application:"Preview"}]
    service.capturePreviewBarSessions = [{kind:"microphone", application:"Preview"}]
    service.capturePreviewSettings = {showIdle:false}
    service.captureHistoryPresentationEnabled = false
    service.capturePreviewOwner = "expired_fixture_owner_123456"
    service.capturePreviewExpiresAt = Date.now() - 1
    service.capturePreviewActive = true
  }

  Connections { target: service; function onCapturePreviewActiveChanged() { root.verifyExpiry() } }
  Timer { interval: 2500; running: true; onTriggered: { throw new Error("capture preview expiry did not complete") } }
}
