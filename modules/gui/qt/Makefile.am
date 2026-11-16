guidir = $(pluginsdir)/gui
gui_LTLIBRARIES =
gui_PLUGINS =
gui_RPATH =

if HAVE_PARTIAL_LINKING
noinst_LTLIBRARIES = $(gui_PLUGINS)
else
gui_LTLIBRARIES += $(gui_PLUGINS)
gui_RPATH += -rpath '$(guidir)'
endif


## Howto
# For each Q_OBJECT:
#   - Add *.moc.cpp to nodist_..._SOURCES
#   - Add *.cpp to ..._SOURCES
#   - Add *.hpp to ..._SOURCES
# For each UI
#   - Add *.ui to ..._UI
#   - Add *.h to nodist_..._SOURCES
# For each resource (icon, png, ...)
#   - Add it to DEPS_res
# For each qml and js resource
#   - Add it to ..._QML

CLEANFILES =

include ../../common.am

# Generate vlc_modules_list for Qt plugins
include ../../modulelist.mk

SUFFIXES += .ui .h .hpp .moc.cpp .qml .js .mjs .moc
TEST_EXTENSIONS = .qml
EXTRA_DIST = qt6.pro qtest.pro quicktest.pro scripts
vlc_qt_libs = $(QT_LIBS)
RCC_EXTRA_PARAMS =

all-local: $(VLC_QT_CHECK_DEP) $(QML_MODULE_STAMPS)

if !HAVE_QT_ZSTD
RCC_EXTRA_PARAMS += --no-zstd
endif

vlc_qt_check_SOURCES = vlc-qt-check.cpp plugins.hpp
vlc_qt_check_CXXFLAGS = $(AM_CXXFLAGS) $(QT_CFLAGS) -fPIC $(CXXFLAGS_qt)
vlc_qt_check_CPPFLAGS = $(AM_CPPFLAGS) $(CPPFLAGS_qt)
vlc_qt_check_LDADD = $(vlc_qt_libs)
vlc_qt_check_LDFLAGS = $(AM_LDFLAGS) $(QT_LDFLAGS)

libqt_plugin_la_CPPFLAGS = $(AM_CPPFLAGS) $(CPPFLAGS_qt) \
	-DQT_STRICT_ITERATORS \
	-DQT_USE_QSTRINGBUILDER \
	-DQT_NO_CAST_TO_ASCII \
	-DQT_NO_CAST_FROM_BYTEARRAY \
	-I$(srcdir) -I$(builddir) \
	-I$(builddir)/dialogs/extended \
	-I$(builddir)/dialogs/fingerprint \
	-I$(builddir)/dialogs/firstrun \
	-I$(builddir)/dialogs/help \
	-I$(builddir)/dialogs/messages \
	-I$(builddir)/dialogs/open \
	-I$(builddir)/dialogs/podcast \
	-I$(builddir)/dialogs/preferences \
	-I$(builddir)/dialogs/sout \
	-I$(builddir)/dialogs/vlm

libqt_plugin_la_CXXFLAGS = $(AM_CXXFLAGS) $(QT_CFLAGS) $(CXXFLAGS_qt) -fPIC
libqt_plugin_la_LIBADD = $(vlc_qt_libs)
if HAVE_LIBATOMIC
libqt_plugin_la_CXXFLAGS += -DQT_HAS_LIBATOMIC
libqt_plugin_la_LIBADD += -latomic
endif
libqt_plugin_la_LDFLAGS = $(AM_LDFLAGS) $(QT_LDFLAGS) $(GC_SECTIONS_LDFLAGS)
if HAVE_OSX
libqt_plugin_la_LDFLAGS += -Wl,-framework,Cocoa
endif

if HAVE_X
if HAVE_XCB
libqt_plugin_la_CXXFLAGS += $(XCB_CFLAGS) -DQT_HAS_X11
libqt_plugin_la_LIBADD += $(XCB_LIBS) $(X_LIBS) $(X_PRE_LIB) -lX11
vlc_qt_check_CXXFLAGS += $(XCB_CFLAGS) -DQT_HAS_X11
endif
endif

if HAVE_WIN32
libqt_plugin_la_CXXFLAGS += $(LIBCOMCXXFLAGS)
libqt_plugin_la_LIBADD += $(LIBCOM) -lcomctl32 -luuid -ldwmapi
endif
if UPDATE_CHECK
libqt_plugin_la_CPPFLAGS += -DUPDATE_CHECK
endif
if QT_QML_DEBUG
libqt_plugin_la_CPPFLAGS += -DQT_QML_DEBUG
endif
if HAVE_QT_GTK
libqt_plugin_la_CPPFLAGS += -DQT_HAS_GTK
endif

libqt_plugin_la_SOURCES = \
	qt.cpp qt.hpp plugins.hpp \
	dialogs/bookmarks/bookmarks.cpp dialogs/bookmarks/bookmarks.hpp \
	dialogs/dialogs/dialogmodel.cpp \
	dialogs/dialogs/dialogmodel.hpp \
	dialogs/dialogs_provider.cpp dialogs/dialogs_provider.hpp \
	dialogs/epg/EPGChannels.cpp \
	dialogs/epg/EPGChannels.hpp \
	dialogs/epg/EPGItem.cpp \
	dialogs/epg/EPGItem.hpp \
	dialogs/epg/EPGProgram.cpp \
	dialogs/epg/EPGProgram.hpp \
	dialogs/epg/EPGRuler.cpp dialogs/epg/EPGRuler.hpp \
	dialogs/epg/EPGView.cpp dialogs/epg/EPGView.hpp \
	dialogs/epg/EPGWidget.cpp \
	dialogs/epg/EPGWidget.hpp \
	dialogs/epg/epg.cpp dialogs/epg/epg.hpp \
	dialogs/epg/epgmodel.cpp dialogs/epg/epgmodel.hpp \
	dialogs/extended/extended.cpp dialogs/extended/extended.hpp \
	dialogs/extended/v4l2controls.cpp dialogs/extended/v4l2controls.hpp \
	dialogs/extended/extended_panels.cpp \
	dialogs/extended/extended_panels.hpp \
	dialogs/extensions/extensions.cpp dialogs/extensions/extensions.hpp \
	dialogs/extensions/extensiondialogmodel.cpp dialogs/extensions/extensiondialogmodel.hpp \
	dialogs/extensions/extensions_manager.cpp dialogs/extensions/extensions_manager.hpp \
	dialogs/fingerprint/chromaprint.cpp \
	dialogs/fingerprint/chromaprint.hpp \
	dialogs/fingerprint/fingerprintdialog.cpp \
	dialogs/fingerprint/fingerprintdialog.hpp \
	dialogs/fingerprint/fingerprintmodel.cpp \
	dialogs/fingerprint/fingerprintmodel.hpp \
	dialogs/firstrun/firstrunwizard.cpp dialogs/firstrun/firstrunwizard.hpp \
	dialogs/gototime/gototime.cpp dialogs/gototime/gototime.hpp \
	dialogs/help/aboutmodel.hpp \
	dialogs/help/help.cpp dialogs/help/help.hpp \
	dialogs/mediainfo/info_panels.cpp dialogs/mediainfo/info_panels.hpp \
	dialogs/mediainfo/info_widgets.cpp dialogs/mediainfo/info_widgets.hpp \
	dialogs/mediainfo/mediainfo.cpp dialogs/mediainfo/mediainfo.hpp \
	dialogs/mediainfo/mediainfomodel.cpp dialogs/mediainfo/mediainfomodel.hpp \
	dialogs/messages/messagesmodel.cpp dialogs/messages/messagesmodel.hpp \
	dialogs/messages/messages.cpp dialogs/messages/messages.hpp \
	dialogs/open/open.cpp dialogs/open/open.hpp \
	dialogs/open/open_panels.cpp dialogs/open/open_panels.hpp \
	dialogs/open/openurl.cpp dialogs/open/openurl.hpp \
	dialogs/open/openmedia.cpp dialogs/open/openmedia.hpp \
	dialogs/plugins/plugins.cpp dialogs/plugins/plugins.hpp \
	dialogs/plugins/pluginshelper.cpp dialogs/plugins/pluginshelper.hpp \
	dialogs/podcast/podcast_configuration.cpp \
	dialogs/podcast/podcast_configuration.hpp \
	dialogs/preferences/complete_preferences.cpp \
	dialogs/preferences/complete_preferences.hpp \
	dialogs/preferences/expert_model.cpp \
	dialogs/preferences/expert_model.hpp \
	dialogs/preferences/expert_view.cpp \
	dialogs/preferences/expert_view.hpp \
	dialogs/preferences/preferences.cpp \
	dialogs/preferences/preferences.hpp \
	dialogs/preferences/preferences_widgets.cpp \
	dialogs/preferences/preferences_widgets.hpp \
	dialogs/preferences/simple_preferences.cpp \
	dialogs/preferences/simple_preferences.hpp \
	dialogs/sout/convert.cpp dialogs/sout/convert.hpp \
	dialogs/sout/southelper.cpp dialogs/sout/southelper.hpp \
	dialogs/sout/profile_selector.cpp \
	dialogs/sout/profile_selector.hpp \
	dialogs/sout/profiles.hpp \
	dialogs/sout/sout.cpp dialogs/sout/sout.hpp \
	dialogs/sout/sout_widgets.cpp \
	dialogs/sout/sout_widgets.hpp \
	dialogs/systray/systray.cpp \
	dialogs/systray/systray.hpp \
	dialogs/toolbar/controlbar_profile.hpp \
	dialogs/toolbar/controlbar_profile.cpp \
	dialogs/toolbar/controlbar_profile_model.cpp \
	dialogs/toolbar/controlbar_profile_model.hpp \
	dialogs/vlm/vlm.cpp dialogs/vlm/vlm.hpp \
	dialogs/vlm/vlmmodel.cpp dialogs/vlm/vlmmodel.hpp \
	dialogs/playlists/playlists.cpp dialogs/playlists/playlists.hpp \
	maininterface/compositor.hpp \
	maininterface/compositor.cpp \
	maininterface/compositor_common.hpp \
	maininterface/compositor_common.cpp \
	maininterface/compositor_accessibility.cpp \
	maininterface/compositor_accessibility.hpp \
	maininterface/compositor_dummy.hpp \
	maininterface/compositor_dummy.cpp \
	maininterface/compositor_platform.hpp \
	maininterface/compositor_platform.cpp \
	maininterface/interface_window_handler.cpp \
	maininterface/interface_window_handler.hpp \
	maininterface/mainctx.cpp \
	maininterface/mainctx.hpp \
	maininterface/mainctx_submodels.cpp maininterface/mainctx_submodels.hpp \
	maininterface/mainui.cpp \
	maininterface/mainui.hpp \
	maininterface/navigationmodel.cpp maininterface/navigationmodel.hpp \
	maininterface/videosurface.cpp \
	maininterface/videosurface.hpp \
	maininterface/video_window_handler.cpp \
	maininterface/video_window_handler.hpp \
	maininterface/windoweffects_module.hpp \
	medialibrary/medialib.cpp \
	medialibrary/medialib.hpp \
	medialibrary/mlmediastore.cpp \
	medialibrary/mlmediastore.hpp \
	medialibrary/mlalbum.cpp \
	medialibrary/mlalbum.hpp \
	medialibrary/mlalbummodel.cpp \
	medialibrary/mlalbummodel.hpp \
	medialibrary/mlaudio.cpp \
	medialibrary/mlaudio.hpp \
	medialibrary/mlaudiomodel.cpp \
	medialibrary/mlaudiomodel.hpp \
	medialibrary/mlartist.cpp \
	medialibrary/mlartist.hpp \
	medialibrary/mlartistmodel.cpp \
	medialibrary/mlartistmodel.hpp \
	medialibrary/mlbasemodel.cpp \
	medialibrary/mlbasemodel.hpp \
	medialibrary/mlbookmarkmodel.cpp \
	medialibrary/mlbookmarkmodel.hpp \
	medialibrary/mlevent.hpp \
	medialibrary/mlfolder.cpp \
	medialibrary/mlfolder.hpp \
	medialibrary/mlfoldersmodel.cpp \
	medialibrary/mlfoldersmodel.hpp \
	medialibrary/mlgenre.cpp \
	medialibrary/mlgenre.hpp \
	medialibrary/mlgenremodel.cpp \
	medialibrary/mlgenremodel.hpp \
	medialibrary/mlgroup.cpp \
	medialibrary/mlgroup.hpp \
	medialibrary/mlhelper.cpp \
	medialibrary/mlhelper.hpp \
	medialibrary/mlthreadpool.cpp \
	medialibrary/mlthreadpool.hpp \
	medialibrary/mlqmltypes.hpp \
	medialibrary/mlmedia.hpp \
	medialibrary/mlqueryparams.cpp \
	medialibrary/mlqueryparams.hpp \
	medialibrary/mlrecentmediamodel.cpp \
	medialibrary/mlrecentmediamodel.hpp \
	medialibrary/mlrecentaudiomodel.cpp \
	medialibrary/mlrecentaudiomodel.hpp \
	medialibrary/mlrecentvideomodel.cpp \
	medialibrary/mlrecentvideomodel.hpp \
	medialibrary/mlurlmodel.cpp \
	medialibrary/mlurlmodel.hpp \
	medialibrary/mlvideo.cpp \
	medialibrary/mlvideo.hpp \
	medialibrary/mlvideofoldersmodel.cpp \
	medialibrary/mlvideofoldersmodel.hpp \
	medialibrary/mlvideogroupsmodel.cpp \
	medialibrary/mlvideogroupsmodel.hpp \
	medialibrary/mlmediamodel.cpp \
	medialibrary/mlmediamodel.hpp \
	medialibrary/mlvideomodel.cpp \
	medialibrary/mlvideomodel.hpp \
	medialibrary/mlplaylist.cpp \
	medialibrary/mlplaylist.hpp \
	medialibrary/mlplaylistlistmodel.cpp \
	medialibrary/mlplaylistlistmodel.hpp \
	medialibrary/mlplaylistmedia.cpp \
	medialibrary/mlplaylistmedia.hpp \
	medialibrary/mlplaylistmodel.cpp \
	medialibrary/mlplaylistmodel.hpp \
	medialibrary/thumbnailcollector.hpp \
	medialibrary/thumbnailcollector.cpp \
	medialibrary/mlcustomcover.hpp \
	medialibrary/mlcustomcover.cpp \
	menus/custom_menus.cpp \
	menus/custom_menus.hpp \
	menus/qml_menu_wrapper.cpp \
	menus/qml_menu_wrapper.hpp \
	menus/menus.cpp menus/menus.hpp \
	network/addonsmodel.cpp \
	network/addonsmodel.hpp \
	network/mediatreelistener.cpp \
	network/mediatreelistener.hpp \
	network/devicesourceprovider.cpp \
	network/devicesourceprovider.hpp \
	network/networkbasemodel.cpp \
	network/networkbasemodel.hpp \
	network/networkdevicemodel.cpp \
	network/networkdevicemodel.hpp \
	network/networksourcesmodel.cpp \
	network/networksourcesmodel.hpp \
	network/networkmediamodel.cpp \
	network/networkmediamodel.hpp \
	network/videofolderfilter.cpp \
	network/videofolderfilter.hpp \
	network/standardpathmodel.cpp \
	network/standardpathmodel.hpp \
	network/vlcmediasourcewrapper.hpp \
	style/qtthemeprovider.hpp \
	style/colorcontext.cpp \
	style/colorcontext.hpp \
	style/systempalette.cpp \
	style/systempalette.hpp \
	style/menustyle.cpp \
	style/menustyle.hpp \
	style/vlcicons.cpp 	style/vlcicons.hpp \
	style/defaultthemeproviders.hpp \
	style/systempalettethemeprovider.cpp \
	player/input_models.cpp player/input_models.hpp \
	player/delay_estimator.cpp \
	player/delay_estimator.hpp \
	player/seek_preview.cpp \
	player/seek_preview.hpp \
	player/audio_waveform.cpp \
	player/audio_waveform.hpp \
	player/subtitle_cues.cpp \
	player/subtitle_cues.hpp \
	player/player_controller.cpp player/player_controller.hpp player/player_controller_p.hpp \
	player/player_controlbar_model.cpp player/player_controlbar_model.hpp \
	player/control_list_model.cpp player/control_list_model.hpp \
	player/control_list_filter.cpp \
	player/control_list_filter.hpp \
	playlist/media.hpp \
	playlist/playlist_common.hpp \
	playlist/playlist_controller.cpp \
	playlist/playlist_controller.hpp \
	playlist/playlist_controller_p.hpp \
	playlist/playlist_item.cpp \
	playlist/playlist_item.hpp \
	playlist/playlist_model.cpp \
	playlist/playlist_model.hpp \
	playlist/playlist_model_p.hpp \
	util/asynctask.hpp \
	util/accessible_compat_attached.cpp util/accessible_compat_attached.hpp \
	util/audio_device_model.cpp  \
	util/audio_device_model.hpp \
	util/workerthreadset.hpp util/workerthreadset.cpp \
	util/base_model.hpp util/base_model_p.hpp util/base_model.cpp \
	util/color_scheme_model.cpp util/color_scheme_model.hpp \
	util/config_bridge.cpp util/config_bridge.hpp \
	util/settings_profiles.cpp util/settings_profiles.hpp \
	util/effects_bridge.cpp util/effects_bridge.hpp \
	util/opensubtitles.cpp util/opensubtitles.hpp \
	util/https_request.cpp util/https_request.hpp \
	util/update_check.cpp util/update_check.hpp \
	util/ui_notifier.cpp util/ui_notifier.hpp \
	util/color_svg_image_provider.cpp util/color_svg_image_provider.hpp \
	util/vlcaccess_image_provider.cpp util/vlcaccess_image_provider.hpp \
	util/covergenerator.cpp \
	util/covergenerator.hpp \
	util/imageluminanceextractor.cpp util/imageluminanceextractor.hpp \
	util/csdbuttonmodel.cpp util/csdbuttonmodel.hpp \
	util/csdmenu.cpp util/csdmenu.hpp \
	util/imagehelper.cpp util/imagehelper.hpp \
	util/keyhelper.cpp util/keyhelper.hpp \
	util/listcache.hxx util/listcache.hpp \
	util/listcacheloader.hpp \
	util/locallistcacheloader.hpp \
	util/locallistbasemodel.hpp \
	util/navigation_history.cpp util/navigation_history.hpp \
	util/item_key_event_filter.cpp \
	util/item_key_event_filter.hpp \
	util/flickable_scroll_handler.cpp \
	util/flickable_scroll_handler.hpp \
	util/qt_dirs.cpp util/qt_dirs.hpp \
	util/proxycolumnmodel.hpp \
	util/registry.cpp util/registry.hpp \
	util/renderer_manager.cpp util/renderer_manager.hpp \
	util/singleton.hpp \
	util/soutchain.cpp util/soutchain.hpp \
	util/validators.cpp util/validators.hpp \
	util/varcommon_p.hpp \
	util/varchoicemodel.cpp  util/varchoicemodel.hpp \
	util/variables.cpp util/variables.hpp \
	util/vlchotkeyconverter.cpp util/vlchotkeyconverter.hpp \
	util/vlctick.cpp \
	util/vlctick.hpp \
	util/shared_input_item.hpp \
	util/fast_gaussian_blur_template.h \
	util/effects_image_provider.cpp \
	util/effects_image_provider.hpp \
	util/qsgtextureview.cpp \
	util/qsgtextureview.hpp \
	util/dismiss_popup_event_filter.cpp \
	util/dismiss_popup_event_filter.hpp \
	util/list_selection_model.cpp \
	util/list_selection_model.hpp \
	util/model_recovery_agent.hpp \
	util/vlcqtmessagehandler.cpp \
	util/vlcqtmessagehandler.hpp \
	util/colorizedsvgicon.cpp \
	util/colorizedsvgicon.hpp \
	util/textureproviderobserver.cpp \
	util/textureproviderobserver.hpp \
	util/kirigamiwheelhandler.cpp \
	util/kirigamiwheelhandler.hpp \
	util/textureproviderindirection.cpp \
	util/textureproviderindirection.hpp \
	util/sgmanipulator.cpp \
	util/sgmanipulator.hpp \
	util/pointingtooltipattached.hpp \
	widgets/native/animators.cpp \
	widgets/native/animators.hpp \
	widgets/native/customwidgets.cpp widgets/native/customwidgets.hpp \
	widgets/native/csdthemeimage.cpp \
	widgets/native/csdthemeimage.hpp \
	widgets/native/interface_widgets.cpp \
	widgets/native/interface_widgets.hpp \
	widgets/native/navigation_attached.cpp \
	widgets/native/navigation_attached.hpp \
	widgets/native/mlfolderseditor.cpp \
	widgets/native/mlfolderseditor.hpp \
	widgets/native/qvlcframe.cpp \
	widgets/native/qvlcframe.hpp \
	widgets/native/searchlineedit.cpp widgets/native/searchlineedit.hpp \
	widgets/native/viewblockingrectangle.cpp widgets/native/viewblockingrectangle.hpp \
	widgets/native/doubleclickignoringitem.hpp

