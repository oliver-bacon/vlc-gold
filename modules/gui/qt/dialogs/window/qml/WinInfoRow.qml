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

// a value to read (and copy): name on the left, the value on the right
RowLayout {
    id: infoRow

    property string label
    property string value

    Layout.fillWidth: true
    Layout.minimumHeight: VLCStyle.dp(38, VLCStyle.scale)
    spacing: VLCStyle.margin_small

    T.Label {
        Layout.preferredWidth: parent.width * 0.4
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: VLCStyle.dp(9, VLCStyle.scale)
        text: infoRow.label
        color: WinStyle.mutedText
        font.pixelSize: VLCStyle.fontSize_large
        elide: Text.ElideRight
    }

    WinValueText {
        Layout.fillWidth: true
        // the rest of the row, however long the value
        Layout.preferredWidth: 0
        Layout.topMargin: VLCStyle.dp(9, VLCStyle.scale)
        Layout.bottomMargin: VLCStyle.dp(9, VLCStyle.scale)
        text: infoRow.value
        wrapMode: Text.Wrap
    }
}
