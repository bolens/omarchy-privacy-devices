import Quickshell
import QtQuick
import qs.Commons

ShellRoot {
  id: root
  property var patches: []

  QtObject {
    id: controllerMock
    property color activeThemeColor: Color.accent
    property real barIconScale: 1.1
    property real disabledOpacity: 0.7
    property string statusMarkerMode: "custom"
    property string barMarkerPosition: "before"
    property string statePillStyle: "outline"
    property string popupDensity: "compact"
    property string popupLayout: "grid"
    property string popupWidth: "wide"
    property real popupItemScale: 1.2
    property real popupIdleOpacity: 0.65
    property var values: ({displayMode:"active-count",barItemSpacing:3,barItemPadding:6,popupMaxHeight:700})
    function setting(key, fallback) { return values[key] === undefined ? fallback : values[key] }
    function persistSettings(patch) { root.patches = root.patches.concat([patch]) }
  }

  PrivacyAppearanceSettings { id: page; width: 700; controller: controllerMock }

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
    var display = descendant(page, "appearanceDisplayModeSetting")
    var scale = descendant(page, "appearanceBarIconScaleSetting")
    var markerMode = descendant(page, "appearanceStatusMarkerModeSetting")
    var markerPosition = descendant(page, "appearanceMarkerPositionSetting")
    var customMarkers = descendant(page, "appearanceCustomMarkers")
    var layout = descendant(page, "appearancePopupLayoutSetting")
    var widthSetting = descendant(page, "appearancePopupWidthSetting")
    var itemScale = descendant(page, "appearancePopupItemScaleSetting")
    var maxHeight = descendant(page, "appearancePopupMaxHeightSetting")
    if (!display || !scale || !markerMode || !markerPosition || !customMarkers
        || !layout || !widthSetting || !itemScale || !maxHeight)
      throw new Error("appearance presentation controls are not addressable")
    if (display.value !== "active-count" || scale.value !== 110 || markerMode.value !== "custom"
        || markerPosition.value !== "before" || !customMarkers.visible || layout.value !== "grid"
        || widthSetting.value !== "wide" || itemScale.value !== 120 || maxHeight.value !== 700)
      throw new Error("appearance presentation did not reflect settings")
    display.changed("active-only")
    scale.modified(95)
    markerMode.changed("off")
    layout.changed("list")
    widthSetting.changed("narrow")
    itemScale.modified(105)
    maxHeight.modified(760)
    if (root.patches.length !== 7 || root.patches[0].displayMode !== "active-only"
        || root.patches[1].barIconScale !== 0.95 || root.patches[2].statusMarkerMode !== "off"
        || root.patches[3].popupLayout !== "list" || root.patches[4].popupWidth !== "narrow"
        || root.patches[5].popupItemScale !== 1.05 || root.patches[6].popupMaxHeight !== 760)
      throw new Error("appearance presentation persisted incorrect values")
    controllerMock.statusMarkerMode = "off"
    Qt.callLater(function() {
      if (customMarkers.visible) throw new Error("custom marker editors remained visible when disabled")
      console.log("PRIVACY_QML_APPEARANCE_PRESENTATION_OK")
      Qt.quit()
    })
  })
}
