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

// "Plugins and extensions" (classic dialogs/plugins): the tabs Addons
// Manager (search, category, Find more addons online / Only installed,
// Install / Remove, drop a .vlp file to install it), Active Extensions
// (More information..., Reload extensions) and Plugins (search, sortable
// Name / Capability / Score). "More information" opens a details window.
RedesignWindow {
    id: root

    title: qsTr("Plugins and extensions")

    resizable: true
    initialHeight: VLCStyle.dp(660, VLCStyle.scale)

    tabs: [
        { "text": qsTr("Addons Manager"), "icon": "main_open_network_stream" },
        { "text": qsTr("Active Extensions"), "icon": "main_customize_player" },
        { "text": qsTr("Plugins"), "icon": "main_settings" }
    ]

    PluginsHelper {
        id: helper
        ctx: MainCtx
    }

    // AddonsModel (VLC.Network, created here to keep VLC.Dialogs free of it)
    property var addons: null

    // AddonsModel::Type and ::State
    readonly property int typeNone: 9
    readonly property int stateNone: 4
    readonly property int stateNotInstalled: 0
    readonly property int stateInstalling: 1
    readonly property int stateInstalled: 2
    readonly property int stateUninstalling: 3

    // "Find more addons online" was used: "Only installed" instead
    property bool onlineLoaded: false

    Component.onCompleted: {
        addons = Qt.createQmlObject("import VLC.Network; import VLC.MainInterface; ServicesDiscoveryModel { ctx: MainCtx }", root)
    }

    function reset(args) {
    }

    // ---- Plugins: list, search, sorting -------------------------------------------

    property var pluginList: []
    property string pluginSearch: ""
    // 0 name, 1 capability, 2 score (as the classic tree, by capability first)
    property int pluginSort: 1
    property bool pluginDescending: false

    onCurrentTabChanged: if (currentTab === 2 && pluginList.length === 0) pluginList = helper.plugins()

    readonly property var shownPlugins: {
        const search = pluginSearch.toLowerCase()
        const list = pluginList.filter((p) => search === ""
                                       || p.name.toLowerCase().includes(search)
                                       || p.capability.toLowerCase().includes(search))
        const col = pluginSort
        list.sort((a, b) => {
            let r
            if (col === 2)
                r = a.score - b.score
            else if (col === 1)
                r = a.capability === b.capability ? a.name.localeCompare(b.name)
                                                  : a.capability.localeCompare(b.capability)
            else
                r = a.name.localeCompare(b.name)
            return pluginDescending ? -r : r
        })
        return list
    }

    // ---- details window -------------------------------------------------------------

    function _showExtension(ext) {
        infoWindow.show({
            "name": ext.title, "icon": ext.icon,
            "rows": [[qsTr("Version"), ext.version], [qsTr("Author"), ext.author]],
            "summary": ext.summary, "description": "",
            "website": ext.url, "files": ext.file !== "" ? [ext.file] : []
        })
    }

    function _showAddon(addon) {
        const rows = [[qsTr("Type"), addon.typeLabel]]
        if (addon.version !== "") rows.push([qsTr("Version"), addon.version])
        if (addon.author !== "") rows.push([qsTr("Author"), addon.author])
        infoWindow.show({
            "name": addon.name, "icon": addon.icon, "rows": rows,
            "summary": addon.summary, "description": addon.description,
            "website": addon.link, "files": addon.files
        })
    }

    RedesignWindow {
        id: infoWindow

        property var info: ({})

        transientParent: root
        modality: Qt.WindowModal
        title: qsTr("About") + " " + (info.name ?? "")
        fitWidth: VLCStyle.dp(640, VLCStyle.scale)

        function show(data) {
            info = data
            open()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: VLCStyle.margin_normal

            Image {
                Layout.preferredWidth: VLCStyle.dp(64, VLCStyle.scale)
                Layout.preferredHeight: VLCStyle.dp(64, VLCStyle.scale)
                Layout.alignment: Qt.AlignTop
                source: infoWindow.info.icon ?? ""
                sourceSize: Qt.size(128, 128)
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                WinSectionTitle {
                    topPadding: 0
                    text: infoWindow.info.name ?? ""
                }

                Repeater {
                    model: infoWindow.info.rows ?? []
                    WinInfoRow {
                        required property var modelData
                        label: modelData[0]
                        value: modelData[1]
                    }
                }
            }
        }

        WinTextArea {
            Layout.fillWidth: true
            Layout.topMargin: VLCStyle.margin_small
            Layout.preferredHeight: VLCStyle.dp(180, VLCStyle.scale)
            readOnly: true
            textFormat: TextEdit.RichText
            text: {
                let html = (infoWindow.info.summary ?? "")
                const description = infoWindow.info.description ?? ""
                if (description !== "")
                    html += "<hr/>" + description.replace(/\n/g, "<br/>")
                return html.replace(/<a /g, "<a style=\"color:" + String(WinStyle.accent) + "\" ")
            }
            onLinkActivated: (link) => Qt.openUrlExternally(link)
        }

        WinRow {
            visible: (infoWindow.info.website ?? "") !== ""
            label: qsTr("Website")

            WinLabel {
                Layout.maximumWidth: WinStyle.controlWidth
                text: infoWindow.info.website ?? ""
                color: WinStyle.accent
                font.underline: websiteHover.hovered

                HoverHandler { id: websiteHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Qt.openUrlExternally(infoWindow.info.website) }
            }
        }

        WinRow {
            visible: (infoWindow.info.files ?? []).length > 0
            label: (infoWindow.info.files ?? []).length > 1 ? qsTr("Files") : qsTr("File")

            WinDropdown {
                visible: (infoWindow.info.files ?? []).length > 1
                model: (infoWindow.info.files ?? []).map((f) => ({ "value": f, "text": f }))
                value: (infoWindow.info.files ?? [])[0]
            }
            WinField {
                visible: (infoWindow.info.files ?? []).length === 1
                readOnly: true
                text: (infoWindow.info.files ?? [])[0] ?? ""
            }
        }

        footer: [
            WinButton {
                text: qsTr("Close")
                onClicked: infoWindow.close()
            }
        ]
    }

    // ---- pages ---------------------------------------------------------------------------

    readonly property var _categories: [
        { "value": 9, "text": qsTr("All"), "tip": qsTr("Interface Settings") },
        { "value": 4, "text": qsTr("Skins"), "tip": qsTr("Skins customize player's appearance. You can activate them through preferences.") },
        { "value": 2, "text": qsTr("Playlist parsers"), "tip": qsTr("Playlist parsers add new capabilities to read internet streams or extract meta data.") },
        { "value": 3, "text": qsTr("Service Discovery"), "tip": qsTr("Service discoveries adds new sources to your play queue such as web radios, video websites, ...") },
        { "value": 6, "text": qsTr("Interfaces"), "tip": "" },
        { "value": 7, "text": qsTr("Art and meta fetchers"), "tip": qsTr("Retrieves extra info and art for play queue items") },
        { "value": 1, "text": qsTr("Extensions"), "tip": qsTr("Extensions brings various enhancements. Check descriptions for more details") }
    ]

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: root.currentTab

        // Addons Manager
        ColumnLayout {
            spacing: VLCStyle.margin_small

            RowLayout {
                Layout.fillWidth: true
                spacing: VLCStyle.margin_small

                WinField {
                    Layout.fillWidth: true
                    placeholderText: qsTr("Search")
                    onTextChanged: if (root.addons) root.addons.searchPattern = text
                }

                WinDropdown {
                    id: categoryBox
                    implicitWidth: VLCStyle.dp(240, VLCStyle.scale)
                    model: root._categories
                    value: root.typeNone
                    onPicked: (v) => { if (root.addons) root.addons.typeFilter = v }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: VLCStyle.margin_small

                WinDescription {
                    Layout.bottomMargin: 0
                    text: root._categories.find((c) => c.value === categoryBox.value)?.tip ?? ""
                }

                WinButton {
                    visible: !root.onlineLoaded
                    text: qsTr("Find more addons online")
                    onClicked: {
                        root.onlineLoaded = true
                        root.addons.loadFromDefaultRepository()
                    }
                }

                WinLabel {
                    visible: root.onlineLoaded
                    text: qsTr("Only installed")
                }
                WinToggle {
                    visible: root.onlineLoaded
                    onToggled: root.addons.stateFilter = checked ? root.stateInstalled : root.stateNone
                }
            }

            WinList {
                id: addonFrame

                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.addons
                emptyText: (root.addons && root.addons.loading) ? qsTr("Retrieving addons...") : qsTr("No addons found")

                // a .vlp package dropped here is installed
                DropArea {
                    anchors.fill: parent
                    keys: ["text/uri-list"]
                    onEntered: (drag) => {
                        drag.accepted = drag.urls.length === 1
                                        && String(drag.urls[0]).startsWith("file:")
                                        && String(drag.urls[0]).endsWith(".vlp")
                    }
                    onDropped: (drop) => {
                        root.addons.loadFromExternalRepository(drop.urls[0])
                        drop.accept(Qt.CopyAction)
                    }
                    Rectangle {
                        anchors.fill: parent
                        visible: parent.containsDrag
                        color: "transparent"
                        radius: WinStyle.radius
                        border.width: VLCStyle.dp(2, VLCStyle.scale)
                        border.color: WinStyle.accent
                    }
                }

                delegate: T.ItemDelegate {
                    id: addon

                    required property int index
                    required property string name
                    required property string summary
                    required property string description
                    required property string author
                    required property string version
                    required property var link
                    required property var filename
                    required property var artwork
                    required property int score
                    // `state` is an Item property: the role is read from `model`
                    required property var model
                    readonly property int addonState: model.state
                    required property var type
                    required property int downloadCount

                    readonly property bool selected: ListView.view.currentIndex === index
                    readonly property string typeIcon: root.addons ? root.addons.getIconForType(type) : ""
                    readonly property bool busy: addonState === root.stateInstalling || addonState === root.stateUninstalling

                    function details() {
                        return {
                            "name": name, "icon": artworkImage.status === Image.Ready ? artworkImage.source : typeIcon,
                            "typeLabel": root.addons.getLabelForType(type), "version": version, "author": author,
                            "summary": summary, "description": description, "link": String(link ?? ""),
                            "files": (filename ?? []).map((f) => String(f))
                        }
                    }

                    width: ListView.view.width
                    implicitHeight: VLCStyle.dp(68, VLCStyle.scale)
                    leftPadding: VLCStyle.margin_small
                    rightPadding: VLCStyle.margin_small

                    onClicked: {
                        ListView.view.currentIndex = index
                        ListView.view.forceActiveFocus()
                    }
                    onDoubleClicked: root._showAddon(details())
                    Keys.onReturnPressed: root._showAddon(details())

                    background: Rectangle {
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: addon.selected ? WinStyle.selected
                                              : (addon.hovered ? Qt.alpha(WinStyle.surface, 0.6) : "transparent")
                    }

                    contentItem: RowLayout {
                        spacing: VLCStyle.margin_small

                        Item {
                            Layout.preferredWidth: VLCStyle.dp(44, VLCStyle.scale)
                            Layout.preferredHeight: VLCStyle.dp(44, VLCStyle.scale)

                            Image {
                                id: artworkImage
                                anchors.fill: parent
                                source: addon.artwork ?? ""
                                sourceSize: Qt.size(88, 88)
                                fillMode: Image.PreserveAspectFit
                                visible: status === Image.Ready
                            }
                            Image {
                                anchors.fill: parent
                                visible: artworkImage.status !== Image.Ready
                                source: addon.typeIcon
                                sourceSize: Qt.size(88, 88)
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: VLCStyle.dp(2, VLCStyle.scale)

                            RowLayout {
                                spacing: VLCStyle.margin_xsmall
                                T.Label {
                                    text: addon.name
                                    color: WinStyle.strongText
                                    font.pixelSize: VLCStyle.fontSize_large
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: addon.width * 0.45
                                }
                                T.Label {
                                    visible: addon.addonState === root.stateInstalled
                                    text: qsTr("Installed")
                                    color: WinStyle.accent
                                    font.pixelSize: VLCStyle.fontSize_small
                                }
                            }
                            T.Label {
                                Layout.fillWidth: true
                                text: addon.summary
                                color: WinStyle.mutedText
                                font.pixelSize: VLCStyle.fontSize_normal
                                elide: Text.ElideRight
                            }
                            T.Label {
                                Layout.fillWidth: true
                                text: [addon.version !== "" ? qsTr("Version %1").arg(addon.version) : "",
                                       addon.score > 0 && root.addons
                                           ? "★".repeat(Math.round(5 * addon.score / root.addons.maxScore))
                                             + "☆".repeat(5 - Math.round(5 * addon.score / root.addons.maxScore)) : "",
                                       addon.downloadCount > 0 ? qsTr("%1 downloads").arg(addon.downloadCount) : ""]
                                      .filter((t) => t !== "").join("   ")
                                color: WinStyle.mutedText
                                font.pixelSize: VLCStyle.fontSize_small
                                elide: Text.ElideRight
                            }
                        }

                        WinButton {
                            text: {
                                switch (addon.addonState) {
                                case root.stateInstalled: return qsTr("Remove")
                                case root.stateInstalling: return qsTr("Installing")
                                case root.stateUninstalling: return qsTr("Uninstalling")
                                default: return qsTr("Install")
                                }
                            }
                            enabled: !addon.busy
                            highlighted: addon.addonState === root.stateNotInstalled
                            onClicked: {
                                if (addon.addonState === root.stateInstalled)
                                    root.addons.removeService(addon.index)
                                else
                                    root.addons.installService(addon.index)
                            }
                        }

                        WinButton {
                            iconText: VLCIcons.info
                            toolTip.text: qsTr("More information...")
                            onClicked: root._showAddon(addon.details())
                        }
                    }
                }
            }
        }

        // Active Extensions
        ColumnLayout {
            spacing: VLCStyle.margin_small

            WinList {
                id: extensionFrame

                Layout.fillWidth: true
                Layout.fillHeight: true
                model: helper.extensions
                emptyText: qsTr("No extensions.")

                delegate: T.ItemDelegate {
                    id: extension

                    required property var modelData
                    required property int index
                    readonly property bool selected: ListView.view.currentIndex === index

                    width: ListView.view.width
                    implicitHeight: VLCStyle.dp(58, VLCStyle.scale)
                    leftPadding: VLCStyle.margin_small
                    rightPadding: VLCStyle.margin_small

                    onClicked: {
                        ListView.view.currentIndex = index
                        ListView.view.forceActiveFocus()
                    }
                    onDoubleClicked: root._showExtension(modelData)
                    Keys.onReturnPressed: root._showExtension(modelData)

                    background: Rectangle {
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: extension.selected ? WinStyle.selected
                                                  : (extension.hovered ? Qt.alpha(WinStyle.surface, 0.6) : "transparent")
                    }

                    contentItem: RowLayout {
                        spacing: VLCStyle.margin_small

                        Image {
                            Layout.preferredWidth: VLCStyle.dp(36, VLCStyle.scale)
                            Layout.preferredHeight: VLCStyle.dp(36, VLCStyle.scale)
                            source: extension.modelData.icon
                            sourceSize: Qt.size(72, 72)
                            fillMode: Image.PreserveAspectFit
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: VLCStyle.dp(2, VLCStyle.scale)
                            T.Label {
                                Layout.fillWidth: true
                                text: extension.modelData.title
                                color: WinStyle.strongText
                                font.pixelSize: VLCStyle.fontSize_large
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            T.Label {
                                Layout.fillWidth: true
                                text: extension.modelData.summary
                                textFormat: Text.PlainText
                                color: WinStyle.mutedText
                                font.pixelSize: VLCStyle.fontSize_normal
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                WinButton {
                    text: qsTr("More information...")
                    enabled: extensionFrame.currentIndex >= 0
                    onClicked: root._showExtension(helper.extensions[extensionFrame.currentIndex])
                }

                Item { Layout.fillWidth: true }

                WinButton {
                    text: qsTr("Reload extensions")
                    onClicked: {
                        extensionFrame.currentIndex = -1
                        helper.reloadExtensions()
                    }
                }
            }
        }

        // Plugins
        ColumnLayout {
            spacing: VLCStyle.margin_small

            WinField {
                Layout.fillWidth: true
                placeholderText: qsTr("Search")
                onTextChanged: root.pluginSearch = text
            }

            WinList {
                id: pluginFrame

                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: [
                    { "title": qsTr("Name"), "width": 0 },
                    { "title": qsTr("Capability"), "width": VLCStyle.dp(200, VLCStyle.scale) },
                    { "title": qsTr("Score"), "width": VLCStyle.dp(80, VLCStyle.scale) }
                ]
                sortColumn: root.pluginSort
                sortDescending: root.pluginDescending
                onHeaderClicked: (column) => {
                    if (root.pluginSort === column)
                        root.pluginDescending = !root.pluginDescending
                    else {
                        root.pluginSort = column
                        root.pluginDescending = false
                    }
                }
                model: root.shownPlugins

                delegate: WinListRow {
                    required property var modelData
                    frame: pluginFrame
                    cells: [modelData.name, modelData.capability, String(modelData.score)]
                }
            }
        }
    }

    footer: [
        WinButton {
            text: qsTr("Close")
            onClicked: root.close()
        }
    ]
}
