import QtQuick
import QtQuick.Layouts
import qs.Commons

Rectangle {
  id: surface
  required property string message
  property string kind: "info"
  readonly property color tone: kind === "error" ? Color.urgent : (kind === "success" ? Color.accent : Color.muted)
  readonly property string icon: kind === "error" ? "!" : (kind === "success" ? "✓" : "󰋼")
  Layout.fillWidth: true
  implicitHeight: row.implicitHeight + Style.spacing.md * 2
  radius: Style.cornerRadius
  color: Util.alpha(tone, 0.055)
  border.width: 1
  border.color: Util.alpha(tone, 0.18)
  RowLayout {
    id: row
    anchors.fill: parent
    anchors.margins: Style.spacing.md
    spacing: Style.spacing.sm
    Text { text: surface.icon; textFormat: Text.PlainText; color: surface.tone; font.family: Style.font.family; font.pixelSize: Style.font.body; font.weight: Font.DemiBold }
    Text { objectName: "messageSurfaceText"; Layout.fillWidth: true; text: surface.message; textFormat: Text.PlainText; color: Color.popups.text; wrapMode: Text.WordWrap; font.family: Style.font.family; font.pixelSize: Style.font.caption }
  }
}
