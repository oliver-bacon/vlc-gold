/*****************************************************************************
 * menus.cpp : Qt menus
 *****************************************************************************
 * Copyright © 2006-2011 the VideoLAN team
 *
 * Authors: Clément Stenac <zorglub@videolan.org>
 *          Jean-Baptiste Kempf <jb@videolan.org>
 *          Jean-Philippe André <jpeg@videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
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

/** \todo
 * - Remove static currentGroup
 */

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <vlc_common.h>
#include <vlc_intf_strings.h>
#include <vlc_aout.h>                             /* audio_output_t */
#include <vlc_interface.h>

#include "menus.hpp"

#include "maininterface/mainctx.hpp"                     /* View modifications */
#include "maininterface/mainctx_submodels.hpp"
#include "dialogs/dialogs_provider.hpp"                   /* Dialogs display */
#include "dialogs/help/help.hpp"
#include "player/player_controller.hpp"                      /* Input Management */
#include "playlist/playlist_controller.hpp"
#include "dialogs/extensions/extensions_manager.hpp"                 /* Extensions menu */
#include "dialogs/extended/extended_panels.hpp"
#include "dialogs/systray/systray.hpp"
#include "util/varchoicemodel.hpp"
#include "util/color_scheme_model.hpp"
#include "util/colorizedsvgicon.hpp"
#include "medialibrary/medialib.hpp"
#include "medialibrary/mlrecentmediamodel.hpp"
#include "medialibrary/mlbookmarkmodel.hpp"


#include <QMenu>
#include <QMenuBar>
#include <QAction>
#include <QActionGroup>
#include <QSignalMapper>

using namespace vlc::playlist;

/*
  This file defines the main menus and the pop-up menu (right-click menu)
  and the systray menu (in that order in the file)

  There are 4 menus that have to be rebuilt every time there are called:
  Audio, Video, Navigation, view
  4 functions are building those menus: AudioMenu, VideoMenu, NavigMenu, View

  */

RendererMenu *VLCMenuBar::rendererMenu = NULL;

/**
 * @brief Add static entries to DP in menus
 **/
template<typename Functor>
QAction *addDPStaticEntry( QMenu *menu,
                       const QString& text,
                       const char *icon,
                       const Functor member,
                       const char *shortcut = NULL,
                       QAction::MenuRole role = QAction::NoRole
                       )
{
    QAction *action = NULL;
#ifndef __APPLE__ /* We don't set icons in menus in MacOS X */
    if( !EMPTY_STR( icon ) )
    {
        action = menu->addAction( ColorizedSvgIcon::colorizedIconForWidget( icon, menu ), text, THEDP, member );
    }
    else
#endif
    {
        action = menu->addAction( text, THEDP, member );
    }
    if( !EMPTY_STR( shortcut ) )
        action->setShortcut( qfut( shortcut ) );
#ifdef __APPLE__
    action->setMenuRole( role );
#else
    Q_UNUSED( role );
#endif
    return action;
}

/**
 * @brief Add static entries to MIM in menus
 **/
template<typename Fun>
static QAction* addMIMStaticEntry( qt_intf_t *p_intf,
                            QMenu *menu,
                            const QString& text,
                            const char *icon,
                            Fun member )
{
    QAction *action;
#ifndef __APPLE__ /* We don't set icons in menus in MacOS X */
    if( !EMPTY_STR( icon ) )
    {
        action = menu->addAction( text, THEMIM,  member );
        action->setIcon( ColorizedSvgIcon::colorizedIconForWidget( icon, menu ) );
    }
    else
#endif
    {
        action = menu->addAction( text, THEMIM, member );
    }
    return action;
}

template<typename Fun>
static QAction* addMPLStaticEntry( qt_intf_t *p_intf,
                            QMenu *menu,
                            const QString& text,
                            const char *icon,
                            Fun member )
{
    QAction *action;
#ifndef __APPLE__ /* We don't set icons in menus in MacOS X */
    if( !EMPTY_STR( icon ) )
    {
        action = menu->addAction( text, THEMPL,  member );
        action->setIcon( ColorizedSvgIcon::colorizedIconForWidget( icon, menu ) );
    }
    else
#endif
    {
        action = menu->addAction( text, THEMPL, member );
    }
    return action;
}

/*****************************************************************************
 * All normal menus
 * Simple Code
 *****************************************************************************/

/**
 * Main Menu Bar Creation
 **/
VLCMenuBar::VLCMenuBar(QObject* parent)
    : QObject(parent)
{}


/**
 * Media ( File ) Menu
 * Opening, streaming and quit
 **/