# Meta-object compilation

moc_verbose = $(moc_verbose_$(V))
moc_verbose_ = $(moc_verbose__$(AM_DEFAULT_VERBOSITY))
moc_verbose_0 = @echo "  MOC     " $@;
moc_verbose__0 = $(moc_verbose_0)

.hpp.moc.cpp:
	$(moc_verbose)$(MOC) $(MOC_CPPFLAGS) -o $@ $<

.cpp.moc:
	$(moc_verbose)$(MOC) $(MOC_CPPFLAGS) -o $@ $<

# These MOC files depend on the configure settings:
dialogs/dialogs_provider.moc.cpp dialogs/vlm/vlm.moc.cpp: $(top_builddir)/config.h

# opensubtitles.com API key ("From OpenSubtitles" in Add Subtitles). It is
# not in git: put it in a file named opensubtitles-api-key.txt at the top of
# the source tree. Without the file the key is empty and the feature is off.
BUILT_SOURCES += util/opensubtitles_key.h
util/opensubtitles_key.h: $(wildcard $(top_srcdir)/opensubtitles-api-key.txt)
	$(AM_V_GEN)$(MKDIR_P) util; \
	key=`cat "$(top_srcdir)/opensubtitles-api-key.txt" 2>/dev/null | tr -cd 'A-Za-z0-9_-'`; \
	echo "#define OPENSUBTITLES_API_KEY \"$$key\"" > $@.tmp && mv -f $@.tmp $@

nodist_libqt_plugin_la_SOURCES = \
	dialogs/bookmarks/bookmarks.moc.cpp \
	dialogs/dialogs/dialogmodel.moc.cpp \
	dialogs/dialogs_provider.moc.cpp \
	dialogs/epg/EPGChannels.moc.cpp \
	dialogs/epg/EPGProgram.moc.cpp \
	dialogs/epg/EPGRuler.moc.cpp \
	dialogs/epg/EPGView.moc.cpp \
	dialogs/epg/EPGWidget.moc.cpp \
	dialogs/epg/epg.moc.cpp \
	dialogs/epg/epgmodel.moc.cpp \
	dialogs/extended/extended.moc.cpp \
	dialogs/extended/v4l2controls.moc.cpp \
	dialogs/extended/extended_panels.moc.cpp \
	dialogs/extensions/extensions.moc.cpp \
	dialogs/extensions/extensiondialogmodel.moc.cpp \
	dialogs/extensions/extensions_manager.moc.cpp \
	dialogs/fingerprint/chromaprint.moc.cpp \
	dialogs/fingerprint/fingerprintdialog.moc.cpp \
	dialogs/fingerprint/fingerprintmodel.moc.cpp \
	dialogs/firstrun/firstrunwizard.moc.cpp \
	dialogs/gototime/gototime.moc.cpp \
	dialogs/help/aboutmodel.moc.cpp \
	dialogs/help/help.moc.cpp \
	dialogs/mediainfo/info_panels.moc.cpp \
	dialogs/mediainfo/info_widgets.moc.cpp \
	dialogs/mediainfo/mediainfo.moc.cpp \
	dialogs/mediainfo/mediainfomodel.moc.cpp \
	dialogs/messages/messagesmodel.moc.cpp \
	dialogs/vlm/vlmmodel.moc.cpp \
	dialogs/messages/messages.moc.cpp \
	dialogs/open/open.moc.cpp \
	dialogs/open/open_panels.moc.cpp \
	dialogs/open/openurl.moc.cpp \
	dialogs/open/openmedia.moc.cpp \
	dialogs/plugins/plugins.moc.cpp \
	dialogs/plugins/pluginshelper.moc.cpp \
	dialogs/podcast/podcast_configuration.moc.cpp \
	dialogs/preferences/complete_preferences.moc.cpp \
	dialogs/preferences/expert_model.moc.cpp \
	dialogs/preferences/expert_view.moc.cpp \
	dialogs/preferences/preferences.moc.cpp \
	dialogs/preferences/preferences_widgets.moc.cpp \
	dialogs/preferences/simple_preferences.moc.cpp \
	dialogs/sout/convert.moc.cpp \
	dialogs/sout/southelper.moc.cpp \
	dialogs/sout/profile_selector.moc.cpp \
	dialogs/sout/sout.moc.cpp \
	dialogs/sout/sout_widgets.moc.cpp \
	dialogs/systray/systray.moc.cpp \
	dialogs/toolbar/controlbar_profile.moc.cpp \
	dialogs/toolbar/controlbar_profile_model.moc.cpp \
	dialogs/playlists/playlists.moc.cpp \
	maininterface/compositor.moc.cpp \
	maininterface/compositor_common.moc.cpp \
	maininterface/compositor_dummy.moc.cpp \
	maininterface/compositor_platform.moc.cpp \
	maininterface/interface_window_handler.moc.cpp \
	maininterface/mainctx.moc.cpp \
	maininterface/mainctx_submodels.moc.cpp \
	maininterface/mainui.moc.cpp \
	maininterface/navigationmodel.moc.cpp \
	maininterface/videosurface.moc.cpp \
	maininterface/video_window_handler.moc.cpp \
	medialibrary/medialib.moc.cpp \
	medialibrary/mlmediastore.moc.cpp \
	medialibrary/mlalbummodel.moc.cpp \
	medialibrary/mlaudiomodel.moc.cpp \
	medialibrary/mlartistmodel.moc.cpp \
	medialibrary/mlbookmarkmodel.moc.cpp \
	medialibrary/mlbasemodel.moc.cpp \
	medialibrary/mlfoldersmodel.moc.cpp \
	medialibrary/mlgenremodel.moc.cpp \
	medialibrary/mlthreadpool.moc.cpp \
	medialibrary/mlqmltypes.moc.cpp \
	medialibrary/mlrecentmediamodel.moc.cpp \
	medialibrary/mlrecentaudiomodel.moc.cpp \
	medialibrary/mlrecentvideomodel.moc.cpp \
	medialibrary/mlurlmodel.moc.cpp \
	medialibrary/mlvideo.moc.cpp \
	medialibrary/mlmediamodel.moc.cpp \
	medialibrary/mlvideomodel.moc.cpp \
	medialibrary/mlplaylistlistmodel.moc.cpp \
	medialibrary/mlplaylistmodel.moc.cpp \
	medialibrary/mlvideofoldersmodel.moc.cpp \
	medialibrary/mlvideogroupsmodel.moc.cpp \
	medialibrary/thumbnailcollector.moc.cpp \
	menus/custom_menus.moc.cpp \
	menus/qml_menu_wrapper.moc.cpp \
	menus/menus.moc.cpp \
	network/addonsmodel.moc.cpp \
	network/devicesourceprovider.moc.cpp \
	network/networkdevicemodel.moc.cpp \
	network/networkbasemodel.moc.cpp \
	network/networksourcesmodel.moc.cpp \
	network/networkmediamodel.moc.cpp \
	network/videofolderfilter.moc.cpp \
	network/standardpathmodel.moc.cpp \
	style/colorcontext.moc.cpp \
	style/systempalette.moc.cpp \
	style/menustyle.moc.cpp \
	style/vlcicons.moc.cpp \
	player/delay_estimator.moc.cpp \
	player/seek_preview.moc.cpp \
	player/audio_waveform.moc.cpp \
	player/subtitle_cues.moc.cpp \
	player/input_models.moc.cpp \
	player/player_controller.moc.cpp \
	player/player_controlbar_model.moc.cpp \
	player/control_list_model.moc.cpp \
	player/control_list_filter.moc.cpp \
	playlist/playlist_controller.moc.cpp \
	playlist/playlist_item.moc.cpp \
	playlist/playlist_model.moc.cpp \
	util/asynctask.moc.cpp \
	util/accessible_compat_attached.moc.cpp \
	util/audio_device_model.moc.cpp \
	util/workerthreadset.moc.cpp \
	util/base_model.moc.cpp \
	util/color_scheme_model.moc.cpp \
	util/config_bridge.moc.cpp \
	util/effects_bridge.moc.cpp \
	util/opensubtitles.moc.cpp \
	util/update_check.moc.cpp \
	util/ui_notifier.moc.cpp \
	util/color_svg_image_provider.moc.cpp \
	util/vlcaccess_image_provider.moc.cpp \
	util/imageluminanceextractor.moc.cpp \
	util/csdbuttonmodel.moc.cpp \
	util/csdmenu.moc.cpp \
	util/keyhelper.moc.cpp \
	util/listcache.moc.cpp \
	util/locallistcacheloader.moc.cpp \
	util/navigation_history.moc.cpp \
	util/item_key_event_filter.moc.cpp \
	util/effects_image_provider.moc.cpp \
	util/flickable_scroll_handler.moc.cpp \
	util/renderer_manager.moc.cpp \
	util/validators.moc.cpp \
	util/varchoicemodel.moc.cpp \
	util/variables.moc.cpp \
	util/vlctick.moc.cpp \
	util/dismiss_popup_event_filter.moc.cpp \
	util/list_selection_model.moc.cpp \
	util/vlchotkeyconverter.moc.cpp \
	util/qsgtextureview.moc.cpp \
	util/textureproviderobserver.moc.cpp \
	util/kirigamiwheelhandler.moc.cpp \
	util/textureproviderindirection.moc.cpp \
	util/sgmanipulator.moc.cpp \
	util/pointingtooltipattached.moc.cpp \
	widgets/native/animators.moc.cpp \
	widgets/native/csdthemeimage.moc.cpp \
	widgets/native/customwidgets.moc.cpp \
	widgets/native/interface_widgets.moc.cpp \
	widgets/native/navigation_attached.moc.cpp \
	widgets/native/mlfolderseditor.moc.cpp \
	widgets/native/searchlineedit.moc.cpp \
	widgets/native/viewblockingrectangle.moc.cpp

nodist_libqt_plugin_la_SOURCES += \
	dialogs/extended/ui_equalizer.h \
	dialogs/extended/ui_video_effects.h \
	dialogs/fingerprint/ui_fingerprintdialog.h \
	dialogs/firstrun/ui_firstrunwizard.h \
	dialogs/help/ui_about.h \
	dialogs/help/ui_update.h \
	dialogs/messages/ui_messages_panel.h \
	dialogs/open/ui_open.h \
	dialogs/open/ui_open_capture.h \
	dialogs/open/ui_open_disk.h \
	dialogs/open/ui_open_file.h \
	dialogs/open/ui_open_net.h \
	dialogs/podcast/ui_podcast_configuration.h \
	dialogs/preferences/ui_sprefs_audio.h \
	dialogs/preferences/ui_sprefs_input.h \
	dialogs/preferences/ui_sprefs_interface.h \
	dialogs/preferences/ui_sprefs_medialibrary.h \
	dialogs/preferences/ui_sprefs_subtitles.h \
	dialogs/preferences/ui_sprefs_video.h \
	dialogs/sout/ui_profiles.h \
	dialogs/sout/ui_sout.h \
	dialogs/vlm/ui_vlm.h


