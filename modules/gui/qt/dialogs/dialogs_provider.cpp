/*****************************************************************************
 * dialogs_provider.cpp : Dialog Provider
 *****************************************************************************
 * Copyright (C) 2006-2009 the VideoLAN team
 *
 * Authors: Clément Stenac <zorglub@videolan.org>
 *          Jean-Baptiste Kempf <jb@videolan.org>
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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <vlc_common.h>
#include <vlc_interface.h>
#include <vlc_intf_strings.h>
#include <vlc_preparser.h>

#include "qt.hpp"
#include "dialogs_provider.hpp"
#include "player/player_controller.hpp" /* Load Subtitles */
#include "playlist/playlist_controller.hpp"
#include "menus/menus.hpp"
#include "util/qt_dirs.hpp"
#include "util/vlchotkeyconverter.hpp"
#include "maininterface/mainctx.hpp"

/* The dialogs */
#include "dialogs/bookmarks/bookmarks.hpp"
#include "dialogs/preferences/preferences.hpp"
#include "dialogs/mediainfo/mediainfo.hpp"
#include "dialogs/messages/messages.hpp"
#include "dialogs/extended/extended.hpp"
#include "dialogs/vlm/vlm.hpp"
#include "dialogs/sout/sout.hpp"
#include "dialogs/sout/convert.hpp"
#include "dialogs/open/open.hpp"
#include "dialogs/open/openurl.hpp"
#include "dialogs/help/help.hpp"
#include "dialogs/gototime/gototime.hpp"
#include "dialogs/podcast/podcast_configuration.hpp"
#include "dialogs/plugins/plugins.hpp"
#include "dialogs/epg/epg.hpp"
#include "dialogs/playlists/playlists.hpp"
#include "dialogs/firstrun/firstrunwizard.hpp"

#include <vlc_url.h>

#include <QEvent>
#include <QEventLoop>
#include <QMetaMethod>
#include <QTimer>
#include <QApplication>
#include <QClipboard>
#include <QFile>
#include <QSignalMapper>
#include <QFileDialog>
#include <QUrl>
#include <QInputDialog>
#include <QPointer>
#include <QMessageBox>

#define I_OP_DIR_WINTITLE I_DIR_OR_FOLDER( N_("Open Directory"), \
                                           N_("Open Folder") )

#define BASE_DIALOG(X) \
    X(prefsDialog) \
    X(openDialog) \
    X(firstRunDialog) \
    X(extendedDialog) \
    X(messagesDialog) \
    X(gotoTimeDialog) \
    X(vlmDialog) \
    X(helpDialog) \
    X(aboutDialog) \
    X(mediaInfoDialog) \
    X(bookmarkDialog) \
    X(podcastDialog) \
    X(pluginDialog)\
    X(egpDialog)


#ifdef UPDATE_CHECK
#define ALL_DIALOG(X) \
    BASE_DIALOG(X) \
    X(updateDialog)
#else
#define ALL_DIALOG(X) BASE_DIALOG(X)
#endif

DialogsProvider::DialogsProvider( qt_intf_t *_p_intf )
    : QObject( NULL ), p_intf( _p_intf ), m_parser( nullptr, &input_item_parser_id_Release )

{
    b_isDying = false;
}

DialogsProvider::~DialogsProvider()
{
    /* free parentless menus  */
    VLCMenuBar::freeRendererMenu();
}

QString DialogsProvider::getSaveFileName( QWidget *parent,
                                          const QString &caption,
                                          const QUrl &dir,
                                          const QString &filter,
                                          QString *selectedFilter )
{
    const QStringList schemes = QStringList(QStringLiteral("file"));
    return QFileDialog::getSaveFileUrl( parent, caption, dir, filter, selectedFilter, QFileDialog::Options(), schemes).toLocalFile();
}

QVariant DialogsProvider::getTextDialog(QWidget *parent,
                                        const QString &title,
                                        const QString &label,
                                        const QString &placeholder,
                                        bool *ok)
{
    bool _ok = false;
    QString ret = QInputDialog::getText(parent,
                                        title,
                                        label,
                                        QLineEdit::Normal,
                                        placeholder,
                                        ok ? ok : &_ok);

    if (!ok)
    {
        // When this function is called from the QML side, instead of setting `ok` parameter
        // a QVariantMap with key `ok` and `text` is returned instead

        QVariantMap map;
        map["text"] = ret;
        map["ok"] = _ok;
        return map;
    }
    else
    {
        return ret;
    }
}

void DialogsProvider::quit()
{
    if (b_isDying)
        return;
    b_isDying = true;
    assert(qApp);
    qApp->setProperty("isDying", true);
    libvlc_Quit( vlc_object_instance(p_intf) );
}

