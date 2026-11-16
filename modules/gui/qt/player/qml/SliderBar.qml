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
import QtQuick.Templates as T
import QtQuick.Layouts

import VLC.Player
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util
import VLC.MainInterface

T.ProgressBar {
    id: control

    // "Track" style from the VLC Redesign Figma file: a tall rounded track,
    // played part filled with the dim accent background, and a thin
    // always-visible accent playhead instead of the round hover handle.
    property bool trackStyle: false
    readonly property int trackRadius: VLCStyle.dp(6, VLCStyle.scale)
    readonly property int playheadWidth: VLCStyle.dp(4, VLCStyle.scale)
    readonly property int playheadMargin: VLCStyle.dp(2, VLCStyle.scale)

    readonly property real _hoveredScalingFactor: trackStyle ? 1.0 : 1.8
    property int barHeight: VLCStyle.dp(5, VLCStyle.scale)
    readonly property real _scaledBarHeight: control.barHeight * _hoveredScalingFactor
    readonly property real _scaledY: (-control.barHeight / 2) * (control._hoveredScalingFactor - 1)

    property bool _isSeekPointsShown: true
    readonly property int _seekPointsDistance: VLCStyle.dp(2, VLCStyle.scale)
    readonly property int _seekPointsRadius: trackStyle ? trackRadius : VLCStyle.dp(0.5, VLCStyle.scale)
    // Played part of the track: the accent over the track color. Derived
    // from the accent rather than a palette role so that it also works with
    // system/external palettes (Figma: BG/Accent Bright, about 24% / 35%).
    readonly property color _progressColor: trackStyle ? Qt.alpha(theme.fg.primary, (theme.palette?.isDark ?? true) ? 0.24 : 0.35)
                                                       : theme.fg.primary
    readonly property real _scaledSeekPointsRadius: _seekPointsRadius * _hoveredScalingFactor

    property bool _currentChapterHovered: false
    property real _tooltipPosition: (Widgets.PointingToolTipAttached.instance?.pos.x ?? 0.0) / width

    property color backgroundColor: theme.bg.primary
    property real touchHandlerMargin: VLCStyle.touchHandlerMargin

    // VLC Redesign subtitle timeline (Playback tab switch), shown in track
    // style when the subtitle file of the selected track could be read
    property bool subtitleTimelineEnabled: false
    property var subtitleCues: []
    readonly property bool timelineActive: trackStyle && subtitleTimelineEnabled && subtitleCues.length > 0
    readonly property real timelineStart: timelineLoader.item?.windowStart ?? 0
    readonly property real timelineEnd: timelineLoader.item?.windowEnd ?? 0

    function _readTimelineSetting() {
        subtitleTimelineEnabled = String(VLCConfig.uiValue("Player/SubtitleTimeline", false)) === "true"
        const preview = VLCConfig.uiValue("Player/SeekPreview", true)
        previewSetting = !(preview === false || preview === "false")
    }

    Component.onCompleted: {
        value = Player.position
        _readTimelineSetting()
    }

    Connections {
        target: VLCConfig
        function onUiValueChanged(key) {
            if (key === "" || key === "Player/SubtitleTimeline" || key === "Player/SeekPreview")
                control._readTimelineSetting()
        }
    }

    onSubtitleTimelineEnabledChanged: cueReload.restart()

    // the cues are read again when the media or the subtitle track changes
    Timer {
        id: cueReload
        interval: 300
        onTriggered: {
            if (!control.trackStyle || !control.subtitleTimelineEnabled) {
                control.subtitleCues = []
                return
            }
            control.subtitleCues = SubtitleCues.load().cues ?? []
        }
    }

    Connections {
        target: Player.subtitleTracks
        enabled: control.subtitleTimelineEnabled
        function onDataChanged() { cueReload.restart() }
        function onModelReset() { cueReload.restart() }
        function onRowsInserted() { cueReload.restart() }
        function onRowsRemoved() { cueReload.restart() }
    }

    // waveform of audio files (VLC Redesign "waveform" seek bar): local
    // audio-only media, decoded in the background by AudioWaveform
    readonly property bool _waveFile: trackStyle && !Player.hasVideoOutput && Player.audioTracks.count > 0
                                      && String(Player.url).startsWith("file:")
    readonly property bool waveformActive: _waveFile && !timelineActive && Player.length.valid()
                                           && AudioWaveform.mrl === String(Player.url)
    readonly property int _waveStep: VLCStyle.dp(5, VLCStyle.scale)
    readonly property int _waveBarCount: Math.max(0, Math.floor((availableWidth - 2 * _waveStep) / _waveStep))
    property var _waveLevels: []

    function _updateWave() {
        _waveLevels = waveformActive ? AudioWaveform.levels(_waveBarCount, Player.length.toMilliseconds()) : []
    }

    on_WaveFileChanged: waveStart.restart()
    onWaveformActiveChanged: _updateWave()
    on_WaveBarCountChanged: _updateWave()

    // wait until the tracks are known (a video only gets its video output
    // after a moment)
    Timer {
        id: waveStart
        interval: 1000
        onTriggered: {
            if (control._waveFile)
                AudioWaveform.load(String(Player.url))
            else if (control.trackStyle)
                AudioWaveform.clear()
        }
    }

    Connections {
        target: Player
        function onUrlChanged() { waveStart.restart() }
    }

    Connections {
        target: AudioWaveform
        function onLevelsChanged() { control._updateWave() }
    }

    // seek preview thumbnails (VLC Redesign): video files only
    // "Thumbnail" bar button (ThumbnailButton.qml), on unless turned off
    property bool previewSetting: true
    readonly property bool _previewEnabled: trackStyle && !timelineActive && Player.hasVideoOutput && previewSetting
                                            && String(Player.url).startsWith("file:")
    readonly property real _hoverMs: {
        if (!hoverHandler.hovered || !Player.length.valid())
            return -1
        const x = Helpers.clamp(hoverHandler.point.position.x, 0, control.availableWidth)
        return Player.length.toMilliseconds() * x / Math.max(1, control.availableWidth)
    }

    // one frame per second at most, fewer for long media
    readonly property real _previewStep: Math.max(1000, Math.round(Player.length.toMilliseconds() / 400 / 1000) * 1000)

    Timer {
        id: previewRequest
        interval: 120
        onTriggered: {
            if (control._hoverMs < 0)
                return
            const step = control._previewStep
            SeekPreview.request(String(Player.url), Math.round(control._hoverMs / step) * step)
        }
    }

    on_HoverMsChanged: {
        if (_previewEnabled && _hoverMs >= 0)
            previewRequest.restart()
    }

    Keys.onRightPressed: Player.jumpFwd()
    Keys.onLeftPressed: Player.jumpBwd()

    Accessible.onIncreaseAction: Player.jumpFwd()
    Accessible.onDecreaseAction: Player.jumpBwd()

    function showChapterMarks() {
        _isSeekPointsShown = true
        seekpointTimer.restart()
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Slider

        enabled: control.enabled
        focused: control.visualFocus
        hovered: hoverHandler.hovered
    }

    Timer {
        id: seekpointTimer
        running: Player.hasChapters && !hoverHandler.hovered && _isSeekPointsShown
        interval: 3000
        onTriggered: control._isSeekPointsShown = false
    }

    Widgets.PointingToolTipAttached.visible: (hoverHandler.hovered || control.visualFocus || dragHandler.active)
                                             && !control.timelineActive && !previewCard.visible

    Widgets.PointingToolTipAttached.text: {
        if (!Widgets.PointingToolTipAttached.instance?.visible)
            return ""

        let _text

        const length = Player.length
        if (hoverHandler.hovered)
            _text = length.scale(Widgets.PointingToolTipAttached.instance.pos.x / control.width)
        else
            _text = Player.time

        _text = _text.formatHMS(length.isSubSecond() ? VLCTick.SubSecondFormattedAsMS : 0)

        if (Player.hasChapters)
            _text += " - " + Player.chapters.getNameAtPosition(control._tooltipPosition)

        return _text
    }

    Widgets.PointingToolTipAttached.pos: Qt.point(hoverHandler.hovered ? Helpers.clamp(hoverHandler.point.position.x, 0, control.availableWidth)
                                                                       : (control.visualPosition * control.width), 0)

    FSM {
        id: fsm
        signal playerUpdatePosition(real position)
        signal pressControl(real position, bool forcePrecise)
        signal releaseControl(real position, bool forcePrecise)
        signal moveControl(real position, bool forcePrecise)
        signal inputChanged()

        //each signal is associated to a key, when a signal is received,
        //transitions of active state for the given key are evaluated
        signalMap: ({
            "playerUpdatePosition": fsm.playerUpdatePosition,
            "pressControl": fsm.pressControl,
            "releaseControl": fsm.releaseControl,
            "moveControl": fsm.moveControl,
            "inputChanged": fsm.inputChanged
        })

        initialState: fsmReleased

        function _setPositionFromValue(position) {
            control.value = position
        }

        function _seekToPosition(position, threshold, forcePrecise) {
            position = Helpers.clamp(position, 0., 1.)
            control.value = position
            if (!forcePrecise) {
                const chapter = Player.chapters.getClosestChapterFromPos(position, threshold)
                if (chapter !== -1) {
                    Player.chapters.selectChapter(chapter)
                    return
                }
            }
            Player.position = position
        }

        FSMState {
            id: fsmReleased

            transitions: ({
                "playerUpdatePosition": {
                    action: (position) => {
                        control.value = position
                    }
                },
                "pressControl": {
                    action: (position, forcePrecise) => {
                        control.forceActiveFocus()
                        fsm._seekToPosition(position, VLCStyle.dp(4, VLCStyle.scale) / control.width, forcePrecise)
                    },
                    target: fsmHeld
                }
            })
        }

        FSMState  {
            id: fsmHeld

            transitions: ({
                "moveControl": {
                    action: (position, forcePrecise) => {
                        fsm._seekToPosition(position, VLCStyle.dp(2, VLCStyle.scale) / control.width, forcePrecise)
                    }
                },
                "releaseControl": {
                    target: fsmReleased
                },
                "inputChanged": {
                    target: fsmHeldWrongInput
                }
            })
        }

        FSMState  {
            id: fsmHeldWrongInput

            function enter() {
                fsm._setPositionFromValue(Player.position)
            }

            transitions: ({
                "playerUpdatePosition": {
                    action: fsm._setPositionFromValue
                },
                "releaseControl": {
                    target: fsmReleased
                }
            })
        }
    }

    Connections {
        target: Player
        function onPositionChanged() {  fsm.playerUpdatePosition(Player.position) }
        function onInputChanged() {
            fsm.inputChanged()
            SeekPreview.clear()
            cueReload.restart()
        }
    }

    implicitHeight: control.barHeight
    height: implicitHeight

    padding: 0

    //we use our own HoverHandler
    hoverEnabled: false

    HoverHandler {
        id: hoverHandler

        onHoveredChanged: () => {
            if (hovered) {
                if(Player.hasChapters)
                    control._isSeekPointsShown = true
            } else {
                if(Player.hasChapters)
                    seekpointTimer.restart()
            }
        }
    }

    contentItem: Item {
        implicitHeight: control.implicitHeight
        implicitWidth: control.implicitWidth

        //placing the TapHandler directly in the Control doesn't work with 6.2
        TapHandler {
            acceptedButtons: Qt.LeftButton

            gesturePolicy: TapHandler.WithinBounds

            // Make it easier to tap with touch screen:
            margin: MainCtx.usingTouch ? control.touchHandlerMargin : 0.0

            onPressedChanged: {
                if (pressed) {
                    fsm.pressControl(point.position.x / control.width, point.modifiers === Qt.ShiftModifier)
                } else {
                    // NOTE: Point is still valid at this point.
                    fsm.releaseControl(point.position.x / control.width, point.modifiers === Qt.ShiftModifier)
                }
            }
        }

        DragHandler {
            id: dragHandler
            acceptedButtons: Qt.LeftButton

            // Make it easier to drag with touch screen:
            margin: MainCtx.usingTouch ? control.touchHandlerMargin : 0

            target: null
            dragThreshold: 0
            grabPermissions: PointerHandler.CanTakeOverFromAnything

            property bool filterEvents: false

            function moveControl() {
                fsm.moveControl(dragHandler.centroid.position.x / control.width,
                                dragHandler.centroid.modifiers === Qt.ShiftModifier)
            }

            onActiveChanged: {
                if (active) {
                    filterEvents = false
                    fsm.pressControl(centroid.position.x / control.width, centroid.modifiers === Qt.ShiftModifier)
                } else {
                    fsm.releaseControl( centroid.position.x / control.width, centroid.modifiers === Qt.ShiftModifier)
                }
            }

            onCentroidChanged: {
                // FIXME: Qt 6.5 use xAxis.onActiveValueChanged in the DragHandler
                if (filterEvents) {
                    Qt.callLater(dragHandler.moveControl)
                } else {
                    dragHandler.moveControl()
                    filterEvents = true
                }
            }
        }

        WheelHandler {
            orientation: Qt.Vertical | Qt.Horizontal

            acceptedDevices: PointerDevice.AllDevices

            onWheel: (wheel) => {
                wheelToVLC.qmlWheelEvent(wheel)
                wheel.accepted = true
            }
        }

        WheelToVLCConverter {
            id: wheelToVLC

            function handleVertical(steps: int) {
                if (steps > 0)
                    Player.jumpFwd()
                else
                    Player.jumpBwd()
            }

            function handleHorizontal(steps: int) {
                if (steps > 0)
                    Player.jumpBwd()
                else
                    Player.jumpFwd()
            }

            Component.onCompleted: {
                wheelUpDown.connect(wheelToVLC, wheelToVLC.handleVertical)
                wheelLeftRight.connect(wheelToVLC, wheelToVLC.handleHorizontal)
            }
        }
    }

    background: Item {
        width: control.availableWidth
        implicitHeight: control.implicitHeight
        height: implicitHeight

        Rectangle {
            id: sliderRect
            visible: !Player.hasChapters
            color: control.backgroundColor
            anchors.fill: parent
            radius: control.trackStyle ? control.trackRadius : implicitHeight
        }

        Repeater {
            id: seekpointsRptr

            anchors.left: parent.left
            anchors.right: parent.right
            height: control.barHeight
            visible: Player.hasChapters

            model: Player.chapters
            Item {
                Rectangle {
                    id: seekpointsRect
                    readonly property real startPosition: model.startPosition ??  0.0
                    readonly property real endPosition: model.endPosition ?? 1.0

                    readonly property int _currentChapter: {
                        if (control.visualPosition < seekpointsRect.startPosition)
                            return 1
                        else if (control.visualPosition > seekpointsRect.endPosition)
                            return -1
                        return 0
                    }
                    on_CurrentChapterChanged: {
                        if(_hovered)
                            control._currentChapterHovered = _currentChapter === 0
                    }

                    readonly property bool _hovered: hoverHandler.hovered &&
                                            (hoverHandler.point.position.x > x && hoverHandler.point.position.x < x+width)

                    color: _currentChapter < 0 ? control._progressColor : control.backgroundColor
                    width: sliderRect.width * seekpointsRect.endPosition - x - control._seekPointsDistance
                    x: sliderRect.width * seekpointsRect.startPosition

                    Rectangle {
                        id: progressRepRect
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        radius: parent.radius

                        width: sliderRect.width * control.visualPosition - parent.x - control._seekPointsDistance
                        visible: parent._currentChapter === 0
                        color: control._progressColor

                        // We use dynamic mutability group because time interpolation
                        // may induce rapid change:
                        // TODO: Do not use `Binding` when minimum Qt is 6.12:
                        Binding {
                            target: progressRepRect
                            property: "mutabilityGroup"
                            when: (progressRepRect.mutabilityGroup !== undefined)
                            value: (Player.playingState === Player.PLAYING_STATE_PLAYING) ? Item.DynamicMutabilityGroup
                                                                                          : Item.StaticMutabilityGroup
                        }
                    }
                }

                transitions: [
                    Transition {
                        to: "*"
                        SequentialAnimation{
                            PropertyAction { targets: control; property: "_currentChapterHovered" }
                            NumberAnimation {
                                targets: [seekpointsRect, progressRepRect]; properties: "height, y, radius"
                                duration: VLCStyle.duration_short; easing.type: Easing.InSine
                            }
                        }
                    }
                ]

                states:[
                    State {
                        name: "visible"
                        PropertyChanges {
                            target: control;
                            _currentChapterHovered: seekpointsRect._currentChapter === 0 ? false : control._currentChapterHovered
                        }
                        PropertyChanges { target: seekpointsRect; height: control.barHeight }
                        PropertyChanges { target: seekpointsRect; y: 0 }
                        PropertyChanges { target: seekpointsRect; radius: control._seekPointsRadius }
                    },
                    State {
                        name: "visibleLarge"
                        PropertyChanges {
                            target: control;
                            _currentChapterHovered: seekpointsRect._currentChapter === 0 ? true : control._currentChapterHovered
                        }
                        PropertyChanges { target: seekpointsRect; height: control._scaledBarHeight }
                        PropertyChanges { target: seekpointsRect; y: control._scaledY }
                        PropertyChanges { target: seekpointsRect; radius: control._scaledSeekPointsRadius }
                    }
                ]

                state: (seekpointsRect._hovered || (seekpointsRect._currentChapter === 0 && fsm._state === fsm.fsmHeld))
                       ? "visibleLarge"
                       : "visible"
            }
        }

        Rectangle {
            id: progressRect
            width: control.visualPosition * parent.width
            visible: !Player.hasChapters && !control.waveformActive
            color: control._progressColor
            height: control.barHeight
            radius: control._seekPointsRadius

            // We use dynamic mutability group because time interpolation
            // may induce rapid change:
            // TODO: Do not use `Binding` when minimum Qt is 6.12:
            Binding {
                target: progressRect
                property: "mutabilityGroup"
                when: (progressRect.mutabilityGroup !== undefined)
                value: (Player.playingState === Player.PLAYING_STATE_PLAYING) ? Item.DynamicMutabilityGroup
                                                                              : Item.StaticMutabilityGroup
            }
        }

        // waveform: grey bars, and the same bars in the accent colour up to
        // the playhead (Figma "waveform" seek bar)
        Item {
            anchors.fill: parent
            visible: control.waveformActive

            component WaveBars: Repeater {
                id: bars
                property color barColor
                model: control._waveLevels
                Rectangle {
                    required property int index
                    required property var modelData
                    readonly property real maxHeight: control.barHeight - 4 * control.playheadMargin
                    width: VLCStyle.dp(2, VLCStyle.scale)
                    height: modelData < 0 ? width : Math.max(width, maxHeight * modelData)
                    radius: width / 2
                    x: control._waveStep * (index + 1)
                    y: (control.barHeight - height) / 2
                    color: modelData < 0 ? Qt.alpha(bars.barColor, 0.3) : bars.barColor
                }
            }

            WaveBars {
                barColor: Qt.alpha(theme.fg.secondary, 0.5)
            }

            Item {
                width: control.visualPosition * parent.width
                height: parent.height
                clip: true

                WaveBars {
                    barColor: theme.fg.primary
                }
            }
        }

        Rectangle {
            id: bufferRect
            property int bufferAnimWidth: VLCStyle.dp(100, VLCStyle.scale)
            property int bufferAnimPosition: 0
            property int bufferFrames: 1000
            property alias animateLoading: loadingAnim.running
            property bool display: false
            property bool buffering: Player.buffering > 0 && Player.buffering < 1

            height: control.barHeight
            opacity: 0.4
            color: theme.fg.neutral //FIXME buffer color ?
            radius: control.trackStyle ? control.trackRadius : control.barHeight

            // TODO: Do not use `Binding` when minimum Qt is 6.12:
            Binding {
                target: bufferRect
                property: "mutabilityGroup"
                when: bufferRect.mutabilityGroup !== undefined
                value: bufferRect.buffering ? Item.DynamicMutabilityGroup
                                            : Item.StaticMutabilityGroup
            }

            Timer {
                id: bufferingTimer
                interval: VLCStyle.duration_humanMoment
                repeat: false
                running: false
                onTriggered: {
                    bufferRect.display = true
                }
            }

            onBufferingChanged: {
                if(buffering)
                {
                    bufferingTimer.start()
                }
                else
                {
                    bufferingTimer.stop()
                    bufferRect.display = false
                }
            }

            states: [
                State {
                    name: "hidden"
                    when: !control.visible
                    PropertyChanges {
                        target: bufferRect
                        width: bufferAnimWidth
                        visible: false
                        x: 0
                        animateLoading: false
                    }
                },
                State {
                    name: "buffering not started"
                    // not in Customize Player opened without media
                    when: control.visible && Player.buffering === 0
                          && !(MainCtx.playerCustomizing && Player.playingState === Player.PLAYING_STATE_STOPPED)
                    PropertyChanges {
                        target: bufferRect
                        width: bufferAnimWidth
                        visible: true
                        x: (bufferAnimPosition / bufferFrames) * (parent.width - bufferAnimWidth)
                        animateLoading: true
                    }
                },
                State {
                    name: "time to start playing known"
                    when: control.visible && bufferRect.display
                    PropertyChanges {
                        target: bufferRect
                        width: Player.buffering * parent.width
                        visible: true
                        x: 0
                        animateLoading: false
                    }
                },
                State {
                    name: "playing from buffer"
                    when: control.visible && !bufferRect.display
                    PropertyChanges {
                        target: bufferRect
                        width: Player.buffering * parent.width
                        visible: false
                        x: 0
                        animateLoading: false
                    }
                }
            ]

            SequentialAnimation on bufferAnimPosition {
                id: loadingAnim
                running: bufferRect.animateLoading
                loops: Animation.Infinite
                PropertyAnimation {
                    from: 0.0
                    to: bufferRect.bufferFrames
                    duration: VLCStyle.durationSliderBouncing
                    easing.type: "OutBounce"
                }
                PauseAnimation {
                    duration: VLCStyle.duration_veryLong
                }
                PropertyAnimation {
                    from: bufferRect.bufferFrames
                    to: 0.0
                    duration: VLCStyle.durationSliderBouncing
                    easing.type: "OutBounce"
                }
                PauseAnimation {
                    duration: VLCStyle.duration_veryLong
                }
            }
        }
    }

    Rectangle {
        id: sliderHandle

        property int _size: control.barHeight * 3

        x: (control.visualPosition * control.availableWidth) - width / 2
        y: (control.barHeight - height) / 2

        implicitWidth: sliderHandle._size
        implicitHeight: sliderHandle._size
        radius: VLCStyle.margin_small
        color: theme.fg.primary

        // Replaced by trackPlayhead in track style. The state machine below
        // toggles `visible` itself, so hide through opacity instead.
        opacity: control.trackStyle ? 0.0 : 1.0

        // We use dynamic mutability group because time interpolation
        // may induce rapid change:
        // TODO: Do not use `Binding` when minimum Qt is 6.12:
        Binding {
            target: sliderHandle
            property: "mutabilityGroup"
            when: (sliderHandle.mutabilityGroup !== undefined)
            value: (Player.playingState === Player.PLAYING_STATE_PLAYING) ? Item.DynamicMutabilityGroup
                                                                          : Item.StaticMutabilityGroup
        }

        transitions: [
            Transition {
                to: "hidden"
                SequentialAnimation {
                    NumberAnimation {
                        target: sliderHandle; properties: "implicitWidth,implicitHeight"
                        to: 0
                        duration: VLCStyle.duration_short; easing.type: Easing.OutSine
                    }
                    PropertyAction { target: sliderHandle; property: "visible"; value: false; }
                }
            },
            Transition {
                to: "visible"
                SequentialAnimation {
                    PropertyAction { target: sliderHandle; property: "visible"; value: true; }
                    NumberAnimation {
                        target: sliderHandle; properties: "implicitWidth,implicitHeight"
                        to: sliderHandle._size
                        duration: VLCStyle.duration_short; easing.type: Easing.InSine
                    }
                }
            },
            Transition {
                to: "visibleLarge"
                SequentialAnimation {
                    PropertyAction { target: sliderHandle; property: "visible"; value: true; }
                    NumberAnimation {
                        target: sliderHandle; properties: "implicitWidth,implicitHeight"
                        to: sliderHandle._size * (0.8 * control._hoveredScalingFactor)
                        duration: VLCStyle.duration_short; easing.type: Easing.InSine
                    }
                }
            }
        ]

        state: (!control.trackStyle && (hoverHandler.hovered || control.visualFocus))
               ? ((control._currentChapterHovered || (Player.hasChapters && fsm._state === fsm.fsmHeld)) ? "visibleLarge" : "visible")
               : "hidden"
    }

    // Track style playhead: thin accent pill, always visible, inset by
    // playheadMargin from the top and bottom of the track.
    Rectangle {
        id: trackPlayhead

        visible: control.trackStyle

        width: control.playheadWidth
        height: Math.max(0, control.barHeight - 2 * control.playheadMargin)

        x: Helpers.clamp((control.visualPosition * control.availableWidth) - width / 2,
                         0, control.availableWidth - width)
        y: control.playheadMargin

        radius: control.playheadWidth
        color: theme.fg.primary

        // Keyboard focus is otherwise invisible in track style, as the
        // round handle that used to signal it is hidden.
        border.width: control.visualFocus ? VLCStyle.focus_border : 0
        border.color: theme.visualFocus

        // TODO: Do not use `Binding` when minimum Qt is 6.12:
        Binding {
            target: trackPlayhead
            property: "mutabilityGroup"
            when: (trackPlayhead.mutabilityGroup !== undefined)
            value: (Player.playingState === Player.PLAYING_STATE_PLAYING) ? Item.DynamicMutabilityGroup
                                                                          : Item.StaticMutabilityGroup
        }
    }

    // subtitle timeline over the bar
    Loader {
        id: timelineLoader

        anchors.fill: parent
        z: 10
        active: control.timelineActive

        sourceComponent: SubtitleTimeline {
            cues: control.subtitleCues
            radius: control.trackRadius
            trackColor: control.backgroundColor
            playedColor: control._progressColor
            accentColor: theme.fg.primary
            // Figma: white at 14 % (dark); no light frame, so black at 14 % (user's choice)
            cueColor: (theme.palette?.isDark ?? true) ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.14)
        }
    }

    // seek preview (Figma "thumbnail": 272 x 189 card, 252 x 142 frame for 16:9)
    Rectangle {
        id: previewCard

        readonly property real dp1: VLCStyle.dp(1, VLCStyle.scale)

        visible: control._previewEnabled && hoverHandler.hovered && SeekPreview.source !== ""
        z: 11

        // the card fits the frame: at most 252 x 142 (16:9), narrower or
        // lower for other aspect ratios (wide films, portrait videos)
        readonly property real _maxW: 252 * dp1
        readonly property real _maxH: 142 * dp1
        readonly property real _aspect: (previewImage.status === Image.Ready
                                         && previewImage.implicitWidth > 0 && previewImage.implicitHeight > 0)
                                        ? previewImage.implicitWidth / previewImage.implicitHeight
                                        : 16 / 9
        readonly property real _frameW: Math.round(Math.min(_maxW, _maxH * _aspect))
        readonly property real _frameH: Math.round(Math.min(_maxH, _maxW / _aspect))

        width: Math.max(_frameW + 20 * dp1, timeText.implicitWidth + 40 * dp1)
        height: _frameH + 47 * dp1
        radius: 14 * dp1
        color: Qt.alpha((theme.palette?.isDark ?? true) ? "#191919" : "#F0F0F0", 0.95)

        x: Helpers.clamp((hoverHandler.point.position.x) - width / 2, 0, Math.max(0, control.width - width))
        y: -height - 12 * dp1

        // Figma: frame with 4 px rounded corners
        Widgets.ImageExt {
            id: previewImage

            anchors.horizontalCenter: parent.horizontalCenter
            y: 10 * previewCard.dp1
            width: previewCard._frameW
            height: previewCard._frameH
            radius: 4 * previewCard.dp1
            // the frame already has the video's aspect ratio: crop away rounding gaps
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: false
            source: SeekPreview.source
            // dimmed while the frame of the hovered time is on its way
            opacity: Math.abs(SeekPreview.time - control._hoverMs) <= 1.5 * control._previewStep ? 1.0 : 0.5
        }

        Text {
            id: timeText

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10 * previewCard.dp1
            text: Player.length.scale(Math.max(0, control._hoverMs) / Math.max(1, Player.length.toMilliseconds()))
                  .formatHMS(Player.length.isSubSecond() ? VLCTick.SubSecondFormattedAsMS : 0)
            color: "#8F8F8F"
            font.pixelSize: 15 * previewCard.dp1
        }
    }
}
