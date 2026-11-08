/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Menus
import VLC.Style
import VLC.Util
import VLC.Widgets as Widgets

// VLC's Open Media window (File, Disc, Network, Capture Device) in the
// style of the settings window: the tabs on the left with the Figma "Open"
// menu icons, the options as setting rows on the right. Same options, MRLs
// and buttons as the classic dialog (dialogs/open): "Show more options",
// Play with Enqueue / Stream / Convert. The window fits its content.
Window {
    id: root

    transientParent: MainCtx.intfMainWindow
    flags: Qt.Dialog | Qt.FramelessWindowHint
    modality: Qt.WindowModal

    title: qsTr("Open Media")

    // fixed size: what the page needs; never taller than the screen (the
    // page scrolls then)
    readonly property real _fitWidth: VLCStyle.dp(900, VLCStyle.scale)
    readonly property real _contentHeight: titleBar.height
            + Math.max(sidebarColumn.implicitHeight + 2 * VLCStyle.margin_xsmall,
                       pageColumn.implicitHeight + 2 * root._pageMargin)
            + footer.height + morePanel.height
    readonly property real _fitHeight: Screen.desktopAvailableHeight > 0
            ? Math.min(_contentHeight, Screen.desktopAvailableHeight - VLCStyle.dp(40, VLCStyle.scale))
            : _contentHeight
    width: _fitWidth
    height: _fitHeight
    minimumWidth: _fitWidth
    maximumWidth: _fitWidth
    minimumHeight: _fitHeight
    maximumHeight: _fitHeight

    color: theme.bg.primary

    readonly property var _tabs: ["file", "disc", "network", "capture"]
    property int currentTab: 0
    // opened to add to the queue (playlist "Add"): the main button enqueues
    property bool enqueueMode: false
    // Ctrl+R / Ctrl+S: the main button converts or streams ("convert",
    // "stream"); "select": it gives the media back (VLM Select Input)
    property string streamAction: ""
    signal selected(string mrl, string options)
    property bool moreOptions: false

    readonly property real _pageMargin: VLCStyle.dp(20, VLCStyle.scale)
    readonly property real controlWidth: VLCStyle.dp(320, VLCStyle.scale)

    // colors of the settings window (SettingRow.qml)
    readonly property ColorContext colorContext: ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.View
    }
    readonly property ColorContext windowColorContext: ColorContext {
        id: windowTheme
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }
    readonly property ColorContext selectedColorContext: ColorContext {
        id: selectedTheme
        palette: VLCStyle.palette
        colorSet: ColorContext.TabButton
        focused: true
    }
    readonly property ColorContext itemColorContext: ColorContext {
        id: itemTheme
        palette: VLCStyle.palette
        colorSet: ColorContext.Item
    }
    readonly property color _well: windowTheme.bg.secondary
    readonly property color _surface: windowTheme.bg.primary
    readonly property color _selected: itemTheme.bg.highlight
    readonly property color _text: theme.fg.secondary
    readonly property color _mutedText: Qt.alpha(theme.fg.secondary, 0.7)
    readonly property real _radius: VLCStyle.dp(6, VLCStyle.scale)

    // ---- opening ------------------------------------------------------------

    // DialogsProvider: { tab: "file" | "disc" | "network" | "capture", enqueue: bool }
    function reset(args) {
        const tab = _tabs.indexOf(args?.tab ?? "file")
        currentTab = tab >= 0 ? tab : 0
        enqueueMode = args?.enqueue ?? false
        streamAction = args?.action ?? ""
        const more = VLCConfig.uiValue("OpenDialog/advanced", false)
        moreOptions = more === true || more === "true"

        files = []
        subtitleSwitch.checked = false
        subtitleField.text = ""
        discDevices = VLCOpenMedia.discDevices()
        _setDiscType(discType)
        titleField.text = ""
        chapterField.text = ""
        audioTrackField.text = ""
        subTrackField.text = ""
        netHistory = _loadHistory()
        urlField.text = ""
        startField.text = ""
        stopField.text = ""
        slaveSwitch.checked = false
        slaveField.text = ""
        extraField.text = ""
        advancedShown = false
        advancedValues = {}
        _resetCaching()
        _refreshCapture()
    }

    function open() {
        const parentWindow = transientParent
        if (parentWindow) {
            x = parentWindow.x + (parentWindow.width - width) / 2
            y = parentWindow.y + Math.max(0, (parentWindow.height - height) / 2)
        }
        show()
        raise()
        requestActivate()
        if (currentTab === 2)
            urlField.forceActiveFocus()
    }

    onCurrentTabChanged: {
        _resetCaching()
        if (currentTab === 1)
            discDevices = VLCOpenMedia.discDevices()
        if (currentTab === 2)
            urlField.forceActiveFocus()
    }

    onMoreOptionsChanged: VLCConfig.setUiValue("OpenDialog/advanced", moreOptions)

    Component.onCompleted: {
        if (MainCtx.createWindowWithoutRedirectionSurface) // Win32
            MainCtx.createWindowWithoutRedirectionSurface(this)
    }

    Shortcut {
        sequence: StandardKey.Cancel
        onActivated: root.close()
    }

    // ---- result: MRLs and options --------------------------------------------

    function _escape(s) {
        return String(s).replace(/:/g, "\\:")
    }

    // "1:02:03.5", "2:03" or "45" -> seconds, -1 when invalid or empty
    function _seconds(text) {
        const t = text.trim()
        if (t === "")
            return -1
        const parts = t.split(":")
        if (parts.length > 3)
            return -1
        let total = 0
        for (const part of parts) {
            const v = Number(part)
            if (part === "" || isNaN(v) || v < 0)
                return -1
            total = total * 60 + v
        }
        return total
    }

    readonly property string cachingMethod: ["file-caching", "disc-caching", "network-caching", "live-caching"][currentTab]

    function _resetCaching() {
        cachingField.text = String(VLCConfig.value(cachingMethod) ?? "")
    }

    function _build() {
        let mrls = []
        let options = []

        switch (currentTab) {
        case 0:
            mrls = files.slice()
            if (subtitleSwitch.checked && subtitleField.text.trim() !== "")
                options.push(":sub-file=" + _escape(subtitleField.text.trim()))
            break
        case 1: {
            const d = _discMrl()
            if (d.mrl !== "")
                mrls = [d.mrl]
            options = d.options
            break
        }
        case 2: {
            const url = VLCOpenMedia.fixupUrl(urlField.text.trim())
            if (url !== "")
                mrls = [url]
            break
        }
        case 3: {
            const c = _captureMrl()
            mrls = c.mrls
            options = c.options
            break
        }
        }

        if (moreOptions) {
            if (slaveSwitch.checked && slaveField.text.trim() !== "")
                options.push(":input-slave=" + slaveField.text.trim())
            const caching = parseInt(cachingField.text)
            if (!isNaN(caching) && caching >= 0 && String(caching) !== String(VLCConfig.value(cachingMethod)))
                options.push(":" + cachingMethod + "=" + caching)
            const start = _seconds(startField.text)
            const stop = _seconds(stopField.text)
            if (start > 0)
                options.push(":start-time=" + start.toFixed(3))
            if (stop > 0 && stop > Math.max(start, 0))
                options.push(":stop-time=" + stop.toFixed(3))
            // as typed, separated by " :" like the classic "Edit Options"
            const extra = extraField.text.trim()
            if (extra !== "")
                for (const o of (" " + extra).split(" :"))
                    if (o.trim() !== "")
                        options.push(":" + o.trim().replace(/^:/, ""))
        }
        return { "mrls": mrls, "options": options }
    }

    // follows every value _build() reads
    readonly property var result: _build()
    readonly property bool canOpen: result.mrls.length > 0

    function _open(play) {
        if (!canOpen)
            return
        if (currentTab === 2)
            _remember(urlField.text.trim())
        VLCOpenMedia.open(result.mrls, result.options, play)
        close()
    }

    // the main button (and Enter in the URL field)
    function _main() {
        if (streamAction === "select") {
            if (!canOpen)
                return
            // as OpenDialog::getMRL(false) and getOptions(): " :opt1 :opt2"
            const options = result.options.map((o) => (String(o).startsWith(":") ? "" : ":") + o)
            selected(result.mrls[0], options.length > 0 ? " " + options.join(" ") : "")
            close()
        } else if (streamAction !== "")
            _stream(streamAction === "convert")
        else
            _open(!enqueueMode)
    }

    function _stream(convert) {
        if (!canOpen)
            return
        const r = result
        close()
        // the classic wizards wait for their answer: after this window is gone
        Qt.callLater(() => VLCOpenMedia.stream(r.mrls, r.options, convert))
    }

    // ---- File -------------------------------------------------------------------

    property var files: []

    function _addFiles(list) {
        const merged = files.slice()
        for (const url of list) {
            const s = url.toString()
            if (merged.indexOf(s) < 0)
                merged.push(s)
        }
        files = merged
    }

    // ---- Disc -------------------------------------------------------------------

    readonly property var _discTypes: [
        { "value": "dvd", "text": qsTr("DVD") },
        { "value": "bluray", "text": qsTr("Blu-ray") },
        { "value": "cdda", "text": qsTr("Audio CD") },
        { "value": "vcd", "text": qsTr("SVCD/VCD") },
        { "value": "dvda", "text": qsTr("DVD-Audio") }
    ]
    property string discType: "dvd"
    property var discDevices: []

    function _setDiscType(type) {
        discType = type
        // the drive of the preferences for this kind of disc, as the classic dialog
        const option = (type === "vcd") ? "vcd" : (type === "cdda") ? "cd-audio" : "dvd"
        const configured = VLCConfig.exists(option) ? String(VLCConfig.value(option) ?? "") : ""
        let device = configured
        for (const d of discDevices) {
            if (configured !== "" && d.value.startsWith(configured)) {
                device = d.text
                break
            }
        }
        if (device === "" && discDevices.length > 0)
            device = discDevices[0].text
        deviceField.text = device
        if (type === "bluray")
            noMenusSwitch.checked = !VLCConfig.value("bluray-menu")
    }

    function _discDevicePath() {
        const text = deviceField.text.trim()
        for (const d of discDevices)
            if (d.text === text)
                return d.value
        return text
    }

    function _discMrl() {
        const type = discType
        const scheme = (type === "dvd" && noMenusSwitch.checked) ? "dvdsimple" : type
        const mrl = VLCOpenMedia.discMrl(_discDevicePath(), scheme)
        if (mrl === "")
            return { "mrl": "", "options": [] }

        const title = parseInt(titleField.text)
        const chapter = parseInt(chapterField.text)
        let anchor = ""
        if (title > 0) {
            if (type === "dvd" || type === "bluray" || type === "dvda") {
                anchor = "#" + title
                if (chapter > 0 && type !== "bluray")
                    anchor += ":" + chapter
            } else if (type === "vcd") {
                anchor = "#" + title
            }
        }

        const options = []
        if (type === "dvd" || type === "vcd") {
            const audio = parseInt(audioTrackField.text)
            const sub = parseInt(subTrackField.text)
            if (audio >= 0)
                options.push(":audio-track=" + audio)
            if (sub >= 0)
                options.push(":sub-track=" + sub)
        } else if (type === "cdda") {
            if (title > 0)
                options.push(":cdda-track=" + title)
        } else if (type === "bluray") {
            if (noMenusSwitch.checked)
                options.push(":no-bluray-menu")
        }
        return { "mrl": mrl + anchor, "options": options }
    }

    // ---- Network -----------------------------------------------------------------

    property var netHistory: []
    readonly property bool _keepHistory: !!VLCConfig.value("save-recentplay")

    function _loadHistory() {
        if (!_keepHistory)
            return []
        const v = VLCConfig.uiValue("OpenDialog/netMRL", [])
        return Array.isArray(v) ? v : (v ? [String(v)] : [])
    }

    // the last 10 URLs, as the classic dialog
    function _remember(url) {
        if (!_keepHistory || url === "")
            return
        const list = netHistory.filter((u) => u !== url)
        list.unshift(url)
        netHistory = list.slice(0, 10)
        VLCConfig.setUiValue("OpenDialog/netMRL", netHistory)
    }

    // ---- Capture -----------------------------------------------------------------

    readonly property bool _windows: MainCtx.osName === MainCtx.Windows

    readonly property var captureModes: {
        const modes = []
        if (_windows) {
            if (VLCConfig.moduleExists("dshow"))
                modes.push({ "value": "dshow", "text": "DirectShow" })
        } else {
            if (VLCConfig.moduleExists("v4l2"))
                modes.push({ "value": "v4l2", "text": qsTr("Video camera") })
            if (VLCConfig.moduleExists("jack"))
                modes.push({ "value": "jack", "text": qsTr("JACK Audio Connection Kit") })
        }
        if (VLCConfig.moduleExists("dtv"))
            modes.push({ "value": "dtv", "text": qsTr("TV - digital") })
        if (!_windows && VLCConfig.moduleExists("v4l2"))
            modes.push({ "value": "pvr", "text": qsTr("TV - analog") })
        modes.push({ "value": "screen", "text": qsTr("Desktop") })
        return modes
    }
    property string captureMode: captureModes.length > 0 ? captureModes[0].value : "screen"
    onCaptureModeChanged: {
        advancedValues = {}
        advancedList = []
        if (advancedShown)
            _loadAdvanced()
    }
    onAdvancedShownChanged: if (advancedShown && advancedList.length === 0) _loadAdvanced()

    // module of the "Advanced options" of each mode, and the options already
    // in the window (left out there), as the classic dialog
    readonly property var _captureModules: ({ "dshow": "dshow", "v4l2": "v4l2", "pvr": "v4l2", "dtv": "dtv", "jack": "jack" })
    readonly property var _captureOptionsShown: [
        "dshow-vdev", "dshow-adev", "dshow-size", "v4l2-standard",
        "jack-input-use-vlc-pace", "jack-input-auto-connect",
        "dvb-adapter", "dvb-frequency", "dvb-modulation", "dvb-bandwidth"
    ]
    // "Advanced options": the other options of the capture module, as the
    // classic dialog; only the changed ones go into the options
    property bool advancedShown: false
    property var advancedList: []       // { name, type, text, choices, value }
    property var advancedValues: ({})   // name -> changed value

    function _loadAdvanced() {
        const module = _captureModules[captureMode]
        const rows = []
        const sections = module ? (VLCConfig.moduleSettings(module).sections ?? []) : []
        for (const section of sections) {
            for (const name of section.options) {
                if (name.startsWith("#") || _captureOptionsShown.includes(name))
                    continue
                const type = VLCConfig.type(name)
                if (type === "" || type === "key")
                    continue
                rows.push({ "name": name, "type": type, "text": VLCConfig.text(name),
                            "choices": VLCConfig.choices(name), "value": VLCConfig.value(name) })
            }
        }
        advancedList = rows
    }

    function _setAdvanced(name, value) {
        const values = Object.assign({}, advancedValues)
        values[name] = value
        advancedValues = values
    }

    readonly property var advancedOptions: {
        const options = []
        if (!advancedShown)
            return options
        for (const row of advancedList) {
            const v = advancedValues[row.name]
            if (v === undefined || String(v) === String(row.value))
                continue
            if (row.type === "bool")
                options.push(v ? ":" + row.name : ":no-" + row.name)
            else
                options.push(":" + row.name + "=" + _escape(v))
        }
        return options
    }

    property var dshowVideoDevices: []
    property var dshowAudioDevices: []
    property var dshowVideo: ""
    property var dshowAudio: ""
    property var videoStandards: []
    property var videoStandard: ""
    property string dvbSystem: "dvb-t"
    property var dvbBandwidths: []
    property var dvbBandwidth: 0
    property string dvbQam: "QAM"
    property string dvbPsk: "QPSK"
    property var videoDevices: []
    property var alsaDevices: []

    readonly property var _dvbSystems: [
        { "value": "dvb-c", "text": "DVB-C" }, { "value": "dvb-s", "text": "DVB-S" },
        { "value": "dvb-s2", "text": "DVB-S2" }, { "value": "dvb-t", "text": "DVB-T" },
        { "value": "dvb-t2", "text": "DVB-T2" }, { "value": "atsc", "text": "ATSC" },
        { "value": "cqam", "text": qsTr("Clear QAM") }
    ]
    readonly property var _qamModes: [
        { "value": "QAM", "text": qsTr("Automatic") }, { "value": "256QAM", "text": "256-QAM" },
        { "value": "128QAM", "text": "128-QAM" }, { "value": "64QAM", "text": "64-QAM" },
        { "value": "32QAM", "text": "32-QAM" }, { "value": "16QAM", "text": "16-QAM" }
    ]
    readonly property var _pskModes: [
        { "value": "QPSK", "text": "QPSK" }, { "value": "DQPSK", "text": "DQPSK" },
        { "value": "8PSK", "text": "8-PSK" }, { "value": "16APSK", "text": "16-APSK" },
        { "value": "32APSK", "text": "32-APSK" }
    ]

    function _refreshCapture() {
        if (_windows && VLCConfig.exists("dshow-vdev")) {
            dshowVideoDevices = VLCConfig.choices("dshow-vdev")
            dshowAudioDevices = VLCConfig.choices("dshow-adev")
            dshowVideo = String(VLCConfig.value("dshow-vdev") ?? "")
            dshowAudio = String(VLCConfig.value("dshow-adev") ?? "")
        }
        if (VLCConfig.exists("v4l2-standard")) {
            videoStandards = VLCConfig.choices("v4l2-standard")
            videoStandard = VLCConfig.value("v4l2-standard") ?? ""
        }
        if (VLCConfig.exists("dvb-bandwidth")) {
            dvbBandwidths = VLCConfig.choices("dvb-bandwidth")
            dvbBandwidth = VLCConfig.value("dvb-bandwidth") ?? 0
        }
        if (screenFpsField.text === "")
            screenFpsField.text = VLCConfig.exists("screen-fps") ? String(VLCConfig.value("screen-fps")) : "1"
        videoDevices = VLCOpenMedia.videoDevices()
        alsaDevices = VLCOpenMedia.alsaDevices()
        if (videoDeviceField.text === "" && videoDevices.length > 0)
            videoDeviceField.text = videoDevices[0]
        if (pvrDeviceField.text === "" && videoDevices.length > 0)
            pvrDeviceField.text = videoDevices[0]
    }

    function _captureMrl() {
        const mrls = []
        const options = []
        switch (captureMode) {
        case "dshow":
            mrls.push("dshow://")
            options.push(":dshow-vdev=" + _escape(dshowVideo))
            options.push(":dshow-adev=" + _escape(dshowAudio))
            if (dshowSizeField.text.trim() !== "")
                options.push(":dshow-size=" + dshowSizeField.text.trim())
            break
        case "v4l2":
            mrls.push("v4l2://" + videoDeviceField.text.trim())
            if (String(videoStandard) !== "")
                options.push(":v4l2-standard=" + videoStandard)
            if (audioDeviceField.text.trim() !== "")
                options.push(":input-slave=alsa://" + audioDeviceField.text.trim())
            break
        case "jack":
            mrls.push("jack://channels=" + (parseInt(jackChannelsField.text) || 2)
                      + ":ports=" + (jackPortsField.text || ".*"))
            if (jackPaceSwitch.checked)
                options.push(":jack-input-use-vlc-pace")
            if (jackConnectSwitch.checked)
                options.push(":jack-input-auto-connect")
            break
        case "pvr": {
            mrls.push("v4l2://" + pvrDeviceField.text.trim())
            if (String(videoStandard) !== "")
                options.push(":v4l2-standard=" + videoStandard)
            const freq = parseInt(pvrFreqField.text)
            if (freq > 0)
                options.push(":v4l2-tuner-frequency=" + freq)
            if (pvrAudioField.text.trim() !== "")
                options.push(":input-slave=alsa://" + pvrAudioField.text.trim())
            break
        }
        case "dtv": {
            const sys = dvbSystem
            let mrl = sys + "://frequency=" + (parseInt(dvbFreqField.text) || 0) + "000"
            if (sys === "dvb-c" || sys === "cqam")
                mrl += ":modulation=" + dvbQam
            if (sys === "dvb-s2")
                mrl += ":modulation=" + dvbPsk
            if (sys === "dvb-c" || sys === "dvb-s" || sys === "dvb-s2")
                mrl += ":srate=" + (parseInt(dvbSrateField.text) || 0)
            if (sys === "dvb-t" || sys === "dvb-t2")
                mrl += ":bandwidth=" + dvbBandwidth
            mrls.push(mrl)
            options.push(":dvb-adapter=" + (parseInt(dvbCardField.text) || 0))
            break
        }
        case "screen": {
            mrls.push("screen://")
            const fps = parseFloat(screenFpsField.text)
            if (fps > 0)
                options.push(":screen-fps=" + fps)
            break
        }
        }
        for (const o of advancedOptions)
            options.push(o)
        return { "mrls": mrls, "options": options }
    }

    // ---- title bar (as the settings window) ---------------------------------------

    Rectangle {
        id: titleBar

        readonly property ColorContext colorContext: ColorContext {
            id: titleTheme
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: VLCStyle.globalToolbar_height
        color: titleTheme.bg.primary

        DragHandler {
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onActiveChanged: if (active) root.startSystemMove()
        }

        Text {
            anchors.centerIn: parent
            text: root.title
            color: titleTheme.fg.secondary
            font.pixelSize: VLCStyle.fontSize_large
        }

        Widgets.CSDWindowButton {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            iconTxt: ((MainCtx.osName === MainCtx.Windows) && (MainCtx.osVersion >= 10)) ? "" : VLCIcons.window_close
            isThemeDark: titleTheme.palette.isDark
            color: hovered ? "white" : titleTheme.fg.primary
            hoverColor: "red"
            onClicked: root.close()
        }
    }

    // ---- tabs on the left (as the settings categories) -----------------------------

    Rectangle {
        id: sidebar

        anchors { top: titleBar.bottom; left: parent.left; bottom: footer.top }
        width: VLCStyle.dp(236, VLCStyle.scale)
        color: theme.bg.primary

        Rectangle {
            anchors.fill: parent
            anchors.margins: VLCStyle.margin_xsmall
            radius: root._radius
            color: windowTheme.bg.primary

            ColumnLayout {
                id: sidebarColumn

                anchors { left: parent.left; right: parent.right; top: parent.top; margins: VLCStyle.dp(6, VLCStyle.scale) }
                spacing: VLCStyle.margin_xsmall

                Repeater {
                    model: [
                        { "text": qsTr("File"), "icon": "main_open_file_s" },
                        { "text": qsTr("Disc"), "icon": "main_open_disc" },
                        { "text": qsTr("Network"), "icon": "main_open_network_stream" },
                        { "text": qsTr("Capture Device"), "icon": "main_open_capture_device" }
                    ]

                    T.AbstractButton {
                        id: tabButton

                        required property var modelData
                        required property int index
                        readonly property bool selected: root.currentTab === index

                        Layout.fillWidth: true
                        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)

                        onClicked: root.currentTab = index

                        Accessible.role: Accessible.PageTab
                        Accessible.name: modelData.text

                        background: Rectangle {
                            radius: VLCStyle.dp(2, VLCStyle.scale)
                            color: (tabButton.selected || tabButton.hovered) ? selectedTheme.bg.primary : "transparent"
                            border.width: tabButton.visualFocus ? VLCStyle.focus_border : 0
                            border.color: theme.visualFocus
                        }

                        contentItem: RowLayout {
                            spacing: VLCStyle.margin_xsmall

                            Item {
                                Layout.preferredWidth: VLCStyle.dp(32, VLCStyle.scale)
                                Layout.leftMargin: VLCStyle.dp(4, VLCStyle.scale)
                                Layout.fillHeight: true

                                // Figma menu icon: its details in the accent when selected
                                Image {
                                    anchors.centerIn: parent
                                    width: VLCStyle.icon_normal
                                    height: VLCStyle.icon_normal
                                    sourceSize: Qt.size(width * 2, height * 2)
                                    source: SVGColorImage.colorize("qrc:///menu/figma/" + tabButton.modelData.icon + ".svg")
                                                .any({
                                                    "#8F8F8F": tabButton.selected ? theme.fg.primary : theme.fg.secondary,
                                                    "#AB6314": tabButton.selected ? theme.accent : theme.fg.secondary
                                                }).uri()
                                }
                            }

                            T.Label {
                                Layout.fillWidth: true
                                text: tabButton.modelData.text
                                elide: Text.ElideRight
                                font.pixelSize: VLCStyle.fontSize_large
                                color: tabButton.selected ? theme.fg.primary : theme.fg.secondary
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- pages ---------------------------------------------------------------------------

    Flickable {
        id: pane

        anchors { top: titleBar.bottom; left: sidebar.right; right: parent.right; bottom: footer.top }
        contentHeight: pageColumn.implicitHeight + 2 * root._pageMargin
        interactive: contentHeight > height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        T.ScrollBar.vertical: ScrollBar { visible: pane.interactive }

        ColumnLayout {
            id: pageColumn

            x: VLCStyle.margin_large
            y: root._pageMargin
            width: pane.width - 2 * VLCStyle.margin_large
            spacing: 0

            StackLayout {
                Layout.fillWidth: true
                currentIndex: root.currentTab
                // only the shown page counts (the window fits it)
                Layout.preferredHeight: [filePage, discPage, networkPage, capturePage][currentIndex].implicitHeight

                // File
                Page {
                    id: filePage

                    SectionTitle { text: qsTr("File Selection") }

                    T.Label {
                        Layout.fillWidth: true
                        Layout.bottomMargin: VLCStyle.margin_small
                        text: qsTr("You can select local files with the following list and buttons.")
                        wrapMode: Text.WordWrap
                        color: root._mutedText
                        font.pixelSize: VLCStyle.fontSize_normal
                    }

                    // the files; drop files here too
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: VLCStyle.dp(176, VLCStyle.scale)
                        radius: root._radius
                        color: dropArea.containsDrag ? Qt.lighter(root._well, 1.3) : root._well
                        border.width: VLCStyle.dp(2, VLCStyle.scale)
                        border.color: root._surface

                        DropArea {
                            id: dropArea
                            anchors.fill: parent
                            onDropped: (drop) => {
                                if (drop.hasUrls)
                                    root._addFiles(drop.urls)
                            }
                        }

                        T.Label {
                            anchors.centerIn: parent
                            visible: root.files.length === 0
                            text: qsTr("Drag files here or click \"Add...\".")
                            color: root._mutedText
                            font.pixelSize: VLCStyle.fontSize_large
                        }

                        ListView {
                            id: fileList

                            anchors.fill: parent
                            anchors.margins: VLCStyle.dp(6, VLCStyle.scale)
                            clip: true
                            model: root.files
                            spacing: VLCStyle.dp(2, VLCStyle.scale)
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: ListView.view.width
                                height: VLCStyle.dp(34, VLCStyle.scale)
                                radius: VLCStyle.dp(4, VLCStyle.scale)
                                color: rowHover.hovered ? root._surface : "transparent"

                                HoverHandler { id: rowHover }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: VLCStyle.dp(10, VLCStyle.scale)
                                    anchors.rightMargin: VLCStyle.dp(4, VLCStyle.scale)
                                    spacing: VLCStyle.margin_xsmall

                                    T.Label {
                                        Layout.fillWidth: true
                                        text: VLCOpenMedia.displayPath(modelData)
                                        color: root._text
                                        font.pixelSize: VLCStyle.fontSize_normal
                                        elide: Text.ElideMiddle
                                    }

                                    SettingButton {
                                        implicitHeight: VLCStyle.dp(26, VLCStyle.scale)
                                        implicitWidth: VLCStyle.dp(80, VLCStyle.scale)
                                        text: qsTr("Remove")
                                        onClicked: {
                                            const list = root.files.slice()
                                            list.splice(index, 1)
                                            root.files = list
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: VLCStyle.margin_small
                        spacing: VLCStyle.margin_xsmall

                        Item { Layout.fillWidth: true }

                        SettingButton {
                            text: qsTr("Add...")
                            onClicked: root._addFiles(VLCConfig.browseFiles(qsTr("Select one or multiple files")))
                        }
                    }

                    SectionTitle { text: qsTr("Subtitles") }

                    Row2 {
                        label: qsTr("Use a subtitle file")
                        enabled: root.files.length > 0
                        Toggle { id: subtitleSwitch }
                    }

                    Row2 {
                        label: qsTr("Subtitle file")
                        enabled: root.files.length > 0 && subtitleSwitch.checked
                        PathField {
                            id: subtitleField
                            title: qsTr("Open subtitle file")
                        }
                    }
                }

                // Disc
                Page {
                    id: discPage

                    SectionTitle { text: qsTr("Disc Selection") }

                    Row2 {
                        label: qsTr("Disc type")
                        Dropdown {
                            model: root._discTypes
                            value: root.discType
                            onPicked: (v) => root._setDiscType(v)
                        }
                    }

                    Row2 {
                        label: qsTr("No disc menus")
                        enabled: root.discType === "dvd" || root.discType === "bluray"
                        Toggle { id: noMenusSwitch }
                    }

                    Row2 {
                        label: qsTr("Disc device")
                        EditCombo {
                            id: deviceField
                            Layout.preferredWidth: root.controlWidth - 2 * (VLCStyle.dp(80, VLCStyle.scale) + VLCStyle.margin_xsmall)
                            suggestions: root.discDevices.map((d) => d.text)
                            ToolTipArea { text: qsTr("Select a device or a VIDEO_TS directory") }
                        }
                        SettingButton {
                            implicitWidth: VLCStyle.dp(80, VLCStyle.scale)
                            text: qsTr("Browse")
                            onClicked: {
                                const url = VLCConfig.browseFolder(qsTr("Select a device or a VIDEO_TS directory"))
                                if (url !== "")
                                    deviceField.text = VLCOpenMedia.displayPath(url)
                            }
                        }
                        SettingButton {
                            implicitWidth: VLCStyle.dp(80, VLCStyle.scale)
                            text: qsTr("Eject")
                            onClicked: VLCOpenMedia.eject(root._discDevicePath())
                        }
                    }

                    SectionTitle { text: qsTr("Starting Position") }

                    Row2 {
                        label: root.discType === "cdda" ? qsTr("Track")
                             : root.discType === "vcd" ? qsTr("Entry") : qsTr("Title")
                        NumberField { id: titleField }
                    }

                    Row2 {
                        label: qsTr("Chapter")
                        enabled: root.discType === "dvd" || root.discType === "dvda"
                        NumberField { id: chapterField }
                    }

                    SectionTitle { text: qsTr("Audio and Subtitles") }

                    Row2 {
                        label: qsTr("Audio track")
                        enabled: root.discType === "dvd" || root.discType === "vcd"
                        NumberField { id: audioTrackField }
                    }

                    Row2 {
                        label: qsTr("Subtitle track")
                        enabled: root.discType === "dvd" || root.discType === "vcd"
                        NumberField { id: subTrackField }
                    }
                }

                // Network
                Page {
                    id: networkPage

                    SectionTitle { text: qsTr("Network Protocol") }

                    Row2 {
                        label: qsTr("Network URL")
                        EditCombo {
                            id: urlField
                            Layout.preferredWidth: root.controlWidth + VLCStyle.dp(140, VLCStyle.scale)
                            suggestions: root.netHistory
                            placeholderText: "https://www.example.com/stream.avi"
                            onAccepted: root._main()
                        }
                    }

                    T.Label {
                        Layout.fillWidth: true
                        Layout.topMargin: VLCStyle.margin_xsmall
                        Layout.bottomMargin: VLCStyle.margin_small
                        wrapMode: Text.WordWrap
                        lineHeight: 1.3
                        color: root._mutedText
                        font.pixelSize: VLCStyle.fontSize_normal
                        text: "http://www.example.com/stream.avi\nrtp://@:1234\nmms://mms.examples.com/stream.asx\n"
                            + "rtsp://server.example.org:8080/test.sdp\nhttp://www.yourtube.com/watch?v=gg64x"
                    }

                    Row2 {
                        label: qsTr("Clear the network URL browsing history")
                        enabled: root._keepHistory && root.netHistory.length > 0
                        SettingButton {
                            text: qsTr("Clear History")
                            implicitWidth: VLCStyle.dp(120, VLCStyle.scale)
                            onClicked: {
                                root.netHistory = []
                                VLCConfig.setUiValue("OpenDialog/netMRL", [])
                            }
                        }
                    }
                }

                // Capture Device
                Page {
                    id: capturePage

                    SectionTitle { text: qsTr("Capture Mode") }

                    Row2 {
                        label: qsTr("Capture mode")
                        Dropdown {
                            model: root.captureModes
                            value: root.captureMode
                            onPicked: (v) => root.captureMode = v
                        }
                    }

                    SectionTitle { text: qsTr("Device Selection") }

                    // DirectShow (Windows)
                    Row2 {
                        visible: root.captureMode === "dshow"
                        label: qsTr("Video device name")
                        Dropdown {
                            model: root.dshowVideoDevices
                            value: root.dshowVideo
                            onPicked: (v) => root.dshowVideo = v
                        }
                    }
                    Row2 {
                        visible: root.captureMode === "dshow"
                        label: qsTr("Audio device name")
                        Dropdown {
                            model: root.dshowAudioDevices
                            value: root.dshowAudio
                            onPicked: (v) => root.dshowAudio = v
                        }
                    }

                    // Video camera
                    Row2 {
                        visible: root.captureMode === "v4l2"
                        label: qsTr("Video device name")
                        EditCombo { id: videoDeviceField; suggestions: root.videoDevices }
                    }
                    Row2 {
                        visible: root.captureMode === "v4l2"
                        label: qsTr("Audio device name")
                        EditCombo { id: audioDeviceField; suggestions: root.alsaDevices }
                    }

                    // JACK
                    Row2 {
                        visible: root.captureMode === "jack"
                        label: qsTr("Selected ports")
                        InputField { id: jackPortsField; implicitWidth: root.controlWidth; text: ".*" }
                    }
                    Row2 {
                        visible: root.captureMode === "jack"
                        label: qsTr("Channels")
                        NumberField { id: jackChannelsField; text: "2" }
                    }

                    // TV - analog
                    Row2 {
                        visible: root.captureMode === "pvr"
                        label: qsTr("Device name")
                        EditCombo { id: pvrDeviceField; suggestions: root.videoDevices }
                    }
                    Row2 {
                        visible: root.captureMode === "pvr"
                        label: qsTr("Audio device name")
                        EditCombo { id: pvrAudioField; suggestions: root.alsaDevices }
                    }

                    // TV - digital
                    Row2 {
                        visible: root.captureMode === "dtv"
                        label: qsTr("Tuner card")
                        T.Label {
                            visible: !root._windows
                            text: "/dev/dvb/adapter"
                            color: root._mutedText
                            font.pixelSize: VLCStyle.fontSize_large
                        }
                        NumberField { id: dvbCardField; text: "0" }
                    }
                    Row2 {
                        visible: root.captureMode === "dtv"
                        label: qsTr("Delivery system")
                        Dropdown {
                            model: root._dvbSystems
                            value: root.dvbSystem
                            onPicked: (v) => root.dvbSystem = v
                        }
                    }

                    // Desktop
                    T.Label {
                        visible: root.captureMode === "screen"
                        Layout.fillWidth: true
                        Layout.topMargin: VLCStyle.margin_xsmall
                        Layout.bottomMargin: VLCStyle.margin_xsmall
                        wrapMode: Text.WordWrap
                        color: root._text
                        font.pixelSize: VLCStyle.fontSize_large
                        text: qsTr("Your display will be opened and played in order to stream or save it.")
                    }

                    SectionTitle { text: qsTr("Options") }

                    Row2 {
                        visible: root.captureMode === "dshow"
                        label: qsTr("Video size")
                        InputField {
                            id: dshowSizeField
                            implicitWidth: root.controlWidth
                            placeholderText: "1280x720"
                        }
                    }
                    Row2 {
                        visible: (root.captureMode === "v4l2" || root.captureMode === "pvr")
                        label: qsTr("Video standard")
                        Dropdown {
                            model: root.videoStandards
                            value: root.videoStandard
                            onPicked: (v) => root.videoStandard = v
                        }
                    }
                    Row2 {
                        visible: root.captureMode === "pvr"
                        label: qsTr("Frequency")
                        NumberField { id: pvrFreqField; unit: qsTr("kHz") }
                    }
                    Row2 {
                        visible: root.captureMode === "jack"
                        label: qsTr("Use VLC pace")
                        Toggle { id: jackPaceSwitch }
                    }
                    Row2 {
                        visible: root.captureMode === "jack"
                        label: qsTr("Auto connection")
                        Toggle { id: jackConnectSwitch }
                    }
                    Row2 {
                        visible: root.captureMode === "dtv"
                        label: qsTr("Transponder/multiplex frequency")
                        NumberField { id: dvbFreqField; unit: qsTr("kHz") }
                    }
                    Row2 {
                        visible: root.captureMode === "dtv"
                                 && (root.dvbSystem === "dvb-c" || root.dvbSystem === "dvb-s" || root.dvbSystem === "dvb-s2")
                        label: qsTr("Transponder symbol rate")
                        NumberField { id: dvbSrateField; unit: qsTr("bauds") }
                    }
                    Row2 {
                        visible: root.captureMode === "dtv"
                                 && (root.dvbSystem === "dvb-c" || root.dvbSystem === "cqam" || root.dvbSystem === "dvb-s2")
                        label: qsTr("Modulation / Constellation")
                        Dropdown {
                            model: root.dvbSystem === "dvb-s2" ? root._pskModes : root._qamModes
                            value: root.dvbSystem === "dvb-s2" ? root.dvbPsk : root.dvbQam
                            onPicked: (v) => {
                                if (root.dvbSystem === "dvb-s2")
                                    root.dvbPsk = v
                                else
                                    root.dvbQam = v
                            }
                        }
                    }
                    Row2 {
                        visible: root.captureMode === "dtv"
                                 && (root.dvbSystem === "dvb-t" || root.dvbSystem === "dvb-t2")
                        label: qsTr("Bandwidth")
                        Dropdown {
                            model: root.dvbBandwidths
                            value: root.dvbBandwidth
                            onPicked: (v) => root.dvbBandwidth = v
                        }
                    }
                    Row2 {
                        visible: root.captureMode === "screen"
                        label: qsTr("Desired frame rate for the capture.")
                        NumberField { id: screenFpsField; unit: qsTr("f/s"); decimals: true }
                    }
                    Row2 {
                        visible: root._captureModules[root.captureMode] !== undefined
                        label: qsTr("Advanced options")
                        Toggle {
                            checkable: false
                            checked: root.advancedShown
                            onClicked: root.advancedShown = !root.advancedShown
                        }
                    }

                    // the module's other options; only this list scrolls
                    Rectangle {
                        visible: root.advancedShown && root._captureModules[root.captureMode] !== undefined
                        Layout.fillWidth: true
                        Layout.topMargin: VLCStyle.margin_xxsmall
                        Layout.bottomMargin: VLCStyle.margin_xsmall
                        Layout.preferredHeight: Math.min(advancedColumn.implicitHeight + 2 * VLCStyle.margin_xsmall,
                                                         VLCStyle.dp(280, VLCStyle.scale))
                        radius: root._radius
                        color: root._well
                        border.width: VLCStyle.dp(2, VLCStyle.scale)
                        border.color: root._surface

                        T.Label {
                            anchors.centerIn: parent
                            visible: root.advancedList.length === 0
                            text: qsTr("This device has no other options.")
                            color: root._mutedText
                            font.pixelSize: VLCStyle.fontSize_large
                        }

                        Flickable {
                            id: advancedFlick

                            anchors.fill: parent
                            anchors.margins: VLCStyle.margin_xsmall
                            clip: true
                            contentHeight: advancedColumn.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            T.ScrollBar.vertical: ScrollBar { }

                            ColumnLayout {
                                id: advancedColumn

                                x: VLCStyle.margin_small
                                width: advancedFlick.width - 2 * VLCStyle.margin_small
                                spacing: 0

                                Repeater {
                                    model: root.advancedList

                                    Row2 {
                                        id: optionRow

                                        required property var modelData
                                        readonly property var value: root.advancedValues[modelData.name] ?? modelData.value

                                        label: modelData.text

                                        Loader {
                                            sourceComponent: optionRow.modelData.type === "bool" ? boolOption
                                                           : optionRow.modelData.choices.length > 0 ? choiceOption
                                                           : textOption
                                        }

                                        Component {
                                            id: boolOption
                                            Toggle {
                                                checkable: false
                                                checked: !!optionRow.value
                                                onClicked: root._setAdvanced(optionRow.modelData.name, !optionRow.value)
                                            }
                                        }
                                        Component {
                                            id: choiceOption
                                            Dropdown {
                                                model: optionRow.modelData.choices
                                                value: optionRow.value
                                                onPicked: (v) => root._setAdvanced(optionRow.modelData.name, v)
                                            }
                                        }
                                        Component {
                                            id: textOption
                                            InputField {
                                                implicitWidth: root.controlWidth
                                                text: String(optionRow.value ?? "")
                                                echoMode: optionRow.modelData.type === "password" ? TextInput.Password : TextInput.Normal
                                                onEditingFinished: {
                                                    const t = optionRow.modelData.type
                                                    root._setAdvanced(optionRow.modelData.name,
                                                                      t === "int" ? (parseInt(text) || 0)
                                                                    : t === "float" ? (parseFloat(text) || 0) : text)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- "Show more options": its own section under the window ---------------------

    Rectangle {
        id: morePanel

        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: root.moreOptions ? moreOptionsColumn.implicitHeight + VLCStyle.margin_small + VLCStyle.margin_large : 0
        visible: root.moreOptions
        color: theme.bg.primary

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: VLCStyle.border
            color: titleTheme.border
        }

        ColumnLayout {
            id: moreOptionsColumn

            x: VLCStyle.margin_large
            y: VLCStyle.margin_small
            width: morePanel.width - 2 * VLCStyle.margin_large
            spacing: 0

            SectionTitle { text: qsTr("More Options") }

            Row2 {
                label: qsTr("Caching")
                NumberField { id: cachingField; unit: qsTr("ms") }
            }

            Row2 {
                label: qsTr("Start time / Stop time")
                InputField {
                    id: startField
                    implicitWidth: VLCStyle.dp(120, VLCStyle.scale)
                    horizontalAlignment: TextInput.AlignRight
                    placeholderText: "00:00:00"
                }
                T.Label {
                    text: "–"
                    color: root._mutedText
                    font.pixelSize: VLCStyle.fontSize_large
                }
                InputField {
                    id: stopField
                    implicitWidth: VLCStyle.dp(120, VLCStyle.scale)
                    horizontalAlignment: TextInput.AlignRight
                    placeholderText: "00:00:00"
                }
            }

            Row2 {
                label: qsTr("Play another media synchronously")
                Toggle { id: slaveSwitch }
            }

            Row2 {
                label: qsTr("Extra media")
                enabled: slaveSwitch.checked
                PathField {
                    id: slaveField
                    title: qsTr("Select the file")
                    urls: true
                }
            }

            Row2 {
                label: qsTr("Edit options")
                InputField {
                    id: extraField
                    implicitWidth: root.controlWidth
                    placeholderText: ":option=value"
                }
            }

            Row2 {
                label: qsTr("MRL")
                T.Label {
                    Layout.preferredWidth: root.controlWidth
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideMiddle
                    color: root._mutedText
                    font.pixelSize: VLCStyle.fontSize_normal
                    text: root.result.mrls.concat(root.result.options).join(" ")

                    ToolTipArea { text: parent.text }
                }
            }
        }
    }

    // ---- buttons -------------------------------------------------------------------

    Rectangle {
        id: footer

        anchors { left: parent.left; right: parent.right; bottom: morePanel.top }
        height: VLCStyle.dp(60, VLCStyle.scale)
        color: windowTheme.bg.secondary

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: VLCStyle.margin_large
            anchors.rightMargin: VLCStyle.margin_large
            spacing: VLCStyle.margin_xsmall

            // shows the "More Options" section under the window
            Toggle {
                checkable: false
                checked: root.moreOptions
                onClicked: root.moreOptions = !root.moreOptions
                Accessible.name: qsTr("Show more options")
            }

            T.Label {
                Layout.leftMargin: VLCStyle.margin_xsmall
                text: qsTr("Show more options")
                color: root._text
                font.pixelSize: VLCStyle.fontSize_large

                TapHandler { onTapped: root.moreOptions = !root.moreOptions }
            }

            Item { Layout.fillWidth: true }

            SettingButton {
                text: qsTr("Cancel")
                onClicked: root.close()
            }

            SettingButton {
                text: root.enqueueMode ? qsTr("Play") : qsTr("Enqueue")
                enabled: root.canOpen
                onClicked: root._open(root.enqueueMode)
            }

            // the main button, and Stream / Convert in its menu
            Row {
                spacing: VLCStyle.dp(2, VLCStyle.scale)

                SettingButton {
                    highlighted: true
                    text: root.streamAction === "select" ? qsTr("Select")
                        : root.streamAction === "convert" ? qsTr("Convert / Save")
                        : root.streamAction === "stream" ? qsTr("Stream")
                        : root.enqueueMode ? qsTr("Enqueue") : qsTr("Play")
                    enabled: root.canOpen
                    onClicked: root._main()
                }

                SettingButton {
                    id: menuButton

                    highlighted: true
                    implicitWidth: VLCStyle.dp(32, VLCStyle.scale)
                    enabled: root.canOpen
                    text: VLCIcons.chevron_down
                    font.family: VLCIcons.fontFamily
                    onClicked: actionMenu.popup(menuButton.mapToGlobal(0, menuButton.height + VLCStyle.dp(2, VLCStyle.scale)), [
                        { "text": qsTr("Stream...") },
                        { "text": qsTr("Convert / Save...") }
                    ])

                    StringListMenu {
                        id: actionMenu
                        ctx: MainCtx
                        onSelected: (index, _) => root._stream(index === 1)
                    }
                }
            }
        }
    }

    // outline instead of the system frame
    Rectangle {
        anchors.fill: parent
        z: 99
        color: "transparent"
        border.width: VLCStyle.border
        border.color: titleTheme.border
    }

    // ---- components (as SettingRow.qml) ---------------------------------------------

    // thin scroll bar in the colors of the window, wider while used
    component ScrollBar: T.ScrollBar {
        id: bar

        readonly property bool _used: bar.hovered || bar.pressed

        // templates have no size of their own
        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                 implicitContentHeight + topPadding + bottomPadding)

        policy: T.ScrollBar.AsNeeded
        padding: VLCStyle.dp(2, VLCStyle.scale)
        minimumSize: 0.1

        background: Rectangle {
            radius: width / 2
            visible: bar._used && bar.size < 1.0
            color: root._surface
        }
        contentItem: Rectangle {
            implicitWidth: bar._used ? VLCStyle.scrollBarInteractingSize : VLCStyle.scrollBarNonInteractingSize
            radius: width / 2
            visible: bar.size < 1.0
            color: Qt.alpha(theme.fg.secondary, bar._used ? 0.8 : 0.5)

            Behavior on implicitWidth {
                NumberAnimation { duration: VLCStyle.duration_veryShort; easing.type: Easing.OutSine }
            }
        }
    }

    component Page: ColumnLayout {
        spacing: 0
    }

    component SectionTitle: T.Label {
        Layout.fillWidth: true
        topPadding: VLCStyle.dp(10, VLCStyle.scale)
        bottomPadding: VLCStyle.dp(10, VLCStyle.scale)
        color: theme.fg.primary
        opacity: 0.85
        font.pixelSize: VLCStyle.fontSize_xlarge
        font.weight: Font.DemiBold
    }

    // label on the left, controls on the right; greyed out when disabled
    component Row2: RowLayout {
        property string label

        Layout.fillWidth: true
        Layout.minimumHeight: VLCStyle.dp(46, VLCStyle.scale)
        spacing: VLCStyle.margin_xsmall
        opacity: enabled ? 1.0 : 0.4

        T.Label {
            Layout.fillWidth: true
            Layout.rightMargin: VLCStyle.margin_small
            text: parent.label
            color: root._text
            font.pixelSize: VLCStyle.fontSize_large
            elide: Text.ElideRight
        }
    }

    // text input: well with a 2px surface border, accent while editing
    component InputField: T.TextField {
        id: field

        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
        leftPadding: VLCStyle.dp(12, VLCStyle.scale)
        rightPadding: VLCStyle.dp(12, VLCStyle.scale)
        verticalAlignment: TextInput.AlignVCenter

        color: root._text
        selectionColor: root._selected
        selectedTextColor: theme.fg.primary
        placeholderTextColor: Qt.alpha(theme.fg.secondary, 0.4)
        font.pixelSize: VLCStyle.fontSize_large

        background: Rectangle {
            color: root._well
            radius: root._radius
            border.width: VLCStyle.dp(2, VLCStyle.scale)
            border.color: field.activeFocus ? theme.accent : root._surface

            // templates do not draw the placeholder
            T.Label {
                anchors.fill: parent
                anchors.leftMargin: field.leftPadding
                anchors.rightMargin: field.rightPadding
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: field.horizontalAlignment === TextInput.AlignRight ? Text.AlignRight : Text.AlignLeft
                visible: field.text === "" && !field.preeditText
                text: field.placeholderText
                color: field.placeholderTextColor
                font: field.font
                elide: Text.ElideRight
            }
        }
    }

    // whole numbers (or decimals) with a unit
    component NumberField: RowLayout {
        id: numberField

        property alias text: numberInput.text
        property string unit: ""
        property bool decimals: false

        spacing: VLCStyle.margin_xsmall

        InputField {
            id: numberInput
            Layout.preferredWidth: VLCStyle.dp(120, VLCStyle.scale)
            horizontalAlignment: TextInput.AlignRight
            validator: RegularExpressionValidator {
                regularExpression: numberField.decimals ? /[0-9]*[.]?[0-9]*/ : /-?[0-9]*/
            }
        }

        T.Label {
            visible: numberField.unit !== ""
            Layout.preferredWidth: VLCStyle.dp(44, VLCStyle.scale)
            text: numberField.unit
            font.pixelSize: VLCStyle.fontSize_large
            color: root._mutedText
        }
    }

    // a file path (or URL) with a Browse button
    component PathField: RowLayout {
        id: pathField

        property alias text: pathInput.text
        property string title
        // the URL of the file instead of its path
        property bool urls: false

        spacing: VLCStyle.margin_xsmall

        InputField {
            id: pathInput
            Layout.preferredWidth: root.controlWidth - VLCStyle.dp(100, VLCStyle.scale) - VLCStyle.margin_xsmall
        }

        SettingButton {
            text: qsTr("Browse")
            onClicked: {
                const list = VLCConfig.browseFiles(pathField.title)
                if (list.length > 0)
                    pathInput.text = pathField.urls ? list[0].toString() : VLCOpenMedia.displayPath(list[0].toString())
            }
        }
    }

    // ON/OFF switch (Figma "Toggle": 68x32)
    component Toggle: T.AbstractButton {
        id: toggle

        checkable: true
        implicitWidth: VLCStyle.dp(68, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

        readonly property real _inset: VLCStyle.dp(3, VLCStyle.scale)
        readonly property real _knob: height - 2 * _inset

        background: Rectangle {
            color: root._well
            radius: root._radius
            border.width: toggle.visualFocus ? VLCStyle.focus_border : 0
            border.color: theme.visualFocus

            Rectangle {
                x: toggle.checked ? toggle._inset : (toggle.width - width - toggle._inset)
                anchors.verticalCenter: parent.verticalCenter
                width: toggle.width - toggle._knob - 3 * toggle._inset
                height: toggle._knob
                radius: VLCStyle.dp(3, VLCStyle.scale)
                color: toggle.checked ? root._selected : root._surface

                T.Label {
                    anchors.centerIn: parent
                    text: toggle.checked ? qsTr("ON") : qsTr("OFF")
                    font.pixelSize: VLCStyle.fontSize_normal
                    color: toggle.checked ? theme.accent : root._mutedText
                }
            }

            Rectangle {
                x: toggle.checked ? (toggle.width - width - toggle._inset) : toggle._inset
                anchors.verticalCenter: parent.verticalCenter
                width: toggle._knob
                height: toggle._knob
                radius: VLCStyle.dp(3, VLCStyle.scale)
                color: toggle.checked ? Qt.darker(theme.accent, 1.23) : theme.border

                Behavior on x {
                    NumberAnimation { duration: VLCStyle.duration_veryShort; easing.type: Easing.InOutSine }
                }
            }
        }
    }

    // button of the settings window; highlighted = the main one
    component SettingButton: T.Button {
        id: button

        implicitWidth: Math.max(VLCStyle.dp(100, VLCStyle.scale), contentItem.implicitWidth + VLCStyle.dp(28, VLCStyle.scale))
        implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
        font.pixelSize: VLCStyle.fontSize_large
        font.weight: Font.DemiBold

        background: Rectangle {
            radius: root._radius
            readonly property color fill: button.highlighted ? root._selected : root._surface
            color: button.hovered && button.enabled ? Qt.lighter(fill, 1.2) : fill
            border.width: button.visualFocus ? VLCStyle.focus_border : 0
            border.color: theme.visualFocus
        }
        contentItem: T.Label {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: button.text
            font: button.font
            opacity: button.enabled ? 1.0 : 0.4
            color: button.highlighted ? theme.accent : root._text
        }
    }

    // drop-down list of { value, text } (Figma "Dropdown": 320x36)
    component Dropdown: T.ComboBox {
        id: combo

        property var value
        signal picked(var value)

        implicitWidth: root.controlWidth
        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)

        textRole: "text"
        valueRole: "value"
        // the index of `value`, also when it changes from outside
        function _sync() {
            const m = model ?? []
            let index = -1
            for (let i = 0; i < m.length; ++i)
                if (String(m[i].value) === String(value))
                    index = i
            currentIndex = index
        }
        onValueChanged: _sync()
        onModelChanged: _sync()
        Component.onCompleted: _sync()
        onActivated: (index) => picked(valueAt(index))

        background: Rectangle {
            color: root._well
            radius: root._radius
            border.width: combo.visualFocus ? VLCStyle.focus_border : 0
            border.color: theme.visualFocus

            Rectangle {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: combo.hovered ? Qt.lighter(root._surface, 1.2) : root._surface
            }
        }

        contentItem: T.Label {
            leftPadding: VLCStyle.dp(14, VLCStyle.scale)
            rightPadding: VLCStyle.dp(14, VLCStyle.scale) + VLCStyle.icon_normal
            verticalAlignment: Text.AlignVCenter
            text: combo.currentIndex >= 0 ? combo.displayText : String(combo.value ?? "")
            color: root._text
            font.pixelSize: VLCStyle.fontSize_large
            elide: Text.ElideRight
        }

        indicator: T.Label {
            x: combo.width - width - VLCStyle.dp(10, VLCStyle.scale)
            anchors.verticalCenter: combo.verticalCenter
            text: VLCIcons.chevron_down
            font.family: VLCIcons.fontFamily
            font.pixelSize: VLCStyle.icon_normal
            color: root._text
        }

        delegate: T.ItemDelegate {
            required property var modelData
            required property int index

            width: combo.width - VLCStyle.dp(4, VLCStyle.scale)
            implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
            highlighted: combo.highlightedIndex === index

            contentItem: T.Label {
                leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                verticalAlignment: Text.AlignVCenter
                text: modelData.text || String(modelData.value)
                color: (combo.currentIndex === index) ? theme.accent : root._text
                font.pixelSize: VLCStyle.fontSize_large
                elide: Text.ElideRight
            }
            background: Rectangle {
                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: parent.highlighted ? root._surface : "transparent"
            }
        }

        popup: T.Popup {
            y: combo.height + VLCStyle.dp(2, VLCStyle.scale)
            width: combo.width
            implicitHeight: Math.min(contentItem.implicitHeight + 2 * padding, VLCStyle.dp(320, VLCStyle.scale))
            padding: VLCStyle.dp(2, VLCStyle.scale)

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: combo.popup.visible ? combo.delegateModel : null
                currentIndex: combo.highlightedIndex
            }

            background: Rectangle {
                color: root._well
                radius: root._radius
                border.width: VLCStyle.border
                border.color: windowTheme.border
            }
        }
    }

    // text field with a list of values to pick (devices, URL history)
    component EditCombo: InputField {
        id: editCombo

        property var suggestions: []

        implicitWidth: root.controlWidth
        rightPadding: VLCStyle.dp(12, VLCStyle.scale) + (suggestions.length > 0 ? VLCStyle.icon_normal : 0)

        T.Label {
            id: editIndicator

            visible: editCombo.suggestions.length > 0
            anchors { right: parent.right; rightMargin: VLCStyle.dp(10, VLCStyle.scale); verticalCenter: parent.verticalCenter }
            text: VLCIcons.chevron_down
            font.family: VLCIcons.fontFamily
            font.pixelSize: VLCStyle.icon_normal
            color: root._text

            TapHandler {
                onTapped: suggestionPopup.opened ? suggestionPopup.close() : suggestionPopup.open()
            }
        }

        T.Popup {
            id: suggestionPopup

            y: editCombo.height + VLCStyle.dp(2, VLCStyle.scale)
            width: editCombo.width
            implicitHeight: Math.min(suggestionList.contentHeight + 2 * padding, VLCStyle.dp(320, VLCStyle.scale))
            padding: VLCStyle.dp(2, VLCStyle.scale)

            contentItem: ListView {
                id: suggestionList

                clip: true
                model: editCombo.suggestions
                delegate: T.ItemDelegate {
                    id: suggestion

                    required property var modelData

                    width: suggestionList.width
                    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
                    onClicked: {
                        editCombo.text = modelData
                        suggestionPopup.close()
                    }

                    contentItem: T.Label {
                        leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                        verticalAlignment: Text.AlignVCenter
                        text: suggestion.modelData
                        color: suggestion.modelData === editCombo.text ? theme.accent : root._text
                        font.pixelSize: VLCStyle.fontSize_large
                        elide: Text.ElideMiddle
                    }
                    background: Rectangle {
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: suggestion.hovered ? root._surface : "transparent"
                    }
                }
            }

            background: Rectangle {
                color: root._well
                radius: root._radius
                border.width: VLCStyle.border
                border.color: windowTheme.border
            }
        }
    }

    // tool tip over its parent
    component ToolTipArea: HoverHandler {
        id: hover

        property string text

        property T.ToolTip tip: T.ToolTip {
            parent: hover.parent
            visible: hover.hovered && hover.text !== ""
            delay: VLCStyle.delayToolTipAppear
            text: hover.text
            y: -height - VLCStyle.dp(6, VLCStyle.scale)
            implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
            implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
            width: Math.min(implicitWidth, VLCStyle.dp(420, VLCStyle.scale))
            padding: VLCStyle.margin_small
            contentItem: T.Label {
                text: hover.text
                color: theme.fg.primary
                wrapMode: Text.WrapAnywhere
                font.pixelSize: VLCStyle.fontSize_normal
            }
            background: Rectangle {
                color: windowTheme.bg.primary
                radius: root._radius
                border.width: VLCStyle.dp(2, VLCStyle.scale)
                border.color: root._well
            }
        }
    }
}
