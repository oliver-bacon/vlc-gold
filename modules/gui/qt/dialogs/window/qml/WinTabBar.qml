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

import VLC.Style
import VLC.Util

// The tabs of a redesigned window, in a row under the title bar (as the
// classic dialogs had them): Figma menu icon + name, equally wide when the
// names fit, the selected one filled. Left / Right move between them.
Rectangle {
    id: bar

    // { text, icon } with the icon name of qrc:///menu/figma/*.svg
    property var tabs: []
    property int currentTab: 0

    signal picked(int index)

    readonly property real _inset: VLCStyle.dp(6, VLCStyle.scale)
    readonly property real _tabHeight: VLCStyle.dp(40, VLCStyle.scale)
    // every name fits in an equal share of the row
    readonly property bool _equal: {
        const n = repeater.count
        let widest = 0
        for (let i = 0; i < n; ++i)
            widest = Math.max(widest, repeater.itemAt(i)?.naturalWidth ?? 0)
        return n === 0 || widest <= (tabRow.width - (n - 1) * tabRow.spacing) / n
    }

    implicitHeight: visible ? _tabHeight + 2 * _inset + 2 * VLCStyle.margin_xsmall : 0
    visible: tabs.length > 0
    color: WinStyle.view.bg.primary

    Rectangle {
        anchors.fill: parent
        anchors.margins: VLCStyle.margin_xsmall
        radius: WinStyle.radius
        color: WinStyle.window.bg.primary

        RowLayout {
            id: tabRow

            anchors.fill: parent
            anchors.margins: bar._inset
            spacing: VLCStyle.margin_xsmall

            Repeater {
                id: repeater

                model: bar.tabs

                T.AbstractButton {
                    id: tabButton

                    required property var modelData
                    required property int index
                    readonly property bool selected: bar.currentTab === index

                    // equally wide; when a name does not fit that way, as wide
                    // as each name needs (the room left is shared)
                    readonly property real naturalWidth: VLCStyle.icon_normal + tabLabel.implicitWidth
                                                         + 3 * VLCStyle.margin_xsmall
                    Layout.fillWidth: true
                    Layout.preferredWidth: bar._equal ? 1 : naturalWidth
                    Layout.minimumWidth: VLCStyle.icon_normal + 2 * VLCStyle.margin_xsmall
                    Layout.fillHeight: true
                    implicitHeight: bar._tabHeight

                    onClicked: bar.picked(index)

                    Keys.onLeftPressed: bar._move(-1)
                    Keys.onRightPressed: bar._move(1)

                    Accessible.role: Accessible.PageTab
                    Accessible.name: modelData.text

                    background: Rectangle {
                        radius: VLCStyle.dp(2, VLCStyle.scale)
                        color: (tabButton.selected || tabButton.hovered) ? WinStyle.tab.bg.primary : "transparent"
                        border.width: tabButton.visualFocus ? VLCStyle.focus_border : 0
                        border.color: WinStyle.focus
                    }

                    contentItem: Item {
                        Row {
                            anchors.centerIn: parent
                            spacing: VLCStyle.margin_xsmall

                            // Figma menu icon: its details in the accent when selected
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                width: VLCStyle.icon_normal
                                height: VLCStyle.icon_normal
                                sourceSize: Qt.size(width * 2, height * 2)
                                source: SVGColorImage.colorize("qrc:///menu/figma/" + tabButton.modelData.icon + ".svg")
                                            .any({
                                                "#8F8F8F": tabButton.selected ? WinStyle.strongText : WinStyle.text,
                                                "#AB6314": tabButton.selected ? WinStyle.accent : WinStyle.text,
                                                "#D37918": tabButton.selected ? WinStyle.accent : WinStyle.text
                                            }).uri()
                            }

                            T.Label {
                                id: tabLabel

                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.min(implicitWidth,
                                                tabButton.width - VLCStyle.icon_normal - 3 * VLCStyle.margin_xsmall)
                                text: tabButton.modelData.text
                                elide: Text.ElideRight
                                font.pixelSize: VLCStyle.fontSize_large
                                color: tabButton.selected ? WinStyle.strongText : WinStyle.text
                            }
                        }
                    }
                }
            }
        }
    }

    function _move(step) {
        const next = currentTab + step
        if (next < 0 || next >= tabs.length)
            return
        picked(next)
        repeater.itemAt(next)?.forceActiveFocus(Qt.TabFocusReason)
    }
}
