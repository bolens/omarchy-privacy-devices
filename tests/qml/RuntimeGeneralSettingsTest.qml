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
    property var values: ({enabledKinds:["microphone"],showIdle:false,showControls:true,deduplicateApps:false,privacyModes:[{name:"Meeting",controls:{microphone:false}}]})
    property var privacyService: QtObject { property string privacyPresetState: "idle"; function requestPrivacyMode(mode) { root.patches = root.patches.concat([{appliedMode:mode.name}]); return true } }
    function setting(key, fallback) { return values[key] === undefined ? fallback : values[key] }
    function persistSettings(patch) { root.patches = root.patches.concat([patch]) }
    function savePrivacyMode(name) { root.patches = root.patches.concat([{savedMode:name}]) }
    function removePrivacyMode(index) { root.patches = root.patches.concat([{removedMode:index}]) }
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
    var modeName = descendant(page, "privacyModeNameField")
    var modeSave = descendant(page, "privacyModeSaveButton")
    var modeApply = descendant(page, "privacyModeApply-0")
    var modeDelete = descendant(page, "privacyModeDelete-0")
    if (!kinds || !idle || !controls || !deduplicate || !modeName || !modeSave || !modeApply || !modeDelete) throw new Error("general settings controls are not addressable")
    if (kinds.values.length !== 1 || kinds.values[0] !== "microphone" || idle.checked || !controls.checked || deduplicate.checked)
      throw new Error("general settings controls did not reflect configured values")
    kinds.changed(["camera"])
    idle.clicked()
    controls.clicked()
    deduplicate.clicked()
    modeName.text = "Travel"
    modeSave.clicked()
    modeApply.clicked()
    modeDelete.clicked()
    if (root.patches.length !== 7 || root.patches[0].enabledKinds[0] !== "camera"
        || root.patches[1].showIdle !== true || root.patches[2].showControls !== false
        || root.patches[3].deduplicateApps !== true || root.patches[4].savedMode !== "Travel"
        || root.patches[5].appliedMode !== "Meeting" || root.patches[6].removedMode !== 0)
      throw new Error("general settings controls persisted incorrect patches")
    console.log("PRIVACY_QML_GENERAL_SETTINGS_OK")
    Qt.quit()
  })
}
