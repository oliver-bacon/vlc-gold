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
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Dialogs
import VLC.Menus
import VLC.Style
import VLC.Util
import VLC.Widgets as Widgets

// VLC's Media Information window (General, Metadata, Codec, Statistics) in
// the style of the settings window, like the Open Media window: the tabs in
// a row under the title bar, the values as setting rows below. Same data and editing
// as the classic dialog (dialogs/mediainfo): the metadata can be changed and
// saved to the file ("Save Metadata" shows once something is edited), the
// cover art can be downloaded or picked, Fingerprint, the Location below.
// Without an item it follows the playing media and has the Statistics tab.
Window {
    id: root

    transientParent: MainCtx.intfMainWindow
    flags: Qt.Dialog | Qt.FramelessWindowHint

    title: itemMode ? qsTr("Media Information") : qsTr("Current Media Information")

    // fixed size: what the General page needs; the other pages scroll
    readonly property real _fitWidth: VLCStyle.dp(700, VLCStyle.scale)
    readonly property real _contentHeight: titleBar.height
            + tabBar.implicitHeight + generalPage.implicitHeight + 2 * root._pageMargin
            + footer.height
    readonly property real _fitHeight: Screen.desktopAvailableHeight > 0
            ? Math.min(_contentHeight, Screen.desktopAvailableHeight - VLCStyle.dp(40, VLCStyle.scale))
            : _contentHeight
    width: _fitWidth
    height: _fitHeight
    minimumWidth: _fitWidth
    maximumWidth: _fitWidth
    minimumHeight: _fitHeight
    maximumHeight: _fitHeight

    color: theme.bg.primary

    // a window for one item of the library or the queue (no statistics)
    property bool itemMode: false
    readonly property var _tabs: itemMode ? ["general", "metadata", "codec"]
                                          : ["general", "metadata", "codec", "statistics"]
    property int currentTab: 0

    // the General fields were changed (not saved yet)
    property bool edited: false
    // cover art picked from a file, saved with the metadata
    property string pendingArt: ""
    property string saveError: ""

    readonly property real _pageMargin: VLCStyle.dp(20, VLCStyle.scale)
    readonly property real controlWidth: VLCStyle.dp(320, VLCStyle.scale)

    // colors of the settings window (SettingRow.qml)
    readonly property ColorContext colorContext: ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.View
    }
    readonly property ColorContext windowColorContext: ColorContext {
        id: windowTheme
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }
    readonly property ColorContext selectedColorContext: ColorContext {
        id: selectedTheme
        palette: VLCStyle.palette
        colorSet: ColorContext.TabButton
        focused: true
    }
    readonly property ColorContext itemColorContext: ColorContext {
        id: itemTheme
        palette: VLCStyle.palette
        colorSet: ColorContext.Item
    }
    readonly property color _well: windowTheme.bg.secondary
    readonly property color _surface: windowTheme.bg.primary
    readonly property color _selected: itemTheme.bg.highlight
    readonly property color _text: theme.fg.secondary
    readonly property color _mutedText: Qt.alpha(theme.fg.secondary, 0.7)
    readonly property real _radius: VLCStyle.dp(6, VLCStyle.scale)

    MediaInfoModel {
        id: info

        ctx: MainCtx
        editing: root.edited

        onMetaChanged: root._loadFields(false)
        onFingerprintApplied: {
            root._loadFields(true)
            root.edited = true
        }
    }

    // Fingerprint: its own window while it works and shows the identities
    FingerprintWindow {
        transientParent: root
        fingerprinter: info.fingerprinter
    }

    // ---- opening ------------------------------------------------------------

    // DialogsProvider: { tab: "general" | "codec" } for the playing media,
    // { item: SharedInputItem } for one item
    function reset(args) {
        if (args?.item !== undefined) {
            itemMode = true
            info.current = false
            info.item = args.item
        } else {
            itemMode = false
            info.current = true
        }
        const tab = _tabs.indexOf(args?.tab ?? "general")
        currentTab = tab >= 0 ? tab : 0
    }

    // the classic dialog hides on a second Ctrl+I / Ctrl+J on the same tab
    function isShowingTab(tab) {
        return _tabs[currentTab] === (tab ?? "general")
    }

    function open() {
        if (!visible) {
            const parentWindow = transientParent
            if (parentWindow) {
                x = parentWindow.x + (parentWindow.width - width) / 2
                y = parentWindow.y + Math.max(0, (parentWindow.height - height) / 2)
            }
        }
        show()
        raise()
        requestActivate()
    }

    // closing without saving drops the changes, as the classic dialog
    onVisibleChanged: {
        if (visible) {
            info.resetStats()
            return
        }
        edited = false
        pendingArt = ""
        saveError = ""
        info.reload()
        _loadFields(true)
    }

    Component.onCompleted: {
        if (MainCtx.createWindowWithoutRedirectionSurface) // Win32
            MainCtx.createWindowWithoutRedirectionSurface(this)
    }

    Shortcut {
        sequence: StandardKey.Cancel
        onActivated: root.close()
    }

    // ---- General: fields and saving -----------------------------------------

    property bool _loading: false

    // the item's values into the fields; kept while being edited
    function _loadFields(force) {
        if (edited && !force)
            return
        const m = info.meta
        _loading = true
        titleField.text = m.title ?? ""
        artistField.text = m.artist ?? ""
        albumField.text = m.album ?? ""
        genreField.text = m.genre ?? ""
        dateField.text = m.date ?? ""
        trackField.text = m.trackNumber ?? ""
        trackTotalField.text = m.trackTotal ?? ""
        languageField.text = m.language ?? ""
        publisherField.text = m.publisher ?? ""
        copyrightField.text = m.copyright ?? ""
        encodedByField.text = m.encodedBy ?? ""
        commentsField.text = m.description ?? ""
        _loading = false
    }

    function _edit() {
        if (!_loading)
            edited = true
    }

    function _save() {
        const error = info.save({
            "title": titleField.text,
            "artist": artistField.text,
            "album": albumField.text,
            "genre": genreField.text,
            "date": dateField.text,
            "trackNumber": trackField.text,
            "trackTotal": trackTotalField.text,
            "language": languageField.text,
            "publisher": publisherField.text,
            "copyright": copyrightField.text,
            "encodedBy": encodedByField.text,
            "description": commentsField.text
        }, pendingArt)
        saveError = error
        if (error === "") {
            edited = false
            pendingArt = ""
            _loadFields(true)
        }
    }

    readonly property string _coverSource: {
        const art = pendingArt !== "" ? pendingArt : info.artwork
        return art !== "" ? VLCAccessImage.uri(art) : ""
    }

    // ---- title bar (as the settings window) ---------------------------------------

    Rectangle {
        id: titleBar

        readonly property ColorContext colorContext: ColorContext {
            id: titleTheme
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: VLCStyle.globalToolbar_height
        color: titleTheme.bg.primary

        DragHandler {
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onActiveChanged: if (active) root.startSystemMove()
        }

        Text {
            anchors.centerIn: parent
            text: root.title
            color: titleTheme.fg.secondary
            font.pixelSize: VLCStyle.fontSize_large
        }

        Widgets.CSDWindowButton {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            iconTxt: ((MainCtx.osName === MainCtx.Windows) && (MainCtx.osVersion >= 10)) ? "" : VLCIcons.window_close
            isThemeDark: titleTheme.palette.isDark
            color: hovered ? "white" : titleTheme.fg.primary
            hoverColor: "red"
            onClicked: root.close()
        }
    }

    // ---- tabs under the title bar (as the classic dialog) -------------------------

    WinTabBar {
        id: tabBar

        anchors { top: titleBar.bottom; left: parent.left; right: parent.right }
        height: implicitHeight
        currentTab: root.currentTab
        onPicked: index => root.currentTab = index
        tabs: {
            const list = [
                { "text": qsTr("General"), "icon": "file_properties_metadata" },
                { "text": qsTr("Metadata"), "icon": "view_list_view" },
                { "text": qsTr("Codec"), "icon": "player_video" },
                { "text": qsTr("Statistics"), "icon": "player_audio" }
            ]
            return list.slice(0, root._tabs.length)
        }
    }

    // ---- pages ---------------------------------------------------------------------------

    Flickable {
        id: pane

        anchors { top: tabBar.bottom; left: parent.left; right: parent.right; bottom: footer.top }
        contentHeight: pageColumn.implicitHeight + 2 * root._pageMargin
        interactive: contentHeight > height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        T.ScrollBar.vertical: ScrollBar { visible: pane.interactive }

        ColumnLayout {
            id: pageColumn

            x: VLCStyle.margin_large
            y: root._pageMargin
            width: pane.width - 2 * VLCStyle.margin_large
            spacing: 0

            StackLayout {
                Layout.fillWidth: true
                currentIndex: root.currentTab
                // only the shown page counts
                Layout.preferredHeight: [generalPage, metadataPage, codecPage, statisticsPage][currentIndex].implicitHeight

                // General
                Page {
                    id: generalPage

                    // cover art next to title, artist and album
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: VLCStyle.margin_xsmall
                        Layout.bottomMargin: VLCStyle.margin_small
                        spacing: VLCStyle.margin_large

                        // click: "Download cover art" / "Add cover art from file"
                        T.AbstractButton {
                            id: coverButton

                            Layout.preferredWidth: VLCStyle.dp(132, VLCStyle.scale)
                            Layout.preferredHeight: VLCStyle.dp(132, VLCStyle.scale)
                            Layout.alignment: Qt.AlignTop
                            enabled: info.hasItem

                            Accessible.name: qsTr("Cover art")

                            onClicked: coverMenu.popup(coverButton.mapToGlobal(0, coverButton.height + VLCStyle.dp(2, VLCStyle.scale)), [
                                { "text": qsTr("Download cover art") },
                                { "text": qsTr("Add cover art from file") }
                            ])

                            StringListMenu {
                                id: coverMenu
                                ctx: MainCtx
                                onSelected: (index, _) => {
                                    if (index === 0) {
                                        info.downloadArt()
                                    } else {
                                        const url = info.pickArtFile()
                                        if (url !== "") {
                                            root.pendingArt = url
                                            root.edited = true
                                        }
                                    }
                                }
                            }

                            background: Rectangle {
                                radius: root._radius
                                color: root._well
                                border.width: coverButton.visualFocus ? VLCStyle.focus_border : VLCStyle.dp(2, VLCStyle.scale)
                                border.color: coverButton.visualFocus ? theme.visualFocus : root._surface
                                clip: true

                                Image {
                                    id: cover

                                    anchors.fill: parent
                                    anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
                                    source: root._coverSource
                                    sourceSize: Qt.size(width * 2, height * 2)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }

                                Image {
                                    anchors.centerIn: parent
                                    visible: cover.status !== Image.Ready
                                    width: parent.width * 0.6
                                    height: width
                                    sourceSize: Qt.size(width * 2, height * 2)
                                    source: VLCStyle.noArtAlbumCover
                                    fillMode: Image.PreserveAspectFit
                                }

                                // "Change" on hover
                                Rectangle {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: VLCStyle.dp(2, VLCStyle.scale) }
                                    height: VLCStyle.dp(30, VLCStyle.scale)
                                    radius: VLCStyle.dp(4, VLCStyle.scale)
                                    visible: coverButton.hovered && coverButton.enabled
                                    color: Qt.alpha(root._well, 0.85)

                                    T.Label {
                                        anchors.centerIn: parent
                                        text: qsTr("Change")
                                        color: root._text
                                        font.pixelSize: VLCStyle.fontSize_normal
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 0

                            Row2 {
                                label: qsTr("Title")
                                Field { id: titleField }
                            }
                            Row2 {
                                label: qsTr("Artist")
                                Field { id: artistField }
                            }
                            Row2 {
                                label: qsTr("Album")
                                Field { id: albumField }
                            }
                        }
                    }

                    SectionTitle { text: qsTr("Details") }

                    Row2 {
                        label: qsTr("Genre")
                        Field { id: genreField }
                    }
                    Row2 {
                        label: qsTr("Date")
                        Field {
                            id: dateField
                            implicitWidth: VLCStyle.dp(140, VLCStyle.scale)
                            horizontalAlignment: TextInput.AlignRight
                        }
                    }
                    Row2 {
                        label: qsTr("Track number")
                        Field {
                            id: trackField
                            implicitWidth: VLCStyle.dp(80, VLCStyle.scale)
                            horizontalAlignment: TextInput.AlignRight
                        }
                        T.Label {
                            text: "/"
                            color: root._mutedText
                            font.pixelSize: VLCStyle.fontSize_large
                        }
                        Field {
                            id: trackTotalField
                            implicitWidth: VLCStyle.dp(80, VLCStyle.scale)
                            horizontalAlignment: TextInput.AlignRight
                        }
                    }
                    Row2 {
                        label: qsTr("Language")
                        Field { id: languageField }
                    }
                    Row2 {
                        label: qsTr("Publisher")
                        Field { id: publisherField }
                    }
                    Row2 {
                        label: qsTr("Copyright")
                        Field { id: copyrightField }
                    }
                    Row2 {
                        label: qsTr("Encoded by")
                        Field { id: encodedByField }
                    }
                    // live streams (radio, TV): what is on now
                    Row2 {
                        label: qsTr("Now playing")
                        ValueText {
                            Layout.preferredWidth: root.controlWidth
                            horizontalAlignment: Text.AlignRight
                            wrapMode: Text.Wrap
                            text: info.meta.nowPlaying ?? ""
                        }
                    }
                    Row2 {
                        label: qsTr("Find meta data using audio fingerprinting")
                        enabled: info.canFingerprint
                        SettingButton {
                            text: qsTr("Fingerprint")
                            onClicked: info.fingerprint()
                        }
                    }

                    SectionTitle { text: qsTr("Comments") }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: VLCStyle.dp(96, VLCStyle.scale)
                        radius: root._radius
                        color: root._well
                        border.width: VLCStyle.dp(2, VLCStyle.scale)
                        border.color: commentsField.activeFocus ? theme.accent : root._surface
                        enabled: info.hasItem
                        opacity: enabled ? 1.0 : 0.4

                        Flickable {
                            id: commentsFlick

                            anchors.fill: parent
                            anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
                            clip: true
                            contentHeight: commentsField.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            T.ScrollBar.vertical: ScrollBar { }

                            T.TextArea {
                                id: commentsField

                                width: commentsFlick.width
                                implicitHeight: Math.max(commentsFlick.height, contentHeight + topPadding + bottomPadding)
                                padding: VLCStyle.dp(10, VLCStyle.scale)
                                wrapMode: TextEdit.Wrap
                                textFormat: TextEdit.PlainText
                                selectByMouse: true
                                color: root._text
                                selectionColor: root._selected
                                selectedTextColor: theme.fg.primary
                                font.pixelSize: VLCStyle.fontSize_large
                                onTextChanged: root._edit()
                            }
                        }
                    }
                }

                // Metadata
                Page {
                    id: metadataPage

                    SectionTitle { text: qsTr("Extra Metadata") }

                    Description {
                        text: qsTr("Extra metadata and other information are shown in this panel.")
                    }

                    Empty {
                        visible: info.extraMeta.length === 0
                        text: qsTr("No extra metadata.")
                    }

                    Repeater {
                        model: info.extraMeta
                        InfoRow {
                            required property var modelData
                            label: modelData.name
                            value: modelData.value
                        }
                    }
                }

                // Codec
                Page {
                    id: codecPage

                    SectionTitle { text: qsTr("Codec Details") }

                    Description {
                        text: qsTr("Information about what your media or stream is made of.\nMuxer, Audio and Video Codecs, Subtitles are shown.")
                    }

                    Empty {
                        visible: info.codecInfo.length === 0
                        text: qsTr("No codec information.")
                    }

                    Repeater {
                        model: info.codecInfo

                        ColumnLayout {
                            id: category

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 0

                            SectionTitle { text: category.modelData.name }

                            Repeater {
                                model: category.modelData.infos
                                InfoRow {
                                    required property var modelData
                                    label: modelData.name
                                    value: modelData.value
                                }
                            }
                        }
                    }
                }

                // Statistics (playing media only)
                Page {
                    id: statisticsPage

                    readonly property var s: info.stats

                    function count(key) {
                        return s[key] !== undefined ? String(s[key]) : "0"
                    }

                    SectionTitle { text: qsTr("Audio") }
                    StatRow { label: qsTr("Decoded"); value: statisticsPage.count("decodedAudio"); unit: qsTr("blocks") }
                    StatRow { label: qsTr("Played"); value: statisticsPage.count("playedBuffers"); unit: qsTr("buffers") }
                    StatRow { label: qsTr("Lost"); value: statisticsPage.count("lostBuffers"); unit: qsTr("buffers") }

                    SectionTitle { text: qsTr("Video") }
                    StatRow { label: qsTr("Decoded"); value: statisticsPage.count("decodedVideo"); unit: qsTr("blocks") }
                    StatRow { label: qsTr("Displayed"); value: statisticsPage.count("displayedPictures"); unit: qsTr("frames") }
                    StatRow { label: qsTr("Late"); value: statisticsPage.count("latePictures"); unit: qsTr("frames") }
                    StatRow { label: qsTr("Lost"); value: statisticsPage.count("lostPictures"); unit: qsTr("frames") }

                    SectionTitle { text: qsTr("Input/Read") }
                    StatRow { label: qsTr("Media data size"); value: statisticsPage.count("readBytes"); unit: "KiB" }
                    StatRow { label: qsTr("Input bitrate"); value: statisticsPage.count("inputBitrate"); unit: "kb/s" }

                    BitrateGraph {
                        Layout.fillWidth: true
                        Layout.topMargin: VLCStyle.margin_xxsmall
                        Layout.bottomMargin: VLCStyle.margin_small
                    }

                    StatRow { label: qsTr("Demuxed data size"); value: statisticsPage.count("demuxBytes"); unit: "KiB" }
                    StatRow { label: qsTr("Content bitrate"); value: statisticsPage.count("demuxBitrate"); unit: "kb/s" }
                    StatRow { label: qsTr("Discarded (corrupted)"); value: statisticsPage.count("demuxCorrupted") }
                    StatRow { label: qsTr("Dropped (discontinued)"); value: statisticsPage.count("demuxDiscontinuity") }
                }
            }
        }
    }

    // ---- Location and buttons ------------------------------------------------------------

    Rectangle {
        id: footer

        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: VLCStyle.dp(60, VLCStyle.scale)
        color: windowTheme.bg.secondary

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: VLCStyle.margin_large
            anchors.rightMargin: VLCStyle.margin_large
            spacing: VLCStyle.margin_xsmall

            T.Label {
                text: qsTr("Location:")
                color: root._mutedText
                font.pixelSize: VLCStyle.fontSize_large
            }

            // selectable, as the classic read-only line
            TextInput {
                id: locationText

                Layout.fillWidth: true
                Layout.rightMargin: VLCStyle.margin_small
                text: info.location
                readOnly: true
                selectByMouse: true
                clip: true
                color: theme.fg.primary
                selectionColor: root._selected
                selectedTextColor: theme.fg.primary
                font.pixelSize: VLCStyle.fontSize_large
                // the start of a long path stays visible
                onTextChanged: cursorPosition = 0

                ToolTipArea { text: locationText.contentWidth > locationText.width ? info.location : "" }
            }

            T.Label {
                visible: root.saveError !== ""
                text: root.saveError
                color: theme.fg.negative
                font.pixelSize: VLCStyle.fontSize_normal
            }

            SettingButton {
                highlighted: true
                visible: root.edited && root._tabs[root.currentTab] === "general"
                text: qsTr("Save Metadata")
                onClicked: root._save()
            }

            SettingButton {
                text: qsTr("Close")
                onClicked: root.close()
            }
        }
    }

    // outline instead of the system frame
    Rectangle {
        anchors.fill: parent
        z: 99
        color: "transparent"
        border.width: VLCStyle.border
        border.color: titleTheme.border
    }

    // ---- components (as OpenMediaDialog.qml) ---------------------------------------------

    // thin scroll bar in the colors of the window, wider while used
    component ScrollBar: T.ScrollBar {
        id: bar

        readonly property bool _used: bar.hovered || bar.pressed

        // templates have no size of their own
        implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                implicitContentWidth + leftPadding + rightPadding)
        implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                 implicitContentHeight + topPadding + bottomPadding)

        policy: T.ScrollBar.AsNeeded
        padding: VLCStyle.dp(2, VLCStyle.scale)
        minimumSize: 0.1

        background: Rectangle {
            radius: width / 2
            visible: bar._used && bar.size < 1.0
            color: root._surface
        }
        contentItem: Rectangle {
            implicitWidth: bar._used ? VLCStyle.scrollBarInteractingSize : VLCStyle.scrollBarNonInteractingSize
            radius: width / 2
            visible: bar.size < 1.0
            color: Qt.alpha(theme.fg.secondary, bar._used ? 0.8 : 0.5)

            Behavior on implicitWidth {
                NumberAnimation { duration: VLCStyle.duration_veryShort; easing.type: Easing.OutSine }
            }
        }
    }

    component Page: ColumnLayout {
        spacing: 0
    }

    component SectionTitle: T.Label {
        Layout.fillWidth: true
        topPadding: VLCStyle.dp(10, VLCStyle.scale)
        bottomPadding: VLCStyle.dp(10, VLCStyle.scale)
        color: theme.fg.primary
        opacity: 0.85
        font.pixelSize: VLCStyle.fontSize_xlarge
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    component Description: T.Label {
        Layout.fillWidth: true
        Layout.bottomMargin: VLCStyle.margin_small
        wrapMode: Text.WordWrap
        color: root._mutedText
        font.pixelSize: VLCStyle.fontSize_normal
    }

    // shown instead of an empty list
    component Empty: T.Label {
        Layout.fillWidth: true
        Layout.topMargin: VLCStyle.margin_small
        horizontalAlignment: Text.AlignHCenter
        color: root._mutedText
        font.pixelSize: VLCStyle.fontSize_large
    }

    // label on the left, controls on the right; greyed out when disabled
    component Row2: RowLayout {
        property string label

        Layout.fillWidth: true
        Layout.minimumHeight: VLCStyle.dp(46, VLCStyle.scale)
        spacing: VLCStyle.margin_xsmall
        opacity: enabled ? 1.0 : 0.4

        T.Label {
            Layout.fillWidth: true
            Layout.rightMargin: VLCStyle.margin_small
            text: parent.label
            color: root._text
            font.pixelSize: VLCStyle.fontSize_large
            elide: Text.ElideRight
        }
    }

    // a value to read (and copy): name on the left, the value on the right
    component InfoRow: RowLayout {
        id: infoRow

        property string label
        property string value

        Layout.fillWidth: true
        Layout.minimumHeight: VLCStyle.dp(38, VLCStyle.scale)
        spacing: VLCStyle.margin_small

        T.Label {
            Layout.preferredWidth: parent.width * 0.4
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: VLCStyle.dp(9, VLCStyle.scale)
            text: infoRow.label
            color: root._mutedText
            font.pixelSize: VLCStyle.fontSize_large
            elide: Text.ElideRight
        }

        ValueText {
            Layout.fillWidth: true
            // the rest of the row, however long the value
            Layout.preferredWidth: 0
            Layout.topMargin: VLCStyle.dp(9, VLCStyle.scale)
            Layout.bottomMargin: VLCStyle.dp(9, VLCStyle.scale)
            text: infoRow.value
            wrapMode: Text.Wrap
        }
    }

    // a counter of the statistics, with its unit
    component StatRow: RowLayout {
        property string label
        property string value
        property string unit

        Layout.fillWidth: true
        Layout.minimumHeight: VLCStyle.dp(38, VLCStyle.scale)
        spacing: VLCStyle.margin_xsmall

        T.Label {
            Layout.fillWidth: true
            text: parent.label
            color: root._text
            font.pixelSize: VLCStyle.fontSize_large
            elide: Text.ElideRight
        }
        T.Label {
            text: parent.value
            color: theme.fg.primary
            font.pixelSize: VLCStyle.fontSize_large
        }
        T.Label {
            Layout.preferredWidth: VLCStyle.dp(64, VLCStyle.scale)
            text: parent.unit
            color: root._mutedText
            font.pixelSize: VLCStyle.fontSize_large
        }
    }

    // read-only text that can be selected and copied
    component ValueText: TextEdit {
        readOnly: true
        selectByMouse: true
        textFormat: TextEdit.PlainText
        color: theme.fg.primary
        selectionColor: root._selected
        selectedTextColor: theme.fg.primary
        font.pixelSize: VLCStyle.fontSize_large
        clip: true
    }

    // the input bitrate: last 60 samples over the whole playback (60 blocks),
    // as the classic graph
    component BitrateGraph: ColumnLayout {
        id: graph

        readonly property var recent: info.recentBitrates
        readonly property var overall: info.overallBitrates
        readonly property real maximum: Math.max(1, ...recent, ...overall)

        spacing: VLCStyle.margin_xxsmall

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(110, VLCStyle.scale)
            radius: root._radius
            color: root._well
            border.width: VLCStyle.dp(2, VLCStyle.scale)
            border.color: root._surface

            Item {
                id: plot

                anchors.fill: parent
                anchors.margins: VLCStyle.dp(8, VLCStyle.scale)
                readonly property real step: width / 60

                // rulers at a quarter, half and three quarters
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        x: 0
                        y: plot.height * (index + 1) / 4
                        width: plot.width
                        height: 1
                        color: root._surface
                    }
                }

                Repeater {
                    model: graph.overall
                    Rectangle {
                        required property var modelData
                        required property int index
                        x: index * plot.step
                        width: Math.max(1, plot.step - 1)
                        height: plot.height * modelData / graph.maximum
                        y: plot.height - height
                        color: Qt.alpha(root._text, 0.35)
                    }
                }

                Repeater {
                    model: graph.recent
                    Rectangle {
                        required property var modelData
                        required property int index
                        x: index * plot.step + plot.step / 4
                        width: Math.max(1, plot.step / 2)
                        height: plot.height * modelData / graph.maximum
                        y: plot.height - height
                        color: theme.accent
                    }
                }

                T.Label {
                    anchors { right: parent.right; top: parent.top }
                    text: Math.round(graph.maximum) + " kb/s"
                    color: root._mutedText
                    font.pixelSize: VLCStyle.fontSize_small
                }
            }
        }

        RowLayout {
            spacing: VLCStyle.margin_small

            Rectangle { implicitWidth: VLCStyle.dp(10, VLCStyle.scale); implicitHeight: implicitWidth; radius: 2; color: theme.accent }
            T.Label { text: qsTr("Last 60 seconds"); color: root._text; font.pixelSize: VLCStyle.fontSize_normal }
            Rectangle {
                Layout.leftMargin: VLCStyle.margin_small
                implicitWidth: VLCStyle.dp(10, VLCStyle.scale); implicitHeight: implicitWidth; radius: 2
                color: Qt.alpha(root._text, 0.35)
            }
            T.Label { text: qsTr("Overall"); color: root._text; font.pixelSize: VLCStyle.fontSize_normal }
        }
    }

    // text input: well with a 2px surface border, accent while editing
    component InputField: T.TextField {
        id: field

        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
        leftPadding: VLCStyle.dp(12, VLCStyle.scale)
        rightPadding: VLCStyle.dp(12, VLCStyle.scale)
        verticalAlignment: TextInput.AlignVCenter

        color: root._text
        selectionColor: root._selected
        selectedTextColor: theme.fg.primary
        placeholderTextColor: Qt.alpha(theme.fg.secondary, 0.4)
        font.pixelSize: VLCStyle.fontSize_large
        selectByMouse: true

        background: Rectangle {
            color: root._well
            radius: root._radius
            border.width: VLCStyle.dp(2, VLCStyle.scale)
            border.color: field.activeFocus ? theme.accent : root._surface

            // templates do not draw the placeholder
            T.Label {
                anchors.fill: parent
                anchors.leftMargin: field.leftPadding
                anchors.rightMargin: field.rightPadding
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: field.horizontalAlignment === TextInput.AlignRight ? Text.AlignRight : Text.AlignLeft
                visible: field.text === "" && !field.preeditText
                text: field.placeholderText
                color: field.placeholderTextColor
                font: field.font
                elide: Text.ElideRight
            }
        }
    }

    // a metadata field of the General page
    component Field: InputField {
        implicitWidth: root.controlWidth
        enabled: info.hasItem
        opacity: enabled ? 1.0 : 0.4
        onTextEdited: root._edit()
    }

    // button of the settings window; highlighted = the main one
    component SettingButton: T.Button {
        id: button

        implicitWidth: Math.max(VLCStyle.dp(100, VLCStyle.scale), contentItem.implicitWidth + VLCStyle.dp(28, VLCStyle.scale))
        implicitHeight: VLCStyle.dp(34, VLCStyle.scale)
        font.pixelSize: VLCStyle.fontSize_large
        font.weight: Font.DemiBold

        background: Rectangle {
            radius: root._radius
            readonly property color fill: button.highlighted ? root._selected : root._surface
            color: button.hovered && button.enabled ? Qt.lighter(fill, 1.2) : fill
            border.width: button.visualFocus ? VLCStyle.focus_border : 0
            border.color: theme.visualFocus
        }
        contentItem: T.Label {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: button.text
            font: button.font
            opacity: button.enabled ? 1.0 : 0.4
            color: button.highlighted ? theme.accent : root._text
        }
    }

    // tool tip over its parent
    component ToolTipArea: HoverHandler {
        id: hover

        property string text

        property T.ToolTip tip: T.ToolTip {
            parent: hover.parent
            visible: hover.hovered && hover.text !== ""
            delay: VLCStyle.delayToolTipAppear
            text: hover.text
            y: -height - VLCStyle.dp(6, VLCStyle.scale)
            implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
            implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
            width: Math.min(implicitWidth, VLCStyle.dp(420, VLCStyle.scale))
            padding: VLCStyle.margin_small
            contentItem: T.Label {
                text: hover.text
                color: theme.fg.primary
                wrapMode: Text.WrapAnywhere
                font.pixelSize: VLCStyle.fontSize_normal
            }
            background: Rectangle {
                color: windowTheme.bg.primary
                radius: root._radius
                border.width: VLCStyle.dp(2, VLCStyle.scale)
                border.color: root._well
            }
        }
    }
}
