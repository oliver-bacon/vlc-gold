/*****************************************************************************
 * Copyright (C) 2024 VLC authors and VideoLAN
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
import QtQml.Models

import VLC.Style
import VLC.Widgets as Widgets

import VLC.MainInterface
import VLC.Dialogs
import VLC.Menus
import VLC.Util

T.Pane {
    id: root

    signal itemClicked(uri : var, item : Item)

    //safe area margins for delegate content,
    //so the background of the delegates fills the available space
    //but the content remains within the safe area
    property int safeAreaLeftMargin: 0
    property int safeAreaRightMargin: 0

    property bool useAcrylic: true

    property bool delegateShowText: true

    property alias model: navigationModel

    // width of the rail (icons only): the panel inset on both sides, the
    // delegate's left padding, the icon and a margin after it
    // Figma "sidebar" frame: a 50px rail, 24px icons centred in it, a row
    // every 46px; the navigation with text keeps VLC's row height
    readonly property real _railPanelWidth: VLCStyle.dp(50, VLCStyle.scale)
    readonly property real _rowHeight: delegateShowText ? VLCStyle.buttonHeightNavigationPane
                                                        : VLCStyle.dp(46, VLCStyle.scale)
    readonly property real _iconLeft: delegateShowText ? VLCStyle.margin_xsmall
                                                       : (_railPanelWidth - VLCStyle.icon_normal) / 2

    // left edge of the entry icons, from the pane's left edge without the
    // safe area (the top bar cone lines up with it)
    readonly property real iconLeft: panelInset + _iconLeft

    readonly property real railWidth: 2 * panelInset + safeAreaLeftMargin + safeAreaRightMargin
                                      + _railPanelWidth + rightPadding

    // filled Figma icons (in the accent colour) of the selected entries (no Figma one for Recent)
    readonly property var _selectedIcons: ({
        "home": "qrc:///misc/rail_home_selected.svg",
        "video": "qrc:///misc/rail_video_selected.svg",
        "music": "qrc:///misc/rail_music_selected.svg",
        "streams": "qrc:///misc/rail_network_selected.svg",
        "playlists": "qrc:///misc/rail_playlists_selected.svg"
    })

    // ---- pinned items (VLC Redesign: "Pin whatever you want here")
    // [{ type: "folder" | "playlist", name, url (folder), id (playlist,
    // serialized media library id) }], kept in the interface settings

    readonly property string _pinsKey: "Library/Pins"
    property var _pins: []

    // playlists offered by "Add item" (created only with a media library)
    property var _playlists: null

    function _loadPins() {
        try {
            const list = JSON.parse(VLCConfig.uiValue(_pinsKey, "[]"))
            _pins = Array.isArray(list) ? list : []
        } catch (e) {
            _pins = []
        }
    }

    function _savePins(list) {
        VLCConfig.setUiValue(_pinsKey, JSON.stringify(list))
    }

    function _pin(item) {
        const list = _pins.filter((p) => !(p.type === item.type && p.url === item.url && p.id === item.id))
        list.push(item)
        _savePins(list)
    }

    function _unpin(index) {
        const list = _pins.slice()
        list.splice(index, 1)
        _savePins(list)
    }

    function _openPin(pin) {
        if (pin.type === "folder") {
            History.push(["network", "browse"], { "tree": VLCConfig.browseNode(pin.url) })
        } else if (pin.type === "playlist" && MainCtx.mediaLibrary) {
            History.push(["playlists", "list"], {
                "parentId": MainCtx.mediaLibrary.deserializeMlItemIdFromString(pin.id),
                "title": pin.name
            })
        }
    }

    function _addItemMenu() {
        const items = [{ "text": qsTr("Pin a Folder…") }]
        if (_playlists && _playlists.count > 0) {
            const children = []
            for (let i = 0; i < Math.min(_playlists.count, 50); ++i)
                children.push({ "text": _playlists.getDataAt(i).name })
            items.push({ "text": qsTr("Pin a Playlist"), "children": children })
        }
        return items
    }

    Component.onCompleted: {
        _loadPins()
        if (MainCtx.mediaLibraryAvailable) {
            _playlists = Qt.createQmlObject("import VLC.MediaLibrary; MLPlaylistListModel { playlistType: MLPlaylistListModel.PLAYLIST_TYPE_ALL }", root)
            _playlists.ml = MainCtx.mediaLibrary
        }
    }

    Connections {
        target: VLCConfig
        function onUiValueChanged(key) {
            if (key === "" || key === root._pinsKey)
                root._loadPins()
        }
    }

    readonly property int minimumWidth: VLCStyle.expandNavigationPaneWidth + safeAreaLeftMargin + safeAreaRightMargin

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    // The panel is inset by `panelInset` (Figma: 8px around a 6px-radius
    // panel); the content is laid out inside the panel.
    readonly property real panelInset: VLCStyle.margin_xsmall

    padding: VLCStyle.margin_normal

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    Accessible.name: qsTr("Sidebar")

    NavigationModel {
        id: navigationModel
        hasMedialib: MainCtx.mediaLibraryAvailable
    }

    Connections {
        target: History

        // NOTE: handles cases where the path changes not by clicking in the sidebar
        function onViewPathChanged(viewPath) {
            for (let i = 0; i < listView.count; ++i) {
                const rowIndex = navigationModel.index(i, 0)
                const uri = navigationModel.data(rowIndex, NavigationModel.URI)

                if (uri && History.match(viewPath, uri)) {
                    // handle back button
                    listView.currentIndex = i

                    // handle keyboard navigation
                    if (!navigationModel.data(rowIndex, NavigationModel.EXPANDED))
                        navigationModel.setData(rowIndex, true, NavigationModel.EXPANDED)

                    return
                }
            }
        }
    }

    readonly property ColorContext viewColorContext: ColorContext {
        id: viewTheme
        colorSet: ColorContext.View
    }

    background: Rectangle {
        color: viewTheme.bg.primary

        Rectangle {
            anchors.fill: parent
            anchors.margins: root.panelInset
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: theme.bg.primary
        }
    }

    contentItem:  Item {
        id: contentItemId

        //don't use Layout as top item as items put as children of the Control
        //would be parented (and layouted) to the Layout
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.panelInset
            anchors.topMargin: root.panelInset * 2
            spacing: VLCStyle.margin_xsmall

            // entries, pins and "Add item" scroll when the window is too short;
            // Preferences stays at the bottom
            Flickable {
                id: entriesFlickable

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0

                contentWidth: width
                contentHeight: entriesColumn.implicitHeight
                clip: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                // no scroll bar in the narrow icon-only pane: it would cover the icons
                T.ScrollBar.vertical: Widgets.ScrollBarExt {
                    visible: root.delegateShowText && entriesFlickable.contentHeight > entriesFlickable.height
                }

                ColumnLayout {
                    id: entriesColumn

                    width: entriesFlickable.width
                    spacing: VLCStyle.margin_xsmall

                    Widgets.ListViewExt {
                        id: listView

                        Layout.fillWidth: true
                        // as high as its entries: the pinned items follow it
                        Layout.preferredHeight: contentHeight
                        Layout.maximumHeight: contentHeight

                        // the surrounding Flickable scrolls
                        interactive: false

                        clip: !fadingEdge.implicitClipping && (height < contentHeight)
                        focus: true

                        model: navigationModel

                        Binding {
                            target: listView.T.ScrollBar.vertical
                            property: "policy"
                            when: listView.T.ScrollBar.vertical?.size > (1.0 - Number.EPSILON)
                            value: T.ScrollBar.AlwaysOff
                        }

                        colorContext.colorSet: ColorContext.Window

                        fadingEdge.backgroundColor:  (root.background && (root.background.color.a >= 1.0)) ? root.background.color
                                                                                                           : "transparent"

                        component DelegateAnimation : NumberAnimation {
                            easing.type: Easing.InOutSine
                            duration: VLCStyle.duration_long
                        }

                        reuseItems: false // Not relevant here, we disable it because of QTBUG-131106 when transition is involved.

                        // As the docs note, `ListView` transitions do not seem to handle height animation. For that reason,
                        // we animate the height directly in the delegate (Qt's recommended workaround). Because of this, we
                        // do not need to have `addDisplaced` transition here, but we can have `removeDisplaced` here:
                        removeDisplaced: Transition {
                            DelegateAnimation { property: "y" }
                        }

                        onCurrentIndexChanged: {
                            const rowIndex = navigationModel.index(currentIndex, 0)

                            if (rowIndex.valid && !navigationModel.data(rowIndex, NavigationModel.EXPANDED)
                                    && History.match(History.viewPath, navigationModel.data(rowIndex, NavigationModel.URI)))
                                navigationModel.setData(rowIndex, true, NavigationModel.EXPANDED)
                        }

                        property bool readyForAnimations: false

                        onModelChanged: {
                            if (!listView.readyForAnimations)
                                Qt.callLater(() => { listView.readyForAnimations = true })
                        }

                        Navigation.parentItem: root
                        Navigation.downItem: preferenceButton

                        delegate: SideNavigationDelegate {
                            id: delegate

                            width: ListView.view.contentWidth
                            height: preferredHeight

                            property real preferredHeight: shouldShow ? root._rowHeight : 0.0

                            leftPadding: root.safeAreaLeftMargin + root._iconLeft
                            rightPadding: root.safeAreaRightMargin

                            leftInset: root.safeAreaLeftMargin + implicitLeftInset
                            rightInset: root.safeAreaRightMargin + implicitRightInset

                            iconTxt: icon_alias
                            selectedIconSource: (uri && root._selectedIcons[uri[0]]) || ""
                            text: title

                            showText: root.delegateShowText

                            required property string title
                            required property var uri
                            required property int depth
                            // TODO: Qt 6.2 has property `icon` marked final, so we can't override it:
                            required property string icon_alias
                            required property bool expandable
                            required property bool expanded

                            required property int index

                            visible: (height > 0.0)

                            property bool shouldShow: showText || (iconTxt.length > 0)

                            onShouldShowChanged: {
                                if (listView.readyForAnimations)
                                    heightBehavior.enabled = true // At this point, it can keep being enabled for good.
                            }

                            highlighted: !!uri && History.match(History.viewPath, uri)
                            checked: (!showText || !expanded) && highlighted

                            onClicked: {
                                itemClicked(uri, this)
                                listView.currentIndex = index
                                listView.forceActiveFocus(focusReason)
                            }

                            Behavior on height {
                                id: heightBehavior

                                enabled: false

                                DelegateAnimation {
                                    onRunningChanged: {
                                        if (running) {
                                            delegate.clip = true
                                        } else {
                                            delegate.clip = false
                                        }
                                    }
                                }
                            }

                            ListView.onAdd: {
                                if (listView.readyForAnimations && delegate.showText) {
                                    heightBehavior.enabled = false
                                    delegate.height = 0.0
                                    heightBehavior.enabled = true
                                    delegate.height = Qt.binding(() => delegate.preferredHeight)
                                    heightBehavior.enabled = false
                                }
                            }
                        }
                    }

                    // pinned folders and playlists
                    Repeater {
                        model: root._pins

                        delegate: SideNavigationDelegate {
                            id: pinDelegate

                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.preferredHeight: root._rowHeight

                            leftPadding: root.safeAreaLeftMargin + root._iconLeft
                            rightPadding: root.safeAreaRightMargin

                            leftInset: root.safeAreaLeftMargin + implicitLeftInset
                            rightInset: root.safeAreaRightMargin + implicitRightInset

                            iconTxt: modelData.type === "folder" ? VLCIcons.topbar_network : VLCIcons.lists
                            text: modelData.name

                            showText: root.delegateShowText

                            onClicked: root._openPin(modelData)

                            TapHandler {
                                acceptedButtons: Qt.RightButton
                                onTapped: unpinMenu.popup(pinDelegate.mapToGlobal(point.position.x, point.position.y),
                                                          [{ "text": qsTr("Unpin from the Sidebar") }])
                            }

                            StringListMenu {
                                id: unpinMenu
                                ctx: MainCtx
                                onSelected: root._unpin(pinDelegate.index)
                            }
                        }
                    }

                    SideNavigationDelegate {
                        id: addItemButton

                        Layout.fillWidth: true
                        Layout.preferredHeight: root._rowHeight

                        leftPadding: root.safeAreaLeftMargin + root._iconLeft
                        rightPadding: root.safeAreaRightMargin

                        leftInset: root.safeAreaLeftMargin + implicitLeftInset
                        rightInset: root.safeAreaRightMargin + implicitRightInset

                        iconTxt: VLCIcons.add
                        text: qsTr("Add item")

                        showText: root.delegateShowText

                        onClicked: addItemMenu.popup(addItemButton.mapToGlobal(0, addItemButton.height), root._addItemMenu())

                        StringListMenu {
                            id: addItemMenu
                            ctx: MainCtx
                            onSelected: (index, text) => {
                                if (index === 0) {
                                    const folder = VLCConfig.browseFolder(qsTr("Pin a Folder to the Sidebar"))
                                    if (folder !== "") {
                                        const parts = decodeURIComponent(folder).split("/").filter((p) => p !== "")
                                        root._pin({ "type": "folder", "name": parts[parts.length - 1] ?? folder, "url": folder })
                                    }
                                } else if (root._playlists) {
                                    // playlist entries follow "Pin a Folder…"
                                    const data = root._playlists.getDataAt(index - 1)
                                    root._pin({ "type": "playlist", "name": data.name, "id": data.id.toString() })
                                }
                            }
                        }
                    }
                }
            }

            Loader {
                id: loaderProgress

                Layout.fillWidth: true

                active: (MainCtx.mediaLibraryAvailable && MainCtx.mediaLibrary.idle === false)
                visible: active

                source: "qrc:///qt/qml/VLC/MediaLibrary/ScanProgressBar.qml"

                onLoaded: {
                    if (item.background) {
                        item.background.opacity = 0.6
                        item.background.radius = Qt.binding(() => VLCStyle.dp(4, VLCStyle.scale))
                    }

                    item.leftPadding = Qt.binding(function() { return root.safeAreaLeftMargin + VLCStyle.margin_small })
                    item.rightPadding = Qt.binding(function() { return root.safeAreaRightMargin + VLCStyle.margin_small })

                    item.leftInset = Qt.binding(() => { return VLCStyle.margin_xxsmall + root.safeAreaLeftMargin })
                    item.rightInset = Qt.binding(() => { return VLCStyle.margin_xxsmall + root.safeAreaRightMargin })
                }
            }

            SideNavigationDelegate {
                id: preferenceButton

                AccessibleCompat.id: "preferencesButton"

                Layout.fillWidth: true
                Layout.preferredHeight: root._rowHeight

                leftPadding: root.safeAreaLeftMargin + root._iconLeft
                rightPadding: root.safeAreaRightMargin

                leftInset: root.safeAreaLeftMargin + implicitLeftInset
                rightInset: root.safeAreaRightMargin + implicitRightInset

                iconTxt: VLCIcons.settings
                text: qsTr("Preferences")

                checked: DialogsProvider.prefsDialogVisible

                showText: root.delegateShowText

                onClicked: DialogsProvider.settingsDialog()

                //SideNavigationDelegate is an ItemDelegate and has NoFocus by default
                focusPolicy: Qt.StrongFocus

                Navigation.parentItem: root
                Navigation.upItem: listView

                Keys.priority: Keys.AfterItem
                Keys.onPressed: (e) => Navigation.defaultKeyAction(e)
                Keys.onReleased: (e) => Navigation.defaultKeyReleaseAction(e)
            }

        }
    }
}
