import Quickshell
import QtQuick

ShellRoot {
  QtObject {
    id: mockController
    property string globalSettingsPage: "general"
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
    var back = descendant(navigation, "settingsBackButton")
    if (!monitoring || !back) throw new Error("settings navigation controls are not addressable")
    monitoring.clicked()
    if (mockController.selections.length !== 1 || mockController.selections[0].page !== "monitoring" || mockController.selections[0].section !== "")
      throw new Error("settings page selection failed")
    if (!monitoring.active || !monitoring.selected) throw new Error("selected settings page was not reflected")
    back.clicked()
    if (!mockController.returned) throw new Error("settings back action failed")
    console.log("PRIVACY_QML_SETTINGS_NAVIGATION_OK")
    Qt.quit()
  })
}