void VLCMenuBar::FileMenu(qt_intf_t *p_intf, QMenu *menu)
{
    auto mi = p_intf->p_mi;
    QAction *action;

    //use a lambda here as the Triggrered signal is emiting and it will pass false (checked) as a first argument
    addDPStaticEntry( menu, qtr( "Open &File..." ),
        ":/menu/figma/main_open_file_s.svg", []() { THEDP->simpleOpenDialog(); } , "Ctrl+O" );
    addDPStaticEntry( menu, qtr( "&Open Multiple Files..." ),
        ":/menu/figma/main_open_file_s.svg", &DialogsProvider::openFileDialog, "Ctrl+Shift+O" );
    addDPStaticEntry( menu, qfut( I_OP_OPDIR ),
        ":/menu/figma/main_open_folder.svg", &DialogsProvider::PLOpenDir, "Ctrl+F" );
    addDPStaticEntry( menu, qtr( "Open &Disc..." ),
        ":/menu/figma/main_open_disc.svg", &DialogsProvider::openDiscDialog, "Ctrl+D" );
    addDPStaticEntry( menu, qtr( "Open &Network Stream..." ),
        ":/menu/figma/main_open_network_stream.svg", &DialogsProvider::openNetDialog, "Ctrl+N" );
    addDPStaticEntry( menu, qtr( "Open &Capture Device..." ),
        ":/menu/figma/main_open_capture_device.svg", &DialogsProvider::openCaptureDialog, "Ctrl+C" );

    addDPStaticEntry( menu, qtr( "Open &Location from clipboard" ),
                      NULL, &DialogsProvider::openUrlDialog, "Ctrl+V" );

    if( mi && var_InheritBool( p_intf, "save-recentplay" ) && mi->hasMediaLibrary() )
    {
        MLRecentMediaModel* recentModel = new MLRecentMediaModel(nullptr);
        recentModel->setMl(mi->getMediaLibrary());
        recentModel->setLimit(10);
        QMenu* recentsMenu = new RecentMenu(recentModel, mi->getMediaLibrary(), menu);
        recentsMenu->setTitle(qtr( "Open &Recent Media" ) );
        recentModel->setParent(recentsMenu);
        menu->addMenu( recentsMenu );
    }

    menu->addSeparator();

    addDPStaticEntry( menu, qfut( I_PL_SAVE ), "", &DialogsProvider::savePlayingToPlaylist,
        "Ctrl+Y" );

    addDPStaticEntry( menu, qtr( "Conve&rt / Save..." ), "",
        &DialogsProvider::openAndTranscodingDialogs, "Ctrl+R" );
    addDPStaticEntry( menu, qtr( "&Stream..." ),
        ":/menu/figma/file_stream.svg", &DialogsProvider::openAndStreamingDialogs, "Ctrl+S" );
    menu->addSeparator();

    action = menu->addAction( qtr( "Quit at the end of play queue" ), [playlist = THEMPL](bool checked){
        if (checked)
            playlist->setMediaStopAction(PlaylistController::MEDIA_STOPPED_EXIT);
        else
            playlist->setMediaStopAction(PlaylistController::MEDIA_STOPPED_CONTINUE);
    });
    action->setCheckable( true );
    action->setChecked( THEMPL->getMediaStopAction() ==  PlaylistController::MEDIA_STOPPED_EXIT);

    VLCSystray* systray = mi ? mi->getSysTray() : nullptr;
    if( systray )
    {
        action = menu->addAction( qtr( "Close to systray"), systray,
                                 &VLCSystray::toggleUpdateMenu );
    }

    addDPStaticEntry( menu, qtr( "&Quit" ) ,
        ":/menu/figma/player_quit_vlc.svg", &DialogsProvider::quit, "Ctrl+Q" );
}

/**
 * Tools, like Media Information, Preferences or Messages
 **/
void VLCMenuBar::ToolsMenu( qt_intf_t *p_intf, QMenu *menu, bool popup )
{
    addDPStaticEntry( menu, qtr( "&Effects and Filters"), ":/icons/figma/preferences.svg",
            &DialogsProvider::extendedDialog, "Ctrl+E" );

    addDPStaticEntry( menu, qtr( "&Track Synchronization"), ":/icons/figma/preferences.svg",
            &DialogsProvider::synchroDialog, "" );

    /* the player's right-click menu has it at its top level */
    if( !popup )
        addDPStaticEntry( menu, qfut( I_MENU_INFO ) , ":/menu/figma/file_properties_metadata.svg",
            QOverload<>::of(&DialogsProvider::mediaInfoDialog), "Ctrl+I" );

    addDPStaticEntry( menu, qfut( I_MENU_CODECINFO ) ,
        ":/menu/figma/folder_info.svg", &DialogsProvider::mediaCodecDialog, "Ctrl+J" );

#ifdef ENABLE_VLM
    addDPStaticEntry( menu, qfut( I_MENU_VLM ), "", &DialogsProvider::vlmDialog,
        "Ctrl+Shift+W" );
#endif

    addDPStaticEntry( menu, qtr( "Program Guide" ), "", &DialogsProvider::epgDialog,
        "" );

    addDPStaticEntry( menu, qfut( I_MENU_MSG ),
        ":/icons/figma/lists.svg", &DialogsProvider::messagesDialog, "Ctrl+M" );

    addDPStaticEntry( menu, qtr( "Plu&gins and extensions" ),
        "", &DialogsProvider::pluginDialog );
    menu->addSeparator();

    /* not in the player's right-click menu: the player is customized with
     * Customize Player */
    if( !p_intf->b_isDialogProvider && !popup )
        addDPStaticEntry( menu, qtr( "Customi&ze Interface..." ),
            ":/menu/figma/main_customize_player.svg", &DialogsProvider::showToolbarEditorDialog);

    addDPStaticEntry( menu, qtr( "&Preferences" ),
        ":/menu/figma/main_settings.svg", &DialogsProvider::settingsDialog, "Ctrl+P", QAction::PreferencesRole );
}

