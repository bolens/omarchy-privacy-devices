pragma ComponentBehavior: Bound
import Quickshell
import QtQuick

ShellRoot {
  id: root
  property var commits: []
  property int phase: 0
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
    id: lifecycle
    interval: 110; running: true
    onTriggered: {
      if (root.phase === 0) {
        if (root.commits.length !== 2 || root.commits[1].showIdle !== true) throw new Error("explicit flush lost the latest mutation")
        if (mutation.flush()) throw new Error("empty mutation flush was accepted")
        mutation.complete(false, "write rejected")
        if (mutation.status !== "failed" || mutation.detail !== "write rejected") throw new Error("failed mutation feedback was lost")
        root.phase = 1
        interval = 35
        restart()
        return
      }
      if (root.phase === 1) {
        mutation.submit(root.commits[1], {showControls:true})
        if (mutation.status !== "saving" || mutation.detail !== "") throw new Error("new mutation did not clear stale failure feedback")
        root.phase = 2
        interval = 130
        restart()
        return
      }
      if (root.commits.length !== 3 || root.commits[2].showControls !== true)
        throw new Error("mutation after failure did not commit")
      if (mutation.status !== "") throw new Error("successful mutation feedback did not expire")
      console.log("PRIVACY_QML_SETTINGS_MUTATION_OK")
      Qt.quit()
    }
  }
}
