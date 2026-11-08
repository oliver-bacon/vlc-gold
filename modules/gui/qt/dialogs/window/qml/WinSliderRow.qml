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

// setting row with a slider and its value (min, value, max under it)
WinRow {
    id: sliderRow

    property alias slider: slider
    property alias from: slider.from
    property alias to: slider.to
    property alias value: slider.value
    property alias stepSize: slider.stepSize
    property var format: (v) => (Math.round(v * 100) / 100).toString()

    signal moved(real value)

    // a fixed width: every row's slider lines up, the labels under it
    ColumnLayout {
        Layout.preferredWidth: WinStyle.controlWidth
        Layout.maximumWidth: WinStyle.controlWidth
        spacing: VLCStyle.dp(4, VLCStyle.scale)

        WinSlider {
            id: slider

            Layout.fillWidth: true
            format: sliderRow.format
            Accessible.name: sliderRow.label
            onMoved: sliderRow.moved(value)
        }

        RowLayout {
            Layout.fillWidth: true

            T.Label {
                text: sliderRow.format(slider.from)
                font.pixelSize: VLCStyle.fontSize_small
                color: WinStyle.mutedText
            }
            Item { Layout.fillWidth: true }
            T.Label {
                text: sliderRow.format(slider.value)
                font.pixelSize: VLCStyle.fontSize_small
                color: WinStyle.text
            }
            Item { Layout.fillWidth: true }
            T.Label {
                text: sliderRow.format(slider.to)
                font.pixelSize: VLCStyle.fontSize_small
                color: WinStyle.mutedText
            }
        }
    }
}
