import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {enabledKinds:["camera", "screen-recording"], blockableKinds:["camera"], notifyOnControlChanges:false}
    if (service.controlRequestStatus("not-a-kind") !== "unsupported")
      throw new Error("unknown control was not rejected")
    if (service.controlRequestStatus("microphone") !== "disabled")
      throw new Error("disabled control did not report disabled")

    service.dependencyCheckedMap = {camera:true}
    service.dependencyReadyMap = {camera:false}
    if (service.controlRequestStatus("camera") !== "unavailable")
      throw new Error("missing dependency did not gate the control")
    service.dependencyReadyMap = {camera:true}
    service.controlTransactions = {camera:{status:"verifying", expectedEnabled:false}}
    if (service.controlRequestStatus("camera") !== "busy" || !service.controlPending("camera"))
      throw new Error("pending transaction did not gate duplicate control")
    service.controlTransactions = ({})
    if (service.controlRequestStatus("camera") !== "ok")
      throw new Error("eligible camera control was not enabled")

    if (!service.controllable("screen-recording") || service.serviceControllable("screen-recording")
        || service.controlRequestStatus("screen-recording") !== "unsupported")
      throw new Error("externally observed recording control crossed the service-owned boundary")
    if (service.toggleControl("microphone") || service.toggleControl("screen-recording"))
      throw new Error("gated control unexpectedly launched a helper")

    console.log("PRIVACY_QML_CONTROL_REQUEST_GATING_OK")
    Qt.quit()
  }
}
