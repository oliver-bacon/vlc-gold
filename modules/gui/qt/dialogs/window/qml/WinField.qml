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
import QtQuick.Templates as T

import VLC.Style

// text input: well with a 2px surface border, accent while editing
T.TextField {
    id: field

    implicitWidth: WinStyle.controlWidth
    implicitHeight: WinStyle.fieldHeight
    leftPadding: VLCStyle.dp(12, VLCStyle.scale)
    rightPadding: VLCStyle.dp(12, VLCStyle.scale)
    verticalAlignment: TextInput.AlignVCenter
    opacity: enabled ? 1.0 : 0.4

    color: WinStyle.text
    selectionColor: WinStyle.selected
    selectedTextColor: WinStyle.strongText
    placeholderTextColor: Qt.alpha(WinStyle.text, 0.4)
    font.pixelSize: VLCStyle.fontSize_large
    selectByMouse: true

    background: Rectangle {
        color: WinStyle.well
        radius: WinStyle.radius
        border.width: VLCStyle.dp(2, VLCStyle.scale)
        border.color: field.activeFocus ? WinStyle.accent : WinStyle.surface

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