void DialogsProvider::customEvent( QEvent *event )
{
    if( event->type() == DialogEvent::DialogEvent_Type )
    {
        DialogEvent *de = static_cast<DialogEvent*>(event);
        switch( de->i_dialog )
        {
        case INTF_DIALOG_FILE_SIMPLE:
        case INTF_DIALOG_FILE:
            openDialog(); break;
        case INTF_DIALOG_FILE_GENERIC:
            openFileGenericDialog( de->p_arg ); break;
        case INTF_DIALOG_DISC:
            openDiscDialog(); break;
        case INTF_DIALOG_NET:
            openNetDialog(); break;
        case INTF_DIALOG_SAT:
        case INTF_DIALOG_CAPTURE:
            openCaptureDialog(); break;
        case INTF_DIALOG_DIRECTORY:
            PLAppendDir(); break;
        case INTF_DIALOG_PLAYLIST:
            //FIXME
            //playlistDialog(); break;
            break;
        // case INTF_DIALOG_PLAYLISTS:
        // FIXME: `intf_dialog_args_t` is not supported by `PlaylistsDialog`.
        case INTF_DIALOG_MESSAGES:
            messagesDialog(); break;
        case INTF_DIALOG_FILEINFO:
           mediaInfoDialog(); break;
        case INTF_DIALOG_PREFS:
           settingsDialog(); break;
        case INTF_DIALOG_BOOKMARKS:
           bookmarksDialog(); break;
        case INTF_DIALOG_EXTENDED:
           extendedDialog(); break;
        case INTF_DIALOG_SENDKEY:
           sendKey( de->i_arg ); break;
#ifdef ENABLE_VLM
        case INTF_DIALOG_VLM:
           vlmDialog(); break;
#endif
        case INTF_DIALOG_POPUPMENU:
        {
           popupMenu.reset();
           bool show = (de->i_arg != 0);
           if( show )
           {
              //popping a QMenu prevents mouse release events to be received,
              //this ensures the coherency of the vout mouse state.
              emit releaseMouseEvents();
              popupMenu.reset(VLCMenuBar::PopupMenu( p_intf, true ));
           }
           break;
        }
        case INTF_DIALOG_AUDIOPOPUPMENU:
        {
           audioPopupMenu.reset();
           bool show = (de->i_arg != 0);
           if( show )
               audioPopupMenu.reset(VLCMenuBar::AudioPopupMenu( p_intf, show ));
           break;
        }
        case INTF_DIALOG_VIDEOPOPUPMENU:
        {
           videoPopupMenu.reset();
           bool show = (de->i_arg != 0);
           if( show )
               videoPopupMenu.reset(VLCMenuBar::VideoPopupMenu( p_intf, show ));
           break;
        }
        case INTF_DIALOG_MISCPOPUPMENU:
        {
           miscPopupMenu.reset();
           bool show = (de->i_arg != 0);
           if( show )
               miscPopupMenu.reset(VLCMenuBar::MiscPopupMenu( p_intf, show ));
           break;
        }
        case INTF_DIALOG_WIZARD:
        case INTF_DIALOG_STREAMWIZARD:
            openAndStreamingDialogs(); break;
#ifdef UPDATE_CHECK
        case INTF_DIALOG_UPDATEVLC:
            updateDialog(); break;
#endif
        case INTF_DIALOG_EXIT:
            quit(); break;
        default:
           msg_Warn( p_intf, "unimplemented dialog" );
        }
    }
}

bool DialogsProvider::eventFilter(QObject *watched, QEvent *event) {
    assert(event);
    assert(watched);

#define CASE_DIALOG(dialog) \
    if (watched == m_ ## dialog .get()) { \
        emit dialog ## VisibleChanged(); \
        break;\
    }

    switch (event->type()) {
    case QEvent::Hide:
    case QEvent::Show:
    case QEvent::Close:
    case QEvent::Destroy:
    {
        ALL_DIALOG(CASE_DIALOG)
        break;
    }
    default:
        break;
    }
    return false;
}


/****************************************************************************
 * Individual simple dialogs
 ****************************************************************************/
const QEvent::Type DialogEvent::DialogEvent_Type =
        (QEvent::Type)QEvent::registerEventType();

void DialogsProvider::settingsDialog()
{
    // The QML main interface connects to this signal to show its settings
    // window; without it (e.g. dialogs-only use of this module), fall back
    // to the classic preferences dialog.
    if (isSignalConnected(QMetaMethod::fromSignal(&DialogsProvider::showSettingsWindow)))
        emit showSettingsWindow();
    else
        prefsDialog();
}

void DialogsProvider::settingsPageDialog(const QString& page)
{
    if (isSignalConnected(QMetaMethod::fromSignal(&DialogsProvider::showSettingsPage)))
        emit showSettingsPage(page);
    else
        prefsDialog();
}

void DialogsProvider::allSettingsDialog()
{
    if (isSignalConnected(QMetaMethod::fromSignal(&DialogsProvider::showAllSettingsWindow)))
        emit showAllSettingsWindow();
    else
        prefsDialog();
}

bool DialogsProvider::figmaDialog(const QString& name, const QVariant& args)
{
    if (!isSignalConnected(QMetaMethod::fromSignal(&DialogsProvider::showFigmaDialog)))
        return false;
    emit showFigmaDialog(name, args);
    return true;
}

