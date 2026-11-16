/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * Authors: Oliver Bacon <oliverbacon@tutamail.com>
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

import VLC.MainInterface
import VLC.Player
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util

// HDR output on or off for the playing video (Customize Player "HDR").
// Direct3D11 only (Windows): off = always tone-mapped to SDR
// ("d3d11-hdr-mode" never), on = automatic. The video track is restarted
// so that the display opens again with the mode.
Widgets.IconToolButton {
    id: root

    readonly property bool _supported: !paintOnly && VLCConfig.exists("d3d11-hdr-mode")
    property bool _on: _supported && String(VLCConfig.value("d3d11-hdr-mode")) !== "never"

    text: VLCIcons.hdr
    description: _on ? qsTr("Turn HDR output off") : qsTr("Turn HDR output on")
    checked: _on

    enabled: _supported

    onClicked: {
        VLCConfig.setValue("d3d11-hdr-mode", _on ? "never" : "auto")
        _on = !_on
        Player.restartVideoTrack()
    }
}
