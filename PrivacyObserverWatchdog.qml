import QtQuick
import "Model.js" as Model

QtObject {
  id: watchdog

  property bool enabled: false
  property bool processRunning: false
  property bool retiring: false
  property double lastSeen: 0
  property double startedAt: 0
  property int heartbeatSeconds: 5
  property int interval: 1000
  readonly property bool running: retryTimer.running

  signal retryRequested()
  signal heartbeatStale()

  function stop() { retryTimer.stop() }
  function restart() { retryTimer.restart() }

  property Timer retryTimer: Timer {
    interval: Math.max(100, watchdog.interval)
    repeat: false
    onTriggered: if (watchdog.enabled && !watchdog.retiring) watchdog.retryRequested()
  }

  property Timer heartbeatTimer: Timer {
    interval: 5000
    repeat: true
    running: watchdog.enabled
    onTriggered: {
      if (!watchdog.processRunning || watchdog.retiring) return
      if (Model.observerHeartbeatState(watchdog.lastSeen, watchdog.startedAt, Date.now(), watchdog.heartbeatSeconds).stale)
        watchdog.heartbeatStale()
    }
  }
}