# windows compositor

if HAVE_WIN32

libqt_plugin_la_SOURCES += \
	maininterface/mainctx_win32.cpp \
	maininterface/mainctx_win32.hpp \
	maininterface/compositor_win7.cpp \
	maininterface/compositor_win7.hpp \
	style/windowsthemeprovider.cpp \
	maininterface/win32windoweffects_module.cpp \
	maininterface/win32windoweffects_module.hpp \
	util/csdmenu_win32.c \
	util/csdmenu_win32.h

nodist_libqt_plugin_la_SOURCES += maininterface/mainctx_win32.moc.cpp \
	maininterface/compositor_win7.moc.cpp

libqt_plugin_la_SOURCES += \
	maininterface/compositor_dcomp.cpp \
	maininterface/compositor_dcomp.hpp \
	maininterface/compositor_dcomp_error.hpp \
	maininterface/compositor_dcomp_acrylicsurface.hpp \
	maininterface/compositor_dcomp_acrylicsurface.cpp

nodist_libqt_plugin_la_SOURCES += \
	maininterface/compositor_dcomp_acrylicsurface.moc.cpp \
	maininterface/compositor_dcomp.moc.cpp

endif

# X11 compositor

if HAVE_X
if HAVE_QT_XCB
if HAVE_XCB
if HAVE_XCB_DAMAGE
if HAVE_XCB_XFIXES

libqt_plugin_la_CXXFLAGS += -DQT_HAS_X11_COMPOSITOR \
	$(QT_X11_CFLAGS) $(XCB_RENDER_CFLAGS) $(XCB_COMPOSITE_CFLAGS) $(XCB_DAMAGE_CFLAGS) $(XCB_XFIXES_CFLAGS)

libqt_plugin_la_LIBADD += $(QT_X11_LIBS) $(XCB_RENDER_LIBS) $(XCB_COMPOSITE_LIBS) $(XCB_DAMAGE_LIBS) $(XCB_XFIXES_LIBS)

libqt_plugin_la_SOURCES += \
	maininterface/compositor_x11.cpp \
	maininterface/compositor_x11.hpp \
	maininterface/compositor_x11_renderclient.cpp \
	maininterface/compositor_x11_renderclient.hpp \
	maininterface/compositor_x11_renderwindow.cpp \
	maininterface/compositor_x11_renderwindow.hpp \
	maininterface/compositor_x11_uisurface.cpp \
	maininterface/compositor_x11_uisurface.hpp \
	maininterface/compositor_x11_utils.cpp \
	maininterface/compositor_x11_utils.hpp

nodist_libqt_plugin_la_SOURCES += \
	maininterface/compositor_x11.moc.cpp \
	maininterface/compositor_x11_renderclient.moc.cpp \
	maininterface/compositor_x11_renderwindow.moc.cpp \
	maininterface/compositor_x11_uisurface.moc.cpp

#extra X11 features

libqt_x11_plugin_la_CXXFLAGS = $(AM_CXXFLAGS) $(XCB_CFLAGS) $(XCB_RENDER_CFLAGS) $(XCB_COMPOSITE_CFLAGS) $(XCB_DAMAGE_CFLAGS) $(XCB_XFIXES_CFLAGS)
libqt_x11_plugin_la_LIBADD = $(XCB_LIBS) $(XCB_RENDER_LIBS) $(XCB_COMPOSITE_LIBS) $(XCB_DAMAGE_LIBS) $(XCB_XFIXES_LIBS)
libqt_x11_plugin_la_SOURCES = \
	maininterface/qt_x11_plugin.c \
	maininterface/compositor_x11_utils.hpp \
	maininterface/compositor_x11_utils.cpp \
	util/csdmenu_module.h \
	util/csdmenu_x11.cpp \
	util/csdmenu_x11.h

if ENABLE_QT
gui_PLUGINS += libqt_x11_plugin.la
endif

endif
endif
endif
endif
endif

# wayland compositor

if HAVE_WAYLAND
if HAVE_QT_GUI_PRIVATE

libqt_plugin_la_CPPFLAGS += -DQT_HAS_WAYLAND_COMPOSITOR

libqt_plugin_la_SOURCES += \
	maininterface/compositor_wayland.cpp \
	maininterface/compositor_wayland.hpp


nodist_libqt_plugin_la_SOURCES += \
	maininterface/compositor_wayland.moc.cpp

libqt_wayland_plugin_la_CFLAGS = $(AM_CFLAGS) $(WAYLAND_CLIENT_CFLAGS)
libqt_wayland_plugin_la_LIBADD =  $(WAYLAND_CLIENT_LIBS) $(LIBM)
libqt_wayland_plugin_la_SOURCES = \
	maininterface/qt_wayland_plugin.c \
	maininterface/compositor_wayland_module.c \
	maininterface/compositor_wayland_module.h

#if WAYLAND_PROTOCOLS
#if WAYLAND_SCANNER
libqt_wayland_plugin_la_CFLAGS += -DQT_HAS_WAYLAND_PROTOCOLS -I$(builddir)/maininterface

libqt_wayland_plugin_la_SOURCES += \
	util/csdmenu_wayland.c \
	util/csdmenu_wayland.h \
	util/csdmenu_module.h

nodist_libqt_wayland_plugin_la_SOURCES = \
	maininterface/xdg-shell-client-protocol.h \
	maininterface/xdg-shell-protocol.c

if HAVE_QT65
libqt_wayland_plugin_la_CFLAGS += -DQT_HAS_WAYLAND_FRACTIONAL_SCALING
nodist_libqt_wayland_plugin_la_SOURCES += \
	maininterface/viewporter-client-protocol.h \
	maininterface/viewporter-protocol.c

maininterface/viewporter-client-protocol.h: \
		$(WAYLAND_PROTOCOLS)/stable/viewporter/viewporter.xml
	$(AM_V_GEN)$(WAYLAND_SCANNER) client-header $< $@

maininterface/viewporter-protocol.c: \
		$(WAYLAND_PROTOCOLS)/stable/viewporter/viewporter.xml \
		maininterface/viewporter-client-protocol.h
	$(AM_V_GEN)$(WAYLAND_SCANNER) private-code $< $@
endif

BUILT_SOURCES += $(nodist_libqt_wayland_plugin_la_SOURCES)

maininterface/xdg-shell-client-protocol.h: $(WAYLAND_PROTOCOLS)/stable/xdg-shell/xdg-shell.xml
	$(AM_V_GEN)$(WAYLAND_SCANNER) client-header $< $@

maininterface/xdg-shell-protocol.c: $(WAYLAND_PROTOCOLS)/stable/xdg-shell/xdg-shell.xml
	$(AM_V_GEN)$(WAYLAND_SCANNER) private-code $< $@

#endif
#endif

if ENABLE_QT
gui_PLUGINS += libqt_wayland_plugin.la
endif

endif
endif

if !HAVE_WIN32
if HAVE_KF6WINDOWSYSTEM

libqt_plugin_la_CPPFLAGS += -DQT_HAS_KWINDOWSYSTEM_PLUGIN

libqt_kwindowsystem_plugin_la_CXXFLAGS = $(AM_CXXFLAGS) $(KF6WINDOWSYSTEM_CFLAGS)
libqt_kwindowsystem_plugin_la_LIBADD =  $(KF6WINDOWSYSTEM_LIBS) $(QT_LIBS)
libqt_kwindowsystem_plugin_la_LDFLAGS = $(AM_LDFLAGS) $(QT_LDFLAGS)
libqt_kwindowsystem_plugin_la_SOURCES = \
	maininterface/kwindowsystem_module.cpp

if ENABLE_QT
gui_PLUGINS += libqt_kwindowsystem_plugin.la
endif
endif
endif

# User interface compilation

uic_verbose = $(uic_verbose_$(V))
uic_verbose_ = $(uic_verbose__$(AM_DEFAULT_VERBOSITY))
uic_verbose_0 = @echo "  UIC     " $@;
uic_verbose__0 = $(uic_verbose_0)

MOC_CPPFLAGS = $(DEFS) \
	-I$(top_srcdir)/include -I$(top_builddir)/include -I$(top_builddir) \
	$(QT_MOC_INCLUDE_DIRS) \
	$(QT_CFLAGS) \
	$(libqt_plugin_la_CPPFLAGS)
if HAVE_DARWIN
MOC_CPPFLAGS += -DQ_OS_MAC
endif
if HAVE_WIN32
MOC_CPPFLAGS += -D_WIN32
endif

libqt_plugin_la_UI = \
	dialogs/extended/equalizer.ui \
	dialogs/extended/video_effects.ui \
	dialogs/fingerprint/fingerprintdialog.ui \
	dialogs/firstrun/firstrunwizard.ui \
	dialogs/help/about.ui \
	dialogs/help/update.ui \
	dialogs/messages/messages_panel.ui \
	dialogs/open/open.ui \
	dialogs/open/open_capture.ui \
	dialogs/open/open_disk.ui \
	dialogs/open/open_file.ui \
	dialogs/open/open_net.ui \
	dialogs/podcast/podcast_configuration.ui \
	dialogs/preferences/sprefs_audio.ui \
	dialogs/preferences/sprefs_input.ui \
	dialogs/preferences/sprefs_interface.ui \
	dialogs/preferences/sprefs_medialibrary.ui \
	dialogs/preferences/sprefs_subtitles.ui \
	dialogs/preferences/sprefs_video.ui \
	dialogs/sout/profiles.ui \
	dialogs/sout/sout.ui \
	dialogs/vlm/vlm.ui
EXTRA_DIST += $(libqt_plugin_la_UI)

ui_%.h: %.ui
	$(AM_V_at)$(MKDIR_P) "ui"
	$(AM_V_at)rm -f $@ $@.tmp
	$(AM_V_at)echo "#define Q_(a,b) QString::fromUtf8(_(a))" > $@.tmp
	$(uic_verbose)$(UIC) -tr "Q_" $< >> $@.tmp
	$(AM_V_at)sed -e 's/Q_(\"_(\\\"\(.*\)\\\")"/Q_("\1"/' $@.tmp >$@
	$(AM_V_at)rm -f $@.tmp

# Resources