void DialogsProvider::keyboardShortcutsDialog()
{
    if (!figmaDialog(QStringLiteral("shortcuts")))
        prefsDialog();
}

void DialogsProvider::customizePlayerDialog()
{
    figmaDialog(QStringLiteral("customize"));
}

void DialogsProvider::newPlaylistDialog(const QVariantList& files)
{
    figmaDialog(QStringLiteral("newPlaylist"), files);
}

void DialogsProvider::addSubtitlesDialog(const QVariant& target)
{
    figmaDialog(QStringLiteral("subtitles"), target);
}

void DialogsProvider::prefsDialog()
{
    if (Q_LIKELY(!m_prefsDialog))
    {
        m_prefsDialog = new PrefsDialog( nullptr, p_intf );
        m_prefsDialog->setAttribute(Qt::WA_DeleteOnClose);
        m_prefsDialog->installEventFilter(this);
        m_prefsDialog->open();
    }
    else
    {
        m_prefsDialog->reject();
    }
}

void DialogsProvider::firstRunDialog()
{
    /* Figma onboarding screens, once the QML interface is ready (it may
     * still be loading at startup); the classic wizard otherwise */
    static int attempts = 0;
    if (figmaDialog(QStringLiteral("onboarding")))
        return;
    if (attempts++ < 20)
    {
        QTimer::singleShot(250, this, &DialogsProvider::firstRunDialog);
        return;
    }

    ensureDialog(m_firstRunDialog);
    QVLCDialog::setWindowTransientParent(m_firstRunDialog.get(), nullptr, p_intf);
    m_firstRunDialog->show();
}

void DialogsProvider::extendedDialog()
{
    ensureDialog(m_extendedDialog);
    if( !m_extendedDialog->isVisible() || /* Hidden */
        m_extendedDialog->currentTab() != 0 )  /* wrong tab */
        m_extendedDialog->showTab( 0 );
    else
        m_extendedDialog->hide();
}

void DialogsProvider::synchroDialog()
{
    ensureDialog(m_extendedDialog);
    if( !m_extendedDialog->isVisible() || /* Hidden */
        m_extendedDialog->currentTab() != 2 )  /* wrong tab */
        m_extendedDialog->showTab( 2 );
    else
        m_extendedDialog->hide();
}

void DialogsProvider::messagesDialog(int page)
{
    // shown again on another tab; a second call on the first tab hides it
    if( figmaDialog( QStringLiteral( "messages" ),
                     QVariantMap { { "tab", page }, { "toggle", page == 0 } } ) )
        return;
    ensureDialog(m_messagesDialog);
    if(!m_messagesDialog->isVisible() || page)
        m_messagesDialog->showTab(page);
    else
        m_messagesDialog->toggleVisible();
}

void DialogsProvider::gotoTimeDialog()
{
    if( figmaDialog( QStringLiteral( "gotoTime" ), QVariantMap { { "toggle", true } } ) )
        return;
    toggleDialogVisible(m_gotoTimeDialog);
}

#ifdef ENABLE_VLM
void DialogsProvider::vlmDialog()
{
    toggleDialogVisible(m_vlmDialog);
}
#endif

void DialogsProvider::helpDialog()
{
    if( figmaDialog( QStringLiteral( "help" ), QVariantMap { { "toggle", true } } ) )
        return;
    toggleDialogVisible(m_helpDialog);
}

#ifdef UPDATE_CHECK
void DialogsProvider::updateDialog(Mode mode)
{
    ensureDialog(m_updateDialog);
    assert(m_updateDialog);

    switch (mode)
    {
    case Mode::Show:
        m_updateDialog->show();
        break;
    case Mode::Hide:
        m_updateDialog->hide();
        break;
    case Mode::Toggle:
    default:
        toggleDialogVisible(m_updateDialog);
    };
}
#endif

void DialogsProvider::aboutDialog()
{
    if( figmaDialog( QStringLiteral( "about" ), QVariantMap { { "toggle", true } } ) )
        return;
    toggleDialogVisible(m_aboutDialog);
}

void DialogsProvider::mediaInfoDialog( void )
{
    // the redesign's window; shown again or hidden like the classic one
    if( figmaDialog( QStringLiteral( "mediaInfo" ), QVariantMap { { "tab", "general" } } ) )
        return;
    ensureDialog(m_mediaInfoDialog);
    if( !m_mediaInfoDialog->isVisible() || m_mediaInfoDialog->currentTab() != MediaInfoDialog::META_PANEL )
        m_mediaInfoDialog->showTab( MediaInfoDialog::META_PANEL );
    else
        m_mediaInfoDialog->hide();
}

void DialogsProvider::mediaInfoDialog( const SharedInputItem& inputItem )
{
    assert(inputItem.get());

    // one window per item, as the classic dialog
    if( figmaDialog( QStringLiteral( "mediaInfoItem" ),
                     QVariantMap { { "item", QVariant::fromValue( inputItem ) } } ) )
        return;

    MediaInfoDialog * const mid = new MediaInfoDialog( p_intf, inputItem );
    mid->setWindowFlag( Qt::Dialog );
    mid->setAttribute( Qt::WA_DeleteOnClose );
    mid->showTab( MediaInfoDialog::META_PANEL );
}

