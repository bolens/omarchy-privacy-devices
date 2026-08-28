import Quickshell
import QtQuick

ShellRoot {
  QtObject {
    id: viewport
    property real contentY: 0
    property real contentHeight: 900
    property real height: 300
    property var contentItem: null
  }

  QtObject {
    id: confirmation
    property int clears: 0
    function clear() { clears++ }
  }

  QtObject {
    id: host
    property var confirmationController: confirmation
    property var contentViewport: viewport
    property var settingsPageItem: null
    property var privacyService: null
    property int presentations: 0
    function publishCaptureBarPresentation() { presentations++ }
  }

  PrivacyPopupNavigationController { id: navigation; host: host }

  Component.onCompleted: Qt.callLater(function() {
    navigation.showSettings("monitoring", "observer-health")
    if (!navigation.showingGlobalSettings || navigation.globalSettingsPage !== "monitoring"
        || navigation.globalSettingsSection !== "observer-health")
      throw new Error("navigation did not retain the displayed settings target")
    if (navigation.applySettingsScroll("middle") !== "invalid position")
      throw new Error("navigation accepted an invalid capture scroll target")
    if (navigation.applySettingsScroll("bottom") !== "ok" || viewport.contentY !== 600
        || navigation.settingsScrollPosition !== "bottom")
      throw new Error("navigation did not apply the deterministic bottom position")
    navigation.showActivity()
    if (navigation.applySettingsScroll("top") !== "settings closed")
      throw new Error("navigation scrolled outside the settings surface")
    console.log("PRIVACY_QML_POPUP_NAVIGATION_CONTROLLER_OK")
    Qt.quit()
  })
}
