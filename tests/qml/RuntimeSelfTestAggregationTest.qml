import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  function check(label) {
    for (var index = 0; index < service.selfTestResult.checks.length; index++)
      if (service.selfTestResult.checks[index].label === label) return service.selfTestResult.checks[index]
    return null
  }

  Component.onCompleted: {
    service.settings = {enabledKinds:["screen-recording"], directDeviceMonitoring:true, historyEnabled:false}
    service.dependencyCheckedMap = {"screen-recording":true}
    service.dependencyReadyMap = {"screen-recording":false}
    service.observerHealth = {
      "direct-device":{status:"degraded", source:"direct-device", code:"permission_denied", reason:"denied"},
      "fallback-observer":{status:"degraded", source:"fallback-observer", code:"invalid_payload", reason:"invalid"}
    }
    service.runSelfTest()
    if (!check("direct-device observer") || check("direct-device observer").status !== "attention"
        || !check("fallback observer") || check("fallback observer").status !== "attention"
        || check("Dependencies").status !== "attention" || check("Private history").status !== "passed"
        || service.selfTestResult.status !== "attention")
      throw new Error("self-test did not aggregate degraded runtime state")

    service.dependencyReadyMap = {"screen-recording":true}
    service.observerHealth = {
      "direct-device":{status:"healthy", source:"direct-device", code:"ok", reason:""},
      "fallback-observer":{status:"healthy", source:"fallback-observer", code:"ok", reason:""}
    }
    service.runSelfTest()
    if (check("direct-device observer").status !== "passed" || check("fallback observer").status !== "passed"
        || check("Dependencies").status !== "passed" || check("Private history").detail !== "disabled")
      throw new Error("self-test did not recover after runtime state improved")

    console.log("PRIVACY_QML_SELF_TEST_AGGREGATION_OK")
    Qt.quit()
  }
}
