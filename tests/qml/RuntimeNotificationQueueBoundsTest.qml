pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../.."

ShellRoot {
  QtObject { id: host }
  PrivacyNotificationController { id: controller; host: host }
  Component.onCompleted: {
    for (var index = 0; index < 150; index++)
      controller.enqueueActivity("started", {kind:"camera", application:String(index), icon:"camera"})
    if (controller.queue.length !== 100 || controller.queue[0].application !== "50")
      throw new Error("notification count bound did not retain newest events")
    controller.enqueueActivity("started", {kind:"camera", application:"x".repeat(262144), icon:"camera"})
    if (controller.queuedEventBytes(controller.queue) > controller.maximumQueuedEventBytes)
      throw new Error("notification byte bound was exceeded")
    console.info("PRIVACY_QML_NOTIFICATION_QUEUE_BOUNDS_OK")
    Qt.quit()
  }
}
