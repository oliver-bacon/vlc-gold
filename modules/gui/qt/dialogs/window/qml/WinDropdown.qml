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

// drop-down list of { value, text } (Figma "Dropdown": 320x36); `value` is
// the picked one, `picked(value)` when the user picks one; `source` when
// the value comes from somewhere that can change
T.ComboBox {
    id: combo

    property var value
    // a value to follow, also after the user picked one (a binding on
    // `value` is lost by then)
    property var source
    onSourceChanged: if (source !== undefined) value = source
    signal picked(var value)
    // the list can be wider than the box (long names); it stays right aligned
    property real popupWidth: width

    implicitWidth: WinStyle.controlWidth
    implicitHeight: WinStyle.fieldHeight
    opacity: enabled ? 1.0 : 0.4

    textRole: "text"
    valueRole: "value"
    // the index of `value`, also when it changes from outside
    function _sync() {
        const m = model ?? []
        let index = -1
        for (let i = 0; i < m.length; ++i)
            if (String(m[i].value) === String(value))
                index = i
        currentIndex = index
    }
    onValueChanged: _sync()
    onModelChanged: _sync()
    Component.onCompleted: _sync()
    onActivated: (index) => {
        value = valueAt(index)
        picked(value)
    }

    background: Rectangle {
        color: WinStyle.well
        radius: WinStyle.radius
        border.width: combo.visualFocus ? VLCStyle.focus_border : 0
        border.color: WinStyle.focus

        Rectangle {
            anchors.fill: parent
            anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: combo.hovered ? Qt.lighter(WinStyle.surface, 1.2) : WinStyle.surface
        }
    }

    contentItem: T.Label {
        leftPadding: VLCStyle.dp(14, VLCStyle.scale)
        rightPadding: VLCStyle.dp(14, VLCStyle.scale) + VLCStyle.icon_normal
        verticalAlignment: Text.AlignVCenter
        text: combo.currentIndex >= 0 ? combo.displayText : String(combo.value ?? "")
        color: WinStyle.text
        font.pixelSize: VLCStyle.fontSize_large
        elide: Text.ElideRight
    }

    indicator: T.Label {
        x: combo.width - width - VLCStyle.dp(10, VLCStyle.scale)
        anchors.verticalCenter: combo.verticalCenter
        text: VLCIcons.chevron_down
        font.family: VLCIcons.fontFamily
        font.pixelSize: VLCStyle.icon_normal
        color: WinStyle.text
    }

    delegate: T.ItemDelegate {
        id: choice

        required property var modelData
        required property int index

        width: combo.popupWidth - VLCStyle.dp(4, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
        highlighted: combo.highlightedIndex === index

        contentItem: T.Label {
            leftPadding: VLCStyle.dp(12, VLCStyle.scale)
            verticalAlignment: Text.AlignVCenter
            text: choice.modelData.text || String(choice.modelData.value)
            color: (combo.currentIndex === choice.index) ? WinStyle.accent : WinStyle.text
            font.pixelSize: VLCStyle.fontSize_large
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: choice.highlighted ? WinStyle.surface : "transparent"
        }
    }

    popup: T.Popup {
        x: combo.width - combo.popupWidth
        y: combo.height + VLCStyle.dp(2, VLCStyle.scale)
        width: combo.popupWidth
        implicitHeight: Math.min(contentItem.implicitHeight + 2 * padding, VLCStyle.dp(320, VLCStyle.scale))
        padding: VLCStyle.dp(2, VLCStyle.scale)

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: combo.popup.visible ? combo.delegateModel : null
            currentIndex: combo.highlightedIndex
            T.ScrollBar.vertical: WinScrollBar { }
        }

        background: Rectangle {
            color: WinStyle.well
            radius: WinStyle.radius
            border.width: VLCStyle.border
            border.color: WinStyle.border
        }
    }
}
