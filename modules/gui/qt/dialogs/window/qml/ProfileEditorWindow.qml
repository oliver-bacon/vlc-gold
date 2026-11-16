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
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.Style

// The transcoding profile editor (classic VLCProfileEditor,
// dialogs/sout/profile_selector): Encapsulation (the muxer and what it
// supports), Video codec, Audio codec, Subtitles as tabs, the profile
// name. Reads and writes the same profile string ("cat_prop=value;..."),
// where settings that are off or do not apply are left out, as the classic
// editor leaves out its disabled widgets; reads the old format too.
RedesignWindow {
    id: root

    // SoutHelper
    property var helper

    modality: Qt.WindowModal
    title: editing ? qsTr("Edit profile") : qsTr("New profile")

    tabs: [
        { "text": qsTr("Encapsulation"), "icon": "playlist_properties_metadata" },
        { "text": qsTr("Video codec"), "icon": "player_video" },
        { "text": qsTr("Audio codec"), "icon": "player_audio" },
        { "text": qsTr("Subtitles"), "icon": "player_subtitle" }
    ]
    pageHeight: VLCStyle.dp(520, VLCStyle.scale)

    // the profile being changed ("" for a new one)
    property string oldName: ""
    readonly property bool editing: oldName !== ""
    property string error: ""

    property var editorData: ({ "muxers": [], "videoFilters": [], "audioFilters": [] })

    // ---- the classic choices (registerCodecs) ---------------------------------------

    // { value (sout), text, module, video, audio, menus, subs, stream, chapters }
    readonly property var muxers: [
        { "value": "ts", "text": "MPEG-TS", "module": "ts", "caps": [1, 1, 0, 1, 1, 0] },
        { "value": "ps", "text": "MPEG-PS", "module": "ps", "caps": [1, 1, 0, 1, 0, 1] },
        { "value": "webm", "text": "Webm", "module": "avformat", "caps": [1, 1, 0, 0, 1, 0] },
        { "value": "mpeg1", "text": "MPEG 1", "module": "ps", "caps": [1, 1, 0, 0, 0, 0] },
        { "value": "ogg", "text": "Ogg/Ogm", "module": "ogg", "caps": [1, 1, 0, 0, 1, 1] },
        { "value": "asf", "text": "ASF/WMV", "module": "asf", "caps": [1, 1, 0, 1, 1, 1] },
        { "value": "mp4", "text": "MP4/MOV", "module": "mp4", "caps": [1, 1, 1, 1, 1, 0] },
        { "value": "wav", "text": "WAV", "module": "wav", "caps": [0, 1, 0, 0, 0, 0] },
        { "value": "flac", "text": "FLAC", "module": "dummy", "caps": [0, 1, 0, 0, 0, 0] },
        { "value": "mp3", "text": "MP3", "module": "dummy", "caps": [0, 1, 0, 0, 0, 0] },
        { "value": "raw", "text": "RAW", "module": "dummy", "caps": [1, 1, 0, 0, 0, 0] },
        { "value": "flv", "text": "FLV", "module": "avformat", "caps": [1, 1, 0, 0, 1, 0] },
        { "value": "mkv", "text": "MKV", "module": "avformat", "caps": [1, 1, 1, 1, 1, 1] },
        { "value": "avi", "text": "AVI", "module": "avi", "caps": [1, 1, 0, 0, 0, 0] },
        { "value": "mpjpeg", "text": "MJPEG", "module": "mpjpeg", "caps": [1, 0, 0, 0, 0, 0] }
    ]
    readonly property var capNames: [qsTr("Video"), qsTr("Audio"), qsTr("Menus"),
                                     qsTr("Subtitles"), qsTr("Streamable"), qsTr("Chapters")]

    readonly property var videoCodecs: [
        { "value": "mp1v", "text": "MPEG-1" }, { "value": "mp2v", "text": "MPEG-2" },
        { "value": "mp4v", "text": "MPEG-4" }, { "value": "DIV1", "text": "DIVX 1" },
        { "value": "DIV2", "text": "DIVX 2" }, { "value": "DIV3", "text": "DIVX 3" },
        { "value": "H263", "text": "H-263" }, { "value": "h264", "text": "H-264 (AVC)" },
        { "value": "hevc", "text": "H-265 (HEVC)" }, { "value": "av01", "text": "AV1" },
        { "value": "VP80", "text": "VP8" }, { "value": "WMV1", "text": "WMV1" },
        { "value": "WMV2", "text": "WMV2" }, { "value": "MJPG", "text": "M-JPEG" },
        { "value": "theo", "text": "Theora" }
    ]
    // can do quality
    readonly property var qpCodecs: ["h264"]

    readonly property var audioCodecs: [
        { "value": "mpga", "text": "MPEG Audio" }, { "value": "mp3", "text": "MP3" },
        { "value": "mp4a", "text": "MPEG 4 Audio ( AAC )" }, { "value": "a52", "text": "A52/AC-3" },
        { "value": "vorb", "text": "Vorbis" }, { "value": "flac", "text": "Flac" },
        { "value": "opus", "text": "Opus" }, { "value": "spx", "text": "Speex" },
        { "value": "s16l", "text": "PCM 16-bit" }, { "value": "wma2", "text": "WMA2" }
    ]
    readonly property var scales: [qsTr("Auto"), "1", "0.25", "0.5", "0.75", "1.25", "1.5", "1.75", "2"]
    readonly property var sampleRates: [8000, 11025, 22050, 44100, 48000].map((r) => ({ "value": r, "text": r + " Hz" }))
    readonly property var subtitleCodecs: [
        { "value": "dvbs", "text": "DVBS (DVB subtitles)" },
        { "value": "tx3g", "text": "tx3g (MPEG-4 timed text)" },
        { "value": "t140", "text": "T-REC 140 (for rtp)" }
    ]

    // ---- the settings --------------------------------------------------------------

    property string mux: "ts"
    property bool videoEnable: false
    property bool videoCopy: false
    property string videoCodec: "mp1v"
    property var videoFilters: []
    property bool audioEnable: false
    property bool audioCopy: false
    property string audioCodec: "mpga"
    property int sampleRate: 8000
    property var audioFilters: []
    property bool subtitlesEnable: false
    property bool subtitlesOverlay: false
    property string subtitlesCodec: "dvbs"

    readonly property var _mux: muxers.find((m) => m.value === mux) ?? muxers[0]
    readonly property string muxWarning: {
        if (_mux.module === "avformat")
            return qsTr("This muxer is not provided directly by VLC: It could be missing.")
        const present = editorData.muxers
        if (!present.includes(_mux.module) && !present.includes("mux_" + _mux.module))
            return qsTr("This muxer is missing. Using this profile will fail")
        return ""
    }

    // VLCSoutHelper / VLCProfileSelector: the profile to edit
    function openEditor(name, value) {
        editorData = helper.profileEditorData()
        oldName = name
        error = ""
        currentTab = 0
        nameField.text = name
        _reset()
        _fill(value)
        open()
    }

    // VLCProfileEditor::reset, and the defaults of profiles.ui
    function _reset() {
        mux = "ts"
        videoEnable = false; videoCopy = false
        videoCodec = "mp1v"; vBitrate.value = 800; vQuality.value = 0; vFramerate.value = 0
        vCustom.text = ""; vScale.text = scales[0]; vWidth.value = 0; vHeight.value = 0
        videoFilters = []
        audioEnable = false; audioCopy = false
        audioCodec = "mpga"; aBitrate.value = 128; aChannels.value = 2; sampleRate = 8000; aGain.value = 0
        audioFilters = []
        subtitlesEnable = false; subtitlesOverlay = false; subtitlesCodec = "dvbs"
    }

    // VLCProfileEditor::fillProfile
    function _fill(value) {
        if (/^\w+;\d+;\d+;\d+;/.test(value)) {
            _fillOld(value)
            return
        }
        for (const tuple of value.split(";")) {
            const kv = tuple.split("=")
            if (kv.length !== 2)
                continue
            const key = kv[0], v = kv[1]
            switch (key) {
            case "muxer_mux": if (muxers.some((m) => m.value === v)) mux = v; break
            case "video_enable": videoEnable = v !== ""; break
            case "video_copy": videoCopy = v !== ""; break
            case "video_codec": videoCodec = v; break
            case "vcodec_bitrate": vBitrate.value = Number(v); break
            case "vcodec_qp": vQuality.value = Number(v); break
            case "vcodec_framerate": vFramerate.value = Number(v); break
            case "vcodec_custom": vCustom.text = helper.percentDecode(v); break
            case "vcodec_scale": vScale.text = v; break
            case "vcodec_width": vWidth.value = Number(v); break
            case "vcodec_height": vHeight.value = Number(v); break
            case "video_filters": videoFilters = helper.percentDecode(v).split(";"); break
            case "audio_enable": audioEnable = v !== ""; break
            case "audio_copy": audioCopy = v !== ""; break
            case "audio_codec": audioCodec = v; break
            case "acodec_bitrate": aBitrate.value = Number(v); break
            case "acodec_channels": aChannels.value = Number(v); break
            case "acodec_samplerate": sampleRate = Number(v); break
            case "acodec_gain": aGain.value = Number(v); break
            case "audio_filters": audioFilters = helper.percentDecode(v).split(";"); break
            case "subtitles_enable": subtitlesEnable = v !== ""; break
            case "subtitles_overlay": subtitlesOverlay = v !== ""; break
            case "subtitles_codec": subtitlesCodec = v; break
            }
        }
    }

    // VLCProfileEditor::fillProfileOldFormat
    function _fillOld(value) {
        const o = value.split(";")
        if (o.length < 16)
            return
        if (muxers.some((m) => m.value === o[0])) mux = o[0]
        videoCopy = !Number(o[1])
        videoEnable = o[4] !== "none"
        audioCopy = !Number(o[2])
        audioEnable = o[10] !== "none"
        subtitlesEnable = !!Number(o[3])
        videoCodec = o[4]
        vBitrate.value = Number(o[5])
        vScale.text = Number(o[6]) > 0 ? o[6] : scales[0]
        vFramerate.value = Number(o[7])
        vWidth.value = Number(o[8])
        vHeight.value = Number(o[9])
        audioCodec = o[10]
        aBitrate.value = Number(o[11])
        aChannels.value = Number(o[12])
        sampleRate = sampleRates.some((r) => String(r.value) === o[13]) ? Number(o[13]) : 44100
        subtitlesCodec = o[14]
        subtitlesOverlay = !!Number(o[15])
    }

    // VLCProfileEditor::transcodeValue: only what is on and applies
    function _value() {
        const c = ["muxer_mux=" + mux]
        if (videoEnable) {
            c.push("video_enable=yes")
            if (videoCopy)
                c.push("video_copy=yes")
            else {
                c.push("video_codec=" + videoCodec)
                c.push("vcodec_bitrate=" + vBitrate.value)
                if (qpCodecs.includes(videoCodec))
                    c.push("vcodec_qp=" + vQuality.value)
                c.push("vcodec_framerate=" + vFramerate.value)
                if (vCustom.text !== "")
                    c.push("vcodec_custom=" + helper.percentEncode(vCustom.text))
                if (vScale.text !== "")
                    c.push("vcodec_scale=" + vScale.text)
                c.push("vcodec_width=" + vWidth.value)
                c.push("vcodec_height=" + vHeight.value)
                if (videoFilters.length > 0)
                    c.push("video_filters=" + helper.percentEncode(videoFilters.join(";")))
            }
        }
        if (audioEnable) {
            c.push("audio_enable=yes")
            if (audioCopy)
                c.push("audio_copy=yes")
            else {
                c.push("audio_codec=" + audioCodec)
                c.push("acodec_bitrate=" + aBitrate.value)
                c.push("acodec_channels=" + aChannels.value)
                c.push("acodec_samplerate=" + sampleRate)
                c.push("acodec_gain=" + aGain.value)
                if (audioFilters.length > 0)
                    c.push("audio_filters=" + helper.percentEncode(audioFilters.join(";")))
            }
        }
        if (subtitlesEnable) {
            c.push("subtitles_enable=yes")
            if (subtitlesOverlay)
                c.push("subtitles_overlay=yes")
            else
                c.push("subtitles_codec=" + subtitlesCodec)
        }
        return c.join(";")
    }

    function _accept() {
        if (nameField.text === "") {
            error = qsTr("You must set a name for the profile.")
            nameField.forceActiveFocus()
            return
        }
        helper.storeProfile(oldName, nameField.text, _value())
        close()
    }

    // a list of filters with check boxes
    component FilterList: WinList {
        id: filterList

        property var filters: []
        property var selected: []
        signal toggled(var list)

        Layout.fillWidth: true
        Layout.fillHeight: true
        model: filters

        delegate: T.ItemDelegate {
            id: filterRow

            required property var modelData
            width: ListView.view.width
            implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
            leftPadding: VLCStyle.margin_small
            background: null

            contentItem: WinCheck {
                text: filterRow.modelData.text
                checked: filterList.selected.includes(filterRow.modelData.value)
                onToggled: {
                    const list = filterList.selected.filter((v) => v !== filterRow.modelData.value)
                    if (checked)
                        list.push(filterRow.modelData.value)
                    filterList.toggled(list)
                }
                WinToolTip { text: filterRow.modelData.help }
            }
        }
    }

    WinRow {
        label: qsTr("Profile Name")
        WinField {
            id: nameField
            readOnly: root.editing
            opacity: readOnly ? 0.6 : 1.0
        }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.pageHeight - WinStyle.rowHeight
        currentIndex: root.currentTab

        // Encapsulation
        ColumnLayout {
            spacing: VLCStyle.margin_small

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: VLCStyle.margin_small
                spacing: VLCStyle.margin_xsmall

                Repeater {
                    model: root.muxers
                    WinButton {
                        required property var modelData
                        implicitWidth: VLCStyle.dp(120, VLCStyle.scale)
                        text: modelData.text
                        checked: root.mux === modelData.value
                        onClicked: root.mux = modelData.value
                    }
                }
            }

            WinSectionTitle { text: qsTr("Features") }

            Flow {
                Layout.fillWidth: true
                spacing: VLCStyle.margin_normal

                Repeater {
                    model: root.capNames
                    RowLayout {
                        required property string modelData
                        required property int index
                        spacing: VLCStyle.margin_xxsmall
                        T.Label {
                            text: root._mux.caps[parent.index] ? VLCIcons.check : VLCIcons.close
                            font.family: VLCIcons.fontFamily
                            font.pixelSize: VLCStyle.icon_small
                            color: root._mux.caps[parent.index] ? WinStyle.accent : WinStyle.mutedText
                        }
                        WinLabel { text: parent.modelData }
                    }
                }
            }

            WinDescription {
                visible: root.muxWarning !== ""
                Layout.topMargin: VLCStyle.margin_small
                text: root.muxWarning
                color: root._mux.module === "avformat" ? WinStyle.text : WinStyle.negative
                font.pixelSize: VLCStyle.fontSize_large
            }

            Item { Layout.fillHeight: true }
        }

        // Video codec
        Flickable {
            id: videoFlick
            clip: true
            contentHeight: videoColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollBar.vertical: WinScrollBar { }

            ColumnLayout {
                id: videoColumn
                width: videoFlick.width - VLCStyle.margin_small
                spacing: 0

                WinRow {
                    label: qsTr("Video")
                    WinToggle { checked: root.videoEnable; onToggled: root.videoEnable = checked }
                }
                WinRow {
                    enabled: root.videoEnable
                    label: qsTr("Keep original video track")
                    WinToggle { checked: root.videoCopy; onToggled: root.videoCopy = checked }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    enabled: root.videoEnable && !root.videoCopy
                    opacity: enabled ? 1 : 0.4

                    WinSectionTitle { text: qsTr("Encoding parameters") }
                    WinRow {
                        label: qsTr("Codec")
                        WinDropdown {
                            model: root.videoCodecs
                            source: root.videoCodec
                            onPicked: (v) => root.videoCodec = v
                        }
                    }
                    WinRow {
                        label: qsTr("Bitrate")
                        // bitrate and quality exclude each other
                        WinNumberField { id: vBitrate; from: 0; to: 32768; step: 16; unit: "kb/s"; onEdited: vQuality.value = 0 }
                    }
                    WinRow {
                        label: qsTr("Quality")
                        enabled: root.qpCodecs.includes(root.videoCodec)
                        WinNumberField { id: vQuality; from: 0; to: 99; onEdited: vBitrate.value = 0 }
                    }
                    WinRow {
                        label: qsTr("Frame Rate")
                        WinNumberField { id: vFramerate; from: 0; to: 99.99; decimals: 2; unit: "fps" }
                    }
                    WinRow {
                        label: qsTr("Custom options")
                        WinField { id: vCustom }
                    }

                    WinSectionTitle { text: qsTr("Resolution") }
                    WinDescription {
                        text: qsTr("You just need to fill one of the three following parameters, VLC will autodetect the other using the original aspect ratio")
                    }
                    WinRow {
                        label: qsTr("Scale")
                        WinEditCombo { id: vScale; suggestions: root.scales }
                    }
                    WinRow {
                        label: qsTr("Width")
                        WinNumberField { id: vWidth; from: 0; to: 9999; step: 8; unit: "px" }
                    }
                    WinRow {
                        label: qsTr("Height")
                        WinNumberField { id: vHeight; from: 0; to: 9999; step: 8; unit: "px" }
                    }

                    WinSectionTitle { text: qsTr("Filters") }
                    FilterList {
                        Layout.preferredHeight: VLCStyle.dp(200, VLCStyle.scale)
                        filters: root.editorData.videoFilters
                        selected: root.videoFilters
                        onToggled: (list) => root.videoFilters = list
                    }
                }
            }
        }

        // Audio codec
        Flickable {
            id: audioFlick
            clip: true
            contentHeight: audioColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollBar.vertical: WinScrollBar { }

            ColumnLayout {
                id: audioColumn
                width: audioFlick.width - VLCStyle.margin_small
                spacing: 0

                WinRow {
                    label: qsTr("Audio")
                    WinToggle { checked: root.audioEnable; onToggled: root.audioEnable = checked }
                }
                WinRow {
                    enabled: root.audioEnable
                    label: qsTr("Keep original audio track")
                    WinToggle { checked: root.audioCopy; onToggled: root.audioCopy = checked }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    enabled: root.audioEnable && !root.audioCopy
                    opacity: enabled ? 1 : 0.4

                    WinSectionTitle { text: qsTr("Encoding parameters") }
                    WinRow {
                        label: qsTr("Codec")
                        WinDropdown {
                            model: root.audioCodecs
                            source: root.audioCodec
                            onPicked: (v) => root.audioCodec = v
                        }
                    }
                    WinRow {
                        label: qsTr("Bitrate")
                        WinNumberField { id: aBitrate; from: 8; to: 512; unit: "kb/s" }
                    }
                    WinRow {
                        label: qsTr("Channels")
                        WinNumberField { id: aChannels; from: 1; to: 10 }
                    }
                    WinRow {
                        label: qsTr("Sample Rate")
                        WinDropdown {
                            model: root.sampleRates
                            source: root.sampleRate
                            onPicked: (v) => root.sampleRate = v
                        }
                    }
                    WinRow {
                        label: qsTr("Volume")
                        WinNumberField { id: aGain; from: 0; to: 400; step: 10; unit: "%" }
                    }

                    WinSectionTitle { text: qsTr("Filters") }
                    FilterList {
                        Layout.preferredHeight: VLCStyle.dp(200, VLCStyle.scale)
                        filters: root.editorData.audioFilters
                        selected: root.audioFilters
                        onToggled: (list) => root.audioFilters = list
                    }
                }
            }
        }

        // Subtitles
        ColumnLayout {
            spacing: 0

            WinRow {
                label: qsTr("Subtitles")
                WinToggle { checked: root.subtitlesEnable; onToggled: root.subtitlesEnable = checked }
            }
            WinRow {
                enabled: root.subtitlesEnable && !root.subtitlesOverlay
                label: qsTr("Codec")
                WinDropdown {
                    model: root.subtitleCodecs
                    source: root.subtitlesCodec
                    onPicked: (v) => root.subtitlesCodec = v
                }
            }
            WinRow {
                enabled: root.subtitlesEnable
                label: qsTr("Overlay subtitles on the video")
                WinToggle { checked: root.subtitlesOverlay; onToggled: root.subtitlesOverlay = checked }
            }

            Item { Layout.fillHeight: true }
        }
    }

    footerLeft: [
        WinLabel {
            visible: root.error !== ""
            text: root.error
            color: WinStyle.negative
            font.pixelSize: VLCStyle.fontSize_normal
        }
    ]

    footer: [
        WinButton {
            text: qsTr("Cancel")
            onClicked: root.close()
        },
        WinButton {
            text: root.editing ? qsTr("Save") : qsTr("Create")
            highlighted: true
            onClicked: root._accept()
        }
    ]
}
