import Quickshell
import QtQuick

ShellRoot {
  id: root
  property var commits: []
  PrivacySettingsMutationController {
    id: mutation
    interval: 40
    feedbackDuration: 80
    onCommitRequested: function(settings) {
      root.commits = root.commits.concat([settings])
      mutation.complete(true)
    }
  }
  Component.onCompleted: {
    mutation.submit({showIdle:true,showControls:true}, {showIdle:false})
    mutation.submit({showIdle:false,showControls:true}, {showControls:false})
    if (mutation.status !== "saving") throw new Error("queued mutation did not expose saving state")
  }
  Timer {
    interval: 70; running: true
    onTriggered: {
      if (root.commits.length !== 1) throw new Error("rapid mutations were not coalesced")
      if (root.commits[0].showIdle !== false || root.commits[0].showControls !== false) throw new Error("coalesced settings lost a patch")
      if (mutation.status !== "saved") throw new Error("successful mutation did not expose saved state")
      mutation.submit(root.commits[0], {showIdle:true})
      mutation.flush()
    }
  }
  Timer {
    interval: 110; running: true
    onTriggered: {
      if (root.commits.length !== 2 || root.commits[1].showIdle !== true) throw new Error("explicit flush lost the latest mutation")
      mutation.complete(false, "write rejected")
      if (mutation.status !== "failed" || mutation.detail !== "write rejected") throw new Error("failed mutation feedback was lost")
      console.log("PRIVACY_QML_SETTINGS_MUTATION_OK")
      Qt.quit()
    }
  }
}
