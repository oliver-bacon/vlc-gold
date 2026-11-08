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

// "Add to Playlist" (classic dialogs/playlists): pick an existing playlist
// (double-click adds at once) or type the name of a new one; OK adds the
// media, the footer shows how many. Picking a playlist clears the name and
// typing a name clears the pick, as the classic dialog. Only with a media
// library (DialogsProvider asserts it).
RedesignWindow {
    id: root

    title: qsTr("Add to Playlist")
    fitWidth: VLCStyle.dp(600, VLCStyle.scale)

    // what to add: MLItemIds or input items (MLPlaylistListModel::append)
    property var medias: []
    property var model: null

    readonly property bool canAccept: newName.text !== "" || playlists.currentIndex >= 0

    // DialogsProvider: { medias, type }
    function reset(args) {
        medias = args?.medias ?? []
        if (!model && MainCtx.mediaLibraryAvailable) {
            model = Qt.createQmlObject("import VLC.MediaLibrary; MLPlaylistListModel { }", root)
            model.ml = MainCtx.mediaLibrary
        }
        if (model)
            model.playlistType = args?.type ?? 0
        newName.text = ""
        playlists.currentIndex = -1
    }

    function _accept() {
        if (!model || !canAccept)
            return
        const name = newName.text
        if (name !== "")
            model.create(name, medias)
        else
            model.append(model.getItemId(playlists.currentIndex), medias)
        close()
    }

    WinSectionTitle { text: qsTr("Existing Playlist") }

    WinList {
        id: playlistFrame

        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.dp(260, VLCStyle.scale)
        columns: [
            { "title": qsTr("Name"), "width": 0 },
            { "title": qsTr("Tracks"), "width": VLCStyle.dp(80, VLCStyle.scale) }
        ]
        model: root.model
        emptyText: qsTr("No playlists yet.")

        delegate: WinListRow {
            id: playlistRow

            required property string name
            required property int count

            frame: playlistFrame
            cells: [name, String(count)]
            onClicked: newName.text = ""
            onActivated: root._accept()
        }
    }

    readonly property ListView playlists: playlistFrame.list

    WinRow {
        Layout.topMargin: VLCStyle.margin_small
        label: qsTr("New Playlist")

        WinField {
            id: newName
            onTextEdited: root.playlists.currentIndex = -1
            onAccepted: root._accept()
        }
    }

    footerLeft: [
        WinLabel {
            text: qsTr("%1 Media").arg(root.medias.length)
            color: WinStyle.mutedText
        }
    ]

    footer: [
        WinButton {
            text: qsTr("Cancel")
            onClicked: root.close()
        },
        WinButton {
            text: qsTr("OK")
            highlighted: true
            enabled: root.canAccept
            onClicked: root._accept()
        }
    ]
}
