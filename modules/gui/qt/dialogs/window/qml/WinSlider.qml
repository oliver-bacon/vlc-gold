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

// slider of the design (Figma effect settings, as FxSlider of the player's
// settings panel): 16 px well track (radius 6), accent bright fill inset by
// 2 px up to the 8 x 24 accent dim handle, 2 x 6 px marks that divide the
// track into `tickCount` parts. The handle jumps from step to step.
T.Slider {
    id: slider

    // the text shown in the tool tip
    property var format: (v) => (Math.round(v * 100) / 100).toString()
    // number of parts the marks divide the track into (0: no marks)
    property int tickCount: 0

    readonly property real _dp: VLCStyle.dp(1, VLCStyle.scale)

    // handle x for a position 0..1
    function handleX(pos) { return 2 * _dp + pos * (availableWidth - 12 * _dp) }

    implicitWidth: WinStyle.controlWidth
    implicitHeight: 24 * _dp
    snapMode: (stepSize > 0) ? T.Slider.SnapAlways : T.Slider.NoSnap
    opacity: enabled ? 1.0 : 0.4

    background: Item {
        Rectangle {
            id: track

            y: 4 * slider._dp
            width: slider.availableWidth
            height: 16 * slider._dp
            radius: 6 * slider._dp
            color: WinStyle.sliderTrack
            border.width: slider.visualFocus ? VLCStyle.focus_border : 0
            border.color: WinStyle.focus

            Rectangle {
                x: 2 * slider._dp
                y: 2 * slider._dp
                width: slider.handleX(slider.visualPosition) + 6 * slider._dp
                height: 12 * slider._dp
                radius: 4 * slider._dp
                color: WinStyle.selected
            }
        }

        Repeater {
            model: Math.max(0, slider.tickCount - 1)

            Rectangle {
                required property int index
                x: slider.handleX((index + 1) / slider.tickCount) + 3 * slider._dp
                y: track.y + 5 * slider._dp
                width: 2 * slider._dp
                height: 6 * slider._dp
                radius: slider._dp
                color: WinStyle.sliderTick
            }
        }
    }

    handle: Rectangle {
        x: slider.handleX(slider.visualPosition)
        y: 0
        width: 8 * slider._dp
        height: 24 * slider._dp
        radius: 4 * slider._dp
        color: WinStyle.accentDim
    }

    T.ToolTip {
        id: sliderTip

        parent: slider.handle
        visible: slider.pressed
        text: slider.format(slider.value)
        x: (parent.width - width) / 2
        y: -height - VLCStyle.dp(4, VLCStyle.scale)
        padding: VLCStyle.dp(4, VLCStyle.scale)
        implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
        implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
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
