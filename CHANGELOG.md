# Changelog

All notable changes of VLC Gold. Versions use the tag scheme
`redesign-vX.Y.Z`, so they cannot clash with VLC's own tags.

## redesign-v1.0.0

### Added
- Every remaining window of the old interface in the style of the settings window, with
  all of its options: Adjustments and Effects (with Track Synchronization and the v4l2
  controls), Convert, Stream Output and the transcoding profile editor, VLM, Program
  Guide, Messages, Plugins and extensions, the dialogs of Lua extensions, Edit Bookmarks,
  Go to Time, Podcast, Open URL, Add to Playlist, Audio Fingerprinting, About and Help,
  and the login, progress and question dialogs
- Check for Updates (Help menu): looks for a newer release of VLC Gold on GitHub, shows
  its notes and opens the release page. It also checks once a day by itself; the switch is
  in Settings › General › Startup. Nothing is downloaded or installed automatically
- Effects window: every slider has a field to type the value in, and shows its divisions
- Media Information is an entry of the player's right-click menu
- Playback settings: Show Statistics, a Test button for the stereo mode (a tone on the
  left, then on the right channel) and Subtitle Duration Factor
- Customize Player: HDR (HDR output on or off for the playing video) and Thumbnail (seek
  bar preview thumbnails on or off) buttons
- Back and forward arrows on the artist page
- Linux: the AppImage includes Lua, so extensions such as VLSub, YouTube links and the
  other Lua scripts work
- Playback settings: the values next to the sliders can be typed in

### Changed
- Windows with a few tabs (Open Media, Media Information, Effects, Messages, Plugins,
  About, Stream Output, profile editor) have them in a row under the title bar instead of
  a pane on the left
- The HDR mode in the Video tab of the playback settings applies to the playing video
- Right-click menu: "More Settings" is now "More", at the end of the menu, without
  Customize Interface; the main menu's "More" no longer repeats Playback, Audio, Video and
  Subtitle
- The library rail opens its pages directly, without the side panel
- The grid / list button switches the view with one click; the search field opens in the
  page header and is called Search
- Music and Network: sections as cards in the grid and as plain rows in the list
- Playback settings sliders use the real range of each option (Color Threshold 0 to 100)
  and steps that fit it
- Right-click menus of playlists, files and folders and the main menu show their entries
  directly instead of under "More", with icons where the design has one; folders get Play,
  Add to Queue and Add to Playlist like files
- Interface scale is the first setting of the Interface page and is applied when the
  slider is let go
- Onboarding: the shortcut keys look like the design's keycaps
- Ctrl+R and Ctrl+S open the new Open Media window; VLM picks its input and output with
  the new windows
- The Effects window applies and keeps every change at once, like the playback settings

### Fixed
- Windows: flipping the video, Sharpen or Banding Removal could break the picture, freeze
  or crash playback with hardware decoding
- A crash when seeking after a video filter option had been changed
- Videos was empty on first open when the library folders arrived late
- The login dialog showed "Save password" when the password could not be stored; Escape
  now cancels login and question dialogs
- VLM: enabling, disabling, looping and deleting an entry now reach VLM itself
- The window could shrink when a video started with "resize interface to video size"
- Warnings on every media change outside the library (bookmarks)

## redesign-v0.5.0 (beta)

### Added
- Subtitles from OpenSubtitles (opensubtitles.com) in the Add Subtitles dialog: for one
  video pick from the results, for a folder or playlist the best match per video; optional
  login in Settings › Network. Subtitles are saved next to the video
- Presets of all playback settings in the settings panel footer (subtitle, audio and video
  options, filters, flip and rotation, delays)
- Video tab of the playback settings: Defaults section with Flip, Rotate, Zoom, HDR,
  Resolution, Aspect Ratio, Crop and Render
- Playback settings for music files (Playback and Audio tabs)
- Restore Defaults at the end of each playback settings tab
- Customize Player: the seek bar is a control that can be dragged like the others, or put
  in its own row above the player bar
