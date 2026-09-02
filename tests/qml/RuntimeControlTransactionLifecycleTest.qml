pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.settings = {enabledKinds:["screen-recording"], notifyOnControlChanges:false}

    service.beginControlTransaction("screen-recording", true)
    if (!service.controlPending("screen-recording") || service.controlTransactions["screen-recording"].status !== "applying")
      throw new Error("control transaction did not enter applying state")
    service.beginControlVerification("screen-recording", 0)
    if (service.controlTransactions["screen-recording"].status !== "verifying")
      throw new Error("successful command did not enter verification")
    service.verifyControlTransaction("screen-recording", false, true)
    if (service.controlTransactions["screen-recording"].status !== "verifying")
      throw new Error("mismatched observation completed verification")
    service.verifyControlTransaction("screen-recording", true, true)
    if (service.controlPending("screen-recording") || service.controlTransactions["screen-recording"].status !== "succeeded")
      throw new Error("matching observation did not complete verification")

    service.beginControlTransaction("screen-recording", false)
    service.beginControlVerification("screen-recording", 9)
    if (service.controlPending("screen-recording") || service.controlTransactions["screen-recording"].status !== "failed"
        || service.controlTransactions["screen-recording"].code !== "command_failed")
      throw new Error("failed command did not terminate its transaction")

    service.controlTransactions = ({})
    if (!service.beginExternalControl("screen-recording", true)
        || service.controlTransactions["screen-recording"].status !== "verifying")
      throw new Error("eligible external control was not tracked")
    if (service.beginExternalControl("screen-recording", false))
      throw new Error("pending external control was accepted twice")
    service.settings = {enabledKinds:[], notifyOnControlChanges:false}
    service.controlTransactions = ({})
    if (service.beginExternalControl("screen-recording", true))
      throw new Error("disabled external control was accepted")

    console.log("PRIVACY_QML_CONTROL_TRANSACTION_LIFECYCLE_OK")
    Qt.quit()
  }
}
