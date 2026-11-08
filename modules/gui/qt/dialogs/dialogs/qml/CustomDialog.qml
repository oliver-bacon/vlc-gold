/*****************************************************************************
 * Copyright (C) 2020 VLC authors and VideoLAN
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

import VLC.MainInterface
import VLC.Style
import VLC.Dialogs
import VLC.Widgets as Widgets

ModalDialog {
    id: root

    property string text

    property alias cancelTxt: cancelBtn.text
    property alias okTxt: okBtn.text

    property var _acceptCb: undefined
    property var _rejectCb: undefined

    function ask(text, acceptCb, rejectCb, buttons) {
        //TODO: use a Promise here when dropping support of Qt 5.11
        let okTxt = qsTr("OK")
        let cancelTxt = qsTr("Cancel")
        if (buttons) {
            if (buttons.cancel) {
                cancelTxt = buttons.cancel
            }
            if (buttons.ok) {
                okTxt = buttons.ok
            }
        }
        root.cancelTxt = cancelTxt
        root.okTxt = okTxt
        root.text = text
        root._acceptCb = acceptCb
        root._rejectCb = rejectCb
        root.open()
    }

    onAccepted: {
        if (_acceptCb)
            _acceptCb()
    }

    onRejected: {
        if (_rejectCb)
            _rejectCb()
    }

    contentItem: WinDescription {
        Layout.bottomMargin: 0
        text: root.text
        color: WinStyle.text
        font.pixelSize: VLCStyle.fontSize_large
    }

    // VLC Redesign: footer bar of the redesigned windows
    footer: WinDialogFooter {
        WinButton {
            id: cancelBtn
            visible: cancelBtn.text !== ""
            onClicked: root.reject()
        }
        WinButton {
            id: okBtn
            visible: okBtn.text !== ""
            highlighted: true
            onClicked: root.accept()
        }
    }

    onOpened: okBtn.forceActiveFocus()
}
