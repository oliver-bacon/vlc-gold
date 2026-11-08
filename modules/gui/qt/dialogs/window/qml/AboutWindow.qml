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

import VLC.MainInterface
import VLC.Style

// "About" (classic dialogs/help, about.ui): logo, name, version (click: who
// built it, where and when), the text with its links; License, Authors and
// Credits as tabs instead of the links in the footer. Opens on About.
RedesignWindow {
    id: root

    title: qsTr("About")
    modality: Qt.WindowModal

    tabs: [
        { "text": qsTr("About"), "icon": "main_about_vlc" },
        { "text": qsTr("License"), "icon": "file_properties_metadata" },
        { "text": qsTr("Authors"), "icon": "main_profile" },
        { "text": qsTr("Credits"), "icon": "file_favorite" }
    ]

    // the same size on every tab; the texts scroll
    pageHeight: Math.max(aboutPage.implicitHeight, VLCStyle.dp(440, VLCStyle.scale))

    property bool _advanced: false

    function reset(args) {
        currentTab = 0
        _advanced = false
        licenseText.flickable.contentY = 0
        authorsText.flickable.contentY = 0
        creditsText.flickable.contentY = 0
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.pageHeight
        currentIndex: root.currentTab

        ColumnLayout {
            id: aboutPage

            spacing: VLCStyle.margin_small

            Image {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: VLCStyle.margin_small
                Layout.preferredWidth: VLCStyle.dp(128, VLCStyle.scale)
                Layout.preferredHeight: VLCStyle.dp(128, VLCStyle.scale)
                source: "qrc:///logo/vlc256.png"
                sourceSize: Qt.size(256, 256)
                fillMode: Image.PreserveAspectFit
            }

            T.Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("VLC Gold")
                color: WinStyle.strongText
                font.pixelSize: VLCStyle.dp(30, VLCStyle.scale)
                font.weight: Font.DemiBold
            }

            // click: build information instead of the version
            T.Label {
                Layout.alignment: Qt.AlignHCenter
                text: root._advanced ? AboutModel.compiledBy
                                     : AboutModel.version + " (VLC " + AboutModel.vlcVersion + ")"
                color: WinStyle.mutedText
                font.pixelSize: VLCStyle.fontSize_large

                TapHandler { onTapped: root._advanced = !root._advanced }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

            T.Label {
                Layout.fillWidth: true
                Layout.topMargin: VLCStyle.margin_small
                Layout.bottomMargin: VLCStyle.margin_small
                wrapMode: Text.WordWrap
                textFormat: Text.StyledText
                linkColor: WinStyle.accent
                color: WinStyle.text
                font.pixelSize: VLCStyle.fontSize_large
                lineHeight: 1.15
                text: qsTr("<p>VLC Gold is a free and open source media player with a redesigned interface, based on VLC.</p><p>VLC is the media player, encoder, and streamer made by the volunteers of the <a href=\"https://www.videolan.org/\">VideoLAN</a> community.</p><p>VLC uses its internal codecs, works on essentially every popular platform, and can read almost all files, CDs, DVDs, network streams, capture cards and other media formats!</p><p><a href=\"https://www.videolan.org/contribute/\">Help and join us!</a></p>")
                onLinkActivated: (link) => Qt.openUrlExternally(link)

                HoverHandler {
                    enabled: parent.hoveredLink !== ""
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Item { Layout.fillHeight: true }
        }

        WinTextArea {
            id: licenseText
            readOnly: true
            text: AboutModel.license
            font.family: "monospace"
            font.pixelSize: VLCStyle.fontSize_normal
        }

        WinTextArea {
            id: authorsText
            readOnly: true
            text: AboutModel.authors
        }

        WinTextArea {
            id: creditsText
            readOnly: true
            text: AboutModel.thanks
        }
    }

    footer: [
        WinButton {
            text: qsTr("Close")
            onClicked: root.close()
        }
    ]
}