void DialogsProvider::mediaInfoDialog( const PlaylistItem& pItem )
{
    input_item_t *p_input = nullptr;

    vlc_playlist_item_t * const playlistItem = pItem.raw();

    if( playlistItem )
    {
        p_input = vlc_playlist_item_GetMedia(playlistItem);
    }

    if( p_input )
    {
        mediaInfoDialog( SharedInputItem{ p_input } );
    }
}

void DialogsProvider::mediaInfoDialog( const MLItemId& itemId )
{
    assert( p_intf );

    vlc_medialibrary_t* const ml = vlc_ml_instance_get( p_intf );
    assert( ml );

    input_item_t * const inputItem = vlc_ml_get_input_item( ml, itemId.id );
    assert( inputItem );

    const SharedInputItem sharedInputItem { inputItem, false };
    if ( input_item_IsPreparsed( inputItem ) )
    {
        mediaInfoDialog( sharedInputItem );
    }
    else
    {
        static const input_item_parser_cbs_t cbs = {
            // on_preparse_ended
            []( input_item_t * const item, int status, void * const userData ) {
                const auto dp = static_cast<DialogsProvider *>( userData );

                if ( status != VLC_SUCCESS )
                    qWarning( "Could not preparse input item %p. Status %i", item, status );

                const SharedInputItem sharedInputItem{ item };

                QMetaObject::invokeMethod( dp, [dp, sharedInputItem]() {
                        dp->m_parser.reset();
                        dp->mediaInfoDialog( sharedInputItem );
                    }, Qt::QueuedConnection );
            },
            // on_subtree_added
            NULL,
            // on_attachments_added
            NULL,
        };

        const struct input_item_parser_cfg cfg = {
            .cbs = &cbs,
            .cbs_data = this,
            .subitems = true,
            .interact = false,
        };

        m_parser = vlc::wrap_cptr( input_item_Parse( VLC_OBJECT( p_intf ),
                                   inputItem, &cfg ),
                                   &input_item_parser_id_Release );
    }
}

bool DialogsProvider::questionDialog(const QString& text, const QString &title)
{
    // the redesign's dialog (ConfirmDialog.qml), unless one is already open
    if (!m_questionLoop
        && figmaDialog(QStringLiteral("confirm"),
                       QVariantMap{ { QStringLiteral("text"), text },
                                    { QStringLiteral("title"), title } }))
    {
        QEventLoop loop;
        m_questionLoop = &loop;
        m_questionAnswer = false;
        loop.exec();
        m_questionLoop = nullptr;
        return m_questionAnswer;
    }

    QMessageBox messageBox;
    messageBox.setText(text);
    if (!title.isEmpty())
        messageBox.setWindowTitle(title);
    messageBox.setIcon(QMessageBox::Question);
    messageBox.setStandardButtons(QMessageBox::StandardButtons(QMessageBox::Yes | QMessageBox::No));
    messageBox.setDefaultButton(QMessageBox::No);

    QVLCDialog::setWindowTransientParent(&messageBox, nullptr, p_intf);

    int result = messageBox.exec();
    return result == QMessageBox::Yes;
}

void DialogsProvider::answerQuestion(bool yes)
{
    if (!m_questionLoop)
        return;
    m_questionAnswer = yes;
    m_questionLoop->quit();
}

void DialogsProvider::mediaCodecDialog()
{
    if( figmaDialog( QStringLiteral( "mediaInfo" ), QVariantMap { { "tab", "codec" } } ) )
        return;
    ensureDialog(m_mediaInfoDialog);

    if( !m_mediaInfoDialog->isVisible() || m_mediaInfoDialog->currentTab() != MediaInfoDialog::INFO_PANEL )
        m_mediaInfoDialog->showTab( MediaInfoDialog::INFO_PANEL );
    else
        m_mediaInfoDialog->hide();
}

QMessageBox::StandardButton DialogsProvider::messageDialog(const QString &text,
                                                           const QString &title,
                                                           const QMessageBox::StandardButtons buttons,
                                                           const QMessageBox::StandardButton defaultButton,
                                                           const QMessageBox::Icon icon)
{
    QMessageBox messageBox;

    messageBox.setText(text);

    if (!title.isEmpty())
        messageBox.setWindowTitle(title);

    if (icon != QMessageBox::NoIcon)
        messageBox.setIcon(icon);

    if (buttons != QMessageBox::NoButton)
        messageBox.setStandardButtons(buttons);

    if (defaultButton != QMessageBox::NoButton)
        messageBox.setDefaultButton(defaultButton);

    QVLCDialog::setWindowTransientParent(&messageBox, nullptr, p_intf);

    return static_cast<QMessageBox::StandardButton>(messageBox.exec());
}

