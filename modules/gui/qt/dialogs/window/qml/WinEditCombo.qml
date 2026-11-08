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
import QtQuick.Templates as T

import VLC.Style

// text field with a list of values to pick (history, presets)
WinField {
    id: editCombo

    property var suggestions: []

    rightPadding: VLCStyle.dp(12, VLCStyle.scale) + (suggestions.length > 0 ? VLCStyle.icon_normal : 0)

    T.Label {
        visible: editCombo.suggestions.length > 0
        anchors { right: parent.right; rightMargin: VLCStyle.dp(10, VLCStyle.scale); verticalCenter: parent.verticalCenter }
        text: VLCIcons.chevron_down
        font.family: VLCIcons.fontFamily
        font.pixelSize: VLCStyle.icon_normal
        color: WinStyle.text

        TapHandler {
            onTapped: suggestionPopup.opened ? suggestionPopup.close() : suggestionPopup.open()
        }
    }

    T.Popup {
        id: suggestionPopup

        y: editCombo.height + VLCStyle.dp(2, VLCStyle.scale)
        width: editCombo.width
        implicitHeight: Math.min(suggestionList.contentHeight + 2 * padding, VLCStyle.dp(320, VLCStyle.scale))
        padding: VLCStyle.dp(2, VLCStyle.scale)

        contentItem: ListView {
            id: suggestionList

            clip: true
            model: editCombo.suggestions
            T.ScrollBar.vertical: WinScrollBar { }
            delegate: T.ItemDelegate {
                id: suggestion

                required property var modelData

                width: suggestionList.width
                implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
                onClicked: {
                    editCombo.text = modelData
                    editCombo.textEdited()
                    suggestionPopup.close()
                }

                contentItem: T.Label {
                    leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                    verticalAlignment: Text.AlignVCenter
                    text: suggestion.modelData
                    color: suggestion.modelData === editCombo.text ? WinStyle.accent : WinStyle.text
                    font.pixelSize: VLCStyle.fontSize_large
                    elide: Text.ElideMiddle
                }
                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: suggestion.hovered ? WinStyle.surface : "transparent"
                }
            }
        }

        background: Rectangle {
            color: WinStyle.well
            radius: WinStyle.radius
            border.width: VLCStyle.border
            border.color: WinStyle.border
        }
    }
}