libqt_plugin_la_RES = \
	pixmaps/VLCIcons.ttf \
	pixmaps/addons/addon_default.svg \
	pixmaps/addons/addon_broken.svg \
	pixmaps/addons/addon_blue.svg \
	pixmaps/addons/addon_cyan.svg \
	pixmaps/addons/addon_green.svg \
	pixmaps/addons/addon_magenta.svg \
	pixmaps/addons/addon_red.svg \
	pixmaps/addons/addon_yellow.svg \
	pixmaps/addons/addon_score.svg \
	pixmaps/icons/active_indicator.svg \
	pixmaps/icons/add.svg \
	pixmaps/icons/ic_album_cover.svg \
	pixmaps/icons/ic_aspect_ratio.svg \
	pixmaps/icons/atob.svg \
	pixmaps/icons/ic_audiosub.svg \
	pixmaps/icons/back.svg \
	pixmaps/icons/ic_fluent_bookmark.svg \
	pixmaps/icons/breadcrumb_prev.svg \
	pixmaps/icons/breadcrumb_sep.svg \
	pixmaps/icons/check.svg \
	pixmaps/icons/clear.svg \
	pixmaps/icons/close.svg \
	pixmaps/icons/ic_fluent_full_screen_minimize.svg \
	pixmaps/icons/del.svg \
	pixmaps/icons/download.svg \
	pixmaps/icons/dropzone.svg \
	pixmaps/icons/dvd_menu.svg \
	pixmaps/icons/dvd_next.svg \
	pixmaps/icons/dvd_prev.svg \
	pixmaps/icons/ic_fluent_arrow_eject.svg \
	pixmaps/icons/ellipsis.svg \
	pixmaps/icons/ic_playlist_add.svg \
	pixmaps/icons/expand_inverted.svg \
	pixmaps/icons/expand.svg \
	pixmaps/icons/ic_fluent_options.svg \
	pixmaps/icons/ic_fluent_fast_forward.svg \
	pixmaps/icons/ic_fluent_next_frame.svg \
	pixmaps/icons/ic_fluent_previous_frame.svg \
	pixmaps/icons/ic_fluent_full_screen_maximize.svg \
	pixmaps/icons/ic_fluent_grid.svg \
	pixmaps/icons/history.svg \
	pixmaps/icons/ic_fluent_home.svg \
	pixmaps/icons/ic_fluent_info.svg \
	pixmaps/icons/ic_fluent_apps_list.svg \
	pixmaps/icons/ic_fluent_more_vertical.svg \
	pixmaps/icons/multiselect.svg \
	pixmaps/icons/ok.svg \
	pixmaps/icons/ic_fluent_next.svg \
	pixmaps/icons/ic_pause_filled.svg \
	pixmaps/icons/pip.svg \
	pixmaps/icons/ic_playlist_clear.svg \
	pixmaps/icons/ic_playlist.svg \
	pixmaps/icons/ic_fluent_play.svg \
	pixmaps/icons/ic_fluent_play_reverse_filled.svg \
	pixmaps/icons/ic_fluent_arrow_move.svg \
	pixmaps/icons/ic_fluent_chevron_down_24.svg \
	pixmaps/icons/ic_fluent_chevron_left_24.svg \
	pixmaps/icons/ic_fluent_chevron_right_24.svg \
	pixmaps/icons/ic_fluent_chevron_up_24.svg \
	pixmaps/icons/ic_fluent_play_filled.svg \
	pixmaps/icons/podcast.svg \
	pixmaps/icons/ic_fluent_previous.svg \
	pixmaps/icons/profile_new.svg \
	pixmaps/icons/ic_fluent_record.svg \
	pixmaps/icons/remove.svg \
	pixmaps/icons/ic_fluent_cast.svg \
	pixmaps/icons/ic_fluent_arrow_repeat_all.svg \
	pixmaps/icons/ic_fluent_arrow_repeat_1.svg \
	pixmaps/icons/ic_fluent_rewind.svg \
	pixmaps/icons/ic_fluent_search.svg \
	pixmaps/icons/ic_fluent_arrow_shuffle.svg \
	pixmaps/icons/ic_fluent_skip_back_10.svg \
	pixmaps/icons/ic_fluent_skip_forward_10.svg \
	pixmaps/icons/ic_fluent_camera.svg \
	pixmaps/icons/ic_fluent_spacebar.svg \
	pixmaps/icons/ic_fluent_stop.svg \
	pixmaps/icons/stream.svg \
	pixmaps/icons/sync.svg \
	pixmaps/icons/ic_fluent_clock.svg \
	pixmaps/icons/ic_fluent_globe.svg \
	pixmaps/icons/topbar_filter.svg \
	pixmaps/icons/ic_fluent_music_note_2.svg \
	pixmaps/icons/ic_fluent_wifi_1.svg \
	pixmaps/icons/ic_fluent_arrow_sort.svg \
	pixmaps/icons/ic_fluent_filmstrip.svg \
	pixmaps/icons/ic_fluent_chevron_up.svg \
	pixmaps/icons/ic_fluent_chevron_down.svg \
	pixmaps/icons/ic_fluent_tv.svg \
	pixmaps/icons/ic_tvtelx.svg \
	pixmaps/icons/visualization.svg \
	pixmaps/icons/volume_high.svg \
	pixmaps/icons/volume_low.svg \
	pixmaps/icons/volume_medium.svg \
	pixmaps/icons/volume_muted.svg \
	pixmaps/icons/volume_zero.svg \
	pixmaps/icons/window_close.svg \
	pixmaps/icons/window_maximize.svg \
	pixmaps/icons/window_minimize.svg \
	pixmaps/icons/window_restore.svg \
	pixmaps/icons/ic_fluent_arrow_download_24_regular.svg \
	pixmaps/icons/ic_fluent_arrow_sync_24_regular.svg \
	pixmaps/icons/figma/backward_10_sec.svg \
	pixmaps/icons/figma/close_low.svg \
	pixmaps/icons/figma/close_none.svg \
	pixmaps/icons/figma/forward_10_sec.svg \
	pixmaps/icons/figma/lists.svg \
	pixmaps/icons/figma/preferences.svg \
	pixmaps/icons/figma/speed.svg \
	pixmaps/icons/figma/volume_high.svg \
	pixmaps/icons/regex.svg \
	pixmaps/icons/ic_fluent_text_change_case_24_regular.svg \
	pixmaps/menu/add.svg \
	pixmaps/menu/capture-card.svg \
	pixmaps/menu/clear.svg \
	pixmaps/menu/disc.svg \
	pixmaps/menu/download.svg \
	pixmaps/menu/ic_fluent_arrow_eject.svg \
	pixmaps/menu/exit.svg \
	pixmaps/menu/ic_fluent_fast_forward.svg \
	pixmaps/menu/file.svg \
	pixmaps/menu/folder.svg \
	pixmaps/menu/help.svg \
	pixmaps/menu/info.svg \
	pixmaps/menu/media_library.svg \
	pixmaps/menu/messages.svg \
	pixmaps/menu/movie.svg \
	pixmaps/menu/music.svg \
	pixmaps/menu/network.svg \
	pixmaps/menu/ic_playlist.svg \
	pixmaps/menu/ic_fluent_next.svg \
	pixmaps/menu/ic_pause_filled.svg \
	pixmaps/menu/ic_fluent_play_filled.svg \
	pixmaps/menu/preferences.svg \
	pixmaps/menu/ic_fluent_previous.svg \
	pixmaps/menu/profile_new.svg \
	pixmaps/menu/ic_fluent_record.svg \
	pixmaps/menu/remove.svg \
	pixmaps/menu/ic_fluent_arrow_repeat_all.svg \
	pixmaps/menu/repeat_off.svg \
	pixmaps/menu/ic_fluent_arrow_repeat_1.svg \
	pixmaps/menu/ic_fluent_rewind.svg \
	pixmaps/menu/search_clear.svg \
	pixmaps/menu/ic_fluent_options.svg \
	pixmaps/menu/ic_fluent_skip_back_10.svg \
	pixmaps/menu/ic_fluent_skip_forward_10.svg \
	pixmaps/menu/ic_fluent_arrow_shuffle.svg \
	pixmaps/menu/ic_fluent_stop.svg \
	pixmaps/menu/figma/main_about_vlc.svg \
	pixmaps/menu/figma/main_convert.svg \
	pixmaps/menu/figma/main_customize_player.svg \
	pixmaps/menu/figma/main_keyboard_shortcuts.svg \
	pixmaps/menu/figma/main_new.svg \
	pixmaps/menu/figma/main_open_capture_device.svg \
	pixmaps/menu/figma/main_open_disc.svg \
	pixmaps/menu/figma/main_open_file_s.svg \
	pixmaps/menu/figma/main_open_folder.svg \
	pixmaps/menu/figma/main_open_network_stream.svg \
	pixmaps/menu/figma/main_open_recent.svg \
	pixmaps/menu/figma/main_profile.svg \
	pixmaps/menu/figma/main_settings.svg \
	pixmaps/menu/figma/file_add_audio_tracks.svg \
	pixmaps/menu/figma/file_add_subtitle_tracks.svg \
	pixmaps/menu/figma/file_add_to_playlist.svg \
	pixmaps/menu/figma/file_add_to_queue.svg \
	pixmaps/menu/figma/file_convert.svg \
	pixmaps/menu/figma/file_favorite.svg \
	pixmaps/menu/figma/file_go_to_source.svg \
	pixmaps/menu/figma/file_mark_as_watched.svg \
	pixmaps/menu/figma/file_play.svg \
	pixmaps/menu/figma/file_remove_from_home.svg \
	pixmaps/menu/figma/eq_classical.svg \
	pixmaps/menu/figma/eq_club.svg \
	pixmaps/menu/figma/eq_dance.svg \
	pixmaps/menu/figma/eq_flat.svg \
	pixmaps/menu/figma/eq_fullbass.svg \
	pixmaps/menu/figma/eq_fullbasstreble.svg \
	pixmaps/menu/figma/eq_fulltreble.svg \
	pixmaps/menu/figma/eq_headphones.svg \
	pixmaps/menu/figma/eq_largehall.svg \
	pixmaps/menu/figma/eq_live.svg \
	pixmaps/menu/figma/eq_party.svg \
	pixmaps/menu/figma/eq_pop.svg \
	pixmaps/menu/figma/eq_reggae.svg \
	pixmaps/menu/figma/eq_rock.svg \
	pixmaps/menu/figma/eq_ska.svg \
	pixmaps/menu/figma/eq_soft.svg \
	pixmaps/menu/figma/eq_softrock.svg \
	pixmaps/menu/figma/eq_techno.svg \
	pixmaps/menu/figma/file_properties_metadata.svg \
	pixmaps/menu/figma/file_show_in_file_explorer.svg \
	pixmaps/menu/figma/file_stream.svg \
	pixmaps/menu/figma/folder_add_file.svg \
	pixmaps/menu/figma/folder_add_folder.svg \
	pixmaps/menu/figma/folder_edit_audio_tracks.svg \
	pixmaps/menu/figma/folder_edit_subtitle_tracks.svg \
	pixmaps/menu/figma/folder_info.svg \
	pixmaps/menu/figma/folder_resync.svg \
	pixmaps/menu/figma/player_audio.svg \
	pixmaps/menu/figma/player_hide_ui.svg \
	pixmaps/menu/figma/player_more_settings.svg \
	pixmaps/menu/figma/player_next_item.svg \
	pixmaps/menu/figma/player_open_media.svg \
	pixmaps/menu/figma/player_pause.svg \
	pixmaps/menu/figma/player_play.svg \
	pixmaps/menu/figma/player_playback.svg \
	pixmaps/menu/figma/player_playlist.svg \
	pixmaps/menu/figma/player_previous_item.svg \
	pixmaps/menu/figma/player_quit_vlc.svg \
	pixmaps/menu/figma/player_record.svg \
	pixmaps/menu/figma/player_stop.svg \
	pixmaps/menu/figma/player_subtitle.svg \
	pixmaps/menu/figma/player_video.svg \
	pixmaps/menu/figma/playlist_add_audio_tracks.svg \
	pixmaps/menu/figma/playlist_add_subtitle_tracks.svg \
	pixmaps/menu/figma/playlist_add_to_queue.svg \
	pixmaps/menu/figma/playlist_export_playlist.svg \
	pixmaps/menu/figma/playlist_favorite.svg \
	pixmaps/menu/figma/playlist_play.svg \
	pixmaps/menu/figma/playlist_properties_metadata.svg \
	pixmaps/menu/figma/playlist_shuffle.svg \
	pixmaps/menu/figma/view_grid_view.svg \
	pixmaps/menu/figma/view_list_view.svg \
	pixmaps/menu/stream.svg \
	pixmaps/menu/sync.svg \
	pixmaps/menu/update.svg \
	pixmaps/menu/volume-high.svg \
	pixmaps/menu/volume-low.svg \
	pixmaps/menu/volume-muted.svg \
	pixmaps/misc/cone.svg \
	pixmaps/misc/new_indicator.svg \
	pixmaps/misc/onboarding_system_tile.svg \
	pixmaps/misc/theme_dark.svg \
	pixmaps/misc/theme_daynight.svg \
	pixmaps/misc/theme_light.svg \
	pixmaps/misc/volume_fill.svg \
	pixmaps/misc/cone_flat.svg \
	pixmaps/misc/cone_rounded.svg \
	pixmaps/misc/rail_home_selected.svg \
	pixmaps/flags/ad.svg \
	pixmaps/flags/ae.svg \
	pixmaps/flags/af.svg \
	pixmaps/flags/ag.svg \
	pixmaps/flags/ai.svg \
	pixmaps/flags/al.svg \
	pixmaps/flags/am.svg \
	pixmaps/flags/ao.svg \
	pixmaps/flags/aq.svg \
	pixmaps/flags/ar.svg \
	pixmaps/flags/arab.svg \
	pixmaps/flags/as.svg \
	pixmaps/flags/asean.svg \
	pixmaps/flags/at.svg \
	pixmaps/flags/au.svg \
	pixmaps/flags/aw.svg \
	pixmaps/flags/ax.svg \
	pixmaps/flags/az.svg \
	pixmaps/flags/ba.svg \
	pixmaps/flags/bb.svg \
	pixmaps/flags/bd.svg \
	pixmaps/flags/be.svg \
	pixmaps/flags/bf.svg \
	pixmaps/flags/bg.svg \
	pixmaps/flags/bh.svg \
	pixmaps/flags/bi.svg \
	pixmaps/flags/bj.svg \
	pixmaps/flags/bl.svg \
	pixmaps/flags/bm.svg \
	pixmaps/flags/bn.svg \
	pixmaps/flags/bo.svg \
	pixmaps/flags/bq.svg \
	pixmaps/flags/br.svg \
	pixmaps/flags/bs.svg \
	pixmaps/flags/bt.svg \
	pixmaps/flags/bv.svg \
	pixmaps/flags/bw.svg \
	pixmaps/flags/by.svg \
	pixmaps/flags/bz.svg \
	pixmaps/flags/ca.svg \
	pixmaps/flags/cc.svg \
	pixmaps/flags/cd.svg \
	pixmaps/flags/cefta.svg \
	pixmaps/flags/cf.svg \
	pixmaps/flags/cg.svg \
	pixmaps/flags/ch.svg \
	pixmaps/flags/ci.svg \
	pixmaps/flags/ck.svg \
	pixmaps/flags/cl.svg \
	pixmaps/flags/cm.svg \
	pixmaps/flags/cn.svg \
	pixmaps/flags/co.svg \
	pixmaps/flags/cp.svg \
	pixmaps/flags/cr.svg \
	pixmaps/flags/cu.svg \
	pixmaps/flags/cv.svg \
	pixmaps/flags/cw.svg \
	pixmaps/flags/cx.svg \
	pixmaps/flags/cy.svg \
	pixmaps/flags/cz.svg \
	pixmaps/flags/de.svg \
	pixmaps/flags/dg.svg \
	pixmaps/flags/dj.svg \
	pixmaps/flags/dk.svg \
	pixmaps/flags/dm.svg \
	pixmaps/flags/do.svg \
	pixmaps/flags/dz.svg \
	pixmaps/flags/eac.svg \
	pixmaps/flags/ec.svg \
	pixmaps/flags/ee.svg \
	pixmaps/flags/eg.svg \
	pixmaps/flags/eh.svg \
	pixmaps/flags/er.svg \
	pixmaps/flags/es.svg \
	pixmaps/flags/et.svg \
	pixmaps/flags/eu.svg \
	pixmaps/flags/fi.svg \
	pixmaps/flags/fj.svg \
	pixmaps/flags/fk.svg \
	pixmaps/flags/fm.svg \
	pixmaps/flags/fo.svg \
	pixmaps/flags/fr.svg \
	pixmaps/flags/ga.svg \
	pixmaps/flags/gb.svg \
	pixmaps/flags/gd.svg \
	pixmaps/flags/ge.svg \
	pixmaps/flags/gf.svg \
	pixmaps/flags/gg.svg \
	pixmaps/flags/gh.svg \
	pixmaps/flags/gi.svg \
	pixmaps/flags/gl.svg \
	pixmaps/flags/gm.svg \
	pixmaps/flags/gn.svg \
	pixmaps/flags/gp.svg \
	pixmaps/flags/gq.svg \
	pixmaps/flags/gr.svg \
	pixmaps/flags/gs.svg \
	pixmaps/flags/gt.svg \
	pixmaps/flags/gu.svg \
	pixmaps/flags/gw.svg \
	pixmaps/flags/gy.svg \
	pixmaps/flags/hk.svg \
	pixmaps/flags/hm.svg \
	pixmaps/flags/hn.svg \
	pixmaps/flags/hr.svg \
	pixmaps/flags/ht.svg \
	pixmaps/flags/hu.svg \
	pixmaps/flags/ic.svg \
	pixmaps/flags/id.svg \
	pixmaps/flags/ie.svg \
	pixmaps/flags/il.svg \
	pixmaps/flags/im.svg \
	pixmaps/flags/in.svg \
	pixmaps/flags/io.svg \
	pixmaps/flags/iq.svg \
	pixmaps/flags/ir.svg \
	pixmaps/flags/is.svg \
	pixmaps/flags/it.svg \
	pixmaps/flags/je.svg \
	pixmaps/flags/jm.svg \
	pixmaps/flags/jo.svg \
	pixmaps/flags/jp.svg \
	pixmaps/flags/ke.svg \
	pixmaps/flags/kg.svg \
	pixmaps/flags/kh.svg \
	pixmaps/flags/ki.svg \
	pixmaps/flags/km.svg \
	pixmaps/flags/kn.svg \
	pixmaps/flags/kp.svg \
	pixmaps/flags/kr.svg \
	pixmaps/flags/kw.svg \
	pixmaps/flags/ky.svg \
	pixmaps/flags/kz.svg \
	pixmaps/flags/la.svg \
	pixmaps/flags/lb.svg \
	pixmaps/flags/lc.svg \
	pixmaps/flags/li.svg \
	pixmaps/flags/lk.svg \
	pixmaps/flags/lr.svg \
	pixmaps/flags/ls.svg \
	pixmaps/flags/lt.svg \
	pixmaps/flags/lu.svg \
	pixmaps/flags/lv.svg \
	pixmaps/flags/ly.svg \
	pixmaps/flags/ma.svg \
	pixmaps/flags/mc.svg \
	pixmaps/flags/md.svg \
	pixmaps/flags/me.svg \
	pixmaps/flags/mf.svg \
	pixmaps/flags/mg.svg \
	pixmaps/flags/mh.svg \
	pixmaps/flags/mk.svg \
	pixmaps/flags/ml.svg \
	pixmaps/flags/mm.svg \
	pixmaps/flags/mn.svg \
	pixmaps/flags/mo.svg \
	pixmaps/flags/mp.svg \
	pixmaps/flags/mq.svg \
	pixmaps/flags/mr.svg \
	pixmaps/flags/ms.svg \
	pixmaps/flags/mt.svg \
	pixmaps/flags/mu.svg \
	pixmaps/flags/mv.svg \
	pixmaps/flags/mw.svg \
	pixmaps/flags/mx.svg \
	pixmaps/flags/my.svg \
	pixmaps/flags/mz.svg \
	pixmaps/flags/na.svg \
	pixmaps/flags/nc.svg \
	pixmaps/flags/ne.svg \
	pixmaps/flags/nf.svg \
	pixmaps/flags/ng.svg \
	pixmaps/flags/ni.svg \
	pixmaps/flags/nl.svg \
	pixmaps/flags/no.svg \
	pixmaps/flags/np.svg \
	pixmaps/flags/nr.svg \
	pixmaps/flags/nu.svg \
	pixmaps/flags/nz.svg \
	pixmaps/flags/om.svg \
	pixmaps/flags/pa.svg \
	pixmaps/flags/pc.svg \
	pixmaps/flags/pe.svg \
	pixmaps/flags/pf.svg \
	pixmaps/flags/pg.svg \
	pixmaps/flags/ph.svg \
	pixmaps/flags/pk.svg \
	pixmaps/flags/pl.svg \
	pixmaps/flags/pm.svg \
	pixmaps/flags/pn.svg \
	pixmaps/flags/pr.svg \
	pixmaps/flags/ps.svg \
	pixmaps/flags/pt.svg \
	pixmaps/flags/pw.svg \
	pixmaps/flags/py.svg \
	pixmaps/flags/qa.svg \
	pixmaps/flags/re.svg \
	pixmaps/flags/ro.svg \
	pixmaps/flags/rs.svg \
	pixmaps/flags/ru.svg \
	pixmaps/flags/rw.svg \
	pixmaps/flags/sa.svg \
	pixmaps/flags/sb.svg \
	pixmaps/flags/sc.svg \
	pixmaps/flags/sd.svg \
	pixmaps/flags/se.svg \
	pixmaps/flags/sg.svg \
	pixmaps/flags/sh.svg \
	pixmaps/flags/si.svg \
	pixmaps/flags/sj.svg \
	pixmaps/flags/sk.svg \
	pixmaps/flags/sl.svg \
	pixmaps/flags/sm.svg \
	pixmaps/flags/sn.svg \
	pixmaps/flags/so.svg \
	pixmaps/flags/sr.svg \
	pixmaps/flags/ss.svg \
	pixmaps/flags/st.svg \
	pixmaps/flags/sv.svg \
	pixmaps/flags/sx.svg \
	pixmaps/flags/sy.svg \
	pixmaps/flags/sz.svg \
	pixmaps/flags/tc.svg \
	pixmaps/flags/td.svg \
	pixmaps/flags/tf.svg \
	pixmaps/flags/tg.svg \
	pixmaps/flags/th.svg \
	pixmaps/flags/tj.svg \
	pixmaps/flags/tk.svg \
	pixmaps/flags/tl.svg \
	pixmaps/flags/tm.svg \
	pixmaps/flags/tn.svg \
	pixmaps/flags/to.svg \
	pixmaps/flags/tr.svg \
	pixmaps/flags/tt.svg \
	pixmaps/flags/tv.svg \
	pixmaps/flags/tw.svg \
	pixmaps/flags/tz.svg \
	pixmaps/flags/ua.svg \
	pixmaps/flags/ug.svg \
	pixmaps/flags/um.svg \
	pixmaps/flags/un.svg \
	pixmaps/flags/us.svg \
	pixmaps/flags/uy.svg \
	pixmaps/flags/uz.svg \
	pixmaps/flags/va.svg \
	pixmaps/flags/vc.svg \
	pixmaps/flags/ve.svg \
	pixmaps/flags/vg.svg \
	pixmaps/flags/vi.svg \
	pixmaps/flags/vn.svg \
	pixmaps/flags/vu.svg \
	pixmaps/flags/wf.svg \
	pixmaps/flags/ws.svg \
	pixmaps/flags/xk.svg \
	pixmaps/flags/xx.svg \
	pixmaps/flags/ye.svg \
	pixmaps/flags/yt.svg \
	pixmaps/flags/za.svg \
	pixmaps/flags/zm.svg \
	pixmaps/flags/zw.svg \
	pixmaps/misc/rail_video_selected.svg \
	pixmaps/misc/rail_music_selected.svg \
	pixmaps/misc/rail_network_selected.svg \
	pixmaps/misc/rail_playlists_selected.svg \
	pixmaps/misc/volume_track_dark.svg \
	pixmaps/misc/volume_track_light.svg \
	pixmaps/misc/wait1.svg \
	pixmaps/misc/wait2.svg \
	pixmaps/misc/wait3.svg \
	pixmaps/misc/wait4.svg \
	pixmaps/placeholder/add_service.svg \
	pixmaps/placeholder/noart.png \
	pixmaps/placeholder/noart_album.svg \
	pixmaps/placeholder/noart_albumCover.svg \
	pixmaps/placeholder/noart_artist.svg \
	pixmaps/placeholder/noart_artistCover.svg \
	pixmaps/placeholder/noart_artist_small.svg \
	pixmaps/placeholder/noart_videoCover.svg \
	pixmaps/prefs/advprefs_audio.svg \
	pixmaps/prefs/advprefs_codec.svg \
	pixmaps/prefs/advprefs_extended.svg \
	pixmaps/prefs/advprefs_intf.svg \
	pixmaps/prefs/advprefs_playlist.svg \
	pixmaps/prefs/advprefs_sout.svg \
	pixmaps/prefs/advprefs_video.svg \
	pixmaps/prefs/sample_complete.png \
	pixmaps/prefs/sample_minimal.png \
	pixmaps/prefs/sample_skins.png \
	pixmaps/prefs/spref_audio.png \
	pixmaps/prefs/spref_hotkeys.png \
	pixmaps/prefs/spref_input.png \
	pixmaps/prefs/spref_interface.png \
	pixmaps/prefs/spref_medialibrary.png \
	pixmaps/prefs/spref_subtitles.png \
	pixmaps/prefs/spref_video.png \
	pixmaps/sd/assembleenationale.svg \
	pixmaps/sd/capture-card.svg \
	pixmaps/sd/directory.svg \
	pixmaps/sd/disc.svg \
	pixmaps/sd/file.svg \
	pixmaps/sd/fmc.svg \
	pixmaps/sd/frenchtv.svg \
	pixmaps/sd/harddisk.svg \
	pixmaps/sd/icecast.svg \
	pixmaps/sd/jamendo.svg \
	pixmaps/sd/katsomo.svg \
	pixmaps/sd/lan.svg \
	pixmaps/sd/library.svg \
	pixmaps/sd/metachannels.svg \
	pixmaps/sd/mtp.svg \
	pixmaps/sd/network.svg \
	pixmaps/sd/node.svg \
	pixmaps/sd/pictures.svg \
	pixmaps/sd/playlist.svg \
	pixmaps/sd/podcast.svg \
	pixmaps/sd/radio.svg \
	pixmaps/sd/screen.svg \
	pixmaps/sd/stream.svg \
	pixmaps/sd/unknown.svg

