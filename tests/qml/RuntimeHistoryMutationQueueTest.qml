import Quickshell
import QtQuick

ShellRoot {
  Service { id: service }

  Component.onCompleted: {
    service.historyMutationBusy = true
    if (!service.enqueueHistoryMutation(["append", "first"])
        || !service.enqueueHistoryMutation(["clear"])
        || !service.enqueueHistoryMutation(["append", "second"])
        || service.enqueueHistoryMutation(["invalid"]))
      throw new Error("history mutation queue rejected a valid action or accepted an invalid one")
    if (JSON.stringify(service.historyMutationQueue) !== JSON.stringify([
      ["append", "first"], ["clear"], ["append", "second"]
    ])) throw new Error("history mutations did not preserve request order")
    console.log("PRIVACY_QML_HISTORY_MUTATION_QUEUE_OK")
    Qt.quit()
  }
}
