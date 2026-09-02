pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  property int activations: 0

  Button {
    id: target
    text: "Accessible action"
    enabled: false
    onClicked: root.activations += 1
  }

  Component.onCompleted: Qt.callLater(function() {
    if (target.triggerAccessiblePress() || root.activations !== 0)
      throw new Error("disabled accessible action was invoked")
    target.enabled = true
    if (!target.triggerAccessiblePress() || root.activations !== 1)
      throw new Error("enabled accessible action was not invoked exactly once")
    console.log("PRIVACY_QML_ACCESSIBILITY_OK")
    Qt.quit()
  })
}
