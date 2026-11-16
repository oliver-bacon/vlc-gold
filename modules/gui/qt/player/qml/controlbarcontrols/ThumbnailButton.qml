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
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util

// Preview thumbnails over the seek bar on or off (Customize Player
// "Thumbnail"); the setting "Player/SeekPreview" is read by SliderBar.qml.
Widgets.IconToolButton {
    id: root

    property bool _on: true

    function _read() {
        const stored = VLCConfig.uiValue("Player/SeekPreview", true)
        _on = !(stored === false || stored === "false")
    }

    text: VLCIcons.snapshot
    description: _on ? qsTr("Hide seek bar thumbnails") : qsTr("Show seek bar thumbnails")
    checked: _on

    enabled: !paintOnly

    onClicked: VLCConfig.setUiValue("Player/SeekPreview", !_on)

    Component.onCompleted: _read()

    Connections {
        target: VLCConfig
        function onUiValueChanged(key) {
            if (key === "" || key === "Player/SeekPreview")
                root._read()
        }
    }
}
