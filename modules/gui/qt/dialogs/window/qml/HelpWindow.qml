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

import VLC.MainInterface
import VLC.Style

// "Help" (classic dialogs/help): VLC's help text with its links, Close.
// Resizable as the classic one.
RedesignWindow {
    id: root

    title: qsTr("Help")

    resizable: true
    fitWidth: VLCStyle.dp(620, VLCStyle.scale)
    initialHeight: VLCStyle.dp(560, VLCStyle.scale)

    WinTextArea {
        Layout.fillWidth: true
        Layout.fillHeight: true
        readOnly: true
        textFormat: TextEdit.RichText
        // links in the accent (rich text ignores linkColor)
        text: AboutModel.help.replace(/<a /g, "<a style=\"color:" + String(WinStyle.accent) + "\" ")
        onLinkActivated: (link) => Qt.openUrlExternally(link)
    }

    footer: [
        WinButton {
            text: qsTr("Close")
            onClicked: root.close()
        }
    ]
}
