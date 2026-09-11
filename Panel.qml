import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import "Model.js" as Model

Panel {
  id: root
  moduleName: "xoox.aero-x16-rgb"
  ipcTarget: "xoox.aero-x16-rgb"

  property int red: 0
  property int green: 80
  property int blue: 255
  property int brightnessPercent: 100
  property int pendingBrightness: 100
  property bool applyQueued: false
  property real wheelAccumulator: 0
  property string focusSection: "colors"
  property int selectedIndex: 0
  property bool cursorActive: false
  property bool cycling: false

  readonly property var swatches: Model.swatches
  readonly property bool lampOff: Model.isOff({
    r: red, g: green, b: blue, brightness: brightnessPercent
  })
  readonly property string currentHex: Model.hex(red, green, blue)
  readonly property color lampColor: Qt.rgba(red / 255, green / 255, blue / 255, 1)
  readonly property string bin: {
    var url = Qt.resolvedUrl("aero-rgb").toString()
    if (url.indexOf("file://") === 0)
      url = url.substring(7)
    return url
  }
  readonly property string statePath: Quickshell.env("HOME") + "/.config/aero-rgb/state.json"

  function applyState(obj) {
    if (!obj) return
    red = obj.r
    green = obj.g
    blue = obj.b
    brightnessPercent = obj.brightness
    pendingBrightness = obj.brightness
    cycling = obj.mode === "cycle"
  }

  function stopCycle() {
    if (cycleProc.running)
      cycleProc.running = false
    cycling = false
  }

  function startCycle() {
    cycling = true
    if (brightnessPercent <= 0)
      brightnessPercent = 100
    if (applyProc.running)
      applyProc.running = false
    cycleProc.running = false
    cycleProc.command = ["/usr/bin/python3", bin, "cycle", String(brightnessPercent)]
    cycleProc.running = true
  }

  function applyCommand(colorArg, brightnessArg) {
    stopCycle()
    pendingBrightness = brightnessArg
    if (applyProc.running) {
      applyQueued = true
      applyProc.pendingColor = colorArg
      applyProc.pendingBrightness = brightnessArg
      return
    }
    applyProc.running = false
    if (colorArg === "off")
      applyProc.command = ["/usr/bin/python3", bin, "off"]
    else
      applyProc.command = ["/usr/bin/python3", bin, colorArg.replace("#", ""), String(brightnessArg)]
    applyProc.running = true
  }

  function setSwatch(swatch) {
    if (!swatch) return
    if (swatch.id === "off") {
      red = 0
      green = 0
      blue = 0
      brightnessPercent = 0
      applyCommand("off", 0)
      return
    }
    red = swatch.r
    green = swatch.g
    blue = swatch.b
    if (brightnessPercent <= 0) brightnessPercent = 100
    applyCommand(Model.hex(red, green, blue), brightnessPercent)
  }

  function setBrightness(value) {
    var pct = Model.clamp(value, 0, 100)
    brightnessPercent = pct
    pendingBrightness = pct
    if (pct <= 0) {
      applyCommand("off", 0)
      return
    }
    if (cycling) {
      startCycle()
      return
    }
    if (red === 0 && green === 0 && blue === 0) {
      red = 0
      green = 80
      blue = 255
    }
    applyCommand(Model.hex(red, green, blue), pct)
  }

  function previewBrightness(value) {
    brightnessPercent = Model.clamp(value, 0, 100)
    brightnessDebounce.restart()
  }

  function moveCursor(dy) {
    cursorActive = true
    if (dy > 0 && focusSection === "colors") {
      focusSection = "brightness"
      selectedIndex = -1
      return
    }
    if (dy < 0 && focusSection === "brightness") {
      focusSection = "colors"
      if (selectedIndex < 0) selectedIndex = 0
    }
  }

  function moveCursorH(dx) {
    cursorActive = true
    if (focusSection === "brightness") {
      setBrightness(brightnessPercent + dx * 5)
      return
    }
    var next = selectedIndex + dx
    if (next < 0) next = 0
    if (next > swatches.length - 1) next = swatches.length - 1
    selectedIndex = next
  }

  function activateCursor() {
    if (focusSection === "colors" && selectedIndex >= 0 && selectedIndex < swatches.length)
      setSwatch(swatches[selectedIndex])
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView {
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: root.applyState(Model.parseState(text()))
    onFileChanged: reload()
  }

  Timer {
    id: brightnessDebounce
    interval: 120
    repeat: false
    onTriggered: root.setBrightness(root.brightnessPercent)
  }

  Process {
    id: applyProc
    property string pendingColor: ""
    property int pendingBrightness: 100
    stdout: StdioCollector { waitForEnd: true }
    onRunningChanged: {
      if (running) return
      if (root.applyQueued) {
        root.applyQueued = false
        root.applyCommand(pendingColor, pendingBrightness)
      }
    }
  }

  Process {
    id: cycleProc
  }

  Process {
    id: disableProc
    command: ["/usr/bin/omarchy", "plugin", "disable", "xoox.aero-x16-rgb"]
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰌌"
    dimmed: root.lampOff
    tooltipText: root.cycling ? "Gigabyte Aero X16 · cycle" : (root.lampOff ? "Gigabyte Aero X16 · off" : "Gigabyte Aero X16 · " + root.currentHex + " · " + root.brightnessPercent + "%")
    iconComponent: Component {
      OpticalGlyph {
        anchors.fill: parent
        text: "󰌌"
        color: root.lampOff ? button.foreground : root.lampColor
        fontFamily: button.fontFamily
        fontSize: button.fontSize
      }
    }
    onPressed: function() { root.toggle() }
    onWheelMoved: function(delta) {
      var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
      root.wheelAccumulator = wheel.remainder
      if (wheel.steps === 0) return
      root.setBrightness(root.brightnessPercent + wheel.steps * 5)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight, Style.space(480))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        if (dy !== 0) root.moveCursor(dy)
        else if (dx !== 0) root.moveCursorH(dx)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: panelColumn
        width: parent.width
        spacing: Style.space(14)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, closeButton.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: "󰌌"
            color: root.lampOff ? Qt.darker(root.bar.foreground, 1.6) : root.lampColor
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: closeButton.left
            anchors.rightMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Gigabyte Aero X16: Keyboard RGB"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              wrapMode: Text.WordWrap
              width: parent.width
            }

            Text {
              text: root.cycling ? ("CYCLE  " + root.brightnessPercent + "%") : (root.lampOff ? "OFF" : (root.currentHex + "  " + root.brightnessPercent + "%").toUpperCase())
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }

          PanelActionButton {
            id: closeButton
            anchors.right: parent.right
            anchors.top: parent.top
            iconText: "󰅖"
            tooltipText: "Close"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onClicked: root.close()
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "COLOUR"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }

          Grid {
            id: swatchGrid
            width: parent.width
            columns: 5
            columnSpacing: Style.space(8)
            rowSpacing: Style.space(8)

            Repeater {
              model: root.swatches

              CursorSurface {
                width: (swatchGrid.width - swatchGrid.columnSpacing * 4) / 5
                height: Style.space(36)
                hasCursor: root.cursorActive && root.focusSection === "colors" && root.selectedIndex === index
                foreground: root.bar.foreground
                outline: true

                Rectangle {
                  id: swatchFill
                  anchors.fill: parent
                  anchors.margins: Style.space(6)
                  radius: Style.space(6)
                  readonly property bool active: Model.swatchActive(modelData, {
                    r: root.red, g: root.green, b: root.blue, brightness: root.brightnessPercent, mode: root.cycling ? "cycle" : "static"
                  }, root.cycling)
                  color: modelData.id === "off" ? "#111111" : Qt.rgba(modelData.r / 255, modelData.g / 255, modelData.b / 255, 1)
                  border.width: active ? 3 : 1
                  border.color: active ? root.bar.foreground : Qt.darker(root.bar.foreground, 1.8)

                  Text {
                    visible: modelData.id === "off" && !swatchFill.active
                    anchors.centerIn: parent
                    text: "✕"
                    color: root.bar.foreground
                    font.pixelSize: Style.font.caption
                    font.bold: true
                  }

                  Text {
                    visible: swatchFill.active
                    anchors.centerIn: parent
                    text: "✓"
                    color: (modelData.id === "off" || !Model.isLight(modelData.r, modelData.g, modelData.b)) ? "#ffffff" : "#111111"
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }
                }

                HoverHandler {
                  onHoveredChanged: if (hovered) {
                    root.cursorActive = true
                    root.focusSection = "colors"
                    root.selectedIndex = index
                  }
                }

                TapHandler {
                  onTapped: root.setSwatch(modelData)
                }
              }
            }
          }

          Button {
            width: parent.width
            text: root.cycling ? "Cycle  ✓" : "Cycle"
            tooltipText: "Rainbow cycle on the whole keyboard"
            bordered: true
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onClicked: {
              if (root.cycling)
                root.applyCommand(Model.hex(root.red, root.green, root.blue), Math.max(root.brightnessPercent, 1))
              else
                root.startCycle()
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Column {
          width: parent.width
          spacing: Style.space(6)

          Item {
            width: parent.width
            implicitHeight: Math.max(brightnessHeader.implicitHeight, brightnessLabel.implicitHeight)

            PanelSectionHeader {
              id: brightnessHeader
              text: "BRIGHTNESS"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              id: brightnessLabel
              textFormat: Text.PlainText
              text: Math.round(brightnessSlider.dragging ? brightnessSlider.liveValue : root.brightnessPercent) + "%"
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              anchors.right: parent.right
              anchors.rightMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          CursorSurface {
            width: parent.width
            height: brightnessSlider.implicitHeight + Style.spacing.controlGap
            hasCursor: root.cursorActive && root.focusSection === "brightness"
            foreground: root.bar.foreground
            outline: true

            PanelSlider {
              id: brightnessSlider
              bar: root.bar
              anchors.fill: parent
              anchors.leftMargin: Style.space(6)
              anchors.rightMargin: Style.space(6)
              minimum: 0
              maximum: 100
              step: 1
              value: root.brightnessPercent
              integer: true
              onMoved: function(v) { root.previewBrightness(v) }
              onReleased: function(v) {
                brightnessDebounce.stop()
                root.setBrightness(v)
              }
            }

            HoverHandler {
              onHoveredChanged: if (hovered) {
                root.cursorActive = true
                root.focusSection = "brightness"
                root.selectedIndex = -1
              }
            }
          }
        }

        PanelSeparator { foreground: root.bar.foreground }

        Button {
          width: parent.width
          text: "Close plugin"
          tooltipText: "Remove from the bar"
          bordered: true
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          onClicked: {
            root.close()
            disableProc.running = true
          }
        }
      }
    }
  }
}
