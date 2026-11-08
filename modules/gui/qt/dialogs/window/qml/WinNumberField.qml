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

    // the user changed it (not from `value`)
    signal edited(real value)

    spacing: VLCStyle.margin_xsmall

    function _format(v) {
        return decimals > 0 ? Number(v).toFixed(decimals) : String(Math.round(v))
    }

    onValueChanged: if (!numberInput.activeFocus) numberInput.text = _format(value)
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

    WinField {
        id: numberInput

        Layout.preferredWidth: numberField.fieldWidth
        implicitWidth: numberField.fieldWidth
        horizontalAlignment: TextInput.AlignRight
        validator: RegularExpressionValidator {
            regularExpression: numberField.decimals > 0 ? /-?[0-9]*[.,]?[0-9]*/ : /-?[0-9]*/
        }
        onEditingFinished: numberField._commit()
        Keys.onUpPressed: { text = numberField._format(Math.min(numberField.to, Number(text) + Math.pow(10, -numberField.decimals))); numberField._commit() }
        Keys.onDownPressed: { text = numberField._format(Math.max(numberField.from, Number(text) - Math.pow(10, -numberField.decimals))); numberField._commit() }
    }

    T.Label {
        visible: numberField.unit !== ""
        Layout.minimumWidth: VLCStyle.dp(44, VLCStyle.scale)
        text: numberField.unit
        font.pixelSize: VLCStyle.fontSize_large
        color: WinStyle.mutedText
    }
}
