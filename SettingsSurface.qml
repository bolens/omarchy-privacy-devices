import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Rectangle {
  id: surface
  default property alias content: surfaceColumn.data
  property color accent: Color.muted

  Layout.fillWidth: true
  implicitHeight: surfaceColumn.implicitHeight + Style.spacing.md * 2
  radius: Style.cornerRadius
  color: Util.alpha(accent, 0.05)
  border.width: 1
  border.color: Util.alpha(accent, 0.18)

  ColumnLayout {
    id: surfaceColumn
    anchors.fill: parent
    anchors.margins: Style.spacing.md
    spacing: Style.spacing.md
  }
}
