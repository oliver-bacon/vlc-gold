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
        { "title": qsTr("Podcasts"), "icon": VLCIcons.stream, "uri": ["streams", "services", "source_root"], "source": "podcast", "info": qsTr("Your podcast subscriptions") },
        { "title": qsTr("Radio"),    "icon": VLCIcons.stream, "uri": ["streams", "services", "source_root"], "source": "radio", "info": qsTr("Internet radio stations") },
        { "title": qsTr("Saved Streams"), "icon": VLCIcons.link, "uri": ["streams", "url"], "info": qsTr("Streams you opened") }
    ]

    // "Add Network Stream": VLC's network stream dialog
    readonly property var _entries: [{ "title": qsTr("Add Network Stream"), "icon": VLCIcons.add, "uri": null, "info": qsTr("Open a stream from its URL") }].concat(root._sections)

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
            anchors.topMargin: VLCStyle.margin_small
            spacing: VLCStyle.margin_xsmall


            GridView {
                id: gridView

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: MainCtx.gridView
                clip: true
                focus: MainCtx.gridView
                boundsBehavior: Flickable.StopAtBounds
                model: root._entries

                // cards at least 260 dp wide; each cell holds a card and the
                // gap after it, so the view reaches one gap past the page edge
                // and the last card ends at the edge
                readonly property real _gap: VLCStyle.margin_normal
                Layout.rightMargin: -_gap
                readonly property int _columns: Math.max(1, Math.floor(width / (VLCStyle.dp(260, VLCStyle.scale) + _gap)))
                cellWidth: Math.floor(width / _columns)
                cellHeight: VLCStyle.dp(88, VLCStyle.scale) + _gap

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
                    height: VLCStyle.dp(56, VLCStyle.scale)
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
            color: !entry.grid && (entry.hovered || entry.visualFocus) ? Qt.alpha(theme.fg.primary, 0.05) : "transparent"
        }

        contentItem: Item {
            // grid: a card with the icon in an accent circle, the name and
            // what it holds (all cards the same size, rows fill the width)
            Rectangle {
                visible: entry.grid
                anchors.fill: parent
                anchors.rightMargin: VLCStyle.margin_normal
                anchors.bottomMargin: VLCStyle.margin_normal
                radius: VLCStyle.dp(10, VLCStyle.scale)
                color: (entry.hovered || entry.visualFocus) ? Qt.lighter(tileTheme.bg.primary, 1.2) : tileTheme.bg.primary
                border.width: entry.visualFocus ? VLCStyle.focus_border : 0
                border.color: theme.visualFocus

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: VLCStyle.margin_normal
                    anchors.rightMargin: VLCStyle.margin_normal
                    spacing: VLCStyle.margin_normal

                    Rectangle {
                        Layout.preferredWidth: VLCStyle.dp(48, VLCStyle.scale)
                        Layout.preferredHeight: Layout.preferredWidth
                        radius: width / 2
                        color: Qt.alpha(theme.accent, (entry.hovered || entry.visualFocus) ? 0.25 : 0.14)

                        Widgets.IconLabel {
                            anchors.centerIn: parent
                            text: entry.modelData.icon
                            color: theme.accent
                            font.pixelSize: VLCStyle.icon_normal
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: VLCStyle.dp(2, VLCStyle.scale)

                        Text {
                            Layout.fillWidth: true
                            text: entry.modelData.title
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: theme.fg.primary
                            font.pixelSize: VLCStyle.fontSize_large
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: entry.modelData.info ?? ""
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: theme.fg.secondary
                            font.pixelSize: VLCStyle.fontSize_normal
                        }
                    }
                }
            }

            // list: a row with a smaller accent icon, the name and what it
            // holds; lit only while hovered (or reached with the keyboard)
            RowLayout {
                visible: !entry.grid
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.margin_xsmall
                spacing: VLCStyle.margin_small

                Rectangle {
                    Layout.preferredWidth: VLCStyle.dp(36, VLCStyle.scale)
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: width / 2
                    color: Qt.alpha(theme.accent, entry.hovered ? 0.25 : 0.14)

                    Widgets.IconLabel {
                        anchors.centerIn: parent
                        text: entry.modelData.icon
                        color: theme.accent
                        font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
                    }
                }
                Text {
                    text: entry.modelData.title
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    color: theme.fg.primary
                    font.pixelSize: VLCStyle.fontSize_large
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    text: entry.modelData.info ?? ""
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    color: theme.fg.secondary
                    font.pixelSize: VLCStyle.fontSize_normal
                }
            }
        }

        onClicked: root._activate(modelData)
    }
}
