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

// multi-line text in a well that scrolls; `readOnly` for logs and texts
Rectangle {
    id: box

    property alias text: area.text
    property alias readOnly: area.readOnly
    property alias textFormat: area.textFormat
    property alias wrapMode: area.wrapMode
    property alias font: area.font
    property alias area: area
    property alias flickable: flick
    property string placeholderText

    signal edited()
    signal linkActivated(string link)

    implicitHeight: VLCStyle.dp(96, VLCStyle.scale)
    radius: WinStyle.radius
    color: WinStyle.well
    border.width: VLCStyle.dp(2, VLCStyle.scale)
    border.color: area.activeFocus && !area.readOnly ? WinStyle.accent : WinStyle.surface
    opacity: enabled ? 1.0 : 0.4

    Flickable {
        id: flick

        anchors.fill: parent
        anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
        clip: true
        contentWidth: width
        contentHeight: area.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        T.ScrollBar.vertical: WinScrollBar { }

        T.TextArea {
            id: area

            width: flick.width
            implicitHeight: Math.max(flick.height, contentHeight + topPadding + bottomPadding)
            padding: VLCStyle.dp(10, VLCStyle.scale)
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.PlainText
            selectByMouse: true
            color: WinStyle.text
            selectionColor: WinStyle.selected
            selectedTextColor: WinStyle.strongText
            font.pixelSize: VLCStyle.fontSize_large
            onTextChanged: if (!readOnly) box.edited()
            onLinkActivated: (link) => box.linkActivated(link)

            HoverHandler {
                enabled: area.hoveredLink !== ""
                cursorShape: Qt.PointingHandCursor
            }

            T.Label {
                anchors.fill: parent
                anchors.margins: area.padding
                visible: area.text === "" && box.placeholderText !== ""
                text: box.placeholderText
                color: Qt.alpha(WinStyle.text, 0.4)
                font: area.font
                wrapMode: Text.WordWrap
            }
        }
    }
}