void DialogsProvider::playlistsDialog( const QVariantList & medias, MLPlaylistListModel::PlaylistType type )
{
    if( figmaDialog( QStringLiteral( "addToPlaylist" ),
                     QVariantMap { { "medias", medias }, { "type", static_cast<int>( type ) } } ) )
        return;
    const auto dialog = new PlaylistsDialog(p_intf, medias, type);
    dialog->setAttribute(Qt::WA_DeleteOnClose);
    dialog->show(); // "Modeless dialogs are displayed using show()"
}

void DialogsProvider::bookmarksDialog()
{
    // the redesigned window needs the media library (MLBookmarkModel)
    if( p_intf->p_mi && p_intf->p_mi->hasMediaLibrary()
        && figmaDialog( QStringLiteral( "bookmarks" ), QVariantMap { { "toggle", true } } ) )
        return;
    toggleDialogVisible(m_bookmarkDialog);
}

void DialogsProvider::podcastConfigureDialog()
{
    if( figmaDialog( QStringLiteral( "podcast" ), QVariantMap { { "toggle", true } } ) )
        return;
    toggleDialogVisible(m_podcastDialog);
}

void DialogsProvider::pluginDialog()
{
    if( figmaDialog( QStringLiteral( "plugins" ), QVariantMap { { "toggle", true } } ) )
        return;
    toggleDialogVisible(m_pluginDialog);
}

void DialogsProvider::epgDialog()
{
    toggleDialogVisible(m_egpDialog);
}

void DialogsProvider::setPopupMenu()
{
    popupMenu.reset(VLCMenuBar::PopupMenu( p_intf, true ));
}

void DialogsProvider::destroyPopupMenu()
{
    popupMenu.reset();
}

/* Generic open file */
void DialogsProvider::openFileGenericDialog( intf_dialog_args_t *p_arg )
{
    if( p_arg == NULL )
    {
        msg_Warn( p_intf, "openFileGenericDialog() called with NULL arg" );
        return;
    }

    /* Replace the extensions to a Qt format */
    int i = 0;
    QString extensions = qfu( p_arg->psz_extensions );
    while ( ( i = extensions.indexOf( "|", i ) ) != -1 )
    {
        if( ( extensions.count( "|" ) % 2 ) == 0 )
            extensions.replace( i, 1, ");;" );
        else
            extensions.replace( i, 1, "(" );
    }
    extensions.replace( ";*", " *" );
    extensions.append( ")" );

    /* Save */
    if( p_arg->b_save )
    {
        QString file = getSaveFileName( NULL,
                                        qfu( p_arg->psz_title ),
                                        p_intf->p_mi->getDialogFilePath(), extensions );
        if( !file.isEmpty() )
        {
            p_arg->i_results = 1;
            p_arg->psz_results = (char **)vlc_alloc( p_arg->i_results, sizeof( char * ) );
            p_arg->psz_results[0] = strdup( qtu( toNativeSepNoSlash( std::move(file) ) ) );
        }
        else
            p_arg->i_results = 0;
    }
    else /* non-save mode */
    {
        QList<QUrl> urls = QFileDialog::getOpenFileUrls( NULL, qfu( p_arg->psz_title ),
                                       p_intf->p_mi->getDialogFilePath(), extensions );
        p_arg->i_results = urls.count();
        p_arg->psz_results = (char **)vlc_alloc( p_arg->i_results, sizeof( char * ) );
        i = 0;
        foreach( const QUrl &uri, urls )
            p_arg->psz_results[i++] = strdup( uri.toEncoded().constData() );
        if( !urls.isEmpty() )
            p_intf->p_mi->setDialogFilePath(urls.last());
    }

    /* Callback */
    if( p_arg->pf_callback )
        p_arg->pf_callback( p_arg );

    /* Clean afterwards */
    if( p_arg->psz_results )
    {
        for( i = 0; i < p_arg->i_results; i++ )
            free( p_arg->psz_results[i] );
        free( p_arg->psz_results );
    }
    free( p_arg->psz_title );
    free( p_arg->psz_extensions );
    free( p_arg );
}
/****************************************************************************
 * All the open/add stuff
 * Open Dialog first - Simple Open then
 ****************************************************************************/

/* name of the tab in the redesign's Open Media window */
static QString openTabName( OpenDialog::OpenTab tab )
{
    switch( tab )
    {
    case OpenDialog::OPEN_DISC_TAB:    return QStringLiteral( "disc" );
    case OpenDialog::OPEN_NETWORK_TAB: return QStringLiteral( "network" );
    case OpenDialog::OPEN_CAPTURE_TAB: return QStringLiteral( "capture" );
    default:                           return QStringLiteral( "file" );
    }
}

