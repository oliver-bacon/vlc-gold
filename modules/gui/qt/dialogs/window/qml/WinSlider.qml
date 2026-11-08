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

// slider of the settings window (Figma "range": 16px track, 8x24 handle);
// `vertical` for the equalizer bands
T.Slider {
    id: slider

    // the text shown in the tool tip and under the slider
    property var format: (v) => (Math.round(v * 100) / 100).toString()

    implicitWidth: vertical ? VLCStyle.dp(24, VLCStyle.scale) : WinStyle.controlWidth
    implicitHeight: vertical ? VLCStyle.dp(160, VLCStyle.scale) : VLCStyle.dp(24, VLCStyle.scale)
    snapMode: (stepSize > 0) ? T.Slider.SnapAlways : T.Slider.NoSnap
    opacity: enabled ? 1.0 : 0.4

    readonly property real _track: VLCStyle.dp(16, VLCStyle.scale)
    readonly property real _inner: VLCStyle.dp(2, VLCStyle.scale)

    background: Rectangle {
        x: slider.vertical ? slider.leftPadding + (slider.availableWidth - width) / 2 : slider.leftPadding
        y: slider.vertical ? slider.topPadding : slider.topPadding + (slider.availableHeight - height) / 2
        width: slider.vertical ? slider._track : slider.availableWidth
        height: slider.vertical ? slider.availableHeight : slider._track
        radius: VLCStyle.dp(4, VLCStyle.scale)
        color: WinStyle.well
        border.width: slider.visualFocus ? VLCStyle.focus_border : 0
        border.color: WinStyle.focus

        Rectangle {
            readonly property real _length: slider.vertical ? parent.height - 2 * slider._inner
                                                            : parent.width - 2 * slider._inner
            x: slider._inner
            y: slider.vertical ? parent.height - slider._inner - height : slider._inner
            width: slider.vertical ? parent.width - 2 * slider._inner
                                   : Math.max(0, slider.position * _length)
            height: slider.vertical ? Math.max(0, slider.position * _length)
                                    : parent.height - 2 * slider._inner
            radius: VLCStyle.dp(3, VLCStyle.scale)
            color: WinStyle.selected
        }
    }

    handle: Rectangle {
        x: slider.vertical ? slider.leftPadding + (slider.availableWidth - width) / 2
                           : slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
        y: slider.vertical ? slider.topPadding + slider.visualPosition * (slider.availableHeight - height)
                           : slider.topPadding + (slider.availableHeight - height) / 2
        implicitWidth: slider.vertical ? VLCStyle.dp(24, VLCStyle.scale) : VLCStyle.dp(8, VLCStyle.scale)
        implicitHeight: slider.vertical ? VLCStyle.dp(8, VLCStyle.scale) : VLCStyle.dp(24, VLCStyle.scale)
        radius: VLCStyle.dp(3, VLCStyle.scale)
        color: WinStyle.accent
    }

    T.ToolTip {
        id: sliderTip

        parent: slider.handle
        visible: slider.pressed || slider.hovered
        text: slider.format(slider.value)
        y: -height - VLCStyle.dp(4, VLCStyle.scale)
        padding: VLCStyle.dp(4, VLCStyle.scale)
        contentItem: T.Label {
            text: sliderTip.text
            color: WinStyle.strongText
            font.pixelSize: VLCStyle.fontSize_normal
        }
        background: Rectangle {
            color: WinStyle.window.bg.primary
            radius: VLCStyle.dp(4, VLCStyle.scale)
        }
    }
}
