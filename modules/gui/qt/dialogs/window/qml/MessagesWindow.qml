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
import VLC.Dialogs
import VLC.Style

// "Messages" (classic dialogs/messages): VLC's log from the moment the
// window was first opened, with Verbosity and Filter, Save as...; the error
// dialogs shown so far; the modules tree (Update); the queue as a tree in
// debug builds. Click selects lines (Ctrl / Shift: several), Ctrl+C copies.
// Resizable as the classic one.
RedesignWindow {
    id: root

    title: qsTr("Messages")

    resizable: true
    initialHeight: VLCStyle.dp(620, VLCStyle.scale)

    tabs: {
        const list = [
            { "text": qsTr("Messages"), "icon": "view_list_view" },
            { "text": qsTr("Errors"), "icon": "folder_info" },
            { "text": qsTr("Modules Tree"), "icon": "view_grid_view" }
        ]
        if (messages.debugBuild)
            list.push({ "text": qsTr("Playlist Tree"), "icon": "player_playlist" })
        return list
    }

    MessagesModel {
        id: messages
        ctx: MainCtx
    }

    property string saveError: ""

    // DialogsProvider: { tab: 0 messages, 1 errors, ... }
    function reset(args) {
        currentTab = Math.max(0, Math.min(tabs.length - 1, args?.tab ?? 0))
        saveError = ""
    }

    onCurrentTabChanged: {
        saveError = ""
        if (currentTab === 2 && objectTree.length === 0)
            _updateObjectTree()
        else if (currentTab === 3)
            playlistTree = messages.playlistTree()
    }

    // ---- Messages -------------------------------------------------------------

    property var selection: []
    property int anchorRow: -1

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
    }

    Connections {
        target: messages
        function onModelReset() {
            root.selection = []
            root.anchorRow = -1
        }
    }

    function _escape(s) {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    readonly property var _typeColors: ({
        "info": WinStyle.view.fg.primary,
        "error": WinStyle.negative,
        "warning": VLCStyle.palette.orange500 ?? WinStyle.accent,
        "debug": WinStyle.mutedText
    })

    // ---- Errors -------------------------------------------------------------------

    // Clear hides the errors shown so far (they stay in VLC's list)
    property int errorsCleared: 0

    // ---- Modules tree ---------------------------------------------------------------

    property var objectTree: []
    // indexes of collapsed rows
    property var collapsed: ({})

    function _updateObjectTree() {
        objectTree = messages.objectTree()
        collapsed = ({})
    }

    readonly property var _shownTree: {
        const out = []
        let hideBelow = -1
        for (let i = 0; i < objectTree.length; ++i) {
            const node = objectTree[i]
            if (hideBelow >= 0) {
                if (node.depth > hideBelow)
                    continue
                hideBelow = -1
            }
            const hasChildren = i + 1 < objectTree.length && objectTree[i + 1].depth > node.depth
            out.push({ "index": i, "text": node.text, "depth": node.depth, "hasChildren": hasChildren,
                       "collapsed": !!collapsed[i] })
            if (collapsed[i])
                hideBelow = node.depth
        }
        return out
    }

    // ---- Playlist tree (debug) -------------------------------------------------------

    property var playlistTree: []

    // ---- pages -------------------------------------------------------------------------

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: root.currentTab

        // Messages
        ColumnLayout {
            spacing: VLCStyle.margin_small

            RowLayout {
                Layout.fillWidth: true
                spacing: VLCStyle.margin_small

                WinLabel { text: qsTr("Verbosity") }

                WinDropdown {
                    implicitWidth: VLCStyle.dp(170, VLCStyle.scale)
                    model: [
                        { "value": 0, "text": qsTr("0 (errors)") },
                        { "value": 1, "text": qsTr("1 (warnings)") },
                        { "value": 2, "text": qsTr("2 (debug)") }
                    ]
                    source: messages.verbosity
                    onPicked: (v) => messages.verbosity = v
                }

                WinLabel {
                    Layout.leftMargin: VLCStyle.margin_small
                    text: qsTr("Filter")
                }

                WinField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("Show only the lines that contain…")
                    text: messages.filter
                    onTextEdited: messages.filter = text
                }
            }

            WinList {
                id: logFrame

                Layout.fillWidth: true
                Layout.fillHeight: true
                model: messages
                emptyText: messages.filter !== "" ? qsTr("No messages match the filter.") : qsTr("No messages yet.")

                // follow the end while it is shown (as the classic log)
                property bool follow: true
                Connections {
                    target: logFrame.list
                    function onContentYChanged() {
                        if (!logFrame.list.moving && !logFrame.list.dragging && logFrame._autoScrolling)
                            return
                        logFrame.follow = logFrame.list.atYEnd
                    }
                }
                property bool _autoScrolling: false
                Connections {
                    target: messages
                    function onAppended() {
                        if (!logFrame.follow)
                            return
                        logFrame._autoScrolling = true
                        Qt.callLater(() => {
                            logFrame.list.positionViewAtEnd()
                            logFrame._autoScrolling = false
                        })
                    }
                }

                Keys.onPressed: (event) => {
                    if (event.matches(StandardKey.Copy)) {
                        messages.copyRows(root.selection)
                        event.accepted = true
                    } else if (event.matches(StandardKey.SelectAll)) {
                        root.selection = Array.from({ length: logFrame.count }, (_, i) => i)
                        event.accepted = true
                    }
                }

                delegate: T.ItemDelegate {
                    id: logLine

                    required property int index
                    // `text` is a property of the delegate: the roles come from `model`
                    required property var model
                    readonly property string module: model.module
                    readonly property string type: model.type
                    readonly property string message: model.text

                    readonly property bool selected: root.selection.indexOf(index) >= 0

                    width: ListView.view.width
                    // templates have no implicit size: the lines lay on top of each other
                    implicitHeight: implicitContentHeight + topPadding + bottomPadding
                    leftPadding: VLCStyle.margin_small
                    rightPadding: VLCStyle.margin_small
                    topPadding: VLCStyle.dp(3, VLCStyle.scale)
                    bottomPadding: VLCStyle.dp(3, VLCStyle.scale)

                    // with the modifiers of the click
                    MouseArea {
                        anchors.fill: parent
                        onClicked: (mouse) => {
                            root._click(logLine.index, mouse.modifiers)
                            logLine.ListView.view.forceActiveFocus()
                        }
                    }

                    background: Rectangle {
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: logLine.selected ? WinStyle.selected : "transparent"
                    }

                    contentItem: T.Label {
                        textFormat: Text.StyledText
                        wrapMode: Text.WrapAnywhere
                        font.pixelSize: VLCStyle.fontSize_normal
                        font.family: "monospace"
                        color: WinStyle.text
                        text: "<i><font color=\"" + WinStyle.accent + "\">" + root._escape(logLine.module) + "</font> "
                              + "<font color=\"" + (root._typeColors[logLine.type] ?? WinStyle.mutedText) + "\">"
                              + logLine.type + ":</font></i> " + root._escape(logLine.message)
                    }
                }
            }
        }

        // Errors
        WinList {
            id: errorFrame

            model: DialogErrorModel
            emptyText: qsTr("No errors.")

            delegate: T.ItemDelegate {
                id: errorLine

                required property int index
                required property var model

                width: ListView.view.width
                visible: index >= root.errorsCleared
                implicitHeight: implicitContentHeight + topPadding + bottomPadding
                height: visible ? implicitHeight : 0
                leftPadding: VLCStyle.margin_small
                rightPadding: VLCStyle.margin_small
                topPadding: VLCStyle.dp(4, VLCStyle.scale)
                bottomPadding: VLCStyle.dp(4, VLCStyle.scale)
                background: null

                contentItem: TextEdit {
                    readOnly: true
                    selectByMouse: true
                    wrapMode: Text.Wrap
                    textFormat: TextEdit.RichText
                    font.pixelSize: VLCStyle.fontSize_large
                    color: WinStyle.text
                    selectionColor: WinStyle.selected
                    selectedTextColor: WinStyle.strongText
                    text: "<i><font color=\"" + WinStyle.negative + "\">" + root._escape(errorLine.model.title) + ":</font></i> "
                          + root._escape(errorLine.model.text)
                }
            }
        }

        // Modules tree
        WinList {
            id: treeFrame

            model: root._shownTree

            delegate: T.ItemDelegate {
                id: node

                required property var modelData
                required property int index

                width: ListView.view.width
                implicitHeight: VLCStyle.dp(30, VLCStyle.scale)
                leftPadding: VLCStyle.margin_small + node.modelData.depth * VLCStyle.dp(18, VLCStyle.scale)
                rightPadding: VLCStyle.margin_small

                onClicked: {
                    if (!node.modelData.hasChildren)
                        return
                    const c = Object.assign({}, root.collapsed)
                    if (c[node.modelData.index]) delete c[node.modelData.index]
                    else c[node.modelData.index] = true
                    root.collapsed = c
                }

                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: node.hovered ? Qt.alpha(WinStyle.surface, 0.6) : "transparent"
                }

                contentItem: RowLayout {
                    spacing: VLCStyle.dp(4, VLCStyle.scale)

                    T.Label {
                        Layout.preferredWidth: VLCStyle.dp(16, VLCStyle.scale)
                        text: node.modelData.hasChildren ? (node.modelData.collapsed ? "▸" : "▾") : ""
                        color: WinStyle.mutedText
                        font.pixelSize: VLCStyle.fontSize_normal
                    }
                    TextEdit {
                        Layout.fillWidth: true
                        readOnly: true
                        selectByMouse: true
                        text: node.modelData.text
                        color: WinStyle.text
                        selectionColor: WinStyle.selected
                        selectedTextColor: WinStyle.strongText
                        font.pixelSize: VLCStyle.fontSize_normal
                        font.family: "monospace"
                        clip: true
                    }
                }
            }
        }

        // Playlist tree (debug builds)
        WinList {
            id: playlistFrame

            columns: [
                { "title": "Name", "width": 0 },
                { "title": "PL id", "width": VLCStyle.dp(70, VLCStyle.scale) },
                { "title": "Item id", "width": VLCStyle.dp(150, VLCStyle.scale) },
                { "title": "PL flags", "width": VLCStyle.dp(90, VLCStyle.scale) }
            ]
            model: root.playlistTree

            delegate: WinListRow {
                required property var modelData
                frame: playlistFrame
                cells: [modelData.name, modelData.index, modelData.item, modelData.type]
                WinToolTip { text: modelData.uri }
            }
        }
    }

    footerLeft: [
        WinButton {
            visible: root.currentTab === 0
            text: qsTr("Save as...")
            toolTip.text: qsTr("Saves all the displayed logs to a file")
            onClicked: root.saveError = messages.save()
        },
        WinButton {
            text: root.currentTab > 1 ? qsTr("Update") : qsTr("Clear")
            toolTip.text: root.currentTab > 1 ? qsTr("Update the tree")
                                              : root.currentTab === 0 ? qsTr("Clear the messages")
                                                                      : qsTr("Clear the errors")
            onClicked: {
                if (root.currentTab === 0)
                    messages.clear()
                else if (root.currentTab === 1)
                    root.errorsCleared = DialogErrorModel.count
                else if (root.currentTab === 2)
                    root._updateObjectTree()
                else
                    root.playlistTree = messages.playlistTree()
            }
        },
        WinLabel {
            visible: root.saveError !== ""
            Layout.maximumWidth: VLCStyle.dp(320, VLCStyle.scale)
            text: root.saveError
            color: WinStyle.negative
            font.pixelSize: VLCStyle.fontSize_normal
        }
    ]

    footer: [
        WinButton {
            text: qsTr("Close")
            onClicked: root.close()
        }
    ]
}
