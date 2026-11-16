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

import VLC.MainInterface
import VLC.Style

// "Stream Output" (classic dialogs/sout, a wizard): its pages as tabs under
// the title bar (Source, Destination Setup, Transcoding Options, Option Setup) with
// Back / Next; destinations of any kind, each with its fields; Display
// locally; transcoding with a profile; Stream all elementary streams; the
// generated stream output string, which can still be changed by hand
// (until the next change of a setting, as the classic one).
RedesignWindow {
    id: root

    title: qsTr("Stream Output")

    tabs: [
        { "text": qsTr("Source"), "icon": "main_open_file_s" },
        { "text": qsTr("Destination Setup"), "icon": "file_stream" },
        { "text": qsTr("Transcoding Options"), "icon": "file_convert" },
        { "text": qsTr("Option Setup"), "icon": "main_settings" }
    ]

    // the same size on every tab
    pageHeight: VLCStyle.dp(470, VLCStyle.scale)

    SoutHelper {
        id: sout
        ctx: MainCtx
    }

    property var mrls: []
    property var options: []

    // VLM Select Output: the chain is given back instead of streaming
    property bool selectMode: false
    signal selected(string chain)

    // [{ type, caption, fields }]
    property var destinations: []

    readonly property var destinationTypes: [
        { "value": "file", "text": qsTr("File"), "caption": qsTr("File"),
          "description": qsTr("This module writes the transcoded stream to a file."),
          "fields": [{ "key": "path", "label": qsTr("Filename"), "browse": true }] },
        { "value": "http", "text": "HTTP", "caption": "HTTP",
          "description": qsTr("This module outputs the transcoded stream to a network via HTTP."),
          "fields": [{ "key": "path", "label": qsTr("Path"), "default": "/" },
                     { "key": "port", "label": qsTr("Port"), "default": 8080 }] },
        { "value": "mmsh", "text": "MS-WMSP (MMSH)", "caption": "WMSP",
          "description": qsTr("This module outputs the transcoded stream to a network via the mms protocol."),
          "fields": [{ "key": "address", "label": qsTr("Address"), "default": "0.0.0.0" },
                     { "key": "port", "label": qsTr("Port"), "default": 8080 }] },
        { "value": "rtsp", "text": "RTSP", "caption": "RTSP",
          "description": qsTr("This module outputs the transcoded stream to a network via RTSP."),
          "fields": [{ "key": "path", "label": qsTr("Path"), "default": "/" },
                     { "key": "port", "label": qsTr("Port"), "default": 8554 }] },
        { "value": "srt", "text": "SRT / MPEG Transport Stream", "caption": "SRT/TS",
          "description": qsTr("This module outputs the transcoded stream to a network via SRT."),
          "fields": [{ "key": "address", "label": qsTr("Address") },
                     { "key": "port", "label": qsTr("Base port"), "default": 7001 },
                     { "key": "name", "label": qsTr("Stream name") }] },
        { "value": "rist", "text": "RIST / MPEG Transport Stream", "caption": "RIST/TS",
          "description": qsTr("This module outputs the stream using the RIST protocol (TR06)."),
          "fields": [{ "key": "address", "label": qsTr("Destination Address") },
                     { "key": "port", "label": qsTr("Destination Port"), "default": 1968 },
                     { "key": "name", "label": qsTr("Stream Name") }] },
        { "value": "rtp-ts", "text": "RTP / MPEG Transport Stream", "caption": "RTP/TS",
          "description": qsTr("This module outputs the transcoded stream to a network via RTP."),
          "fields": [{ "key": "address", "label": qsTr("Address") },
                     { "key": "port", "label": qsTr("Base port"), "default": 5004 },
                     { "key": "name", "label": qsTr("Stream name") }] },
        { "value": "rtp-avp", "text": "RTP Audio/Video Profile", "caption": "RTP/AVP",
          "description": qsTr("This module outputs the transcoded stream to a network via RTP."),
          "fields": [{ "key": "address", "label": qsTr("Address") },
                     { "key": "port", "label": qsTr("Base port"), "default": 5004 },
                     { "key": "name", "label": qsTr("Stream name") }] },
        { "value": "udp", "text": "UDP (legacy)", "caption": "UDP",
          "description": qsTr("This module outputs the transcoded stream to a network via UDP."),
          "fields": [{ "key": "address", "label": qsTr("Address") },
                     { "key": "port", "label": qsTr("Port"), "default": 1234 }] },
        { "value": "icecast", "text": "Icecast", "caption": "Icecast",
          "description": qsTr("This module outputs the transcoded stream to an Icecast server."),
          "fields": [{ "key": "address", "label": qsTr("Address") },
                     { "key": "port", "label": qsTr("Port"), "default": 8000 },
                     { "key": "mount", "label": qsTr("Mount Point") },
                     { "key": "password", "label": qsTr("Login:pass") }] }
    ]

    function _type(value) {
        return destinationTypes.find((t) => t.value === value)
    }

    // DialogsProvider: { mrls, options }
    function reset(args) {
        mrls = args?.mrls ?? []
        options = args?.options ?? []
        destinations = []
        currentTab = 0
        localToggle.checked = false
        transcodeToggle.checked = true
        allToggle.checked = false
        _regenerate()
    }

    function _add() {
        const type = _type(newType.value)
        const fields = {}
        for (const f of type.fields)
            fields[f.key] = f.default ?? (f.key === "port" ? 0 : "")
        destinations = destinations.concat([{ "type": type.value, "caption": type.caption, "fields": fields }])
        _regenerate()
    }

    function _remove(index) {
        const list = destinations.slice()
        list.splice(index, 1)
        destinations = list
        _regenerate()
    }

    // changed in place: the cards (and the field being typed in) stay
    function _setField(index, key, value) {
        destinations[index].fields[key] = value
        _regenerate()
    }

    // SoutDialog::updateChain: the string is made again on every change
    function _regenerate() {
        const chains = destinations.map((d) => sout.destinationChain(d.type, d.fields))
        chainArea.text = sout.streamChain(chains, transcodeToggle.checked, localToggle.checked, allToggle.checked)
    }

    Connections {
        target: sout
        function onProfileChanged() { root._regenerate() }
    }

    function _stream() {
        const m = mrls, o = options, chain = chainArea.text
        close()
        if (selectMode) {
            // as VLMDialog::selectOutput: the chain without its options
            const i = chain.indexOf(" ")
            selected(i >= 0 ? chain.substring(0, i) : chain)
            return
        }
        sout.startStream(m, o, chain)
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.pageHeight
        currentIndex: root.currentTab

        // Source
        ColumnLayout {
            spacing: 0

            WinSectionTitle { text: qsTr("Set up media sources to stream") }

            WinRow {
                label: qsTr("Source:")
                WinLabel {
                    Layout.preferredWidth: WinStyle.controlWidth + VLCStyle.dp(100, VLCStyle.scale)
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideMiddle
                    color: WinStyle.strongText
                    text: root.mrls.length > 0 ? sout.describeSource(root.mrls[0]).text : ""
                }
            }
            WinRow {
                label: qsTr("Type:")
                WinLabel { text: root.mrls.length > 0 ? sout.describeSource(root.mrls[0]).type : "" }
            }

            WinDescription {
                Layout.topMargin: VLCStyle.margin_normal
                font.pixelSize: VLCStyle.fontSize_large
                text: qsTr("This wizard will allow you to stream or convert your media for use locally, on your private network, or on the Internet.\nYou should start by checking that source matches what you want your input to be and then press the \"Next\" button to continue.\n")
            }

            Item { Layout.fillHeight: true }
        }

        // Destination Setup
        ColumnLayout {
            spacing: 0

            WinSectionTitle { text: qsTr("Select destinations to stream to") }

            WinDescription {
                text: qsTr("Add destinations following the streaming methods you need. Be sure to check with transcoding that the format is compatible with the method used.")
            }

            WinRow {
                label: qsTr("New destination")
                WinDropdown {
                    id: newType
                    implicitWidth: WinStyle.controlWidth - VLCStyle.dp(100, VLCStyle.scale) - VLCStyle.margin_xsmall
                    model: root.destinationTypes
                    value: "file"
                }
                WinButton {
                    text: qsTr("Add")
                    onClicked: root._add()
                }
            }

            WinRow {
                label: qsTr("Display locally")
                WinToggle {
                    id: localToggle
                    onToggled: root._regenerate()
                }
            }

            // the added destinations
            Flickable {
                id: destFlick

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: VLCStyle.margin_xsmall
                clip: true
                contentHeight: destColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                T.ScrollBar.vertical: WinScrollBar { }

                ColumnLayout {
                    id: destColumn
                    width: destFlick.width - VLCStyle.margin_small
                    spacing: VLCStyle.margin_small

                    Repeater {
                        model: root.destinations

                        Rectangle {
                            id: destCard

                            required property var modelData
                            required property int index
                            readonly property var type: root._type(modelData.type)

                            Layout.fillWidth: true
                            implicitHeight: destContent.implicitHeight + 2 * VLCStyle.margin_small
                            radius: WinStyle.radius
                            color: WinStyle.surface

                            ColumnLayout {
                                id: destContent

                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: VLCStyle.margin_small }
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true
                                    T.Label {
                                        Layout.fillWidth: true
                                        text: destCard.modelData.caption
                                        color: WinStyle.strongText
                                        font.pixelSize: VLCStyle.fontSize_large
                                        font.weight: Font.DemiBold
                                    }
                                    WinButton {
                                        iconText: VLCIcons.close
                                        toolTip.text: qsTr("Remove")
                                        onClicked: root._remove(destCard.index)
                                    }
                                }

                                WinDescription { text: destCard.type.description }

                                Repeater {
                                    model: destCard.type.fields

                                    WinRow {
                                        id: fieldRow
                                        required property var modelData
                                        label: modelData.label

                                        WinNumberField {
                                            visible: fieldRow.modelData.key === "port"
                                            from: 1; to: 65535
                                            fieldWidth: VLCStyle.dp(110, VLCStyle.scale)
                                            value: Number(destCard.modelData.fields.port ?? 0)
                                            onEdited: (v) => root._setField(destCard.index, "port", v)
                                        }
                                        WinField {
                                            id: textField
                                            visible: fieldRow.modelData.key !== "port"
                                            implicitWidth: WinStyle.controlWidth - (fieldRow.modelData.browse ? VLCStyle.dp(100, VLCStyle.scale) + VLCStyle.margin_xsmall : 0)
                                            echoMode: fieldRow.modelData.key === "password" ? TextInput.PasswordEchoOnEdit : TextInput.Normal
                                            text: String(destCard.modelData.fields[fieldRow.modelData.key] ?? "")
                                            onTextEdited: root._setField(destCard.index, fieldRow.modelData.key, text)
                                        }
                                        WinButton {
                                            visible: !!fieldRow.modelData.browse
                                            text: qsTr("Browse...")
                                            onClicked: {
                                                const url = sout.browseSaveFile(qsTr("Save file..."),
                                                    qsTr("Containers (*.ps *.ts *.mpg *.ogg *.asf *.mp4 *.mov *.wav *.raw *.flv *.webm)"))
                                                if (url !== "") {
                                                    textField.text = sout.displayPath(url)
                                                    root._setField(destCard.index, "path", textField.text)
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

        // Transcoding Options
        ColumnLayout {
            spacing: 0

            WinSectionTitle { text: qsTr("Select and choose transcoding options") }

            WinRow {
                label: qsTr("Activate Transcoding")
                WinToggle {
                    id: transcodeToggle
                    checked: true
                    onToggled: root._regenerate()
                }
            }

            ProfileRow {
                helper: sout
                enabled: transcodeToggle.checked
            }

            Item { Layout.fillHeight: true }
        }

        // Option Setup
        ColumnLayout {
            spacing: 0

            WinSectionTitle { text: qsTr("Set up any additional options for streaming") }

            WinRow {
                label: qsTr("Stream all elementary streams")
                WinToggle {
                    id: allToggle
                    onToggled: root._regenerate()
                }
            }

            WinSectionTitle { text: qsTr("Generated stream output string") }

            WinTextArea {
                id: chainArea

                Layout.fillWidth: true
                Layout.fillHeight: true
                font.family: "monospace"
                font.pixelSize: VLCStyle.fontSize_normal

                WinToolTip {
                    text: qsTr("Stream output string.\nThis is automatically generated when you change the above settings,\nbut you can change it manually.")
                }
            }
        }
    }

    footerLeft: [
        WinButton {
            text: qsTr("Back")
            enabled: root.currentTab > 0
            onClicked: root.currentTab = root.currentTab - 1
        },
        WinButton {
            text: qsTr("Next")
            enabled: root.currentTab < root.tabs.length - 1
            onClicked: root.currentTab = root.currentTab + 1
        }
    ]

    footer: [
        WinButton {
            text: qsTr("Cancel")
            onClicked: root.close()
        },
        WinButton {
            text: qsTr("Stream")
            highlighted: true
            enabled: root.selectMode || root.mrls.length > 0
            onClicked: root._stream()
        }
    ]
}
