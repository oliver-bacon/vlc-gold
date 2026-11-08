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

// ON/OFF switch (Figma "Toggle": 68x32)
T.AbstractButton {
    id: toggle

    checkable: true
    implicitWidth: VLCStyle.dp(68, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
    opacity: enabled ? 1.0 : 0.4

    readonly property real _inset: VLCStyle.dp(3, VLCStyle.scale)
    readonly property real _knob: height - 2 * _inset

    background: Rectangle {
        color: WinStyle.well
        radius: WinStyle.radius
        border.width: toggle.visualFocus ? VLCStyle.focus_border : 0
        border.color: WinStyle.focus

        Rectangle {
            x: toggle.checked ? toggle._inset : (toggle.width - width - toggle._inset)
            anchors.verticalCenter: parent.verticalCenter
            width: toggle.width - toggle._knob - 3 * toggle._inset
            height: toggle._knob
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: toggle.checked ? WinStyle.selected : WinStyle.surface

            T.Label {
                anchors.centerIn: parent
                text: toggle.checked ? qsTr("ON") : qsTr("OFF")
                font.pixelSize: VLCStyle.fontSize_normal
                color: toggle.checked ? WinStyle.accent : WinStyle.mutedText
            }
        }

        Rectangle {
            x: toggle.checked ? (toggle.width - width - toggle._inset) : toggle._inset
            anchors.verticalCenter: parent.verticalCenter
            width: toggle._knob
            height: toggle._knob
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: toggle.checked ? Qt.darker(WinStyle.accent, 1.23) : WinStyle.view.border

            Behavior on x {
                NumberAnimation { duration: VLCStyle.duration_veryShort; easing.type: Easing.InOutSine }
            }
        }
    }
}
