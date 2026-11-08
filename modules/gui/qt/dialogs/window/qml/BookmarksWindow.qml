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

import VLC.MainInterface
import VLC.Player
import VLC.Style

// "Edit Bookmarks" (classic dialogs/bookmarks): the bookmarks of the playing
// media with Name, Time, Description; Create (at the current time), Delete
// (the selected ones), Clear, Close. Click selects (Ctrl / Shift: several),
// double-click or Enter jumps there; double-click a name or description (or
// click it again once selected) to edit it. The headers sort by name or
// time; a third click on a header goes back to the order of creation.
// Opened only with a media library (DialogsProvider).
RedesignWindow {
    id: root

    title: qsTr("Edit Bookmarks")

    resizable: true
    fitWidth: VLCStyle.dp(640, VLCStyle.scale)
    initialHeight: VLCStyle.dp(420, VLCStyle.scale)

    property var model: null

    // selected rows (indexes)
    property var selection: []
    property int anchorRow: -1

    // the cell being edited: { row, column }
    property var editing: null

    closeOnEscape: editing === null

    Component.onCompleted: {
        if (MainCtx.mediaLibraryAvailable) {
            model = Qt.createQmlObject("import VLC.MediaLibrary; MLBookmarkModel { }", root)
            model.player = Player
            model.ml = MainCtx.mediaLibrary
        }
    }

    Connections {
        target: root.model
        function onModelReset() { root._clearSelection() }
        function onRowsRemoved() { root._clearSelection() }
    }

    function reset(args) {
        _clearSelection()
    }

    onVisibleChanged: if (!visible) editing = null

    function _clearSelection() {
        selection = []
        anchorRow = -1
        editing = null
    }

    function _isSelected(row) {
        return selection.indexOf(row) >= 0
    }

    // as QAbstractItemView::ExtendedSelection
    function _click(row, modifiers) {
        if ((modifiers & Qt.ShiftModifier) && anchorRow >= 0) {
            const list = []
            for (let i = Math.min(anchorRow, row); i <= Math.max(anchorRow, row); ++i)
                list.push(i)
            selection = list
        } else if (modifiers & Qt.ControlModifier) {
            const list = selection.slice()
            const i = list.indexOf(row)
            if (i >= 0) list.splice(i, 1)
            else list.push(row)
            selection = list
            anchorRow = row
        } else {
            selection = [row]
            anchorRow = row
        }
        bookmarkList.currentIndex = row
    }

    function _activate(row) {
        if (model)
            model.select(model.index(row, 0))
    }

    function _delete() {
        if (!model || selection.length === 0)
            return
        model.remove(selection.map((row) => model.index(row, 0)))
        _clearSelection()
    }

    function _commitEdit(text) {
        if (!editing || !model)
            return
        model.setData(model.index(editing.row, editing.column), text, Qt.EditRole)
        editing = null
    }

    // header clicks: ascending, descending, then the model's order
    property int sortColumn: -1
    property bool sortDescending: false

    function _sort(column) {
        if (!model || column === 2) // no order by description (MLBookmarkModel)
            return
        if (sortColumn !== column) {
            sortColumn = column
            sortDescending = false
        } else if (!sortDescending) {
            sortDescending = true
        } else {
            sortColumn = -1
            sortDescending = false
        }
        model.sort(sortColumn, sortDescending ? Qt.DescendingOrder : Qt.AscendingOrder)
    }

    readonly property bool _canCreate: Player.playingState !== Player.PLAYING_STATE_STOPPED
                                       && Player.playingState !== Player.PLAYING_STATE_STOPPING

    Shortcut {
        sequence: StandardKey.Delete
        enabled: root.editing === null
        onActivated: root._delete()
    }

    WinList {
        id: bookmarkFrame

        Layout.fillWidth: true
        Layout.fillHeight: true

        columns: [
            { "title": qsTr("Name"), "width": 0 },
            { "title": qsTr("Time"), "width": VLCStyle.dp(110, VLCStyle.scale) },
            { "title": qsTr("Description"), "width": 0 }
        ]
        sortColumn: root.sortColumn
        sortDescending: root.sortDescending
        onHeaderClicked: (column) => root._sort(column)

        model: root.model
        emptyText: Player.isStarted ? qsTr("No bookmarks. Create one at the current time.")
                                    : qsTr("Play a media to see its bookmarks.")


        delegate: T.ItemDelegate {
            id: bookmark

            required property int index
            required property string name
            required property string time
            required property string description

            readonly property bool selected: root._isSelected(index)

            width: ListView.view.width
            implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
            leftPadding: VLCStyle.margin_small
            rightPadding: VLCStyle.margin_small

            Keys.onReturnPressed: root._activate(index)
            Keys.onEnterPressed: root._activate(index)

            background: Rectangle {
                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: bookmark.selected ? WinStyle.selected
                                         : (bookmark.hovered ? Qt.alpha(WinStyle.surface, 0.6) : "transparent")
            }

            contentItem: Item {
                Repeater {
                    model: [bookmark.name, bookmark.time, bookmark.description]

                    Item {
                        id: cell

                        required property var modelData
                        required property int index
                        readonly property var _geo: bookmarkFrame.columnGeometry(index, bookmark.availableWidth)
                        readonly property bool editable: index !== 1
                        readonly property bool isEditing: root.editing !== null
                                                          && root.editing.row === bookmark.index
                                                          && root.editing.column === index

                        x: _geo.x
                        width: _geo.width
                        height: parent.height

                        T.Label {
                            anchors.fill: parent
                            visible: !cell.isEditing
                            rightPadding: VLCStyle.margin_xsmall
                            verticalAlignment: Text.AlignVCenter
                            text: cell.modelData
                            color: bookmark.selected ? WinStyle.strongText : WinStyle.text
                            font.pixelSize: VLCStyle.fontSize_large
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton
                            onClicked: (mouse) => {
                                // a second click on a selected cell edits it (SelectedClicked)
                                const wasOnly = root.selection.length === 1 && bookmark.selected
                                root._click(bookmark.index, mouse.modifiers)
                                bookmarkFrame.list.forceActiveFocus()
                                if (wasOnly && cell.editable && mouse.modifiers === Qt.NoModifier)
                                    root.editing = { "row": bookmark.index, "column": cell.index }
                            }
                            onDoubleClicked: {
                                root._activate(bookmark.index)
                                if (cell.editable)
                                    root.editing = { "row": bookmark.index, "column": cell.index }
                            }
                        }

                        WinField {
                            anchors.fill: parent
                            anchors.topMargin: VLCStyle.dp(1, VLCStyle.scale)
                            anchors.bottomMargin: VLCStyle.dp(1, VLCStyle.scale)
                            anchors.rightMargin: VLCStyle.margin_xsmall
                            implicitHeight: parent.height
                            visible: cell.isEditing
                            leftPadding: VLCStyle.dp(6, VLCStyle.scale)
                            onVisibleChanged: if (visible) {
                                text = cell.modelData
                                selectAll()
                                forceActiveFocus()
                            }
                            onAccepted: root._commitEdit(text)
                            onActiveFocusChanged: if (!activeFocus && visible) root._commitEdit(text)
                            Keys.onEscapePressed: root.editing = null
                        }
                    }
                }
            }
        }
    }

    // the ListView inside the frame
    readonly property ListView bookmarkList: bookmarkFrame.list

    footerLeft: [
        WinButton {
            text: qsTr("Create")
            toolTip.text: qsTr("Create a new bookmark")
            enabled: root.model !== null && root._canCreate
            onClicked: root.model.add()
        },
        WinButton {
            text: qsTr("Delete")
            toolTip.text: qsTr("Delete the selected item")
            enabled: root.selection.length > 0
            onClicked: root._delete()
        },
        WinButton {
            text: qsTr("Clear")
            toolTip.text: qsTr("Delete all the bookmarks")
            enabled: bookmarkFrame.count > 0
            onClicked: {
                root.model.clear()
                root._clearSelection()
            }
        }
    ]

    footer: [
        WinButton {
            text: qsTr("Close")
            onClicked: root.close()
        }
    ]
}
