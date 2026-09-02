pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  property var patches: []

  QtObject {
    id: mockController
    property color activeThemeColor: "#55aaff"
    property real barIconScale: 1
    property real disabledOpacity: 0.7
    property string statusMarkerMode: "off"
    property string barMarkerPosition: "after"
    property string statePillStyle: "filled"
    property string popupDensity: "comfortable"
    property string popupLayout: "adaptive"
    property string popupWidth: "standard"
    property real popupItemScale: 1
    property real popupIdleOpacity: 0.72
    property var values: ({activeColorRole:"accent",activeOpacity:0.9,inactiveColorRole:"foreground",idleOpacity:0.45,disabledColorRole:"muted",blockedActiveColorRole:"urgent",blockedActiveOpacity:0.8})
    function setting(key, fallback) { return values[key] === undefined ? fallback : values[key] }
    function persistSettings(patch) { root.patches = root.patches.concat([patch]) }
  }

  PrivacyAppearanceSettings { id: page; width: 500; controller: mockController }

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
    var activeRole = descendant(page, "activeColorRoleSetting")
    var activeOpacity = descendant(page, "activeOpacitySetting")
    var idleRole = descendant(page, "inactiveColorRoleSetting")
    var idleOpacity = descendant(page, "idleOpacitySetting")
    var disabledRole = descendant(page, "disabledColorRoleSetting")
    var disabledOpacity = descendant(page, "disabledOpacitySetting")
    var blockedRole = descendant(page, "blockedActiveColorRoleSetting")
    var blockedOpacity = descendant(page, "blockedActiveOpacitySetting")
    if (!activeRole || !activeOpacity || !idleRole || !idleOpacity || !disabledRole || !disabledOpacity || !blockedRole || !blockedOpacity)
      throw new Error("semantic appearance controls are not addressable")
    if (activeRole.value !== "accent" || activeOpacity.value !== 90 || idleRole.value !== "foreground" || idleOpacity.value !== 45
        || disabledRole.value !== "muted" || disabledOpacity.value !== 70 || blockedRole.value !== "urgent" || blockedOpacity.value !== 80)
      throw new Error("semantic appearance controls did not reflect global settings")
    activeRole.changed("bar-active")
    blockedOpacity.modified(65)
    if (root.patches.length !== 2 || root.patches[0].activeColorRole !== "bar-active" || root.patches[1].blockedActiveOpacity !== 0.65)
      throw new Error("semantic appearance controls persisted the wrong settings")
    console.log("PRIVACY_QML_APPEARANCE_SETTINGS_OK")
    Qt.quit()
  })
}
