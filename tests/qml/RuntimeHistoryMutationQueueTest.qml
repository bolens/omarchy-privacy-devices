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
      ["clear"], ["append", "second"]
    ])) throw new Error("history clear did not supersede obsolete queued appends")
    for (var index = 0; index < 150; index++)
      if (!service.enqueueHistoryMutation(["append", String(index)]))
        throw new Error("bounded history mutation queue rejected normal work")
    if (service.historyMutationQueue.length !== 100
        || service.historyMutationQueue[0][1] !== "50"
        || service.historyMutationQueue[99][1] !== "149")
      throw new Error("history mutation queue did not retain the newest bounded work")
    if (service.enqueueHistoryMutation(["append", "x".repeat(1048576)]))
      throw new Error("oversized history mutation was accepted")
    if (service.historyMutationQueue.length !== 100)
      throw new Error("oversized history mutation discarded queued work")
    if (!service.enqueueHistoryMutation(["clear"])
        || JSON.stringify(service.historyMutationQueue) !== JSON.stringify([["clear"]]))
      throw new Error("clear did not supersede obsolete queued history mutations")
    console.log("PRIVACY_QML_HISTORY_MUTATION_QUEUE_OK")
    Qt.quit()
  }
}
