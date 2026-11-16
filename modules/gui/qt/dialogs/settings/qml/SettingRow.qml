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
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Util

// One line of the settings window: a label (with the option's own
// description as a tooltip) on the left and a control on the right,
// styled after the "VLC Redesign" Figma file.
FocusScope {
    id: root

    // Row description, see SettingsModel.qml
    required property var row

    signal actionRequested(string action)
    // kind "picker": a choice that only the window uses (no option)
    signal picked(var value)

    readonly property string option: row.option ?? ""
    readonly property string kind: row.kind ?? ""

    // filters behind "Spatial audio" (kind "spatial" / "spatialMode")
    readonly property var spatialModes: [
        { text: qsTr("Headphone virtualization"), value: "headphone_channel_mixer" },
        { text: qsTr("Room effect"), value: "spatializer" }
    ].filter((m) => VLCConfig.moduleExists(m.value))

    function _spatialMode() {
        const mode = String(VLCConfig.uiValue("Audio/SpatialMode", ""))
        return spatialModes.some((m) => m.value === mode) ? mode : (spatialModes[0]?.value ?? "")
    }

    // Simple-preferences settings that are not one option (see SettingsModel)
    readonly property var layoutChoices: [
        { value: "modern", text: qsTr("Modern") },
        { value: "classic", text: qsTr("Classic") }
    ].concat(VLCConfig.moduleExists("skins2") ? [{ value: "skins", text: qsTr("Skins") }] : [])

    // as the classic "Caching policy" (network = value * 10 / 3)
    readonly property var cachingChoices: [
        { value: 0, text: qsTr("Custom") },
        { value: 100, text: qsTr("Lowest latency") },
        { value: 200, text: qsTr("Low latency") },
        { value: 300, text: qsTr("Normal") },
        { value: 500, text: qsTr("High latency") },
        { value: 1000, text: qsTr("Higher latency") }
    ]

    function _layout() {
        if (String(VLCConfig.value("intf") ?? "").indexOf("skin") >= 0)
            return "skins"
        const menu = !!VLCConfig.value("qt-menubar")
        const title = !!VLCConfig.value("qt-titlebar")
        const pin = !!VLCConfig.value("qt-pin-controls")
        if (menu && title && pin)
            return "classic"
        if (!menu && !title && !pin)
            return "modern"
        return "" // a mix: neither preset
    }

    function _setLayout(layout) {
        if (layout === "skins") {
            VLCConfig.setValue("intf", "skins2,any")
            return
        }
        VLCConfig.setValue("intf", "")
        const classic = (layout === "classic")
        VLCConfig.setValue("qt-menubar", classic)
        VLCConfig.setValue("qt-titlebar", classic)
        VLCConfig.setValue("qt-pin-controls", classic)
        MainCtx.reloadPrefs()
    }

    function _caching() {
        const file = Number(VLCConfig.value("file-caching"))
        const same = Math.trunc(file * 10 / 3) === Number(VLCConfig.value("network-caching"))
                  && file === Number(VLCConfig.value("disc-caching"))
                  && file === Number(VLCConfig.value("live-caching"))
        return (same && cachingChoices.some((c) => c.value === file)) ? file : 0
    }

    // options whose change refreshes the row
    readonly property var _watched: {
        switch (kind) {
        case "intf": return ["control", "extraintf"]
        case "startVolume": return ["aout", "#startVolume"]
        case "layout": return ["intf", "qt-menubar", "qt-titlebar", "qt-pin-controls"]
        case "caching": return ["file-caching", "network-caching", "disc-caching", "live-caching"]
        case "language": return ["#language"]
        case "qtStyle": return ["#qtStyle"]
        }
        return []
    }

    // "option" / "!option": the row is enabled only when that switch is on / off
    readonly property string _reqOption: String(row.requires ?? "").replace(/^!/, "")
    readonly property bool _reqNegated: String(row.requires ?? "").startsWith("!")
    property var _reqValue: _reqOption !== "" ? VLCConfig.value(_reqOption) : true
    readonly property bool _requirementMet: _reqOption === "" || (!!_reqValue !== _reqNegated)

    // Whether this build can do what the row sets
    readonly property bool supported: {
        if (row.os && Qt.platform.os !== row.os)
            return false
        if (row.needsML && !MainCtx.mediaLibraryAvailable)
            return false
        if (kind === "colorScheme" || kind === "action" || kind === "picker" || kind === "layout"
         || kind === "intfScale" || kind === "caching" || kind === "qtStyle" || kind === "uiToggle")
            return true
        if (kind === "intf")
            return VLCConfig.moduleExists(row.module)
        if (kind === "startVolume")
            return Number(value) >= 0
        if (kind === "language")
            return choices.length > 0
        if (kind === "mediaFolders")
            return MainCtx.mediaLibraryAvailable
        if (kind === "openSubtitles")
            return VLCOpenSubtitles.available
        if (kind === "filter")
            return VLCConfig.exists(row.list) && VLCConfig.moduleExists(row.module)
        if (kind === "equalizer")
            return VLCConfig.moduleExists(row.module)
        if (kind === "spatial" || kind === "spatialMode")
            return VLCConfig.exists("audio-filter") && spatialModes.length > 0
        if (row.module && !VLCConfig.moduleExists(row.module))
            return false
        return VLCConfig.exists(option)
    }

    // Whether the row is shown: rows marked greyIfMissing stay, greyed out
    readonly property bool available: supported || !!row.greyIfMissing

    readonly property string type: (option !== "") ? VLCConfig.type(option) : ""
    readonly property var choices: {
        if (kind === "spatialMode")
            return spatialModes
        if (kind === "picker")
            return row.choices ?? []
        if (kind === "layout")
            return layoutChoices
        if (kind === "caching")
            return cachingChoices
        if (kind === "language")
            return VLCConfig.languages()
        if (kind === "qtStyle")
            return VLCConfig.qtStyles()
        return (option !== "" && kind !== "accent") ? VLCConfig.choices(option) : []
    }
    readonly property var range: (option !== "") ? VLCConfig.range(option) : ({})

    // Current value, refreshed when the option changes from anywhere
    property var value: _read()

    function _read() {
        if (kind === "filter")
            return VLCConfig.hasModule(row.list, row.module)
        if (kind === "spatial")
            return spatialModes.some((m) => VLCConfig.hasModule("audio-filter", m.value))
        if (kind === "spatialMode")
            return _spatialMode()
        if (kind === "picker")
            return row.value ?? ""
        if (kind === "uiToggle") {
            // an interface setting (VLCConfig.uiValue), read back as text
            const stored = VLCConfig.uiValue(row.uiKey, row.uiDefault ?? false)
            return stored === true || stored === "true"
        }
        if (kind === "intf")
            return VLCConfig.hasIntf(row.module)
        if (kind === "startVolume")
            return VLCConfig.startVolume()
        if (kind === "language")
            return VLCConfig.language()
        if (kind === "qtStyle")
            return VLCConfig.qtStyle()
        if (kind === "intfScale")
            return Math.round(MainCtx.getIntfUserScaleFactor() * 100)
        if (kind === "layout")
            return _layout()
        if (kind === "caching")
            return _caching()
        if (option === "")
            return undefined
        return VLCConfig.value(option)
    }

    // turns spatial audio on with `mode`, or off
    function _setSpatial(on, mode) {
        for (const m of spatialModes) {
            const enable = on && m.value === mode
            VLCConfig.setModule("audio-filter", m.value, enable)
            VLCEffects.applyAudioFilter(m.value, enable)
        }
    }

    function write(newValue) {
        if (kind === "picker") {
            root.value = newValue
            root.picked(newValue)
        } else if (kind === "uiToggle") {
            VLCConfig.setUiValue(row.uiKey, !!newValue)
            root.value = !!newValue
        } else if (kind === "intf") {
            VLCConfig.setIntf(row.module, !!newValue)
        } else if (kind === "startVolume") {
            VLCConfig.setStartVolume(Math.round(newValue))
        } else if (kind === "language") {
            VLCConfig.setLanguage(newValue)
        } else if (kind === "qtStyle") {
            VLCConfig.setQtStyle(newValue)
        } else if (kind === "intfScale") {
            MainCtx.setIntfUserScaleFactor(newValue / 100)
        } else if (kind === "layout") {
            _setLayout(newValue)
        } else if (kind === "caching") {
            if (newValue > 0) {
                VLCConfig.setValue("file-caching", newValue)
                VLCConfig.setValue("network-caching", Math.trunc(newValue * 10 / 3))
                VLCConfig.setValue("disc-caching", newValue)
                VLCConfig.setValue("live-caching", newValue)
            }
            root.value = _caching()
        } else if (kind === "filter") {
            VLCConfig.setModule(row.list, row.module, newValue)
            if (row.live)
                VLCEffects.applyAudioFilter(row.module, newValue)
        } else if (kind === "spatial") {
            _setSpatial(!!newValue, _spatialMode())
        } else if (kind === "spatialMode") {
            const on = spatialModes.some((m) => VLCConfig.hasModule("audio-filter", m.value))
            VLCConfig.setUiValue("Audio/SpatialMode", newValue)
            root.value = newValue
            if (on)
                _setSpatial(true, newValue)
        } else if (option !== "") {
            VLCConfig.setValue(option, newValue)
            // e.g. the disc drive sets the DVD, VCD and audio CD devices at once
            if (newValue !== "")
                for (const other of (row.alsoSet ?? []))
                    if (VLCConfig.exists(other))
                        VLCConfig.setValue(other, newValue)
            if (kind === "eqPreset")
                VLCEffects.applyEqualizerPreset(newValue) // the bands of the preset
            else if (row.live)
                VLCEffects.applyAudioValue(option, newValue)
        }
    }

    Connections {
        target: VLCConfig
        function onValueChanged(name) {
            if (name === "" || name === root.option || name === root.row.list || root._watched.includes(name))
                root.value = root._read()
            if (root._reqOption !== "" && (name === "" || name === root._reqOption))
                root._reqValue = VLCConfig.value(root._reqOption)
        }
    }

    Connections {
        target: MainCtx
        enabled: root.kind === "intfScale"
        function onIntfScaleFactorChanged() { root.value = root._read() }
    }

    // The control used for this row
    readonly property Component _control: {
        switch (kind) {
        case "colorScheme": return colorSchemeComponent
        case "accent": return accentComponent
        case "filter": return toggleComponent
        case "spatial": return toggleComponent
        case "spatialMode": return dropdownComponent
        case "picker": return dropdownComponent
        case "layout": return segmentedComponent
        case "caching": return dropdownComponent
        case "language": return dropdownComponent
        case "qtStyle": return dropdownComponent
        case "intf": return toggleComponent
        case "uiToggle": return toggleComponent
        case "startVolume": return sliderComponent
        case "intfScale": return sliderComponent
        case "mediaFolders": return foldersComponent
        case "eqPreset": return dropdownComponent
        case "equalizer": return null
        case "action": return actionComponent
        case "openSubtitles": return openSubtitlesComponent
        case "slider": return sliderComponent
        case "number": return numberComponent
        }
        switch (type) {
        case "bool": return toggleComponent
        case "file":
        case "directory": return pathComponent
        case "rgb": return textComponent
        // the list as text (order and extra entries kept), the modules as
        // chips below the row (moduleChips)
        case "modulelist": return textComponent
        }
        if (choices.length > 0)
            return (choices.length <= 3 && type !== "module") ? segmentedComponent : dropdownComponent
        if ((type === "int" || type === "float") && range.min !== undefined && (range.max - range.min) <= 1000)
            return sliderComponent
        if (type === "int" || type === "float")
            return numberComponent
        return textComponent
    }

    visible: available
    enabled: supported && _requirementMet
    opacity: enabled ? 1.0 : 0.4

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: {
        if (!available)
            return 0
        if (kind === "equalizer")
            return equalizerLoader.implicitHeight + 2 * VLCStyle.dp(6, VLCStyle.scale)
        return _rowHeight + (moduleChips.active ? moduleChips.implicitHeight + VLCStyle.margin_small : 0)
    }

    readonly property real _rowHeight: Math.max(VLCStyle.dp(46, VLCStyle.scale), rowLayout.implicitHeight)

    // Module lists (e.g. video filters): one chip per module, on = in the list
    Loader {
        id: moduleChips

        active: root.available && root.kind === "" && root.type === "modulelist" && root.choices.length > 0
        anchors { top: rowLayout.bottom; left: parent.left; right: parent.right }

        sourceComponent: Flow {
            id: chipFlow

            spacing: VLCStyle.dp(4, VLCStyle.scale)

            // "a:b" or "a,b" (some lists use commas, keep what is there)
            readonly property string separator: String(root.value ?? "").indexOf(",") >= 0 ? "," : ":"
            readonly property var entries: String(root.value ?? "").split(/[,:]/)
                                                                   .map((e) => e.trim())
                                                                   .filter((e) => e !== "")

            function setModule(name, on) {
                const list = entries.filter((e) => e.split("{")[0] !== name)
                if (on)
                    list.push(name)
                root.write(list.join(separator))
            }

            Repeater {
                model: root.choices

                T.AbstractButton {
                    id: chip

                    required property var modelData

                    readonly property bool isOn: chipFlow.entries.some((e) => e.split("{")[0] === modelData.value)

                    implicitWidth: chipLabel.implicitWidth + 2 * VLCStyle.dp(10, VLCStyle.scale)
                    implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

                    onClicked: chipFlow.setModule(modelData.value, !isOn)

                    Accessible.role: Accessible.CheckBox
                    Accessible.checked: isOn
                    Accessible.name: modelData.text

                    background: Rectangle {
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: chip.isOn ? root._selected
                                       : (chip.hovered ? Qt.lighter(root._well, 1.3) : root._well)
                        border.width: chip.visualFocus ? VLCStyle.focus_border : 0
                        border.color: theme.visualFocus
                    }
                    contentItem: T.Label {
                        id: chipLabel
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: chip.modelData.text
                        font.pixelSize: VLCStyle.fontSize_normal
                        color: chip.isOn ? theme.accent : root._text
                    }
                }
            }
        }
    }

    // the equalizer bands take the whole width (Figma "EQ")
    Loader {
        id: equalizerLoader

        active: root.kind === "equalizer"
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }

        sourceComponent: EqualizerPanel {
            wellColor: root._well
            surfaceColor: root._surface
            fillColor: root._selected
            handleColor: Qt.darker(theme.accent, 1.23)
            textColor: root._text
            labelColor: root._mutedText
        }
    }

    readonly property real controlWidth: VLCStyle.dp(320, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    readonly property ColorContext windowColorContext: ColorContext {
        id: windowTheme
        colorSet: ColorContext.Window
    }

    readonly property ColorContext itemColorContext: ColorContext {
        id: itemTheme
        colorSet: ColorContext.Item
    }

    // Figma colors expressed with palette roles:
    // well (#090909), surface (#191919), selected (#371F06)
    readonly property color _well: windowTheme.bg.secondary
    readonly property color _surface: windowTheme.bg.primary
    readonly property color _selected: itemTheme.bg.highlight
    readonly property color _text: theme.fg.secondary
    readonly property color _mutedText: Qt.alpha(theme.fg.secondary, 0.7)
    readonly property real _radius: VLCStyle.dp(6, VLCStyle.scale)

    RowLayout {
        id: rowLayout

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: root._rowHeight
        visible: root.kind !== "equalizer"
        spacing: VLCStyle.margin_normal

        RowLayout {
            Layout.fillWidth: true
            visible: root.row.label !== ""
            spacing: VLCStyle.margin_xsmall

            T.Label {
                // Natural width; the layout shrinks it (and it elides) only
                // when the window is too narrow for the label and the control
                text: root.row.label
                color: root._text
                font.pixelSize: VLCStyle.fontSize_large
                elide: Text.ElideRight
            }

            // Info icon with the option's description from VLC itself
            T.Label {
                id: infoIcon

                visible: !!row.info || (root.option !== "" && VLCConfig.longText(root.option) !== "")
                text: VLCIcons.info
                font.family: VLCIcons.fontFamily
                font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
                color: infoHover.hovered ? root._text : root._mutedText

                HoverHandler { id: infoHover }

                T.ToolTip {
                    id: infoTip

                    visible: infoHover.hovered
                    delay: VLCStyle.delayToolTipAppear
                    text: row.info ?? (root.option !== "" ? VLCConfig.longText(root.option) : "")

                    // above the icon, clear of the icon and the mouse pointer
                    x: 0
                    y: -height - VLCStyle.dp(6, VLCStyle.scale)

                    // a template ToolTip has no size of its own
                    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
                    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
                    width: Math.min(implicitWidth, VLCStyle.dp(360, VLCStyle.scale))
                    padding: VLCStyle.margin_small

                    contentItem: T.Label {
                        text: infoTip.text
                        color: theme.fg.primary
                        wrapMode: Text.Wrap
                        font.pixelSize: VLCStyle.fontSize_normal
                    }
                    // with the 2 px well frame of the redesign's drop-downs
                    background: Rectangle {
                        color: windowTheme.bg.primary
                        radius: root._radius
                        border.width: VLCStyle.dp(2, VLCStyle.scale)
                        border.color: root._well
                    }
                }
            }
        }

        Loader {
            id: controlLoader

            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            // without a label, the control takes the whole row
            Layout.fillWidth: root.row.label === ""
            focus: true
            active: root.available
            sourceComponent: root._control
        }
    }

    // ------------------------------------------------------------------
    // Controls

    // ON/OFF switch (Figma "Toggle": 68x32)
    Component {
        id: toggleComponent

        T.AbstractButton {
            id: toggle

            checkable: true
            checked: !!root.value
            onToggled: root.write(checked)

            implicitWidth: VLCStyle.dp(68, VLCStyle.scale)
            implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

            Accessible.role: Accessible.CheckBox
            Accessible.name: root.row.label

            readonly property real _inset: VLCStyle.dp(3, VLCStyle.scale)
            readonly property real _knob: height - 2 * _inset

            background: Rectangle {
                color: root._well
                radius: root._radius
                border.width: toggle.visualFocus ? VLCStyle.focus_border : 0
                border.color: theme.visualFocus

                // Label half
                Rectangle {
                    x: toggle.checked ? toggle._inset : (toggle.width - width - toggle._inset)
                    anchors.verticalCenter: parent.verticalCenter
                    width: toggle.width - toggle._knob - 3 * toggle._inset
                    height: toggle._knob
                    radius: VLCStyle.dp(3, VLCStyle.scale)
                    color: toggle.checked ? root._selected : root._surface

                    T.Label {
                        anchors.centerIn: parent
                        text: toggle.checked ? qsTr("ON") : qsTr("OFF")
                        font.pixelSize: VLCStyle.fontSize_normal
                        color: toggle.checked ? theme.accent : root._mutedText
                    }
                }

                // Knob
                Rectangle {
                    x: toggle.checked ? (toggle.width - width - toggle._inset) : toggle._inset
                    anchors.verticalCenter: parent.verticalCenter
                    width: toggle._knob
                    height: toggle._knob
                    radius: VLCStyle.dp(3, VLCStyle.scale)
                    color: toggle.checked ? Qt.darker(theme.accent, 1.23) : theme.border

                    Behavior on x {
                        NumberAnimation { duration: VLCStyle.duration_veryShort; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    // Drop-down list (Figma "Dropdown": 320x36, inner 32px surface)
    Component {
        id: dropdownComponent

        T.ComboBox {
            id: combo

            implicitWidth: root.controlWidth
            implicitHeight: VLCStyle.dp(36, VLCStyle.scale)

            model: root.choices
            textRole: "text"
            valueRole: "value"

            Component.onCompleted: currentIndex = indexOfValue(root.value)
            Connections {
                target: root
                function onValueChanged() { combo.currentIndex = combo.indexOfValue(root.value) }
            }

            onActivated: (index) => root.write(valueAt(index))

            Accessible.name: root.row.label

            background: Rectangle {
                color: root._well
                radius: root._radius
                border.width: combo.visualFocus ? VLCStyle.focus_border : 0
                border.color: theme.visualFocus

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: combo.hovered ? Qt.lighter(root._surface, 1.2) : root._surface
                }
            }

            contentItem: T.Label {
                leftPadding: VLCStyle.dp(14, VLCStyle.scale)
                rightPadding: VLCStyle.dp(14, VLCStyle.scale) + VLCStyle.icon_normal
                verticalAlignment: Text.AlignVCenter
                text: (combo.currentIndex >= 0) ? combo.displayText : String(root.value ?? "")
                color: root._text
                font.pixelSize: VLCStyle.fontSize_large
                elide: Text.ElideRight
            }

            indicator: T.Label {
                x: combo.width - width - VLCStyle.dp(10, VLCStyle.scale)
                anchors.verticalCenter: combo.verticalCenter
                text: VLCIcons.chevron_down
                font.family: VLCIcons.fontFamily
                font.pixelSize: VLCStyle.icon_normal
                color: root._text
            }

            delegate: T.ItemDelegate {
                required property var modelData
                required property int index

                width: combo.width - VLCStyle.dp(4, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
                highlighted: combo.highlightedIndex === index

                contentItem: T.Label {
                    leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.text
                    color: (combo.currentIndex === index) ? theme.accent : root._text
                    font.pixelSize: VLCStyle.fontSize_large
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: parent.highlighted ? root._surface : "transparent"
                }
            }

            popup: T.Popup {
                y: combo.height + VLCStyle.dp(2, VLCStyle.scale)
                width: combo.width
                implicitHeight: Math.min(contentItem.implicitHeight + 2 * padding, VLCStyle.dp(320, VLCStyle.scale))
                padding: VLCStyle.dp(2, VLCStyle.scale)

                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: combo.popup.visible ? combo.delegateModel : null
                    currentIndex: combo.highlightedIndex
                }

                background: Rectangle {
                    color: root._well
                    radius: root._radius
                    border.width: VLCStyle.border
                    border.color: windowTheme.border
                }
            }
        }
    }

    // Segmented choice (Figma "Values": up to three options side by side)
    Component {
        id: segmentedComponent

        Rectangle {
            id: segmented

            implicitWidth: root.controlWidth
            implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
            color: root._well
            radius: root._radius

            property var options: root.choices
            property var current: root.value
            signal picked(var value)
            onPicked: (v) => root.write(v)

            RowLayout {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
                spacing: VLCStyle.dp(2, VLCStyle.scale)

                Repeater {
                    model: segmented.options

                    T.AbstractButton {
                        id: segment

                        required property var modelData

                        readonly property bool selected: modelData.value == segmented.current

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        onClicked: segmented.picked(modelData.value)

                        Accessible.role: Accessible.RadioButton
                        Accessible.name: modelData.text

                        background: Rectangle {
                            radius: VLCStyle.dp(4, VLCStyle.scale)
                            color: segment.selected ? root._selected : root._surface
                            border.width: segment.visualFocus ? VLCStyle.focus_border : 0
                            border.color: theme.visualFocus
                        }
                        contentItem: T.Label {
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: segment.modelData.text
                            elide: Text.ElideRight
                            font.pixelSize: VLCStyle.fontSize_large
                            color: segment.selected ? theme.accent : root._mutedText
                        }
                    }
                }
            }
        }
    }

    // Day / Night / System, stored by the interface rather than the core
    Component {
        id: colorSchemeComponent

        Loader {
            sourceComponent: segmentedComponent
            onLoaded: {
                item.options = [
                    { value: 2, text: qsTr("Dark") },
                    { value: 1, text: qsTr("Light") },
                    { value: 0, text: qsTr("System") }
                ]
                item.current = Qt.binding(() => MainCtx.colorScheme.scheme)
                // root.write() ignores this row (it has no option); the
                // scheme is changed through the interface model instead
                item.picked.connect((v) => {
                    const model = MainCtx.colorScheme
                    model.setData(model.index(v, 0), true, Qt.CheckStateRole)
                })
            }
        }
    }

    // Accent color swatches (Figma presets); applied on next start
    Component {
        id: accentComponent

        Rectangle {
            id: swatches

            implicitWidth: root.controlWidth
            implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
            color: root._well
            radius: root._radius

            // "default" keeps the built-in accent (the first swatch)
            readonly property var presets: ["default", "#E15032", "#C49E23", "#19A234",
                                            "#18AAD3", "#185DD3", "#8E42FF", "#F052B3", "#AFAFAF"]

            RowLayout {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(2, VLCStyle.scale)
                spacing: VLCStyle.dp(4, VLCStyle.scale)

                Repeater {
                    model: swatches.presets

                    T.AbstractButton {
                        id: swatch

                        required property string modelData
                        required property int index

                        readonly property bool selected: String(root.value).toLowerCase() === modelData.toLowerCase()

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        onClicked: root.write(modelData)

                        Accessible.role: Accessible.RadioButton
                        Accessible.name: (index === 0) ? qsTr("Default") : modelData

                        background: Rectangle {
                            radius: VLCStyle.dp(4, VLCStyle.scale)
                            color: swatch.selected ? root._selected : "transparent"
                            border.width: swatch.visualFocus ? VLCStyle.focus_border : 0
                            border.color: theme.visualFocus

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: VLCStyle.dp(6, VLCStyle.scale)
                                radius: VLCStyle.dp(1, VLCStyle.scale)
                                // The first swatch shows the built-in VLC orange
                                color: (swatch.index === 0) ? "#D37918" : swatch.modelData
                                opacity: swatch.selected ? 1.0 : 0.7
                            }
                        }
                    }
                }
            }

        }
    }

    // Slider with tick marks (Figma "range": 16px track, 8x24 handle)
    Component {
        id: sliderComponent

        ColumnLayout {
            id: sliderColumn

            spacing: VLCStyle.dp(4, VLCStyle.scale)

            readonly property real scale: root.row.scale ?? 1
            readonly property real from: root.row.min ?? ((root.range.min ?? 0) / scale)
            readonly property real to: (root.kind === "startVolume") ? Number(VLCConfig.value("qt-max-volume"))
                                                                    : (root.row.max ?? ((root.range.max ?? 100) / scale))
            readonly property real step: root.row.step ?? (((root.type === "int" || root.kind === "startVolume") && scale === 1) ? 1 : 0)
            readonly property string unit: root.row.unit ?? ""

            function format(v) {
                const rounded = Math.round(v * 100) / 100
                return rounded + (unit !== "" ? " " + unit : "")
            }

            T.Slider {
                id: slider

                Layout.preferredWidth: root.controlWidth
                implicitHeight: VLCStyle.dp(24, VLCStyle.scale)

                from: sliderColumn.from
                to: sliderColumn.to
                stepSize: sliderColumn.step
                snapMode: (stepSize > 0) ? T.Slider.SnapAlways : T.Slider.NoSnap
                value: Number(root.value) / sliderColumn.scale

                Accessible.name: root.row.label

                onMoved: {
                    let v = value * sliderColumn.scale
                    if (root.type === "int")
                        v = Math.round(v)
                    root.write(v)
                }

                background: Rectangle {
                    x: slider.leftPadding
                    y: slider.topPadding + (slider.availableHeight - height) / 2
                    width: slider.availableWidth
                    height: VLCStyle.dp(16, VLCStyle.scale)
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: root._well
                    border.width: slider.visualFocus ? VLCStyle.focus_border : 0
                    border.color: theme.visualFocus

                    Rectangle {
                        x: VLCStyle.dp(2, VLCStyle.scale)
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(0, slider.visualPosition * (parent.width - 2 * x))
                        height: parent.height - 2 * VLCStyle.dp(2, VLCStyle.scale)
                        radius: VLCStyle.dp(3, VLCStyle.scale)
                        color: root._selected
                    }
                }

                handle: Rectangle {
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + (slider.availableHeight - height) / 2
                    implicitWidth: VLCStyle.dp(8, VLCStyle.scale)
                    implicitHeight: VLCStyle.dp(24, VLCStyle.scale)
                    radius: VLCStyle.dp(3, VLCStyle.scale)
                    color: theme.accent
                }

                T.ToolTip {
                    id: sliderTip

                    parent: slider.handle
                    visible: slider.pressed || slider.hovered
                    text: sliderColumn.format(slider.value)
                    y: -height - VLCStyle.dp(4, VLCStyle.scale)
                    padding: VLCStyle.dp(4, VLCStyle.scale)
                    contentItem: T.Label {
                        text: sliderTip.text
                        color: theme.fg.primary
                        font.pixelSize: VLCStyle.fontSize_normal
                    }
                    background: Rectangle {
                        color: windowTheme.bg.primary
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                T.Label {
                    text: sliderColumn.format(slider.from)
                    font.pixelSize: VLCStyle.fontSize_small
                    color: root._mutedText
                }
                Item { Layout.fillWidth: true }
                T.Label {
                    text: sliderColumn.format(slider.value)
                    font.pixelSize: VLCStyle.fontSize_small
                    color: root._text
                }
                Item { Layout.fillWidth: true }
                T.Label {
                    text: sliderColumn.format(slider.to)
                    font.pixelSize: VLCStyle.fontSize_small
                    color: root._mutedText
                }
            }
        }
    }

    // Shared look for text inputs (Figma: well with a 2px surface border)
    component InputField: T.TextField {
        id: field

        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)
        leftPadding: VLCStyle.dp(12, VLCStyle.scale)
        rightPadding: VLCStyle.dp(12, VLCStyle.scale)
        verticalAlignment: TextInput.AlignVCenter

        color: root._text
        selectionColor: root._selected
        selectedTextColor: theme.fg.primary
        font.pixelSize: VLCStyle.fontSize_large

        background: Rectangle {
            color: root._well
            radius: root._radius
            border.width: VLCStyle.dp(2, VLCStyle.scale)
            border.color: field.activeFocus ? theme.accent : root._surface
        }
    }

    // Plain text, colors as #RRGGBB, and passwords
    Component {
        id: textComponent

        InputField {
            implicitWidth: root.controlWidth
            text: String(root.value ?? "")
            echoMode: (root.type === "password") ? TextInput.Password : TextInput.Normal
            onEditingFinished: {
                if (text !== String(root.value ?? ""))
                    root.write(text)
            }
            Accessible.name: root.row.label
        }
    }

    // Numbers without a meaningful range
    Component {
        id: numberComponent

        RowLayout {
            spacing: VLCStyle.margin_xsmall

            InputField {
                id: numberField

                Layout.preferredWidth: VLCStyle.dp(120, VLCStyle.scale)
                horizontalAlignment: TextInput.AlignRight

                readonly property real scale: root.row.scale ?? 1

                // Floats are stored with binary rounding noise (e.g. 1.0000019),
                // show them with at most three decimals
                text: (root.value === undefined) ? "" : String(Math.round(Number(root.value) / scale * 1000) / 1000)
                validator: (root.type === "int" && scale === 1) ? intValidator : doubleValidator
                onEditingFinished: {
                    let v = Number(text) * scale
                    if (root.type === "int")
                        v = Math.round(v)
                    if (!isNaN(v) && v !== Number(root.value))
                        root.write(v)
                }
                Accessible.name: root.row.label

                IntValidator { id: intValidator }
                DoubleValidator { id: doubleValidator; notation: DoubleValidator.StandardNotation; locale: "C" }
            }

            T.Label {
                visible: text !== ""
                text: root.row.unit ?? ""
                font.pixelSize: VLCStyle.fontSize_large
                color: root._mutedText
            }
        }
    }

    // File or folder path with a Browse button
    Component {
        id: pathComponent

        RowLayout {
            spacing: VLCStyle.margin_xsmall

            InputField {
                id: pathField
                Layout.preferredWidth: root.controlWidth - VLCStyle.dp(100, VLCStyle.scale) - VLCStyle.margin_xsmall
                text: String(root.value ?? "")
                onEditingFinished: {
                    if (text !== String(root.value ?? ""))
                        root.write(text)
                }
                Accessible.name: root.row.label
            }

            SettingButton {
                text: qsTr("Browse")
                onClicked: {
                    const path = VLCConfig.browse(root.row.label, pathField.text,
                                                  root.type === "directory",
                                                  VLCConfig.type(root.option) === "file")
                    if (path !== "")
                        root.write(path)
                }
            }
        }
    }

    // A button that triggers something in the window; with `confirm`, the
    // first click asks for a second one (e.g. "Reset" -> "Confirm")
    Component {
        id: actionComponent

        SettingButton {
            id: actionButton

            property bool armed: false

            text: armed ? root.row.confirm : (root.row.buttonText ?? qsTr("Open"))
            highlighted: armed
            onClicked: {
                if (root.row.confirm && !armed) {
                    armed = true
                    disarmTimer.restart()
                    return
                }
                armed = false
                root.actionRequested(root.row.action)
            }

            Timer {
                id: disarmTimer
                interval: 4000
                onTriggered: actionButton.armed = false
            }
        }
    }

    // Media library folders (row.banned: the excluded ones), with Remove
    // buttons and one to add a folder
    Component {
        id: foldersComponent

        ColumnLayout {
            id: folders

            readonly property var model: VLCConfig.mediaFolders(!!root.row.banned)

            implicitWidth: root.controlWidth
            spacing: VLCStyle.margin_xxsmall

            Repeater {
                model: folders.model

                RowLayout {
                    required property string display_url
                    required property int index

                    Layout.preferredWidth: root.controlWidth
                    spacing: VLCStyle.margin_xsmall

                    T.Label {
                        Layout.fillWidth: true
                        text: parent.display_url
                        elide: Text.ElideMiddle
                        color: root._text
                        font.pixelSize: VLCStyle.fontSize_normal
                    }

                    SettingButton {
                        text: qsTr("Remove")
                        onClicked: folders.model.removeAt(parent.index)
                    }
                }
            }

            SettingButton {
                Layout.alignment: Qt.AlignRight
                implicitWidth: VLCStyle.dp(140, VLCStyle.scale)
                text: root.row.banned ? qsTr("Exclude folder…") : qsTr("Add folder…")
                onClicked: {
                    const url = VLCConfig.browseFolder(root.row.label)
                    if (url !== "")
                        folders.model.add(url)
                }
            }
        }
    }

    // opensubtitles.com account: user name, password and Sign in, or the
    // account and Sign out. The password goes to VLC's keystore.
    Component {
        id: openSubtitlesComponent

        ColumnLayout {
            id: osAccount

            spacing: VLCStyle.margin_xsmall

            function signIn() {
                if (osUser.text.trim() !== "" && osPassword.text !== "")
                    VLCOpenSubtitles.signIn(osUser.text, osPassword.text)
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                visible: !VLCOpenSubtitles.signedIn
                spacing: VLCStyle.margin_xsmall

                onVisibleChanged: {
                    if (!visible)
                        osPassword.text = ""
                }

                InputField {
                    id: osUser
                    Layout.preferredWidth: VLCStyle.dp(150, VLCStyle.scale)
                    Accessible.name: qsTr("User name")
                    onAccepted: osPassword.forceActiveFocus()

                    FieldPlaceholder { field: osUser; text: qsTr("User name") }
                }

                InputField {
                    id: osPassword
                    Layout.preferredWidth: VLCStyle.dp(150, VLCStyle.scale)
                    echoMode: TextInput.Password
                    Accessible.name: qsTr("Password")
                    onAccepted: osAccount.signIn()

                    FieldPlaceholder { field: osPassword; text: qsTr("Password") }
                }

                SettingButton {
                    text: VLCOpenSubtitles.signingIn ? qsTr("Signing in…") : qsTr("Sign in")
                    enabled: !VLCOpenSubtitles.signingIn && osUser.text.trim() !== "" && osPassword.text !== ""
                    onClicked: osAccount.signIn()
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                visible: VLCOpenSubtitles.signedIn
                spacing: VLCStyle.margin_normal

                T.Label {
                    text: VLCOpenSubtitles.allowedDownloads > 0
                          ? qsTr("Signed in as %1 (%2 downloads a day)").arg(VLCOpenSubtitles.username).arg(VLCOpenSubtitles.allowedDownloads)
                          : qsTr("Signed in as %1").arg(VLCOpenSubtitles.username)
                    color: root._text
                    font.pixelSize: VLCStyle.fontSize_large
                }

                SettingButton {
                    text: qsTr("Sign out")
                    onClicked: VLCOpenSubtitles.signOut()
                }
            }

            T.Label {
                Layout.alignment: Qt.AlignRight
                visible: text !== ""
                text: VLCOpenSubtitles.signedIn ? "" : VLCOpenSubtitles.accountError
                color: theme.accent
                font.pixelSize: VLCStyle.fontSize_normal
            }
        }
    }

    // the template text field draws no placeholder
    component FieldPlaceholder: T.Label {
        required property T.TextField field

        anchors.fill: parent
        leftPadding: field.leftPadding
        verticalAlignment: Text.AlignVCenter
        visible: field.text === "" && !field.activeFocus
        color: root._mutedText
        font: field.font
        elide: Text.ElideRight
    }

    component SettingButton: T.Button {
        id: button

        implicitWidth: VLCStyle.dp(100, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

        background: Rectangle {
            radius: root._radius
            color: button.hovered ? Qt.lighter(root._surface, 1.2) : root._surface
            border.width: button.visualFocus ? VLCStyle.focus_border : 0
            border.color: theme.visualFocus
        }
        contentItem: T.Label {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: button.text
            font.pixelSize: VLCStyle.fontSize_large
            font.weight: Font.DemiBold
            color: button.highlighted ? theme.accent : root._text
        }
    }
}