if HAVE_WIN32
libqt_plugin_la_RES += \
	pixmaps/win7/pause.svg \
	pixmaps/win7/prev.svg \
	pixmaps/win7/next.svg \
	pixmaps/win7/play.svg
endif

# QML modules
#
# Each QML module has a small section below. To add a new module "foo", append
# a section following this template:
#
#   libqml_module_foo_a_Module     = VLC.Foo
#   libqml_module_foo_a_ModulePath = VLC/Foo
#   libqml_module_foo_a_CXXFLAGS   = $(libqt_plugin_la_CXXFLAGS)
#   libqml_module_foo_a_CPPFLAGS   = $(libqt_plugin_la_CPPFLAGS)
#   libqml_module_foo_a_SOURCES    = $(QML_MODULE_foo_SRC)
#   libqml_module_foo_a_QML 			 = foo/qml/Bar.qml # ...
#   libqml_module_foo_a_Singleton_QML  = foo/qml/SingletonBar.qml # only when there are Singletons
#   nodist_libqml_module_foo_a_SOURCES = foo/qmlassets.cpp $(QML_MODULE_foo_NODIST_EXTRA)
#   QML_MODULE_LIBS += libqml_module_foo.a
#
# When exposing singletons, list those QML files in the proper variable so that
# they are declared as singletons in the generated qmldir.
#
# Then:
#   1. Add "foo" to libqt_plugin_la_QML_MODULES.
#   2. Add the QML file lists to libqt_plugin_la_ALL_QML.
#   3. Add a QML_MODULE_foo_SRC / QML_MODULE_foo_NODIST_EXTRA pair to the
#      "if HAVE_QMLCACHEGEN" block below.
#
noinst_LIBRARIES =
QML_MODULE_LIBS =

libqml_module_dialogs_a_Module = VLC.Dialogs
libqml_module_dialogs_a_ModulePath = VLC/Dialogs
libqml_module_dialogs_a_CXXFLAGS = $(libqt_plugin_la_CXXFLAGS)
libqml_module_dialogs_a_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
libqml_module_dialogs_a_QML = \
	dialogs/dialogs/qml/CustomDialog.qml \
	dialogs/dialogs/qml/Dialogs.qml \
	dialogs/dialogs/qml/ModalDialog.qml \
	dialogs/dialogs/qml/WindowDialog.qml \
	dialogs/settings/qml/AllSettingsView.qml \
	dialogs/settings/qml/EqualizerPanel.qml \
	dialogs/settings/qml/SettingRow.qml \
	dialogs/settings/qml/SettingsModel.qml \
	dialogs/settings/qml/SettingsWindow.qml \
	dialogs/figma/qml/FigmaDialog.qml \
	dialogs/figma/qml/NetworkStreamDialog.qml \
	dialogs/figma/qml/OpenMediaDialog.qml \
	dialogs/figma/qml/MediaInfoDialog.qml \
	dialogs/figma/qml/ConfirmDialog.qml \
	dialogs/figma/qml/NewPlaylistDialog.qml \
	dialogs/figma/qml/PlaylistPropertiesDialog.qml \
	dialogs/figma/qml/PlaylistThumbnailBox.qml \
	dialogs/figma/qml/DashedBorder.qml \
	dialogs/figma/qml/KeyboardShortcutsDialog.qml \
	dialogs/figma/qml/AddSubtitlesDialog.qml \
	dialogs/figma/qml/CustomizePlayerDialog.qml \
	dialogs/figma/qml/OnboardingWindow.qml \
	dialogs/window/qml/RedesignWindow.qml \
	dialogs/window/qml/WinButton.qml \
	dialogs/window/qml/WinCheck.qml \
	dialogs/window/qml/WinDescription.qml \
	dialogs/window/qml/WinDialogFooter.qml \
	dialogs/window/qml/WinDropdown.qml \
	dialogs/window/qml/WinEditCombo.qml \
	dialogs/window/qml/WinField.qml \
	dialogs/window/qml/WinInfoRow.qml \
	dialogs/window/qml/WinLabel.qml \
	dialogs/window/qml/WinList.qml \
	dialogs/window/qml/WinListRow.qml \
	dialogs/window/qml/WinNumberField.qml \
	dialogs/window/qml/WinRow.qml \
	dialogs/window/qml/WinScrollBar.qml \
	dialogs/window/qml/WinSectionTitle.qml \
	dialogs/window/qml/WinSlider.qml \
	dialogs/window/qml/WinSliderRow.qml \
	dialogs/window/qml/WinTabBar.qml \
	dialogs/window/qml/WinTextArea.qml \
	dialogs/window/qml/WinToggle.qml \
	dialogs/window/qml/WinToolTip.qml \
	dialogs/window/qml/WinValueText.qml \
	dialogs/window/qml/GotoTimeWindow.qml \
	dialogs/window/qml/ProfileEditorWindow.qml \
	dialogs/window/qml/ProfileRow.qml \
	dialogs/window/qml/StreamWindow.qml \
	dialogs/window/qml/ConvertWindow.qml \
	dialogs/window/qml/EffectsWindow.qml \
	dialogs/window/qml/ExtensionWindow.qml \
	dialogs/window/qml/VlmWindow.qml \
	dialogs/window/qml/EpgWindow.qml \
	dialogs/window/qml/FingerprintWindow.qml \
	dialogs/window/qml/PluginsWindow.qml \
	dialogs/window/qml/AddToPlaylistWindow.qml \
	dialogs/window/qml/OpenUrlWindow.qml \
	dialogs/window/qml/PodcastWindow.qml \
	dialogs/window/qml/MessagesWindow.qml \
	dialogs/window/qml/BookmarksWindow.qml \
	dialogs/window/qml/HelpWindow.qml \
	dialogs/window/qml/UpdateWindow.qml \
	dialogs/window/qml/AboutWindow.qml \
	dialogs/toolbar/qml/EditorDNDDelegate.qml \
	dialogs/toolbar/qml/EditorDNDView.qml\
	dialogs/toolbar/qml/EditorDummyButton.qml \
	dialogs/toolbar/qml/EditorTabButton.qml \
	dialogs/toolbar/qml/ToolbarEditor.qml \
	dialogs/toolbar/qml/ToolbarEditorDialog.qml \
	dialogs/toolbar/qml/ToolbarEditorButtonList.qml
libqml_module_dialogs_a_Singleton_QML = \
	dialogs/window/qml/WinStyle.qml
libqml_module_dialogs_a_SOURCES = $(QML_MODULE_dialogs_SRC)
nodist_libqml_module_dialogs_a_SOURCES = dialogs/qmlassets.cpp $(QML_MODULE_dialogs_NODIST_EXTRA)
QML_MODULE_LIBS += libqml_module_dialogs.a

libqml_module_maininterface_a_Module = VLC.MainInterface
libqml_module_maininterface_a_ModulePath = VLC/MainInterface
libqml_module_maininterface_a_CXXFLAGS = $(libqt_plugin_la_CXXFLAGS)
libqml_module_maininterface_a_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
libqml_module_maininterface_a_QML = \
	maininterface/qml/MenuTopbar.qml \
	maininterface/qml/LocalTopbar.qml \
	maininterface/qml/MainInterface.qml \
	maininterface/qml/MainViewLoader.qml \
	maininterface/qml/MainDisplay.qml \
	maininterface/qml/SideNavigationPane.qml \
	maininterface/qml/SideNavigationDelegate.qml \
	maininterface/qml/NoMedialibHome.qml

if UPDATE_CHECK
libqml_module_maininterface_a_QML += maininterface/qml/UpdatePane.qml
endif

libqml_module_maininterface_a_Singleton_QML =
libqml_module_maininterface_a_SOURCES = $(QML_MODULE_maininterface_SRC)
nodist_libqml_module_maininterface_a_SOURCES = maininterface/qmlassets.cpp $(QML_MODULE_maininterface_NODIST_EXTRA)
QML_MODULE_LIBS += libqml_module_maininterface.a

libqml_module_medialibrary_a_Module = VLC.MediaLibrary
libqml_module_medialibrary_a_ModulePath = VLC/MediaLibrary
libqml_module_medialibrary_a_CXXFLAGS = $(libqt_plugin_la_CXXFLAGS)
libqml_module_medialibrary_a_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
libqml_module_medialibrary_a_QML = \
	medialibrary/qml/ArtistTopBanner.qml \
	medialibrary/qml/AudioGridItem.qml \
	medialibrary/qml/HomeDisplay.qml \
	medialibrary/qml/FrequentFolders.qml \
	medialibrary/qml/HomePage.qml \
	medialibrary/qml/MediaView.qml \
	medialibrary/qml/VideoGroupDisplay.qml \
	medialibrary/qml/MusicAlbums.qml \
	medialibrary/qml/MusicAlbumsDisplay.qml \
	medialibrary/qml/MusicAlbumsGridExpandDelegate.qml \
	medialibrary/qml/MusicArtist.qml \
	medialibrary/qml/MusicArtistDelegate.qml \
	medialibrary/qml/MusicArtistsAlbums.qml \
	medialibrary/qml/MusicAllArtists.qml \
	medialibrary/qml/MusicArtistsDisplay.qml \
	medialibrary/qml/MusicDisplay.qml \
	medialibrary/qml/MusicGenres.qml \
	medialibrary/qml/MusicGenresDisplay.qml \
	medialibrary/qml/MusicPlaylistsDisplay.qml \
	medialibrary/qml/MusicTrackListDisplay.qml \
	medialibrary/qml/MusicTracksDisplay.qml \
	medialibrary/qml/UrlListDisplay.qml \
	medialibrary/qml/VideoDisplay.qml \
	medialibrary/qml/VideoAll.qml \
	medialibrary/qml/VideoAllDisplay.qml \
	medialibrary/qml/VideoAllSubDisplay.qml \
	medialibrary/qml/PlaylistMediaList.qml \
	medialibrary/qml/PlaylistMedia.qml \
	medialibrary/qml/PlaylistMediaDisplay.qml \
	medialibrary/qml/VideoPlaylistsDisplay.qml \
	medialibrary/qml/PlaylistsDisplay.qml \
	medialibrary/qml/RecentDisplay.qml \
	medialibrary/qml/VideoFoldersDisplay.qml \
	medialibrary/qml/MusicSectionsDisplay.qml \
	medialibrary/qml/FolderContentMenu.qml \
	medialibrary/qml/VideoGridItem.qml \
	medialibrary/qml/VideoInfoExpandPanel.qml \
	medialibrary/qml/VideoListDisplay.qml \
	medialibrary/qml/VideoGridDisplay.qml \
	medialibrary/qml/MusicAlbumSectionDelegate.qml \
	medialibrary/qml/MLGlobalShortcuts.qml \
	medialibrary/qml/Bookmarks.qml \
	medialibrary/qml/MLContextMenu.qml \
	medialibrary/qml/MLDragItem.qml \
	medialibrary/qml/MLTableColumns.qml \
	medialibrary/qml/ScanProgressBar.qml
