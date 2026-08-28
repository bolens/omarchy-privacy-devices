import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root
  property var patches: []

  QtObject {
    id: controllerMock
    property color activeThemeColor: Color.accent
    function setting(key, fallback) { return key === "marker" ? "●" : fallback }
    function persistSettings(patch) { root.patches = root.patches.concat([patch]) }
  }

  PrivacyMarkerGlyphEditor {
    id: editor
    width: 400
    controller: controllerMock
    settingKey: "marker"
    label: "Active marker"
    fallback: "!"
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
    var field = descendant(editor, "markerGlyphField")
    var save = descendant(editor, "markerGlyphSaveButton")
    if (!field || !save) throw new Error("marker editor controls are not addressable")
    if (save.text !== "" || save.iconText !== "󰆓" || save.tooltipText !== "Save active marker")
      throw new Error("marker save action is not a descriptive icon control")
    if (field.text !== "●" || field.maximumLength !== 8) throw new Error("marker editor did not reflect its setting")
    field.text = "MIC"
    field.accepted()
    field.text = "⊘"
    save.clicked()
    if (root.patches.length !== 2 || root.patches[0].marker !== "MIC" || root.patches[1].marker !== "⊘")
      throw new Error("marker editor did not persist accepted and clicked values")
    console.log("PRIVACY_QML_MARKER_GLYPH_EDITOR_OK")
    Qt.quit()
  })
}
