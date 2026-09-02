pragma ComponentBehavior: Bound
import QtQuick
import qs.Ui as Ui

Ui.WidgetButton {
  id: root

  activeFocusOnTab: visible && interactive && pressable && !concealed
  Keys.onReturnPressed: if (activeFocusOnTab) root.triggerPress(Qt.LeftButton)
  Keys.onEnterPressed: if (activeFocusOnTab) root.triggerPress(Qt.LeftButton)
  Keys.onSpacePressed: if (activeFocusOnTab) root.triggerPress(Qt.LeftButton)
  Accessible.role: Accessible.Button
  Accessible.name: tooltipText !== "" ? tooltipText : text
  Accessible.description: tooltipText !== "" && text !== "" && tooltipText !== text ? tooltipText : ""
  Accessible.onPressAction: root.triggerAccessiblePress()

  function triggerAccessiblePress() {
    if (!enabled || !activeFocusOnTab) return false
    root.triggerPress(Qt.LeftButton)
    return true
  }
}
