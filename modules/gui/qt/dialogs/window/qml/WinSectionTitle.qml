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

// title of a section of a page (xlarge DemiBold)
T.Label {
    Layout.fillWidth: true
    topPadding: VLCStyle.dp(10, VLCStyle.scale)
    bottomPadding: VLCStyle.dp(10, VLCStyle.scale)
    color: WinStyle.strongText
    opacity: 0.85
    font.pixelSize: VLCStyle.fontSize_xlarge
    font.weight: Font.DemiBold
    elide: Text.ElideRight
}
