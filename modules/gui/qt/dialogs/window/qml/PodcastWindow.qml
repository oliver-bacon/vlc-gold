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

// Podcast configuration (classic dialogs/podcast): the podcast URLs
// ("podcast-urls", separated by |), Add, Delete; Close keeps the list,
// Cancel (or Escape) drops the changes.
RedesignWindow {
    id: root

    title: qsTr("Podcast Configuration")
    fitWidth: VLCStyle.dp(640, VLCStyle.scale)

    property var urls: []

    function reset(args) {
        const value = String(VLCConfig.value("podcast-urls") ?? "")
        urls = value !== "" ? value.split("|") : []
        urlField.text = ""
        urlList.currentIndex = -1
    }

    function _add() {
        if (urlField.text === "")
            return
        urls = urls.concat([urlField.text])
        urlField.text = ""
    }

    function _accept() {
        VLCConfig.setValue("podcast-urls", urls.join("|"))
        close()
    }

    WinSectionTitle { text: qsTr("Podcast URLs list") }

    WinRow {
        label: qsTr("URL")

        WinField {
            id: urlField
            implicitWidth: WinStyle.controlWidth - VLCStyle.dp(100, VLCStyle.scale) - VLCStyle.margin_xsmall
            onAccepted: root._add()
        }
        WinButton {
            text: qsTr("Add")
            enabled: urlField.text !== ""
            onClicked: root._add()
        }
    }

    WinList {
        id: urlFrame

        Layout.fillWidth: true
        Layout.topMargin: VLCStyle.margin_small
        Layout.preferredHeight: VLCStyle.dp(220, VLCStyle.scale)
        model: root.urls
        emptyText: qsTr("No podcasts.")


        delegate: WinListRow {
            required property var modelData
            cells: [modelData]
        }
    }

    readonly property ListView urlList: urlFrame.list

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: VLCStyle.margin_small

        Item { Layout.fillWidth: true }

        WinButton {
            text: qsTr("Delete")
            toolTip.text: qsTr("Deletes the selected item")
            enabled: root.urlList.currentIndex >= 0
            onClicked: {
                const list = root.urls.slice()
                list.splice(root.urlList.currentIndex, 1)
                root.urls = list
                root.urlList.currentIndex = -1
            }
        }
    }

    footer: [
        WinButton {
            text: qsTr("Cancel")
            onClicked: root.close()
        },
        WinButton {
            text: qsTr("Close")
            highlighted: true
            onClicked: root._accept()
        }
    ]
}
