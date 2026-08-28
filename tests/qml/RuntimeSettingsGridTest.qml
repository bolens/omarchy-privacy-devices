import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.Commons

ShellRoot {
  id: root

  Item {
    id: constrainedHost
    width: Style.space(400)
    property real configuredWidth: Style.space(720)
    PrivacySettingsGrid {
      id: constrainedGrid
      objectName: "responsiveSettingsGrid"
      width: constrainedHost.width
      responsiveWidth: Math.min(width, constrainedHost.configuredWidth)
      Item { implicitWidth: Style.space(420); implicitHeight: 20 }
      Item { implicitWidth: Style.space(420); implicitHeight: 20 }
    }
  }

  Item {
    id: wideHost
    width: Style.space(600)
    property real configuredWidth: Style.space(720)
    PrivacySettingsGrid {
      id: wideGrid
      width: wideHost.width
      responsiveWidth: Math.min(width, wideHost.configuredWidth)
      Item { implicitWidth: Style.space(200); implicitHeight: 20 }
      Item { implicitWidth: Style.space(200); implicitHeight: 20 }
    }
  }

  Component.onCompleted: Qt.callLater(function() {
    if (constrainedGrid.width > constrainedHost.width || constrainedGrid.twoColumns || constrainedGrid.columns !== 1)
      throw new Error("configured popup width or intrinsic children prevented the constrained grid from collapsing")
    if (!wideGrid.twoColumns || wideGrid.columns !== 2)
      throw new Error("wide settings grid did not pair related controls: width=" + wideGrid.width
        + " responsive=" + wideGrid.responsiveWidth + " breakpoint=" + wideGrid.breakpoint + " host=" + wideHost.width)
    wideGrid.wideColumns = 3
    if (wideGrid.columns !== 3) throw new Error("wide settings grid ignored its configured capacity")
    console.log("PRIVACY_QML_SETTINGS_GRID_OK")
    Qt.quit()
  })
}
