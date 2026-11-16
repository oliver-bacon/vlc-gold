/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *
 * Authors: Oliver Bacon <oliverbacon@tutamail.com>
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

import VLC.Dialogs
import VLC.MainInterface
import VLC.Menus
import VLC.Player
import VLC.Style

// Player settings panel of the VLC Redesign Figma file (gear button of the
// player bar): Playback / Video / Audio / Subtitles tabs, with the audio
// effects (Equalizer, Compressor, Spatializer, Stereo Widener) and video
// effects (Essential, Crop, Colors) as expandable cards. Changes apply live
// and are kept for the next media.
PlayerSidePopup {
    id: root

    property int currentTab: 2 // Audio, as in the design

    // music: no Video and Subtitles tabs (as Player.qml's _audioOnly). The
    // chosen tab is kept, the Audio tab shows meanwhile.
    readonly property bool audioOnly: Player.audioTracks.count > 0 && Player.videoTracks.count === 0
    readonly property int shownTab: (audioOnly && (currentTab === 1 || currentTab === 3)) ? 2 : currentTab

    defaultHeight: Math.min(VLCStyle.dp(640, VLCStyle.scale), (parent?.Window.height ?? 800) - VLCStyle.dp(144, VLCStyle.scale)) // 120 + the gap above the bar
    padding: 0
    modal: false
    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent

    // Figma tokens (dark), light palette tokens otherwise
    readonly property bool dark: VLCStyle.palette?.isDark ?? true
    // Dark/BG/B1 at 95 %, tab bar Dark/BG/B2 (Figma player settings panel)
    readonly property color panelColor: dark ? Qt.rgba(14 / 255, 14 / 255, 14 / 255, 0.95) : "#E7E7E7"
    readonly property color tabsColor: dark ? "#090909" : "#DEDEDE"
    readonly property color cardColor: dark ? "#1F1F1F" : "#DEDEDE"
    readonly property color wellColor: dark ? "#090909" : "#F4F4F4"
    readonly property color wellHoverColor: dark ? "#0E0E0E" : "#FAFAFA"
    // text box ring, dropdown fill (Dark/BG/A4); open card (Dark/BG/A3)
    readonly property color ringColor: dark ? "#191919" : "#DEDEDE"
    readonly property color openCardColor: dark ? "#1B1B1B" : "#DEDEDE"
    // value boxes of the design: 138 x 34 with a 2 px ring
    readonly property real fieldWidth: 140 * root.dp1
    readonly property real fieldHeight: 36 * root.dp1
    readonly property color dividerColor: dark ? "#222222" : "#ACACAC"
    readonly property color titleColor: dark ? "#C6C6C6" : "#161616"
    // section titles of the Figma panel (16 px #969696)
    readonly property color sectionColor: dark ? "#969696" : "#2E2E2E"
    readonly property color textColor: dark ? "#8F8F8F" : "#2E2E2E"
    readonly property color dimColor: "#6B6B6B"
    readonly property color faintColor: dark ? "#404040" : "#9B9B9B"
    readonly property color tickColor: dark ? "#1A1611" : "#C8C8C8"
    readonly property color accentColor: VLCStyle.palette.orange500
    // tab icons: grey part and accent details (Figma Dark/FG/A2, Dark/Accent/Dim)
    readonly property color iconColor: dark ? "#8F8F8F" : "#2E2E2E"
    readonly property color accentDimColor: VLCStyle.palette.accentDim
    readonly property color accentSurface: dark ? VLCStyle.palette.accentBrightDark : VLCStyle.palette.accentBrightLight
    readonly property real dp1: VLCStyle.dp(1, VLCStyle.scale)

    background: Rectangle {
        radius: 10 * root.dp1
        color: root.panelColor
    }

    contentItem: ColumnLayout {
        spacing: 0

        // tabs
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50 * root.dp1
            color: root.tabsColor
            radius: 10 * root.dp1

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: parent.radius
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10 * root.dp1
                anchors.rightMargin: 10 * root.dp1
                spacing: 0

                Repeater {
                    model: [
                        { "text": qsTr("Playback"), "glyph": VLCIcons.playback_tab, "sel": VLCIcons.playback_tab_sel, "selAccent": VLCIcons.playback_tab_sel_accent },
                        { "text": qsTr("Video"), "glyph": VLCIcons.video, "sel": VLCIcons.video_sel, "selAccent": VLCIcons.video_sel_accent },
                        { "text": qsTr("Audio"), "glyph": VLCIcons.visualization, "sel": VLCIcons.visualization_sel, "selAccent": VLCIcons.visualization_sel_accent },
                        { "text": qsTr("Subtitles"), "glyph": VLCIcons.audiosub, "sel": VLCIcons.audiosub_sel, "selAccent": VLCIcons.audiosub_sel_accent }
                    ]

                    delegate: T.TabButton {
                        id: tab

                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: !root.audioOnly || index === 0 || index === 2
                        checked: root.shownTab === index
                        onClicked: root.currentTab = index

                        background: Rectangle {
                            color: "transparent"
                            Rectangle {
                                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 4 * root.dp1; rightMargin: 4 * root.dp1 }
                                height: 2 * root.dp1
                                visible: tab.checked
                                color: root.accentColor
                            }
                        }
                        contentItem: Row {
                            spacing: 6 * root.dp1
                            leftPadding: Math.max(0, (tab.width - implicitWidth) / 2)
                            // Figma: the selected tab icon is two-tone, grey with its details in the dim accent
                            Item {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: tabIcon.implicitWidth
                                implicitHeight: tabIcon.implicitHeight
                                width: implicitWidth
                                height: implicitHeight
                                Text {
                                    id: tabIcon
                                    font.family: VLCIcons.fontFamily
                                    font.pixelSize: 15 * root.dp1
                                    text: tab.checked ? tab.modelData.sel : tab.modelData.glyph
                                    color: tab.checked ? root.iconColor : root.dimColor
                                }
                                Text {
                                    visible: tab.checked
                                    font.family: VLCIcons.fontFamily
                                    font.pixelSize: 15 * root.dp1
                                    text: tab.modelData.selAccent
                                    color: root.accentDimColor
                                }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tab.modelData.text
                                font.pixelSize: 12 * root.dp1
                                color: tab.checked ? root.textColor : root.dimColor
                            }
                        }
                    }
                }
            }
        }

        // pages
        Flickable {
            id: flick

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: pageColumn.implicitHeight + 14 * root.dp1
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: pageColumn

                x: 20 * root.dp1
                width: flick.width - 40 * root.dp1
                spacing: 0

                StackLayout {
                    id: pages

                    Layout.fillWidth: true
                    currentIndex: root.shownTab
                    Layout.preferredHeight: children[currentIndex]?.implicitHeight ?? 0

                    Loader { active: root.pagesActive; sourceComponent: Component { PlaybackPage {} } }
                    Loader { active: root.pagesActive; sourceComponent: Component { VideoPage {} } }
                    Loader { active: root.pagesActive; sourceComponent: Component { AudioPage {} } }
                    Loader { active: root.pagesActive; sourceComponent: Component { SubtitlesPage {} } }
                }

                // at the end of the page: resets the open tab
                FooterButton {
                    Layout.topMargin: 20 * root.dp1
                    Layout.leftMargin: 0
                    Layout.rightMargin: 0
                    flat: true
                    glyph: VLCIcons.history
                    text: qsTr("Restore Defaults")
                    onClicked: root.restoreDefaults(root.shownTab)
                }
            }
        }

        // footer
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.dividerColor
        }

        PresetBar {
            id: presetBar
            Layout.fillWidth: true
            Layout.leftMargin: 20 * root.dp1
            Layout.rightMargin: 20 * root.dp1
            Layout.topMargin: 14 * root.dp1
        }

        FooterButton {
            Layout.topMargin: 8 * root.dp1
            Layout.bottomMargin: 14 * root.dp1
            flat: true
            glyph: VLCIcons.settings
            text: qsTr("Open Advanced Settings")
            // the settings window on the page of the current tab
            onClicked: {
                const page = ["playback", "video", "audio", "subtitles"][root.shownTab] ?? "playback"
                root.close()
                DialogsProvider.settingsPageDialog(page)
            }
        }
    }

    // Figma "Button": full-width bar, Dark/BG/B2, Dark/BG/A4 on hover;
    // flat: icon and text only (Figma panel footer "Open Advanced Settings")
    component FooterButton: T.Button {
        id: footerButton
        property string glyph

        Layout.fillWidth: true
        Layout.leftMargin: 20 * root.dp1
        Layout.rightMargin: 20 * root.dp1
        implicitHeight: 32 * root.dp1
        background: Rectangle {
            radius: 4 * root.dp1
            visible: !footerButton.flat
            color: footerButton.hovered ? root.ringColor : root.wellColor
        }
        contentItem: Item {
            Row {
                anchors.centerIn: parent
                spacing: 8 * root.dp1
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: VLCIcons.fontFamily
                    font.pixelSize: 18 * root.dp1
                    text: footerButton.glyph
                    color: footerButton.hovered ? root.textColor : root.dimColor
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: footerButton.text
                    font.pixelSize: 14 * root.dp1
                    color: footerButton.hovered ? root.textColor : root.dimColor
                }
            }
        }
    }

    // ===================================================================
    // pages

    component PlaybackPage: Page {
        Row2 {
            label: qsTr("Reverse")
            visible: Player.ratechangable
            Switch {
                checked: Player.rate < 0
                onToggled: Player.reverse()
            }
        }
        Row2 {
            label: qsTr("Sleep Timer")
            SleepTimer { Layout.preferredWidth: 216 * root.dp1 }
        }
        Row2 {
            // Applies to the current playback only, like VLC's Audio >
            // Visualizations menu. The saved default is in Settings > Audio.
            label: qsTr("Audio Visualizer")
            visible: visualizerDropdown.count > 0
            VarChoiceDropdown {
                id: visualizerDropdown
                Layout.preferredWidth: 216 * root.dp1
                model: Player.audioVisualization
            }
        }
        Row2 {
            // VLC Redesign: subtitle lines on the seek bar (read by
            // SliderBar.qml); works with subtitle files, not embedded tracks
            label: qsTr("Show Subtitle Timeline on Seekbar")
            visible: !root.audioOnly
            Switch {
                checked: String(VLCConfig.uiValue("Player/SubtitleTimeline", false)) === "true"
                onToggled: VLCConfig.setUiValue("Player/SubtitleTimeline", checked)
            }
        }
        Row2 {
            // Figma Playback tab: the statistics of the playing media
            // (Statistics tab of the Media Information window)
            label: qsTr("Show Statistics")
            Switch {
                checked: DialogsProvider.statisticsVisible
                onToggled: {
                    DialogsProvider.mediaStatisticsDialog()
                    checked = Qt.binding(() => DialogsProvider.statisticsVisible)
                }
            }
        }
        Row2 {
            label: qsTr("Speed")
            ValueBox { text: (Math.round(Player.rate * 100) / 100) + "x" }
        }
        FxSlider {
            from: 0.25; to: 2; stepSize: 0.05
            tickLabels: ["0.25", "0.5", "0.75", "1", "1.25", "1.5", "1.75", "2"]
            value: Player.rate
            enabled: Player.ratechangable
            onMoved: Player.rate = value
        }
    }

    component VideoPage: Page {
        id: videoPage

        // flip and rotation of the picture (VLCEffects keeps them in the
        // transform / rotate filters, so they are saved like the filters)
        property var orientation: VLCEffects.orientation()
        function setOrientation(flip, angle) {
            VLCEffects.setOrientation(flip, angle)
            orientation = VLCEffects.orientation()
        }
        onVisibleChanged: if (visible) orientation = VLCEffects.orientation()

        SectionTitle { text: qsTr("Defaults") }

        Label2 { text: qsTr("Flip") }
        Segmented {
            id: flipChoice
            Layout.fillWidth: true
            options: [qsTr("None"), qsTr("Horizontal"), qsTr("Vertical")]
            current: videoPage.orientation.flip
            onChosen: (i) => videoPage.setOrientation(i, videoPage.orientation.angle)
        }
        Row2 {
            label: qsTr("Rotate")
            UnitBox {
                implicitWidth: root.fieldWidth
                Layout.fillWidth: false
                unit: qsTr("deg")
                maxValue: 359
                value: videoPage.orientation.angle
                onEdited: (v) => videoPage.setOrientation(videoPage.orientation.flip, v)
            }
        }
        // zoom, aspect ratio and crop of the current video (VLC's Video menu)
        Row2 {
            label: qsTr("Zoom")
            visible: zoomDropdown.count > 0
            VarChoiceDropdown { id: zoomDropdown; Layout.preferredWidth: 216 * root.dp1; model: Player.zoom }
        }
        // Direct3D11 only (Windows). The display reads it when it opens: the
        // video track is restarted, which opens the display again
        Row2 {
            label: qsTr("HDR")
            visible: VLCConfig.exists("d3d11-hdr-mode")
            Dropdown {
                Layout.preferredWidth: 216 * root.dp1
                option: "d3d11-hdr-mode"
                onPicked: Player.restartVideoTrack()
            }
        }
        // preferred resolution of adaptive streams (YouTube, DASH, HLS)
        Row2 {
            label: qsTr("Resolution")
            Dropdown { Layout.preferredWidth: 216 * root.dp1; option: "preferred-resolution" }
        }
        Row2 {
            label: qsTr("Aspect Ratio")
            visible: aspectDropdown.count > 0
            VarChoiceDropdown { id: aspectDropdown; Layout.preferredWidth: 216 * root.dp1; model: Player.aspectRatio }
        }
        Row2 {
            label: qsTr("Crop")
            visible: cropDropdown.count > 0
            VarChoiceDropdown { id: cropDropdown; Layout.preferredWidth: 216 * root.dp1; model: Player.crop }
        }
        // play here ("Local") or on a renderer found on the network (Chromecast)
        Row2 {
            label: qsTr("Render")
            RendererDropdown { Layout.preferredWidth: 216 * root.dp1 }
        }

        Divider {}
        SectionTitle { text: qsTr("Filters") }

        Label2 { text: qsTr("Essential") }
        Card {
            FilterSlider { label: qsTr("Hue"); module: "adjust"; option: "hue"; decimals: 0; ticks: 2; tickSteps: false }
            FilterSlider { label: qsTr("Brightness"); module: "adjust"; option: "brightness"; ticks: 2; tickSteps: false }
            FilterSlider { label: qsTr("Contrast"); module: "adjust"; option: "contrast"; ticks: 2; tickSteps: false }
            FilterSlider { label: qsTr("Saturation"); module: "adjust"; option: "saturation"; ticks: 3 }
            FilterSlider { label: qsTr("Gamma"); module: "adjust"; option: "gamma"; ticks: 10; tickFrom: 0 }
            FilterSlider { label: qsTr("Sharpen Sigma"); module: "sharpen"; option: "sharpen-sigma"; ticks: 4 }
            FilterSlider { label: qsTr("Banding Removal Radius"); module: "gradfun"; option: "gradfun-radius"; decimals: 0; ticks: 7 }
            FilterSlider { label: qsTr("Film Grain Variance"); module: "grain"; option: "grain-variance"; ticks: 10 }
        }

        Label2 { text: qsTr("Crop") }
        Card {
            id: cropCard

            property int cropTop: 0
            property int cropBottom: 0
            property int cropLeft: 0
            property int cropRight: 0
            property bool linkVertical: false
            property bool linkHorizontal: false

            function apply() { VLCEffects.setCrop(cropTop, cropBottom, cropLeft, cropRight) }
            contentSpacing: 16 * root.dp1

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * root.dp1
                PixelBox { label: qsTr("Top"); value: cropCard.cropTop
                    onEdited: (v) => { cropCard.cropTop = v; if (cropCard.linkVertical) cropCard.cropBottom = v; cropCard.apply() } }
                PixelBox { label: qsTr("Bottom"); value: cropCard.cropBottom
                    onEdited: (v) => { cropCard.cropBottom = v; if (cropCard.linkVertical) cropCard.cropTop = v; cropCard.apply() } }
                LinkButton { checked: cropCard.linkVertical; onClicked: cropCard.linkVertical = !cropCard.linkVertical }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * root.dp1
                PixelBox { label: qsTr("Left"); value: cropCard.cropLeft
                    onEdited: (v) => { cropCard.cropLeft = v; if (cropCard.linkHorizontal) cropCard.cropRight = v; cropCard.apply() } }
                PixelBox { label: qsTr("Right"); value: cropCard.cropRight
                    onEdited: (v) => { cropCard.cropRight = v; if (cropCard.linkHorizontal) cropCard.cropLeft = v; cropCard.apply() } }
                LinkButton { checked: cropCard.linkHorizontal; onClicked: cropCard.linkHorizontal = !cropCard.linkHorizontal }
            }
        }

        Label2 { text: qsTr("Colors") }
        Card {
            ColorFilterRow { label: qsTr("Color Extraction"); module: "extract"; option: "extract-component" }
            ColorFilterRow { label: qsTr("Color Threshold"); module: "colorthres"; option: "colorthres-color" }
            FilterSlider { label: qsTr("Saturation"); module: "colorthres"; option: "colorthres-saturationthres"; decimals: 0; enables: false }
            FilterSlider { label: qsTr("Similarity"); module: "colorthres"; option: "colorthres-similaritythres"; decimals: 0; enables: false }
            FilterToggle { label: qsTr("Negate Colors"); module: "invert" }
            FilterToggle { label: qsTr("Posterize"); module: "posterize" }
            FilterToggle { label: qsTr("Gradient"); module: "gradient" }
            Dropdown {
                Layout.fillWidth: true
                visible: VLCConfig.exists("gradient-mode")
                option: "gradient-mode"
                video: true
            }
            OptionToggle { label: qsTr("Color"); option: "gradient-color" }
            OptionToggle { label: qsTr("Cartoon"); option: "gradient-cartoon" }
            FilterSlider { label: qsTr("Sepia Intensity"); module: "sepia"; option: "sepia-intensity"; decimals: 0; ticks: 3 }
        }
    }

    component AudioPage: Page {
        SectionTitle { text: qsTr("Defaults") }
        Row2 { label: qsTr("Audio Track"); ConfigBox { option: "audio-track" } }
        Row2 { label: qsTr("Audio Language"); ConfigBox { option: "audio-language" } }
        Row2 {
            label: qsTr("Stereo Mode")
            visible: VLCConfig.exists("stereo-mode")
            // Figma Audio tab: a tone on the left, then on the right channel
            SmallButton {
                text: qsTr("Test")
                onClicked: VLCEffects.testStereo()
            }
        }
        Dropdown { Layout.fillWidth: true; option: "stereo-mode"; audio: true; visible: VLCConfig.exists("stereo-mode") }

        Divider {}
        SectionTitle { text: qsTr("Synchronization") }
        Row2 {
            label: qsTr("Audio Track Delay")
            ValueBox { text: (Player.audioDelayMS / 1000).toFixed(3) + " s" }
        }
        FxSlider {
            from: -10000; to: 10000; stepSize: 50
            tickLabels: ["-10 s", "0 s", "+10 s"]
            tickCount: 8 // Figma audio delay slider
            fillFromZero: true
            value: Player.audioDelayMS
            onMoved: Player.audioDelayMS = value
        }

        Divider {}
        SectionTitle { text: qsTr("Filters") }

        Label2 { text: qsTr("Equalizer") }
        EqualizerPreset { Layout.fillWidth: true }
        Card {
            id: eqCard

            property var bands: VLCEffects.equalizerBands()
            readonly property var labels: ["60 Hz", "170 Hz", "310 Hz", "600 Hz", "1 KHz", "3 KHz", "6 KHz", "12 KHz", "14 KHz", "16 KHz"]

            FilterSlider { label: qsTr("Preamp"); module: "equalizer"; option: "equalizer-preamp"; audio: true; unit: " dB"; boxed: true }
            Repeater {
                model: 10
                delegate: FilterSlider {
                    required property int index
                    label: eqCard.labels[index]
                    module: "equalizer"
                    audio: true
                    unit: " dB"
                    boxed: true
                    from: -20; to: 20
                    current: eqCard.bands[index] ?? 0
                    onValueSet: (v) => VLCEffects.setEqualizerBand(index, v)
                }
            }
            Connections {
                target: VLCEffects
                function onChanged() { eqCard.bands = VLCEffects.equalizerBands() }
            }
        }
        OptionToggle { label: qsTr("2 Pass"); option: "equalizer-2pass"; audio: true }

        AudioEffect {
            label: qsTr("Compressor"); module: "compressor"
            FilterSlider { label: qsTr("RMS / Peak"); module: "compressor"; option: "compressor-rms-peak"; audio: true }
            FilterSlider { label: qsTr("Attack"); module: "compressor"; option: "compressor-attack"; audio: true; unit: " ms" }
            FilterSlider { label: qsTr("Release"); module: "compressor"; option: "compressor-release"; audio: true; unit: " ms" }
            FilterSlider { label: qsTr("Threshold"); module: "compressor"; option: "compressor-threshold"; audio: true; unit: " dB" }
            FilterSlider { label: qsTr("Ratio"); module: "compressor"; option: "compressor-ratio"; audio: true; unit: " : 1" }
            FilterSlider { label: qsTr("Knee Radius"); module: "compressor"; option: "compressor-knee"; audio: true; unit: " dB" }
            FilterSlider { label: qsTr("Makeup Gain"); module: "compressor"; option: "compressor-makeup-gain"; audio: true; unit: " dB" }
        }
        AudioEffect {
            label: qsTr("Spatializer"); module: "spatializer"
            FilterSlider { label: qsTr("Size"); module: "spatializer"; option: "spatializer-roomsize"; audio: true; ticks: 11 }
            FilterSlider { label: qsTr("Width"); module: "spatializer"; option: "spatializer-width"; audio: true; ticks: 10 }
            FilterSlider { label: qsTr("Wet"); module: "spatializer"; option: "spatializer-wet"; audio: true; ticks: 10 }
            FilterSlider { label: qsTr("Dry"); module: "spatializer"; option: "spatializer-dry"; audio: true; ticks: 10 }
            FilterSlider { label: qsTr("Damp"); module: "spatializer"; option: "spatializer-damp"; audio: true; ticks: 10 }
        }
        AudioEffect {
            label: qsTr("Stereo Widener"); module: "stereo_widen"
            FilterSlider { label: qsTr("Delay Time"); module: "stereo_widen"; option: "stereowiden-delay"; audio: true; unit: " ms" }
            FilterSlider { label: qsTr("Feedback Gain"); module: "stereo_widen"; option: "stereowiden-feedback"; audio: true; ticks: 9 }
            FilterSlider { label: qsTr("Crossfeed"); module: "stereo_widen"; option: "stereowiden-crossfeed"; audio: true; ticks: 8 }
            FilterSlider { label: qsTr("Dry Mix"); module: "stereo_widen"; option: "stereowiden-dry-mix"; audio: true; ticks: 10 }
        }
    }

    component SubtitlesPage: Page {
        SectionTitle { text: qsTr("Defaults") }
        Row2 { label: qsTr("Subtitle Track"); ConfigBox { option: "sub-track" } }
        Row2 { label: qsTr("Subtitle Language"); ConfigBox { option: "sub-language" } }

        Divider {}
        SectionTitle { text: qsTr("Synchronization") }
        Row2 {
            label: qsTr("Subtitle Track Delay")
            ValueBox { text: (Player.subtitleDelayMS / 1000).toFixed(3) + " s" }
        }
        FxSlider {
            from: -10000; to: 10000; stepSize: 50
            tickLabels: ["-10 s", "0 s", "+10 s"]
            tickCount: 8
            fillFromZero: true
            value: Player.subtitleDelayMS
            onMoved: Player.subtitleDelayMS = value
        }
        Row2 {
            label: qsTr("Subtitle Speed")
            ValueBox { text: Player.subtitleFPS.toFixed(3) + " fps" }
        }
        FxSlider {
            from: 0.1; to: 10; stepSize: 0.01
            value: Player.subtitleFPS
            onMoved: Player.subtitleFPS = value
        }
        // Figma Subtitles tab: how long a subtitle stays (VLC's subsdelay
        // filter, on while the factor is above 0; its mode is in All Settings)
        Row2 {
            visible: durationFactor.visible
            label: qsTr("Subtitle Duration Factor")
            ValueBox { text: durationFactor.value.toFixed(1) }
        }
        FxSlider {
            id: durationFactor
            visible: VLCConfig.exists("subsdelay-factor") && VLCConfig.moduleExists("subsdelay")
            from: 0; to: 20; stepSize: 0.1
            tickCount: 10
            value: { root.configRevision; return Number(VLCEffects.videoValue("subsdelay-factor") ?? 0) || 0 }
            onMoved: {
                const v = Math.round(value * 10) / 10
                VLCEffects.setVideoValue("subsdelay-factor", v)
                VLCEffects.setVideoFilterEnabled("subsdelay", v > 0)
            }
        }

        Divider {}
        SectionTitle { text: qsTr("Appearance") }
        Row2 { label: qsTr("Subtitle Font"); visible: VLCConfig.exists("freetype-font"); ConfigBox { option: "freetype-font" } }
        Row2 { label: qsTr("Text Color"); visible: VLCConfig.exists("freetype-color"); ColorBox { option: "freetype-color" } }
        Row2 { label: qsTr("Outline Color"); visible: VLCConfig.exists("freetype-outline-color"); ColorBox { option: "freetype-outline-color" } }
        Row2 {
            label: qsTr("Subtitle Offset")
            UnitBox {
                implicitWidth: root.fieldWidth
                Layout.fillWidth: false
                unit: "px"
                value: { root.configRevision; return Number(VLCConfig.value("sub-margin") ?? 0) || 0 }
                onEdited: (v) => VLCConfig.setValue("sub-margin", v)
            }
        }

        // video 8:00: size values as "Relative" (named steps) or "Scale"
        // (numbers in percent, VLC 4 has no font size in pixels)
        Row2 {
            label: qsTr("Size Values")
            Segmented {
                options: [qsTr("Relative"), qsTr("Scale")]
                current: root.subtitleSizeScale ? 1 : 0
                onChosen: (i) => {
                    root.subtitleSizeScale = (i === 1)
                    VLCConfig.setUiValue("Player/SubtitleSizeValues", root.subtitleSizeScale ? "scale" : "relative")
                }
            }
        }

        // ---- relative: sliders with named steps
        StepSlider {
            visible: !root.subtitleSizeScale
            label: qsTr("Font Size")
            steps: [10, 50, 75, 100, 150, 200, 300]
            names: [qsTr("Tiny"), qsTr("Smaller"), qsTr("Small"), qsTr("Normal"), qsTr("Large"), qsTr("Larger"), qsTr("Huge")]
            value: root.textScale
            onChosen: (v) => root.setTextScale(v)
        }
        StepSlider {
            visible: !root.subtitleSizeScale && VLCConfig.exists("freetype-outline-thickness")
            label: qsTr("Outline Thickness")
            steps: [0, 2, 4, 6]
            names: [qsTr("None"), qsTr("Thin"), qsTr("Normal"), qsTr("Thick")]
            value: { root.configRevision; return Number(VLCConfig.value("freetype-outline-thickness") ?? 4) }
            onChosen: (v) => root.setSubtitleOption("freetype-outline-thickness", v)
        }
        StepSlider {
            visible: !root.subtitleSizeScale && VLCConfig.exists("freetype-background-opacity")
            label: qsTr("Background Opacity")
            steps: [0, 64, 128, 191, 255]
            names: ["0 %", "25 %", "50 %", "75 %", "100 %"]
            value: { root.configRevision; return Number(VLCConfig.value("freetype-background-opacity") ?? 0) }
            onChosen: (v) => root.setSubtitleOption("freetype-background-opacity", v)
        }

        // ---- scale: numbers
        Row2 {
            visible: root.subtitleSizeScale
            label: qsTr("Font Size")
            UnitBox {
                implicitWidth: root.fieldWidth
                Layout.fillWidth: false
                unit: "%"
                maxValue: 500
                value: root.textScale
                onEdited: (v) => root.setTextScale(v)
            }
        }
        Row2 {
            visible: root.subtitleSizeScale && VLCConfig.exists("freetype-outline-thickness")
            label: qsTr("Outline Thickness")
            UnitBox {
                implicitWidth: root.fieldWidth
                Layout.fillWidth: false
                unit: "%"
                maxValue: 50
                value: { root.configRevision; return Number(VLCConfig.value("freetype-outline-thickness") ?? 4) }
                onEdited: (v) => root.setSubtitleOption("freetype-outline-thickness", Math.min(50, v))
            }
        }
        Row2 {
            visible: root.subtitleSizeScale && VLCConfig.exists("freetype-background-opacity")
            label: qsTr("Background Opacity")
            UnitBox {
                implicitWidth: root.fieldWidth
                Layout.fillWidth: false
                unit: "%"
                maxValue: 100
                value: { root.configRevision; return Math.round(Number(VLCConfig.value("freetype-background-opacity") ?? 0) * 100 / 255) }
                onEdited: (v) => root.setSubtitleOption("freetype-background-opacity", Math.round(Math.min(100, v) * 255 / 100))
            }
        }

    }

    // ---- subtitle settings: size values, presets ------------------------

    // bumped when subtitle options change from a preset, so that the fields
    // read them again
    property int configRevision: 0
    property bool subtitleSizeScale: String(VLCConfig.uiValue("Player/SubtitleSizeValues", "relative")) === "scale"
    property int textScale: 100

    onOpened: textScale = Player.getSubtitleTextScale()
    onClosed: presetBar.listOpen = false

    function setTextScale(v) {
        textScale = Math.max(10, Math.min(500, v))
        Player.setSubtitleTextScale(textScale)
        VLCConfig.setValue("sub-text-scale", textScale)
    }

    // the text renderer reads these options for every subtitle: they apply
    // at once
    function setSubtitleOption(option, value) {
        VLCConfig.setValue(option, value)
        configRevision++
    }

    // ---- presets: all settings of the panel, saved under a name ---------

    // video 8:30: "save all these settings for this specific show through a
    // preset and then later you just select whatever preset you want".
    // Leaving a preset keeps the settings it had in it; "Default Preset" is
    // the settings used without a preset.

    // plain options, options of the audio output, options of the video output
    readonly property var configPresetOptions: [
        "freetype-font", "freetype-color", "freetype-outline-color", "freetype-outline-thickness",
        "freetype-background-opacity", "sub-margin", "sub-language", "sub-track",
        "audio-track", "audio-language", "d3d11-hdr-mode", "preferred-resolution"]
    readonly property var audioPresetOptions: [
        "stereo-mode", "equalizer-preamp", "equalizer-bands", "equalizer-preset", "equalizer-2pass",
        "compressor-rms-peak", "compressor-attack", "compressor-release", "compressor-threshold",
        "compressor-ratio", "compressor-knee", "compressor-makeup-gain",
        "spatializer-roomsize", "spatializer-width", "spatializer-wet", "spatializer-dry", "spatializer-damp",
        "stereowiden-delay", "stereowiden-feedback", "stereowiden-crossfeed", "stereowiden-dry-mix"]
    readonly property var videoPresetOptions: [
        "hue", "brightness", "contrast", "saturation", "gamma", "sharpen-sigma", "gradfun-radius",
        "grain-variance", "extract-component", "colorthres-color", "colorthres-saturationthres",
        "colorthres-similaritythres", "gradient-mode", "gradient-color", "gradient-cartoon", "sepia-intensity"]

    function _loadJson(key, fallback) {
        try {
            const value = JSON.parse(String(VLCConfig.uiValue(key, "")))
            return value ?? fallback
        } catch (e) {
            return fallback
        }
    }

    // the subtitle presets of earlier versions become presets of the panel
    property var presets: {
        const list = _loadJson("Player/Presets", null) ?? _loadJson("Player/SubtitlePresets", [])
        return Array.isArray(list) ? list : []
    }
    property var defaultPreset: _loadJson("Player/DefaultPreset", null)
    property string activePreset: {
        const name = String(VLCConfig.uiValue("Player/Preset", VLCConfig.uiValue("Player/SubtitlePreset", "")))
        return presets.some((p) => p.name === name) ? name : ""
    }

    // the pages read their values when they are created: they are created
    // again after a preset changed the settings
    property bool pagesActive: true

    function currentSettings(name) {
        const values = {}
        for (const option of configPresetOptions)
            if (VLCConfig.exists(option))
                values[option] = VLCConfig.value(option)
        for (const option of audioPresetOptions)
            if (VLCConfig.exists(option))
                values[option] = VLCEffects.audioValue(option)
        for (const option of videoPresetOptions)
            if (VLCConfig.exists(option))
                values[option] = VLCEffects.videoValue(option)
        const orientation = VLCEffects.orientation()
        return { "name": name, "values": values,
                 "audioFilters": VLCEffects.filterChain(true), "videoFilters": VLCEffects.filterChain(false),
                 "flip": orientation.flip, "angle": orientation.angle,
                 "textScale": textScale, "sizeValues": subtitleSizeScale ? "scale" : "relative",
                 "delay": Player.subtitleDelayMS, "audioDelay": Player.audioDelayMS }
    }

    function applyPreset(preset) {
        const values = preset.values ?? {}
        for (const option in values) {
            if (!VLCConfig.exists(option))
                continue
            if (audioPresetOptions.includes(option))
                VLCEffects.setAudioValue(option, values[option])
            else if (videoPresetOptions.includes(option))
                VLCEffects.setVideoValue(option, values[option])
            else
                VLCConfig.setValue(option, values[option])
        }
        if (preset.audioFilters !== undefined)
            VLCEffects.setFilterChain(true, preset.audioFilters)
        if (preset.videoFilters !== undefined)
            VLCEffects.setFilterChain(false, preset.videoFilters)
        if (preset.flip !== undefined)
            VLCEffects.setOrientation(preset.flip, preset.angle ?? 0)
        if (preset.textScale !== undefined)
            setTextScale(preset.textScale)
        if (preset.delay !== undefined)
            Player.subtitleDelayMS = preset.delay
        if (preset.audioDelay !== undefined)
            Player.audioDelayMS = preset.audioDelay
        if (preset.sizeValues !== undefined) {
            subtitleSizeScale = preset.sizeValues === "scale"
            VLCConfig.setUiValue("Player/SubtitleSizeValues", preset.sizeValues)
        }
        configRevision++
        pagesActive = false
        pagesActive = true
    }

    // ---- "Restore Defaults": the settings of one tab back to VLC's defaults

    readonly property var tabDefaults: [
        { "config": [], "audio": [], "video": [], "audioModules": [], "videoModules": [] },
        { "config": ["d3d11-hdr-mode", "preferred-resolution"], "audio": [], "video": videoPresetOptions,
          "audioModules": [],
          "videoModules": ["adjust", "sharpen", "gradfun", "grain", "extract", "colorthres",
                           "invert", "posterize", "gradient", "sepia"] },
        { "config": ["audio-track", "audio-language"], "audio": audioPresetOptions, "video": [],
          "audioModules": ["equalizer", "compressor", "spatializer", "stereo_widen"], "videoModules": [] },
        { "config": ["freetype-font", "freetype-color", "freetype-outline-color", "freetype-outline-thickness",
                     "freetype-background-opacity", "sub-margin", "sub-language", "sub-track"],
          "audio": [], "video": [], "audioModules": [], "videoModules": [] }
    ]

    function restoreDefaults(tab) {
        const d = tabDefaults[tab]
        if (!d)
            return
        for (const option of d.config)
            if (VLCConfig.exists(option))
                VLCConfig.resetValue(option)
        for (const option of d.audio)
            if (VLCConfig.exists(option))
                VLCEffects.setAudioValue(option, VLCConfig.defaultValue(option))
        for (const option of d.video)
            if (VLCConfig.exists(option))
                VLCEffects.setVideoValue(option, VLCConfig.defaultValue(option))
        // only the filters of the panel: filters chosen elsewhere stay
        for (const module of d.audioModules)
            VLCEffects.setAudioFilterEnabled(module, false)
        for (const module of d.videoModules)
            VLCEffects.setVideoFilterEnabled(module, false)

        switch (tab) {
        case 0:
            if (Player.ratechangable)
                Player.rate = 1
            VLCConfig.setUiValue("Player/SubtitleTimeline", false)
            break
        case 1:
            VLCEffects.setOrientation(0, 0)
            VLCEffects.setCrop(0, 0, 0, 0)
            break
        case 2:
            Player.audioDelayMS = 0
            break
        case 3:
            Player.subtitleDelayMS = 0
            Player.subtitleFPS = 1
            setTextScale(100)
            subtitleSizeScale = false
            VLCConfig.setUiValue("Player/SubtitleSizeValues", "relative")
            break
        }

        // the pages read their values when they are created
        configRevision++
        pagesActive = false
        pagesActive = true
    }

    function _savePresets(list) {
        presets = list
        VLCConfig.setUiValue("Player/Presets", JSON.stringify(list))
    }

    function _setActive(name) {
        activePreset = name
        VLCConfig.setUiValue("Player/Preset", name)
    }

    // keeps the current settings in the preset that is left
    function _storeActive() {
        if (activePreset === "") {
            defaultPreset = currentSettings("")
            VLCConfig.setUiValue("Player/DefaultPreset", JSON.stringify(defaultPreset))
        } else {
            _savePresets(presets.map((p) => p.name === activePreset ? currentSettings(p.name) : p))
        }
    }

    // "" chooses "Default Preset"
    function choosePreset(name) {
        if (name === activePreset)
            return
        _storeActive()
        const preset = name === "" ? defaultPreset : presets.find((p) => p.name === name)
        if (preset)
            applyPreset(preset)
        _setActive(name)
    }

    function newPresetName() {
        for (let i = 1; ; ++i) {
            const name = qsTr("Custom Preset %1").arg(String(i).padStart(2, "0"))
            if (!presets.some((p) => p.name === name))
                return name
        }
    }

    // a new preset with the current settings
    function addPreset() {
        _storeActive()
        const name = newPresetName()
        _savePresets(presets.concat([currentSettings(name)]))
        _setActive(name)
        return name
    }

    function renamePreset(oldName, newName) {
        newName = newName.trim()
        if (newName === "" || newName === oldName || presets.some((p) => p.name === newName))
            return false
        _savePresets(presets.map((p) => p.name === oldName ? Object.assign({}, p, { "name": newName }) : p))
        if (activePreset === oldName)
            _setActive(newName)
        return true
    }

    // deleting the active preset goes back to "Default Preset"
    function deletePreset(name) {
        _savePresets(presets.filter((p) => p.name !== name))
        if (activePreset === name) {
            if (defaultPreset)
                applyPreset(defaultPreset)
            _setActive("")
        }
    }

    // ===================================================================
    // building blocks

    component Page: ColumnLayout {
        spacing: 12 * root.dp1
        Item { Layout.preferredHeight: 4 * root.dp1 }
    }

    // Figma panel: titles 16 px #969696, labels 14 px #6B6B6B
    component SectionTitle: Text {
        Layout.topMargin: 6 * root.dp1
        color: root.sectionColor
        font.pixelSize: 16 * root.dp1
    }

    component Label2: Text {
        color: root.dimColor
        font.pixelSize: 14 * root.dp1
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: -20 * root.dp1
        Layout.rightMargin: -20 * root.dp1
        Layout.topMargin: 6 * root.dp1
        implicitHeight: 1
        color: root.dividerColor
    }

    // label on the left, controls on the right
    component Row2: RowLayout {
        property string label
        Layout.fillWidth: true
        spacing: 10 * root.dp1
        Text {
            Layout.fillWidth: true
            text: parent.label
            color: root.dimColor
            font.pixelSize: 14 * root.dp1
            elide: Text.ElideRight
        }
    }

    // background of the text boxes (Figma "Values", EQ value boxes): 2 px
    // Dark/BG/A4 ring around a Dark/BG/B2 well, accent ring while editing
    component FieldBackground: Rectangle {
        property bool focused: false
        radius: 6 * root.dp1
        color: focused ? root.accentColor : root.ringColor
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2 * root.dp1
            radius: 4 * root.dp1
            color: root.wellColor
        }
    }

    // Figma chevrons are 10 x 5 px glyphs on a 24 px em, centred in the box
    component Chevron: Text {
        Layout.preferredWidth: 24 * root.dp1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: VLCIcons.fontFamily
        font.pixelSize: 24 * root.dp1
        text: VLCIcons.chevron_down
        color: root.textColor
    }

    component ValueBox: FieldBackground {
        property alias text: valueText.text
        property real fontSize: 14 * root.dp1
        implicitWidth: root.fieldWidth
        implicitHeight: root.fieldHeight
        Text {
            id: valueText
            anchors { fill: parent; leftMargin: 14 * root.dp1; rightMargin: 14 * root.dp1 }
            verticalAlignment: Text.AlignVCenter
            color: root.textColor
            font.pixelSize: parent.fontSize
            elide: Text.ElideRight
        }
    }

    // editable config value (text or number)
    component ConfigBox: T.TextField {
        id: configBox
        property string option
        implicitWidth: root.fieldWidth
        implicitHeight: root.fieldHeight
        leftPadding: 14 * root.dp1
        rightPadding: 14 * root.dp1
        verticalAlignment: TextInput.AlignVCenter
        color: root.textColor
        selectionColor: root.accentSurface
        font.pixelSize: 14 * root.dp1
        text: { root.configRevision; return String(VLCConfig.value(option) ?? "") }
        background: FieldBackground { focused: configBox.activeFocus }
        onEditingFinished: VLCConfig.setValue(option, text)
    }

    // hex value and a swatch in one text box
    component ColorBox: FieldBackground {
        id: colorBox
        property string option
        property string value: { root.configRevision; return String(VLCConfig.value(option) ?? "#000000") }
        implicitWidth: root.fieldWidth
        implicitHeight: root.fieldHeight
        focused: colorField.activeFocus
        RowLayout {
            anchors { fill: parent; leftMargin: 14 * root.dp1; rightMargin: 12 * root.dp1 }
            spacing: 6 * root.dp1
            T.TextField {
                id: colorField
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                color: root.textColor
                selectionColor: root.accentSurface
                font.pixelSize: 14 * root.dp1
                text: colorBox.value.toUpperCase()
                background: null
                onEditingFinished: {
                    VLCConfig.setValue(colorBox.option, text)
                    colorBox.value = String(VLCConfig.value(colorBox.option))
                }
            }
            Rectangle { implicitWidth: 14 * root.dp1; implicitHeight: 14 * root.dp1; radius: 2 * root.dp1; color: colorBox.value }
        }
    }

    // slider of the design (Figma effect settings): 16 px Dark/BG/B2 track,
    // Accent Bright fill inset by 2 px up to the 8 x 24 Accent Dim handle;
    // the delay sliders fill from 0 (empty at 0 s in the Figma panel)
    component FxSlider: T.Slider {
        id: slider
        property var tickLabels: []
        // Figma: 2 x 6 px marks dividing the track into tickCount parts
        property int tickCount: 0
        property bool fillFromZero: false
        // handle x for a position 0..1
        function handleX(pos) { return 2 * root.dp1 + pos * (availableWidth - 12 * root.dp1) }
        readonly property real zeroPosition: (fillFromZero && from < 0 && to > 0) ? -from / (to - from) : 0
        Layout.fillWidth: true
        implicitHeight: (tickLabels.length > 0 ? 41 : 24) * root.dp1
        live: true
        // the handle jumps from step to step instead of sliding between them
        snapMode: T.Slider.SnapAlways

        background: Item {
            Rectangle {
                id: track
                y: 4 * root.dp1
                width: slider.availableWidth
                height: 16 * root.dp1
                radius: 6 * root.dp1
                color: root.wellColor
                Rectangle {
                    readonly property real zeroX: slider.handleX(slider.mirrored ? 1 - slider.zeroPosition : slider.zeroPosition)
                    readonly property real valueX: slider.handleX(slider.visualPosition)
                    x: Math.min(zeroX, valueX)
                    y: 2 * root.dp1
                    width: Math.abs(valueX - zeroX) + 8 * root.dp1
                    height: 12 * root.dp1
                    radius: 4 * root.dp1
                    color: root.accentSurface
                }
            }
            Repeater {
                model: Math.max(0, slider.tickCount - 1)
                Rectangle {
                    required property int index
                    x: slider.handleX((index + 1) / slider.tickCount) + 3 * root.dp1
                    y: track.y + 5 * root.dp1
                    width: 2 * root.dp1
                    height: 6 * root.dp1
                    radius: 1 * root.dp1
                    color: root.tickColor
                }
            }
            Repeater {
                model: slider.tickLabels
                Text {
                    required property var modelData
                    required property int index
                    y: 26 * root.dp1
                    x: Math.max(0, Math.min(track.width - implicitWidth,
                         slider.handleX(index / Math.max(1, slider.tickLabels.length - 1)) + 4 * root.dp1 - implicitWidth / 2))
                    text: modelData
                    color: root.dimColor
                    font.pixelSize: 12 * root.dp1
                }
            }
        }
        handle: Rectangle {
            x: slider.handleX(slider.visualPosition)
            y: 0
            width: 8 * root.dp1
            height: 24 * root.dp1
            radius: 4 * root.dp1
            color: slider.enabled ? root.accentDimColor : root.faintColor
        }
    }

    // label + value + slider bound to a filter option; moving it enables
    // the filter (unless enables is false)
    component FilterSlider: ColumnLayout {
        id: fs
        property string label
        property string module
        property string option
        property bool audio: false
        property bool enables: true
        property bool boxed: false
        property string unit: ""
        property int decimals: 1
        property real from: VLCConfig.range(option)?.min ?? 0
        property real to: VLCConfig.range(option)?.max ?? 1
        // tick marks of the design; the slider moves from tick to tick
        // unless tickSteps is false (a single mark in the middle)
        property int ticks: 0
        property bool tickSteps: true
        // where the ticks start when it is not the minimum (gamma: 0, min 0.01)
        property real tickFrom: from
        property real current: option !== "" ? Number(audio ? VLCEffects.audioValue(option) : VLCEffects.videoValue(option)) : 0
        signal valueSet(real value)

        Layout.fillWidth: true
        visible: option === "" || VLCConfig.exists(option)
        // Figma effect settings: label 14 px, value box 10 px above the slider
        spacing: (boxed ? 10 : 14) * root.dp1

        RowLayout {
            Text { Layout.fillWidth: true; text: fs.label; color: root.dimColor; font.pixelSize: 14 * root.dp1 }
            Text {
                visible: !fs.boxed
                text: fs.current.toFixed(fs.decimals) + fs.unit
                color: root.dimColor
                font.pixelSize: 14 * root.dp1
            }
            ValueBox { visible: fs.boxed; fontSize: 12 * root.dp1; text: fs.current.toFixed(fs.decimals) + fs.unit }
        }
        FxSlider {
            from: fs.tickFrom; to: fs.to
            // from tick to tick, or in steps of the shown precision (0.1 for one decimal)
            stepSize: fs.ticks > 1 && fs.tickSteps ? (fs.to - fs.tickFrom) / fs.ticks : Math.pow(10, -fs.decimals)
            tickCount: fs.ticks
            value: fs.current
            tickLabels: []
            onMoved: {
                fs.current = Math.max(fs.from, Number(value.toFixed(fs.decimals)))
                if (fs.option === "") {
                    fs.valueSet(fs.current)
                } else if (fs.audio) {
                    VLCEffects.setAudioValue(fs.option, fs.current)
                } else {
                    VLCEffects.setVideoValue(fs.option, fs.current)
                }
                if (fs.enables && fs.module !== "") {
                    if (fs.audio)
                        VLCEffects.setAudioFilterEnabled(fs.module, true)
                    else
                        VLCEffects.setVideoFilterEnabled(fs.module, true)
                }
            }
        }
    }

    // ON/OFF switch of the design (Figma "Toggle"): 68 x 32 Dark/BG/B2,
    // a 26 px knob and the ON/OFF label on its own 33 px tile
    component Switch: T.Switch {
        id: sw
        implicitWidth: 68 * root.dp1
        implicitHeight: 32 * root.dp1
        indicator: Rectangle {
            anchors.fill: parent
            radius: 6 * root.dp1
            color: root.wellColor
            Rectangle {
                x: sw.checked ? 3 * root.dp1 : 32 * root.dp1
                anchors.verticalCenter: parent.verticalCenter
                width: 33 * root.dp1; height: 26 * root.dp1
                radius: 3 * root.dp1
                color: sw.checked ? root.accentSurface : root.ringColor
                Behavior on x { NumberAnimation { duration: VLCStyle.duration_short } }
                Text {
                    anchors.centerIn: parent
                    text: sw.checked ? qsTr("ON") : qsTr("OFF")
                    color: sw.checked ? root.accentColor : root.dimColor
                    font.pixelSize: 12 * root.dp1
                }
            }
            Rectangle {
                x: sw.checked ? 39 * root.dp1 : 3 * root.dp1
                anchors.verticalCenter: parent.verticalCenter
                width: 26 * root.dp1; height: 26 * root.dp1
                radius: 3 * root.dp1
                color: sw.checked ? root.accentDimColor : root.faintColor
                Behavior on x { NumberAnimation { duration: VLCStyle.duration_short } }
            }
        }
    }

    component FilterToggle: Row2 {
        property string module
        property bool audio: false
        Switch {
            checked: parent.audio ? VLCEffects.audioFilterEnabled(parent.module) : VLCEffects.videoFilterEnabled(parent.module)
            onToggled: parent.audio ? VLCEffects.setAudioFilterEnabled(parent.module, checked)
                                    : VLCEffects.setVideoFilterEnabled(parent.module, checked)
        }
    }

    component OptionToggle: Row2 {
        property string option
        property bool audio: false
        visible: VLCConfig.exists(option)
        Switch {
            checked: Boolean(parent.audio ? VLCEffects.audioValue(parent.option) : VLCEffects.videoValue(parent.option))
            onToggled: parent.audio ? VLCEffects.setAudioValue(parent.option, checked)
                                    : VLCEffects.setVideoValue(parent.option, checked)
        }
    }

    // hex color value + swatch + filter toggle
    component ColorFilterRow: Row2 {
        id: cfr
        property string module
        property string option
        property string hex: {
            const v = Number(VLCEffects.videoValue(option) ?? 0)
            return "#" + ("000000" + v.toString(16).toUpperCase()).slice(-6)
        }
        visible: VLCConfig.exists(option)
        T.TextField {
            id: cfrField
            implicitWidth: 100 * root.dp1
            implicitHeight: root.fieldHeight
            leftPadding: 14 * root.dp1
            rightPadding: 10 * root.dp1
            verticalAlignment: TextInput.AlignVCenter
            color: root.textColor
            selectionColor: root.accentSurface
            font.pixelSize: 14 * root.dp1
            text: cfr.hex
            background: FieldBackground { focused: cfrField.activeFocus }
            onEditingFinished: {
                const v = parseInt(text.replace("#", ""), 16)
                if (!isNaN(v))
                    VLCEffects.setVideoValue(cfr.option, v)
            }
        }
        Rectangle { implicitWidth: 14 * root.dp1; implicitHeight: 14 * root.dp1; radius: 2 * root.dp1; color: cfr.hex }
        Switch {
            checked: VLCEffects.videoFilterEnabled(cfr.module)
            onToggled: VLCEffects.setVideoFilterEnabled(cfr.module, checked)
        }
    }

    // number field with a unit ("px", "%")
    component UnitBox: FieldBackground {
        id: ub
        property int value: 0
        property string unit: "px"
        property int maxValue: 10000
        signal edited(int value)
        Layout.fillWidth: true
        implicitHeight: root.fieldHeight
        focused: ubField.activeFocus
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14 * root.dp1
            anchors.rightMargin: 14 * root.dp1
            T.TextField {
                id: ubField
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                color: root.textColor
                selectionColor: root.accentSurface
                font.pixelSize: 14 * root.dp1
                text: String(ub.value)
                validator: IntValidator { bottom: 0; top: ub.maxValue }
                background: null
                onEditingFinished: ub.edited(parseInt(text) || 0)
            }
            Text { text: ub.unit; color: root.faintColor; font.pixelSize: 14 * root.dp1 }
        }
    }

    // two-way choice ("Relative" | "Scale"), the chosen one in the accent
    component Segmented: Rectangle {
        id: seg
        property var options: []
        property int current: 0
        signal chosen(int index)
        // Figma "Values": 44 px Dark/BG/B2 box, 40 px buttons 2 px apart
        implicitWidth: 213 * root.dp1
        implicitHeight: 44 * root.dp1
        radius: 6 * root.dp1
        color: root.wellColor
        Row {
            id: segRow
            anchors.fill: parent
            anchors.margins: 2 * root.dp1
            spacing: 2 * root.dp1
            Repeater {
                model: seg.options
                T.Button {
                    id: segButton
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === seg.current
                    width: (segRow.width - (seg.options.length - 1) * segRow.spacing) / Math.max(1, seg.options.length)
                    height: segRow.height
                    background: Rectangle {
                        radius: 4 * root.dp1
                        color: segButton.selected ? root.accentSurface
                             : segButton.hovered ? root.cardColor : root.ringColor
                    }
                    contentItem: Text {
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: segButton.modelData
                        font.pixelSize: 14 * root.dp1
                        color: segButton.selected ? root.accentColor : root.dimColor
                        elide: Text.ElideRight
                    }
                    onClicked: seg.chosen(index)
                }
            }
        }
    }

    // title, name of the current step on the right, slider over the steps
    component StepSlider: ColumnLayout {
        id: ss
        property string label
        property var steps: []
        property var names: []
        property real value: 0
        signal chosen(real value)
        readonly property int index: {
            let best = 0
            for (let i = 1; i < steps.length; ++i)
                if (Math.abs(steps[i] - value) < Math.abs(steps[best] - value))
                    best = i
            return best
        }
        Layout.fillWidth: true
        spacing: 6 * root.dp1
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: ss.label
                color: root.dimColor
                font.pixelSize: 14 * root.dp1
            }
            Text {
                // the exact value when it is between two steps
                text: ss.steps[ss.index] === ss.value ? (ss.names[ss.index] ?? "") : (Math.round(ss.value) + "")
                color: root.dimColor
                font.pixelSize: 14 * root.dp1
            }
        }
        FxSlider {
            from: 0
            to: Math.max(1, ss.steps.length - 1)
            stepSize: 1
            snapMode: T.Slider.SnapAlways
            value: ss.index
            onMoved: ss.chosen(ss.steps[Math.round(value)])
        }
    }

    // preset of the subtitle settings: name and chevron, a menu to apply,
    // save, rename or delete presets
    // footer bar of the presets (Figma "Setting Preset"): the active preset;
    // above it the list with "New Preset", the presets (with a "…" menu to
    // rename or delete them) and "Default Preset" at the bottom
    component PresetBar: Rectangle {
        id: bar
        property bool listOpen: false
        property string editing: ""     // preset being renamed
        property string menuTarget: ""  // preset of the open "…" menu

        z: 10
        implicitHeight: 42 * root.dp1
        radius: 6 * root.dp1
        color: barArea.containsMouse ? root.wellHoverColor : root.wellColor
        onListOpenChanged: if (!listOpen) editing = ""

        // closes the list on a click elsewhere in the panel
        MouseArea {
            readonly property point origin: bar.listOpen ? bar.mapToItem(root.contentItem, 0, 0) : Qt.point(0, 0)
            visible: bar.listOpen
            x: -origin.x
            y: -origin.y
            width: root.contentItem.width
            height: root.contentItem.height
            onClicked: bar.listOpen = false
        }

        MouseArea {
            id: barArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: bar.listOpen = !bar.listOpen
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16 * root.dp1
            anchors.rightMargin: 16 * root.dp1
            Text {
                Layout.fillWidth: true
                text: root.activePreset !== "" ? root.activePreset : qsTr("Default Preset")
                color: root.textColor
                font.pixelSize: 14 * root.dp1
                elide: Text.ElideRight
            }
            Chevron { text: bar.listOpen ? VLCIcons.chevron_down : VLCIcons.chevron_up }
        }

        Accessible.role: Accessible.ComboBox
        Accessible.name: qsTr("Preset")

        Rectangle {
            id: presetList
            visible: bar.listOpen
            width: bar.width
            height: listColumn.implicitHeight + 2
            y: -height - 6 * root.dp1
            radius: 6 * root.dp1
            color: root.ringColor
            clip: true

            Column {
                id: listColumn
                x: 1
                y: 1
                width: parent.width - 2

                Flickable {
                    width: parent.width
                    // room for the tabs above
                    height: Math.min(presetRows.implicitHeight,
                                     Math.max(80 * root.dp1, bar.mapToItem(root.contentItem, 0, 0).y - 140 * root.dp1))
                    contentHeight: presetRows.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    Column {
                        id: presetRows
                        width: parent.width

                        PresetRow {
                            width: presetRows.width
                            icon: VLCIcons.add
                            dim: true
                            text: qsTr("New Preset")
                            onClicked: bar.editing = root.addPreset()
                        }
                        Repeater {
                            model: root.presets
                            delegate: PresetRow {
                                required property var modelData
                                width: presetRows.width
                                text: modelData.name
                                menu: true
                                checked: modelData.name === root.activePreset
                                editing: bar.editing === modelData.name
                                onClicked: {
                                    root.choosePreset(modelData.name)
                                    bar.listOpen = false
                                }
                                onMenuClicked: (button) => {
                                    bar.menuTarget = modelData.name
                                    presetMenu.popup(button.mapToGlobal(0, button.height + 4 * root.dp1),
                                                     [{ "text": qsTr("Rename") }, { "text": qsTr("Delete") }])
                                }
                                onRenamed: (name) => {
                                    root.renamePreset(modelData.name, name)
                                    bar.editing = ""
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: listColumn.width
                    height: 42 * root.dp1
                    radius: 6 * root.dp1
                    color: root.wellColor
                PresetRow {
                    x: 2 * root.dp1
                    y: 2 * root.dp1
                    width: parent.width - 4 * root.dp1
                    implicitHeight: 38 * root.dp1
                    radius: 4 * root.dp1
                    color: hovered ? Qt.lighter(root.cardColor, 1.15) : root.cardColor
                    textMargin: 14 * root.dp1
                    text: qsTr("Default Preset")
                    checked: root.activePreset === ""
                    onClicked: {
                        root.choosePreset("")
                        bar.listOpen = false
                    }
                }
                }
            }
        }

        StringListMenu {
            id: presetMenu
            ctx: MainCtx
            onSelected: (index, _) => {
                if (index === 0)
                    bar.editing = bar.menuTarget
                else if (index === 1)
                    root.deletePreset(bar.menuTarget)
            }
        }
    }

    // row of the preset list: "…" button or icon, name (editable while it
    // is renamed), check mark of the active preset
    component PresetRow: Rectangle {
        id: row
        property string text
        property string icon: ""
        property bool menu: false
        property bool checked: false
        property bool editing: false
        property bool dim: false            // "New Preset"
        property real textMargin: 16 * root.dp1
        readonly property bool hovered: rowArea.containsMouse
        signal clicked()
        signal menuClicked(Item button)
        signal renamed(string name)

        implicitHeight: 40 * root.dp1
        color: hovered ? root.cardColor : "transparent"
        function _startEditing() {
            nameEdit.text = row.text
            nameEdit.selectAll()
            nameEdit.forceActiveFocus()
        }
        onEditingChanged: if (editing) _startEditing()
        // a new preset is created while it is renamed
        Component.onCompleted: if (editing) _startEditing()

        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: if (!row.editing) row.clicked()
        }

        RowLayout {
            anchors.fill: parent
            // Figma: icon centred 28 px in, name at 50 px, 14 px text
            anchors.leftMargin: row.textMargin
            anchors.rightMargin: 16 * root.dp1
            spacing: 10 * root.dp1

            T.Button {
                id: menuButton
                visible: row.menu
                implicitWidth: 24 * root.dp1
                implicitHeight: 24 * root.dp1
                background: Rectangle {
                    radius: 3 * root.dp1
                    color: menuButton.hovered ? root.wellColor : "transparent"
                }
                contentItem: Text {
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: VLCIcons.fontFamily
                    font.pixelSize: 24 * root.dp1
                    text: VLCIcons.ellipsis
                    color: menuButton.hovered ? root.titleColor : root.textColor
                }
                Accessible.name: qsTr("Preset options")
                onClicked: row.menuClicked(menuButton)
            }
            Text {
                visible: row.icon !== ""
                Layout.preferredWidth: 24 * root.dp1
                horizontalAlignment: Text.AlignHCenter
                font.family: VLCIcons.fontFamily
                font.pixelSize: 24 * root.dp1
                text: row.icon
                color: row.hovered ? root.textColor : row.dim ? root.dimColor : root.textColor
            }
            Text {
                visible: !row.editing
                Layout.fillWidth: true
                text: row.text
                color: row.hovered ? root.titleColor : row.dim ? root.dimColor : root.textColor
                font.pixelSize: 14 * root.dp1
                elide: Text.ElideRight
            }
            T.TextField {
                id: nameEdit
                visible: row.editing
                Layout.fillWidth: true
                implicitHeight: 28 * root.dp1
                leftPadding: 6 * root.dp1
                verticalAlignment: TextInput.AlignVCenter
                color: root.textColor
                selectionColor: root.accentSurface
                font.pixelSize: 14 * root.dp1
                background: Rectangle {
                    radius: 4 * root.dp1
                    color: root.wellColor
                    border.width: 1
                    border.color: root.accentColor
                }
                onEditingFinished: if (row.editing) row.renamed(text)
            }
            Text {
                visible: row.checked
                font.family: VLCIcons.fontFamily
                font.pixelSize: 24 * root.dp1
                text: VLCIcons.check
                color: root.accentColor
            }
        }
    }

    // Figma "Video - Crop": 141 x 33 Dark/BG/B2 box, label, value, "px"
    component PixelBox: Rectangle {
        id: pb
        property string label
        property int value: 0
        signal edited(int value)
        Layout.fillWidth: true
        implicitHeight: 33 * root.dp1
        radius: 6 * root.dp1
        color: root.wellColor
        border.width: pbField.activeFocus ? 1 : 0
        border.color: root.accentColor
        MouseArea { anchors.fill: parent; onClicked: pbField.forceActiveFocus() }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12 * root.dp1
            anchors.rightMargin: 12 * root.dp1
            spacing: 0
            Text { Layout.preferredWidth: 60 * root.dp1; text: pb.label; color: root.dimColor; font.pixelSize: 14 * root.dp1; elide: Text.ElideRight }
            T.TextField {
                id: pbField
                Layout.preferredWidth: Math.max(10 * root.dp1, contentWidth + 2 * root.dp1)
                Layout.fillHeight: true
                padding: 0
                verticalAlignment: TextInput.AlignVCenter
                color: root.textColor
                selectionColor: root.accentSurface
                font.pixelSize: 14 * root.dp1
                text: String(pb.value)
                validator: IntValidator { bottom: 0; top: 10000 }
                background: null
                onEditingFinished: pb.edited(parseInt(text) || 0)
            }
            Text { Layout.leftMargin: 3 * root.dp1; text: "px"; color: root.faintColor; font.pixelSize: 14 * root.dp1 }
            Item { Layout.fillWidth: true }
        }
    }

    // small text button of a row (Figma "Button": well with a ring)
    component SmallButton: T.Button {
        id: smallButton
        implicitWidth: Math.max(72 * root.dp1, contentItem.implicitWidth + 28 * root.dp1)
        implicitHeight: 32 * root.dp1
        background: Rectangle {
            radius: 6 * root.dp1
            color: root.wellColor
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2 * root.dp1
                radius: 4 * root.dp1
                color: smallButton.hovered ? root.cardColor : root.ringColor
            }
        }
        contentItem: Text {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: smallButton.text
            color: root.textColor
            font.pixelSize: 14 * root.dp1
        }
    }

    component LinkButton: T.Button {
        id: link
        implicitWidth: 30 * root.dp1
        implicitHeight: 33 * root.dp1
        background: null
        contentItem: Text {
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: VLCIcons.fontFamily
            font.pixelSize: 15 * root.dp1
            text: VLCIcons.link
            color: link.checked ? root.accentColor : root.textColor
        }
    }

    // dropdown bound to an option with choices; "None" entry for modules
    // Dropdown over a VLC object variable (VLCVarChoiceModel): the choice
    // applies to the current playback and is not saved in the preferences.
    component VarChoiceDropdown: T.Button {
        id: vd
        property var model: null
        property int _revision: 0
        readonly property int count: { _revision; return model ? model.rowCount() : 0 }
        readonly property int currentIndex: {
            _revision
            for (let i = 0; i < count; ++i) {
                if (model.data(model.index(i, 0), Qt.CheckStateRole))
                    return i
            }
            return -1
        }

        function itemText(i) {
            return model.data(model.index(i, 0), Qt.DisplayRole)
        }

        Connections {
            target: vd.model
            function onDataChanged() { vd._revision++ }
            function onModelReset() { vd._revision++ }
            function onRowsInserted() { vd._revision++ }
            function onRowsRemoved() { vd._revision++ }
        }

        implicitHeight: 48 * root.dp1
        leftPadding: 16 * root.dp1
        rightPadding: 16 * root.dp1
        background: Rectangle {
            radius: 6 * root.dp1
            color: root.wellColor
            Rectangle { anchors.fill: parent; anchors.margins: 2 * root.dp1; radius: 4 * root.dp1; color: vd.hovered ? root.cardColor : root.ringColor }
        }
        contentItem: RowLayout {
            Text {
                Layout.fillWidth: true
                                text: vd.currentIndex >= 0 ? vd.itemText(vd.currentIndex) : ""
                color: root.textColor
                font.pixelSize: 14 * root.dp1
                elide: Text.ElideRight
            }
            Chevron {}
        }
        onClicked: {
            const items = []
            for (let i = 0; i < count; ++i)
                items.push({ "text": itemText(i), "checked": i === currentIndex })
            varMenu.popup(mapToGlobal(0, height + 4 * root.dp1), items)
        }

        StringListMenu {
            id: varMenu
            ctx: MainCtx
            onSelected: (index, _) => vd.model.toggleIndex(index)
        }
    }

    component Dropdown: T.Button {
        id: dd
        property string option
        property string noneText: ""
        property bool audio: false
        property bool video: false
        // a choice was made (already saved)
        signal picked(var value)
        readonly property var choices: VLCConfig.choices(option)
        property var current: audio ? VLCEffects.audioValue(option) : video ? VLCEffects.videoValue(option) : VLCConfig.value(option)

        implicitHeight: 48 * root.dp1
        leftPadding: 16 * root.dp1
        rightPadding: 16 * root.dp1
        background: Rectangle {
            radius: 6 * root.dp1
            color: root.wellColor
            Rectangle { anchors.fill: parent; anchors.margins: 2 * root.dp1; radius: 4 * root.dp1; color: dd.hovered ? root.cardColor : root.ringColor }
        }
        contentItem: RowLayout {
            Text {
                Layout.fillWidth: true
                text: {
                    const found = dd.choices.find((c) => String(c.value) === String(dd.current))
                    if (found && found.value !== "" && found.value !== "any")
                        return found.text
                    return dd.noneText !== "" ? dd.noneText : (found?.text ?? String(dd.current))
                }
                color: root.textColor
                font.pixelSize: 14 * root.dp1
                elide: Text.ElideRight
            }
            Chevron {}
        }
        onClicked: menu.popup(mapToGlobal(0, height + 4 * root.dp1),
                              choices.map((c) => ({ "text": c.text, "checked": String(c.value) === String(current) })))

        StringListMenu {
            id: menu
            ctx: MainCtx
            onSelected: (index, _) => {
                const value = dd.choices[index].value
                if (dd.audio) VLCEffects.setAudioValue(dd.option, value)
                else if (dd.video) VLCEffects.setVideoValue(dd.option, value)
                else VLCConfig.setValue(dd.option, value)
                dd.current = value
                dd.picked(value)
            }
        }
    }

    // "Local" and the renderers found so far; looks for renderers while the
    // page is shown, like VLC's Playback > Renderer menu while it is open
    component RendererDropdown: T.Button {
        id: rd
        readonly property var manager: Player.rendererManager
        property int _revision: 0
        readonly property var names: {
            _revision
            const list = []
            for (let i = 0; i < manager.rowCount(); ++i)
                list.push(manager.data(manager.index(i, 0), Qt.DisplayRole))
            return list
        }
        readonly property int selected: {
            _revision
            for (let i = 0; i < manager.rowCount(); ++i)
                if (manager.data(manager.index(i, 0), Qt.CheckStateRole) == Qt.Checked)
                    return i
            return -1
        }

        Connections {
            target: rd.manager
            function onDataChanged() { rd._revision++ }
            function onModelReset() { rd._revision++ }
            function onRowsInserted() { rd._revision++ }
            function onRowsRemoved() { rd._revision++ }
            function onUseRendererChanged() { rd._revision++ }
        }
        // the scan stops by itself after 20 s
        onVisibleChanged: if (visible) manager.StartScan()

        implicitHeight: 48 * root.dp1
        leftPadding: 16 * root.dp1
        rightPadding: 16 * root.dp1
        background: Rectangle {
            radius: 6 * root.dp1
            color: root.wellColor
            Rectangle { anchors.fill: parent; anchors.margins: 2 * root.dp1; radius: 4 * root.dp1; color: rd.hovered ? root.cardColor : root.ringColor }
        }
        contentItem: RowLayout {
            Text {
                Layout.fillWidth: true
                                text: rd.selected >= 0 ? rd.names[rd.selected] : qsTr("Local")
                color: root.textColor
                font.pixelSize: 14 * root.dp1
                elide: Text.ElideRight
            }
            Chevron {}
        }
        onClicked: {
            manager.StartScan()
            const items = [{ "text": qsTr("Local"), "checked": selected < 0 }]
            for (let i = 0; i < names.length; ++i)
                items.push({ "text": names[i], "checked": i === selected })
            rendererMenu.popup(mapToGlobal(0, height + 4 * root.dp1), items)
        }

        StringListMenu {
            id: rendererMenu
            ctx: MainCtx
            onSelected: (index, _) => {
                if (index === 0) {
                    if (rd.selected >= 0)
                        rd.manager.setData(rd.manager.index(rd.selected, 0), false, Qt.CheckStateRole)
                } else {
                    rd.manager.setData(rd.manager.index(index - 1, 0), true, Qt.CheckStateRole)
                }
            }
        }
    }

    // pauses playback after a delay (VLCEffects keeps the timer running)
    component SleepTimer: T.Button {
        id: st
        readonly property var minutes: [0, 15, 30, 45, 60, 90, 120]
        function label(m) { return m === 0 ? qsTr("Off") : qsTr("%1 min").arg(m) }

        implicitHeight: 48 * root.dp1
        leftPadding: 16 * root.dp1
        rightPadding: 16 * root.dp1
        background: Rectangle {
            radius: 6 * root.dp1
            color: root.wellColor
            Rectangle { anchors.fill: parent; anchors.margins: 2 * root.dp1; radius: 4 * root.dp1; color: st.hovered ? root.cardColor : root.ringColor }
        }
        contentItem: RowLayout {
            Text {
                Layout.fillWidth: true
                                text: st.label(VLCEffects.sleepMinutes)
                color: root.textColor
                font.pixelSize: 14 * root.dp1
            }
            Chevron {}
        }
        onClicked: sleepMenu.popup(mapToGlobal(0, height + 4 * root.dp1),
                                   minutes.map((m) => ({ "text": label(m), "checked": m === VLCEffects.sleepMinutes })))

        StringListMenu {
            id: sleepMenu
            ctx: MainCtx
            onSelected: (index, _) => VLCEffects.setSleepTimer(st.minutes[index])
        }
    }

    component EqualizerPreset: T.Button {
        id: eqp
        readonly property var presets: VLCEffects.equalizerPresets()
        property bool enabledEq: VLCEffects.audioFilterEnabled("equalizer")
        property string preset: String(VLCEffects.audioValue("equalizer-preset") ?? "")

        implicitHeight: 48 * root.dp1
        leftPadding: 16 * root.dp1
        rightPadding: 16 * root.dp1
        background: Rectangle {
            radius: 6 * root.dp1
            color: root.wellColor
            Rectangle { anchors.fill: parent; anchors.margins: 2 * root.dp1; radius: 4 * root.dp1; color: eqp.hovered ? root.cardColor : root.ringColor }
        }
        contentItem: RowLayout {
            Text {
                Layout.fillWidth: true
                                text: eqp.enabledEq ? (eqp.presets.find((p) => p.name === eqp.preset)?.text ?? qsTr("Custom")) : qsTr("None")
                color: root.textColor
                font.pixelSize: 14 * root.dp1
            }
            Chevron {}
        }
        onClicked: presetMenu.popup(mapToGlobal(0, height + 4 * root.dp1),
            [{ "text": qsTr("None"), "checked": !enabledEq }].concat(
                // Figma EQ preset icons (:/menu/figma/eq_<preset>.svg)
                presets.map((p) => ({ "text": p.text, "icon": "eq_" + p.name,
                                      "checked": enabledEq && p.name === preset }))))

        StringListMenu {
            id: presetMenu
            ctx: MainCtx
            onSelected: (index, _) => {
                if (index === 0) {
                    VLCEffects.setAudioFilterEnabled("equalizer", false)
                    eqp.enabledEq = false
                    return
                }
                const name = eqp.presets[index - 1].name
                VLCEffects.applyEqualizerPreset(name)
                VLCEffects.setAudioFilterEnabled("equalizer", true)
                eqp.enabledEq = true
                eqp.preset = name
            }
        }
    }

    // "Expand Settings >" / "Collapse Settings v" card (Figma effect
    // settings): 48 px Dark/BG/B2 bar, Dark/BG/A3 card while open
    component Card: Rectangle {
        id: card
        default property alias cardContent: inner.data
        property alias contentSpacing: inner.spacing
        property bool expanded: false
        Layout.fillWidth: true
        implicitHeight: header.height + (expanded ? inner.implicitHeight + 30 * root.dp1 : 0)
        radius: 6 * root.dp1
        color: expanded ? root.openCardColor : header.hovered ? root.wellHoverColor : root.wellColor

        T.Button {
            id: header
            width: parent.width
            height: 48 * root.dp1
            leftPadding: 16 * root.dp1
            rightPadding: 10 * root.dp1
            background: null
            contentItem: RowLayout {
                Text {
                    Layout.fillWidth: true
                    text: card.expanded ? qsTr("Collapse Settings") : qsTr("Expand Settings")
                    color: root.dimColor
                    font.pixelSize: 14 * root.dp1
                }
                Chevron {
                    text: card.expanded ? VLCIcons.chevron_down : VLCIcons.breadcrumb_sep
                    color: root.dimColor
                }
            }
            onClicked: card.expanded = !card.expanded
        }

        ColumnLayout {
            id: inner
            visible: card.expanded
            anchors { left: parent.left; right: parent.right; top: header.bottom
                      topMargin: 10 * root.dp1; leftMargin: 16 * root.dp1; rightMargin: 16 * root.dp1 }
            spacing: 20 * root.dp1
        }
    }

    // an audio filter: name + ON/OFF, then its card
    component AudioEffect: ColumnLayout {
        id: effect
        property string label
        property string module
        default property alias effectContent: effectCard.cardContent
        Layout.fillWidth: true
        visible: VLCConfig.moduleExists(module)
        spacing: 8 * root.dp1
        Row2 {
            label: effect.label
            Switch {
                checked: VLCEffects.audioFilterEnabled(effect.module)
                onToggled: VLCEffects.setAudioFilterEnabled(effect.module, checked)
            }
        }
        Card { id: effectCard }
    }
}
