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

// "Audio Fingerprinting" (classic dialogs/fingerprint), from the Media
// Information window: "Fingerprinting track...", then the matching
// identities (title links to MusicBrainz, artist) to apply one, or "No
// fingerprint has been found". Follows a FingerprintModel.
RedesignWindow {
    id: root

    // FingerprintModel of the Media Information window
    property var fingerprinter: null

    readonly property int _state: fingerprinter ? fingerprinter.state : 0

    title: qsTr("Audio Fingerprinting")
    modality: Qt.WindowModal
    fitWidth: VLCStyle.dp(560, VLCStyle.scale)
    pageHeight: VLCStyle.dp(280, VLCStyle.scale)

    // closing drops the results, as the classic dialog
    onVisibleChanged: if (!visible && fingerprinter && _state !== 0) fingerprinter.discard()

    Connections {
        target: root.fingerprinter
        function onStateChanged() {
            if (root._state === 1)          // Working
                root.open()
            else if (root._state === 0)     // applied or discarded
                root.close()
            else if (root._state === 2)     // Results
                identities.currentIndex = 0
        }
    }

    StackLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: root.pageHeight
        currentIndex: root._state === 2 ? 1 : (root._state === 3 ? 2 : 0)

        // working
        ColumnLayout {
            spacing: VLCStyle.margin_normal

            Item { Layout.fillHeight: true }

            WinLabel {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("Fingerprinting track...")
            }

            Rectangle {
                id: track

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: VLCStyle.dp(260, VLCStyle.scale)
                Layout.preferredHeight: VLCStyle.dp(12, VLCStyle.scale)
                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: WinStyle.well
                clip: true

                Rectangle {
                    id: chunk
                    width: parent.width * 0.3
                    height: parent.height
                    radius: parent.radius
                    color: WinStyle.accent

                    SequentialAnimation on x {
                        running: root.visible && root._state === 1
                        loops: Animation.Infinite
                        NumberAnimation { from: 0; to: track.width - chunk.width; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { from: track.width - chunk.width; to: 0; duration: 900; easing.type: Easing.InOutSine }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }

        // results
        ColumnLayout {
            spacing: VLCStyle.margin_small

            WinSectionTitle {
                topPadding: 0
                text: qsTr("Select a matching identity")
            }

            WinList {
                id: identityFrame

                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.fingerprinter ? root.fingerprinter.results : []

                delegate: T.ItemDelegate {
                    id: identity

                    required property var modelData
                    required property int index
                    readonly property bool selected: ListView.view.currentIndex === index

                    width: ListView.view.width
                    implicitHeight: VLCStyle.dp(54, VLCStyle.scale)
                    leftPadding: VLCStyle.margin_small
                    rightPadding: VLCStyle.margin_small

                    onClicked: ListView.view.currentIndex = index
                    onDoubleClicked: root.fingerprinter.apply(index)

                    background: Rectangle {
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: identity.selected ? WinStyle.selected
                                                 : (identity.hovered ? Qt.alpha(WinStyle.surface, 0.6) : "transparent")
                    }

                    contentItem: ColumnLayout {
                        spacing: VLCStyle.dp(2, VLCStyle.scale)

                        // the title opens the recording on MusicBrainz
                        T.Label {
                            text: identity.modelData.title
                            color: WinStyle.accent
                            font.pixelSize: VLCStyle.fontSize_large
                            font.weight: Font.DemiBold
                            font.underline: titleHover.hovered
                            elide: Text.ElideRight
                            Layout.fillWidth: true

                            HoverHandler { id: titleHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: Qt.openUrlExternally(identity.modelData.link) }
                        }
                        T.Label {
                            Layout.fillWidth: true
                            Layout.leftMargin: VLCStyle.margin_normal
                            text: identity.modelData.artist
                            color: WinStyle.mutedText
                            font.pixelSize: VLCStyle.fontSize_normal
                            elide: Text.ElideRight
                        }
                    }
                }
            }

        }

        // nothing found
        ColumnLayout {
            Item { Layout.fillHeight: true }
            WinLabel {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("No fingerprint has been found")
            }
            Item { Layout.fillHeight: true }
        }
    }

    readonly property ListView identities: identityFrame.list

    footer: [
        WinButton {
            visible: root._state === 2
            text: qsTr("Discard all identities")
            onClicked: root.fingerprinter.discard()
        },
        WinButton {
            visible: root._state === 2
            highlighted: true
            text: qsTr("Apply this identity to the file")
            onClicked: root.fingerprinter.apply(root.identities.currentIndex)
        },
        WinButton {
            text: qsTr("Close")
            onClicked: root.close()
        }
    ]
}