void DialogsProvider::openDialog( OpenDialog::OpenTab i_tab )
{
    if( figmaDialog( QStringLiteral( "openMedia" ),
                     QVariantMap { { "tab", openTabName( i_tab ) }, { "enqueue", false } } ) )
        return;
    ensureDialog(m_openDialog);
    m_openDialog->showTab( i_tab, OpenDialog::OPEN_AND_PLAY );
}
void DialogsProvider::openDialog()
{
    openDialog( OpenDialog::OPEN_FILE_TAB );
}
void DialogsProvider::openFileDialog()
{
    openDialog( OpenDialog::OPEN_FILE_TAB );
}
void DialogsProvider::openDiscDialog()
{
    openDialog( OpenDialog::OPEN_DISC_TAB );
}
void DialogsProvider::openNetDialog()
{
    openDialog( OpenDialog::OPEN_NETWORK_TAB );
}
void DialogsProvider::addNetworkStreamDialog()
{
    if( !figmaDialog( QStringLiteral( "network" ) ) )
        openDialog( OpenDialog::OPEN_NETWORK_TAB );
}
void DialogsProvider::openCaptureDialog()
{
    openDialog( OpenDialog::OPEN_CAPTURE_TAB );
}

/* Same as the open one, but force the enqueue */
void DialogsProvider::PLAppendDialog( OpenDialog::OpenTab tab )
{
    if( figmaDialog( QStringLiteral( "openMedia" ),
                     QVariantMap { { "tab", openTabName( tab ) }, { "enqueue", true } } ) )
        return;
    ensureDialog(m_openDialog);
    m_openDialog->showTab( tab, OpenDialog::OPEN_AND_ENQUEUE );
}

/**
 * Simple open
 ***/
QStringList DialogsProvider::showSimpleOpen( const QString& help,
                                             int filters,
                                             const QUrl& path )
{
    QString fileTypes = "";
    if( filters & EXT_FILTER_MEDIA ) {
        ADD_EXT_FILTER( fileTypes, EXTENSIONS_MEDIA );
    }
    if( filters & EXT_FILTER_VIDEO ) {
        ADD_EXT_FILTER( fileTypes, EXTENSIONS_VIDEO );
    }
    if( filters & EXT_FILTER_AUDIO ) {
        ADD_EXT_FILTER( fileTypes, EXTENSIONS_AUDIO );
    }
    if( filters & EXT_FILTER_PLAYLIST ) {
        ADD_EXT_FILTER( fileTypes, EXTENSIONS_PLAYLIST );
    }
    if( filters & EXT_FILTER_SUBTITLE ) {
        ADD_EXT_FILTER( fileTypes, EXTENSIONS_SUBTITLE );
    }
    ADD_EXT_FILTER( fileTypes, EXTENSIONS_ALL );
    fileTypes.replace( ";*", " *");
    fileTypes.chop(2); //remove trailing ";;"

    QList<QUrl> urls = QFileDialog::getOpenFileUrls( NULL,
        help.isEmpty() ? qfut(I_OP_SEL_FILES ) : help,
        path.isEmpty() ? p_intf->p_mi->getDialogFilePath() : path,
        fileTypes );

    if( !urls.isEmpty() )
        p_intf->p_mi->setDialogFilePath(urls.last());

    QStringList res;
    foreach( const QUrl &url, urls )
        res << url.toEncoded();

    return res;
}

void DialogsProvider::simpleOpenDialog(bool start)
{
    QStringList urls = DialogsProvider::showSimpleOpen();

    urls.sort();
    QVector<vlc::playlist::Media> medias;
    for( const QString& mrl : urls)
        medias.push_back( vlc::playlist::Media{mrl, QString {}} );
    if (!medias.empty())
        THEMPL->append(medias, start);
}

/* Url & Clipboard */
/**
 * Open a MRL.
 * If the clipboard contains URLs, the first is automatically 'preselected'.
 **/
void DialogsProvider::openUrlDialog()
{
    if( figmaDialog( QStringLiteral( "openUrl" ) ) )
        return;

    OpenUrlDialog oud( p_intf );
    if( oud.exec() != QDialog::Accepted )
        return;

    openUrl( oud.url(), oud.shouldEnqueue() );
}

QString DialogsProvider::clipboardMedia() const
{
    QClipboard *clipboard = QApplication::clipboard();
    assert( clipboard != NULL );
    QString txt = clipboard->text( QClipboard::Selection ).trimmed();

    if( txt.isEmpty() || ( !txt.contains("://") && !QFile::exists(txt) ) )
        txt = clipboard->text( QClipboard::Clipboard ).trimmed();

    if( txt.contains( "://" ) || QFile::exists( txt ) )
        return txt;
    return {};
}

void DialogsProvider::openUrl( const QString& text, bool enqueue )
{
    QString url = text.trimmed();
    if( url.isEmpty() )
        return;

    char *uri;
    if( !url.contains( qfu( "://" ) ) )
    {
        uri = vlc_path2uri( qtu( url ), NULL );
    } else {
        uri = vlc_uri_fixup( qtu( url ) );
    }

    if( uri == NULL )
        return;
    url = qfu(uri);
    free( uri );

    QVector<vlc::playlist::Media> medias = { {url, QString {}} };
    THEMPL->append(medias, !enqueue);
}

/* Directory */
/**
 * Open a directory,
 * pl helps you to choose from playlist or media library,
 * go to start or enqueue
 **/
