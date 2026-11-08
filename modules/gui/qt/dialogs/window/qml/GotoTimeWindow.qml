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

import VLC.Player
import VLC.Style

// "Go to Time" (classic dialogs/gototime): hours, minutes and seconds of the
// playing media, Reset to 0, Go seeks there. Opens with the current time.
RedesignWindow {
    id: root

    title: qsTr("Go to Time")

    readonly property bool canGo: Player.isStarted && Player.seekable

    // QTimeEdit of the classic dialog: 00:00:00 to 23:59:59
    function _set(ms) {
        const s = Math.max(0, Math.floor(ms / 1000))
        hours.value = Math.min(23, Math.floor(s / 3600))
        minutes.value = Math.floor(s / 60) % 60
        seconds.value = s % 60
    }

    // DialogsProvider: opened (or hidden) by the menu and Ctrl+T
    function reset(args) {
        _set(Player.isStarted ? Player.time.toMilliseconds() : 0)
    }

    onVisibleChanged: if (visible) hours.field.forceActiveFocus()

    function _go() {
        if (!canGo)
            return
        hours._commit(); minutes._commit(); seconds._commit()
        Player.setTimeMs(((hours.value * 60 + minutes.value) * 60 + seconds.value) * 1000)
        close()
    }

    Shortcut {
        sequences: ["Return", "Enter"]
        onActivated: root._go()
    }

    WinRow {
        label: qsTr("Go to time")

        WinNumberField { id: hours; from: 0; to: 23; unit: qsTr("h"); fieldWidth: VLCStyle.dp(64, VLCStyle.scale) }
        WinNumberField { id: minutes; from: 0; to: 59; unit: qsTr("m"); fieldWidth: VLCStyle.dp(64, VLCStyle.scale) }
        WinNumberField { id: seconds; from: 0; to: 59; unit: qsTr("s"); fieldWidth: VLCStyle.dp(64, VLCStyle.scale) }

        WinButton {
            text: qsTr("Reset")
            onClicked: root._set(0)
        }
    }

    footer: [
        WinButton {
            text: qsTr("Cancel")
            onClicked: root.close()
        },
        WinButton {
            text: qsTr("Go")
            highlighted: true
            enabled: root.canGo
            onClicked: root._go()
        }
    ]
}
