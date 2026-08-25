import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

ColumnLayout {
  id: editor
  required property var controller
  default property alias sections: sectionColumn.data
  signal backRequested()

  Layout.fillWidth: true
  spacing: Style.spacing.md

  RowLayout {
    Layout.fillWidth: true
    Button {
      iconText: "󰁍"
      tooltipText: "Back to privacy activity"
      horizontalPadding: Style.spacing.controlGap
      onClicked: editor.backRequested()
    }
    Text {
      Layout.fillWidth: true
      text: Model.label(editor.controller.editingKind) + " settings"
      textFormat: Text.PlainText
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.title
      font.weight: Font.DemiBold
    }
    Button {
      iconText: "󰅁"
      tooltipText: "Previous device"
      enabled: editor.controller.canMoveItem(editor.controller.editingKind, -1)
      horizontalPadding: Style.spacing.controlGap
      onClicked: editor.controller.moveDeviceEditor(-1)
    }
    Button {
      iconText: "󰅂"
      tooltipText: "Next device"
      enabled: editor.controller.canMoveItem(editor.controller.editingKind, 1)
      horizontalPadding: Style.spacing.controlGap
      onClicked: editor.controller.moveDeviceEditor(1)
    }
  }

  ColumnLayout {
    id: sectionColumn
    Layout.fillWidth: true
    spacing: Style.spacing.md
  }
}