static void openDirectory( qt_intf_t *p_intf, bool go )
{
    QString uri = DialogsProvider::getDirectoryDialog( p_intf );
    if( !uri.isEmpty() )
    {
        QVector<vlc::playlist::Media> medias = { {uri, QString {}} };
        THEMPL->append(medias, go);
    }
}

QString DialogsProvider::getDirectoryDialog( qt_intf_t *p_intf )
{
    const QStringList schemes = QStringList(QStringLiteral("file"));
    QUrl dirurl = QFileDialog::getExistingDirectoryUrl( NULL,
            qfut( I_OP_DIR_WINTITLE ), p_intf->p_mi->getDialogFilePath(),
            QFileDialog::ShowDirsOnly, schemes );

    if( dirurl.isEmpty() ) return QString();

    p_intf->p_mi->setDialogFilePath(dirurl);

    QString dir = dirurl.toLocalFile();
    const char *scheme = "directory";
    if( dir.endsWith( DIR_SEP "VIDEO_TS", Qt::CaseInsensitive ) )
        scheme = "dvd";
    else if( dir.endsWith( DIR_SEP "BDMV", Qt::CaseInsensitive ) )
    {
        scheme = "bluray";
        dir.remove( "BDMV" );
    }

    char *uri = vlc_path2uri( qtu( toNativeSeparators( dir ) ), scheme );
    if( unlikely(uri == NULL) )
        return QString();

    dir = qfu( uri );
    free( uri );

    return dir;
}

void DialogsProvider::PLOpenDir()
{
    openDirectory( p_intf, true );
}

void DialogsProvider::PLAppendDir()
{
    openDirectory( p_intf, false );
}

/****************
 * Playlist     *
 ****************/
void DialogsProvider::savePlayingToPlaylist()
{
    static const struct
    {
        char filter_name[14];
        char filter_patterns[5];
        char module[12];
    } types[] = {
        { N_("XSPF playlist"), "xspf", "export-xspf", },
        { N_("M3U playlist"),  "m3u",  "export-m3u", },
        { N_("M3U8 playlist"), "m3u8", "export-m3u8", },
        { N_("HTML playlist"), "html", "export-html", },
    };

    QStringList filters;
    QString ext = getSettings()->value( "last-playlist-ext" ).toString();

    for( size_t i = 0; i < ARRAY_SIZE(types); i++ )
    {
        QString tmp = qfut( types[i].filter_name ) + " (*." + types[i].filter_patterns + ")";
        if( ext == qfu( types[i].filter_patterns ) )
            filters.insert( 0, tmp );
        else
            filters.append( tmp );
    }

    QString selected;
    QString file = getSaveFileName( NULL,
                                    qtr( "Save play queue as..." ),
                                    p_intf->p_mi->getDialogFilePath(), filters.join( ";;" ),
                                    &selected );
    const char *psz_selected_module = NULL;
    const char *psz_last_playlist_ext = NULL;

    if( file.isEmpty() )
        return;

    /* First test if the file extension is set, and different to selected filter */
    for( size_t i = 0; i < ARRAY_SIZE(types); i++)
    {
        if ( file.endsWith( QString( "." ) + qfu( types[i].filter_patterns ) ) )
        {
            psz_selected_module = types[i].module;
            psz_last_playlist_ext = types[i].filter_patterns;
            break;
        }
    }

    /* otherwise apply the selected extension */
    if ( !psz_last_playlist_ext )
    {
        for( size_t i = 0; i < ARRAY_SIZE(types); i++)
        {
            if ( selected.startsWith( qfut( types[i].filter_name ) ) )
            {
                psz_selected_module = types[i].module;
                psz_last_playlist_ext = types[i].filter_patterns;
                /* Fix file extension */
                file = file.append( QString( "." ) + qfu( psz_last_playlist_ext ) );
                break;
            }
        }
    }

    if ( psz_selected_module )
    {
        vlc_playlist_Lock( p_intf->p_playlist  );
        vlc_playlist_Export( p_intf->p_playlist,
                             qtu( toNativeSeparators( file ) ),
                             psz_selected_module );
        vlc_playlist_Unlock( p_intf->p_playlist  );
        getSettings()->setValue( "last-playlist-ext", psz_last_playlist_ext );
    }
}

/****************************************************************************
 * Sout emulation
 ****************************************************************************/

