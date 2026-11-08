/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
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
import QtQuick.Layouts

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Dialogs

// VLC Redesign: "Customize Interface" in the frame of the redesigned windows
// (RedesignWindow): the profile drop-down with Clone / New / Delete, the
// editor, Cancel / OK. Same behaviour as before: OK saves the profiles,
// Cancel (or closing) brings back the saved ones.
RedesignWindow {
    id: root

    resizable: true
    fitWidth: VLCStyle.dp(900, VLCStyle.scale)
    initialHeight: VLCStyle.dp(600, VLCStyle.scale)
    modality: Qt.ApplicationModal
    title: qsTr("Toolbar Editor")

    signal unload()

    property bool _accepting: false

    function _accept() {
        _accepting = true
        MainCtx.controlbarProfileModel.save()
        close()
        _accepting = false
        unload()
    }

    // Cancel, Escape, the close button: discard the changes
    onVisibleChanged: {
        if (visible) // Save first, in case the dialog is rejected.
            MainCtx.controlbarProfileModel.save(false)
        else if (!_accepting) {
            // Load saved to discard the changes
            MainCtx.controlbarProfileModel.reload()
            unload()
        }
    }

    function newProfile(profileCreatorFunction) {
        console.assert(typeof profileCreatorFunction === 'function')

        const count = MainCtx.controlbarProfileModel.rowCount()
        const npDialog = DialogsProvider.getTextDialog(null,
                                                       qsTr("Profile Name"),
                                                       qsTr("Please enter the new profile name:"),
                                                       qsTr("Profile %1").arg(count + 1))
        if (!npDialog.ok)
            return

        profileCreatorFunction(npDialog.text)
        MainCtx.controlbarProfileModel.selectedProfile = count
    }

    function _markDirty(text) {
        return (text += " *")
    }

    // the profiles as { value, text } for the drop-down
    property var profiles: []

    Instantiator {
        id: profileItems

        model: MainCtx.controlbarProfileModel

        delegate: QtObject {
            required property int index
            required property string name
            required property bool dirty
            readonly property int value: index
            readonly property string text: dirty ? root._markDirty(name) : name
        }

        onObjectAdded: Qt.callLater(root._updateProfiles)
        onObjectRemoved: Qt.callLater(root._updateProfiles)
    }

    function _updateProfiles() {
        const list = []
        for (let i = 0; i < profileItems.count; ++i)
            list.push(profileItems.objectAt(i))
        profiles = list
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: VLCStyle.margin_small
        spacing: VLCStyle.margin_xsmall

        WinLabel {
            Layout.fillWidth: true
            text: qsTr("Select profile:")
        }

        WinDropdown {
            id: comboBox

            model: root.profiles
            value: MainCtx.controlbarProfileModel.selectedProfile
            displayText: {
                const current = MainCtx.controlbarProfileModel.currentModel
                if (!current)
                    return "N/A"
                return current.dirty ? root._markDirty(current.name) : current.name
            }
            onPicked: (v) => MainCtx.controlbarProfileModel.selectedProfile = v

            Accessible.name: qsTr("Profiles")
        }

        WinButton {
            iconText: VLCIcons.ic_fluent_document_copy_24_regular
            toolTip.text: qsTr("Clone the selected profile")
            onClicked: root.newProfile(MainCtx.controlbarProfileModel.cloneSelectedProfile)
        }

        WinButton {
            iconText: VLCIcons.ic_fluent_document_add_24_regular
            toolTip.text: qsTr("New profile")
            onClicked: root.newProfile(MainCtx.controlbarProfileModel.newProfile)
        }

        WinButton {
            iconText: VLCIcons.del
            toolTip.text: qsTr("Delete the current profile.\nDeleting all profiles brings back the default styles.")
            onClicked: MainCtx.controlbarProfileModel.deleteSelectedProfile()
        }
    }

    // The main context of the toolbareditor dialog:
    ToolbarEditor {
        id: toolbarEditor

        Layout.fillWidth: true
        Layout.fillHeight: true

        MouseArea {
            anchors.fill: parent
            z: -1
            cursorShape: toolbarEditor.dragActive ? Qt.ForbiddenCursor : Qt.ArrowCursor
        }
    }

    footer: [
        WinButton {
            text: qsTr("Cancel")
            onClicked: root.close()
        },
        WinButton {
            text: qsTr("OK")
            highlighted: true
            onClicked: root._accept()
        }
    ]
}
