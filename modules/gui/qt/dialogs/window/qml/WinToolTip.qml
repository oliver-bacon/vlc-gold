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

// tool tip over its parent item, shown while it is hovered
HoverHandler {
    id: hover

    property string text

    property T.ToolTip tip: T.ToolTip {
        parent: hover.parent
        visible: hover.hovered && hover.text !== ""
        delay: VLCStyle.delayToolTipAppear
        text: hover.text
        y: -height - VLCStyle.dp(6, VLCStyle.scale)
        implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
        implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
        width: Math.min(implicitWidth, VLCStyle.dp(420, VLCStyle.scale))
        padding: VLCStyle.margin_small
        contentItem: T.Label {
            text: hover.text
            color: WinStyle.strongText
            wrapMode: Text.WordWrap
            font.pixelSize: VLCStyle.fontSize_normal
        }
        background: Rectangle {
            color: WinStyle.window.bg.primary
            radius: WinStyle.radius
            border.width: VLCStyle.dp(2, VLCStyle.scale)
            border.color: WinStyle.well
        }
    }
}