/**
 * View Menu
 * Interface modification, load other interfaces, activate Extensions
 * \param current, set to NULL for menu creation, else for menu update
 **/
void VLCMenuBar::ViewMenu(qt_intf_t *p_intf, QMenu *menu)
{
    QAction *action;

    MainCtx *mi = p_intf->p_mi;
    assert( mi );
    assert(menu);

    //menu->clear();
    //HACK menu->clear() does not delete submenus
    QList<QAction*> actions = menu->actions();
    foreach( QAction *a, actions )
    {
        QMenu *m = a->menu();
        if( a->parent() == menu ) delete a;
        else menu->removeAction( a );
        if( m && m->parent() == menu ) delete m;
    }

    action = menu->addAction(
#ifndef __APPLE__
            ColorizedSvgIcon::colorizedIconForWidget( ":/menu/figma/player_playlist.svg", menu ),
#endif
            qtr( "Play &Queue" ));
    action->setShortcut(QString( "Ctrl+L" ));
    action->setCheckable( true );
    connect( action, &QAction::triggered, mi->getPlayqueuePanel(), &SidePanelCtx::setVisible );
    action->setChecked( mi->getPlayqueuePanel()->isVisible() );

    /* Docked Play Queue */
    action = menu->addAction( qtr( "Docked Play Queue" ) );
    action->setCheckable( true );
    connect( action, &QAction::triggered, mi->getPlayqueuePanel(), &SidePanelCtx::setDocked );
    action->setChecked( mi->getPlayqueuePanel()->isDocked() );

    menu->addSeparator();

    action = menu->addAction( qtr( "Always on &top" ) );
    action->setCheckable( true );
    action->setChecked( mi->isInterfaceAlwaysOnTop() );
    connect( action, &QAction::triggered, mi, &MainCtx::setInterfaceAlwaysOnTop );

    menu->addSeparator();

    {
        bool isPlayerVisible = mi->getMainInterfaceModes() & MainCtx::MAININTERFACE_MODE_PLAYER;
        action = menu->addAction(qtr("&Big Player View"));
        action->setCheckable( true );
        action->setChecked( isPlayerVisible );
        connect( action, &QAction::triggered, mi, &MainCtx::setPlayerView);
    }

    /* FullScreen View */
    action = menu->addAction( qtr( "&Fullscreen Interface" ), mi,
            &MainCtx::toggleInterfaceFullScreen );
    action->setShortcut( QString( "F11" ) );
    action->setCheckable( true );
    action->setChecked( mi->interfaceVisibility() == QWindow::FullScreen );

    /*Minimal View*/
    action = menu->addAction( qtr( "&Hide UI" ) );
    action->setShortcut(QString( "Ctrl+\\" ));
    action->setCheckable( true );
    connect( action, &QAction::triggered, mi, &MainCtx::setMinimalView );
    action->setChecked( mi->isMinimalView() );

    action = menu->addAction( qtr( "&View Items as Grid" ), mi,
            &MainCtx::setGridView );
    action->setCheckable( true );
    action->setChecked( mi->hasGridView() );

    menu->addMenu( new CheckableListMenu(qtr( "&Color Scheme" ), mi->getColorScheme(), QActionGroup::ExclusionPolicy::Exclusive, menu) );

    menu->addSeparator();

    InterfacesMenu( p_intf, menu );
    menu->addSeparator();

    /* Extensions */
    ExtensionsMenu( p_intf, menu );
}

/**
 * Interface Sub-Menu, to list extras interface and skins
 **/
void VLCMenuBar::InterfacesMenu( qt_intf_t *p_intf, QMenu *current )
{
    assert(current);
    VLCVarChoiceModel* model = new VLCVarChoiceModel(VLC_OBJECT(p_intf->intf), "intf-add", current);
    CheckableListMenu* submenu = new CheckableListMenu(qtr("Interfaces"), model, QActionGroup::ExclusionPolicy::None, current);
    current->addMenu(submenu);
}

/**
 * Extensions menu: populate the current menu with extensions
 **/
void VLCMenuBar::ExtensionsMenu( qt_intf_t *p_intf, QMenu *extMenu )
{
    /* Get ExtensionsManager and load extensions if needed */
    ExtensionsManager *extMgr = ExtensionsManager::getInstance( p_intf );

    if( !var_InheritBool( p_intf, "qt-autoload-extensions")
        && !extMgr->isLoaded() )
    {
        return;
    }

    if( !extMgr->isLoaded() && !extMgr->cannotLoad() )
    {
        extMgr->loadExtensions();
    }

    /* Let the ExtensionsManager build itself the menu */
    extMenu->addSeparator();
    extMgr->menu( extMenu );
}

void VLCMenuBar::VolumeEntries( qt_intf_t *p_intf, QMenu *current )
{
    current->addSeparator();

    current->addAction( QIcon( ":/icons/figma/volume_high.svg" ), qtr( "&Increase Volume" ), THEMIM, &PlayerController::setVolumeUp );
    current->addAction( QIcon( ":/icons/figma/volume_low.svg" ), qtr( "&Decrease Volume" ), THEMIM, &PlayerController::setVolumeDown );
    current->addAction( QIcon( ":/icons/figma/volume_muted.svg" ), qtr( "&Mute" ), THEMIM, &PlayerController::toggleMuted );
}

