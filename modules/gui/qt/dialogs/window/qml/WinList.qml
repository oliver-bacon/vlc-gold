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

// list in a well, with optional column headers. Columns: [{ title, width }]
// (width 0 = the rest). The delegate is the caller's; WinListRow draws the
// usual row with its cells.
Rectangle {
    id: frame

    property var columns: []
    property alias model: list.model
    property alias delegate: list.delegate
    property alias currentIndex: list.currentIndex
    property alias list: list
    property alias count: list.count
    property string emptyText: ""
    // the header was clicked: sort by that column
    signal headerClicked(int column)
    property int sortColumn: -1
    property bool sortDescending: false

    implicitHeight: VLCStyle.dp(240, VLCStyle.scale)
    radius: WinStyle.radius
    color: WinStyle.well
    border.width: VLCStyle.dp(2, VLCStyle.scale)
    border.color: list.activeFocus ? WinStyle.accent : WinStyle.surface
    clip: true

    // x and width of each column for a row of `width`
    function columnGeometry(index, width) {
        let fixed = 0
        let fill = 0
        for (const c of columns) {
            if (c.width > 0) fixed += c.width
            else ++fill
        }
        const rest = Math.max(0, width - fixed) / Math.max(1, fill)
        let x = 0
        for (let i = 0; i < columns.length; ++i) {
            const w = columns[i].width > 0 ? columns[i].width : rest
            if (i === index)
                return { "x": x, "width": w }
            x += w
        }
        return { "x": 0, "width": width }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)
            visible: frame.columns.length > 0
            color: WinStyle.surface
            radius: VLCStyle.dp(4, VLCStyle.scale)

            Repeater {
                model: frame.columns

                T.AbstractButton {
                    id: header

                    required property var modelData
                    required property int index
                    readonly property var _geo: frame.columnGeometry(index, parent.width - 2 * VLCStyle.margin_small)

                    x: VLCStyle.margin_small + _geo.x
                    width: _geo.width
                    height: parent.height
                    onClicked: frame.headerClicked(index)

                    contentItem: T.Label {
                        text: header.modelData.title
                              + (frame.sortColumn === header.index ? (frame.sortDescending ? "  ▾" : "  ▴") : "")
                        verticalAlignment: Text.AlignVCenter
                        color: header.hovered ? WinStyle.strongText : WinStyle.mutedText
                        font.pixelSize: VLCStyle.fontSize_normal
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        rightPadding: VLCStyle.margin_xsmall
                    }
                    background: null
                }
            }
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: true
            focus: true
            currentIndex: -1
            highlightMoveDuration: 0
            T.ScrollBar.vertical: WinScrollBar { }

            T.Label {
                anchors.centerIn: parent
                visible: list.count === 0 && frame.emptyText !== ""
                text: frame.emptyText
                color: WinStyle.mutedText
                font.pixelSize: VLCStyle.fontSize_large
            }
        }
    }
}
