import QtQuick
import "BarHostProtocol.js" as Protocol

QtObject {
  id: access
  property QtObject host: null
  property int fallbackBarSize: 24
  property color fallbackUrgent: "#cc0000"
  property color fallbackForeground: "#ffffff"
  property color fallbackBarForeground: "#ffffff"
  readonly property bool vertical: Protocol.vertical(access.host)
  readonly property int barSize: Protocol.barSize(access.host, access.fallbackBarSize)
  readonly property color urgent: Protocol.color(access.host, "urgent", access.fallbackUrgent)
  readonly property color foreground: Protocol.color(access.host, "foreground", access.fallbackForeground)
  readonly property color barForeground: Protocol.color(access.host, "barForeground", access.fallbackBarForeground)
  function run(command: string): bool { return Protocol.run(access.host, command) }
  function switchPanel(owner: QtObject, direction: int): bool { return Protocol.switchPanel(access.host, owner, direction) }
  function serviceFor(moduleName: string): var { return Protocol.serviceFor(access.host, moduleName) }
  function updateEntry(moduleName: string, entry: var): bool { return Protocol.updateEntry(access.host, moduleName, entry) }
}
