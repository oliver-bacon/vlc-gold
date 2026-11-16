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

import VLC.Style

// Content of the settings window, following the "VLC Redesign" Figma file.
//
// Each row is bound to a real VLC option. Its control is chosen from the
// option's type (see SettingRow.qml) unless `kind` says otherwise. Rows
// whose option does not exist in the running build are hidden, so a
// platform-specific option simply does not show up elsewhere.
//
// Row fields:
//   label     text shown in the window (the option's own description is
//             shown in the info tooltip)
//   option    VLC option name
//   kind      optional: "segmented", "slider", "number", "colorScheme",
//             "accent", "filter", "action"
//   unit      optional suffix for numbers ("ms", "s", "%")
//   scale     optional: the stored value is `scale` times the shown one
//             (e.g. 1000 to show milliseconds as seconds)
//   list/module  for kind "filter": toggles `module` in the `list` option
//   live      apply to the audio that is playing too (audio options/filters)
//   greyIfMissing  shown greyed out (not hidden) when `module` is missing
//   kind "eqPreset": the preset also sets the bands; "equalizer": the bands
//   (EqualizerPanel.qml); "spatial"/"spatialMode": spatial audio on/off and
//   its filter (headphone virtualization or room effect)
//   action    for kind "action": name of a function of the window
//             (confirm: text of the button after a first click, which then
//             has to be clicked again)
//   os        only on this platform (Qt.platform.os, e.g. "windows")
//   needsML   only with a media library
//   aout      only while "aout" is one of these values
//   requires  "option" / "!option": enabled only while that switch is on / off
//   alsoSet   options that get the same value (the disc drive)
//   kind "intf": an extra interface started with VLC (module); "startVolume":
//   the volume at start; "layout": the classic Modern / Classic / Skins preset;
//   "intfScale": interface zoom; "language", "qtStyle": interface language
//   (Windows), style of the classic dialogs; "caching": the classic caching
//   policy; "mediaFolders": media library folders (banned: excluded ones)

