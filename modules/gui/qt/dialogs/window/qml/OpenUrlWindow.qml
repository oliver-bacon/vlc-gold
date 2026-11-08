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

import VLC.Dialogs
import VLC.Style

// "Open URL" (classic dialogs/open/openurl, Ctrl+V / Open Location from
// Clipboard): a URL or a path, filled from the clipboard when it holds one;
// Play, Enqueue, Cancel.
RedesignWindow {
    id: root

    title: qsTr("Open URL")
    modality: Qt.WindowModal

    function reset(args) {
        urlField.text = DialogsProvider.clipboardMedia()
    }

    onVisibleChanged: if (visible) {
        urlField.forceActiveFocus()
        urlField.selectAll()
    }

    function _open(enqueue) {
        const url = urlField.text.trim()
        close()
        if (url !== "")
            DialogsProvider.openUrl(url, enqueue)
    }

    WinDescription {
        Layout.bottomMargin: VLCStyle.margin_xsmall
        text: qsTr("Please enter the URL or path to the media you want to play.")
        font.pixelSize: VLCStyle.fontSize_large
        color: WinStyle.text
    }

    WinField {
        id: urlField

        Layout.fillWidth: true
        placeholderText: qsTr("Enter URL here...")
        onAccepted: root._open(false)

        WinToolTip {
            text: qsTr("If your clipboard contains a valid URL\nor the path to a file on your computer,\nit will be automatically selected.")
        }
    }

    footer: [
        WinButton {
            text: qsTr("Cancel")
            onClicked: root.close()
        },
        WinButton {
            text: qsTr("Enqueue")
            onClicked: root._open(true)
        },
        WinButton {
            text: qsTr("Play")
            highlighted: true
            onClicked: root._open(false)
        }
    ]
}
