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

import VLC.MainInterface
import VLC.Style

// "Convert" (classic dialogs/sout/convert): the source, Convert (Display
// the output, Deinterlace, the profile) or Dump raw input, the destination
// file (or, for several files, "-converted" next to each), Start.
RedesignWindow {
    id: root

    title: qsTr("Convert")
    fitWidth: VLCStyle.dp(760, VLCStyle.scale)

    SoutHelper {
        id: sout
        ctx: MainCtx
        onProfileChanged: root._fixExtension()
    }

    property var mrls: []
    property var options: []
    readonly property bool single: mrls.length === 1

    // the destination file, as a URL
    property string destination: ""

    // DialogsProvider: { mrls, options }
    function reset(args) {
        mrls = args?.mrls ?? []
        options = args?.options ?? []
        destination = ""
        dumpToggle.checked = false
        displayToggle.checked = false
        deinterlaceToggle.checked = false
        appendToggle.checked = false
    }

    // a destination without an extension gets the one of the muxer
    // (ConvertDialog::setDestinationFileExtension)
    function _fixExtension() {
        if (destination === "" || dumpToggle.checked || sout.mux === "")
            return
        const name = destination.substring(destination.lastIndexOf("/") + 1)
        if (name.lastIndexOf(".") === -1)
            destination = destination + "." + sout.mux
    }

    function _browse() {
        const extension = dumpToggle.checked ? ".*" : "." + sout.mux
        const url = sout.browseSaveFile(qsTr("Save file..."),
                                        "%1 (*%2);;%3 (*.*)".arg(qsTr("Containers")).arg(extension).arg(qsTr("All")))
        if (url !== "") {
            destination = url
            _fixExtension()
        }
    }

    function _start() {
        if (single && destination === "")
            return
        const m = mrls, o = options
        const settings = {
            "destination": destination,
            "dump": dumpToggle.checked,
            "deinterlace": deinterlaceToggle.checked,
            "display": displayToggle.checked,
            "appendConverted": appendToggle.checked
        }
        close()
        sout.startConvert(m, o, settings)
    }

    WinSectionTitle { text: qsTr("Source") }

    WinRow {
        label: qsTr("Source:")
        WinLabel {
            Layout.preferredWidth: WinStyle.controlWidth + VLCStyle.dp(140, VLCStyle.scale)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideMiddle
            color: WinStyle.strongText
            text: root.single ? sout.describeSource(root.mrls[0]).text : qsTr("Multiple files selected.")
        }
    }
    WinRow {
        visible: root.single
        label: qsTr("Type:")
        WinLabel { text: root.single ? sout.describeSource(root.mrls[0]).type : "" }
    }

    WinSectionTitle { text: qsTr("Settings") }

    WinRow {
        label: qsTr("Dump raw input")
        WinToggle {
            id: dumpToggle
            onToggled: root._fixExtension()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        enabled: !dumpToggle.checked
        opacity: enabled ? 1 : 0.4

        WinRow {
            label: qsTr("Display the output")
            description: qsTr("This displays the resulting media, but can slow things down.")
            WinToggle { id: displayToggle }
        }
        WinRow {
            label: qsTr("Deinterlace")
            WinToggle { id: deinterlaceToggle }
        }
        ProfileRow {
            helper: sout
        }
    }

    WinSectionTitle { text: qsTr("Destination") }

    WinRow {
        visible: root.single
        label: qsTr("Destination file:")
        WinField {
            implicitWidth: WinStyle.controlWidth - VLCStyle.dp(100, VLCStyle.scale) - VLCStyle.margin_xsmall
            readOnly: true
            text: root.destination !== "" ? sout.displayPath(root.destination) : ""
        }
        WinButton {
            text: qsTr("Browse")
            onClicked: root._browse()
        }
    }

    WinRow {
        visible: !root.single
        label: qsTr("Destination file:")
        WinLabel {
            text: qsTr("Multiple Files Selected.")
            WinToolTip { text: qsTr("Files will be placed in the same directory with the same name.") }
        }
    }
    WinRow {
        visible: !root.single
        label: qsTr("Append '-converted' to filename")
        WinToggle { id: appendToggle }
    }

    footer: [
        WinButton {
            text: qsTr("Cancel")
            onClicked: root.close()
        },
        WinButton {
            text: qsTr("Start")
            highlighted: true
            enabled: !root.single || root.destination !== ""
            onClicked: root._start()
        }
    ]
}