libqml_module_medialibrary_a_Singleton_QML =
libqml_module_medialibrary_a_SOURCES = $(QML_MODULE_medialibrary_SRC)
nodist_libqml_module_medialibrary_a_SOURCES = medialibrary/qmlassets.cpp $(QML_MODULE_medialibrary_NODIST_EXTRA)
QML_MODULE_LIBS += libqml_module_medialibrary.a

libqml_module_menus_a_Module = VLC.Menus
libqml_module_menus_a_ModulePath = VLC/Menus
libqml_module_menus_a_CXXFLAGS = $(libqt_plugin_la_CXXFLAGS)
libqml_module_menus_a_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
libqml_module_menus_a_QML = \
	menus/qml/GlobalShortcuts.qml \
	menus/qml/Menubar.qml \
	menus/qml/ShortcutExt.qml
libqml_module_menus_a_Singleton_QML =
libqml_module_menus_a_SOURCES = $(QML_MODULE_menus_SRC)
nodist_libqml_module_menus_a_SOURCES = menus/qmlassets.cpp $(QML_MODULE_menus_NODIST_EXTRA)
QML_MODULE_LIBS += libqml_module_menus.a

libqml_module_network_a_Module = VLC.Network
libqml_module_network_a_ModulePath = VLC/Network
libqml_module_network_a_CXXFLAGS = $(libqt_plugin_la_CXXFLAGS)
libqml_module_network_a_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
libqml_module_network_a_QML = \
	network/qml/AddressbarButton.qml \
	network/qml/BrowseDeviceView.qml \
	network/qml/BrowseDisplay.qml \
	network/qml/BrowseHomeDisplay.qml \
	network/qml/BrowseTreeDisplay.qml \
	network/qml/BrowseTreeHeader.qml \
	network/qml/DiscoverDisplay.qml \
	network/qml/DiscoverUrlDisplay.qml \
	network/qml/StreamsDisplay.qml \
	network/qml/NetworkSectionsDisplay.qml \
	network/qml/NetworkAddressbar.qml \
	network/qml/NetworkGridItem.qml \
	network/qml/NetworkThumbnailItem.qml \
	network/qml/ServicesHomeDisplay.qml \
	network/qml/ServicesManage.qml \
	network/qml/ServicesSources.qml
libqml_module_network_a_Singleton_QML =
libqml_module_network_a_SOURCES = $(QML_MODULE_network_SRC)
nodist_libqml_module_network_a_SOURCES = network/qmlassets.cpp $(QML_MODULE_network_NODIST_EXTRA)
QML_MODULE_LIBS += libqml_module_network.a

libqml_module_player_a_Module = VLC.Player
libqml_module_player_a_ModulePath = VLC/Player
libqml_module_player_a_CXXFLAGS = $(libqt_plugin_la_CXXFLAGS)
libqml_module_player_a_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
libqml_module_player_a_QML = \
	player/qml/ControlBar.qml \
	player/qml/PlaybackSpeed.qml \
	player/qml/LyricsFlickable.qml \
	player/qml/MiniPlayer.qml \
	player/qml/PIPPlayer.qml \
	player/qml/Player.qml \
	player/qml/PlayerControlLayout.qml \
	player/qml/LiveBarSection.qml \
	player/qml/CustomizePlayerPanel.qml \
	player/qml/PlayerPlaylistVisibilityFSM.qml \
	player/qml/PlayerToolbarVisibilityFSM.qml \
	player/qml/MinimalView.qml \
	player/qml/ResumeDialog.qml \
	player/qml/PlayerLibraryPanel.qml \
	player/qml/PlayerLibraryModels.qml \
	player/qml/PlayerSideTabs.qml \
	player/qml/PlayerMarksView.qml \
	player/qml/SliderBar.qml \
	player/qml/PressedKeyOSD.qml \
	player/qml/SubtitleTimeline.qml \
	player/qml/TopBar.qml \
	player/qml/WindowButtons.qml \
	player/qml/TracksMenu.qml \
	player/qml/PlayerSettingsPanel.qml \
	player/qml/TracksPopover.qml \
	player/qml/QueuePopover.qml \
	player/qml/PlayerSidePopup.qml \
	player/qml/MiniQueue.qml \
	player/qml/TracksPage.qml \
	player/qml/TracksPageAudio.qml \
	player/qml/TracksPageSpeed.qml \
	player/qml/TracksPageSubtitle.qml \
	player/qml/TracksListPage.qml \
	player/qml/ControlLayout.qml \
	player/qml/ControlRepeater.qml \
	player/qml/NavigationBox.qml

libqml_module_player_a_Singleton_QML = \
	player/qml/PlayerControlbarControls.qml
libqml_module_player_a_SOURCES = $(QML_MODULE_player_SRC)
nodist_libqml_module_player_a_SOURCES = player/qmlassets.cpp $(QML_MODULE_player_NODIST_EXTRA)
QML_MODULE_LIBS += libqml_module_player.a

libqml_module_playercontrols_a_Module = VLC.PlayerControls
libqml_module_playercontrols_a_ModulePath = VLC/PlayerControls
libqml_module_playercontrols_a_CXXFLAGS = $(libqt_plugin_la_CXXFLAGS)
libqml_module_playercontrols_a_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
libqml_module_playercontrols_a_QML = \
	player/qml/controlbarcontrols/HighResolutionTimeWidget.qml \
	player/qml/controlbarcontrols/ArtworkInfoWidget.qml \
	player/qml/controlbarcontrols/AspectRatioWidget.qml \
	player/qml/controlbarcontrols/AtoBButton.qml \
	player/qml/controlbarcontrols/BackButton.qml \
	player/qml/controlbarcontrols/BookmarkButton.qml \
	player/qml/controlbarcontrols/FavoriteButton.qml \
	player/qml/controlbarcontrols/PipButton.qml \
	player/qml/controlbarcontrols/HdrButton.qml \
	player/qml/controlbarcontrols/ThumbnailButton.qml \
	player/qml/controlbarcontrols/JumpButton.qml \
	player/qml/controlbarcontrols/Backward15Button.qml \
	player/qml/controlbarcontrols/Forward15Button.qml \
	player/qml/controlbarcontrols/ChaptersButton.qml \
	player/qml/controlbarcontrols/BookmarkAddButton.qml \
	player/qml/controlbarcontrols/AudioTracksButton.qml \
	player/qml/controlbarcontrols/SubtitleTracksButton.qml \
	player/qml/controlbarcontrols/GoHomeButton.qml \
	player/qml/controlbarcontrols/SettingsButton.qml \
	player/qml/controlbarcontrols/PropertiesButton.qml \
	player/qml/controlbarcontrols/ReplayButton.qml \
	player/qml/controlbarcontrols/SidebarButton.qml \
	player/qml/controlbarcontrols/LibraryButton.qml \
	player/qml/controlbarcontrols/MediaTitleLabel.qml \
	player/qml/controlbarcontrols/ZoomButton.qml \
	player/qml/controlbarcontrols/DividerWidget.qml \
	player/qml/controlbarcontrols/FileNameLabel.qml \
	player/qml/controlbarcontrols/ArtistNameLabel.qml \
	player/qml/controlbarcontrols/FolderNameLabel.qml \
	player/qml/controlbarcontrols/PlaylistNameLabel.qml \
	player/qml/controlbarcontrols/MediaLabel.qml \
	player/qml/controlbarcontrols/ChapterNextButton.qml \
	player/qml/controlbarcontrols/ChapterPreviousButton.qml \
	player/qml/controlbarcontrols/DvdMenuButton.qml \
	player/qml/controlbarcontrols/ExpandingSpacerWidget.qml \
	player/qml/controlbarcontrols/SeekBarWidget.qml \
	player/qml/controlbarcontrols/ExtendedSettingsButton.qml \
	player/qml/controlbarcontrols/FasterButton.qml \
	player/qml/controlbarcontrols/FrameNextButton.qml \
	player/qml/controlbarcontrols/FramePrevButton.qml \
	player/qml/controlbarcontrols/FullscreenButton.qml \
	player/qml/controlbarcontrols/InfoButton.qml \
	player/qml/controlbarcontrols/LangButton.qml \
	player/qml/controlbarcontrols/LoopButton.qml \
	player/qml/controlbarcontrols/MenuButton.qml \
	player/qml/controlbarcontrols/NavigationBoxButton.qml \
	player/qml/controlbarcontrols/NavigationWidget.qml \
	player/qml/controlbarcontrols/NextButton.qml \
	player/qml/controlbarcontrols/OpenButton.qml \
	player/qml/controlbarcontrols/PlaybackSpeedButton.qml \
	player/qml/controlbarcontrols/PlayButton.qml \
	player/qml/controlbarcontrols/PlayerSwitchButton.qml \
	player/qml/controlbarcontrols/PlaylistButton.qml \
	player/qml/controlbarcontrols/PreviousButton.qml \
	player/qml/controlbarcontrols/ProgramButton.qml \
	player/qml/controlbarcontrols/QuitButton.qml \
	player/qml/controlbarcontrols/RandomButton.qml \
	player/qml/controlbarcontrols/RendererButton.qml \
	player/qml/controlbarcontrols/RecordButton.qml \
	player/qml/controlbarcontrols/ReverseButton.qml \
	player/qml/controlbarcontrols/SkipBackButton.qml \
	player/qml/controlbarcontrols/SkipForwardButton.qml \
	player/qml/controlbarcontrols/SlowerButton.qml \
	player/qml/controlbarcontrols/SnapshotButton.qml \
	player/qml/controlbarcontrols/SpacerWidget.qml \
	player/qml/controlbarcontrols/StopButton.qml \
	player/qml/controlbarcontrols/TeletextButton.qml \
	player/qml/controlbarcontrols/TeletextColorButton.qml \
	player/qml/controlbarcontrols/TeletextWidget.qml \
	player/qml/controlbarcontrols/VolumeWidget.qml \
	player/qml/controlbarcontrols/Fallback.qml
libqml_module_playercontrols_a_Singleton_QML =
libqml_module_playercontrols_a_SOURCES = $(QML_MODULE_playercontrols_SRC)
nodist_libqml_module_playercontrols_a_SOURCES = playercontrols/qmlassets.cpp $(QML_MODULE_playercontrols_NODIST_EXTRA)
QML_MODULE_LIBS += libqml_module_playercontrols.a

libqml_module_playlist_a_Module = VLC.Playlist
libqml_module_playlist_a_ModulePath = VLC/Playlist
libqml_module_playlist_a_CXXFLAGS = $(libqt_plugin_la_CXXFLAGS)
libqml_module_playlist_a_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
libqml_module_playlist_a_QML = \
	playlist/qml/PlaylistDelegate.qml \
	playlist/qml/PlaylistPane.qml \
	playlist/qml/PlaylistDetachedWindow.qml
libqml_module_playlist_a_Singleton_QML =
libqml_module_playlist_a_SOURCES = $(QML_MODULE_playlist_SRC)
nodist_libqml_module_playlist_a_SOURCES = playlist/qmlassets.cpp $(QML_MODULE_playlist_NODIST_EXTRA)
QML_MODULE_LIBS += libqml_module_playlist.a

libqml_module_style_a_Module = VLC.Style
libqml_module_style_a_ModulePath = VLC/Style
libqml_module_style_a_CXXFLAGS = $(libqt_plugin_la_CXXFLAGS)
libqml_module_style_a_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
libqml_module_style_a_QML =
libqml_module_style_a_Singleton_QML = \
	style/AcrylicController.qml \
	style/VLCStyle.qml
libqml_module_style_a_SOURCES = $(QML_MODULE_style_SRC)
nodist_libqml_module_style_a_SOURCES = style/qmlassets.cpp $(QML_MODULE_style_NODIST_EXTRA)
QML_MODULE_LIBS += libqml_module_style.a

libqml_module_util_a_Module = VLC.Util
libqml_module_util_a_ModulePath = VLC/Util
libqml_module_util_a_CXXFLAGS = $(libqt_plugin_la_CXXFLAGS)
libqml_module_util_a_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
libqml_module_util_a_QML = \
	util/qml/ModelSortSettingHandler.qml \
	util/qml/DefaultFlickableScrollHandler.qml \
	util/qml/ViewDragAutoScrollHandler.qml \
	util/qml/FSM.qml \
	util/qml/FSMState.qml \
	util/qml/NativeMenu.qml \
	util/qml/FadeControllerStateGroup.qml \
	util/qml/GridSizeHelper.qml \
	util/qml/DelayedBehavior.qml \
	util/qml/DelegateTouchTapHandler.qml
libqml_module_util_a_Singleton_QML = \
	util/qml/Helpers.qml
libqml_module_util_a_SOURCES = $(QML_MODULE_util_SRC)
nodist_libqml_module_util_a_SOURCES = util/qmlassets.cpp $(QML_MODULE_util_NODIST_EXTRA)
QML_MODULE_LIBS += libqml_module_util.a

