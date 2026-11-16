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
pragma Singleton

import QtQuick

import VLC.Style

// Colors and sizes of the redesigned windows (as the settings window,
// SettingRow.qml), shared by RedesignWindow and the Win* controls.
QtObject {
    id: style

    readonly property ColorContext view: ColorContext {
        palette: VLCStyle.palette
        colorSet: ColorContext.View
    }
    readonly property ColorContext window: ColorContext {
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }
    readonly property ColorContext tab: ColorContext {
        palette: VLCStyle.palette
        colorSet: ColorContext.TabButton
        focused: true
    }
    readonly property ColorContext item: ColorContext {
        palette: VLCStyle.palette
        colorSet: ColorContext.Item
    }

    readonly property color well: window.bg.secondary
    readonly property color surface: window.bg.primary
    readonly property color selected: item.bg.highlight
    readonly property color text: view.fg.secondary
    readonly property color strongText: view.fg.primary
    readonly property color mutedText: Qt.alpha(view.fg.secondary, 0.7)
    readonly property color accent: view.accent
    // slider of the design (Figma effect settings)
    readonly property color accentDim: VLCStyle.palette.accentDim
    // card of an effect's settings (Figma open card), the track is a well in it
    readonly property color card: VLCStyle.palette.isDark ? "#1B1B1B" : "#DEDEDE"
    readonly property color sliderTrack: VLCStyle.palette.isDark ? "#090909" : "#F4F4F4"
    readonly property color sliderTick: VLCStyle.palette.isDark ? "#1A1611" : "#C8C8C8"
    readonly property color negative: view.fg.negative
    readonly property color focus: view.visualFocus
    readonly property color border: window.border

    readonly property real radius: VLCStyle.dp(6, VLCStyle.scale)
    readonly property real controlWidth: VLCStyle.dp(320, VLCStyle.scale)
    readonly property real pageMargin: VLCStyle.dp(20, VLCStyle.scale)
    readonly property real rowHeight: VLCStyle.dp(46, VLCStyle.scale)
    readonly property real fieldHeight: VLCStyle.dp(36, VLCStyle.scale)
}
