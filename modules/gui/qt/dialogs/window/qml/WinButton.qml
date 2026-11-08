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

// button of the settings window; highlighted = the main one
T.Button {
    id: button

    // an icon font glyph instead of text (VLCIcons)
    property string iconText: ""

    implicitWidth: iconText !== "" && text === ""
                   ? implicitHeight
                   : Math.max(VLCStyle.dp(100, VLCStyle.scale), contentItem.implicitWidth + VLCStyle.dp(28, VLCStyle.scale))
    implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
    font.pixelSize: VLCStyle.fontSize_large
    font.weight: Font.DemiBold

    Accessible.name: text !== "" ? text : (toolTip.text ?? "")

    property alias toolTip: tip

    WinToolTip { id: tip }

    background: Rectangle {
        radius: WinStyle.radius
        readonly property color fill: (button.highlighted || button.checked) ? WinStyle.selected : WinStyle.surface
        color: button.hovered && button.enabled ? Qt.lighter(fill, 1.2) : fill
        border.width: button.visualFocus ? VLCStyle.focus_border : 0
        border.color: WinStyle.focus
    }
    contentItem: T.Label {
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: button.iconText !== "" && button.text === "" ? button.iconText : button.text
        font.family: button.iconText !== "" && button.text === "" ? VLCIcons.fontFamily : button.font.family
        font.pixelSize: button.iconText !== "" && button.text === "" ? VLCStyle.icon_normal : button.font.pixelSize
        font.weight: button.font.weight
        opacity: button.enabled ? 1.0 : 0.4
        color: (button.highlighted || button.checked) ? WinStyle.accent : WinStyle.text
    }
}
