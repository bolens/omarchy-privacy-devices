import QtQuick
import QtQuick.Layouts
import qs.Commons

GridLayout {
  id: grid

  property int wideColumns: 2
  property real responsiveWidth: width
  property real breakpoint: Style.space(520)
  readonly property bool twoColumns: responsiveWidth >= breakpoint

  Layout.fillWidth: true
  Layout.minimumWidth: 0
  Layout.preferredWidth: 0
  implicitWidth: 0
  columns: twoColumns ? Math.max(2, wideColumns) : 1
  columnSpacing: Style.spacing.md
  rowSpacing: Style.spacing.md
}
