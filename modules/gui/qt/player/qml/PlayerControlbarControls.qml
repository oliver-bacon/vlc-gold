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

pragma Singleton

import QtQml


import VLC.MainInterface
import VLC.PlayerControls
import VLC.Widgets as Widgets
import VLC.Style

QtObject {
    readonly property string controlPath : "qrc:///qt/qml/VLC/PlayerControls/"

    readonly property var controlList: [
        { id: ControlListModel.PLAY_BUTTON, file: "PlayButton.qml", label: VLCIcons.play_filled, text: qsTr("Play") },
        { id: ControlListModel.STOP_BUTTON, file: "StopButton.qml", label: VLCIcons.stop, text: qsTr("Stop") },
        { id: ControlListModel.OPEN_BUTTON, file: "OpenButton.qml", label: VLCIcons.eject, text: qsTr("Open") },
        { id: ControlListModel.PREVIOUS_BUTTON, file: "PreviousButton.qml", label: VLCIcons.previous, text: qsTr("Previous") },
        { id: ControlListModel.NEXT_BUTTON, file: "NextButton.qml", label: VLCIcons.next, text: qsTr("Next") },
        { id: ControlListModel.SLOWER_BUTTON, file: "SlowerButton.qml", label: VLCIcons.slower, text: qsTr("Slower") },
        { id: ControlListModel.FASTER_BUTTON, file: "FasterButton.qml", label: VLCIcons.faster, text: qsTr("Faster") },
        { id: ControlListModel.FULLSCREEN_BUTTON, file: "FullscreenButton.qml", label: VLCIcons.fullscreen, text: qsTr("Fullscreen") },
        { id: ControlListModel.EXTENDED_BUTTON, file: "ExtendedSettingsButton.qml", label: VLCIcons.playback_settings, text: qsTr("Playback settings") },
        { id: ControlListModel.PLAYLIST_BUTTON, file: "PlaylistButton.qml", label: VLCIcons.lists, text: qsTr("Play Queue") },
        { id: ControlListModel.SNAPSHOT_BUTTON, file: "SnapshotButton.qml", label: VLCIcons.snapshot, text: qsTr("Snapshot") },
        { id: ControlListModel.RECORD_BUTTON, file: "RecordButton.qml", label: VLCIcons.record, text: qsTr("Record") },
        { id: ControlListModel.ATOB_BUTTON, file: "AtoBButton.qml", label: VLCIcons.atob, text: qsTr("A-B Loop") },
        { id: ControlListModel.FRAME_PREV_BUTTON, file: "FrameNextButton.qml", label: VLCIcons.next_frame, text: qsTr("Next Frame") },
        { id: ControlListModel.FRAME_NEXT_BUTTON, file: "FramePrevButton.qml", label: VLCIcons.previous_frame, text: qsTr("Previous Frame") },
        { id: ControlListModel.REVERSE_BUTTON, file: "ReverseButton.qml", label: VLCIcons.play_reverse, text: qsTr("Trickplay Reverse") },
        { id: ControlListModel.SKIP_BACK_BUTTON, file: "SkipBackButton.qml", label: VLCIcons.skip_back, text: qsTr("Step backward") },
        { id: ControlListModel.SKIP_FW_BUTTON, file: "SkipForwardButton.qml", label: VLCIcons.skip_for, text: qsTr("Step forward") },
        { id: ControlListModel.QUIT_BUTTON, file: "QuitButton.qml", label: VLCIcons.clear, text: qsTr("Quit") },
        { id: ControlListModel.RANDOM_BUTTON, file: "RandomButton.qml", label: VLCIcons.shuffle, text: qsTr("Random") },
        { id: ControlListModel.LOOP_BUTTON, file: "LoopButton.qml", label: VLCIcons.repeat_all, text: qsTr("Loop") },
        { id: ControlListModel.INFO_BUTTON, file: "InfoButton.qml", label: VLCIcons.info, text: qsTr("Information") },
        { id: ControlListModel.LANG_BUTTON, file: "LangButton.qml", label: VLCIcons.audiosub, text: qsTr("Open subtitles") },
        { id: ControlListModel.BOOKMARK_BUTTON, file: "BookmarkButton.qml", label: VLCIcons.bookmarks, text: qsTr("Bookmarks") },
        { id: ControlListModel.FAVORITE_BUTTON, file: "FavoriteButton.qml", label: VLCIcons.favorite, text: qsTr("Favorite") },
        { id: ControlListModel.PIP_BUTTON, file: "PipButton.qml", label: VLCIcons.pip, text: qsTr("Picture in picture") },
        { id: ControlListModel.HDR_BUTTON, file: "HdrButton.qml", label: VLCIcons.hdr, text: qsTr("HDR") },
        { id: ControlListModel.THUMBNAIL_BUTTON, file: "ThumbnailButton.qml", label: VLCIcons.snapshot, text: qsTr("Thumbnail") },
        { id: ControlListModel.GO_HOME_BUTTON, file: "GoHomeButton.qml", label: VLCIcons.home, text: qsTr("Go Home") },
        { id: ControlListModel.SETTINGS_BUTTON, file: "SettingsButton.qml", label: VLCIcons.settings, text: qsTr("VLC Settings") },
        { id: ControlListModel.PROPERTIES_BUTTON, file: "PropertiesButton.qml", label: VLCIcons.info, text: qsTr("Properties") },
        { id: ControlListModel.REPLAY_BUTTON, file: "ReplayButton.qml", label: VLCIcons.replay, text: qsTr("Replay") },
        { id: ControlListModel.SIDEBAR_BUTTON, file: "SidebarButton.qml", label: VLCIcons.sidebar_right, text: qsTr("Right Sidebar") },
        { id: ControlListModel.LIBRARY_BUTTON, file: "LibraryButton.qml", label: VLCIcons.panel_left, text: qsTr("Library") },
        { id: ControlListModel.MENU_BUTTON, file: "MenuButton.qml", label: VLCIcons.ellipsis, text: qsTr("Menu") },
        { id: ControlListModel.MEDIA_TITLE_LABEL, file: "MediaTitleLabel.qml", label: VLCIcons.ic_fluent_text_change_case_24_regular, text: qsTr("Title") },
        { id: ControlListModel.ZOOM_BUTTON, file: "ZoomButton.qml", label: VLCIcons.zoom, text: qsTr("Zoom") },
        { id: ControlListModel.DIVIDER, file: "DividerWidget.qml", label: VLCIcons.remove, text: qsTr("Divider") },
        { id: ControlListModel.FILE_NAME_LABEL, file: "FileNameLabel.qml", label: VLCIcons.ic_fluent_document_add_24_regular, text: qsTr("File Name") },
        { id: ControlListModel.ARTIST_NAME_LABEL, file: "ArtistNameLabel.qml", label: VLCIcons.artist, text: qsTr("Artist Name") },
        { id: ControlListModel.FOLDER_NAME_LABEL, file: "FolderNameLabel.qml", label: VLCIcons.topbar_network, text: qsTr("Folder Name") },
        { id: ControlListModel.PLAYLIST_NAME_LABEL, file: "PlaylistNameLabel.qml", label: VLCIcons.playlist, text: qsTr("Playlist Name") },
        { id: ControlListModel.BACKWARD_15_BUTTON, file: "Backward15Button.qml", label: VLCIcons.backward_15_sec, text: qsTr("Backward 15s") },
        { id: ControlListModel.FORWARD_15_BUTTON, file: "Forward15Button.qml", label: VLCIcons.forward_15_sec, text: qsTr("Forward 15s") },
        { id: ControlListModel.CHAPTERS_BUTTON, file: "ChaptersButton.qml", label: VLCIcons.chapters, text: qsTr("Chapters") },
        { id: ControlListModel.BOOKMARK_ADD_BUTTON, file: "BookmarkAddButton.qml", label: VLCIcons.bookmark, text: qsTr("Bookmark") },
        { id: ControlListModel.AUDIO_TRACKS_BUTTON, file: "AudioTracksButton.qml", label: VLCIcons.visualization, text: qsTr("Audio Tracks") },
        { id: ControlListModel.SUBTITLE_TRACKS_BUTTON, file: "SubtitleTracksButton.qml", label: VLCIcons.audiosub, text: qsTr("Subtitle Tracks") },
        { id: ControlListModel.CHAPTER_PREVIOUS_BUTTON, file: "ChapterPreviousButton.qml", label: VLCIcons.dvd_prev, text: qsTr("Previous chapter") },
        { id: ControlListModel.CHAPTER_NEXT_BUTTON, file: "ChapterNextButton.qml", label: VLCIcons.dvd_next, text: qsTr("Next chapter") },
        { id: ControlListModel.VOLUME, file: "VolumeWidget.qml", label: VLCIcons.volume_high, text: qsTr("Volume Widget") },
        { id: ControlListModel.NAVIGATION_BOX, file: "NavigationBoxButton.qml", label: VLCIcons.ic_fluent_arrow_move, text: qsTr("Navigation Box") },
        { id: ControlListModel.NAVIGATION_BUTTONS, file: "NavigationWidget.qml", label: VLCIcons.dvd_menu, text: qsTr("Navigation") },
        { id: ControlListModel.DVD_MENUS_BUTTON, file: "DvdMenuButton.qml", label: VLCIcons.dvd_menu, text: qsTr("DVD menus") },
        { id: ControlListModel.PROGRAM_BUTTON, file: "ProgramButton.qml", label: VLCIcons.tv, text: qsTr("Program Button") },
        { id: ControlListModel.TELETEXT_BUTTONS, file: "TeletextButton.qml", label: VLCIcons.tvtelx, text: qsTr("Teletext") },
        { id: ControlListModel.RENDERER_BUTTON, file: "RendererButton.qml", label: VLCIcons.renderer, text: qsTr("Renderer Button") },
        { id: ControlListModel.ASPECT_RATIO_COMBOBOX, file: "AspectRatioWidget.qml", label: VLCIcons.aspect_ratio, text: qsTr("Aspect Ratio") },
        { id: ControlListModel.WIDGET_SPACER, file: "SpacerWidget.qml", label: VLCIcons.space, text: qsTr("Spacer") },
        { id: ControlListModel.WIDGET_SPACER_EXTEND, file: "ExpandingSpacerWidget.qml", label: VLCIcons.space, text: qsTr("Expanding Spacer") },
        { id: ControlListModel.PLAYER_SWITCH_BUTTON, file: "PlayerSwitchButton.qml", label: VLCIcons.fullscreen, text: qsTr("Switch Player") },
        { id: ControlListModel.ARTWORK_INFO, file: "ArtworkInfoWidget.qml", label: VLCIcons.info, text: qsTr("Artwork Info") },
        { id: ControlListModel.PLAYBACK_SPEED_BUTTON, file: "PlaybackSpeedButton.qml", label: "1x", text: qsTr("Playback Speed") },
        { id: ControlListModel.SEEK_BAR, file: "SeekBarWidget.qml", label: VLCIcons.time, text: qsTr("Seek Bar") },
        { id: ControlListModel.HIGH_RESOLUTION_TIME_WIDGET, file: "HighResolutionTimeWidget.qml", label: VLCIcons.time, text: qsTr("High Resolution Time") }
    ]

    function control(id) {
        const entry = controlList.find( function(e) { return ( e.id === id ) } )

        if (entry === undefined) {
            console.warn("control delegate id " + id +  " doesn't exist")
            return { source: controlPath + "Fallback.qml" }
        }

        entry.source = controlPath + entry.file

        return entry
    }
}
