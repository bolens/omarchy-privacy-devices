import Quickshell
import QtQuick

ShellRoot {
  id: root
  property var patches: []
  QtObject {
    id: mockController
    property var values: ({showIdle:false})
    property color activeThemeColor: "#88aaff"
    function setting(key, fallback) { return values[key] === undefined ? fallback : values[key] }
    function persistSettings(patch) {
      root.patches = root.patches.concat([patch])
      values = Object.assign({}, values, patch)
    }
  }
  PrivacySettingToggle { id: toggle; controller: mockController; settingKey: "showIdle"; fallback: true; label: "Show idle" }
  Component.onCompleted: Qt.callLater(function() {
    if (toggle.checked) throw new Error("toggle did not reflect stored false")
    toggle.clicked()
    if (root.patches.length !== 1 || root.patches[0].showIdle !== true || !toggle.checked) throw new Error("toggle did not persist inverse state")
    mockController.values = ({showIdle:false})
    Qt.callLater(function() {
      if (toggle.checked) throw new Error("toggle did not react to an external settings replacement")
      mockController.values = ({})
      Qt.callLater(function() {
        if (!toggle.checked) throw new Error("toggle did not restore its fallback after setting removal")
        console.log("PRIVACY_QML_SETTING_TOGGLE_OK")
        Qt.quit()
      })
    })
  })
}