- All Settings: every VLC option and module, in the style of the settings window, opened
  with the "All Settings" switch in its header
- Settings window: the classic simple settings it was missing (interface language, layout,
  interface scale, Last.fm, history, audio device, start volume, media library folders,
  file associations, network buffering, …) and Reset all preferences
- Grid and list view for the Music and Network pages
- Seeking from the progress bar of the mini player

### Changed
- Open Media and Media Information windows in the style of the settings window, with all
  the options of the old dialogs
- Folders added from Music no longer show up in Videos
- VLC's menus (More, More Settings) use the redesign's icons
- Selected tab icons and active player bar buttons are two-tone as in the design
- Settings panel controls, labels and colours as in the design; effect sliders move in
  the steps they show, with tick marks
- Mini player: rounded and outlined video, padding, progress bar and card size as in the design
- Seek bar preview has rounded corners; empty pages and the player placeholder show the cone
- The queue's "+" button opens files
- The About text, installer, AutoPlay and `vlc.exe` file properties name VLC Gold on its
  own; the installer's website link goes to this project

### Fixed
- DVD menus: the bars and the way back to the library could not be brought back; they
  now show when the pointer is at the top or bottom edge
- Windows installer: the desktop and start menu shortcuts showed VLC's old cone (Windows
  kept the icon cached for VLC's path); they now use their own icon file
- Flip works on Windows with hardware decoding (Direct3D 11); before, it did nothing and
  turned off all other video filters
- The mini player's video slipped out of its frame while it was dragged
- Thumbnails that failed once (e.g. a timeout) are tried again; the thumbnailer gets 10 s
- DVD `.ifo` files no longer show up as empty playlists in the library
- Read-only files can be deleted from the library, like in File Explorer
- Crashes on quit (`--play-and-exit`, shared media library)
- OpenSubtitles: the subtitle language no longer becomes "c" on systems without a locale

## redesign-v0.3.0 (beta)

### Changed
- Renamed to **VLC Gold**, version 0.3.0: window titles, About, tray, installer, Linux app
  entry and `vlc --version`. VLC's own version (4.0.0-dev) stays for libVLC and plugins
- Windows packages are named `vlc-gold-<version>-win64.zip` / `.7z` / `.exe`, the Linux
  AppImage `VLC_Gold-<version>-x86_64.AppImage`; the repository is now `oliver-bacon/vlc-gold`
- The folder inside the Windows zip / 7z is `vlc-gold-<version>`, and the installer shows
  the VLC Gold version
- README: shorter feature list, beta note, no known issues section
- Linux build instructions moved from the README to `docs/building-linux.md`, with an
  optional install to `/opt/vlc-gold` (`vlc-gold` command, app menu entry, update and
  uninstall steps)

- Yes/no questions use the redesign's dialog: centered, no title bar, outlined frame,
  buttons under the text that light up on hover
- The redesign's cone is the app icon, and a cone shows instead of the music
  placeholder while a video starts
- Playback settings and the queue open as a card on the right side of the player, 20 px
  from the video frame
- The on-screen message shows the pressed key under it

### Removed
- Update check (it compared against VLC releases from VideoLAN)

### Added
- Linux AppImage build script (`extras/package/appimage/build.sh`, Ubuntu 22.04 in Docker)
- README: how to download and run the Linux AppImage
- Delete File From System in the file menu of library folders

### Fixed
- Linux install from source: a launcher script finds VLC's libraries instead of a
  system-wide `ld.so.conf.d` entry, which made the distribution's VLC 3 load the redesign's
  `libvlccore.so.9`
- Submenus open right next to the menu instead of 28 px away
- Videos: subfolder pages keep their folder, and the parent folders in the breadcrumbs
  can be clicked
- HDR videos are tone mapped on SDR screens (Windows, Direct3D 11)

## redesign-v0.2.6 (beta)

