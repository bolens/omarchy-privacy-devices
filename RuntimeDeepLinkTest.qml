import Quickshell
import QtQuick

ShellRoot {
  id: root
  property int summons: 0

  QtObject {
    id: shellMock
    function summon(pluginId, argument) {
      if (pluginId !== "io.github.bolens.privacy-devices" || argument !== "") throw new Error("deep link summoned the wrong plugin")
      root.summons += 1
      return true
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
    console.log("PRIVACY_QML_DEEP_LINK_OK")
    Qt.quit()
  }
}
