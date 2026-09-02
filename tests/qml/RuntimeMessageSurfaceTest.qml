pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root
  property string currentMessage: "Checking observers"
  property string currentKind: "info"

  PrivacyMessageSurface {
    id: surface
    width: 400
    message: root.currentMessage
    kind: root.currentKind
  }

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
    var icon = descendant(surface, "messageSurfaceIcon")
    var text = descendant(surface, "messageSurfaceText")
    if (!icon || !text) throw new Error("message surface content is not addressable")
    if (icon.text !== "󰋼" || text.text !== "Checking observers") throw new Error("info feedback rendered incorrectly")
    root.currentKind = "error"
    root.currentMessage = "Observer failed"
    Qt.callLater(function() {
      if (icon.text !== "!" || text.text !== "Observer failed" || surface.tone !== Color.urgent)
        throw new Error("error feedback did not react to state changes")
      root.currentKind = "success"
      Qt.callLater(function() {
        if (icon.text !== "✓" || surface.tone !== Color.accent) throw new Error("success feedback rendered incorrectly")
        console.log("PRIVACY_QML_MESSAGE_SURFACE_OK")
        Qt.quit()
      })
    })
  })
}
