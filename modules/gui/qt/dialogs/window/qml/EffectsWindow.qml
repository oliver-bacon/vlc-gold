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
import VLC.Player
import VLC.Style

// "Adjustments and Effects" (classic dialogs/extended): Audio Effects
// (Equalizer, Compressor, Expander, Limiter, Spatializer, Stereo Widener,
// Advanced), Video Effects (Essential, Crop, Colors, Geometry, Overlay,
// Advanced), Synchronization and the v4l2 controls, as tabs on the left and
// sections above each page. Same filters and options as the classic window;
// every change is applied and kept at once (VLCEffects, as the player's
// settings panel: no Save button). Crop is not kept, as before.
RedesignWindow {
    id: root

    title: qsTr("Adjustments and Effects")

    resizable: true
    initialHeight: VLCStyle.dp(680, VLCStyle.scale)

    V4l2Controls {
        id: v4l2
        ctx: MainCtx
    }

    tabs: {
        const list = [
            { "text": qsTr("Audio Effects"), "icon": "player_audio" },
            { "text": qsTr("Video Effects"), "icon": "player_video" },
            { "text": qsTr("Synchronization"), "icon": "player_subtitle" }
        ]
        if (v4l2.available)
            list.push({ "text": qsTr("v4l2 controls"), "icon": "main_open_capture_device" })
        return list
    }

    // DialogsProvider: { tab: 0 audio, 2 synchronization }
    function reset(args) {
        currentTab = Math.max(0, Math.min(tabs.length - 1, args?.tab ?? 0))
        _readAll()
    }

    function isShowingTab(tab) {
        return currentTab === tab
    }

    // values are read again when the window opens or the effects change
    property int revision: 0
    function _readAll() { ++revision }

    Connections {
        target: VLCEffects
        function onChanged() { root._readAll() }
    }

    // classic: crop goes back to 0 when the playback stops
    Connections {
        target: Player
        function onPlayingStateChanged() {
            if (Player.playingState === Player.PLAYING_STATE_STOPPED) {
                cropTop.value = 0; cropBottom.value = 0; cropLeft.value = 0; cropRight.value = 0
            }
        }
    }

    // ---- data of the classic panels ------------------------------------------------

    // AudioFilterControlWidget: { option, label, unit, min, max, step }
    readonly property var audioPanels: [
        { "module": "compressor", "title": qsTr("Compressor"), "controls": [
            { "option": "compressor-rms-peak", "label": qsTr("RMS/peak"), "unit": "", "min": 0, "max": 1, "step": 0.001 },
            { "option": "compressor-attack", "label": qsTr("Attack"), "unit": qsTr("ms"), "min": 1.5, "max": 400, "step": 0.1 },
            { "option": "compressor-release", "label": qsTr("Release"), "unit": qsTr("ms"), "min": 2, "max": 800, "step": 0.1 },
            { "option": "compressor-threshold", "label": qsTr("Threshold"), "unit": qsTr("dB"), "min": -30, "max": 0, "step": 0.01 },
            { "option": "compressor-ratio", "label": qsTr("Ratio"), "unit": ":1", "min": 1, "max": 20, "step": 0.01 },
            { "option": "compressor-knee", "label": qsTr("Knee radius"), "unit": qsTr("dB"), "min": 1, "max": 10, "step": 0.01 },
            { "option": "compressor-makeup-gain", "label": qsTr("Makeup gain"), "unit": qsTr("dB"), "min": 0, "max": 24, "step": 0.01 } ] },
        { "module": "expander", "title": qsTr("Expander"), "controls": [
            { "option": "expander-rms-peak", "label": qsTr("RMS/peak"), "unit": "", "min": 0, "max": 1, "step": 0.001 },
            { "option": "expander-attack", "label": qsTr("Attack"), "unit": qsTr("ms"), "min": 1.5, "max": 400, "step": 0.1 },
            { "option": "expander-release", "label": qsTr("Release"), "unit": qsTr("ms"), "min": 2, "max": 800, "step": 0.1 },
            { "option": "expander-threshold", "label": qsTr("Threshold"), "unit": qsTr("dB"), "min": -60, "max": 0, "step": 0.01 },
            { "option": "expander-ratio", "label": qsTr("Ratio"), "unit": ":1", "min": 1, "max": 20, "step": 0.01 },
            { "option": "expander-knee", "label": qsTr("Knee radius"), "unit": qsTr("dB"), "min": 1, "max": 10, "step": 0.01 },
            { "option": "expander-makeup-gain", "label": qsTr("Makeup gain"), "unit": qsTr("dB"), "min": 0, "max": 24, "step": 0.01 } ] },
        { "module": "limiter", "title": qsTr("Limiter"), "controls": [
            { "option": "limiter-rms-peak", "label": qsTr("RMS/peak"), "unit": "", "min": 0, "max": 1, "step": 0.001 },
            { "option": "limiter-attack", "label": qsTr("Attack"), "unit": qsTr("ms"), "min": 1.5, "max": 400, "step": 0.1 },
            { "option": "limiter-release", "label": qsTr("Release"), "unit": qsTr("ms"), "min": 2, "max": 800, "step": 0.1 },
            { "option": "limiter-threshold", "label": qsTr("Threshold"), "unit": qsTr("dB"), "min": -60, "max": 0, "step": 0.01 },
            { "option": "limiter-ratio", "label": qsTr("Ratio"), "unit": ":1", "min": 1, "max": 20, "step": 0.01 },
            { "option": "limiter-knee", "label": qsTr("Knee radius"), "unit": qsTr("dB"), "min": 1, "max": 10, "step": 0.01 },
            { "option": "limiter-makeup-gain", "label": qsTr("Makeup gain"), "unit": qsTr("dB"), "min": 0, "max": 24, "step": 0.01 } ] },
        { "module": "spatializer", "title": qsTr("Spatializer"), "controls": [
            { "option": "spatializer-roomsize", "label": qsTr("Size"), "unit": "", "min": 0, "max": 1.1, "step": 0.1 },
            { "option": "spatializer-width", "label": qsTr("Width"), "unit": "", "min": 0, "max": 1, "step": 0.1 },
            { "option": "spatializer-wet", "label": qsTr("Wet"), "unit": "", "min": 0, "max": 1, "step": 0.1 },
            { "option": "spatializer-dry", "label": qsTr("Dry"), "unit": "", "min": 0, "max": 1, "step": 0.1 },
            { "option": "spatializer-damp", "label": qsTr("Damp"), "unit": "", "min": 0, "max": 1, "step": 0.1 } ] },
        { "module": "stereo_widen", "title": qsTr("Stereo Widener"), "controls": [
            { "option": "stereowiden-delay", "label": qsTr("Delay time"), "unit": "ms", "min": 1, "max": 100, "step": 1 },
            { "option": "stereowiden-feedback", "label": qsTr("Feedback gain"), "unit": "%", "min": 0, "max": 0.9, "step": 0.1 },
            { "option": "stereowiden-crossfeed", "label": qsTr("Crossfeed"), "unit": "%", "min": 0, "max": 0.8, "step": 0.1 },
            { "option": "stereowiden-dry-mix", "label": qsTr("Dry mix"), "unit": "%", "min": 0, "max": 1, "step": 0.1 } ] }
    ]

    readonly property var advancedAudioPanels: [
        { "module": "scaletempo_pitch", "title": qsTr("Pitch Shifter"), "controls": [
            { "option": "pitch-shift", "label": qsTr("Adjust pitch"), "unit": qsTr("semitones"), "min": -12, "max": 12, "step": 0.25 } ] },
        { "module": "stereo_pan", "title": qsTr("Stereo Panner"), "controls": [
            { "option": "pan-control", "label": qsTr("Adjust pan"), "unit": "", "min": 0, "max": 1, "step": 0.1 } ] }
    ]

    // ExtVideo: the filter (module) and its options. kind: slider (min / max
    // of the classic slider; float options are divided by `scale`), spin,
    // check, combo (choices of the option), color (hex), text, file
    readonly property var videoSections: [
        { "title": qsTr("Essential"), "filters": [
            { "module": "adjust", "title": qsTr("Image adjust"), "options": [
                { "option": "hue", "label": qsTr("Hue"), "kind": "slider", "min": -180, "max": 180, "scale": 1 },
                { "option": "brightness", "label": qsTr("Brightness"), "kind": "slider", "min": 0, "max": 200, "scale": 100 },
                { "option": "brightness-threshold", "label": qsTr("Brightness Threshold"), "kind": "check" },
                { "option": "contrast", "label": qsTr("Contrast"), "kind": "slider", "min": 0, "max": 200, "scale": 100 },
                { "option": "saturation", "label": qsTr("Saturation"), "kind": "slider", "min": 0, "max": 300, "scale": 100 },
                { "option": "gamma", "label": qsTr("Gamma"), "kind": "slider", "min": 0, "max": 1000, "scale": 100 } ] },
            { "module": "sharpen", "title": qsTr("Sharpen"), "options": [
                { "option": "sharpen-sigma", "label": qsTr("Sigma"), "kind": "slider", "min": 0, "max": 200, "scale": 50 } ] },
            { "module": "gradfun", "title": qsTr("Banding removal"), "options": [
                { "option": "gradfun-radius", "label": qsTr("Radius"), "kind": "slider", "min": 4, "max": 32, "scale": 4 } ] },
            { "module": "grain", "title": qsTr("Film Grain"), "options": [
                { "option": "grain-variance", "label": qsTr("Variance"), "kind": "slider", "min": 0, "max": 40, "scale": 4 } ] } ] },
        { "title": qsTr("Crop"), "crop": true, "filters": [] },
        { "title": qsTr("Colors"), "filters": [
            { "module": "extract", "title": qsTr("Color extraction"), "options": [
                { "option": "extract-component", "label": qsTr("Color"), "kind": "color" } ] },
            { "module": "invert", "title": qsTr("Negate colors"), "options": [] },
            { "module": "posterize", "title": qsTr("Posterize"), "options": [] },
            { "module": "gradient", "title": qsTr("Gradient"), "options": [
                { "option": "gradient-mode", "label": qsTr("Mode"), "kind": "combo" },
                { "option": "gradient-color", "label": qsTr("Color"), "kind": "check" },
                { "option": "gradient-cartoon", "label": qsTr("Cartoon"), "kind": "check" } ] },
            { "module": "colorthres", "title": qsTr("Color threshold"), "options": [
                { "option": "colorthres-color", "label": qsTr("Color"), "kind": "color" },
                { "option": "colorthres-saturationthres", "label": qsTr("Saturation"), "kind": "slider", "min": 0, "max": 99, "scale": 1 },
                { "option": "colorthres-similaritythres", "label": qsTr("Similarity"), "kind": "slider", "min": 0, "max": 99, "scale": 1 } ] },
            { "module": "sepia", "title": qsTr("Sepia"), "options": [
                { "option": "sepia-intensity", "label": qsTr("Intensity"), "kind": "spin", "min": 0, "max": 255 } ] } ] },
        { "title": qsTr("Geometry"), "filters": [
            { "module": "magnify", "title": qsTr("Interactive Zoom"), "options": [] },
            { "module": "wall", "title": qsTr("Wall"), "options": [
                { "option": "wall-rows", "label": qsTr("Rows"), "kind": "spin", "min": 1, "max": 99 },
                { "option": "wall-cols", "label": qsTr("Columns"), "kind": "spin", "min": 1, "max": 99 } ] },
            { "module": "transform", "title": qsTr("Transform"), "options": [
                { "option": "transform-type", "label": qsTr("Type"), "kind": "combo" } ] },
            { "module": "rotate", "title": qsTr("Rotate"), "options": [
                { "option": "rotate-angle", "label": qsTr("Angle"), "kind": "slider", "min": 0, "max": 359, "scale": 1 } ] },
            { "module": "puzzle", "title": qsTr("Puzzle game"), "options": [
                { "option": "puzzle-rows", "label": qsTr("Rows"), "kind": "spin", "min": 2, "max": 42 },
                { "option": "puzzle-cols", "label": qsTr("Columns"), "kind": "spin", "min": 2, "max": 42 } ] } ] },
        { "title": qsTr("Overlay"), "filters": [
            { "module": "logo", "title": qsTr("Add logo"), "options": [
                { "option": "logo-file", "label": qsTr("Logo"), "kind": "file", "browse": qsTr("Logo filenames") },
                { "option": "logo-y", "label": qsTr("Top"), "kind": "spin", "min": 0, "max": 4096, "unit": "px" },
                { "option": "logo-x", "label": qsTr("Left"), "kind": "spin", "min": 0, "max": 4096, "unit": "px" },
                { "option": "logo-opacity", "label": qsTr("Opacity"), "kind": "slider", "min": 0, "max": 255, "scale": 32 } ] },
            { "module": "marq", "title": qsTr("Add text"), "options": [
                { "option": "marq-marquee", "label": qsTr("Text"), "kind": "text" },
                { "option": "marq-position", "label": qsTr("Position"), "kind": "combo" } ] },
            { "module": "erase", "title": qsTr("Logo erase"), "options": [
                { "option": "erase-mask", "label": qsTr("Mask"), "kind": "file", "browse": qsTr("Image mask") },
                { "option": "erase-y", "label": qsTr("Top"), "kind": "spin", "min": 0, "max": 4096, "unit": "px" },
                { "option": "erase-x", "label": qsTr("Left"), "kind": "spin", "min": 0, "max": 4096, "unit": "px" } ] } ] },
        { "title": qsTr("Advanced"), "filters": [
            { "module": "anaglyph", "title": qsTr("Anaglyph 3D"), "options": [] },
            { "module": "mirror", "title": qsTr("Mirror"), "options": [] },
            { "module": "psychedelic", "title": qsTr("Psychedelic"), "options": [] },
            { "module": "wave", "title": qsTr("Waves"), "options": [] },
            { "module": "ripple", "title": qsTr("Water effect"), "options": [] },
            { "module": "motiondetect", "title": qsTr("Motion detect"), "options": [] },
            { "module": "gaussianblur", "title": qsTr("Spatial blur"), "options": [
                { "option": "gaussianblur-sigma", "label": qsTr("Sigma"), "kind": "slider", "min": 1, "max": 127, "scale": 16 } ] },
            { "module": "motionblur", "title": qsTr("Motion blur"), "options": [
                { "option": "blur-factor", "label": qsTr("Factor"), "kind": "slider", "min": 1, "max": 127, "scale": 16 } ] },
            { "module": "antiflicker", "title": qsTr("Anti-Flickering"), "options": [
                { "option": "antiflicker-softening-size", "label": qsTr("Soften"), "kind": "slider", "min": 0, "max": 100, "scale": 16 } ] },
            { "module": "hqdn3d", "title": qsTr("Denoiser"), "options": [
                { "option": "hqdn3d-luma-spat", "label": qsTr("Spatial luma strength"), "kind": "slider", "min": 1, "max": 127, "scale": 16 },
                { "option": "hqdn3d-luma-temp", "label": qsTr("Temporal luma strength"), "kind": "slider", "min": 1, "max": 127, "scale": 16 },
                { "option": "hqdn3d-chroma-spat", "label": qsTr("Spatial chroma strength"), "kind": "slider", "min": 1, "max": 127, "scale": 16 },
                { "option": "hqdn3d-chroma-temp", "label": qsTr("Temporal chroma strength"), "kind": "slider", "min": 1, "max": 127, "scale": 16 } ] },
            { "module": "clone", "title": qsTr("Clone"), "options": [
                { "option": "clone-count", "label": qsTr("Number of clones"), "kind": "spin", "min": 1, "max": 99 } ] } ] }
    ]

    readonly property var audioSections: [qsTr("Equalizer")].concat(audioPanels.map((p) => p.title)).concat([qsTr("Advanced")])

    property int audioSection: 0
    property int videoSection: 0

    // ---- components ---------------------------------------------------------------

    // the sections of a page, as buttons (the classic inner tabs)
    component SectionBar: Flow {
        id: bar

        property var sections: []
        property int current: 0
        signal picked(int index)

        Layout.fillWidth: true
        Layout.bottomMargin: VLCStyle.margin_small
        spacing: VLCStyle.margin_xxsmall

        Repeater {
            model: bar.sections
            WinButton {
                required property var modelData
                required property int index
                implicitWidth: Math.max(VLCStyle.dp(80, VLCStyle.scale), contentItem.implicitWidth + VLCStyle.dp(24, VLCStyle.scale))
                text: modelData
                checked: bar.current === index
                onClicked: bar.picked(index)
            }
        }
    }

    // the design of the player's side panel (PlayerSettingsPanel.qml): the
    // settings of an effect in a well card, each slider under its name and value
    component EffectCard: Rectangle {
        default property alias cardContent: cardColumn.data

        Layout.fillWidth: true
        Layout.bottomMargin: VLCStyle.margin_normal
        implicitHeight: cardColumn.implicitHeight + 2 * VLCStyle.dp(16, VLCStyle.scale)
        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: WinStyle.well
        opacity: enabled ? 1.0 : 0.5

        ColumnLayout {
            id: cardColumn
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: VLCStyle.dp(16, VLCStyle.scale) }
            spacing: VLCStyle.dp(20, VLCStyle.scale)
        }
    }

    component EffectSlider: ColumnLayout {
        id: effectSlider

        property string label
        property alias from: slider.from
        property alias to: slider.to
        property alias stepSize: slider.stepSize
        property alias value: slider.value
        property var format: (v) => (Math.round(v * 100) / 100).toString()
        signal moved(real value)

        Layout.fillWidth: true
        spacing: VLCStyle.dp(14, VLCStyle.scale)

        RowLayout {
            Layout.fillWidth: true
            T.Label {
                Layout.fillWidth: true
                text: effectSlider.label
                color: WinStyle.text
                font.pixelSize: VLCStyle.fontSize_normal
                elide: Text.ElideRight
            }
            T.Label {
                text: effectSlider.format(slider.value)
                color: WinStyle.text
                font.pixelSize: VLCStyle.fontSize_normal
            }
        }
        WinSlider {
            id: slider
            Layout.fillWidth: true
            opacity: 1.0
            format: effectSlider.format
            Accessible.name: effectSlider.label
            onMoved: effectSlider.moved(value)
        }
    }

    // an audio filter: name + ON/OFF, then its card (AudioFilterControlWidget)
    component AudioPanel: ColumnLayout {
        id: panel

        property var panelData

        readonly property bool on: root.revision >= 0 && VLCEffects.audioFilterEnabled(panelData.module)

        Layout.fillWidth: true
        spacing: VLCStyle.dp(8, VLCStyle.scale)

        WinRow {
            label: panel.panelData.title
            WinToggle {
                checked: panel.on
                onToggled: VLCEffects.setAudioFilterEnabled(panel.panelData.module, checked)
            }
        }

        EffectCard {
          enabled: panel.on

          Repeater {
            model: panel.panelData.controls

            EffectSlider {
                required property var modelData

                label: modelData.label
                from: modelData.min
                to: modelData.max
                stepSize: modelData.step
                format: (v) => {
                    const decimals = modelData.step < 0.01 ? 3 : (modelData.step < 0.1 ? 2 : (modelData.step < 1 ? 1 : 0))
                    return Number(v).toFixed(decimals) + (modelData.unit !== "" ? " " + modelData.unit : "")
                }
                value: root.revision >= 0 ? Number(VLCEffects.audioValue(modelData.option)) : 0
                onMoved: (v) => VLCEffects.setAudioValue(modelData.option, v)
            }
          }
        }
    }

    // a video filter: enable + its options (ExtVideo)
    component VideoFilter: ColumnLayout {
        id: filter

        property var panelData

        readonly property bool on: root.revision >= 0 && VLCEffects.videoFilterEnabled(panelData.module)

        Layout.fillWidth: true
        spacing: VLCStyle.dp(8, VLCStyle.scale)

        WinRow {
            label: filter.panelData.title
            WinToggle {
                checked: filter.on
                onToggled: VLCEffects.setVideoFilterEnabled(filter.panelData.module, checked)
            }
        }

        EffectCard {
          visible: filter.panelData.options.length > 0
          enabled: filter.on

          Repeater {
            model: filter.panelData.options

            Loader {
                id: optionLoader

                required property var modelData

                Layout.fillWidth: true

                readonly property bool isFloat: VLCConfig.type(modelData.option) === "float"
                readonly property var current: root.revision >= 0 ? VLCEffects.videoValue(modelData.option) : undefined

                function write(value) {
                    VLCEffects.setVideoValue(modelData.option, value)
                }

                sourceComponent: ({
                    "slider": sliderOption, "spin": spinOption, "check": checkOption, "combo": comboOption,
                    "color": colorOption, "text": textOption, "file": fileOption
                })[modelData.kind]

                Component {
                    id: sliderOption
                    EffectSlider {
                        readonly property real sliderScale: optionLoader.isFloat ? optionLoader.modelData.scale : 1
                        label: optionLoader.modelData.label
                        from: optionLoader.modelData.min / sliderScale
                        to: optionLoader.modelData.max / sliderScale
                        stepSize: 1 / sliderScale
                        format: (v) => optionLoader.isFloat ? Number(v).toFixed(sliderScale >= 10 ? 2 : 1) : String(Math.round(v))
                        value: Number(optionLoader.current ?? 0)
                        onMoved: (v) => optionLoader.write(optionLoader.isFloat ? v : Math.round(v))
                    }
                }
                Component {
                    id: spinOption
                    WinRow {
                        label: optionLoader.modelData.label
                        WinNumberField {
                            from: optionLoader.modelData.min
                            to: optionLoader.modelData.max
                            unit: optionLoader.modelData.unit ?? ""
                            value: Number(optionLoader.current ?? 0)
                            onEdited: (v) => optionLoader.write(v)
                        }
                    }
                }
                Component {
                    id: checkOption
                    WinRow {
                        label: optionLoader.modelData.label
                        WinToggle {
                            checked: !!optionLoader.current
                            onToggled: optionLoader.write(checked)
                        }
                    }
                }
                Component {
                    id: comboOption
                    WinRow {
                        label: optionLoader.modelData.label
                        WinDropdown {
                            model: VLCConfig.choices(optionLoader.modelData.option)
                            value: optionLoader.current
                            onPicked: (v) => optionLoader.write(v)
                        }
                    }
                }
                Component {
                    id: colorOption
                    WinRow {
                        label: optionLoader.modelData.label
                        Rectangle {
                            implicitWidth: VLCStyle.dp(28, VLCStyle.scale)
                            implicitHeight: implicitWidth
                            radius: VLCStyle.dp(4, VLCStyle.scale)
                            color: "#" + colorField.text.padStart(6, "0")
                            border.width: 1
                            border.color: WinStyle.border
                        }
                        // as the classic hex field (>HHHHHH)
                        WinField {
                            id: colorField
                            implicitWidth: VLCStyle.dp(120, VLCStyle.scale)
                            font.family: "monospace"
                            maximumLength: 6
                            validator: RegularExpressionValidator { regularExpression: /[0-9A-Fa-f]{0,6}/ }
                            text: Number(optionLoader.current ?? 0).toString(16).toUpperCase().padStart(6, "0")
                            onTextEdited: optionLoader.write(parseInt(text === "" ? "0" : text, 16))
                        }
                    }
                }
                Component {
                    id: textOption
                    WinRow {
                        label: optionLoader.modelData.label
                        WinField {
                            text: String(optionLoader.current ?? "")
                            onTextEdited: optionLoader.write(text)
                        }
                    }
                }
                Component {
                    id: fileOption
                    WinRow {
                        label: optionLoader.modelData.label
                        WinField {
                            id: fileField
                            implicitWidth: WinStyle.controlWidth - VLCStyle.dp(100, VLCStyle.scale) - VLCStyle.margin_xsmall
                            text: String(optionLoader.current ?? "")
                            onEditingFinished: optionLoader.write(text)
                        }
                        WinButton {
                            text: qsTr("Browse")
                            onClicked: {
                                const list = VLCConfig.browseFiles(optionLoader.modelData.browse,
                                                                   qsTr("Image Files") + " (*.png *.jpg);;" + qsTr("All") + " (*)")
                                if (list.length > 0) {
                                    const url = list[0].toString()
                                    fileField.text = decodeURIComponent(url.replace(/^file:\/\/(\/(?=[A-Za-z]:))?/, ""))
                                    optionLoader.write(fileField.text)
                                }
                            }
                        }
                    }
                }
            }
          }
        }
    }

    // ---- pages -------------------------------------------------------------------------

    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        currentIndex: root.currentTab

        // Audio Effects
        ColumnLayout {
            spacing: 0

            SectionBar {
                sections: root.audioSections
                current: root.audioSection
                onPicked: (i) => root.audioSection = i
            }

            Flickable {
                id: audioFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: audioColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                T.ScrollBar.vertical: WinScrollBar { }

                ColumnLayout {
                    id: audioColumn
                    width: audioFlick.width - VLCStyle.margin_small
                    spacing: 0

                    // Equalizer, as the side panel: preset, Preamp and the 10 bands in a card, 2 Pass
                    ColumnLayout {
                        id: equalizer

                        visible: root.audioSection === 0
                        Layout.fillWidth: true
                        spacing: VLCStyle.dp(8, VLCStyle.scale)

                        readonly property bool on: root.revision >= 0 && VLCEffects.audioFilterEnabled("equalizer")
                        readonly property var bands: root.revision >= 0 ? VLCEffects.equalizerBands() : []
                        readonly property var labels: ["60 Hz", "170 Hz", "310 Hz", "600 Hz", "1 KHz",
                                                       "3 KHz", "6 KHz", "12 KHz", "14 KHz", "16 KHz"]

                        function dB(v) { return Number(v).toFixed(1) + " dB" }

                        WinRow {
                            label: qsTr("Equalizer")
                            WinToggle {
                                checked: equalizer.on
                                onToggled: VLCEffects.setAudioFilterEnabled("equalizer", checked)
                            }
                        }
                        WinRow {
                            enabled: equalizer.on
                            label: qsTr("Preset")
                            WinDropdown {
                                // first entry: custom / modified, as the classic list
                                model: [{ "value": "", "text": "" }].concat(
                                           VLCEffects.equalizerPresets().map((p) => ({ "value": p.name, "text": p.text })))
                                value: root.revision >= 0 ? String(VLCEffects.audioValue("equalizer-preset") ?? "") : ""
                                onPicked: (v) => { if (v !== "") VLCEffects.applyEqualizerPreset(v) }
                            }
                        }

                        EffectCard {
                            enabled: equalizer.on

                            EffectSlider {
                                label: qsTr("Preamp")
                                from: -20; to: 20; stepSize: 0.1
                                format: equalizer.dB
                                value: root.revision >= 0 ? Number(VLCEffects.audioValue("equalizer-preamp")) || 0 : 0
                                onMoved: (v) => VLCEffects.setAudioValue("equalizer-preamp", Math.round(v * 10) / 10)
                            }
                            Repeater {
                                model: 10
                                EffectSlider {
                                    required property int index
                                    label: equalizer.labels[index]
                                    from: -20; to: 20; stepSize: 0.1
                                    format: equalizer.dB
                                    value: Number(equalizer.bands[index] ?? 0)
                                    onMoved: (v) => VLCEffects.setEqualizerBand(index, Math.round(v * 10) / 10)
                                }
                            }
                        }

                        WinRow {
                            enabled: equalizer.on
                            label: qsTr("2 Pass")
                            description: qsTr("Filter the audio twice. This provides a more intense effect.")
                            WinToggle {
                                checked: root.revision >= 0 && !!VLCEffects.audioValue("equalizer-2pass")
                                onToggled: VLCEffects.setAudioValue("equalizer-2pass", checked)
                            }
                        }
                    }

                    // Compressor ... Stereo Widener
                    Repeater {
                        model: root.audioPanels
                        AudioPanel {
                            required property var modelData
                            required property int index
                            panelData: modelData
                            visible: root.audioSection === index + 1
                        }
                    }

                    // Advanced: pitch and pan
                    Repeater {
                        model: root.advancedAudioPanels
                        AudioPanel {
                            required property var modelData
                            panelData: modelData
                            visible: root.audioSection === root.audioSections.length - 1
                            Layout.bottomMargin: VLCStyle.margin_small
                        }
                    }
                }
            }
        }

        // Video Effects
        ColumnLayout {
            spacing: 0

            SectionBar {
                sections: root.videoSections.map((s) => s.title)
                current: root.videoSection
                onPicked: (i) => root.videoSection = i
            }

            Flickable {
                id: videoFlick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: videoColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                T.ScrollBar.vertical: WinScrollBar { }

                ColumnLayout {
                    id: videoColumn
                    width: videoFlick.width - VLCStyle.margin_small
                    spacing: 0

                    Repeater {
                        model: root.videoSections[root.videoSection].filters
                        VideoFilter {
                            required property var modelData
                            panelData: modelData
                        }
                    }

                    // Crop (pixels of the current video, not kept)
                    ColumnLayout {
                        id: cropPage

                        visible: root.videoSections[root.videoSection].crop === true
                        Layout.fillWidth: true
                        spacing: 0

                        function apply() {
                            if (topBottomSync.checked) cropBottom.value = cropTop.value
                            if (leftRightSync.checked) cropRight.value = cropLeft.value
                            VLCEffects.setCrop(cropTop.value, cropBottom.value, cropLeft.value, cropRight.value)
                        }

                        WinRow {
                            label: qsTr("Top")
                            WinNumberField { id: cropTop; from: 0; to: 4095; unit: "px"; buttons: true; onEdited: cropPage.apply() }
                        }
                        WinRow {
                            label: qsTr("Bottom")
                            enabled: !topBottomSync.checked
                            WinNumberField { id: cropBottom; from: 0; to: 4095; unit: "px"; buttons: true; onEdited: cropPage.apply() }
                        }
                        WinRow {
                            label: qsTr("Synchronize top and bottom")
                            WinToggle { id: topBottomSync; onToggled: cropPage.apply() }
                        }
                        WinRow {
                            label: qsTr("Left")
                            WinNumberField { id: cropLeft; from: 0; to: 4095; unit: "px"; buttons: true; onEdited: cropPage.apply() }
                        }
                        WinRow {
                            label: qsTr("Right")
                            enabled: !leftRightSync.checked
                            WinNumberField { id: cropRight; from: 0; to: 4095; unit: "px"; buttons: true; onEdited: cropPage.apply() }
                        }
                        WinRow {
                            label: qsTr("Synchronize left and right")
                            WinToggle { id: leftRightSync; onToggled: cropPage.apply() }
                        }
                    }
                }
            }
        }

        // Synchronization
        Flickable {
            id: syncFlick
            clip: true
            contentHeight: syncColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollBar.vertical: WinScrollBar { }

            ColumnLayout {
                id: syncColumn
                width: syncFlick.width - VLCStyle.margin_small
                spacing: 0

                readonly property bool hasInput: Player.isStarted
                readonly property int subsdelayMode: Number(VLCConfig.value("subsdelay-mode") ?? 0)

                function hint(seconds) {
                    return seconds < 0 ? qsTr("(Hastened)") : (seconds > 0 ? qsTr("(Delayed)") : "")
                }

                WinSectionTitle { text: qsTr("Audio/Video") }

                WinRow {
                    label: qsTr("Audio track synchronization:")
                    enabled: syncColumn.hasInput
                    WinLabel { text: syncColumn.hint(audioDelay.value); color: WinStyle.mutedText }
                    WinNumberField {
                        id: audioDelay
                        from: -600; to: 600; decimals: 3; step: 0.1; unit: "s"; buttons: true
                        value: Player.audioDelayMS / 1000
                        onEdited: (v) => Player.audioDelayMS = Math.round(v * 1000)
                    }
                }

                WinSectionTitle { text: qsTr("Subtitles/Video") }

                WinRow {
                    label: qsTr("Primary subtitle track:")
                    enabled: syncColumn.hasInput
                    WinLabel { text: syncColumn.hint(subDelay.value); color: WinStyle.mutedText }
                    WinNumberField {
                        id: subDelay
                        from: -600; to: 600; decimals: 3; step: 0.1; unit: "s"; buttons: true
                        value: Player.subtitleDelayMS / 1000
                        onEdited: (v) => Player.subtitleDelayMS = Math.round(v * 1000)
                    }
                }
                WinRow {
                    label: qsTr("Secondary subtitle track:")
                    enabled: syncColumn.hasInput
                    WinLabel { text: syncColumn.hint(secondaryDelay.value); color: WinStyle.mutedText }
                    WinNumberField {
                        id: secondaryDelay
                        from: -600; to: 600; decimals: 3; step: 0.1; unit: "s"; buttons: true
                        value: Player.secondarySubtitleDelayMS / 1000
                        onEdited: (v) => Player.secondarySubtitleDelayMS = Math.round(v * 1000)
                    }
                }
                WinRow {
                    label: qsTr("Subtitle speed:")
                    enabled: syncColumn.hasInput
                    WinNumberField {
                        from: 1; to: 100; decimals: 3; step: 0.2; unit: "fps"; buttons: true
                        value: Player.subtitleFPS
                        onEdited: (v) => Player.subtitleFPS = v
                    }
                }
                WinRow {
                    label: qsTr("Subtitle duration factor:")
                    description: [qsTr("Extend subtitle duration by this value.\nSet 0 to disable."),
                                  qsTr("Multiply subtitle duration by this value.\nSet 0 to disable."),
                                  qsTr("Recalculate subtitle duration according\nto their content and this value.\nSet 0 to disable.")][syncColumn.subsdelayMode] ?? ""
                    enabled: syncColumn.hasInput
                    WinNumberField {
                        from: 0; to: 20; decimals: 3; step: 0.2; buttons: true
                        unit: syncColumn.subsdelayMode === 0 ? "s" : ""
                        value: root.revision >= 0 ? Number(VLCEffects.videoValue("subsdelay-factor") ?? 0) : 0
                        onEdited: (v) => {
                            VLCEffects.setVideoValue("subsdelay-factor", v)
                            VLCEffects.setVideoFilterEnabled("subsdelay", v > 0)
                        }
                    }
                }
            }
        }

        // v4l2 controls
        Flickable {
            id: v4l2Flick
            clip: true
            contentHeight: v4l2Column.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            T.ScrollBar.vertical: WinScrollBar { }

            property var v4l2State: ({ "found": false, "controls": [] })

            function refresh() {
                v4l2State = v4l2.read()
            }

            // looks again every 2 s while no device plays, as the classic tab
            Timer {
                interval: 2000
                repeat: true
                running: root.visible && root.currentTab === 3 && !v4l2Flick.v4l2State.found
                triggeredOnStart: true
                onTriggered: v4l2Flick.refresh()
            }

            ColumnLayout {
                id: v4l2Column
                width: v4l2Flick.width - VLCStyle.margin_small
                spacing: 0

                WinDescription {
                    visible: !v4l2Flick.v4l2State.found
                    Layout.topMargin: VLCStyle.margin_large
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: VLCStyle.fontSize_large
                    text: qsTr("No v4l2 instance found.\nPlease check that the device has been opened with VLC and is playing.\n\nControls will automatically appear here.")
                }

                Repeater {
                    model: v4l2Flick.v4l2State.controls

                    Loader {
                        id: control

                        required property var modelData
                        Layout.fillWidth: true

                        sourceComponent: ({ "int": v4l2Slider, "choice": v4l2Choice, "bool": v4l2Bool,
                                            "button": v4l2Button, "label": v4l2Label })[modelData.kind]

                        Component {
                            id: v4l2Slider
                            WinSliderRow {
                                label: control.modelData.text
                                from: control.modelData.min
                                to: control.modelData.max
                                stepSize: Math.max(1, control.modelData.step)
                                value: control.modelData.value
                                format: (v) => String(Math.round(v))
                                onMoved: (v) => v4l2.setValue(control.modelData.name, Math.round(v))
                            }
                        }
                        Component {
                            id: v4l2Choice
                            WinRow {
                                label: control.modelData.text
                                WinDropdown {
                                    model: control.modelData.choices
                                    value: control.modelData.value
                                    onPicked: (v) => v4l2.setValue(control.modelData.name, v)
                                }
                            }
                        }
                        Component {
                            id: v4l2Bool
                            WinRow {
                                label: control.modelData.text
                                WinToggle {
                                    checked: control.modelData.value
                                    onToggled: v4l2.setValue(control.modelData.name, checked)
                                }
                            }
                        }
                        Component {
                            id: v4l2Button
                            WinRow {
                                label: control.modelData.text
                                WinButton {
                                    text: control.modelData.text
                                    onClicked: v4l2.setValue(control.modelData.name, true)
                                }
                            }
                        }
                        Component {
                            id: v4l2Label
                            WinSectionTitle { text: control.modelData.text }
                        }
                    }
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
