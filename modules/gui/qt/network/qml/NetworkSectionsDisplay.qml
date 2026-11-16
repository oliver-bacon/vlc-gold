/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
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
import VLC.Util
import VLC.Widgets as Widgets

// First page of "Network" (VLC Redesign, Figma "sidebar" frame): Add Network
// Stream, Podcasts, Radio, and the saved streams (StreamsDisplay.qml).
Widgets.PageExt {
    id: root

    title: qsTr("Network")

    hasGridListMode: true

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }
    // the tiles: the surface of buttons and cards
    readonly property ColorContext tileColorContext: ColorContext {
        id: tileTheme
        colorSet: ColorContext.Window
    }

    // VLC's services discovery modules "podcast" and "radio"
    readonly property var _sections: [
        { "title": qsTr("Podcasts"), "icon": VLCIcons.stream, "uri": ["streams", "services", "source_root"], "source": "podcast" },
        { "title": qsTr("Radio"),    "icon": VLCIcons.stream, "uri": ["streams", "services", "source_root"], "source": "radio" },
        { "title": qsTr("Saved Streams"), "icon": VLCIcons.link, "uri": ["streams", "url"] }
    ]

    // "Add Network Stream": VLC's network stream dialog
    readonly property var _entries: [{ "title": qsTr("Add Network Stream"), "icon": VLCIcons.add, "uri": null }].concat(root._sections)

    function _activate(modelData) {
        if (!modelData.uri)
            DialogsProvider.addNetworkStreamDialog()
        else if (modelData.source)
            History.push(modelData.uri, { "source_name": modelData.source })
        else
            History.push(modelData.uri)
    }

    Item {
        id: content

        anchors.fill: parent
        focus: true

        function setCurrentItemFocus(reason) {
            (MainCtx.gridView ? gridView : listView).forceActiveFocus(reason)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: VLCStyle.dynamicAppMargins(content.width) + VLCStyle.layout_left_margin
            anchors.rightMargin: VLCStyle.dynamicAppMargins(content.width) + VLCStyle.layout_right_margin
            spacing: VLCStyle.margin_xsmall

            Text {
                Layout.fillWidth: true
                text: qsTr("%1 items").arg(root._sections.length)
                color: theme.fg.secondary
                font.pixelSize: VLCStyle.fontSize_normal
            }

            GridView {
                id: gridView

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: MainCtx.gridView
                clip: true
                focus: MainCtx.gridView
                boundsBehavior: Flickable.StopAtBounds
                model: root._entries

                readonly property int _columns: Math.max(1, Math.floor(width / (VLCStyle.gridCover_video_width + VLCStyle.margin_normal)))
                cellWidth: Math.floor(width / _columns)
                cellHeight: Math.round((cellWidth - VLCStyle.margin_normal) * VLCStyle.gridCover_video_height / VLCStyle.gridCover_video_width)
                            + VLCStyle.dp(52, VLCStyle.scale)

                delegate: Entry {
                    width: GridView.view.cellWidth
                    height: GridView.view.cellHeight
                    grid: true
                }
            }

            ListView {
                id: listView

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !MainCtx.gridView
                clip: true
                focus: !MainCtx.gridView
                boundsBehavior: Flickable.StopAtBounds
                model: root._entries

                delegate: Entry {
                    width: ListView.view.width
                    height: VLCStyle.dp(48, VLCStyle.scale)
                }
            }
        }
    }

    // a section: a row in the list, a tile in the grid (like Videos)
    component Entry: T.ItemDelegate {
        id: entry

        required property var modelData
        property bool grid: false

        padding: 0
        leftPadding: grid ? 0 : VLCStyle.margin_xsmall

        Accessible.name: modelData.title

        background: Rectangle {
            radius: VLCStyle.dp(4, VLCStyle.scale)
            // list: the row lights up; grid: only the tile does
            color: !entry.grid && (entry.hovered || entry.activeFocus) ? theme.bg.secondary : "transparent"
        }

        contentItem: Item {
            // grid: a tile as wide as the cell minus the gap, its name under
            // it at the same left edge (as the Videos cards)
            ColumnLayout {
                visible: entry.grid
                anchors { left: parent.left; top: parent.top }
                width: parent.width - VLCStyle.margin_normal
                spacing: VLCStyle.margin_xsmall

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.round(width * VLCStyle.gridCover_video_height / VLCStyle.gridCover_video_width)
                    radius: VLCStyle.dp(8, VLCStyle.scale)
                    color: (entry.hovered || entry.activeFocus) ? Qt.lighter(tileTheme.bg.primary, 1.25) : tileTheme.bg.primary
                    border.width: entry.visualFocus ? VLCStyle.focus_border : 0
                    border.color: theme.visualFocus

                    Widgets.IconLabel {
                        anchors.centerIn: parent
                        text: entry.modelData.icon
                        color: (entry.hovered || entry.activeFocus) ? theme.accent : theme.fg.secondary
                        font.pixelSize: VLCStyle.dp(56, VLCStyle.scale)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: entry.modelData.title
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    color: theme.fg.primary
                    font.pixelSize: VLCStyle.fontSize_large
                }
            }

            // list: icon and name in a row
            RowLayout {
                visible: !entry.grid
                anchors.fill: parent
                spacing: VLCStyle.margin_small

                Widgets.IconLabel {
                    Layout.preferredWidth: VLCStyle.icon_normal
                    horizontalAlignment: Text.AlignHCenter
                    text: entry.modelData.icon
                    color: theme.fg.secondary
                    font.pixelSize: VLCStyle.icon_normal
                }
                Text {
                    Layout.fillWidth: true
                    text: entry.modelData.title
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    color: theme.fg.primary
                    font.pixelSize: VLCStyle.fontSize_normal
                }
            }
        }

        onClicked: root._activate(modelData)
    }
}
