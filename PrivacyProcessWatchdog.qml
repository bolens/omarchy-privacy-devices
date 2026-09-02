import QtQuick

QtObject {
  id: watchdog
  required property var process
  property int timeoutMilliseconds: 30000
  property bool armed: false
  signal timedOut()
  function start() { armed = true; timer.restart() }
  function stop() { armed = false; timer.stop() }
  property Timer timer: Timer {
    interval: Math.max(100, watchdog.timeoutMilliseconds)
    onTriggered: {
      if (!watchdog.armed) return
      watchdog.armed = false
      watchdog.timedOut()
      if (watchdog.process && watchdog.process.running) watchdog.process.running = false
    }
  }
}
