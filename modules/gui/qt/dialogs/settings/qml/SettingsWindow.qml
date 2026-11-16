/*****************************************************************************
 * Copyright (C) 2026 the VideoLAN team
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
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Dialogs
import VLC.Widgets as Widgets

// Settings window from the "VLC Redesign" Figma file: categories on the
// left (App / Media / System), a search field, and the options of the
// selected category on the right. Every change is saved immediately.
// The header's toggle switches the window to "All Settings", every VLC
// option (AllSettingsView.qml), and back.
Window {
    id: root

    transientParent: MainCtx.intfMainWindow
    // VLC draws the title bar like the player's top bar (TitleBar below)
    flags: Qt.Window | Qt.FramelessWindowHint

    title: allSettings ? qsTr("All Settings") : qsTr("Settings")

    width: VLCStyle.dp(1048, VLCStyle.scale)
    height: VLCStyle.dp(865, VLCStyle.scale)
    minimumWidth: VLCStyle.dp(760, VLCStyle.scale)
    minimumHeight: VLCStyle.dp(480, VLCStyle.scale)

    color: theme.bg.primary

    property string currentPage: "general"
    // showing "All Settings" instead of these settings
    property bool allSettings: false
    // rows marked `aout` show only for these audio outputs
    property string currentAout: String(VLCConfig.value("aout") ?? "")
    readonly property string searchText: searchField.text.trim().toLowerCase()
    readonly property bool searching: searchText !== ""

    function open() {
        // show() leaves a minimized window minimized
        if (visibility === Window.Minimized)
            showNormal()
        else
            show()
        raise()
        requestActivate()
    }

    // a page ("Open Advanced Settings" of the player's settings panel)
    function openPage(page) {
        searchField.text = ""
        currentPage = page
        allSettings = false
        open()
    }

    // DialogsProvider.allSettingsDialog()
    function openAllSettings() {
        allSettings = true
        open()
    }

    function openShortcuts() {
        DialogsProvider.keyboardShortcutsDialog()
    }

    function resetPreferences() {
        VLCConfig.resetPreferences()
    }

    function fileAssociations() {
        VLCConfig.fileAssociations()
    }

    function clearRecent() {
        VLCConfig.clearRecentMedia()
    }

    function rescanLibrary() {
        VLCConfig.reloadMediaLibrary()
    }

    function customizePlayer() {
        DialogsProvider.customizePlayerDialog()
    }

    Connections {
        target: VLCConfig
        function onValueChanged(name) {
            if (name === "" || name === "aout")
                root.currentAout = String(VLCConfig.value("aout") ?? "")
        }
    }

    function openAddons() {
        DialogsProvider.pluginDialog()
    }

    function rowAvailable(row) {
        if (row.os && Qt.platform.os !== row.os)
            return false
        if (row.needsML && !MainCtx.mediaLibraryAvailable)
            return false
        if (row.aout && !row.aout.includes(currentAout))
            return false
        if (["colorScheme", "action", "layout", "intfScale", "caching", "qtStyle", "startVolume", "uiToggle"].includes(row.kind))
            return true
        if (row.kind === "intf")
            return VLCConfig.moduleExists(row.module)
        if (row.kind === "language")
            return VLCConfig.languages().length > 0
        if (row.kind === "mediaFolders")
            return MainCtx.mediaLibraryAvailable
        if (row.kind === "openSubtitles")
            return VLCOpenSubtitles.available
        if (row.greyIfMissing)
            return true // SettingRow greys it out when the build lacks it
        if (row.kind === "filter")
            return VLCConfig.exists(row.list) && VLCConfig.moduleExists(row.module)
        return VLCConfig.exists(row.option)
    }

    function rowMatches(row, section) {
        // Also match the section title and VLC's own description of the
        // option, so that the names used by the classic preferences work too
        const haystack = [row.label, section.title,
                          row.option ? VLCConfig.text(row.option) : "",
                          row.option ?? ""].join("\n").toLowerCase()
        return haystack.indexOf(searchText) >= 0
    }

    function rowShown(row, section) {
        if (!rowAvailable(row))
            return false
        return !searching || rowMatches(row, section)
    }

    // Pages shown on the right: the selected one, or every page while searching
    readonly property var shownPages: {
        if (!searching)
            return [currentPage]
        const result = []
        for (const group of settingsModel.groups)
            for (const pageId of group.pages)
                result.push(pageId)
        return result
    }

    onCurrentPageChanged: contentFlickable.contentY = 0

    Component.onCompleted: {
        if (MainCtx.createWindowWithoutRedirectionSurface) { // Win32
            const ret = MainCtx.createWindowWithoutRedirectionSurface(this)
            if (!ret)
                console.debug("MainCtx::createWindowWithoutRedirectionSurface(): returned false for window", this)
        }
    }

    SettingsModel {
        id: settingsModel
    }

    Shortcut {
        enabled: !root.allSettings
        sequence: StandardKey.Find
        onActivated: searchField.forceActiveFocus()
    }

    Shortcut {
        enabled: !root.allSettings
        sequence: StandardKey.Cancel
        onActivated: {
            if (searchField.text !== "")
                searchField.text = ""
            else
                root.close()
        }
    }

    // Title bar in the style of the player's top bar: cone, title in the
    // middle, minimize / maximize / close (WindowButtons.qml)
    Rectangle {
        id: titleBar

        readonly property ColorContext colorContext: ColorContext {
            id: titleTheme
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }

        readonly property bool useWinIcons: ((MainCtx.osName === MainCtx.Windows) && (MainCtx.osVersion >= 10))
        readonly property bool maximized: root.visibility === Window.Maximized

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: VLCStyle.globalToolbar_height
        color: titleTheme.bg.primary

        // drag to move, double-click to maximize
        TapHandler {
            gesturePolicy: TapHandler.DragThreshold
            onDoubleTapped: titleBar.toggleMaximized()
        }
        DragHandler {
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onActiveChanged: if (active) root.startSystemMove()
        }

        function toggleMaximized() {
            if (maximized)
                root.showNormal()
            else
                root.showMaximized()
        }

        Widgets.BannerCone {
            anchors.left: parent.left
            anchors.leftMargin: VLCStyle.margin_small
            anchors.verticalCenter: parent.verticalCenter
            sourceSize.width: VLCStyle.icon_normal
            sourceSize.height: VLCStyle.icon_normal
            color: titleTheme.accent
        }

        Text {
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - 2 * windowButtons.width)
            text: root.title
            elide: Text.ElideRight
            color: titleTheme.fg.secondary
            font.pixelSize: VLCStyle.fontSize_large
        }

        component TitleButton: Widgets.CSDWindowButton {
            property bool isClose: false
            height: titleBar.height
            isThemeDark: titleTheme.palette.isDark
            color: (isClose && hovered) ? "white" : titleTheme.fg.primary
            hoverColor: isClose ? "red" : titleTheme.fg.primary.alpha(0.12)
        }

        Row {
            id: windowButtons

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            TitleButton {
                iconTxt: titleBar.useWinIcons ? "\uE921" : VLCIcons.window_minimize
                onClicked: root.showMinimized()
            }
            TitleButton {
                iconTxt: titleBar.useWinIcons ? (titleBar.maximized ? "\uE923" : "\uE922")
                                              : (titleBar.maximized ? VLCIcons.window_restore : VLCIcons.window_maximize)
                onClicked: titleBar.toggleMaximized()
            }
            TitleButton {
                isClose: true
                iconTxt: titleBar.useWinIcons ? "\uE8BB" : VLCIcons.window_close
                onClicked: root.close()
            }
        }
    }

    Item {
        id: content

        anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: !root.allSettings

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

        readonly property ColorContext tabColorContext: ColorContext {
            id: selectedTheme
            palette: VLCStyle.palette
            colorSet: ColorContext.TabButton
            focused: true
        }

        // Header: search field and the title of the page
        Rectangle {
            id: header

            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: VLCStyle.dp(50, VLCStyle.scale)
            color: windowTheme.bg.secondary

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.margin_xsmall
                anchors.rightMargin: VLCStyle.dp(14, VLCStyle.scale) + modeButton.width
                spacing: 0

                T.TextField {
                    id: searchField

                    // as wide as the sidebar's panel, so the title below
                    // starts where the page does
                    Layout.preferredWidth: sidebar.width - 2 * VLCStyle.margin_xsmall
                    Layout.preferredHeight: VLCStyle.dp(34, VLCStyle.scale)

                    leftPadding: VLCStyle.dp(42, VLCStyle.scale)
                    rightPadding: VLCStyle.margin_xsmall
                    verticalAlignment: TextInput.AlignVCenter

                    placeholderText: qsTr("Search")
                    placeholderTextColor: Qt.alpha(theme.fg.secondary, 0.5)
                    color: theme.fg.primary
                    selectionColor: theme.accent
                    font.pixelSize: VLCStyle.fontSize_large

                    Accessible.name: qsTr("Search settings")

                    background: Rectangle {
                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: windowTheme.bg.primary
                        border.width: searchField.activeFocus ? VLCStyle.border : 0
                        border.color: theme.accent

                        T.Label {
                            anchors.left: parent.left
                            anchors.leftMargin: VLCStyle.margin_xsmall
                            anchors.verticalCenter: parent.verticalCenter
                            text: VLCIcons.search
                            font.family: VLCIcons.fontFamily
                            font.pixelSize: VLCStyle.icon_normal
                            color: theme.fg.secondary
                        }

                        // Templates do not draw the placeholder text
                        T.Label {
                            anchors.left: parent.left
                            anchors.leftMargin: searchField.leftPadding
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchField.text === "" && !searchField.activeFocus
                            text: searchField.placeholderText
                            color: searchField.placeholderTextColor
                            font: searchField.font
                        }
                    }
                }

                T.Label {
                    Layout.fillWidth: true
                    Layout.leftMargin: VLCStyle.margin_xlarge
                    text: root.searching ? qsTr("Search results")
                                         : settingsModel.pages[root.currentPage].title
                    color: theme.fg.secondary
                    font.pixelSize: VLCStyle.fontSize_xlarge
                    elide: Text.ElideRight
                }
            }
        }

        // Categories
        Rectangle {
            id: sidebar

            anchors { top: header.bottom; left: parent.left; bottom: parent.bottom }
            width: VLCStyle.dp(236, VLCStyle.scale)
            color: theme.bg.primary

            Rectangle {
                anchors.fill: parent
                anchors.margins: VLCStyle.margin_xsmall
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: windowTheme.bg.primary

                Flickable {
                    anchors.fill: parent
                    anchors.margins: VLCStyle.dp(6, VLCStyle.scale)
                    contentHeight: categoryColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: categoryColumn

                        width: parent.width
                        spacing: VLCStyle.margin_xsmall

                        Repeater {
                            model: settingsModel.groups

                            ColumnLayout {
                                id: group

                                required property var modelData

                                Layout.fillWidth: true
                                spacing: VLCStyle.margin_xsmall

                                T.Label {
                                    Layout.fillWidth: true
                                    leftPadding: VLCStyle.dp(10, VLCStyle.scale)
                                    topPadding: VLCStyle.margin_xsmall
                                    bottomPadding: VLCStyle.margin_xsmall
                                    text: group.modelData.title
                                    color: Qt.alpha(theme.fg.secondary, 0.7)
                                    font.pixelSize: VLCStyle.fontSize_large
                                }

                                Repeater {
                                    model: group.modelData.pages

                                    T.AbstractButton {
                                        id: categoryButton

                                        required property string modelData

                                        readonly property var page: settingsModel.pages[modelData]
                                        readonly property bool selected: !root.searching && root.currentPage === modelData

                                        Layout.fillWidth: true
                                        implicitHeight: VLCStyle.dp(40, VLCStyle.scale)

                                        onClicked: {
                                            searchField.text = ""
                                            root.currentPage = modelData
                                        }

                                        Accessible.role: Accessible.PageTab
                                        Accessible.name: page.name

                                        background: Rectangle {
                                            radius: VLCStyle.dp(2, VLCStyle.scale)
                                            color: (categoryButton.selected || categoryButton.hovered)
                                                   ? selectedTheme.bg.primary : "transparent"
                                            border.width: categoryButton.visualFocus ? VLCStyle.focus_border : 0
                                            border.color: theme.visualFocus
                                        }

                                        contentItem: RowLayout {
                                            spacing: VLCStyle.margin_xsmall

                                            T.Label {
                                                Layout.preferredWidth: VLCStyle.dp(32, VLCStyle.scale)
                                                Layout.leftMargin: VLCStyle.dp(4, VLCStyle.scale)
                                                horizontalAlignment: Text.AlignHCenter
                                                text: categoryButton.page.icon
                                                font.family: VLCIcons.fontFamily
                                                font.pixelSize: VLCStyle.icon_normal
                                                color: categoryButton.selected ? theme.accent : theme.fg.secondary
                                            }

                                            T.Label {
                                                Layout.fillWidth: true
                                                text: categoryButton.page.name
                                                elide: Text.ElideRight
                                                font.pixelSize: VLCStyle.fontSize_large
                                                color: categoryButton.selected ? theme.fg.primary : theme.fg.secondary
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Options
        Flickable {
            id: contentFlickable

            anchors { top: header.bottom; left: sidebar.right; right: parent.right; bottom: parent.bottom }

            contentHeight: pagesColumn.implicitHeight + VLCStyle.dp(100, VLCStyle.scale)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            ColumnLayout {
                id: pagesColumn

                x: VLCStyle.margin_large
                y: VLCStyle.dp(20, VLCStyle.scale)
                width: contentFlickable.width - 2 * VLCStyle.margin_large
                spacing: VLCStyle.dp(20, VLCStyle.scale)

                Repeater {
                    model: root.shownPages

                    ColumnLayout {
                        id: pageColumn

                        required property string modelData
                        readonly property var page: settingsModel.pages[modelData]
                        readonly property bool hasMatches: page.sections.some(
                            (section) => section.rows.some((row) => root.rowShown(row, section)))

                        Layout.fillWidth: true
                        visible: hasMatches || !root.searching
                        spacing: VLCStyle.dp(20, VLCStyle.scale)

                        // Page name above its results while searching
                        T.Label {
                            visible: root.searching
                            text: pageColumn.page.name
                            color: theme.accent
                            font.pixelSize: VLCStyle.fontSize_large
                            font.weight: Font.DemiBold
                        }

                        Repeater {
                            model: pageColumn.page.sections

                            ColumnLayout {
                                id: sectionColumn

                                required property var modelData

                                Layout.fillWidth: true
                                spacing: 0
                                visible: modelData.rows.some((row) => root.rowShown(row, sectionColumn.modelData))

                                T.Label {
                                    Layout.fillWidth: true
                                    topPadding: VLCStyle.dp(10, VLCStyle.scale)
                                    bottomPadding: VLCStyle.dp(10, VLCStyle.scale)
                                    text: sectionColumn.modelData.title
                                    color: theme.fg.primary
                                    opacity: 0.85
                                    font.pixelSize: VLCStyle.fontSize_xlarge
                                    font.weight: Font.DemiBold
                                }

                                Repeater {
                                    model: sectionColumn.modelData.rows

                                    SettingRow {
                                        required property var modelData

                                        Layout.fillWidth: true
                                        row: modelData
                                        visible: root.rowShown(modelData, sectionColumn.modelData)

                                        onActionRequested: (action) => root[action]()
                                    }
                                }
                            }
                        }

                    }
                }

                T.Label {
                    visible: root.searching && !root.shownPages.some(
                        (pageId) => settingsModel.pages[pageId].sections.some(
                            (section) => section.rows.some((row) => root.rowShown(row, section))))
                    text: qsTr("No settings match \"%1\".").arg(searchField.text.trim())
                    color: theme.fg.secondary
                    font.pixelSize: VLCStyle.fontSize_large
                }
            }
        }
    }

    // every VLC option; created the first time it is shown, then kept
    Loader {
        id: allSettingsLoader

        anchors { top: titleBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        active: false
        visible: root.allSettings
        source: "qrc:///qt/qml/VLC/Dialogs/AllSettingsView.qml"

        onLoaded: item.headerRightInset = Qt.binding(() => modeButton.width)

        Connections {
            target: allSettingsLoader.item
            function onCloseRequested() { root.close() }
        }
    }

    onAllSettingsChanged: if (allSettings) allSettingsLoader.active = true

    // "All Settings" / "Simple Settings" at the right of the header; flat
    // icon and text, as the player panel's "Open Advanced Settings"
    T.AbstractButton {
        id: modeButton

        readonly property string label: root.allSettings ? qsTr("Simple Settings") : qsTr("All Settings")

        z: 1
        anchors.right: parent.right
        anchors.rightMargin: VLCStyle.dp(14, VLCStyle.scale)
        // centred in the 50 dp header under the title bar
        y: titleBar.height + (VLCStyle.dp(50, VLCStyle.scale) - height) / 2
        height: VLCStyle.dp(34, VLCStyle.scale)
        width: modeRow.implicitWidth + 2 * VLCStyle.margin_xsmall

        onClicked: root.allSettings = !root.allSettings

        Accessible.role: Accessible.Button
        Accessible.name: label

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: modeButton.hovered ? windowTheme.bg.primary : "transparent"
            border.width: modeButton.visualFocus ? VLCStyle.focus_border : 0
            border.color: theme.visualFocus
        }

        contentItem: Item {
            Row {
                id: modeRow

                anchors.centerIn: parent
                spacing: VLCStyle.margin_xsmall

                T.Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: VLCIcons.settings
                    font.family: VLCIcons.fontFamily
                    font.pixelSize: VLCStyle.icon_normal
                    color: modeButton.hovered ? theme.fg.primary : theme.fg.secondary
                }

                T.Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modeButton.label
                    font.pixelSize: VLCStyle.fontSize_large
                    color: modeButton.hovered ? theme.fg.primary : theme.fg.secondary
                }
            }
        }
    }

    // resize at the edges and corners (no system frame)
    component ResizeArea: MouseArea {
        property int edges: 0
        z: 100
        enabled: root.visibility !== Window.Maximized
        cursorShape: {
            if (edges === (Qt.LeftEdge | Qt.TopEdge) || edges === (Qt.RightEdge | Qt.BottomEdge))
                return Qt.SizeFDiagCursor
            if (edges === (Qt.RightEdge | Qt.TopEdge) || edges === (Qt.LeftEdge | Qt.BottomEdge))
                return Qt.SizeBDiagCursor
            if (edges & (Qt.LeftEdge | Qt.RightEdge))
                return Qt.SizeHorCursor
            return Qt.SizeVerCursor
        }
        onPressed: root.startSystemResize(edges)
    }

    readonly property real _edge: VLCStyle.dp(5, VLCStyle.scale)

    ResizeArea { edges: Qt.LeftEdge; x: 0; y: root._edge; width: root._edge; height: root.height - 2 * root._edge }
    ResizeArea { edges: Qt.RightEdge; x: root.width - root._edge; y: root._edge; width: root._edge; height: root.height - 2 * root._edge }
    ResizeArea { edges: Qt.TopEdge; x: root._edge; y: 0; width: root.width - 2 * root._edge; height: root._edge }
    ResizeArea { edges: Qt.BottomEdge; x: root._edge; y: root.height - root._edge; width: root.width - 2 * root._edge; height: root._edge }
    ResizeArea { edges: Qt.LeftEdge | Qt.TopEdge; x: 0; y: 0; width: root._edge; height: root._edge }
    ResizeArea { edges: Qt.RightEdge | Qt.TopEdge; x: root.width - root._edge; y: 0; width: root._edge; height: root._edge }
    ResizeArea { edges: Qt.LeftEdge | Qt.BottomEdge; x: 0; y: root.height - root._edge; width: root._edge; height: root._edge }
    ResizeArea { edges: Qt.RightEdge | Qt.BottomEdge; x: root.width - root._edge; y: root.height - root._edge; width: root._edge; height: root._edge }

    // outline instead of the system frame
    Rectangle {
        anchors.fill: parent
        z: 99
        visible: root.visibility !== Window.Maximized
        color: "transparent"
        border.width: VLCStyle.border
        border.color: titleTheme.border
    }
}
