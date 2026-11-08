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

import VLC.Style

// the transcoding profile of the Convert and Stream windows (classic
// VLCProfileSelector): the profile, Edit / Delete / New
WinRow {
    id: row

    // SoutHelper
    property var helper

    label: qsTr("Profile")

    WinDropdown {
        implicitWidth: WinStyle.controlWidth - 3 * (VLCStyle.dp(34, VLCStyle.scale) + VLCStyle.margin_xsmall)
        model: (row.helper ? row.helper.profiles : []).map((p, i) => ({ "value": i, "text": p.name }))
        value: row.helper ? row.helper.currentProfile : -1
        onPicked: (v) => row.helper.currentProfile = v
    }
    WinButton {
        iconText: VLCIcons.more
        toolTip.text: qsTr("Edit selected profile")
        onClicked: row.helper.editProfile()
    }
    WinButton {
        iconText: VLCIcons.del
        toolTip.text: qsTr("Delete selected profile")
        onClicked: row.helper.deleteProfile()
    }
    WinButton {
        iconText: VLCIcons.add
        toolTip.text: qsTr("Create a new profile")
        onClicked: row.helper.newProfile()
    }
}
