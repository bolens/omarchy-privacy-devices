import Quickshell
import QtQuick

ShellRoot {
  id: root
  property int summons: 0
  property bool summonResult: true

  QtObject {
    id: shellMock
    function summon(pluginId, argument) {
      if (pluginId !== "io.github.bolens.privacy-devices" || argument !== "") throw new Error("deep link summoned the wrong plugin")
      root.summons += 1
      return root.summonResult
    }
  }

  Service { id: service; shell: shellMock }

  Component.onCompleted: {
    if (service.requestDeviceView("microphone") !== "activity" || service.requestedViewArgument !== "microphone" || root.summons !== 1)
      throw new Error("device deep link did not route through the service")
    service.updateBarPresentation("DP-1", {opened:true})
    if (service.requestSettingsView("monitoring", "observer-health") !== "monitoring#observer-health"
        || service.requestedView !== "settings" || service.requestedSettingsPage !== "monitoring"
        || service.requestedSettingsSection !== "observer-health" || root.summons !== 1)
      throw new Error("open-panel settings deep link did not switch in place")
    if (service.requestDeviceView("not-a-device") !== "invalid" || root.summons !== 1)
      throw new Error("invalid device deep link was accepted")
    service.updateBarPresentation("DP-1", {opened:false})
    service.updateBarPresentation("HDMI-A-1", {opened:true})
    if (service.requestPopupView("history", "") !== "history" || root.summons !== 1)
      throw new Error("open panel on another monitor unnecessarily summoned the plugin")
    service.updateBarPresentation("HDMI-A-1", {opened:false})
    root.summonResult = false
    if (service.requestSettingsView("alerts", "notifications") !== "unavailable" || root.summons !== 2
        || service.requestedSettingsPage !== "alerts" || service.requestedSettingsSection !== "notifications")
      throw new Error("closed-bar deep link did not preserve requested state after summon failure")
    console.log("PRIVACY_QML_DEEP_LINK_OK")
    Qt.quit()
  }
}
