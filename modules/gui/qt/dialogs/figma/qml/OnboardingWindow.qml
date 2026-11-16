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
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Dialogs
import VLC.Util

// Onboarding of the VLC Redesign Figma file, shown on first start instead
// of the classic wizard: welcome + media folder, theme and accent color
// (the 9 color variants of the design), and the basic keyboard shortcuts.
Window {
    id: root

    property int page: 0
    property int scheme: 2 // Night, as in the design
    property int accentIndex: 0
    property string folder: ""

    readonly property var accents: ["#D37918", "#E15032", "#C49E23", "#19A234", "#18AAD3",
                                    "#185DD3", "#8E42FF", "#F052B3", "#AFAFAF"]
    readonly property color accent: accents[accentIndex]
    readonly property real dp1: VLCStyle.dp(1, VLCStyle.scale)

    transientParent: MainCtx.intfMainWindow
    flags: Qt.Dialog | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal
    color: "transparent"
    width: 1060 * dp1
    height: 740 * dp1
    title: qsTr("Welcome to VLC Gold")

    function reset() {
        page = 0
        scheme = Number(MainCtx.colorScheme.scheme)
        folder = ""
    }

    function open() {
        const parentWindow = transientParent
        if (parentWindow) {
            x = parentWindow.x + (parentWindow.width - width) / 2
            y = parentWindow.y + (parentWindow.height - height) / 2
        }
        show()
        raise()
        requestActivate()
    }

    function finish() {
        VLCConfig.setValue("metadata-network-access", privacy.checked)
        VLCConfig.setValue("qt-privacy-ask", false)

        const model = MainCtx.colorScheme
        model.setData(model.index(root.scheme, 0), true, Qt.CheckStateRole)
        VLCConfig.setValue("qt-accent-color", root.accentIndex === 0 ? "default" : root.accents[root.accentIndex])

        if (MainCtx.mediaLibraryAvailable) {
            if (root.folder !== "")
                MainCtx.mediaLibrary.addFolder(root.folder)
            MainCtx.mediaLibrary.reload()
        }
        close()
    }

    Rectangle {
        anchors.fill: parent
        radius: 14 * root.dp1
        color: "#0E0E0E"
        clip: true

        DragHandler {
            target: null
            onActiveChanged: if (active) root.startSystemMove()
        }

        StackLayout {
            anchors.fill: parent
            anchors.bottomMargin: 80 * root.dp1
            currentIndex: root.page

            // ---- 1. welcome --------------------------------------------
            Item {
                ColumnLayout {
                    anchors.centerIn: parent
                    width: 560 * root.dp1
                    spacing: 18 * root.dp1

                    Image {
                        Layout.alignment: Qt.AlignHCenter
                        source: SVGColorImage.colorize("qrc:///misc/cone.svg").accent(root.accent).uri()
                        sourceSize: Qt.size(120 * root.dp1, 120 * root.dp1)
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Welcome to VLC Gold!")
                        color: "#EAEAEA"
                        font.pixelSize: 32 * root.dp1
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 14 * root.dp1
                        text: qsTr("VLC Gold is a free and open source cross-platform multimedia player and framework that plays most multimedia files as well as DVDs, Audio CDs, VCDs, and various streaming protocols.")
                        color: "#8F8F8F"
                        font.pixelSize: 14 * root.dp1
                        wrapMode: Text.WordWrap
                        lineHeight: 1.3
                    }
                    Text {
                        Layout.topMargin: 18 * root.dp1
                        visible: MainCtx.mediaLibraryAvailable
                        text: qsTr("Choose a Media Folder to get started with")
                        color: "#8F8F8F"
                        font.pixelSize: 13 * root.dp1
                    }
                    RowLayout {
                        visible: MainCtx.mediaLibraryAvailable
                        spacing: 10 * root.dp1
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34 * root.dp1
                            radius: 5 * root.dp1
                            color: "#191919"
                            Text {
                                anchors { fill: parent; leftMargin: 12 * root.dp1; rightMargin: 12 * root.dp1 }
                                verticalAlignment: Text.AlignVCenter
                                text: root.folder !== "" ? decodeURIComponent(root.folder.replace(/^file:\/\//, "")) : qsTr("No folder selected")
                                color: root.folder !== "" ? "#C6C6C6" : "#404040"
                                font.pixelSize: 13 * root.dp1
                                elide: Text.ElideMiddle
                            }
                        }
                        PlainButton {
                            text: qsTr("Browse")
                            onClicked: {
                                const f = VLCConfig.browseFolder(qsTr("Media Folder"))
                                if (f !== "")
                                    root.folder = f
                            }
                        }
                    }
                    // VLC asks this on first start; kept from the classic wizard
                    T.CheckBox {
                        id: privacy

                        Layout.topMargin: 8 * root.dp1
                        checked: true
                        indicator: Rectangle {
                            y: (privacy.height - height) / 2
                            width: 16 * root.dp1; height: 16 * root.dp1
                            radius: 3 * root.dp1
                            color: privacy.checked ? Qt.alpha(root.accent, 0.2) : "transparent"
                            border.width: 1.5
                            border.color: privacy.checked ? root.accent : "#8F8F8F"
                            Text {
                                anchors.centerIn: parent
                                visible: privacy.checked
                                font.family: VLCIcons.fontFamily
                                font.pixelSize: 12 * root.dp1
                                text: VLCIcons.check
                                color: root.accent
                            }
                        }
                        contentItem: Text {
                            leftPadding: 26 * root.dp1
                            text: qsTr("Allow VLC to look up media information on the internet (covers, metadata)")
                            color: "#6B6B6B"
                            font.pixelSize: 12 * root.dp1
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            // ---- 2. theme and color ------------------------------------
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 30 * root.dp1
                    spacing: 30 * root.dp1

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 30 * root.dp1
                        text: qsTr("Select your preferred theme and color.")
                        color: "#C6C6C6"
                        font.pixelSize: 20 * root.dp1
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 40 * root.dp1

                        Repeater {
                            model: [
                                { "text": qsTr("Light"), "scheme": 1 },
                                { "text": qsTr("Dark"), "scheme": 2 },
                                { "text": qsTr("System"), "scheme": 0 }
                            ]
                            delegate: Column {
                                id: tile
                                required property var modelData
                                spacing: 12 * root.dp1

                                T.Button {
                                    id: tileButton
                                    width: 100 * root.dp1; height: 100 * root.dp1
                                    onClicked: root.scheme = tile.modelData.scheme
                                    background: Rectangle {
                                        radius: 12 * root.dp1
                                        color: "transparent"
                                        border.width: 3 * root.dp1
                                        border.color: root.scheme === tile.modelData.scheme ? root.accent : "transparent"

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: 8 * root.dp1
                                            radius: 8 * root.dp1
                                            clip: true
                                            color: tile.modelData.scheme === 2 ? "#222222" : "#B0B0B0"
                                            border.width: 1
                                            border.color: "#404040"
                                            // System: half light, half dark
                                            Image {
                                                anchors.fill: parent
                                                visible: tile.modelData.scheme === 0
                                                source: "qrc:///misc/onboarding_system_tile.svg"
                                                sourceSize: Qt.size(width, height)
                                            }
                                        }
                                    }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: tile.modelData.text
                                    color: "#8F8F8F"
                                    font.pixelSize: 13 * root.dp1
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // preview of the player bar with the selected theme and color
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34 * root.dp1
                        radius: 4 * root.dp1
                        color: root.scheme === 1 ? "#D5D5D5" : "#191919"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12 * root.dp1
                            anchors.rightMargin: 12 * root.dp1
                            spacing: 12 * root.dp1

                            Text { font.family: VLCIcons.fontFamily; font.pixelSize: 14 * root.dp1; text: VLCIcons.previous; color: "#8F8F8F" }
                            Rectangle {
                                implicitWidth: 40 * root.dp1; implicitHeight: 22 * root.dp1; radius: 5 * root.dp1
                                color: root.accent
                                Text { anchors.centerIn: parent; font.family: VLCIcons.fontFamily; font.pixelSize: 14 * root.dp1; text: VLCIcons.play_filled; color: "#161616" }
                            }
                            Text { font.family: VLCIcons.fontFamily; font.pixelSize: 14 * root.dp1; text: VLCIcons.next; color: "#8F8F8F" }
                            Text { text: "00:02:10"; color: "#8F8F8F"; font.pixelSize: 11 * root.dp1 }
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 10 * root.dp1; radius: 3 * root.dp1
                                color: root.scheme === 1 ? "#E7E7E7" : "#090909"
                                Rectangle { width: parent.width * 0.08; height: parent.height; radius: parent.radius; color: Qt.alpha(root.accent, 0.35) }
                                Rectangle { x: parent.width * 0.08; width: 4 * root.dp1; height: parent.height; radius: 2 * root.dp1; color: root.accent }
                            }
                            Text { text: "00:25:40"; color: "#8F8F8F"; font.pixelSize: 11 * root.dp1 }
                        }
                    }
                }
            }

            // ---- 3. keyboard shortcuts ---------------------------------
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 40 * root.dp1
                    spacing: 26 * root.dp1

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Learn the basic keyboard shortcuts.")
                        color: "#C6C6C6"
                        font.pixelSize: 20 * root.dp1
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 10 * root.dp1
                        columns: 2
                        columnSpacing: 40 * root.dp1
                        rowSpacing: 12 * root.dp1

                        Shortcut { label: qsTr("Play / Pause"); keys: ["key-play-pause"] }
                        Shortcut { label: qsTr("Toggle Fullscreen"); keys: ["key-toggle-fullscreen"] }
                        Shortcut { label: qsTr("Seek Backward / Forward"); keys: ["key-jump-short", "key-jump+short"] }
                        Shortcut { label: qsTr("Increase / Decrease Volume"); keys: ["key-vol-up", "key-vol-down"] }
                        Shortcut { label: qsTr("Previous / Next Item"); keys: ["key-prev", "key-next"] }
                        Shortcut { label: qsTr("Take a Snapshot"); keys: ["key-snapshot"] }
                        Shortcut { label: qsTr("Next Frame"); keys: ["key-frame-next"] }
                        Shortcut { label: qsTr("Record"); keys: ["key-record"] }
                        Shortcut { label: qsTr("Cycle Subtitle Track"); keys: ["key-subtitle-track"] }
                        Shortcut { label: qsTr("Cycle Audio Track"); keys: ["key-audio-track"] }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: qsTr("Find the full list in the menu.")
                        color: "#6B6B6B"
                        font.pixelSize: 13 * root.dp1
                    }
                }
            }
        }

        // ---- bottom: accent dots (color page), Back / Next --------------
        RowLayout {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 30 * root.dp1 }
            spacing: 14 * root.dp1

            Repeater {
                model: root.page === 1 ? root.accents : []
                delegate: T.Button {
                    id: dot
                    required property var modelData
                    required property int index
                    implicitWidth: 34 * root.dp1; implicitHeight: 34 * root.dp1
                    onClicked: root.accentIndex = index
                    background: Rectangle {
                        radius: width / 2
                        color: "transparent"
                        border.width: root.accentIndex === dot.index ? 2 * root.dp1 : 0
                        border.color: Qt.alpha(dot.modelData, 0.6)
                        Rectangle {
                            anchors.centerIn: parent
                            width: 24 * root.dp1; height: 24 * root.dp1; radius: width / 2
                            color: dot.modelData
                            opacity: root.accentIndex === dot.index ? 1 : 0.55
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            PlainButton {
                visible: root.page > 0
                text: qsTr("Back")
                onClicked: root.page -= 1
            }
            PlainButton {
                primary: true
                text: root.page === 2 ? qsTr("Finish") : qsTr("Next")
                onClicked: root.page === 2 ? root.finish() : root.page += 1
            }
        }
    }

    component PlainButton: T.Button {
        id: button
        property bool primary: false
        implicitWidth: Math.max(100 * root.dp1, contentItem.implicitWidth + 32 * root.dp1)
        implicitHeight: 32 * root.dp1
        background: Rectangle {
            radius: 6 * root.dp1
            color: button.primary ? root.accent : "#1B1B1B"
            opacity: button.hovered ? 0.85 : 1
        }
        contentItem: Text {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: button.text
            color: button.primary ? "#161616" : "#8F8F8F"
            font.pixelSize: 14 * root.dp1
            font.weight: Font.DemiBold
        }
    }

    // a label and its keys as keycaps (VLC's current hotkeys)
    component Shortcut: RowLayout {
        id: sc
        property string label
        property var keys: []
        Layout.fillWidth: true
        spacing: 8 * root.dp1
        Text {
            Layout.fillWidth: true
            text: sc.label
            elide: Text.ElideRight
            color: "#8F8F8F"
            font.pixelSize: 13 * root.dp1
        }
        Repeater {
            model: sc.keys
            delegate: Row {
                required property var modelData
                required property int index
                spacing: 4 * root.dp1
                Text {
                    visible: index > 0
                    leftPadding: 4 * root.dp1
                    rightPadding: 4 * root.dp1
                    anchors.verticalCenter: parent.verticalCenter
                    text: "/"
                    color: "#404040"
                    font.pixelSize: 13 * root.dp1
                }
                Repeater {
                    model: VLCConfig.keyDisplayText(String(VLCConfig.value(modelData) ?? "")).split(", ")[0].split(" + ").filter((k) => k !== "")
                    // keycap of the design (Figma shortcuts page): 42 px high,
                    // radius 12, 3 px outline, words in capitals
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool word: modelData.length > 1
                        // narrower than the design's 23 px: four keys and the label share a row
                        readonly property real pad: (word ? 13 : 17) * root.dp1
                        implicitWidth: keyText.implicitWidth + 2 * pad
                        implicitHeight: 42 * root.dp1
                        width: implicitWidth; height: implicitHeight
                        radius: 12 * root.dp1
                        color: "#1B1B1B"
                        border.width: 3 * root.dp1
                        border.color: "#373737"
                        Text {
                            id: keyText
                            anchors.centerIn: parent
                            text: parent.word ? modelData.toUpperCase() : modelData
                            color: "#EAEAEA"
                            font.pixelSize: 16 * root.dp1
                            font.weight: Font.Light
                        }
                    }
                }
            }
        }
    }
}
