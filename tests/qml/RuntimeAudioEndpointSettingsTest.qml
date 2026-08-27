import Quickshell
import QtQuick

ShellRoot {
  id: root
  property var events: []

  QtObject {
    id: serviceMock
    property string audioEndpointMessage: ""
    property var endpoints: [
      {id:"alsa_input.usb-desk",label:"Desk microphone",muted:false},
      {id:"alsa_input.usb-chat",label:"Chat microphone",muted:true}
    ]
    function audioEndpoints(kind) { return kind === "microphone" ? endpoints : [] }
    function deviceChangesFor(kind) { return kind === "microphone" ? [{kind:kind,label:"USB microphone",change:"appeared",at:1}] : [] }
    function refreshAudioEndpoints(kind) { root.events = root.events.concat([{action:"refresh",kind:kind}]) }
    function setAudioEndpointMuted(kind, id, muted) { root.events = root.events.concat([{action:"mute",kind:kind,id:id,muted:muted}]) }
  }

  QtObject {
    id: controllerMock
    property var privacyService: serviceMock
    property string editingKind: "microphone"
    property color activeThemeColor: "#55aaff"
  }

  AudioEndpointSettings { id: settings; width: 500; controller: controllerMock }

  function descendant(item, name) {
    if (!item) return null
    if (item.objectName === name) return item
    var children = item.children || []
    for (var index = 0; index < children.length; index++) {
      var found = descendant(children[index], name)
      if (found) return found
    }
    return null
  }

  Component.onCompleted: Qt.callLater(function() {
    var refresh = descendant(settings, "audioEndpointRefreshButton")
    var allowedRow = descendant(settings, "audioEndpointRow-alsa_input.usb-desk")
    var blockedRow = descendant(settings, "audioEndpointRow-alsa_input.usb-chat")
    var allowedStatus = descendant(settings, "audioEndpointStatus-alsa_input.usb-desk")
    var blockedStatus = descendant(settings, "audioEndpointStatus-alsa_input.usb-chat")
    var allowedAction = descendant(settings, "audioEndpointAction-alsa_input.usb-desk")
    var blockedAction = descendant(settings, "audioEndpointAction-alsa_input.usb-chat")
    var deviceChange = descendant(settings, "audioEndpointChange-0")
    if (!refresh || !allowedRow || !blockedRow || !allowedStatus || !blockedStatus || !allowedAction || !blockedAction || !deviceChange)
      throw new Error("audio endpoint controls are not addressable")
    if (deviceChange.text !== "USB microphone appeared during this session") throw new Error("device discovery feedback was not specific")
    if (allowedStatus.text !== "Allowed · unmuted" || allowedAction.text !== "Block"
        || blockedStatus.text !== "Blocked · muted" || blockedAction.text !== "Allow")
      throw new Error("audio endpoint controls did not reflect observed mute state")
    refresh.clicked()
    allowedAction.clicked()
    blockedAction.clicked()
    if (root.events.length !== 3 || root.events[0].action !== "refresh" || root.events[0].kind !== "microphone"
        || root.events[1].id !== "alsa_input.usb-desk" || root.events[1].muted !== true
        || root.events[2].id !== "alsa_input.usb-chat" || root.events[2].muted !== false)
      throw new Error("audio endpoint controls dispatched the wrong operation")
    serviceMock.audioEndpointMessage = "Endpoint state updated"
    serviceMock.endpoints = [{id:"alsa_input.usb-desk",label:"Desk microphone",muted:true}]
    Qt.callLater(function() {
      var updatedStatus = descendant(settings, "audioEndpointStatus-alsa_input.usb-desk")
      var updatedAction = descendant(settings, "audioEndpointAction-alsa_input.usb-desk")
      var removedRow = descendant(settings, "audioEndpointRow-alsa_input.usb-chat")
      var message = descendant(settings, "messageSurfaceText")
      if (!updatedStatus || updatedStatus.text !== "Blocked · muted" || !updatedAction || updatedAction.text !== "Allow"
          || removedRow || !message || message.text !== "Endpoint state updated")
        throw new Error("audio endpoint surface did not react to observed state changes")
      controllerMock.privacyService = null
      Qt.callLater(function() {
        if (refresh.enabled || descendant(settings, "audioEndpointRow-alsa_input.usb-desk"))
          throw new Error("audio endpoint controls remained active without a service")
        console.log("PRIVACY_QML_AUDIO_ENDPOINT_SETTINGS_OK")
        Qt.quit()
      })
    })
  })
}
