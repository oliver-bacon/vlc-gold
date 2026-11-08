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

// "VLM configurator" (classic dialogs/vlm): the edition of a broadcast or a
// schedule (name, enabled, input, output, loop or date / time / repeat),
// Add (Save while changing one) and Clear; the media list with enable,
// play / pause, stop, repeat, change, delete; Import and Export.
RedesignWindow {
    id: root

    title: qsTr("VLM configurator")

    resizable: true
    fitWidth: VLCStyle.dp(820, VLCStyle.scale)
    initialHeight: VLCStyle.dp(760, VLCStyle.scale)

    VlmModel {
        id: vlm
        ctx: MainCtx
    }

    // Select Input / Select Output: the redesigned Open Media and Stream
    // windows give their result back
    OpenMediaDialog {
        id: inputPicker
        transientParent: root
        modality: Qt.WindowModal
        onSelected: (mrl, options) => {
            inputField.text = mrl
            root.inputOptions = options
        }
    }

    StreamWindow {
        id: outputPicker
        transientParent: root
        modality: Qt.WindowModal
        selectMode: true
        onSelected: (chain) => outputField.text = chain
    }

    // index of the item being changed, -1 when adding
    property int editing: -1
    property string error: ""
    // options of the input picked with Select Input
    property string inputOptions: ""

    function reset(args) {
    }

    function _pad(n) {
        return String(n).padStart(2, "0")
    }

    function _clear() {
        const now = new Date()
        editing = -1
        error = ""
        nameField.text = ""
        inputField.text = ""
        inputOptions = ""
        outputField.text = ""
        enableToggle.checked = true
        loopToggle.checked = false
        hours.value = now.getHours(); minutes.value = now.getMinutes(); seconds.value = now.getSeconds()
        day.value = now.getDate(); month.value = now.getMonth() + 1; year.value = now.getFullYear()
        repeatCount.value = 0
        repeatDays.value = 0
    }

    Component.onCompleted: _clear()

    function _form() {
        return {
            "name": nameField.text,
            "type": typeBox.value,
            "input": inputField.text,
            "inputOptions": inputOptions,
            "output": outputField.text,
            "enabled": enableToggle.checked,
            "loop": loopToggle.checked,
            "time": _pad(hours.value) + ":" + _pad(minutes.value) + ":" + _pad(seconds.value),
            "date": String(year.value).padStart(4, "0") + "-" + _pad(month.value) + "-" + _pad(day.value),
            "repeat": repeatCount.value,
            "repeatDays": repeatDays.value
        }
    }

    function _add() {
        error = vlm.add(_form())
        if (error === "")
            _clear()
    }

    function _save() {
        vlm.modify(editing, _form())
        _clear()
    }

    function _change(index) {
        const item = vlm.items[index]
        editing = index
        error = ""
        typeBox.value = item.type
        nameField.text = item.name
        inputField.text = item.input
        inputOptions = item.inputOptions ?? ""
        outputField.text = item.output
        enableToggle.checked = item.enabled
        loopToggle.checked = item.loop
        const t = String(item.time).split(":")
        hours.value = Number(t[0]); minutes.value = Number(t[1]); seconds.value = Number(t[2])
        const d = String(item.date).split("-")
        year.value = Number(d[0]); month.value = Number(d[1]); day.value = Number(d[2])
        repeatCount.value = item.repeat
        repeatDays.value = item.repeatDays
    }

    readonly property bool _schedule: typeBox.value === 1
    readonly property real _small: VLCStyle.dp(64, VLCStyle.scale)

    WinDescription {
        visible: !vlm.available
        text: qsTr("VLM is not available.")
        color: WinStyle.negative
    }

    // ---- Media Manager Edition -----------------------------------------------------

    WinSectionTitle { text: qsTr("Media Manager Edition") }

    WinRow {
        label: qsTr("Type")
        enabled: root.editing < 0

        WinDropdown {
            id: typeBox
            model: [
                { "value": 0, "text": qsTr("Broadcast") },
                { "value": 1, "text": qsTr("Schedule") }
            ]
            value: 0
        }
    }

    WinRow {
        label: qsTr("Name:")

        WinField {
            id: nameField
            readOnly: root.editing >= 0
            opacity: readOnly ? 0.6 : 1.0
        }
    }

    WinRow {
        label: qsTr("Enable")
        WinToggle { id: enableToggle; checked: true }
    }

    WinRow {
        label: qsTr("Input:")

        WinField {
            id: inputField
            implicitWidth: WinStyle.controlWidth - VLCStyle.dp(130, VLCStyle.scale) - VLCStyle.margin_xsmall
        }
        WinButton {
            implicitWidth: VLCStyle.dp(130, VLCStyle.scale)
            text: qsTr("Select Input")
            onClicked: {
                inputPicker.reset({ "tab": "file", "action": "select" })
                inputPicker.open()
            }
        }
    }

    WinRow {
        label: qsTr("Output:")

        WinField {
            id: outputField
            implicitWidth: WinStyle.controlWidth - VLCStyle.dp(130, VLCStyle.scale) - VLCStyle.margin_xsmall
        }
        WinButton {
            implicitWidth: VLCStyle.dp(130, VLCStyle.scale)
            text: qsTr("Select Output")
            onClicked: {
                outputPicker.reset({})
                outputPicker.open()
            }
        }
    }

    WinRow {
        visible: !root._schedule
        label: qsTr("Loop")
        WinToggle { id: loopToggle }
    }

    WinRow {
        visible: root._schedule
        label: qsTr("Hours / Minutes / Seconds:")
        WinNumberField { id: hours; from: 0; to: 23; fieldWidth: root._small }
        WinNumberField { id: minutes; from: 0; to: 59; fieldWidth: root._small }
        WinNumberField { id: seconds; from: 0; to: 59; fieldWidth: root._small }
    }

    WinRow {
        visible: root._schedule
        label: qsTr("Day / Month / Year:")
        WinNumberField { id: day; from: 1; to: 31; fieldWidth: root._small }
        WinNumberField { id: month; from: 1; to: 12; fieldWidth: root._small }
        WinNumberField { id: year; from: 1970; to: 9999; fieldWidth: VLCStyle.dp(84, VLCStyle.scale) }
    }

    WinRow {
        visible: root._schedule
        label: qsTr("Repeat:")
        WinNumberField { id: repeatCount; from: 0; to: 99; fieldWidth: root._small }
    }

    WinRow {
        visible: root._schedule
        label: qsTr("Repeat delay:")
        WinNumberField { id: repeatDays; from: 0; to: 99; unit: qsTr("days"); fieldWidth: root._small }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: VLCStyle.margin_xsmall
        spacing: VLCStyle.margin_xsmall

        WinLabel {
            Layout.fillWidth: true
            visible: root.error !== ""
            text: root.error
            color: WinStyle.negative
            font.pixelSize: VLCStyle.fontSize_normal
        }
        Item { Layout.fillWidth: root.error === "" }

        WinButton {
            text: qsTr("Clear")
            onClicked: root._clear()
        }
        WinButton {
            highlighted: true
            enabled: vlm.available
            text: root.editing >= 0 ? qsTr("Save") : qsTr("Add")
            onClicked: root.editing >= 0 ? root._save() : root._add()
        }
    }

    // ---- Media Manager List ----------------------------------------------------------

    WinSectionTitle { text: qsTr("Media Manager List") }

    WinList {
        id: mediaFrame

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: VLCStyle.dp(160, VLCStyle.scale)
        model: vlm.items
        emptyText: qsTr("No broadcast nor schedule.")

        delegate: T.ItemDelegate {
            id: media

            required property var modelData
            required property int index
            readonly property bool selected: ListView.view.currentIndex === index || root.editing === index
            readonly property bool broadcast: modelData.type === 0

            width: ListView.view.width
            implicitHeight: VLCStyle.dp(54, VLCStyle.scale)
            leftPadding: VLCStyle.margin_small
            rightPadding: VLCStyle.margin_small

            onClicked: ListView.view.currentIndex = index

            background: Rectangle {
                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: media.selected ? WinStyle.selected
                                      : (media.hovered ? Qt.alpha(WinStyle.surface, 0.6) : "transparent")
            }

            contentItem: RowLayout {
                spacing: VLCStyle.margin_xsmall

                WinToggle {
                    checked: media.modelData.enabled
                    onToggled: vlm.setEnabled(media.index, checked)
                    WinToolTip { text: qsTr("Enable") }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: VLCStyle.margin_xsmall
                    spacing: 0

                    T.Label {
                        Layout.fillWidth: true
                        text: (media.broadcast ? qsTr("Broadcast: ") : qsTr("Schedule: ")) + media.modelData.name
                        color: WinStyle.strongText
                        font.pixelSize: VLCStyle.fontSize_large
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    T.Label {
                        Layout.fillWidth: true
                        text: media.modelData.input + (media.modelData.output !== "" ? "  →  " + media.modelData.output : "")
                        color: WinStyle.mutedText
                        font.pixelSize: VLCStyle.fontSize_small
                        elide: Text.ElideMiddle
                    }
                }

                WinButton {
                    visible: media.broadcast
                    iconText: media.modelData.playing === 1 ? VLCIcons.pause_filled : VLCIcons.play_filled
                    toolTip.text: media.modelData.playing === 1 ? qsTr("Pause") : qsTr("Play")
                    onClicked: vlm.playPause(media.index)
                }
                WinButton {
                    visible: media.broadcast
                    iconText: VLCIcons.stop
                    toolTip.text: qsTr("Stop")
                    onClicked: vlm.stop(media.index)
                }
                WinButton {
                    visible: media.broadcast
                    checkable: true
                    checked: media.modelData.loop
                    iconText: VLCIcons.repeat_all
                    toolTip.text: qsTr("Repeat")
                    onClicked: vlm.toggleLoop(media.index)
                }
                WinButton {
                    iconText: VLCIcons.more
                    toolTip.text: qsTr("Change")
                    onClicked: root._change(media.index)
                }
                WinButton {
                    iconText: VLCIcons.del
                    toolTip.text: qsTr("Delete")
                    onClicked: {
                        if (root.editing === media.index)
                            root._clear()
                        vlm.remove(media.index)
                    }
                }
            }
        }
    }

    footerLeft: [
        WinButton {
            text: qsTr("Import")
            enabled: vlm.available
            onClicked: vlm.importConfig()
        },
        WinButton {
            text: qsTr("Export")
            enabled: vlm.available
            onClicked: vlm.exportConfig()
        }
    ]

    footer: [
        WinButton {
            text: qsTr("Close")
            onClicked: root.close()
        }
    ]
}