//   kind "openSubtitles": sign in to opensubtitles.com (VLCOpenSubtitles)
QtObject {
    id: root

    readonly property var groups: [
        { title: qsTr("App"), pages: ["general", "interface", "privacy", "controls"] },
        { title: qsTr("Media"), pages: ["playback", "video", "audio", "subtitles", "library"] },
        { title: qsTr("System"), pages: ["network", "performance", "recording", "extensions"] }
    ]

    readonly property var pages: ({
        general: {
            name: qsTr("General"), title: qsTr("Global Settings"), icon: VLCIcons.settings,
            sections: [
                { title: qsTr("Appearance"), rows: [
                    { label: qsTr("Theme"), kind: "colorScheme" },
                    { label: qsTr("Accent color"), option: "qt-accent-color", kind: "accent" }
                ]},
                { title: qsTr("Startup"), rows: [
                    { label: qsTr("Show confirmation and error dialogs"), option: "qt-error-dialogs" },
                    { label: qsTr("Check for updates automatically"), kind: "uiToggle",
                      uiKey: "Update/AutoCheck", uiDefault: true,
                      info: qsTr("Once a day, VLC Gold asks GitHub whether a newer release exists and tells you when one does. Nothing is downloaded.") }
                ]},
                { title: qsTr("Diagnostics"), rows: [
                    { label: qsTr("Save a log"), option: "file-logging" },
                    { label: qsTr("Log file"), option: "logfile" },
                    { label: qsTr("Log details"), option: "log-verbose" },
                    { label: qsTr("Log format"), option: "logmode" },
                    { label: qsTr("Collect playback statistics"), option: "stats" },
                    { label: qsTr("Write to the system log"), option: "syslog" },
                    { label: qsTr("Include debug messages in the system log"), option: "syslog-debug" },
                    { label: qsTr("System log identity"), option: "syslog-ident" },
                    { label: qsTr("System log facility"), option: "syslog-facility" }
                ]},
                { title: qsTr("Language"), rows: [
                    { label: qsTr("Interface language (after restart)"), kind: "language" }
                ]},
                { title: qsTr("Reset"), rows: [
                    { label: qsTr("Reset all preferences"), kind: "action", action: "resetPreferences",
                      buttonText: qsTr("Reset"), confirm: qsTr("Confirm") }
                ]}
            ]
        },
        interface: {
            name: qsTr("Interface"), title: qsTr("Interface Settings"), icon: VLCIcons.interface,
            sections: [
                { title: qsTr("Size"), rows: [
                    { label: qsTr("Interface scale"), kind: "intfScale", min: 30, max: 300, step: 10, unit: "%" }
                ]},
                { title: qsTr("Window"), rows: [
                    { label: qsTr("Play video inside main window"), option: "embedded-video" },
                    { label: qsTr("Resize window to fit video"), option: "qt-video-autoresize" },
                    { label: qsTr("Keep window above other windows"), option: "video-on-top" },
                    { label: qsTr("Show window decorations"), option: "qt-titlebar" },
                    { label: qsTr("Show the file name in the title bar"), option: "qt-name-in-title" },
                    { label: qsTr("Open fullscreen on"), option: "qt-fullscreen-screennumber" },
                    { label: qsTr("Window opacity"), option: "qt-opacity", kind: "slider", unit: "%", scale: 0.01 },
                    { label: qsTr("Pause video when window is minimized"), option: "qt-pause-minimized" },
                    { label: qsTr("Bring VLC to the front when playback starts"), option: "qt-auto-raise" },
                    { label: qsTr("Show cover art in the window when playing audio"), option: "qt-bgcone" },
                    { label: qsTr("Show the file browser inside the open dialog"), option: "qt-embedded-open" },
                    { label: qsTr("Allow the app icon to change"), option: "qt-icon-change" }
                ]},
                { title: qsTr("Playback Controls"), rows: [
                    { label: qsTr("Start in compact mode"), option: "qt-minimal-view" },
                    { label: qsTr("Keep the controls visible"), option: "qt-pin-controls" },
                    { label: qsTr("Hide after"), option: "mouse-hide-timeout", kind: "slider", unit: "s", scale: 1000, min: 0, max: 10, step: 0.5 },
                    { label: qsTr("Show controls in fullscreen"), option: "qt-fs-controller" },
                    { label: qsTr("Fullscreen controls opacity"), option: "qt-fs-opacity", kind: "slider", unit: "%", scale: 0.01 },
                    { label: qsTr("Fullscreen controls sensitivity"), option: "qt-fs-sensitivity" }
                ]},
                { title: qsTr("Notifications and System Tray"), rows: [
                    { label: qsTr("Show a system tray icon"), option: "qt-system-tray" },
                    { label: qsTr("Start minimized to the tray"), option: "qt-start-minimized" },
                    { label: qsTr("Close to the system tray"), option: "qt-close-to-system-tray" },
                    { label: qsTr("Show a popup when the track changes"), option: "qt-notification" }
                ]},
                { title: qsTr("Playlist"), rows: [
                    { label: qsTr("Show the playlist as a tree"), option: "playlist-tree" }
                ]},
                { title: qsTr("Layout"), rows: [
                    { label: qsTr("Layout"), kind: "layout" },
                    { label: qsTr("Show the menu bar"), option: "qt-menubar" },
                    { label: qsTr("Customize the player bar"), kind: "action", action: "customizePlayer", buttonText: qsTr("Customize") },
                    { label: qsTr("Skin file"), option: "skins2-last" },
                    { label: qsTr("Style of the classic dialogs"), kind: "qtStyle" }
                ]}
            ]
        },
        privacy: {
            name: qsTr("Privacy"), title: qsTr("Privacy Settings"), icon: VLCIcons.privacy,
            sections: [
                { title: qsTr("Network"), rows: [
                    { label: qsTr("Fetch titles and cover art from the internet"), option: "metadata-network-access" }
                ]},
                { title: qsTr("Last.fm"), rows: [
                    { label: qsTr("Submit played tracks to Last.fm"), kind: "intf", module: "audioscrobbler" },
                    { label: qsTr("Last.fm username"), option: "lastfm-username" },
                    { label: qsTr("Last.fm password"), option: "lastfm-password" },
                    { label: qsTr("Last.fm submission URL"), option: "scrobbler-url" }
                ]},
                { title: qsTr("History"), rows: [
                    { label: qsTr("Save recently played media"), option: "save-recentplay", needsML: true },
                    { label: qsTr("Clear recently played media"), kind: "action", action: "clearRecent",
                      buttonText: qsTr("Clear"), confirm: qsTr("Confirm"), needsML: true }
                ]}
            ]
        },
        controls: {
            name: qsTr("Controls"), title: qsTr("Mouse, Keyboard & Remote Controls"), icon: VLCIcons.hotkeys,
            sections: [
                { title: qsTr("Keyboard Shortcuts"), rows: [
                    { label: qsTr("Edit keyboard shortcuts"), kind: "action", action: "openShortcuts", buttonText: qsTr("Edit") }
                ]},
                { title: qsTr("Skip Amounts"), rows: [
                    { label: qsTr("Very short skip"), option: "extrashort-jump-size", kind: "number", unit: "s" },
                    { label: qsTr("Short skip"), option: "short-jump-size", kind: "number", unit: "s" },
                    { label: qsTr("Medium skip"), option: "medium-jump-size", kind: "number", unit: "s" },
                    { label: qsTr("Long skip"), option: "long-jump-size", kind: "number", unit: "s" }
                ]},
                { title: qsTr("Mouse"), rows: [
                    { label: qsTr("Scroll wheel"), option: "hotkeys-y-wheel-mode" },
                    { label: qsTr("Horizontal scroll"), option: "hotkeys-x-wheel-mode" }
                ]},
                { title: qsTr("Remotes"), rows: [
                    { label: qsTr("Web remote control port"), option: "http-port", kind: "number" },
                    { label: qsTr("Web remote control password"), option: "http-password" }
                ]},
                { title: qsTr("Media Keys"), rows: [
                    { label: qsTr("Ignore the keyboard's volume keys"), option: "qt-disable-volume-keys" }
                ]}
            ]
        },
        playback: {
            name: qsTr("Playback"), title: qsTr("Playback Preferences"), icon: VLCIcons.playback_settings,
            sections: [
                { title: qsTr("Startup"), rows: [
                    { label: qsTr("Start paused"), option: "start-paused" },
                    { label: qsTr("Default playback speed"), option: "rate", kind: "slider", min: 0.25, max: 2, step: 0.25, unit: "×" }
                ]},
                { title: qsTr("Tracks"), rows: [
                    { label: qsTr("Preferred video quality"), option: "preferred-resolution" },
                    { label: qsTr("Preferred menu language"), option: "menu-language" },
                    { label: qsTr("Default audio track"), option: "audio-track", kind: "number" },
                    { label: qsTr("Default subtitle track"), option: "sub-track", kind: "number" }
                ]},
                { title: qsTr("Order"), rows: [
                    { label: qsTr("Repeat all"), option: "loop" },
                    { label: qsTr("Repeat current item"), option: "repeat" },
                    { label: qsTr("Shuffle"), option: "random" },
                    { label: qsTr("Stop after each item"), option: "play-and-stop" },
                    { label: qsTr("Quit when playback finishes"), option: "play-and-exit" }
                ]},
                { title: qsTr("Seeking"), rows: [
                    { label: qsTr("Seek quickly to the nearest keyframe"), option: "input-fast-seek" }
                ]},
                { title: qsTr("Files & Discs"), rows: [
                    { label: qsTr("Default optical drive"), option: "dvd", alsoSet: ["vcd", "cd-audio"] },
                    { label: qsTr("Repair damaged AVI files"), option: "avi-index" },
                    { label: qsTr("Load matching .mkv files from the same folder"), option: "mkv-preload-local-dir" },
                    { label: qsTr("Time-shift buffer folder"), option: "input-timeshift-path" },
                    { label: qsTr("Time-shift buffer granularity"), option: "input-timeshift-granularity", kind: "number" }
                ]},
                { title: qsTr("Resuming"), rows: [
                    { label: qsTr("Continue playback where it stopped"), option: "restore-playback-pos", needsML: true },
                    { label: qsTr("Pause on the last frame of a video"), option: "play-and-pause" }
                ]}
            ]
        },
        video: {
            name: qsTr("Video"), title: qsTr("Video Defaults"), icon: VLCIcons.video,
            sections: [
                { title: qsTr("Output"), rows: [
                    { label: qsTr("Enable video"), option: "video" },
                    { label: qsTr("Start videos in fullscreen"), option: "fullscreen" },
                    { label: qsTr("Stop the screensaver during playback"), option: "disable-screensaver" },
                    { label: qsTr("Play video as desktop wallpaper"), option: "video-wallpaper" },
                    { label: qsTr("Show window decorations around the video"), option: "video-deco" }
                ]},
                { title: qsTr("Deinterlacing"), rows: [
                    { label: qsTr("Deinterlacing"), option: "deinterlace" },
                    { label: qsTr("Method"), option: "deinterlace-mode" }
                ]},
                { title: qsTr("Framing"), rows: [
                    { label: qsTr("Aspect ratio"), option: "aspect-ratio" },
                    { label: qsTr("Crop"), option: "crop" },
                    { label: qsTr("Scale video to the window"), option: "autoscale" },
                    { label: qsTr("Zoom"), option: "zoom", kind: "number" },
                    { label: qsTr("Position in the window"), option: "align" },
                    { label: qsTr("Custom aspect ratios"), option: "custom-aspect-ratios" },
                    { label: qsTr("Custom crop ratios"), option: "custom-crop-ratios" },
                    { label: qsTr("Monitor pixel aspect ratio"), option: "monitor-par" }
                ]},
                { title: qsTr("Snapshots"), rows: [
                    { label: qsTr("Save to"), option: "snapshot-path" },
                    { label: qsTr("File name prefix"), option: "snapshot-prefix" },
                    { label: qsTr("Format"), option: "snapshot-format" },
                    { label: qsTr("Width"), option: "snapshot-width", kind: "number" },
                    { label: qsTr("Height"), option: "snapshot-height", kind: "number" },
                    { label: qsTr("Number files sequentially"), option: "snapshot-sequential" },
                    { label: qsTr("Show a preview after capture"), option: "snapshot-preview" }
                ]},
                { title: qsTr("Output Module"), rows: [
                    { label: qsTr("Output module"), option: "vout" },
                    { label: qsTr("Hardware YUV to RGB conversion"), option: "directx-hw-yuv" },
                    { label: qsTr("Workaround for T23 graphics"), option: "kva-fixt23" },
                    { label: qsTr("KVA video mode"), option: "kva-video-mode" }
                ]}
            ]
        },
        audio: {
            name: qsTr("Audio"), title: qsTr("Audio Defaults"), icon: VLCIcons.visualization,
            sections: [
                { title: qsTr("Output"), rows: [
                    { label: qsTr("Enable audio"), option: "audio" },
                    { label: qsTr("Output module"), option: "aout" },
                    { label: qsTr("Speaker setup"), option: "stereo-mode" },
                    { label: qsTr("Pass compressed audio to the receiver"), option: "spdif" },
                    { label: qsTr("Detect Dolby Surround"), option: "force-dolby-surround" },
                    { label: qsTr("Media role"), option: "role" }
                ]},
                { title: qsTr("Volume"), rows: [
                    { label: qsTr("Maximum volume"), option: "qt-max-volume", kind: "slider", unit: "%" },
                    { label: qsTr("Remember the volume"), option: "volume-save" },
                    { label: qsTr("Volume step"), option: "volume-step", kind: "number" }
                ]},
                { title: qsTr("Loudness"), rows: [
                    { label: qsTr("Normalize loudness"), kind: "filter", list: "audio-filter", module: "normvol" },
                    { label: qsTr("Target level"), option: "norm-max-level", kind: "number" },
                    { label: qsTr("Replay gain"), option: "audio-replay-gain-mode" },
                    { label: qsTr("Replay gain preamp"), option: "audio-replay-gain-preamp", kind: "number", unit: "dB" }
                ]},
                // Figma "Settings - audio": the effects apply at once to the
                // audio that is playing (live), and are greyed out when the
                // build has no such filter
                { title: qsTr("Effects"), rows: [
                    { label: qsTr("Equalizer"), kind: "filter", list: "audio-filter", module: "equalizer", live: true, greyIfMissing: true },
                    { label: qsTr("Equalizer preset"), option: "equalizer-preset", kind: "eqPreset", module: "equalizer", greyIfMissing: true },
                    { label: qsTr("Equalizer bands"), kind: "equalizer", module: "equalizer", greyIfMissing: true },
                    { label: qsTr("Two-pass"), option: "equalizer-2pass", module: "equalizer", live: true, greyIfMissing: true },
                    { label: qsTr("Spatial audio"), kind: "spatial", list: "audio-filter", greyIfMissing: true },
                    { label: qsTr("Spatial audio mode"), kind: "spatialMode", greyIfMissing: true },
                    { label: qsTr("Stereo widening"), kind: "filter", list: "audio-filter", module: "stereo_widen", live: true, greyIfMissing: true },
                    { label: qsTr("Compressor"), kind: "filter", list: "audio-filter", module: "compressor", live: true, greyIfMissing: true },
                    { label: qsTr("Chorus/flanger"), kind: "filter", list: "audio-filter", module: "chorus_flanger", live: true, greyIfMissing: true },
                    { label: qsTr("Karaoke"), kind: "filter", list: "audio-filter", module: "karaoke", live: true, greyIfMissing: true }
                ]},
                { title: qsTr("Tracks"), rows: [
                    { label: qsTr("Preferred audio language"), option: "audio-language" },
                    { label: qsTr("Audio delay"), option: "audio-desync", kind: "number", unit: "ms" }
                ]},
                { title: qsTr("Visualization"), rows: [
                    { label: qsTr("Visualizer"), option: "audio-visual" }
                ]},
                // the device of the audio output in use
                { title: qsTr("Device"), rows: [
                    { label: qsTr("Device"), option: "mmdevice-audio-device", aout: ["mmdevice", "any", ""] },
                    { label: qsTr("Device"), option: "directx-audio-device", aout: ["directx"] },
                    { label: qsTr("Device"), option: "waveout-audio-device", aout: ["waveout"] },
                    { label: qsTr("Device"), option: "alsa-audio-device", aout: ["alsa"] },
                    { label: qsTr("Device"), option: "oss-audio-device", aout: ["oss"] },
                    { label: qsTr("Device"), option: "kai-audio-device", aout: ["kai"] },
                    { label: qsTr("HDMI / S/PDIF passthrough"), option: "mmdevice-passthrough", aout: ["mmdevice", "any", ""] },
                    { label: qsTr("Output file"), option: "audiofile-file", aout: ["afile"] }
                ]},
                { title: qsTr("Start & Speed"), rows: [
                    { label: qsTr("Volume at start"), kind: "startVolume", unit: "%", requires: "!volume-save", greyIfMissing: true },
                    { label: qsTr("Keep the pitch when changing the speed"), option: "audio-time-stretch" }
                ]}
            ]
        },
        subtitles: {
            name: qsTr("Subtitles"), title: qsTr("Subtitle Defaults"), icon: VLCIcons.subtitle,
            sections: [
                { title: qsTr("Tracks & Languages"), rows: [
                    { label: qsTr("Enable subtitles"), option: "spu" },
                    { label: qsTr("Preferred language"), option: "sub-language" },
                    { label: qsTr("Text encoding"), option: "subsdec-encoding" }
                ]},
                { title: qsTr("Loading Subtitles"), rows: [
                    { label: qsTr("Load subtitle files automatically"), option: "sub-autodetect-file" },
                    { label: qsTr("File name matching"), option: "sub-autodetect-fuzzy" },
                    { label: qsTr("Load subtitles from these folders"), option: "sub-autodetect-path" }
                ]},
                { title: qsTr("Appearance"), rows: [
                    { label: qsTr("Font"), option: "freetype-font" },
                    { label: qsTr("Font size"), option: "freetype-rel-fontsize" },
                    { label: qsTr("Text size"), option: "sub-text-scale", kind: "slider", unit: "%" },
                    { label: qsTr("Bold"), option: "freetype-bold" },
                    { label: qsTr("Text color"), option: "freetype-color" },
                    { label: qsTr("Text opacity"), option: "freetype-opacity", kind: "slider" },
                    { label: qsTr("Outline thickness"), option: "freetype-outline-thickness" },
                    { label: qsTr("Outline color"), option: "freetype-outline-color" },
                    { label: qsTr("Shadow opacity"), option: "freetype-shadow-opacity", kind: "slider" },
                    { label: qsTr("Shadow color"), option: "freetype-shadow-color" },
                    { label: qsTr("Background opacity"), option: "freetype-background-opacity", kind: "slider" },
                    { label: qsTr("Background color"), option: "freetype-background-color" },
                    { label: qsTr("Vertical position"), option: "sub-margin", kind: "number", unit: "px" },
                    { label: qsTr("Shadow angle"), option: "freetype-shadow-angle", kind: "number" },
                    { label: qsTr("Shadow distance"), option: "freetype-shadow-distance", kind: "number" },
                    { label: qsTr("Text direction"), option: "freetype-text-direction" },
                    { label: qsTr("Monospace font"), option: "freetype-monofont" }
                ]},
                { title: qsTr("On-Screen Messages"), rows: [
                    { label: qsTr("Show feedback for shortcuts"), option: "osd" },
                    { label: qsTr("Show filename when a video starts"), option: "video-title-show" },
                    { label: qsTr("Show filename for"), option: "video-title-timeout", kind: "slider", unit: "s", scale: 1000, min: 1, max: 10, step: 0.5 }
                ]},
                { title: qsTr("Positions"), rows: [
                    { label: qsTr("Filename position"), option: "video-title-position" },
                    { label: qsTr("Secondary subtitle alignment"), option: "secondary-sub-alignment" },
                    { label: qsTr("Secondary subtitle position"), option: "secondary-sub-margin", kind: "number", unit: "px" }
                ]}
            ]
        },
        library: {
            name: qsTr("Library"), title: qsTr("Playlists, Folders & Files"), icon: VLCIcons.lists,
            sections: [
                { title: qsTr("Opening Files"), rows: [
                    { label: qsTr("Only allow one VLC window"), option: "one-instance" },
                    { label: qsTr("Apply to files opened from the file manager"), option: "one-instance-when-started-from-file" },
                    { label: qsTr("Add to the playlist instead of replacing it"), option: "playlist-enqueue" }
                ]},
                { title: qsTr("When opening a folder"), rows: [
                    { label: qsTr("Include subfolders"), option: "recursive" },
                    { label: qsTr("Show hidden files"), option: "show-hiddenfiles" }
                ]},
                { title: qsTr("Metadata & Artwork"), rows: [
                    { label: qsTr("Use the media library"), option: "media-library" }
                ]},
                { title: qsTr("Media Library Folders"), rows: [
                    { label: qsTr("Folders"), kind: "mediaFolders", needsML: true },
                    { label: qsTr("Excluded folders"), kind: "mediaFolders", banned: true, needsML: true },
                    { label: qsTr("Scan the folders again"), kind: "action", action: "rescanLibrary",
                      buttonText: qsTr("Rescan"), needsML: true }
                ]},
                { title: qsTr("File Associations"), rows: [
                    { label: qsTr("File types opened with VLC Gold"), kind: "action", action: "fileAssociations",
                      buttonText: qsTr("Choose"), os: "windows" }
                ]}
            ]
        },
        network: {
            name: qsTr("Network"), title: qsTr("Network Connections & Security"), icon: VLCIcons.stream,
            sections: [
                { title: qsTr("Buffering"), rows: [
                    { label: qsTr("Local files"), option: "file-caching", kind: "number", unit: "ms" },
                    { label: qsTr("Discs"), option: "disc-caching", kind: "number", unit: "ms" },
                    { label: qsTr("Network streams"), option: "network-caching", kind: "number", unit: "ms" },
                    { label: qsTr("Live capture"), option: "live-caching", kind: "number", unit: "ms" }
                ]},
                { title: qsTr("Proxy"), rows: [
                    { label: qsTr("HTTP proxy"), option: "http-proxy" },
                    { label: qsTr("HTTP proxy password"), option: "http-proxy-pwd" }
                ]},
                { title: qsTr("Security"), rows: [
                    { label: qsTr("Verify certificates against the system trust store"), option: "gnutls-system-trust" },
                    { label: qsTr("Cipher preference"), option: "gnutls-priorities" }
                ]},
                { title: qsTr("OpenSubtitles"), rows: [
                    { label: qsTr("Account for subtitle downloads"), kind: "openSubtitles" }
                ]},
                { title: qsTr("Buffering Preset"), rows: [
                    { label: qsTr("Buffering preset"), kind: "caching" }
                ]},
                { title: qsTr("Streaming"), rows: [
                    { label: qsTr("RTP over RTSP (TCP)"), option: "rtsp-tcp" }
                ]}
            ]
        },
        performance: {
            name: qsTr("Performance"), title: qsTr("Performance Settings"), icon: VLCIcons.speed,
            sections: [
                { title: qsTr("Decoding"), rows: [
                    { label: qsTr("Hardware-accelerated decoding"), option: "dec-dev" },
                    { label: qsTr("Skip the H.264 loop filter"), option: "avcodec-skiploopfilter" },
                    { label: qsTr("Decoding threads"), option: "avcodec-threads", kind: "number" }
                ]},
                { title: qsTr("Smooth Playback"), rows: [
                    { label: qsTr("Drop frames when the system can't keep up"), option: "drop-late-frames" },
                    { label: qsTr("Give VLC real-time priority"), option: "high-priority" },
                    { label: qsTr("Clock synchronisation"), option: "clock-synchro" },
                    { label: qsTr("Clock jitter"), option: "clock-jitter", kind: "number", unit: "ms" }
                ]},
                { title: qsTr("Post-processing"), rows: [
                    { label: qsTr("Post-processing quality"), option: "postproc-q" }
                ]}
            ]
        },
        recording: {
            name: qsTr("Recording"), title: qsTr("Recording, Casting & Streaming Out"), icon: VLCIcons.record,
            sections: [
                { title: qsTr("Recording"), rows: [
                    { label: qsTr("Save recordings to"), option: "input-record-path" },
                    { label: qsTr("Record without re-encoding when possible"), option: "input-record-native" }
                ]},
                { title: qsTr("H.264 Encoder"), rows: [
                    { label: qsTr("H.264 encoder preset"), option: "sout-x264-preset" },
                    { label: qsTr("H.264 encoder tuning"), option: "sout-x264-tune" },
                    { label: qsTr("H.264 profile"), option: "sout-x264-profile" },
                    { label: qsTr("H.264 level"), option: "sout-x264-level" }
                ]}
            ]
        },
        extensions: {
            name: qsTr("Extensions"), title: qsTr("Add-ons & Scripts"), icon: VLCIcons.plugins,
            sections: [
                { title: qsTr("Add-ons"), rows: [
                    { label: qsTr("Manage add-ons"), kind: "action", action: "openAddons", buttonText: qsTr("Open") },
                    { label: qsTr("Load add-ons on startup"), option: "qt-autoload-extensions" }
                ]}
            ]
        }
    })
}
