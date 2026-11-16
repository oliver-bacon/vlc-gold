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
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Dialogs
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style

Item {
    id: root

    //---------------------------------------------------------------------------------------------
    // Properties
    //---------------------------------------------------------------------------------------------

    property Item bgContent: null

    //---------------------------------------------------------------------------------------------
    // Signal
    //---------------------------------------------------------------------------------------------

    signal restoreFocus();

    //---------------------------------------------------------------------------------------------
    // Events
    //---------------------------------------------------------------------------------------------

    Component.onCompleted: if (DialogErrorModel.repeatedMessageCount){
                               hideErrorPopupTimer.restart()
                               errorPopup.state = "visible"
                           }

    Component.onDestruction: {
        if (questionDialog.dialogId !== null) {
            vlcDialog.dismiss(questionDialog.dialogId)
            questionDialog.dialogId = null
        } if (loginDialog.dialogId !== null) {
            vlcDialog.dismiss(loginDialog.dialogId)
            loginDialog.dialogId = null
        }
    }

    //---------------------------------------------------------------------------------------------
    // Functions
    //---------------------------------------------------------------------------------------------

    function ask(text, acceptCb, rejectCb, buttons) {
        customDialog.ask(text, acceptCb, rejectCb, buttons)
    }

    //---------------------------------------------------------------------------------------------
    // Connections
    //---------------------------------------------------------------------------------------------

    VLCDialog
    {
        id: vlcDialog

        Component.onCompleted: {
            VLCDialogModel.provider = vlcDialog
        }

        Component.onDestruction: {
            // Only clear the provider if we are still the current one.
            if (VLCDialogModel.provider === vlcDialog)
                VLCDialogModel.provider = null
        }

        onLogin: (dialogId, title, text, defaultUsername, askStore) => {
            loginDialog.dialogId = dialogId
            loginDialog.title = title
            loginDialog.text = text
            loginDialog.askStore = askStore
            loginDialog.defaultUsername = defaultUsername
            loginDialog.open()
        }

        onQuestion: (dialogId, title, text, type, cancel, action1, action2) => {
            questionDialog.dialogId = dialogId
            questionDialog.title = title
            questionDialog.text = text
            questionDialog.cancelTxt = cancel
            questionDialog.action1Txt = action1
            questionDialog.action2Txt = action2
            questionDialog.open()
        }

        onProgress: (dialogId, title, text, indeterminate, position, cancel) => {
            progressDialog.dialogId = dialogId
            progressDialog.title = title
            progressDialog.text = text
            progressDialog.cancelTxt = cancel
            progressDialog.position = position
            progressDialog.interderminate = indeterminate
            progressDialog.open()
        }

        onProgressUpdated: (dialogId, position, text) => {
            if (progressDialog.dialogId !== dialogId) {
                console.warn("progress event on an inexisting dialog")
                return
            }
            progressDialog.text = text
            progressDialog.position = position
        }

        onCancelled: (dialogId) => {
            if (questionDialog.dialogId === dialogId) {
                questionDialog.close()
                questionDialog.dialogId = null
                dismiss(dialogId)
            } else if (loginDialog.dialogId === dialogId)  {
                loginDialog.close()
                loginDialog.dialogId = null
                dismiss(dialogId)
            } else if (progressDialog.dialogId === dialogId) {
                progressDialog.close()
                progressDialog.dialogId = null
                dismiss(dialogId)
            } else {
                dismiss(dialogId)
            }
        }
    }

    Connections
    {
        target: DialogErrorModel

        function onCountChanged() {
            hideErrorPopupTimer.restart()
            errorPopup.state = "visible"
        }
    }

    //---------------------------------------------------------------------------------------------
    // Childs
    //---------------------------------------------------------------------------------------------

    Widgets.DrawerExt {
        id: errorPopup

        property string messageText
        property int repeatedMessageCount: 0

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            // VLC Redesign: in the player, above the control bar (Figma: 54px)
            // like the resume prompt, not on top of it
            bottomMargin: MainCtx.playerView ? VLCStyle.dp(54, VLCStyle.scale) + VLCStyle.margin_small
                                             : VLCStyle.margin_small
        }

        edge: Widgets.DrawerExt.Edges.Bottom
        width: contentItem?.layoutWidth ?? 0
        height: contentItem?.height ?? 0
        z: 10

        ColorContext {
            id: errorMsgTheme
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }

        // VLC Redesign: the style of the resume prompt (ResumeDialog.qml):
        // #161616 bar, grey text, accent button, dark close square; the
        // icon stays red to mark an error
        component: Rectangle {
            color: errorMsgTheme.palette.isDark ? "#161616" : "#E7E7E7"

            height: Math.max(VLCStyle.dp(52, VLCStyle.scale), messageText.implicitHeight + VLCStyle.margin_normal)
            radius: VLCStyle.dp(8, VLCStyle.scale)

            property real layoutWidth: layout.width + VLCStyle.dp(20 + 10, VLCStyle.scale)

            Accessible.role: Accessible.AlertMessage
            Accessible.name: qsTr("error popup")

            RowLayout {
                id: layout

                spacing: VLCStyle.dp(8, VLCStyle.scale)
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)

                Widgets.IconLabel {
                    text: VLCIcons.info
                    color: errorMsgTheme.fg.negative
                }

                T.Label {
                    id: messageText

                    Layout.maximumWidth: root.width * 0.5
                    Layout.rightMargin: VLCStyle.dp(24, VLCStyle.scale)

                    text: (DialogErrorModel.repeatedMessageCount > 1 ? '[' + DialogErrorModel.repeatedMessageCount + '] ' : '')
                          + DialogErrorModel.notificationText

                    wrapMode: Text.WrapAnywhere
                    font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                    color: errorMsgTheme.fg.secondary
                }

                T.Button {
                    id: detailsBtn

                    text: qsTr("Show Details")

                    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
                    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
                    leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                    rightPadding: VLCStyle.dp(12, VLCStyle.scale)

                    background: Rectangle {
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: detailsBtn.hovered || detailsBtn.visualFocus ? Qt.lighter(errorMsgTheme.accent, 1.15)
                                                                           : errorMsgTheme.accent
                    }
                    contentItem: Text {
                        text: detailsBtn.text
                        color: "#161616"
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        hideErrorPopupTimer.stop()
                        errorPopup.state = "hidden"
                        DialogErrorModel.resetRepeatedMessageCount()
                        DialogsProvider.messagesDialog(1)
                    }
                }

                Widgets.IconToolButton {
                    id: closeBtn
                    font.pixelSize: VLCStyle.icon_small
                    text: VLCIcons.close
                    description: qsTr("Dismiss")

                    // Figma: a 32px square, #1E1E1E
                    implicitWidth: VLCStyle.dp(32, VLCStyle.scale)
                    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
                    background: Rectangle {
                        readonly property color closeColor: errorMsgTheme.palette.isDark ? "#1E1E1E" : "#D5D5D5"
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: closeBtn.hovered ? Qt.lighter(closeColor, 1.3) : closeColor
                    }

                    onClicked: {
                        hideErrorPopupTimer.stop()
                        errorPopup.state = "hidden"
                        DialogErrorModel.resetRepeatedMessageCount()
                    }
                }
            }

            Widgets.RoundedRectangleShadow {
                yOffset: VLCStyle.dp(4, VLCStyle.scale)
                blurRadius: VLCStyle.dp(3, VLCStyle.scale)

                opacity: 0.2

                visible: (color.a > 0.0)

                color: Qt.darker(parent.color)
            }
        }

        state: "hidden"

        Timer {
            id: hideErrorPopupTimer
            interval: 5000
            repeat: false
            onTriggered: {
                errorPopup.state = "hidden"
                DialogErrorModel.resetRepeatedMessageCount()
            }
        }
    }

    // VLC Redesign: the core's login, progress and question dialogs in the
    // style of the redesigned windows (ModalDialog, Win* controls)
    ModalDialog {
        id: loginDialog

        //use var here as DialogId is a QGadget and passed by value
        property var dialogId: null
        property string defaultUsername: ""
        property string text: ""
        property bool askStore: false

        onAboutToHide: restoreFocus()
        rootWindow: root.bgContent

        onAboutToShow: {
            username.text = defaultUsername
            password.text = ""
            savePassword.checked = false
            if (defaultUsername !== "")
                password.forceActiveFocus()
            else
                username.forceActiveFocus()
        }

        contentItem: ColumnLayout {
            spacing: 0

            // what asks for it (the core's text, e.g. the server)
            WinDescription {
                visible: loginDialog.text !== ""
                text: loginDialog.text
                color: WinStyle.text
                font.pixelSize: VLCStyle.fontSize_large
            }

            WinRow {
                label: qsTr("User")
                WinField {
                    id: username
                    onAccepted: password.forceActiveFocus()
                }
            }

            WinRow {
                label: qsTr("Password")
                WinField {
                    id: password
                    echoMode: TextInput.Password
                    onAccepted: loginDialog.accept()
                }
            }

            WinRow {
                visible: loginDialog.askStore
                label: qsTr("Save password")
                WinToggle { id: savePassword }
            }
        }

        footer: WinDialogFooter {
            WinButton {
                text: qsTr("Cancel")
                onClicked: loginDialog.reject()
            }
            WinButton {
                text: qsTr("OK")
                highlighted: true
                onClicked: loginDialog.accept()
            }
        }

        onAccepted: {
            if (loginDialog.dialogId !== null) {
                vlcDialog.post_login(loginDialog.dialogId, username.text, password.text,
                                     loginDialog.askStore && savePassword.checked)
                loginDialog.dialogId = null
            }
        }
        onRejected: {
            if (loginDialog.dialogId !== null) {
                vlcDialog.dismiss(loginDialog.dialogId)
                loginDialog.dialogId = null
            }
        }
        // Escape closes without an answer: tell the core
        onClosed: {
            if (loginDialog.dialogId !== null) {
                vlcDialog.dismiss(loginDialog.dialogId)
                loginDialog.dialogId = null
            }
        }
    }

    ModalDialog {
        id: progressDialog

        property var dialogId: null

        property string text : ""
        property string cancelTxt: ""
        property bool interderminate: false
        property real position: 0.0

        // no close button nor Escape without a cancel action
        closePolicy: cancelTxt !== "" ? T.Popup.CloseOnEscape : T.Popup.NoAutoClose

        onAboutToHide: restoreFocus()
        rootWindow: root.bgContent

        onRejected: _cancel()
        onClosed: _cancel()

        function _cancel() {
            if (progressDialog.dialogId !== null && progressDialog.cancelTxt !== "") {
                vlcDialog.dismiss(progressDialog.dialogId)
                progressDialog.dialogId = null
                progressDialog.close()
            }
        }

        contentItem: ColumnLayout {
            spacing: VLCStyle.margin_small

            WinDescription {
                Layout.bottomMargin: 0
                text: progressDialog.text
                color: WinStyle.text
                font.pixelSize: VLCStyle.fontSize_large
            }

            // well with the progress (Figma "range" track)
            Rectangle {
                id: progressTrack

                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.dp(16, VLCStyle.scale)
                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: WinStyle.well
                clip: true

                readonly property real _inner: VLCStyle.dp(2, VLCStyle.scale)

                Rectangle {
                    x: progressTrack._inner
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !progressDialog.interderminate
                    width: Math.max(0, Math.min(1, progressDialog.position)) * (parent.width - 2 * x)
                    height: parent.height - 2 * progressTrack._inner
                    radius: VLCStyle.dp(3, VLCStyle.scale)
                    color: WinStyle.accent
                }

                // indeterminate: a chunk going back and forth
                Rectangle {
                    id: chunk

                    visible: progressDialog.interderminate
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * 0.25
                    height: parent.height - 2 * progressTrack._inner
                    radius: VLCStyle.dp(3, VLCStyle.scale)
                    color: WinStyle.accent

                    SequentialAnimation on x {
                        running: chunk.visible && progressDialog.visible
                        loops: Animation.Infinite
                        NumberAnimation { from: progressTrack._inner; to: progressTrack.width - chunk.width - progressTrack._inner; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { from: progressTrack.width - chunk.width - progressTrack._inner; to: progressTrack._inner; duration: 900; easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        footer: WinDialogFooter {
            visible: progressDialog.cancelTxt !== ""
            WinButton {
                text: progressDialog.cancelTxt
                onClicked: progressDialog._cancel()
            }
        }
    }

    ModalDialog {
        id: questionDialog

        //use var here as DialogId is a QGadget and passed by value
        property var dialogId: null
        property string text: ""
        property string cancelTxt: ""
        property string action1Txt: ""
        property string action2Txt: ""

        rootWindow: root.bgContent

        onAboutToHide: restoreFocus()

        function _answer(action) {
            if (questionDialog.dialogId === null)
                return
            if (action === 1)
                vlcDialog.post_action1(questionDialog.dialogId)
            else if (action === 2)
                vlcDialog.post_action2(questionDialog.dialogId)
            else
                vlcDialog.dismiss(questionDialog.dialogId)
            questionDialog.dialogId = null
            questionDialog.close()
        }

        // close button and Escape: as the cancel button
        onRejected: _answer(0)
        onClosed: _answer(0)

        contentItem: WinDescription {
            Layout.bottomMargin: 0
            text: questionDialog.text
            color: WinStyle.text
            font.pixelSize: VLCStyle.fontSize_large
        }

        footer: WinDialogFooter {
            WinButton {
                visible: text !== ""
                text: questionDialog.cancelTxt
                onClicked: questionDialog._answer(0)
            }
            WinButton {
                visible: text !== ""
                text: questionDialog.action2Txt
                onClicked: questionDialog._answer(2)
            }
            WinButton {
                id: questionAction1
                visible: text !== ""
                highlighted: true
                text: questionDialog.action1Txt
                onClicked: questionDialog._answer(1)
            }
        }

        onOpened: questionAction1.forceActiveFocus()
    }

    CustomDialog {
        id: customDialog
        rootWindow: root.bgContent
        onAboutToHide: restoreFocus()
    }

    // dialogs of the Figma redesign, created on first use
    readonly property var _figmaDialogs: ({
        "network": "NetworkStreamDialog.qml",
        "openMedia": "OpenMediaDialog.qml",
        "mediaInfo": "MediaInfoDialog.qml",
        "mediaInfoItem": "MediaInfoDialog.qml",
        "newPlaylist": "NewPlaylistDialog.qml",
        "playlistProperties": "PlaylistPropertiesDialog.qml",
        "shortcuts": "KeyboardShortcutsDialog.qml",
        "subtitles": "AddSubtitlesDialog.qml",
        "customize": "CustomizePlayerDialog.qml",
        "onboarding": "OnboardingWindow.qml",
        "confirm": "ConfirmDialog.qml",
        // classic windows redesigned (dialogs/window/qml)
        "gotoTime": "GotoTimeWindow.qml",
        "stream": "StreamWindow.qml",
        "convert": "ConvertWindow.qml",
        "effects": "EffectsWindow.qml",
        "extension": "ExtensionWindow.qml",
        "vlm": "VlmWindow.qml",
        "epg": "EpgWindow.qml",
        "plugins": "PluginsWindow.qml",
        "addToPlaylist": "AddToPlaylistWindow.qml",
        "openUrl": "OpenUrlWindow.qml",
        "podcast": "PodcastWindow.qml",
        "messages": "MessagesWindow.qml",
        "bookmarks": "BookmarksWindow.qml",
        "help": "HelpWindow.qml",
        "update": "UpdateWindow.qml",
        "about": "AboutWindow.qml"
    })
    property var _figmaDialogInstances: ({})

    Connections {
        target: DialogsProvider

        function onShowFigmaDialog(name, args) {
            // the player bars are customized in place, in the player
            if (name === "customize") {
                MainCtx.playerView = true
                MainCtx.playerCustomizing = true
                return
            }
            // Media Information of the playing item: a second call on the
            // same tab hides it, as the classic dialog
            if (name === "mediaInfo" || name === "effects") {
                const shown = root._figmaDialogInstances[name]
                if (shown && shown.visible && shown.isShowingTab(args?.tab)) {
                    shown.close()
                    return
                }
            }
            // Media Information of a library or queue item, dialogs of the
            // Lua extensions: one window each
            const single = (name !== "mediaInfoItem" && name !== "extension")
            let dialog = single ? root._figmaDialogInstances[name] : null
            if (!dialog) {
                const component = Qt.createComponent("qrc:///qt/qml/VLC/Dialogs/" + root._figmaDialogs[name])
                if (component.status !== Component.Ready) {
                    console.warn("cannot load dialog", name, component.errorString())
                    // DialogsProvider.questionDialog() waits for an answer
                    if (name === "confirm")
                        DialogsProvider.answerQuestion(false)
                    return
                }
                dialog = component.createObject(root)
                if (single)
                    root._figmaDialogInstances[name] = dialog
                else if (name !== "extension") // goes away with its extension dialog
                    dialog.closing.connect(() => dialog.destroy())
            }
            // { toggle: true }: a second call hides it (QVLCDialog::toggleVisible)
            if (args?.toggle === true && dialog.visible) {
                dialog.close()
                return
            }
            if (typeof dialog.reset === "function")
                dialog.reset(args)
            // an extension dialog shows itself when its extension wants it
            if (name !== "extension")
                dialog.open()
        }
    }

    Loader {
        id: settingsWindowLoader
        active: false
        source: "qrc:///qt/qml/VLC/Dialogs/SettingsWindow.qml"

        Connections {
            target: DialogsProvider

            function onShowSettingsWindow() {
                settingsWindowLoader.active = true
                settingsWindowLoader.item.open()
            }

            function onShowSettingsPage(page) {
                settingsWindowLoader.active = true
                settingsWindowLoader.item.openPage(page)
            }

            // "All Settings" is a view of the settings window
            function onShowAllSettingsWindow() {
                settingsWindowLoader.active = true
                settingsWindowLoader.item.openAllSettings()
            }
        }
    }

    Loader {
        id: toolbarEditorDialogLoader
        active: false
        source: "qrc:///qt/qml/VLC/Dialogs/ToolbarEditorDialog.qml"

        Connections {
            target: DialogsProvider

            function onShowToolbarEditorDialog() {
                toolbarEditorDialogLoader.active = true
                toolbarEditorDialogLoader.item.open()
            }
        }
    }
}
