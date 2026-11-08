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

import VLC.Style

// footer bar of a redesigned dialog (as RedesignWindow's): buttons on the
// right (children), `left` items on the left
Rectangle {
    id: bar

    default property alias buttons: buttonRow.data
    property alias left: leftRow.data

    implicitHeight: VLCStyle.dp(60, VLCStyle.scale)
    implicitWidth: leftRow.implicitWidth + buttonRow.implicitWidth + 3 * VLCStyle.margin_large
    color: WinStyle.window.bg.secondary

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: VLCStyle.margin_large
        anchors.rightMargin: VLCStyle.margin_large
        spacing: VLCStyle.margin_xsmall

        RowLayout {
            id: leftRow
            spacing: VLCStyle.margin_xsmall
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            id: buttonRow
            spacing: VLCStyle.margin_xsmall
        }
    }
}