/**
 * Main Audio Menu
 **/
void VLCMenuBar::AudioMenu( qt_intf_t *p_intf, QMenu * current )
{
    if( current->isEmpty() )
    {
        current->addMenu(new CheckableListMenu(qtr( "Audio &Track" ), THEMIM->getAudioTracks(), QActionGroup::ExclusionPolicy::ExclusiveOptional, current));

        current->addMenu(new CheckableListMenu(qtr( "&Audio Device" ), THEMIM->getAudioDevices(), QActionGroup::ExclusionPolicy::Exclusive, current));

        VLCVarChoiceModel *mix_mode = THEMIM->getAudioMixMode();
        if (mix_mode->rowCount() == 0)
            current->addMenu( new CheckableListMenu(qtr( "&Stereo Mode" ), THEMIM->getAudioStereoMode(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        else
            current->addMenu( new CheckableListMenu(qtr( "&Mix Mode" ), mix_mode, QActionGroup::ExclusionPolicy::Exclusive, current) );
        current->addSeparator();

        current->addMenu( new CheckableListMenu(qtr( "&Visualizations" ), THEMIM->getAudioVisualizations(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        VolumeEntries( p_intf, current );
    }
}

/* Subtitles */
void VLCMenuBar::SubtitleMenu( qt_intf_t *p_intf, QMenu *current, bool b_popup )
{
    if( current->isEmpty() || b_popup )
    {
        addDPStaticEntry( current, qtr( "Add &Subtitle File..." ), "",
                &DialogsProvider::loadSubtitlesFile);
        current->addMenu(new CheckableListMenu(qtr( "Sub &Track" ), THEMIM->getSubtitleTracks(), QActionGroup::ExclusionPolicy::ExclusiveOptional, current));
        current->addSeparator();
    }
}

/**
 * Main Video Menu
 * Subtitles are part of Video.
 **/
void VLCMenuBar::VideoMenu( qt_intf_t *p_intf, QMenu *current )
{
    if( current->isEmpty() )
    {
        current->addMenu(new CheckableListMenu(qtr( "Video &Track" ), THEMIM->getVideoTracks(), QActionGroup::ExclusionPolicy::None, current));

        current->addSeparator();
        current->addMenu( new CheckableListMenu(qtr( "&3D Output" ), THEMIM->getVideoStereoMode(), QActionGroup::ExclusionPolicy::Exclusive, current) );

        current->addSeparator();
        /* Surface modifiers */
        current->addAction(new BooleanPropertyAction(qtr( "&Fullscreen"), THEMIM, "fullscreen", current));
        QAction* action = new BooleanPropertyAction(qtr( "Always Fit &Window"), THEMIM, "autoscale", current);
        action->setEnabled( THEMIM->hasVideoOutput() );
        connect(THEMIM, &PlayerController::hasVideoOutputChanged, action, &QAction::setEnabled);
        current->addAction(action);
        current->addAction(new BooleanPropertyAction(qtr( "Set as Wall&paper"), THEMIM, "wallpaperMode", current));

        current->addSeparator();
        /* Size modifiers */
        current->addMenu( new CheckableListMenu(qtr( "&Zoom" ), THEMIM->getZoom(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        current->addMenu( new CheckableListMenu(qtr( "&Aspect Ratio" ), THEMIM->getAspectRatio(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        current->addMenu( new CheckableListMenu(qtr( "&Crop" ), THEMIM->getCrop(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        current->addMenu( new CheckableListMenu(qtr( "&Fit" ), THEMIM->getFit(), QActionGroup::ExclusionPolicy::Exclusive, current) );

        current->addSeparator();
        /* Rendering modifiers */
        current->addMenu( new CheckableListMenu(qtr( "&Deinterlace" ), THEMIM->getDeinterlace(), QActionGroup::ExclusionPolicy::Exclusive, current) );
        current->addMenu( new CheckableListMenu(qtr( "&Deinterlace mode" ), THEMIM->getDeinterlaceMode(), QActionGroup::ExclusionPolicy::Exclusive, current) );

        current->addSeparator();
        /* Other actions */
        QAction* snapshotAction = new QAction(qtr( "Take &Snapshot" ), current);
        connect(snapshotAction, &QAction::triggered, THEMIM, &PlayerController::snapshot);
        current->addAction(snapshotAction);
    }
}

/**
 * Navigation Menu
 * For DVD, MP4, MOV and other chapter based format
 **/
void VLCMenuBar::NavigMenu( qt_intf_t *p_intf, QMenu *menu, bool withTransport )
{
    QAction *action;
    QMenu *submenu;

    menu->addMenu( new CheckableListMenu( qtr( "T&itle" ), THEMIM->getTitles(), QActionGroup::ExclusionPolicy::Exclusive, menu) );
    submenu = new CheckableListMenu( qtr( "&Chapter" ), THEMIM->getChapters(), QActionGroup::ExclusionPolicy::Exclusive, menu );
    submenu->setTearOffEnabled( true );
    menu->addMenu( submenu );
    menu->addMenu( new CheckableListMenu( qtr("&Program") , THEMIM->getPrograms(), QActionGroup::ExclusionPolicy::Exclusive, menu) );

    MainCtx * mi = p_intf->p_mi;

    if (mi && p_intf->p_mi->hasMediaLibrary() )
    {
        MediaLib * mediaLib = mi->getMediaLibrary();

        BookmarkMenu * bookmarks = new BookmarkMenu(mediaLib, p_intf->p_player, menu);

        bookmarks->setTitle(qfut(I_MENU_BOOKMARK));

        action = menu->addMenu(bookmarks);

        action->setData("bookmark");
    }

    menu->addSeparator();

    if ( !VLCMenuBar::rendererMenu )
        VLCMenuBar::rendererMenu = new RendererMenu( NULL, p_intf, p_intf->p_mainPlayerController );

    menu->addMenu( VLCMenuBar::rendererMenu );
    menu->addSeparator();


    PopupMenuControlEntries( menu, p_intf );

    if( withTransport )
        RebuildNavigMenu( p_intf, menu );
}

void VLCMenuBar::RebuildNavigMenu( qt_intf_t *p_intf, QMenu *menu )
{
    QAction* action;

#define ADD_ACTION( title, slot, visibleSignal, visible ) \
    action = menu->addAction( title, THEMIM,  slot ); \
    if (! visible)\
        action->setVisible(false); \
    connect( THEMIM, visibleSignal, action, &QAction::setVisible );

    ADD_ACTION( qtr("Previous Title"), &PlayerController::titlePrev, &PlayerController::hasTitlesChanged, THEMIM->hasTitles() );
    ADD_ACTION( qtr("Next Title"), &PlayerController::titleNext, &PlayerController::hasTitlesChanged, THEMIM->hasTitles() );
    ADD_ACTION( qtr("Previous Chapter"), &PlayerController::chapterPrev, &PlayerController::hasChaptersChanged, THEMIM->hasChapters() );
    ADD_ACTION( qtr("Next Chapter"), &PlayerController::chapterNext, &PlayerController::hasChaptersChanged, THEMIM->hasChapters() );

#undef ADD_ACTION

    PopupMenuPlaylistEntries( menu, p_intf );
}

/**
 * Help/About Menu
**/
void VLCMenuBar::HelpMenu(qt_intf_t *p_intf, QMenu *menu )
{
    addDPStaticEntry( menu, qtr( "&Help" ) ,
        ":/menu/figma/folder_info.svg", &DialogsProvider::helpDialog, "F1" );
    /* VLC Gold's own check (GitHub releases), only when asked */
    if( p_intf->p_mi && !p_intf->b_isDialogProvider )
        addDPStaticEntry( menu, qtr( "Check for &Updates..." ) , "",
                          &DialogsProvider::checkForUpdatesDialog );
#ifdef UPDATE_CHECK
    addDPStaticEntry( menu, qtr( "Check for VLC &Updates..." ) , "",
                     [ctx = QPointer(p_intf->p_mi)]() {
        if (Q_LIKELY(ctx))
        {
            const auto updateModel = ctx->getUpdateModel();
            assert(updateModel);
            updateModel->checkUpdate(true);
        }
    });
#endif
    menu->addSeparator();
    addDPStaticEntry( menu, qfut( I_MENU_ABOUT ), ":/menu/figma/main_about_vlc.svg",
            &DialogsProvider::aboutDialog, "Shift+F1", QAction::AboutRole );
}

/*****************************************************************************
 * Popup menus - Right Click menus                                           *
 *****************************************************************************/

void VLCMenuBar::PopupMenuPlaylistEntries( QMenu *menu, qt_intf_t *p_intf )
{
    QAction *action;
    bool hasInput = THEMIM->hasInput();

    /* Play or Pause action and icon */
    if( !hasInput || THEMIM->getPlayingState() != PlayerController::PLAYING_STATE_PLAYING )
    {
        action = menu->addAction( qtr( "&Play" ), [p_intf]() {
            if ( THEMPL->isEmpty() )
                THEDP->openFileDialog();
            else
                THEMPL->togglePlayPause();
        });
#ifndef __APPLE__ /* No icons in menus in Mac */
        action->setIcon( ColorizedSvgIcon::colorizedIconForWidget( QStringLiteral(":/menu/figma/player_play.svg"), menu ) );
#endif
    }
    else
    {
        action = addMPLStaticEntry( p_intf, menu, qtr( "Pause" ),
                ":/menu/figma/player_pause.svg", &PlaylistController::togglePlayPause );
    }

    /* Stop */
    action = addMPLStaticEntry( p_intf, menu, qtr( "&Stop" ),
            ":/menu/figma/player_stop.svg", &PlaylistController::stop );
    if( !hasInput )
        action->setEnabled( false );

    /* Next / Previous */
    bool bPlaylistEmpty = THEMPL->isEmpty();
    QAction* previousAction = addMPLStaticEntry( p_intf, menu, qtr( "Pre&vious" ),
            ":/menu/figma/player_previous_item.svg", &PlaylistController::prev );
    previousAction->setEnabled( !bPlaylistEmpty );
    connect( THEMPL, &PlaylistController::isEmptyChanged, previousAction, &QAction::setDisabled);

    QAction* nextAction = addMPLStaticEntry( p_intf, menu, qtr( "Ne&xt" ),
            ":/menu/figma/player_next_item.svg", &PlaylistController::next );
    nextAction->setEnabled( !bPlaylistEmpty );
    connect( THEMPL, &PlaylistController::isEmptyChanged, nextAction, &QAction::setDisabled);

    action = menu->addAction( qtr( "Record" ), THEMIM, &PlayerController::toggleRecord );
    action->setIcon( QIcon( ":/menu/figma/player_record.svg" ) );
    if( !hasInput )
        action->setEnabled( false );
    menu->addSeparator();
}

void VLCMenuBar::PopupMenuControlEntries( QMenu *menu, qt_intf_t *p_intf,
                                        bool b_normal )
{
    QAction *action;
    QMenu *rateMenu = new QMenu( qtr( "Sp&eed" ), menu );
    rateMenu->setTearOffEnabled( true );

    if( b_normal )
    {
        /* Faster/Slower */
        action = rateMenu->addAction( qtr( "&Faster" ), THEMIM,
                                  &PlayerController::faster );
    }

    action = rateMenu->addAction( qtr( "Faster (fine)" ), THEMIM,
                              &PlayerController::littlefaster );

    action = rateMenu->addAction( qtr( "N&ormal Speed" ), THEMIM,
                              &PlayerController::normalRate );

    action = rateMenu->addAction( qtr( "Slower (fine)" ), THEMIM,
                              &PlayerController::littleslower );

    if( b_normal )
    {
        action = rateMenu->addAction( qtr( "Slo&wer" ), THEMIM,
                                  &PlayerController::slower );
    }

    action = menu->addMenu( rateMenu );
#ifndef __APPLE__ /* No icons in menus in Mac */
    /* the design's icon set has a speed icon, no faster / slower arrows */
    action->setIcon( QIcon( QStringLiteral( ":/icons/figma/speed.svg" ) ) );
#endif

    menu->addSeparator();

    if( !b_normal ) return;

    action = menu->addAction( qtr( "&Jump Forward" ), THEMIM,
             &PlayerController::jumpFwd );
#ifndef __APPLE__ /* No icons in menus in Mac */
    action->setIcon( ColorizedSvgIcon::colorizedIconForWidget( ":/icons/figma/forward_10_sec.svg", menu ) );
#endif

    action = menu->addAction( qtr( "Jump Bac&kward" ), THEMIM,
             &PlayerController::jumpBwd );
#ifndef __APPLE__ /* No icons in menus in Mac */
    action->setIcon( ColorizedSvgIcon::colorizedIconForWidget( ":/icons/figma/backward_10_sec.svg", menu ) );
#endif

    action = menu->addAction( qfut( I_MENU_GOTOTIME ), THEDP, &DialogsProvider::gotoTimeDialog );
    action->setShortcut( QKeySequence( "Ctrl+T" ) );

    menu->addSeparator();
}

void VLCMenuBar::PopupMenuStaticEntries( QMenu *menu )
{
    QMenu *openmenu = new QMenu( qtr( "Open Media" ), menu );
    addDPStaticEntry( openmenu, qfut( I_OP_OPF ),
        ":/menu/figma/main_open_file_s.svg", &DialogsProvider::openFileDialog);
    addDPStaticEntry( openmenu, qfut( I_OP_OPDIR ),
        ":/menu/figma/main_open_folder.svg", &DialogsProvider::PLOpenDir);
    addDPStaticEntry( openmenu, qtr( "Open &Disc..." ),
        ":/menu/figma/main_open_disc.svg", &DialogsProvider::openDiscDialog);
    addDPStaticEntry( openmenu, qtr( "Open &Network..." ),
        ":/menu/figma/main_open_network_stream.svg", &DialogsProvider::openNetDialog);
    addDPStaticEntry( openmenu, qtr( "Open &Capture Device..." ),
        ":/menu/figma/main_open_capture_device.svg", &DialogsProvider::openCaptureDialog);
    menu->addMenu( openmenu );

    menu->addSeparator();

    addDPStaticEntry( menu, qtr( "Quit" ), ":/menu/figma/player_quit_vlc.svg",
                      &DialogsProvider::quit, "Ctrl+Q", QAction::QuitRole );
}

/* Video Tracks and Subtitles tracks */
QMenu* VLCMenuBar::VideoPopupMenu( qt_intf_t *p_intf, bool show )
{
    QMenu* menu = new VLCMenu(p_intf);
    VideoMenu(p_intf, menu);
    if( show )
        menu->popup( QCursor::pos() );
    return menu;
}

/* Audio Tracks */
QMenu* VLCMenuBar::AudioPopupMenu( qt_intf_t *p_intf, bool show )
{
    QMenu* menu = new VLCMenu(p_intf);
    AudioMenu(p_intf, menu);
    if( show )
        menu->popup( QCursor::pos() );
    return menu;
}

/* Navigation stuff, and general menus ( open ), used only for skins */
QMenu* VLCMenuBar::MiscPopupMenu( qt_intf_t *p_intf, bool show )
{
    QMenu* menu = new VLCMenu(p_intf);

    menu->addSeparator();
    PopupMenuPlaylistEntries( menu, p_intf );

    menu->addSeparator();
    PopupMenuControlEntries( menu, p_intf );

    menu->addSeparator();
    PopupMenuStaticEntries( menu );

    if( show )
        menu->popup( QCursor::pos() );
    return menu;
}

/* Main Menu that sticks everything together  */
namespace {

/* Icon of the Figma "right-click menu" rows (two-tone, not colorized) */
QIcon figmaMenuIcon( const char *name )
{
    return QIcon( QStringLiteral( ":/menu/figma/%1.svg" ).arg( QLatin1String( name ) ) );
}

/* "Ctrl+q" -> "Ctrl + Q", as displayed by the design */
QString hotkeyText( const char *var )
{
    char *psz = config_GetPsz( var );
    // several keys may be bound, separated by tabs: show the first one
    QString key = qfu( psz ? psz : "" ).section( '\t', 0, 0 );
    free( psz );
    QStringList parts = key.split( '+', Qt::SkipEmptyParts );
    for( QString &part : parts )
    {
        if( part.size() == 1 )
            part = part.toUpper();
        else
            part[0] = part[0].toUpper();
    }
    return parts.join( QStringLiteral( " + " ) );
}

/* Menu text with the shortcut drawn in the right column (the key itself is
 * handled by the hotkeys module, not by the menu) */
QString withHotkey( const QString &text, const QString &key )
{
    return key.isEmpty() ? text : text + '\t' + key;
}

QAction *addSubmenu( QMenu *menu, QMenu *submenu, const QString &text, const char *icon )
{
    QAction *action = menu->addMenu( submenu );
    action->setText( text );
    action->setIcon( figmaMenuIcon( icon ) );
    if( submenu->isEmpty() )
        action->setEnabled( false );
    return action;
}

} // namespace

/* Player right-click menu, organized like the "right-click menu" of the
 * VLC Redesign Figma file */
QMenu* VLCMenuBar::PopupMenu( qt_intf_t *p_intf, bool show )
{
    QMenu* menu = new VLCMenu(p_intf);
    const bool hasInput = THEMIM->hasInput();
    const bool playlistEmpty = THEMPL->isEmpty();
    QAction *action;

    /* Transport */
    const bool playing = hasInput && THEMIM->getPlayingState() == PlayerController::PLAYING_STATE_PLAYING;
    action = menu->addAction( figmaMenuIcon( playing ? "player_pause" : "player_play" ),
                              withHotkey( playing ? qtr( "Pause" ) : qtr( "Play" ), hotkeyText( "key-play-pause" ) ),
                              [p_intf]() {
        if ( THEMPL->isEmpty() )
            THEDP->openFileDialog();
        else
            THEMPL->togglePlayPause();
    });

    action = menu->addAction( figmaMenuIcon( "player_stop" ), withHotkey( qtr( "Stop" ), hotkeyText( "key-stop" ) ),
                              THEMPL, &PlaylistController::stop );
    action->setEnabled( hasInput );

    action = menu->addAction( figmaMenuIcon( "player_previous_item" ),
                              withHotkey( qtr( "Previous Item" ), hotkeyText( "key-prev" ) ),
                              THEMPL, &PlaylistController::prev );
    action->setEnabled( !playlistEmpty );

    action = menu->addAction( figmaMenuIcon( "player_next_item" ),
                              withHotkey( qtr( "Next Item" ), hotkeyText( "key-next" ) ),
                              THEMPL, &PlaylistController::next );
    action->setEnabled( !playlistEmpty );

    action = menu->addAction( figmaMenuIcon( "player_record" ), withHotkey( qtr( "Record" ), hotkeyText( "key-record" ) ),
                              THEMIM, &PlayerController::toggleRecord );
    action->setEnabled( hasInput );

    menu->addSeparator();

    /* Hide UI (the player controls stay hidden until toggled again) */
    MainCtx *mi = p_intf->p_mi;
    action = menu->addAction( figmaMenuIcon( "player_hide_ui" ), withHotkey( qtr( "Hide UI" ), QStringLiteral( "Ctrl + \\" ) ) );
    if( mi )
    {
        action->setCheckable( true );
        action->setChecked( mi->isMinimalView() );
        connect( action, &QAction::triggered, mi, &MainCtx::setMinimalView );
    }
    else
        action->setEnabled( false );

    menu->addSeparator();

    /* Playback, Video, Audio, Subtitle */
    QMenu *submenu = new QMenu( menu );
    if( hasInput )
    {
        /* play/pause, stop... are already at the top of the menu */
        NavigMenu( p_intf, submenu, false );
    }
    addSubmenu( menu, submenu, qtr( "Playback" ), "player_playback" );

    submenu = new QMenu( menu );
    if( hasInput )
        VideoMenu( p_intf, submenu );
    addSubmenu( menu, submenu, qtr( "Video" ), "player_video" );

    submenu = new QMenu( menu );
    if( hasInput )
        AudioMenu( p_intf, submenu );
    addSubmenu( menu, submenu, qtr( "Audio" ), "player_audio" );

    submenu = new QMenu( menu );
    if( hasInput )
        SubtitleMenu( p_intf, submenu, true );
    addSubmenu( menu, submenu, qtr( "Subtitle" ), "player_subtitle" );

    action = menu->addAction( figmaMenuIcon( "file_properties_metadata" ),
                              withHotkey( qtr( "Media Information" ), QStringLiteral( "Ctrl + I" ) ),
                              THEDP, QOverload<>::of( &DialogsProvider::mediaInfoDialog ) );

    menu->addSeparator();

    /* Playlist: play queue options */
    submenu = new QMenu( menu );
    action = submenu->addAction( qtr( "Shuffle" ) );
    action->setCheckable( true );
    action->setChecked( THEMPL->isRandom() );
    connect( action, &QAction::toggled, THEMPL, &PlaylistController::setRandom );
    const auto repeat = THEMPL->getRepeatMode();
    action = submenu->addAction( qtr( "Repeat All" ) );
    action->setCheckable( true );
    action->setChecked( repeat == PlaylistController::PLAYBACK_REPEAT_ALL );
    connect( action, &QAction::toggled, THEMPL, [p_intf]( bool on ) {
        THEMPL->setRepeatMode( on ? PlaylistController::PLAYBACK_REPEAT_ALL : PlaylistController::PLAYBACK_REPEAT_NONE );
    } );
    action = submenu->addAction( qtr( "Repeat One" ) );
    action->setCheckable( true );
    action->setChecked( repeat == PlaylistController::PLAYBACK_REPEAT_CURRENT );
    connect( action, &QAction::toggled, THEMPL, [p_intf]( bool on ) {
        THEMPL->setRepeatMode( on ? PlaylistController::PLAYBACK_REPEAT_CURRENT : PlaylistController::PLAYBACK_REPEAT_NONE );
    } );
    submenu->addSeparator();
    addDPStaticEntry( submenu, qfut( I_PL_SAVE ), "", &DialogsProvider::savePlayingToPlaylist );
    action = submenu->addAction( qtr( "Clear the Play Queue" ), THEMPL, &PlaylistController::clear );
    action->setEnabled( !playlistEmpty );
    addSubmenu( menu, submenu, qtr( "Playlist" ), "player_playlist" );

    /* Open Media */
    submenu = new QMenu( menu );
    addDPStaticEntry( submenu, qfut( I_OP_OPF ), "", &DialogsProvider::openFileDialog );
    addDPStaticEntry( submenu, qfut( I_OP_OPDIR ), "", &DialogsProvider::PLOpenDir );
    addDPStaticEntry( submenu, qtr( "Open &Disc..." ), "", &DialogsProvider::openDiscDialog );
    addDPStaticEntry( submenu, qtr( "Open &Network..." ), "", &DialogsProvider::openNetDialog );
    addDPStaticEntry( submenu, qtr( "Open &Capture Device..." ), "", &DialogsProvider::openCaptureDialog );
    addSubmenu( menu, submenu, qtr( "Open Media" ), "player_open_media" );

    /* More: everything the design does not show, at the end of the menu */
    submenu = new QMenu( menu );
    ToolsMenu( p_intf, submenu, true );
    submenu->addSeparator();
    if( p_intf->b_isDialogProvider )
    {
        vlc_object_t* p_object = vlc_object_parent(p_intf->intf);

        /* Open skin dialog box */
        if (var_Type(p_object, "intf-skins-interactive") & VLC_VAR_ISCOMMAND)
        {
            QAction* openSkinAction = new QAction(qtr("Open skin..."), submenu);
            openSkinAction->setShortcut( QKeySequence( "Ctrl+Shift+S" ));
            connect(openSkinAction, &QAction::triggered, [=]() {
                var_TriggerCallback(p_object, "intf-skins-interactive");
            });
            submenu->addAction(openSkinAction);
        }

        VLCVarChoiceModel* skinmodel = new VLCVarChoiceModel(p_object, "intf-skins", submenu);
        CheckableListMenu* skinsubmenu = new CheckableListMenu(qtr("Interface"), skinmodel, QActionGroup::ExclusionPolicy::ExclusiveOptional, submenu);
        submenu->addMenu(skinsubmenu);

        submenu->addSeparator();
        ExtensionsMenu( p_intf, submenu );
    }
    else
    {
        QMenu* viewMenu = new QMenu( qtr( "V&iew" ), submenu );
        ViewMenu( p_intf, viewMenu );
        submenu->addMenu( viewMenu );
    }
    QMenu* helpmenu = new QMenu( qtr( "Help" ), submenu );
    HelpMenu( p_intf, helpmenu );
    submenu->addMenu( helpmenu );
    addSubmenu( menu, submenu, qtr( "More" ), "player_more_settings" );

    action = menu->addAction( figmaMenuIcon( "player_quit_vlc" ), withHotkey( qtr( "Quit VLC" ), QStringLiteral( "Ctrl + Q" ) ),
                              THEDP, &DialogsProvider::quit );
    action->setMenuRole( QAction::QuitRole );

    if( show )
        menu->popup( QCursor::pos() );
    return menu;
}
