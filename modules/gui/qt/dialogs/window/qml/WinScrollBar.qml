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

// thin scroll bar in the colors of the window, wider while used
T.ScrollBar {
    id: bar

    readonly property bool _used: bar.hovered || bar.pressed

    // templates have no size of their own
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    policy: T.ScrollBar.AsNeeded
    padding: VLCStyle.dp(2, VLCStyle.scale)
    minimumSize: 0.1

    background: Rectangle {
        radius: width / 2
        visible: bar._used && bar.size < 1.0
        color: WinStyle.surface
    }
    contentItem: Rectangle {
        implicitWidth: bar._used ? VLCStyle.scrollBarInteractingSize : VLCStyle.scrollBarNonInteractingSize
        implicitHeight: implicitWidth
        radius: width / 2
        visible: bar.size < 1.0
        color: Qt.alpha(WinStyle.text, bar._used ? 0.8 : 0.5)

        Behavior on implicitWidth {
            NumberAnimation { duration: VLCStyle.duration_veryShort; easing.type: Easing.OutSine }
        }
    }
}
