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

// "Program Guide" (classic dialogs/epg): the programs of the playing stream
// as rows, their events on a time line (hours above, the stream's time as a
// line), the selected event's title and description below. Double-click an
// event to switch to its program. "No EPG Data Available" without data.
RedesignWindow {
    id: root

    title: qsTr("Program Guide")

    resizable: true
    fitWidth: VLCStyle.dp(820, VLCStyle.scale)
    initialHeight: VLCStyle.dp(560, VLCStyle.scale)

    EpgModel {
        id: epg
        ctx: MainCtx
        onChanged: {
            // the selection follows its event when the guide is read again
            if (root.selected) {
                const p = programs.find((p) => p.id === root.selected.programId)
                const e = p ? p.events.find((e) => e.start === root.selected.start) : null
                root.selected = e ? Object.assign({ "programId": p.id }, e) : null
            }
        }
    }

    function reset(args) {
        epg.update()
    }

    // { programId, start, duration, name, description, rating, items }
    property var selected: null

    // as the classic view: 1/20 px per second (180 px per hour)
    readonly property real pxPerSecond: VLCStyle.dp(180, VLCStyle.scale) / 3600
    readonly property real rowHeight: VLCStyle.dp(52, VLCStyle.scale)
    readonly property real rulerHeight: VLCStyle.dp(28, VLCStyle.scale)
    readonly property real channelWidth: VLCStyle.dp(150, VLCStyle.scale)
    // the ruler starts on the hour before the first event
    readonly property real t0: Math.floor(epg.startTime / 3600) * 3600

    function _x(time) {
        return (time - t0) * pxPerSecond
    }

    function _date(seconds) {
        return new Date(seconds * 1000)
    }

    readonly property string selectedTitle: {
        if (!selected)
            return ""
        const start = _date(selected.start)
        const end = _date(selected.start + selected.duration)
        const now = new Date()
        const startText = start.toDateString() !== now.toDateString()
                ? start.toLocaleString(Qt.locale())
                : start.toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
        return "%1 - %2 : %3%4".arg(startText)
                               .arg(end.toLocaleTimeString(Qt.locale(), Locale.ShortFormat))
                               .arg(selected.name)
                               .arg(selected.rating ? qsTr(" (%1+ rated)").arg(selected.rating) : "")
    }

    function _escape(s) {
        return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    Rectangle {
        id: guide

        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: WinStyle.radius
        color: WinStyle.well
        border.width: VLCStyle.dp(2, VLCStyle.scale)
        border.color: WinStyle.surface
        clip: true

        T.Label {
            anchors.centerIn: parent
            visible: epg.programs.length === 0
            text: qsTr("No EPG Data Available")
            color: WinStyle.mutedText
            font.pixelSize: VLCStyle.fontSize_large
        }

        Item {
            anchors.fill: parent
            anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
            visible: epg.programs.length > 0

            // hours
            Item {
                id: ruler

                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: root.channelWidth }
                height: root.rulerHeight
                clip: true

                Repeater {
                    model: Math.max(0, Math.ceil((epg.endTime - root.t0) / 3600) + 1)

                    Rectangle {
                        required property int index
                        readonly property var date: root._date(root.t0 + index * 3600)

                        x: index * 3600 * root.pxPerSecond - grid.contentX
                        width: 3600 * root.pxPerSecond
                        height: ruler.height
                        // days in alternating shades, as the classic ruler
                        color: Math.floor((date - root._date(root.t0).setHours(0, 0, 0, 0)) / 86400000) % 2 === 0
                               ? WinStyle.surface : Qt.lighter(WinStyle.surface, 1.15)

                        T.Label {
                            anchors { left: parent.left; leftMargin: VLCStyle.margin_xsmall; verticalCenter: parent.verticalCenter }
                            text: parent.date.getHours().toString().padStart(2, "0") + "h"
                                  + (parent.date.getHours() === 0 ? " " + parent.date.toLocaleDateString(Qt.locale(), "ddd dd") : "")
                            color: WinStyle.text
                            font.pixelSize: VLCStyle.fontSize_small
                        }
                    }
                }
            }

            // programs
            Item {
                id: channels

                anchors { left: parent.left; top: ruler.bottom; bottom: parent.bottom }
                width: root.channelWidth
                clip: true

                Repeater {
                    model: epg.programs

                    Rectangle {
                        required property var modelData
                        required property int index

                        y: index * root.rowHeight - grid.contentY
                        width: channels.width
                        height: root.rowHeight
                        color: WinStyle.surface
                        border.width: 0

                        T.Label {
                            anchors.fill: parent
                            anchors.leftMargin: VLCStyle.margin_small
                            anchors.rightMargin: VLCStyle.margin_xsmall
                            verticalAlignment: Text.AlignVCenter
                            text: parent.modelData.name
                            color: WinStyle.strongText
                            font.pixelSize: VLCStyle.fontSize_normal
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 1
                            color: WinStyle.well
                        }
                    }
                }
            }

            // events
            Flickable {
                id: grid

                anchors { left: channels.right; right: parent.right; top: ruler.bottom; bottom: parent.bottom }
                clip: true
                contentWidth: Math.max(width, root._x(epg.endTime) + VLCStyle.dp(40, VLCStyle.scale))
                contentHeight: Math.max(height, epg.programs.length * root.rowHeight)
                boundsBehavior: Flickable.StopAtBounds
                T.ScrollBar.vertical: WinScrollBar { }
                T.ScrollBar.horizontal: WinScrollBar { }

                Repeater {
                    model: epg.programs

                    Item {
                        id: programRow

                        required property var modelData
                        required property int index

                        y: index * root.rowHeight
                        width: grid.contentWidth
                        height: root.rowHeight

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 1
                            color: WinStyle.surface
                        }

                        Repeater {
                            model: programRow.modelData.events

                            T.AbstractButton {
                                id: eventBox

                                required property var modelData
                                readonly property bool selected: root.selected !== null
                                                                 && root.selected.programId === programRow.modelData.id
                                                                 && root.selected.start === modelData.start

                                x: root._x(modelData.start)
                                y: VLCStyle.dp(3, VLCStyle.scale)
                                width: Math.max(VLCStyle.dp(4, VLCStyle.scale), modelData.duration * root.pxPerSecond - VLCStyle.dp(2, VLCStyle.scale))
                                height: root.rowHeight - VLCStyle.dp(7, VLCStyle.scale)

                                onClicked: root.selected = Object.assign({ "programId": programRow.modelData.id }, modelData)
                                onDoubleClicked: epg.activateProgram(programRow.modelData.id)

                                WinToolTip { text: eventBox.modelData.name }

                                background: Rectangle {
                                    radius: VLCStyle.dp(4, VLCStyle.scale)
                                    color: eventBox.selected ? WinStyle.selected
                                                             : (eventBox.hovered ? Qt.lighter(WinStyle.surface, 1.2) : WinStyle.surface)
                                    border.width: eventBox.modelData.current ? VLCStyle.dp(2, VLCStyle.scale) : 0
                                    border.color: WinStyle.accent
                                }

                                contentItem: Item {
                                    clip: true

                                    T.Label {
                                        id: eventName
                                        x: VLCStyle.margin_xsmall
                                        y: VLCStyle.dp(4, VLCStyle.scale)
                                        width: parent.width - 2 * x - (ratingLabel.visible ? ratingLabel.width + VLCStyle.dp(4, VLCStyle.scale) : 0)
                                        text: eventBox.modelData.name
                                        color: eventBox.selected ? WinStyle.strongText : WinStyle.text
                                        font.pixelSize: VLCStyle.fontSize_normal
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    T.Label {
                                        id: ratingLabel
                                        anchors { right: parent.right; rightMargin: VLCStyle.margin_xsmall; top: eventName.top }
                                        visible: eventBox.modelData.rating > 0
                                        text: eventBox.modelData.rating + "+"
                                        color: WinStyle.accent
                                        font.pixelSize: VLCStyle.fontSize_small
                                    }
                                    T.Label {
                                        x: VLCStyle.margin_xsmall
                                        anchors { top: eventName.bottom; topMargin: VLCStyle.dp(2, VLCStyle.scale) }
                                        width: parent.width - 2 * x
                                        text: root._date(eventBox.modelData.start).toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                                              + " – " + root._date(eventBox.modelData.start + eventBox.modelData.duration).toLocaleTimeString(Qt.locale(), Locale.ShortFormat)
                                        color: WinStyle.mutedText
                                        font.pixelSize: VLCStyle.fontSize_small
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }

                // the time of the stream
                Rectangle {
                    visible: epg.epgTime > 0
                    x: root._x(epg.epgTime)
                    width: VLCStyle.dp(2, VLCStyle.scale)
                    height: grid.contentHeight
                    color: WinStyle.negative
                    opacity: 0.8
                }
            }
        }
    }

    // ---- description --------------------------------------------------------------

    WinSectionTitle {
        text: qsTr("Description")
    }

    WinLabel {
        Layout.fillWidth: true
        Layout.bottomMargin: VLCStyle.margin_xsmall
        wrapMode: Text.WordWrap
        color: WinStyle.strongText
        text: root.selected ? root.selectedTitle : qsTr("Title")
        opacity: root.selected ? 1 : 0.5
    }

    WinTextArea {
        id: descriptionText

        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.dp(110, VLCStyle.scale)
        readOnly: true
        textFormat: TextEdit.RichText
        text: {
            if (!root.selected)
                return ""
            let html = root._escape(root.selected.description).replace(/\n/g, "<br/>")
            for (const item of root.selected.items ?? [])
                html += "<br/><b>%1:</b> %2".arg(root._escape(item.key)).arg(root._escape(item.value))
            return html
        }
        onTextChanged: flickable.contentY = 0
    }

    footer: [
        WinButton {
            text: qsTr("Close")
            onClicked: root.close()
        }
    ]
}
