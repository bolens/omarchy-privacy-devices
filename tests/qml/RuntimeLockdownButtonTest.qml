pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root

  Service { id: service }
  QtObject {
    id: shellMock
    function serviceFor(id) { return id === "io.github.bolens.privacy-devices" ? service : null }
    function updateEntryInline(_id, _settings) {}
  }
  QtObject {
    id: barMock
    property var shell: shellMock
    property color barForeground: "#ffffff"
    property color foreground: "#ffffff"
    property color urgent: "#ff5555"
    property string fontFamily: "sans-serif"
    property bool foregroundAnimationEnabled: false
    property var activePopout: ""
    property bool vertical: false
    property int barSize: 40
    property string position: "top"
    property var screen: null
    function switchPanelFrom(_owner, _direction) { return false }
    function requestPopout(key) { activePopout = key }
    function releasePopout(key) { if (activePopout === key) activePopout = "" }
    function registerClickTarget(_item) {}
    function unregisterClickTarget(_item) {}
    function showTooltip(_item, _text) {}
    function hideTooltip(_item) {}
  }
  BarWidget {
    id: widget
    bar: barMock
    settings: ({enabledKinds:[],historyEnabled:false,showIdle:true,showControls:true})
  }

  Component.onCompleted: {
    service.configure({enabledKinds:[],historyEnabled:false,directDeviceMonitoring:false})
    widget.open()
    Qt.callLater(function() {
      var button = widget.lockdownActionControl
      if (!button) throw new Error("privacy lockdown control is not addressable")
      if (button.iconText !== "󰌾" || button.tooltipText !== "Lock down privacy controls" || !button.enabled)
        throw new Error("privacy lockdown control did not expose its initial state")
      if (widget.activateLockdownAction()) throw new Error("first lockdown action bypassed confirmation")
      Qt.callLater(function() {
        if (widget.confirmationPending !== "lockdown" || button.tooltipText !== "Confirm privacy lockdown")
          throw new Error("first lockdown click did not arm confirmation: pending=" + widget.confirmationPending + " tooltip=" + button.tooltipText)
        widget.activateLockdownAction()
        Qt.callLater(function() {
          if (service.privacyPresetState !== "succeeded" || button.tooltipText !== "Lock down privacy controls")
            throw new Error("confirmed lockdown did not settle through the service")
          service.privacyPresetUndoAvailable = true
          Qt.callLater(function() {
            if (button.iconText !== "󰌿" || button.tooltipText !== "Restore the privacy state from before lockdown")
              throw new Error("available lockdown undo did not update the compact control")
            service.privacyPresetState = "applying"
            Qt.callLater(function() {
              if (button.enabled) throw new Error("lockdown control remained enabled while applying")
              service.privacyPresetState = "partial"
              service.privacyPresetUndoAvailable = false
              Qt.callLater(function() {
                var feedback = widget.privacyPresetFeedbackSurface
                if (!button.enabled || !feedback || !feedback.visible || feedback.kind !== "error"
                    || feedback.message !== "Privacy preset finished with unavailable or failed controls.")
                  throw new Error("partial lockdown result did not expose actionable error feedback: enabled=" + button.enabled
                    + " feedback=" + Boolean(feedback) + " visible=" + (feedback ? feedback.visible : "missing")
                    + " kind=" + (feedback ? feedback.kind : "missing") + " message=" + (feedback ? feedback.message : "missing"))
                service.privacyPresetState = "restoring"
                Qt.callLater(function() {
                  if (button.enabled || feedback.kind !== "info" || feedback.message !== "Restoring previous privacy state…")
                    throw new Error("lockdown restore state did not disable actions and update feedback")
                  console.log("PRIVACY_QML_LOCKDOWN_BUTTON_OK")
                  Qt.quit()
                })
              })
            })
          })
        })
      })
    })
  }
}
