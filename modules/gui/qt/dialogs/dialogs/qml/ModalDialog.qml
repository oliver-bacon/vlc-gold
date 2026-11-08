/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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
import QtQuick.Controls.Basic
import QtQuick.Templates as T
import QtQuick.Layouts

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style
import VLC.Dialogs

// VLC Redesign: in the style of the redesigned windows (RedesignWindow.qml):
// a title bar with the title and a close button, the content with the page
// margins, a footer bar (WinDialogFooter) with the buttons
Dialog {
    id: control

    property Item rootWindow: null

    focus: true
    modal: true


    anchors.centerIn: T.Overlay.overlay

    padding: WinStyle.pageMargin
    leftPadding: VLCStyle.margin_large
    rightPadding: VLCStyle.margin_large
    margins: VLCStyle.margin_large
    spacing: 0

    readonly property real _minimumWidth: VLCStyle.dp(460, VLCStyle.scale)

    implicitWidth: Math.max(_minimumWidth,
                            contentWidth > 0 ? contentWidth + leftPadding + rightPadding : 0,
                            footer && footer.visible ? footer.implicitWidth : 0)
    implicitHeight: (header && header.visible ? header.implicitHeight + spacing : 0)
                    + (footer && footer.visible ? footer.implicitHeight + spacing : 0)
                    + (contentHeight > 0 ? contentHeight + topPadding + bottomPadding : 0)

    closePolicy: Popup.CloseOnEscape

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }

    T.Overlay.modal: Item {
        Rectangle {
            anchors.fill: blur

            visible: !blur.visible

            color: theme.bg.primary

            opacity: 0.6
        }

        Widgets.DualKawaseBlur {
            id: blur

            anchors.fill: parent
            anchors.margins: MainCtx.windowExtendedMargin

            visible: MainCtx.backdropBlurRequested() && blur.available

            mode: Widgets.DualKawaseBlur.Mode.SixPass

            source: ShaderEffectSource {
                sourceItem: blur.visible ? control.rootWindow : null
                live: true
                hideSource: true
            }

            radius: 2
        }
    }

    background: Rectangle {
        color: WinStyle.view.bg.primary
        border.width: VLCStyle.border
        border.color: WinStyle.border

        Widgets.RoundedRectangleShadow {
            yOffset: VLCStyle.dp(4, VLCStyle.scale)
            blurRadius: VLCStyle.dp(3, VLCStyle.scale)

            visible: (parent.color.a > 0.0)

            opacity: 0.2

            color: "black"
        }
    }

    // title bar (as the redesigned windows): title centered, close = reject
    header: Rectangle {
        implicitHeight: VLCStyle.globalToolbar_height
        visible: control.title !== ""
        color: WinStyle.window.bg.primary

        T.Label {
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - 2 * closeButton.width)
            text: control.title
            elide: Text.ElideRight
            color: WinStyle.window.fg.secondary
            font.pixelSize: VLCStyle.fontSize_large
        }

        T.Button {
            id: closeButton

            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: height
            focusPolicy: Qt.NoFocus

            Accessible.name: qsTr("Close")
            onClicked: control.reject()

            background: Rectangle {
                color: closeButton.hovered ? "red" : "transparent"
            }
            contentItem: T.Label {
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: VLCIcons.close
                font.family: VLCIcons.fontFamily
                font.pixelSize: VLCStyle.icon_small
                color: closeButton.hovered ? "white" : WinStyle.window.fg.primary
            }
        }
    }

    exit: Transition {
        OpacityAnimator { from: 1.0; to: 0.0 }
    }
    enter: Transition {
        OpacityAnimator { from: 0.0; to: 1.0 }
    }
}
