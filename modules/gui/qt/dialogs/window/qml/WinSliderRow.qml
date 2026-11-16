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

// setting row with a slider and its value in a field (can be typed)
WinRow {
    id: sliderRow

    property real from: 0
    property real to: 1
    property real stepSize: 1
    property int decimals: 0
    property int tickCount: 0
    // the value to show; follows it also after the slider was moved
    property real value: 0

    signal moved(real value)

    readonly property real _fieldWidth: VLCStyle.dp(80, VLCStyle.scale)

    // a fixed width: the sliders and fields of all rows line up
    WinSlider {
        id: slider

        Layout.preferredWidth: WinStyle.controlWidth - sliderRow._fieldWidth - VLCStyle.margin_xsmall
        from: sliderRow.from
        to: sliderRow.to
        stepSize: sliderRow.stepSize
        tickCount: sliderRow.tickCount
        format: (v) => Number(v).toFixed(sliderRow.decimals)
        Accessible.name: sliderRow.label
        onMoved: sliderRow.moved(Number(value.toFixed(sliderRow.decimals)))

        Binding on value { value: sliderRow.value }
    }

    WinNumberField {
        fieldWidth: sliderRow._fieldWidth
        from: sliderRow.from
        to: sliderRow.to
        decimals: sliderRow.decimals
        step: sliderRow.stepSize
        source: sliderRow.value
        name: sliderRow.label
        onEdited: (v) => sliderRow.moved(v)
    }
}
