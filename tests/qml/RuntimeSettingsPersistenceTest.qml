pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import "Model.js" as Model

// Imported JavaScript namespaces are valid here but Qt treats nested test objects as unqualified.
// qmllint disable unqualified
ShellRoot {
  id: root
  property list<string> loadedKinds: ["microphone", "camera"]
  property var loadedModes: ({0:{name:"Meeting",controls:{microphone:false}},length:1})
  property var persistedEntry: null

  QtObject {
    id: shellMock
    function updateEntryInline(moduleName, entry) {
      if (moduleName !== "io.github.bolens.privacy-devices") throw new Error("wrong settings target")
      root.persistedEntry = JSON.parse(JSON.stringify(entry))
      return true
    }
  }

  QtObject { id: barMock; property var shell: shellMock }

  QtObject {
    id: hostMock
    property string moduleName: "io.github.bolens.privacy-devices"
    property var settings: ({enabledKinds: root.loadedKinds, privacyModes:root.loadedModes, showIdle: false})
    readonly property var effectiveSettings: settings
    property var bar: barMock
    property bool opened: true
    function syncService() {}
    function open() { opened = true }
  }

  PrivacySettingsController { id: controller; host: hostMock }

  Component.onCompleted: {
    if (Model.arraySetting(hostMock.settings.enabledKinds, Model.KINDS).join("|") !== "microphone|camera")
      throw new Error("loaded monitored services reset before editing")
    controller.persist({enabledKinds: ["camera"]})
  }

  Connections {
    target: controller.mutationControl
    function onStatusChanged() {
      if (controller.mutationControl.status !== "saved") return
      if (!root.persistedEntry || root.persistedEntry.enabledKinds.join("|") !== "camera")
        throw new Error("monitored service subset was not serialized")
      if (root.persistedEntry.privacyModes.length !== 1 || root.persistedEntry.privacyModes[0].name !== "Meeting")
        throw new Error("privacy modes were not serialized")
      hostMock.settings = JSON.parse(JSON.stringify(root.persistedEntry))
      if (Model.arraySetting(hostMock.settings.enabledKinds, Model.KINDS).join("|") !== "camera")
        throw new Error("monitored service subset reset after reload")
      if (Model.sanitizePrivacyModes(hostMock.settings.privacyModes).length !== 1)
        throw new Error("privacy modes reset after reload")
      console.log("PRIVACY_QML_SETTINGS_PERSISTENCE_OK")
      Qt.quit()
    }
  }
}
