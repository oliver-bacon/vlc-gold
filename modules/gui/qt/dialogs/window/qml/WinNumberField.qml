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

import VLC.Style

// a number in a field, with its unit; `value` follows the text
RowLayout {
    id: numberField

    property real value: 0
    property real from: -2147483647
    property real to: 2147483647
    property int decimals: 0
    property string unit: ""
    property alias field: numberInput
    property real fieldWidth: VLCStyle.dp(120, VLCStyle.scale)
    // Up / Down and the − + buttons
    property real step: Math.pow(10, -decimals)
    property bool buttons: false
    // room for a unit also without one (lines up with the fields that have one)
    property bool keepUnitSpace: false
    // the unit before the field, as wide as its text: the fields of a
    // column end at the same place whatever their unit
    property bool unitFirst: false
    // smaller, for the value of a slider
    property bool compact: false
    // accessible name
    property string name: ""

    // a value to follow, also after the user typed one (a binding on
    // `value` is lost by then)
    property var source
    onSourceChanged: if (source !== undefined) value = Number(source)

    // the user changed it (not from `value`)
    signal edited(real value)

    spacing: VLCStyle.margin_xsmall

    function _format(v) {
        return decimals > 0 ? Number(v).toFixed(decimals) : String(Math.round(v))
    }

    // not while it is being typed in, unless the value came from elsewhere
    onValueChanged: {
        if (!numberInput.activeFocus || Number(numberInput.text.replace(",", ".")) !== value)
            numberInput.text = _format(value)
    }
    Component.onCompleted: numberInput.text = _format(value)

    function _commit() {
        let v = Number(numberInput.text.replace(",", "."))
        if (isNaN(v))
            v = value
        v = Math.min(to, Math.max(from, v))
        numberInput.text = _format(v)
        if (v !== value) {
            value = v
            edited(v)
        }
    }

    T.Label {
        visible: numberField.unitFirst && numberField.unit !== ""
        text: numberField.unit
        font.pixelSize: VLCStyle.fontSize_large
        color: WinStyle.mutedText
    }

    WinField {
        id: numberInput

        Layout.preferredWidth: numberField.fieldWidth
        implicitWidth: numberField.fieldWidth
        horizontalAlignment: TextInput.AlignRight
        implicitHeight: numberField.compact ? VLCStyle.dp(32, VLCStyle.scale) : WinStyle.fieldHeight
        font.pixelSize: numberField.compact ? VLCStyle.fontSize_normal : VLCStyle.fontSize_large
        Accessible.name: numberField.name
        validator: RegularExpressionValidator {
            regularExpression: numberField.decimals > 0 ? /-?[0-9]*[.,]?[0-9]*/ : /-?[0-9]*/
        }
        onEditingFinished: numberField._commit()
        Keys.onUpPressed: numberField.stepBy(1)
        Keys.onDownPressed: numberField.stepBy(-1)
    }

    function stepBy(n) {
        numberInput.text = _format(Math.min(to, Math.max(from, Number(numberInput.text.replace(",", ".")) + n * step)))
        _commit()
    }

    WinButton {
        visible: numberField.buttons
        implicitWidth: implicitHeight
        text: "−"
        Accessible.name: qsTr("Decrease")
        onClicked: numberField.stepBy(-1)
    }
    WinButton {
        visible: numberField.buttons
        implicitWidth: implicitHeight
        text: "+"
        Accessible.name: qsTr("Increase")
        onClicked: numberField.stepBy(1)
    }

    T.Label {
        visible: !numberField.unitFirst && (numberField.unit !== "" || numberField.keepUnitSpace)
        Layout.minimumWidth: VLCStyle.dp(44, VLCStyle.scale)
        text: numberField.unit
        font.pixelSize: VLCStyle.fontSize_large
        color: WinStyle.mutedText
    }
}
