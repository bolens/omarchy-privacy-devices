pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  property int summons: 0

  QtObject {
    id: shellMock
    function summon(_pluginId, _argument) { root.summons++; return true }
  }

  Service { id: service; shell: shellMock }

  Component.onCompleted: {
    service.updateBarPresentation("DP-1", {opened:true})
    var accepted = service.notificationAction("open-activity", "microphone")
    if (!accepted || accepted.name !== "open-activity" || accepted.argument !== "microphone")
      throw new Error("valid notification callback was rejected")
    if (service.notificationAction("open-activity", "not-a-kind") !== null
        || service.notificationAction("open-diagnostics", "unexpected") !== null
        || service.notificationAction("shell-command", "microphone") !== null)
      throw new Error("unsafe notification callback was accepted")

    var serial = service.settingsRequestSerial
    if (service.dispatchPrivacyAction("open-activity", "microphone") !== "activity"
        || service.requestedView !== "activity" || service.requestedViewArgument !== "microphone"
        || service.settingsRequestSerial !== serial + 1 || root.summons !== 0)
      throw new Error("activity callback did not route to the open monitor")
    serial = service.settingsRequestSerial
    if (service.dispatchPrivacyAction("open-diagnostics", "") !== "diagnostics"
        || service.requestedView !== "diagnostics" || service.requestedViewArgument !== ""
        || service.settingsRequestSerial !== serial + 1)
      throw new Error("diagnostics callback did not clear its argument")
    serial = service.settingsRequestSerial
    if (service.dispatchPrivacyAction("lockdown", "") !== "lockdown" || service.requestedView !== "lockdown"
        || service.settingsRequestSerial !== serial + 1)
      throw new Error("lockdown callback did not route to confirmation")
    serial = service.settingsRequestSerial
    if (service.dispatchPrivacyAction("open-history", "camera") !== "history"
        || service.requestedView !== "history" || service.requestedViewArgument !== "camera")
      throw new Error("history callback lost its device context")
    if (service.dispatchPrivacyAction("open-history", "bad-kind") !== "invalid"
        || service.settingsRequestSerial !== serial + 1)
      throw new Error("invalid callback mutated navigation state")
    if (service.dispatchPrivacyAction("undo-lockdown", "") !== "unavailable")
      throw new Error("unavailable undo callback was not guarded")

    console.log("PRIVACY_QML_NOTIFICATION_ACTION_ROUTING_OK")
    Qt.quit()
  }
}