### Added
- Linux AppImage (`VLC_Redesign-0.2.6-x86_64.AppImage`), added to the release on 19 Oct;
  same code as the Windows build

### Fixed
- Quitting no longer crashes at exit: medialibrary kept a logger from a plugin that VLC
  had already unloaded (patch in `contrib/src/medialibrary`)

### Changed
- Linux build instructions in the README: Arch Linux packages, dependencies on other
  distributions, Qt 6.8 or newer, meson 1.10, building medialibrary, running without installing

## redesign-v0.2.5 (beta)

### Changed
- Bug reports use a GitHub issue form with fields for the build, package and system

### Fixed
- The chosen accent colour replaces the orange everywhere: the cone logo, the selected
  icons in the library side panel, the player's popovers, side panel and subtitle
  timeline, the dialogs and the equalizer
- Fullscreen always has a way out: F11 and Esc leave it (also the video's fullscreen), and
  the window buttons stay in fullscreen with "exit fullscreen" instead of maximize
- The track, playback settings and queue popovers keep a gap above the player bar
- "Show Preferences" in the track popover opens the settings page of its tab (Video, Audio,
  Subtitles)
- The settings' info tool tips open above the info icon instead of over it
- The queue's sort button shows its icon instead of a magenta square

## redesign-v0.2.0 (beta)

### Added
- Customize Player edits the player bars in place: the top bar and the control bar
  become drop zones, a panel over the video holds the controls not in use, and a
  Video / Music switch chooses which player bar is edited
- Settings window: equalizer with preamp and 10 bands, audio effects applied live,
  spatial audio mode
- Favorite button for every media (also files outside the library)
- Library: back and forward buttons in the page headers (and the mouse's forward
  button), resizable side panel, "Remove from Home" in the Home context menus
- Music covers on Home taken from the player's artwork (embedded pictures, cover files)
- Rounded frame around the video, cut out together with the bars
- Thumbnails for the videos in the folder views

### Changed
- Settings profiles also keep the interface settings: player bars, theme, view
  options, subtitle presets. Window position, library pins and hidden Home items stay
  the same in every profile
- The accent colour changes at once, without restarting VLC
- The player follows the light theme also while a video plays
- Player corner with VLC's own title bar: minimize, maximize, close; fullscreen is on
  the control bar
- Settings window has a title bar like the player's
- The track popover of audio files shows only the output devices
- The seek preview card has the video's aspect ratio
- A visualization stays on only for the media it was turned on for
- The media library can remove a media from the playback history (used by "Remove from Home")

### Fixed
- A minimized settings window comes back when the settings are opened again

## redesign-v0.1.0 (pre-release)

First public pre-release, based on VLC master `1176b56` (4.0 development version).

### Added
- Theme, accent colour, icon set and two-tone menu icons from the "VLC Redesign" design
- One-row player bar, cone-shaped volume, player top bar with library and folder buttons
- Audio / subtitle track popover; Queue / Bookmarks / Chapters popover
- Playback settings panel: playback, video and audio effects, equalizer presets with
  icons, subtitle appearance with size values and presets
- Seek preview thumbnails, subtitle timeline, waveform seek bar for audio files
- Library: side navigation and rail, Home rows, Videos by folder with previews, Music
  sections, Network (podcasts, radio, saved streams), context menus, compact library
  in the player, mini player card with the queue
- Settings window with profiles; Network Stream, New Playlist, Playlist Properties,
  Keyboard Shortcuts, Add Subtitles and Customize Player dialogs; onboarding
- "Continue watching" prompt and error messages in the redesign style

### Changed
- Default hotkeys: Record is `R`, Random has no default key, Hide UI is `Ctrl+\`
- The media library loads subtitle and audio files saved for a media as extra tracks

### Fixed
- Windows: VLC kept running after closing (libupnp built with MinGW looped forever in
  `strncasecmp`), and the UPnP plugin no longer ends libupnp while holding a lock
- The media library no longer ends VLC when a saved subtitle or audio track cannot be read
