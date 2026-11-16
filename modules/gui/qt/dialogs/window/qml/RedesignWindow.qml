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
import VLC.Style
import VLC.Util
import VLC.Widgets as Widgets

// Frame of a redesigned classic window, in the style of the settings window
// (docs: window-style.md): title bar with the close button, the tabs in a row
// under it (when `tabs` is set), the page, a footer bar with the buttons, a
// 1 px outline. Fixed size that fits the page, or resizable.
//
//   RedesignWindow {
//       title: qsTr("Go to Time")
//       tabs: [{ text: qsTr("General"), icon: "player_video" }]
//       WinRow { ... }                       // the page
//       footer: [ WinButton { ... } ]        // right side of the footer
//   }
Window {
    id: root

    transientParent: MainCtx.intfMainWindow
    flags: Qt.Dialog | Qt.FramelessWindowHint

    // { text, icon } with the icon name of qrc:///menu/figma/*.svg
    property var tabs: []
    property int currentTab: 0

    // the page; children of the window go here
    default property alias content: pageColumn.data
    // right side of the footer (buttons)
    property alias footer: footerButtons.data
    // left side of the footer
    property alias footerLeft: footerLeftRow.data
    property bool footerVisible: true

    // width of the window, height of the page (the window fits it)
    property real fitWidth: VLCStyle.dp(tabs.length > 0 ? 700 : 560, VLCStyle.scale)
    property real pageHeight: pageColumn.implicitHeight

    // resizable instead of fitting; the page fills the window (no scrolling)
    property bool resizable: false
    property real initialHeight: VLCStyle.dp(600, VLCStyle.scale)
    // the page fills the space under the title bar (no Flickable)
    property bool fillPage: resizable
    property real pageMargin: WinStyle.pageMargin

    readonly property real _titleHeight: VLCStyle.globalToolbar_height
    readonly property real _footerHeight: footerVisible ? VLCStyle.dp(60, VLCStyle.scale) : 0
    readonly property real _contentHeight: _titleHeight + tabBar.implicitHeight
            + pageHeight + 2 * pageMargin + _footerHeight
    readonly property real _fitHeight: Screen.desktopAvailableHeight > 0
            ? Math.min(_contentHeight, Screen.desktopAvailableHeight - VLCStyle.dp(40, VLCStyle.scale))
            : _contentHeight

    width: fitWidth
    height: resizable ? initialHeight : _fitHeight
    minimumWidth: resizable ? VLCStyle.dp(480, VLCStyle.scale) : fitWidth
    maximumWidth: resizable ? 16777215 : fitWidth
    minimumHeight: resizable ? VLCStyle.dp(320, VLCStyle.scale) : _fitHeight
    maximumHeight: resizable ? 16777215 : _fitHeight

    color: WinStyle.view.bg.primary

    // centered on the main window when it opens
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

    // shown: hide it; hidden: show it (as QVLCDialog::toggleVisible)
    function toggle() {
        if (visible)
            close()
        else
            open()
    }

    Component.onCompleted: {
        if (MainCtx.createWindowWithoutRedirectionSurface) // Win32
            MainCtx.createWindowWithoutRedirectionSurface(this)
    }

    // Escape closes it (off while something is being edited)
    property bool closeOnEscape: true

    Shortcut {
        sequence: StandardKey.Cancel
        enabled: root.closeOnEscape
        onActivated: root.close()
    }

    // ---- title bar ----------------------------------------------------------

    Rectangle {
        id: titleBar

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: root._titleHeight
        color: WinStyle.window.bg.primary

        DragHandler {
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onActiveChanged: if (active) root.startSystemMove()
        }

        Text {
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - 2 * closeButton.width)
            text: root.title
            elide: Text.ElideRight
            color: WinStyle.window.fg.secondary
            font.pixelSize: VLCStyle.fontSize_large
        }

        Widgets.CSDWindowButton {
            id: closeButton

            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            iconTxt: ((MainCtx.osName === MainCtx.Windows) && (MainCtx.osVersion >= 10)) ? "" : VLCIcons.window_close
            isThemeDark: WinStyle.window.palette.isDark
            color: hovered ? "white" : WinStyle.window.fg.primary
            hoverColor: "red"
            onClicked: root.close()
        }
    }

    // ---- tabs under the title bar ---------------------------------------------

    WinTabBar {
        id: tabBar

        anchors { top: titleBar.bottom; left: parent.left; right: parent.right }
        height: implicitHeight
        tabs: root.tabs
        currentTab: root.currentTab
        onPicked: index => root.currentTab = index
    }

    // ---- page -----------------------------------------------------------------

    Flickable {
        id: pane

        anchors { top: tabBar.bottom; left: parent.left; right: parent.right; bottom: footerBar.top }
        contentHeight: root.fillPage ? height : pageColumn.implicitHeight + 2 * root.pageMargin
        interactive: !root.fillPage && contentHeight > height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        T.ScrollBar.vertical: WinScrollBar { visible: pane.interactive }

        ColumnLayout {
            id: pageColumn

            // colors for VLC's widgets used in a page (ScrollBarExt...)
            readonly property ColorContext colorContext: ColorContext {
                palette: VLCStyle.palette
                colorSet: ColorContext.View
            }

            x: VLCStyle.margin_large
            y: root.pageMargin
            width: pane.width - 2 * VLCStyle.margin_large
            height: root.fillPage ? pane.height - 2 * root.pageMargin : implicitHeight
            spacing: 0
        }
    }

    // ---- footer -----------------------------------------------------------------

    Rectangle {
        id: footerBar

        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: root._footerHeight
        visible: root.footerVisible
        color: WinStyle.window.bg.secondary

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: VLCStyle.margin_large
            anchors.rightMargin: VLCStyle.margin_large
            spacing: VLCStyle.margin_xsmall

            RowLayout {
                id: footerLeftRow
                spacing: VLCStyle.margin_xsmall
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                id: footerButtons
                spacing: VLCStyle.margin_xsmall
            }
        }
    }

    // outline instead of the system frame
    Rectangle {
        anchors.fill: parent
        z: 99
        color: "transparent"
        border.width: VLCStyle.border
        border.color: WinStyle.window.border
    }

    // ---- resizing (no system frame) ---------------------------------------------

    component Edge: Item {
        id: edge

        property int edges
        property int cursor

        z: 100
        visible: root.resizable

        HoverHandler { cursorShape: edge.cursor }
        DragHandler {
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onActiveChanged: if (active) root.startSystemResize(edge.edges)
        }
    }

    readonly property real _grip: VLCStyle.dp(5, VLCStyle.scale)

    Edge { anchors { left: parent.left; right: parent.right; top: parent.top }
           height: root._grip; edges: Qt.TopEdge; cursor: Qt.SizeVerCursor }
    Edge { anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
           height: root._grip; edges: Qt.BottomEdge; cursor: Qt.SizeVerCursor }
    Edge { anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
           width: root._grip; edges: Qt.LeftEdge; cursor: Qt.SizeHorCursor }
    Edge { anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
           width: root._grip; edges: Qt.RightEdge; cursor: Qt.SizeHorCursor }
    Edge { anchors { right: parent.right; bottom: parent.bottom }
           width: 3 * root._grip; height: width; edges: Qt.RightEdge | Qt.BottomEdge; cursor: Qt.SizeFDiagCursor }
    Edge { anchors { left: parent.left; bottom: parent.bottom }
           width: 3 * root._grip; height: width; edges: Qt.LeftEdge | Qt.BottomEdge; cursor: Qt.SizeBDiagCursor }
}
