import Quickshell
import QtQuick

ShellRoot {
  QtObject {
    id: mockController
    property string globalSettingsPage: "general"
    property string popupWidth: "narrow"
    property bool returned: false
    property var selections: []
    function showActivity() { returned = true }
    function showGlobalSettings(page, section) {
      selections = selections.concat([{page:page,section:section}])
      globalSettingsPage = page
    }
  }

  PrivacySettingsNavigation { id: navigation; controller: mockController }

  function descendant(item, name) {
    if (!item) return null
    if (item.objectName === name) return item
    var children = item.children || []
    for (var index = 0; index < children.length; index++) {
      var match = descendant(children[index], name)
      if (match) return match
    }
    return null
  }

  Component.onCompleted: Qt.callLater(function() {
    var monitoring = descendant(navigation, "settingsPageButton-monitoring")
    var pages = descendant(navigation, "settingsPageGrid")
    var back = descendant(navigation, "settingsBackButton")
    if (!monitoring || !back || !pages) throw new Error("settings navigation controls are not addressable")
    if (pages.columns !== 2) throw new Error("narrow settings navigation did not use two columns")
    monitoring.clicked()
    if (mockController.selections.length !== 1 || mockController.selections[0].page !== "monitoring" || mockController.selections[0].section !== "")
      throw new Error("settings page selection failed")
    if (!monitoring.active || !monitoring.selected) throw new Error("selected settings page was not reflected")
    mockController.popupWidth = "wide"
    if (pages.columns !== 4) throw new Error("wide settings navigation did not react to width mode")
    back.clicked()
    if (!mockController.returned) throw new Error("settings back action failed")
    console.log("PRIVACY_QML_SETTINGS_NAVIGATION_OK")
    Qt.quit()
  })
}
