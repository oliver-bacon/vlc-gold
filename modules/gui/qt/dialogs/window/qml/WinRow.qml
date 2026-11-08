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

// label on the left, the controls (children) on the right; greyed out when
// disabled; an optional muted description under the label
RowLayout {
    id: row

    property string label
    property string description

    Layout.fillWidth: true
    Layout.minimumHeight: WinStyle.rowHeight
    spacing: VLCStyle.margin_xsmall
    opacity: enabled ? 1.0 : 0.4

    ColumnLayout {
        Layout.fillWidth: true
        Layout.rightMargin: VLCStyle.margin_small
        Layout.topMargin: row.description !== "" ? VLCStyle.margin_xxsmall : 0
        Layout.bottomMargin: row.description !== "" ? VLCStyle.margin_xxsmall : 0
        spacing: 0

        T.Label {
            Layout.fillWidth: true
            text: row.label
            color: WinStyle.text
            font.pixelSize: VLCStyle.fontSize_large
            elide: Text.ElideRight
        }
        T.Label {
            Layout.fillWidth: true
            visible: row.description !== ""
            text: row.description
            wrapMode: Text.WordWrap
            color: WinStyle.mutedText
            font.pixelSize: VLCStyle.fontSize_normal
        }
    }
}
