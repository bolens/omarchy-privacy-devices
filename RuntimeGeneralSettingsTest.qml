import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root
  property var patches: []

  QtObject {
    id: controllerMock
    property color activeThemeColor: Color.accent
    property string popupWidth: "standard"
    property var kindOptions: [{label:"Microphone",value:"microphone"},{label:"Camera",value:"camera"}]
    property var values: ({enabledKinds:["microphone"],showIdle:false,showControls:true,deduplicateApps:false})
    function setting(key, fallback) { return values[key] === undefined ? fallback : values[key] }
    function persistSettings(patch) { root.patches = root.patches.concat([patch]) }
  }

  PrivacyGeneralSettings { id: page; width: 500; controller: controllerMock }

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
    var kinds = descendant(page, "generalEnabledKindsSetting")
    var idle = descendant(page, "generalShowIdleToggle")
    var controls = descendant(page, "generalShowControlsToggle")
    var deduplicate = descendant(page, "generalDeduplicateAppsToggle")
    if (!kinds || !idle || !controls || !deduplicate) throw new Error("general settings controls are not addressable")
    if (kinds.values.length !== 1 || kinds.values[0] !== "microphone" || idle.checked || !controls.checked || deduplicate.checked)
      throw new Error("general settings controls did not reflect configured values")
    kinds.changed(["camera"])
    idle.clicked()
    controls.clicked()
    deduplicate.clicked()
    if (root.patches.length !== 4 || root.patches[0].enabledKinds[0] !== "camera"
        || root.patches[1].showIdle !== true || root.patches[2].showControls !== false
        || root.patches[3].deduplicateApps !== true)
      throw new Error("general settings controls persisted incorrect patches")
    console.log("PRIVACY_QML_GENERAL_SETTINGS_OK")
    Qt.quit()
  })
}
