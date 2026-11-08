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

// small check box with its text (lists, inline choices)
T.CheckBox {
    id: check

    implicitWidth: implicitIndicatorWidth + (text !== "" ? spacing + contentItem.implicitWidth : 0)
    implicitHeight: Math.max(VLCStyle.dp(28, VLCStyle.scale), contentItem.implicitHeight)
    spacing: VLCStyle.margin_xsmall
    opacity: enabled ? 1.0 : 0.4

    indicator: Rectangle {
        implicitWidth: VLCStyle.dp(20, VLCStyle.scale)
        implicitHeight: implicitWidth
        anchors.verticalCenter: parent.verticalCenter
        radius: VLCStyle.dp(4, VLCStyle.scale)
        color: check.checked ? WinStyle.selected : WinStyle.well
        border.width: check.visualFocus ? VLCStyle.focus_border : VLCStyle.dp(2, VLCStyle.scale)
        border.color: check.visualFocus ? WinStyle.focus : (check.checked ? WinStyle.accent : WinStyle.surface)

        T.Label {
            anchors.centerIn: parent
            visible: check.checkState !== Qt.Unchecked
            text: check.checkState === Qt.PartiallyChecked ? "–" : VLCIcons.check
            font.family: check.checkState === Qt.PartiallyChecked ? undefined : VLCIcons.fontFamily
            font.pixelSize: VLCStyle.icon_xsmall
            color: WinStyle.accent
        }
    }

    contentItem: T.Label {
        leftPadding: check.text !== "" ? check.indicator.width + check.spacing : 0
        verticalAlignment: Text.AlignVCenter
        text: check.text
        color: WinStyle.text
        font.pixelSize: VLCStyle.fontSize_large
        elide: Text.ElideRight
    }
}
