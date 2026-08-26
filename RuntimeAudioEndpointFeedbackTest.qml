import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root

  QtObject {
    id: serviceMock
    property string audioEndpointMessage: "Audio endpoint state was not changed."
    function audioEndpoints(_kind) { return [] }
    function refreshAudioEndpoints(_kind) {}
  }
  QtObject {
    id: controllerMock
    property var privacyService: serviceMock
    property string editingKind: "audio-output"
    property color activeThemeColor: Color.accent
  }

  AudioEndpointSettings { id: settings; width: 500; controller: controllerMock }

  function descendant(item, name) {
    if (!item) return null
    if (item.objectName === name) return item
    var children = item.children || []
    for (var index = 0; index < children.length; index++) {
      var found = descendant(children[index], name)
      if (found) return found
    }
    return null
  }

  Component.onCompleted: Qt.callLater(function() {
    var feedback = descendant(settings, "audioEndpointFeedback")
    var icon = descendant(settings, "messageSurfaceIcon")
    if (!feedback || !icon) throw new Error("audio endpoint feedback is not addressable")
    if (!feedback.visible || feedback.kind !== "error" || feedback.message !== "Audio endpoint state was not changed." || icon.text !== "!")
      throw new Error("audio endpoint failure feedback rendered incorrectly")
    serviceMock.audioEndpointMessage = "Audio endpoints refreshed"
    Qt.callLater(function() {
      if (feedback.kind !== "info" || icon.text !== "󰋼" || feedback.message !== "Audio endpoints refreshed")
        throw new Error("audio endpoint success feedback did not replace failure state")
      serviceMock.audioEndpointMessage = ""
      Qt.callLater(function() {
        if (feedback.visible) throw new Error("cleared audio endpoint feedback remained visible")
        console.log("PRIVACY_QML_AUDIO_ENDPOINT_FEEDBACK_OK")
        Qt.quit()
      })
    })
  })
}
