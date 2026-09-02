pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

ColumnLayout {
  id: view

  required property var controller
  readonly property var privacyService: controller.privacyService
  readonly property alias searchControl: historySearch
  readonly property alias countLabel: historyCountText
  readonly property alias disabledSettingsControl: historyDisabledSettingsButton
  readonly property var filterControls: [historyKindFilterButton, historyConfidenceFilterButton, historySortButton]

  visible: controller.showingHistory
  Layout.fillWidth: true
  spacing: Style.spacing.md

  RowLayout {
    Layout.fillWidth: true
    Button { iconText: "󰁍"; tooltipText: "Back"; horizontalPadding: Style.spacing.controlGap; onClicked: view.controller.showActivity() }
    Text { Layout.fillWidth: true; text: "Activity history"; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.title; font.weight: Font.DemiBold }
    Button {
      visible: view.controller.historyPresentationEnabled && view.privacyService && view.privacyService.displayHistory.length > 0
      text: view.controller.confirmationPending === "history" ? "Confirm clear" : "Clear history"
      onClicked: view.controller.requestHistoryClear()
    }
  }

  SettingsSurface {
    visible: view.controller.historyPresentationEnabled && view.controller.historySummaryRows.length > 0
    Layout.fillWidth: true
    PanelSectionHeader { Layout.fillWidth: true; text: "Privacy summary" }
    RowLayout {
      Layout.fillWidth: true
      Button { text: "Today"; bordered: true; selected: view.controller.historySummaryWindow === 24 * 60 * 60 * 1000; onClicked: view.controller.historySummaryWindow = 24 * 60 * 60 * 1000 }
      Button { text: "7 days"; bordered: true; selected: view.controller.historySummaryWindow === 7 * 24 * 60 * 60 * 1000; onClicked: view.controller.historySummaryWindow = 7 * 24 * 60 * 60 * 1000 }
      Item { Layout.fillWidth: true }
    }
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: 52
      spacing: Style.spacing.xs
      Repeater {
        model: view.controller.historyTrend.buckets
        delegate: Rectangle {
          required property var modelData
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignBottom
          implicitHeight: Math.max(3, 46 * (view.controller.historyTrend.maximum > 0 ? modelData.count / view.controller.historyTrend.maximum : 0))
          radius: Math.min(width / 2, Style.cornerRadius)
          color: modelData.count > 0 ? view.controller.activeThemeColor : Util.alpha(Color.muted, 0.18)
          opacity: modelData.count > 0 ? 0.78 : 1
          ToolTip.text: modelData.count + (modelData.count === 1 ? " completed session" : " completed sessions")
          ToolTip.visible: trendHover.hovered
          HoverHandler { id: trendHover }
        }
      }
    }
    Text { Layout.fillWidth: true; text: view.controller.historyTrend.total + (view.controller.historyTrend.total === 1 ? " completed session across this period" : " completed sessions across this period"); textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; horizontalAlignment: Text.AlignHCenter }
    Repeater {
      model: view.controller.historySummaryRows
      delegate: Rectangle {
        id: summarySurface
        required property var modelData
        Layout.fillWidth: true
        implicitHeight: summaryRow.implicitHeight + Style.spacing.md * 2
        radius: Style.cornerRadius
        color: Util.alpha(view.controller.itemColor(view.controller.item(summarySurface.modelData.kind)), 0.045)
        border.width: 1
        border.color: Util.alpha(view.controller.itemColor(view.controller.item(summarySurface.modelData.kind)), 0.14)
        RowLayout {
          id: summaryRow
          anchors.fill: parent
          anchors.margins: Style.spacing.md
          spacing: Style.spacing.md
          Text { text: view.controller.iconFor(summarySurface.modelData.kind); textFormat: Text.PlainText; color: view.controller.itemColor(view.controller.item(summarySurface.modelData.kind)); font.family: Style.font.family; font.pixelSize: Style.font.icon * view.controller.popupItemScale }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.spacing.xs
            Text { Layout.fillWidth: true; text: Model.label(summarySurface.modelData.kind) + " · " + summarySurface.modelData.count + (summarySurface.modelData.count === 1 ? " session" : " sessions") + " · " + Model.formatDuration(summarySurface.modelData.durationMs); textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body * view.controller.popupItemScale; font.weight: Font.DemiBold; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: summarySurface.modelData.applications.join(", "); textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption * view.controller.popupItemScale; elide: Text.ElideRight }
            Text { visible: summarySurface.modelData.newApplications.length > 0; Layout.fillWidth: true; text: "New in retained history: " + summarySurface.modelData.newApplications.join(", "); textFormat: Text.PlainText; color: view.controller.itemColor(view.controller.item(summarySurface.modelData.kind)); font.family: Style.font.family; font.pixelSize: Style.font.caption * view.controller.popupItemScale; elide: Text.ElideRight }
          }
        }
      }
    }
  }

  RowLayout {
    visible: view.controller.historyPresentationEnabled && view.privacyService && view.privacyService.displayHistory.length > 0
    Layout.fillWidth: true
    TextField {
      id: historySearch
      Layout.fillWidth: true
      placeholderText: "Search history"
      foreground: Color.popups.text
      accent: view.controller.activeThemeColor
      font.family: Style.font.family
      onTextChanged: view.controller.historyQuery = text
    }
    Rectangle {
      id: historyCountPill
      implicitWidth: historyCountText.implicitWidth + Style.spacing.md * 2
      implicitHeight: historyCountText.implicitHeight + Style.spacing.sm
      radius: implicitHeight / 2
      color: Util.alpha(view.controller.activeThemeColor, 0.14)
      border.width: 1
      border.color: Util.alpha(view.controller.activeThemeColor, 0.28)
      Text {
        id: historyCountText
        anchors.centerIn: parent
        text: Model.historyCountLabel(view.controller.filteredHistory.length, view.privacyService.displayHistory.length)
        textFormat: Text.PlainText
        color: view.controller.activeThemeColor
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.weight: Font.DemiBold
      }
    }
  }

  GridLayout {
    objectName: "historyFilterRow"
    visible: view.controller.historyPresentationEnabled && view.privacyService && view.privacyService.displayHistory.length > 0
    Layout.fillWidth: true
    columns: 3
    columnSpacing: Style.spacing.sm
    Button {
      id: historyKindFilterButton
      objectName: "historyKindFilterButton"
      Layout.fillWidth: true
      text: view.controller.historyKindFilter === "all" ? "All devices" : Model.label(view.controller.historyKindFilter)
      tooltipText: "Device filter · click to cycle"
      onClicked: {
        var choices = ["all"].concat(Model.KINDS)
        view.controller.historyKindFilter = choices[(choices.indexOf(view.controller.historyKindFilter) + 1) % choices.length]
      }
    }
    Button {
      id: historyConfidenceFilterButton
      objectName: "historyConfidenceFilterButton"
      Layout.fillWidth: true
      text: view.controller.historyConfidenceFilter === "all" ? "All evidence" : (view.controller.historyConfidenceFilter === "confirmed" ? "Confirmed" : "Inferred")
      tooltipText: "Evidence confidence · click to cycle"
      onClicked: {
        var choices = ["all", "confirmed", "inferred"]
        view.controller.historyConfidenceFilter = choices[(choices.indexOf(view.controller.historyConfidenceFilter) + 1) % choices.length]
      }
    }
    Button {
      id: historySortButton
      objectName: "historySortButton"
      Layout.fillWidth: true
      text: view.controller.historySortMode === "recent" ? "Recent first" : (view.controller.historySortMode === "duration" ? "Longest first" : "By application")
      tooltipText: "Sort order · click to cycle"
      onClicked: {
        var choices = ["recent", "duration", "application"]
        view.controller.historySortMode = choices[(choices.indexOf(view.controller.historySortMode) + 1) % choices.length]
      }
    }
  }

  SettingsSurface {
    visible: !view.controller.historyPresentationEnabled
    Layout.fillWidth: true
    PanelSectionHeader { Layout.fillWidth: true; text: "History is off" }
    Text { Layout.fillWidth: true; text: "Enable history to keep completed activity on this device for up to seven days."; textFormat: Text.PlainText; color: Color.muted; font.family: Style.font.family; font.pixelSize: Style.font.caption; wrapMode: Text.WordWrap }
    Button { id: historyDisabledSettingsButton; text: "Open monitoring settings"; bordered: true; background: Util.alpha(view.controller.activeThemeColor, 0.06); onClicked: view.controller.showGlobalSettings("monitoring", "private-data") }
  }

  PrivacyMessageSurface {
    visible: view.controller.historyPresentationEnabled && view.privacyService && !view.privacyService.historyLoaded
    message: "Loading history…"
  }
  PrivacyMessageSurface {
    visible: view.controller.historyPresentationEnabled && view.privacyService && view.privacyService.historyLoaded && view.privacyService.displayHistory.length === 0
    message: "No completed activity yet."
  }
  PrivacyMessageSurface {
    visible: view.controller.historyPresentationEnabled && view.privacyService && view.privacyService.displayHistory.length > 0 && view.controller.filteredHistory.length === 0
    message: "No history matches your search."
  }

  GridLayout {
    id: historyRows
    visible: view.controller.historyPresentationEnabled
    Layout.fillWidth: true
    columns: view.controller.popupGridColumns
    columnSpacing: view.controller.popupDensity === "compact" ? Style.spacing.sm : Style.spacing.md
    rowSpacing: view.controller.popupDensity === "compact" ? Style.spacing.sm : Style.spacing.md
    Repeater {
      model: view.controller.filteredHistory
      delegate: SettingsSurface {
        id: historySurface
        required property var modelData
        required property int index
        Layout.fillWidth: true
        Layout.columnSpan: view.controller.popupGridColumns === 2 && historySurface.index === view.controller.filteredHistory.length - 1 && view.controller.filteredHistory.length % 2 === 1 ? 2 : 1
        accent: view.controller.itemColor(view.controller.item(historySurface.modelData.kind))
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.spacing.md * view.controller.popupItemScale
          Text { text: view.controller.iconFor(historySurface.modelData.kind); textFormat: Text.PlainText; color: view.controller.itemColor(view.controller.item(historySurface.modelData.kind)); font.family: Style.font.family; font.pixelSize: Style.font.icon * view.controller.popupItemScale }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.spacing.xs
            RowLayout {
              Layout.fillWidth: true
              spacing: Style.spacing.sm
              Text { Layout.fillWidth: true; text: historySurface.modelData.application || "Unknown application"; textFormat: Text.PlainText; color: Color.popups.text; font.family: Style.font.family; font.pixelSize: Style.font.body * view.controller.popupItemScale; font.weight: Font.DemiBold; elide: Text.ElideRight }
              Text { text: Model.historyPeriodLabel(historySurface.modelData.endedAt, view.controller.durationNow); textFormat: Text.PlainText; color: view.controller.itemColor(view.controller.item(historySurface.modelData.kind)); font.family: Style.font.family; font.pixelSize: Style.font.caption * view.controller.popupItemScale; font.weight: Font.DemiBold }
            }
            Text { Layout.fillWidth: true; text: Model.label(historySurface.modelData.kind) + " · " + Model.formatDuration(historySurface.modelData.durationMs) + " · " + Model.historyAgeLabel(historySurface.modelData.endedAt, view.controller.durationNow) + (historySurface.modelData.confidence && String(historySurface.modelData.confidence).toLowerCase() !== "confirmed" ? " · Inferred" : ""); textFormat: Text.PlainText; color: Color.muted; opacity: Math.max(0.75, view.controller.popupIdleOpacity); font.family: Style.font.family; font.pixelSize: Style.font.caption * view.controller.popupItemScale; elide: Text.ElideRight }
            Text { visible: view.controller.popupDensity !== "compact" && Boolean(historySurface.modelData.device); Layout.fillWidth: true; text: view.controller.deviceLabel(historySurface.modelData.device); textFormat: Text.PlainText; color: Color.muted; opacity: Math.max(0.75, view.controller.popupIdleOpacity); font.family: Style.font.family; font.pixelSize: Style.font.caption * view.controller.popupItemScale; elide: Text.ElideRight }
          }
        }
      }
    }
  }
}
