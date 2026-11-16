/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
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

// "Check for Updates": looks for a newer release of VLC Gold on GitHub when
// it opens. A newer one: its notes and Download, which opens the release
// page in the browser (nothing is downloaded or installed by VLC Gold).
RedesignWindow {
    id: root

    title: qsTr("Check for Updates")

    UpdateCheck {
        id: checker
        ctx: MainCtx
    }

    function reset(args) {
        checker.check()
    }

    WinSectionTitle {
        text: {
            switch (checker.state) {
            case UpdateCheck.Available: return qsTr("VLC Gold %1 is available").arg(checker.latestVersion)
            case UpdateCheck.UpToDate: return qsTr("VLC Gold is up to date")
            case UpdateCheck.Failed: return qsTr("The update check failed")
            default: return qsTr("Checking for updates…")
            }
        }
    }

    WinDescription {
        text: checker.state === UpdateCheck.Failed
              ? checker.error
              : qsTr("This is VLC Gold %1.").arg(checker.currentVersion)
    }

    WinTextArea {
        visible: checker.state === UpdateCheck.Available && checker.notes !== ""
        Layout.fillWidth: true
        Layout.topMargin: VLCStyle.margin_normal
        Layout.preferredHeight: VLCStyle.dp(260, VLCStyle.scale)
        readOnly: true
        textFormat: TextEdit.MarkdownText
        text: checker.notes
        onLinkActivated: (link) => Qt.openUrlExternally(link)
    }

    footer: [
        WinButton {
            visible: checker.state === UpdateCheck.Failed
            text: qsTr("Check Again")
            onClicked: checker.check()
        },
        WinButton {
            visible: checker.state === UpdateCheck.Available
            highlighted: true
            text: qsTr("Download")
            onClicked: {
                checker.openPage()
                root.close()
            }
        },
        WinButton {
            text: qsTr("Close")
            onClicked: root.close()
        }
    ]
}