void DialogsProvider::streamingDialog( QWindow *parent,
                                       const QStringList& mrls,
                                       bool b_transcode_only,
                                       QStringList options )
{
    QStringList outputMRLs;

    /* Stream */
    // Does streaming multiple files make sense?  I suppose so, just stream one
    // after the other, but not at the moment.
    if( !b_transcode_only )
    {
        SoutDialog *s = new SoutDialog( parent, p_intf, mrls[0] );
        s->setAttribute( Qt::WA_QuitOnClose, false ); // See #4883
        if( s->exec() == QDialog::Accepted )
        {
            outputMRLs.append(s->getChain());
            delete s;
        }
        else
        {
            delete s; return;
        }
    } else {
    /* Convert */
        ConvertDialog *s = new ConvertDialog( parent, p_intf, mrls );
        s->setAttribute( Qt::WA_QuitOnClose, false ); // See #4883
        if( s->exec() == QDialog::Accepted )
        {
            /* Clear the playlist.  This is because we're going to be populating
               it */
            THEMPL->clear();
            outputMRLs = s->getMrls();
            delete s;
        }
        else
        {
            delete s; return;
        }
    }

    /* Get SoutChain(s) */
    QVector<vlc::playlist::Media> outputMedias;

    for( auto it = outputMRLs.cbegin(); it != outputMRLs.cend(); ++it )
    {
        const QString &mrl = mrls[std::distance(outputMRLs.cbegin(), it)];
        QString title = "Converting " + mrl;
        outputMedias.append(vlc::playlist::Media(mrl, title, options + (*it).split(" :")));
    }

    if( !outputMedias.empty() )
        THEMPL->append(outputMedias, true);
}

void DialogsProvider::streamingDialog(const QList<QUrl> &urls, bool b_stream )
{
    if(urls.isEmpty())
        return;

    QStringList _urls;
    std::transform(urls.begin(),
                   urls.end(),
                   std::back_inserter(_urls),
                   [](const QUrl& url){ return url.toString(); });

    streamingDialog(nullptr, _urls, b_stream);
}

void DialogsProvider::openAndStreamingDialogs()
{
    ensureDialog(m_openDialog);
    m_openDialog->showTab( OpenDialog::OPEN_FILE_TAB, OpenDialog::OPEN_AND_STREAM );
}

void DialogsProvider::openAndTranscodingDialogs()
{
    ensureDialog(m_openDialog);
    m_openDialog->showTab( OpenDialog::OPEN_FILE_TAB, OpenDialog::OPEN_AND_SAVE );
}

void  DialogsProvider::loadMediaFile( const es_format_category_e category, const int filter , const QString &dialogTitle)
{
    input_item_t *p_item = THEMIM->getInput();
    if( !p_item ) return;

    char *path = input_item_GetURI( p_item );
    QUrl url;
    if( path )
    {
        url.setUrl( qfu(path) );
        url = url.adjusted(QUrl::RemoveFilename);
        if (url.scheme() != "file")
            url.clear();
        free(path);
    }

    QStringList qsl = showSimpleOpen( dialogTitle,
                                      filter,
                                      url );

    foreach( const QString &qsUrl, qsl )
    {

        if ( THEMIM->AddAssociatedMedia( category, qsUrl, true, true, false ) )
            msg_Warn( p_intf, "unable to load media from '%s', category(%d)", qtu( qsUrl ), category );
    }
}

void DialogsProvider::loadSubtitlesFile()
{
    loadMediaFile( SPU_ES, EXT_FILTER_SUBTITLE, qtr( "Open subtitles..." ) );
}

void DialogsProvider::loadAudioFile()
{
    loadMediaFile( AUDIO_ES, EXT_FILTER_AUDIO, qtr( "Open audio..." ) );
}

void DialogsProvider::loadVideoFile()
{
    loadMediaFile( VIDEO_ES, EXT_FILTER_VIDEO, qtr( "Open video..." ) );
}


/****************************************************************************
 * Menus
 ****************************************************************************/

void DialogsProvider::sendKey( int key )
{
     // translate from a vlc keycode into a Qt sequence
     QKeySequence kseq0( VLCKeyToString( key, true ) );

     if( !popupMenu )
     {
         // make sure at least a non visible popupmenu is available
         popupMenu.reset(VLCMenuBar::PopupMenu( p_intf, false ));
         if( unlikely( !popupMenu ) )
             return;
     }

     // test against key accelerators from the popupmenu
     QList<QAction*> actions = popupMenu->findChildren<QAction*>();
     for( int i = 0; i < actions.size(); i++ )
     {
         QAction* action = actions.at(i);
         QKeySequence kseq = action->shortcut();
         if( kseq == kseq0 )
         {
             action->trigger();
             return;
         }
     }

     // forward key to vlc core when not a key accelerator
     var_SetInteger( vlc_object_instance(p_intf), "key-pressed", key );
}


template<typename T>
void DialogsProvider::ensureDialog(std::unique_ptr<T>& dialog)
{
    if (!dialog) {
        dialog = std::make_unique<T>(p_intf);
        //install event filter to track visibility
        dialog->installEventFilter(this);
    }
}

template<typename T>
void DialogsProvider::toggleDialogVisible(std::unique_ptr<T>& dialog) {
    ensureDialog(dialog);
    dialog->toggleVisible();
}

#define DIALOG_VISIBLE_GETTER(dialog) \
    bool DialogsProvider:: dialog ## Visible() const { \
        if (!m_ ## dialog) \
            return false; \
        return m_ ## dialog->isVisible(); \
    }

ALL_DIALOG(DIALOG_VISIBLE_GETTER)
