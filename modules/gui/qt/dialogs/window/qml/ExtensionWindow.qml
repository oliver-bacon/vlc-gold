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

// A dialog of a Lua extension (classic dialogs/extensions/ExtensionDialog):
// the extension's widgets (labels, buttons, images, HTML, text and password
// fields, drop-downs, lists, check boxes, spinning icon) on its grid, in the
// controls of the redesigned windows. Shown and hidden by the extension,
// closing it tells the extension; goes away when the extension kills it.
RedesignWindow {
    id: root

    // ExtensionDialogModel
    property var model: null

    title: model ? model.title : ""
    footerVisible: false
    fitWidth: Math.max(VLCStyle.dp(480, VLCStyle.scale),
                       model && model.widthHint > 0 ? model.widthHint : 0,
                       grid.implicitWidth + 2 * VLCStyle.margin_large)

    // DialogsProvider: { model }
    function reset(args) {
        model = args?.model ?? null
    }

    // the extension shows and hides it; the user closing it is told
    property bool _byModel: false

    function _follow() {
        if (!model)
            return
        _byModel = true
        if (model.shown && !visible)
            open()
        else if (!model.shown && visible)
            close()
        _byModel = false
    }

    // `open()` of DialogsProvider: only when the extension shows it
    onModelChanged: Qt.callLater(_follow)

    onVisibleChanged: {
        if (!visible && !_byModel && model)
            model.close()
    }

    Connections {
        target: root.model
        function onDialogChanged() { root._follow() }
        function onKilled() {
            root._byModel = true
            root.close()
            root.destroy()
        }
    }

    GridLayout {
        id: grid

        Layout.fillWidth: true
        rowSpacing: VLCStyle.margin_xsmall
        columnSpacing: VLCStyle.margin_small

        Repeater {
            model: root.model

            Loader {
                id: cell

                required property int index
                required property string widgetType
                required property string widgetText
                required property bool checked
                required property var values
                required property int gridRow
                required property int gridColumn
                required property int rowSpan
                required property int columnSpan
                required property int widthHint
                required property int heightHint
                required property bool hidden
                required property int spinLoops

                readonly property bool _wide: ["text", "password", "html", "list", "dropdown"].includes(widgetType)

                Layout.row: gridRow
                Layout.column: gridColumn
                Layout.rowSpan: rowSpan
                Layout.columnSpan: columnSpan
                Layout.fillWidth: _wide
                Layout.fillHeight: widgetType === "html" || widgetType === "list"
                Layout.preferredWidth: widthHint > 0 ? widthHint : -1
                Layout.preferredHeight: heightHint > 0 && widgetType !== "spin" ? heightHint : -1
                visible: !hidden

                sourceComponent: ({
                    "label": labelComponent, "button": buttonComponent, "image": imageComponent,
                    "html": htmlComponent, "text": textComponent, "password": textComponent,
                    "dropdown": dropdownComponent, "list": listComponent, "check": checkComponent,
                    "spin": spinComponent
                })[widgetType] ?? null

                Component {
                    id: labelComponent
                    T.Label {
                        text: cell.widgetText
                        textFormat: Text.RichText
                        wrapMode: Text.WordWrap
                        color: WinStyle.text
                        linkColor: WinStyle.accent
                        font.pixelSize: VLCStyle.fontSize_large
                        onLinkActivated: (link) => Qt.openUrlExternally(link)
                        HoverHandler {
                            enabled: parent.hoveredLink !== ""
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                Component {
                    id: buttonComponent
                    WinButton {
                        text: cell.widgetText
                        onClicked: root.model.click(cell.index)
                    }
                }

                Component {
                    id: imageComponent
                    Image {
                        source: cell.widgetText
                        fillMode: Image.PreserveAspectFit
                        sourceSize: Qt.size(cell.widthHint > 0 ? cell.widthHint * 2 : 0,
                                            cell.heightHint > 0 ? cell.heightHint * 2 : 0)
                    }
                }

                Component {
                    id: htmlComponent
                    WinTextArea {
                        implicitWidth: WinStyle.controlWidth
                        implicitHeight: VLCStyle.dp(160, VLCStyle.scale)
                        readOnly: true
                        textFormat: TextEdit.RichText
                        text: cell.widgetText.replace(/<a /g, "<a style=\"color:" + String(WinStyle.accent) + "\" ")
                        onLinkActivated: (link) => Qt.openUrlExternally(link)
                    }
                }

                Component {
                    id: textComponent
                    WinField {
                        echoMode: cell.widgetType === "password" ? TextInput.Password : TextInput.Normal
                        Component.onCompleted: text = cell.widgetText
                        // the extension changed it
                        Connections {
                            target: cell
                            function onWidgetTextChanged() {
                                if (parent.text !== cell.widgetText)
                                    parent.text = cell.widgetText
                            }
                        }
                        onTextEdited: root.model.setText(cell.index, text)
                    }
                }

                Component {
                    id: checkComponent
                    WinCheck {
                        text: cell.widgetText
                        checked: cell.checked
                        onToggled: root.model.setChecked(cell.index, checked)
                    }
                }

                Component {
                    id: dropdownComponent
                    WinDropdown {
                        model: cell.values.map((v) => ({ "value": v.id, "text": v.text }))
                        // the value named by the text, as the classic one
                        source: {
                            const byText = cell.values.find((v) => v.text === cell.widgetText)
                            const picked = byText ?? cell.values.find((v) => v.selected)
                            return picked ? picked.id : undefined
                        }
                        onPicked: (v) => root.model.select(cell.index, [v])
                    }
                }

                Component {
                    id: listComponent
                    WinList {
                        id: valueList

                        implicitWidth: WinStyle.controlWidth
                        implicitHeight: VLCStyle.dp(160, VLCStyle.scale)
                        model: cell.values

                        // several can be selected (Ctrl / Shift), as the classic list
                        property int anchorRow: -1

                        function _click(row, modifiers) {
                            let ids = cell.values.filter((v) => v.selected).map((v) => v.id)
                            const id = cell.values[row].id
                            if ((modifiers & Qt.ShiftModifier) && anchorRow >= 0) {
                                ids = []
                                for (let i = Math.min(anchorRow, row); i <= Math.max(anchorRow, row); ++i)
                                    ids.push(cell.values[i].id)
                            } else if (modifiers & Qt.ControlModifier) {
                                const i = ids.indexOf(id)
                                if (i >= 0) ids.splice(i, 1)
                                else ids.push(id)
                                anchorRow = row
                            } else {
                                ids = [id]
                                anchorRow = row
                            }
                            root.model.select(cell.index, ids)
                        }

                        delegate: T.ItemDelegate {
                            id: valueRow

                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            implicitHeight: VLCStyle.dp(30, VLCStyle.scale)
                            leftPadding: VLCStyle.margin_small

                            background: Rectangle {
                                radius: VLCStyle.dp(4, VLCStyle.scale)
                                color: valueRow.modelData.selected ? WinStyle.selected
                                                                   : (valueRow.hovered ? Qt.alpha(WinStyle.surface, 0.6) : "transparent")
                            }
                            contentItem: T.Label {
                                verticalAlignment: Text.AlignVCenter
                                text: valueRow.modelData.text
                                color: valueRow.modelData.selected ? WinStyle.strongText : WinStyle.text
                                font.pixelSize: VLCStyle.fontSize_large
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: (mouse) => valueList._click(valueRow.index, mouse.modifiers)
                            }
                        }
                    }
                }

                Component {
                    id: spinComponent
                    // the classic SpinningIcon: wait1..4.svg, for spinLoops turns
                    Image {
                        id: spinner

                        property int frame: 0
                        property int turns: 0

                        width: VLCStyle.dp(16, VLCStyle.scale)
                        height: width
                        sourceSize: Qt.size(32, 32)
                        source: "qrc:///misc/wait" + (frame + 1) + ".svg"

                        Timer {
                            interval: 100
                            repeat: true
                            running: cell.spinLoops !== 0 && (cell.spinLoops < 0 || spinner.turns < cell.spinLoops)
                            onTriggered: {
                                spinner.frame = (spinner.frame + 1) % 4
                                if (spinner.frame === 0)
                                    ++spinner.turns
                            }
                        }
                        Connections {
                            target: cell
                            function onSpinLoopsChanged() { spinner.turns = 0 }
                        }
                    }
                }
            }
        }
    }
}