libqml_module_widgets_a_Module = VLC.Widgets
libqml_module_widgets_a_ModulePath = VLC/Widgets
libqml_module_widgets_a_CXXFLAGS = $(libqt_plugin_la_CXXFLAGS)
libqml_module_widgets_a_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
libqml_module_widgets_a_QML = \
	widgets/qml/LabelExt.qml \
	widgets/qml/ActionButtonOverlay.qml \
	widgets/qml/ActionButtonPrimary.qml \
	widgets/qml/BannerTabButton.qml \
	widgets/qml/BannerCone.qml \
	widgets/qml/BusyIndicatorExt.qml \
	widgets/qml/CaptionLabel.qml \
	widgets/qml/CheckButton.qml \
	widgets/qml/CheckedDelegate.qml \
	widgets/qml/ComboBoxExt.qml \
	widgets/qml/AcrylicBackground.qml \
	widgets/qml/FloatingNotification.qml \
	widgets/qml/AnimatedBackground.qml \
	widgets/qml/CSDThemeButton.qml \
	widgets/qml/CSDThemeButtonSet.qml \
	widgets/qml/CSDWindowButton.qml \
	widgets/qml/CSDWindowButtonSet.qml \
	widgets/qml/CSDTitlebarTapNDrapHandler.qml \
	widgets/qml/CSDMouseStealer.qml \
	widgets/qml/CurrentIndicator.qml \
	widgets/qml/DragItem.qml \
	widgets/qml/DrawerExt.qml \
	widgets/qml/ExpandGridView.qml \
	widgets/qml/ExpandGridItemView.qml \
	widgets/qml/EmptyLabel.qml \
	widgets/qml/EmptyLabelButton.qml \
	widgets/qml/EmptyLabelHint.qml \
	widgets/qml/GridItem.qml \
	widgets/qml/GridSortFilterControls.qml \
	widgets/qml/HistoryButtons.qml \
	widgets/qml/HorizontalResizeHandle.qml \
	widgets/qml/IconLabel.qml \
	widgets/qml/IconButton.qml \
	widgets/qml/IconToolButton.qml \
	widgets/qml/IconTrackButton.qml \
	widgets/qml/ImageToolButton.qml \
	widgets/qml/ListViewExt.qml \
	widgets/qml/TableViewExt.qml \
	widgets/qml/TableViewDelegateExt.qml \
	widgets/qml/TableRowDelegate.qml \
	widgets/qml/TableHeaderDelegate.qml \
	widgets/qml/DefaultShadow.qml \
	widgets/qml/ListLabel.qml \
	widgets/qml/MediaCover.qml \
	widgets/qml/SubtitleLabel.qml \
	widgets/qml/MenuCaption.qml \
	widgets/qml/MenuLabel.qml \
	widgets/qml/NavigableCol.qml \
	widgets/qml/NavigableRow.qml \
	widgets/qml/PlayCover.qml \
	widgets/qml/RoundButtonExt.qml \
	widgets/qml/ScaledImage.qml \
	widgets/qml/TextAutoScroller.qml \
	widgets/qml/SearchBox.qml \
	widgets/qml/SliderExt.qml \
	widgets/qml/SortControl.qml \
	widgets/qml/SpinBoxExt.qml \
	widgets/qml/StackViewExt.qml \
	widgets/qml/PageLoader.qml \
	widgets/qml/PageExt.qml \
	widgets/qml/BreadcrumbText.qml \
	widgets/qml/ButtonExt.qml \
	widgets/qml/TableColumns.qml \
	widgets/qml/TextFieldExt.qml \
	widgets/qml/TextToolButton.qml \
	widgets/qml/TrackDelayButton.qml \
	widgets/qml/VideoProgressBar.qml \
	widgets/qml/VideoQualityLabels.qml \
	widgets/qml/ListSubtitleLabel.qml \
	widgets/qml/PointingTooltip.qml \
	widgets/qml/FrostedGlassEffect.qml \
	widgets/qml/ToolTipExt.qml \
	widgets/qml/DropShadowImage.qml \
	widgets/qml/DoubleShadow.qml \
	widgets/qml/FadingEdge.qml \
	widgets/qml/FadingEdgeForItemView.qml \
	widgets/qml/PopupIconToolButton.qml \
	widgets/qml/PartialEffect.qml \
	widgets/qml/ViewHeader.qml \
	widgets/qml/ProgressIndicator.qml \
	widgets/qml/ImageExt.qml \
	widgets/qml/EnhancedImageExt.qml \
	widgets/qml/ScrollBarExt.qml \
	widgets/qml/FastBlend.qml \
	widgets/qml/RadioButtonExt.qml \
	widgets/qml/RoundedRectangleShadow.qml \
	widgets/qml/VoronoiSnow.qml \
	widgets/qml/DualKawaseBlur.qml \
	widgets/qml/CheckBoxExt.qml \
	widgets/qml/ProgressBarExt.qml
libqml_module_widgets_a_Singleton_QML =
libqml_module_widgets_a_SOURCES = $(QML_MODULE_widgets_SRC)
nodist_libqml_module_widgets_a_SOURCES = widgets/qmlassets.cpp $(QML_MODULE_widgets_NODIST_EXTRA)
QML_MODULE_LIBS += libqml_module_widgets.a

if ENABLE_QT
libqt_plugin_la_LIBADD += $(QML_MODULE_LIBS)
noinst_LIBRARIES += $(QML_MODULE_LIBS)
endif

if HAVE_QMLCACHEGEN
QML_MODULE_dialogs_SRC = $(libqml_module_dialogs_a_QML) $(libqml_module_dialogs_a_Singleton_QML)
QML_MODULE_dialogs_NODIST_EXTRA = dialogs/qmlcache_loader.cpp
QML_MODULE_maininterface_SRC = $(libqml_module_maininterface_a_QML) $(libqml_module_maininterface_a_Singleton_QML)
QML_MODULE_maininterface_NODIST_EXTRA = maininterface/qmlcache_loader.cpp
QML_MODULE_medialibrary_SRC = $(libqml_module_medialibrary_a_QML) $(libqml_module_medialibrary_a_Singleton_QML)
QML_MODULE_medialibrary_NODIST_EXTRA = medialibrary/qmlcache_loader.cpp
QML_MODULE_menus_SRC = $(libqml_module_menus_a_QML) $(libqml_module_menus_a_Singleton_QML)
QML_MODULE_menus_NODIST_EXTRA = menus/qmlcache_loader.cpp
QML_MODULE_network_SRC = $(libqml_module_network_a_QML) $(libqml_module_network_a_Singleton_QML)
QML_MODULE_network_NODIST_EXTRA = network/qmlcache_loader.cpp
QML_MODULE_player_SRC = $(libqml_module_player_a_QML) $(libqml_module_player_a_Singleton_QML)
QML_MODULE_player_NODIST_EXTRA = player/qmlcache_loader.cpp
QML_MODULE_playercontrols_SRC = $(libqml_module_playercontrols_a_QML) $(libqml_module_playercontrols_a_Singleton_QML)
QML_MODULE_playercontrols_NODIST_EXTRA = playercontrols/qmlcache_loader.cpp
QML_MODULE_playlist_SRC = $(libqml_module_playlist_a_QML) $(libqml_module_playlist_a_Singleton_QML)
QML_MODULE_playlist_NODIST_EXTRA = playlist/qmlcache_loader.cpp
QML_MODULE_style_SRC = $(libqml_module_style_a_QML) $(libqml_module_style_a_Singleton_QML)
QML_MODULE_style_NODIST_EXTRA = style/qmlcache_loader.cpp
QML_MODULE_util_SRC = $(libqml_module_util_a_QML) $(libqml_module_util_a_Singleton_QML)
QML_MODULE_util_NODIST_EXTRA = util/qmlcache_loader.cpp
QML_MODULE_widgets_SRC = $(libqml_module_widgets_a_QML) $(libqml_module_widgets_a_Singleton_QML)
QML_MODULE_widgets_NODIST_EXTRA = widgets/qmlcache_loader.cpp
endif


libqt_plugin_la_QML_MODULES = \
	dialogs \
	maininterface \
	medialibrary \
	menus \
	network \
	player \
	playercontrols \
	playlist \
	style \
	util \
	widgets

libqt_plugin_la_ALL_QML = \
	$(libqml_module_dialogs_a_QML) \
	$(libqml_module_dialogs_a_Singleton_QML) \
	$(libqml_module_maininterface_a_QML) \
	$(libqml_module_medialibrary_a_QML) \
	$(libqml_module_menus_a_QML) \
	$(libqml_module_network_a_QML) \
	$(libqml_module_player_a_QML) \
	$(libqml_module_player_a_Singleton_QML) \
	$(libqml_module_playercontrols_a_QML) \
	$(libqml_module_playlist_a_QML) \
	$(libqml_module_style_a_QML) \
	$(libqml_module_style_a_Singleton_QML) \
	$(libqml_module_util_a_QML) \
	$(libqml_module_util_a_Singleton_QML) \
	$(libqml_module_widgets_a_QML)

# Shaders:
libqt_plugin_la_SHADER_FRAG = shaders/FadingEdge.frag \
                              shaders/Noise.frag \
                              shaders/RectFilter.frag \
                              shaders/SDFAARoundedTexture.frag \
                              shaders/SDFAARoundedTexture_cropsupport_bordersupport.frag \
                              shaders/DitheredTexture.frag \
                              shaders/FastBlend.frag \
                              shaders/FastBlend_additive.frag \
                              shaders/FastBlend_multiply.frag \
                              shaders/FastBlend_screen.frag \
                              shaders/RoundedRectangleShadow.frag \
                              shaders/RoundedRectangleShadow_hollow.frag \
                              shaders/VoronoiSnow.frag \
                              shaders/DualKawaseBlur_upsample.frag \
                              shaders/DualKawaseBlur_downsample.frag \
                              shaders/DualKawaseBlur_upsample_postprocess.frag

libqt_plugin_la_SHADER_VERT = shaders/FadingEdgeX.vert \
                              shaders/FadingEdgeY.vert \
                              shaders/SubTexture.vert

libqt_plugin_la_SHADER = $(libqt_plugin_la_SHADER_FRAG) $(libqt_plugin_la_SHADER_VERT)

if ENABLE_QT

BUILT_SOURCES += \
    $(libqt_plugin_la_SHADER_FRAG:.frag=.frag.qsb) \
    $(libqt_plugin_la_SHADER_VERT:.vert=.vert.qsb)

QSB_PARAMS = --glsl="300 es,130,150" --batchable -O
if HAVE_WIN32
QSB_PARAMS += --hlsl=50 -c
endif
if HAVE_DARWIN
QSB_PARAMS += --msl=12
endif

QSB_EXTRA_PATH =
if HAVE_FXC
QSB_EXTRA_PATH += $(FXC_PATH):
endif

qsb_verbose = $(qsb_verbose_$(V))
qsb_verbose_ = $(qsb_verbose__$(AM_DEFAULT_VERBOSITY))
qsb_verbose_0 = @echo "  QSB     " $@;
qsb_verbose__0 = $(qsb_verbose_0)

QSB_PARAMS_VERBOSE = $(QSB_PARAMS_VERBOSE_$(V))
QSB_PARAMS_VERBOSE_ = $(QSB_PARAMS_VERBOSE__$(AM_DEFAULT_VERBOSITY))
QSB_PARAMS_VERBOSE_0 = -s
QSB_PARAMS_VERBOSE__0 = $(QSB_PARAMS_VERBOSE_0)

EXTRA_DIST += shaders/Common.glsl

$(libqt_plugin_la_SHADER_FRAG:.frag=.frag.qsb) $(libqt_plugin_la_SHADER_VERT:.vert=.vert.qsb): shaders/Common.glsl

$(libqt_plugin_la_SHADER_FRAG:.frag=.frag.qsb):
	$(qsb_verbose)PATH="$(QSB_EXTRA_PATH)$$PATH" $(QSB) $(QSB_PARAMS) $(QSB_PARAMS_VERBOSE) -o $@ $(srcdir)/$(@:.qsb=)

$(libqt_plugin_la_SHADER_VERT:.vert=.vert.qsb):
	$(qsb_verbose)PATH="$(QSB_EXTRA_PATH)$$PATH" $(QSB) $(QSB_PARAMS) $(QSB_PARAMS_VERBOSE) -o $@ $(srcdir)/$(@:.qsb=)

shaders/shaders.qrc: $(libqt_plugin_la_SHADER) Makefile
	$(AM_V_GEN)$(PYTHON3) $(srcdir)/scripts/genqrc.py -o $@ --prefix shaders --sources $(libqt_plugin_la_SHADER_FRAG:.frag=.frag.qsb) $(libqt_plugin_la_SHADER_VERT:.vert=.vert.qsb)

shaders/shaders.cpp: shaders/shaders.qrc $(libqt_plugin_la_SHADER_FRAG:.frag=.frag.qsb) $(libqt_plugin_la_SHADER_VERT:.vert=.vert.qsb)
	$(AM_V_GEN) $(RCC) $(RCC_EXTRA_PARAMS) --name shaders -o $@ $<

libqt_plugin_la_SOURCES += $(libqt_plugin_la_SHADER)
CLEANFILES += shaders/shaders.qrc

lib_qt_plugin_la_QRC = assets.qrc

if HAVE_WIN32
lib_qt_plugin_la_QRC += windows.qrc

windows.cpp: $(libqt_plugin_la_RES)
windows.cpp: windows.qrc
	$(AM_V_GEN)$(RCC) $(RCC_EXTRA_PARAMS) --name windows -o $@ $<

nodist_libqt_plugin_la_SOURCES += windows.cpp
endif

EXTRA_DIST += $(lib_qt_plugin_la_QRC) $(libqt_plugin_la_RES) $(libqt_plugin_la_SHADER)

nodist_libqt_plugin_la_SOURCES += assets.cpp  shaders/shaders.cpp
endif

# Emit shader source dependencies so that the built shaders are properly
# registered with the sources as prerequisites
shaders/shaders.deps: Makefile
	$(AM_V_at)$(MKDIR_P) $(@D)
	$(AM_V_GEN){ \
	  for s in $(libqt_plugin_la_SHADER_FRAG) $(libqt_plugin_la_SHADER_VERT); do \
	    echo "$$s.qsb: $(srcdir)/$$s"; \
	  done; \
	} > $@.tmp && \
	if cmp -s $@.tmp $@; then rm -f $@.tmp; else mv $@.tmp $@; fi

BUILT_SOURCES += shaders/shaders.deps
CLEANFILES    += shaders/shaders.deps

-include shaders/shaders.deps

if ENABLE_VLM
nodist_libqt_plugin_la_SOURCES += dialogs/vlm/vlm.moc.cpp
endif

# Dynamically generate the rules dependencies so that rebuilds are working
# properly. Since this is not GNU Make, we cannot generate the rules using
# text functions.
QML_RULES_DEPS = $(libqt_plugin_la_QML_MODULES:=/qml.deps)

# Since every QML modules is built into a given directory, we can use $(@D)
# to get the module name.
$(QML_RULES_DEPS): Makefile
	$(AM_V_at)$(MKDIR_P) $(@D)
	$(AM_V_GEN){ \
	  echo '$(@D)/qmldir.qrc: $(@D)/qmldir'; \
	  echo '$(@D)/res.qrc $(@D)/qmldir: $(@D)/qml_modules.stamp'; \
	  echo '$(@D)/qmlcachegen.rsp: $$(builddir)/$(@D)/res.qrc'; \
	  echo '$(@D)/qmlcache_loader.cpp: $(@D)/qmlcachegen.rsp'; \
	  echo '$(@D)/qmlassets.cpp: $$(builddir)/$(@D)/qmldir.qrc $$(builddir)/$(@D)/res.qrc'; \
	  echo '$(@D)/qmlassets.cpp: $$(libqml_module_$(@D)_a_QML) $$(libqml_module_$(@D)_a_Singleton_QML)'; \
	  echo '$$(libqml_module_$(@D)_a_QML:.qml=.cpp) $$(libqml_module_$(@D)_a_Singleton_QML:.qml=.cpp): $$(builddir)/$(@D)/res.qrc'; \
	} > $@.tmp && \
	if cmp -s $@.tmp $@; then rm -f $@.tmp; else mv $@.tmp $@; fi

BUILT_SOURCES += $(QML_RULES_DEPS)
CLEANFILES += $(QML_RULES_DEPS)

-include $(QML_RULES_DEPS)

# QRC/qmldir generation depends on the list of files (defined here) but
# not the file contents. Use per-module stamp files so that changes to
# one module's file list don't trigger rebuilds in other modules.
QML_MODULE_STAMPS =
if ENABLE_QT
QML_MODULE_STAMPS += $(libqt_plugin_la_QML_MODULES:=/qml_modules.stamp)
endif

# Pre-expand target lists into named variables so that automake does not
# see the same '$(libqt_plugin_la_QML_MODULES' prefix repeated across
# conditionals and emit spurious "was already defined" warnings.
QML_MODULE_RES_QRC = $(libqt_plugin_la_QML_MODULES:=/res.qrc)
QML_MODULE_QMLDIR = $(libqt_plugin_la_QML_MODULES:=/qmldir)
QML_MODULE_QMLDIR_QRC = $(libqt_plugin_la_QML_MODULES:=/qmldir.qrc)

$(QML_MODULE_STAMPS): Makefile
	$(AM_V_at)$(MKDIR_P) $(@D); \
	echo '$(libqml_module_$(@D)_a_Module) $(libqml_module_$(@D)_a_ModulePath) $(libqml_module_$(@D)_a_QML) $(libqml_module_$(@D)_a_Singleton_QML)' > $@.tmp; \
	if cmp -s $@.tmp $@; then rm -f $@.tmp; else mv $@.tmp $@; fi

$(QML_MODULE_RES_QRC):
	$(AM_V_GEN)$(PYTHON3) $(srcdir)/scripts/genqrc.py \
	-o $@ \
	-s $(srcdir) \
	--prefix qt/qml/$(libqml_module_$(@D)_a_ModulePath) \
	--sources $(libqml_module_$(@D)_a_QML) $(libqml_module_$(@D)_a_Singleton_QML)

