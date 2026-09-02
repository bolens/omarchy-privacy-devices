pragma ComponentBehavior: Bound
import QtQuick
import qs.Ui as Ui

Ui.Button {
  id: root

  focusable: true
  Accessible.role: Accessible.Button
  Accessible.name: text !== "" ? text : (tooltipText !== "" ? tooltipText : iconText)
  Accessible.description: tooltipText !== "" && tooltipText !== Accessible.name ? tooltipText : ""
  Accessible.onPressAction: root.triggerAccessiblePress()

  function triggerAccessiblePress() {
    if (!enabled) return false
    root.clicked()
    return true
  }
}
