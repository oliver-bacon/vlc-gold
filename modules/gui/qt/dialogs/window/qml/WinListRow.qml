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

// a row of a WinList: selected = list.currentIndex; `cells` are the texts
// of the columns (or set `contentItem` for something else)
T.ItemDelegate {
    id: row

    required property int index
    property WinList frame
    property var cells: []
    property bool muted: false

    signal activated()

    width: ListView.view ? ListView.view.width : 0
    implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
    highlighted: ListView.view && ListView.view.currentIndex === index
    leftPadding: VLCStyle.margin_small
    rightPadding: VLCStyle.margin_small

    onClicked: {
        if (ListView.view) {
            ListView.view.currentIndex = index
            ListView.view.forceActiveFocus()
        }
    }
    onDoubleClicked: activated()
    Keys.onReturnPressed: activated()

    background: Rectangle {
        radius: VLCStyle.dp(4, VLCStyle.scale)
        color: row.highlighted ? WinStyle.selected
                               : (row.hovered ? Qt.alpha(WinStyle.surface, 0.6) : "transparent")
    }

    contentItem: Item {
        Repeater {
            model: row.cells

            T.Label {
                required property var modelData
                required property int index
                readonly property var _geo: row.frame ? row.frame.columnGeometry(index, row.availableWidth)
                                                      : { "x": 0, "width": row.availableWidth }

                x: _geo.x
                width: _geo.width
                height: parent.height
                rightPadding: VLCStyle.margin_xsmall
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: row.highlighted ? WinStyle.strongText : (row.muted ? WinStyle.mutedText : WinStyle.text)
                font.pixelSize: VLCStyle.fontSize_large
                elide: Text.ElideRight
            }
        }
    }
}