$(QML_MODULE_QMLDIR):
	$(AM_V_GEN)$(PYTHON3) $(srcdir)/scripts/genqmldir.py \
	-o $@ \
	--prefix qt/qml \
	--module $(libqml_module_$(@D)_a_Module) \
	--sources $(libqml_module_$(@D)_a_QML) \
	--singletons $(libqml_module_$(@D)_a_Singleton_QML)

$(QML_MODULE_QMLDIR_QRC):
	$(AM_V_GEN)$(PYTHON3) $(srcdir)/scripts/genqrc.py -o $@ \
	--prefix qt/qml/$(libqml_module_$(@D)_a_ModulePath) --sources $<

CLEANFILES += $(QML_MODULE_STAMPS) $(QML_MODULE_RES_QRC) $(QML_MODULE_QMLDIR) $(QML_MODULE_QMLDIR_QRC) $(libqml_module_util_a_QML:.qml=.cpp)

if HAVE_QMLCACHEGEN

libqt_plugin_la_CPPFLAGS += -DQT_USE_QMLCACHEGEN

cachegen_verbose = $(cachegen_verbose_$(V))
cachegen_verbose_ = $(cachegen_verbose__$(AM_DEFAULT_VERBOSITY))
cachegen_verbose_0 = @echo " CACHEGEN " $@;
cachegen_verbose__0 = $(cachegen_verbose_0)

if HAVE_QT67
QML_CACHEGEN_EXTRA_ARGS=--validate-basic-blocks
endif

# Each .qml/.js/.mjs is compiled with its module's res.qrc as prerequisite. The
# per-module qrc isn't derivable from the target path, so pick it out of $^.
qml_resource = for f in $^; do case $$f in *.qrc) echo --resource=$$f;; esac; done

.qml.cpp:
	$(cachegen_verbose)$(QMLCACHEGEN) $(QML_CACHEGEN_EXTRA_ARGS) `$(qml_resource)` -o $@ $<

.js.cpp:
	$(cachegen_verbose)$(QMLCACHEGEN) $(QML_CACHEGEN_EXTRA_ARGS) `$(qml_resource)` -o $@ $<

.mjs.cpp:
	$(cachegen_verbose)$(QMLCACHEGEN) $(QML_CACHEGEN_EXTRA_ARGS) `$(qml_resource)` -o $@ $<

# Pre-expand target lists into named variables so that automake does not
# see the same $(libqt_plugin_la_QML_MODULES prefix repeated across
# conditionals and emit spurious "was already defined" warnings.
QML_MODULE_CACHEGEN_RSP = $(libqt_plugin_la_QML_MODULES:=/qmlcachegen.rsp)
QML_MODULE_CACHELOADER = $(libqt_plugin_la_QML_MODULES:=/qmlcache_loader.cpp)
QML_MODULE_CACHEGEN_ASSETS = $(libqt_plugin_la_QML_MODULES:=/qmlassets.cpp)

$(QML_MODULE_CACHEGEN_RSP):
	$(AM_V_GEN)$(PYTHON3) $(srcdir)/scripts/qrc2rsp.py --output $@ $^

$(QML_MODULE_CACHELOADER):
	$(cachegen_verbose)$(QMLCACHEGEN) --resource-name $(@D)_cachegen --resource=$(builddir)/$(@D)/res.qrc -o $@ @$<

$(QML_MODULE_CACHEGEN_ASSETS):
	$(AM_V_GEN)$(RCC) $(RCC_EXTRA_PARAMS) --name $(@D)_assets -o $@ $<


CLEANFILES += \
	$(QML_MODULE_CACHELOADER) \
	$(QML_MODULE_CACHEGEN_RSP) \
	$(QML_MODULE_CACHEGEN_ASSETS) \
	$(libqt_plugin_la_ALL_QML:.qml=.cpp)

else

#package all qml from the genreated QRC files

# See comment above QML_MODULE_RES_QRC for why this is a named variable.
QML_MODULE_ASSETS = $(libqt_plugin_la_QML_MODULES:=/qmlassets.cpp)

$(QML_MODULE_ASSETS):
	$(AM_V_GEN)$(RCC) $(RCC_EXTRA_PARAMS) --name $(@D)_assets \
	-o $@ $(builddir)/$(@D)/qmldir.qrc $(builddir)/$(@D)/res.qrc

nodist_libqt_plugin_la_SOURCES += $(QML_MODULE_ASSETS)
if ENABLE_QT
BUILT_SOURCES += $(QML_MODULE_RES_QRC) $(QML_MODULE_QMLDIR)
endif

endif

EXTRA_DIST += $(libqt_plugin_la_QML)

assets.cpp: $(libqt_plugin_la_RES)
# logos of assets.qrc kept in share/icons
assets.cpp: $(top_srcdir)/share/icons/16x16/vlc.png \
	$(top_srcdir)/share/icons/48x48/vlc.png \
	$(top_srcdir)/share/icons/48x48/vlc-xmas.png \
	$(top_srcdir)/share/icons/48x48/vlc-aprilfools.png \
	$(top_srcdir)/share/icons/128x128/vlc.png \
	$(top_srcdir)/share/icons/128x128/vlc-xmas.png \
	$(top_srcdir)/share/icons/128x128/vlc-aprilfools.png \
	$(top_srcdir)/share/icons/128x128/vlc-kb.png \
	$(top_srcdir)/share/icons/256x256/vlc.png
assets.cpp: assets.qrc
	$(AM_V_GEN)$(RCC) $(RCC_EXTRA_PARAMS) --name assets -o $@ $<


if HAVE_QT_GTK
libqt_gtktheme_plugin_la_CXXFLAGS = $(AM_CXXFLAGS) $(GTK3_CFLAGS) $(QT_CFLAGS)
libqt_gtktheme_CPPFLAGS = $(AM_CPPFLAGS)
libqt_gtktheme_plugin_la_LIBADD = $(GTK3_LIBS) $(QT_LIBS)
libqt_gtktheme_plugin_la_LDFLAGS = $(AM_LDFLAGS) $(QT_LDFLAGS)
libqt_gtktheme_plugin_la_SOURCES = \
	style/gtkthemeprovider/gtk_compat.cpp \
	style/gtkthemeprovider/gtk_compat.h \
	style/gtkthemeprovider/gtkthemeprovider.cpp \
	style/gtkthemeprovider/gtk_util.cpp \
	style/gtkthemeprovider/gtk_util.h \
	style/gtkthemeprovider/nav_button_provider_gtk.cpp \
	style/gtkthemeprovider/nav_button_provider_gtk.h \
	style/gtkthemeprovider/scoped_gobject.h
if ENABLE_QT
gui_PLUGINS += libqt_gtktheme_plugin.la
endif
endif

if ENABLE_QT
gui_PLUGINS += libqt_plugin.la
BUILT_SOURCES += $(nodist_libqt_plugin_la_SOURCES)
if !HAVE_WIN32
if !HAVE_OS2
if !HAVE_IOS_OR_TVOS
if !HAVE_XROS
pkglibexec_PROGRAMS = vlc-qt-check
VLC_QT_CHECK_DEP = $(builddir)/../../vlc-qt-check

$(builddir)/../../vlc-qt-check: vlc-qt-check
	$(AM_V_GEN)cd ../../ && $(LN_S) -f gui/qt/vlc-qt-check . && chmod +x vlc-qt-check
endif
endif
endif
endif

base_model_test_SOURCES = tests/test_base_model.cpp \
        util/base_model.cpp util/base_model.hpp util/base_model_p.hpp

nodist_base_model_test_SOURCES = util/base_model.moc.cpp \
        util/listcache.moc.cpp \
        util/locallistcacheloader.moc.cpp

base_model_test_CXXFLAGS = $(AM_CXXFLAGS) $(QT_CFLAGS) -fPIC $(CXXFLAGS_qt)
base_model_test_LDADD = $(QT_LIBS) $(LIBS_qt)
base_model_test_LDFLAGS = $(AM_LDFLAGS) $(QT_LDFLAGS)
check_PROGRAMS = base_model_test
TESTS = base_model_test

if HAVE_QT_QTEST

LIBVLC = ../../../lib/libvlc.la
QT_QTEST_COMMON_cppflags = $(libqt_plugin_la_CPPFLAGS) -I$(builddir)/tests -DTOP_BUILDDIR=\"$(abs_top_builddir)\"
QT_QTEST_COMMON_cxxflags = $(AM_CXXFLAGS) $(QT_CFLAGS) $(QT_QTEST_CFLAGS) -fPIC $(CXXFLAGS_qt)
QT_QTEST_COMMON_ldadd = $(QT_LIBS) $(LIBS_qt) $(QT_QTEST_LIBS) $(LIBVLCCORE) $(LIBVLC)
QT_QTEST_COMMON_ldflags = $(AM_LDFLAGS) $(QT_LDFLAGS) $(QT_QTEST_LDFLAGS)


# test_ml_model

test_ml_model_SOURCES = \
	tests/vlc_stub_modules.cpp tests/vlc_stub_modules.hpp \
	tests/test_ml_model.cpp \
	util/base_model.hpp util/base_model_p.hpp  util/base_model.cpp \
	util/listcache.hpp \
	util/vlctick.cpp util/vlctick.hpp \
	util/locallistcacheloader.hpp \
	medialibrary/mlqmltypes.hpp \
	medialibrary/mlbasemodel.hpp medialibrary/mlbasemodel.cpp \
	medialibrary/medialib.hpp medialibrary/medialib.cpp \
	medialibrary/mlthreadpool.hpp medialibrary/mlthreadpool.cpp \
	playlist/playlist_controller.hpp playlist/playlist_controller.cpp \
	playlist/playlist_item.hpp playlist/playlist_item.cpp

nodist_test_ml_model_SOURCES = \
	tests/test_ml_model.moc \
	util/base_model.moc.cpp \
	util/listcache.moc.cpp \
	util/locallistcacheloader.moc.cpp \
	util/vlctick.moc.cpp \
	medialibrary/mlqmltypes.moc.cpp \
	medialibrary/mlbasemodel.moc.cpp \
	medialibrary/medialib.moc.cpp \
	medialibrary/mlthreadpool.moc.cpp \
	playlist/playlist_controller.moc.cpp \
	playlist/playlist_item.moc.cpp

BUILT_SOURCES += tests/test_ml_model.moc
CLEANFILES += tests/test_ml_model.moc
test_ml_model_CPPFLAGS = $(QT_QTEST_COMMON_cppflags)
test_ml_model_CXXFLAGS = $(QT_QTEST_COMMON_cxxflags)
test_ml_model_LDADD = $(QT_QTEST_COMMON_ldadd)
test_ml_model_LDFLAGS = $(QT_QTEST_COMMON_ldflags)
check_PROGRAMS += test_ml_model
TESTS += test_ml_model

# test_renderer_manager_model

test_renderer_manager_model_SOURCES = \
	tests/vlc_stub_modules.cpp tests/vlc_stub_modules.hpp \
	tests/test_renderer_manager_model.cpp \
    util/renderer_manager.hpp util/renderer_manager.cpp

nodist_test_renderer_manager_model_SOURCES = \
	tests/test_renderer_manager_model.moc \
    util/renderer_manager.moc.cpp

BUILT_SOURCES += tests/test_renderer_manager_model.moc
CLEANFILES += tests/test_renderer_manager_model.moc
test_renderer_manager_model_CPPFLAGS = $(QT_QTEST_COMMON_cppflags)
test_renderer_manager_model_CXXFLAGS = $(QT_QTEST_COMMON_cxxflags)
test_renderer_manager_model_LDADD = $(QT_QTEST_COMMON_ldadd)
test_renderer_manager_model_LDFLAGS = $(QT_QTEST_COMMON_ldflags)
check_PROGRAMS += test_renderer_manager_model
TESTS += test_renderer_manager_model

# test_thread_runner

test_thread_runner_SOURCES = \
	tests/test_thread_runner.cpp \
    medialibrary/mlthreadpool.cpp medialibrary/mlthreadpool.hpp

nodist_test_thread_runner_SOURCES = \
	tests/test_thread_runner.moc \
    medialibrary/mlthreadpool.moc.cpp

BUILT_SOURCES += tests/test_thread_runner.moc
CLEANFILES += tests/test_thread_runner.moc
test_thread_runner_CPPFLAGS = $(QT_QTEST_COMMON_cppflags)
test_thread_runner_CXXFLAGS = $(QT_QTEST_COMMON_cxxflags)
test_thread_runner_LDADD = $(QT_QTEST_COMMON_ldadd)
test_thread_runner_LDFLAGS = $(QT_QTEST_COMMON_ldflags)
check_PROGRAMS += test_thread_runner
TESTS += test_thread_runner

# test_vlc_dialog_model

test_vlc_dialog_model_SOURCES = \
	tests/vlc_stub_modules.cpp tests/vlc_stub_modules.hpp \
	tests/test_vlc_dialog_model.cpp \
	dialogs/dialogs/dialogmodel.cpp

nodist_test_vlc_dialog_model_SOURCES = \
	tests/test_vlc_dialog_model.moc \
	dialogs/dialogs/dialogmodel.moc.cpp

BUILT_SOURCES += tests/test_vlc_dialog_model.moc
CLEANFILES += tests/test_vlc_dialog_model.moc
test_vlc_dialog_model_CPPFLAGS = $(QT_QTEST_COMMON_cppflags)
test_vlc_dialog_model_CXXFLAGS = $(QT_QTEST_COMMON_cxxflags)
test_vlc_dialog_model_LDADD = $(QT_QTEST_COMMON_ldadd)
test_vlc_dialog_model_LDFLAGS = $(QT_QTEST_COMMON_ldflags)
check_PROGRAMS += test_vlc_dialog_model
TESTS += test_vlc_dialog_model


test_qt_navigation_model_SOURCES = \
	tests/vlc_stub_modules.cpp \
	tests/test_navigation_model.cpp \
	maininterface/navigationmodel.hpp \
	maininterface/navigationmodel.cpp

nodist_test_qt_navigation_model_SOURCES = \
	tests/test_navigation_model.moc \
	maininterface/navigationmodel.moc.cpp

BUILT_SOURCES += tests/test_navigation_model.moc
CLEANFILES += tests/test_navigation_model.moc
test_qt_navigation_model_CPPFLAGS = $(QT_QTEST_COMMON_cppflags)
test_qt_navigation_model_CXXFLAGS = $(QT_QTEST_COMMON_cxxflags)
test_qt_navigation_model_LDADD = $(QT_QTEST_COMMON_ldadd)
test_qt_navigation_model_LDFLAGS = $(QT_QTEST_COMMON_ldflags)
check_PROGRAMS += test_qt_navigation_model
TESTS += test_qt_navigation_model


endif

QML_LOG_COMPILER = $(builddir)/qml_test -input

if HAVE_QT_QUICK_TEST
qml_test_SOURCES = tests/qml_test.cpp tests/qml_test.hpp
nodist_qml_test_SOURCES = tests/qml_test.moc.cpp
CLEANFILES += $(nodist_qml_test_SOURCES)
qml_test_CPPFLAGS = $(libqt_plugin_la_CPPFLAGS)
qml_test_CXXFLAGS = $(AM_CXXFLAGS) $(QT_CFLAGS) -fPIC $(CXXFLAGS_qt) ${QT_QUICK_TEST_CFLAGS} -DQUICK_TEST_SOURCE_DIR="\"${srcdir}/tests\"" -I"${builddir}/tests"
qml_test_LDADD = $(QT_INDIRECT_LIBS) ${QT_QUICK_TEST_LIBS} $(QT_LIBS) $(LIBS_qt) libqml_module_util.a
qml_test_LDFLAGS = $(AM_LDFLAGS) $(QT_QUICK_TEST_LDFLAGS)
check_PROGRAMS += qml_test
EXTRA_DIST += tests/tst_FSM.qml
TESTS += tests/tst_FSM.qml
endif
endif
