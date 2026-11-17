/*****************************************************************************
 * Copyright (C) 2020 VLC authors and VideoLAN
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
#include "qml_menu_wrapper.hpp"
#include "menus.hpp"

#include <vlc_intf_strings.h>
#include "medialibrary/medialib.hpp"
#include "medialibrary/mlplaylistlistmodel.hpp"
#include "medialibrary/mlplaylistmodel.hpp"
#include "medialibrary/mlbookmarkmodel.hpp"
#include "network/networkdevicemodel.hpp"
#include "network/networkmediamodel.hpp"
#include "player/player_controller.hpp"
#include "playlist/playlist_controller.hpp"
#include "playlist/playlist_model.hpp"
#include "dialogs/dialogs_provider.hpp"
#include "util/colorizedsvgicon.hpp"
#include "maininterface/navigationmodel.hpp"
#include "medialibrary/mlrecentmediamodel.hpp"
#include "menus/custom_menus.hpp"
#include "util/settings_profiles.hpp"

// Qt includes
#include <QPainter>
#include <QInputDialog>
#include <QSignalMapper>
#include <QScreen>
#include <QActionGroup>
#include <QAbstractProxyModel>

namespace
{
    QIcon sortIcon(QWidget *widget, int order)
    {
        assert(order == Qt::AscendingOrder || order == Qt::DescendingOrder);

        QStyleOptionHeader headerOption;
        headerOption.initFrom(widget);
        headerOption.sortIndicator = (order == Qt::AscendingOrder)
                ? QStyleOptionHeader::SortDown
                : QStyleOptionHeader::SortUp;

        QStyle *style = qApp->style();
        int arrowsize = style->pixelMetric(QStyle::PM_HeaderMarkSize, &headerOption, widget);
        if (arrowsize <= 0)
            arrowsize = 32;

        qreal dpr = widget ? widget->devicePixelRatioF() : 1.0;
        headerOption.rect = QRect(0, 0, arrowsize, arrowsize);

        QPixmap arrow(arrowsize * dpr, arrowsize * dpr);
        arrow.setDevicePixelRatio(dpr);
        arrow.fill(Qt::transparent);

        {
            QPainter arrowPainter(&arrow);
            style->drawPrimitive(QStyle::PE_IndicatorHeaderArrow, &headerOption, &arrowPainter, widget);
        }

        return QIcon(arrow);
    }
}

void StringListMenu::addItems(QMenu *menu, const QVariantList &items, int &index)
{
    for (const QVariant &entry : items)
    {
        // plain string: simple action
        if (entry.typeId() != QMetaType::QVariantMap)
        {
            const QString str = entry.toString();
            menu->addAction(str, this, [this, i = index, str]() { emit selected(i, str); });
            ++index;
            continue;
        }

        const QVariantMap item = entry.toMap();
        if (item.value("separator").toBool())
        {
            menu->addSeparator();
            continue;
        }

        const QString str = item.value("text").toString();
        const QString icon = item.value("icon").toString();
        const QVariantList children = item.value("children").toList();
        if (!children.isEmpty())
        {
            QMenu *submenu = menu->addMenu(str);
            if (!icon.isEmpty())
                submenu->menuAction()->setIcon(QIcon(QStringLiteral(":/menu/figma/%1.svg").arg(icon)));
            addItems(submenu, children, index);
            continue;
        }

        QAction *action = menu->addAction(str, this, [this, i = index, str]() { emit selected(i, str); });
        if (!icon.isEmpty())
            action->setIcon(QIcon(QStringLiteral(":/menu/figma/%1.svg").arg(icon)));
        if (item.contains("checked"))
        {
            action->setCheckable(true);
            action->setChecked(item.value("checked").toBool());
        }
        if (item.contains("enabled"))
            action->setEnabled(item.value("enabled").toBool());
        ++index;
    }
}

void StringListMenu::popup(const QPoint &point, const QVariantList &stringList)
{
    assert(m_ctx);
    QMenu *m = newMenu();

    int index = 0;
    addItems(m, stringList, index);

    m->popup(point);
}

QMenu *BasicMenuContainer::newMenu()
{
    QMenu *m = new VLCMenu(m_ctx->getIntf());
    m->setAttribute(Qt::WA_DeleteOnClose);
    if (m_prevMenu)
    {
        setVisible(false);
        m_prevMenu->disconnect(this);
    }

    m_prevMenu = m;
    connect(m, &QMenu::aboutToShow, this, [this](){ setVisible(true);});
    connect(m, &QMenu::aboutToHide, this, [this](){ setVisible(false);});
    return m;
}

void BasicMenuContainer::setVisible(bool visible)
{
    if (m_visible == visible) return;

    m_visible = visible;
    emit visibleChanged();
}

// SortMenu

void SortMenu::popup(const QPoint &point, const bool popupAbovePoint, const QVariantList &model)
{
    assert(m_ctx);
    m_menu = std::make_unique<VLCMenu>(m_ctx->getIntf());

    connect( m_menu.get(), &QMenu::aboutToShow, this, [this]() {
        m_shown = true;
        shownChanged();
    } );
    connect( m_menu.get(), &QMenu::aboutToHide, this, [this]() {
        m_shown = false;
        shownChanged();
    } );

    const auto actionGroup = new QActionGroup(m_menu.get());
    actionGroup->setExclusive(true);

    // model => [{text: "", checked: <bool>, order: <sort order> if checked else <invalid>}...]
    for (int i = 0; i != model.size(); ++i)
    {
        const auto obj = model[i].toMap();

        auto action = m_menu->addAction(obj.value("text").toString());
        action->setActionGroup(actionGroup);
        action->setCheckable(true);

        const bool checked = obj.value("checked").toBool();
        action->setChecked(checked);

        // without an order, the check mark alone shows the current sort
        if (checked && obj.contains("order"))
            action->setIcon(sortIcon(m_menu.get(), obj.value("order").toInt()));

        connect(action, &QAction::triggered, this, [this, i]()
        {
            emit selected(i);
        });
    }

    onPopup(m_menu.get());

    if (popupAbovePoint)
        m_menu->popup(QPoint(point.x(), point.y() - m_menu->sizeHint().height()));
    else
        m_menu->popup(point);
}

void SortMenu::close()
{
    if (m_menu)
        m_menu->close();
}

// Protected functions

/* virtual */ void SortMenu::onPopup(QMenu *) {}

// SortMenuVideo

// Protected SortMenu reimplementation

void SortMenuVideo::onPopup(QMenu * menu) /* override */
{
    if (!m_ctx)
        return;

    menu->addSeparator();

    struct
    {
        const char * title;

        MainCtx::Grouping grouping;
    }
    entries[] =
    {
        { N_("Do not group videos"), MainCtx::GROUPING_NONE },
        { N_("Group by name"), MainCtx::GROUPING_NAME },
        { N_("Group by folder"), MainCtx::GROUPING_FOLDER },
    };

    QActionGroup * group = new QActionGroup(this);

    int index = m_ctx->grouping();

    for (size_t i = 0; i < ARRAY_SIZE(entries); i++)
    {
        QAction * action = menu->addAction(qtr(entries[i].title));

        action->setCheckable(true);

        MainCtx::Grouping grouping = entries[i].grouping;

        connect(action, &QAction::triggered, this, [this, grouping]()
        {
            emit this->grouping(grouping);
        });

        group->addAction(action);

        if (index == grouping)
            action->setChecked(true);
    }
}

void SortMenuAlbums::onPopup(QMenu *menu)
{
    if (!m_sectionsVisible)
        return;

    assert(m_ctx);
    assert(menu);

    menu->addSeparator();

    QAction *action = menu->addAction(qtr("Album sections"));
    action->setCheckable(true);
    action->setChecked(m_ctx->albumSections());
    connect(action, &QAction::toggled, this, [this] (bool enabled) {
        if (Q_LIKELY(m_ctx))
            m_ctx->setAlbumSections(enabled);
    });
}

QmlGlobalMenu::QmlGlobalMenu(QObject *parent)
    : VLCMenuBar(parent)
{
}

void QmlGlobalMenu::popup(QPoint pos)
{
    if (!m_ctx)
        return;

    qt_intf_t* p_intf = m_ctx->getIntf();
    if (!p_intf)
        return;

    m_menu = std::make_unique<VLCMenu>(m_ctx->getIntf());
    QMenu* submenu;

    connect( m_menu.get(), &QMenu::aboutToShow, this, [this]() {
        m_shown = true;
        shownChanged();
        aboutToShow();
    });
    connect( m_menu.get(), &QMenu::aboutToHide, this, [this]() {
        m_shown = false;
        shownChanged();
        aboutToHide();
    });

    /* Laid out like the main menu of the VLC Redesign Figma file; VLC's
     * classic menus follow at the end */
    const auto icon = [](const char *name) {
        return QIcon(QStringLiteral(":/menu/figma/%1.svg").arg(QLatin1String(name)));
    };
    const auto withKey = [](const QString &text, const char *key) -> QString {
        return text + '\t' + QString::fromLatin1(key);
    };
    QMenu *menu = m_menu.get();
    QAction *action;

    menu->addAction(icon("main_open_file_s"), withKey(qtr("Open File(s)"), "Ctrl + O"),
                    []() { THEDP->simpleOpenDialog(); });
    menu->addAction(icon("main_open_folder"), withKey(qtr("Open Folder"), "Ctrl + F"),
                    THEDP, &DialogsProvider::PLOpenDir);
    menu->addAction(icon("main_open_network_stream"), withKey(qtr("Open Network Stream"), "Ctrl + N"),
                    THEDP, &DialogsProvider::openNetDialog);
    menu->addAction(icon("main_open_disc"), withKey(qtr("Open Disc"), "Ctrl + D"),
                    THEDP, &DialogsProvider::openDiscDialog);
    menu->addAction(icon("main_open_capture_device"), withKey(qtr("Open Capture Device"), "Ctrl + C"),
                    THEDP, &DialogsProvider::openCaptureDialog);
    menu->addAction(icon("main_convert"), withKey(qtr("Convert"), "Ctrl + R"),
                    THEDP, &DialogsProvider::openAndTranscodingDialogs);

    MainCtx *mi = p_intf->p_mi;
    if (mi && var_InheritBool(p_intf, "save-recentplay") && mi->hasMediaLibrary())
    {
        MLRecentMediaModel* recentModel = new MLRecentMediaModel(nullptr);
        recentModel->setMl(mi->getMediaLibrary());
        recentModel->setLimit(10);
        QMenu* recentsMenu = new RecentMenu(recentModel, mi->getMediaLibrary(), menu);
        recentModel->setParent(recentsMenu);
        recentsMenu->setTitle(qtr("Open Recent"));
        recentsMenu->menuAction()->setIcon(icon("main_open_recent"));
        menu->addMenu(recentsMenu);
    }

    menu->addSeparator();

    /* settings profiles */
    const QString current = SettingsProfiles::current(p_intf);
    submenu = menu->addMenu(icon("main_profile"), qtr("Profile (%1)").arg(current));
    auto group = new QActionGroup(submenu);
    for (const QString &name : SettingsProfiles::names(p_intf))
    {
        action = submenu->addAction(name, [p_intf, name]() {
            SettingsProfiles::switchTo(p_intf, name);
        });
        action->setCheckable(true);
        action->setChecked(name == current);
        action->setActionGroup(group);
    }
    submenu->addAction(icon("main_new"), qtr("New"), [p_intf]() {
        bool ok = false;
        const QString name = QInputDialog::getText(nullptr, qtr("New Profile"),
                                                   qtr("Name of the new settings profile:"),
                                                   QLineEdit::Normal, {}, &ok);
        if (ok)
            SettingsProfiles::create(p_intf, name.trimmed());
    });

    menu->addAction(icon("main_keyboard_shortcuts"), qtr("Keyboard Shortcuts"),
                    THEDP, &DialogsProvider::keyboardShortcutsDialog);
    menu->addAction(icon("main_customize_player"), qtr("Customize Player"),
                    THEDP, &DialogsProvider::customizePlayerDialog);
    menu->addAction(icon("main_settings"), withKey(qtr("Settings"), "Ctrl + P"),
                    THEDP, &DialogsProvider::settingsDialog);
    menu->addAction(icon("main_about_vlc"), withKey(qtr("About VLC Gold"), "Shift + F1"),
                    THEDP, &DialogsProvider::aboutDialog);

    menu->addSeparator();

    /* VLC's Browse (files, network shares, devices) and Discover (services)
     * pages: not in the side navigation of the design */
    menu->addAction(icon("main_open_folder"), qtr("Browse Files and Network"), this, [this]() {
        emit pageRequested({ QStringLiteral("network") });
    });
    menu->addAction(icon("main_open_network_stream"), qtr("Discover"), this, [this]() {
        emit pageRequested({ QStringLiteral("discover") });
    });

    menu->addSeparator();

    /* VLC's classic menus */
    QList<QMenu *> classicMenus;

    submenu = menu->addMenu(icon("player_open_media"), qtr( "&Media" ));
    FileMenu( p_intf, submenu );
    classicMenus.append(submenu);

    /* Playback, Audio, Video and Subtitle are in the player's right-click
     * menu and its settings panel */

    submenu = menu->addMenu(icon("player_more_settings"), qtr( "Tool&s" ));
    ToolsMenu( p_intf, submenu );
    classicMenus.append(submenu);

    submenu = menu->addMenu(icon("view_grid_view"), qtr( "V&iew" ));
    ViewMenu( p_intf, submenu );
    classicMenus.append(submenu);

    submenu = menu->addMenu(icon("folder_info"), qtr( "&Help" ));
    HelpMenu( p_intf, submenu );
    classicMenus.append(submenu);

    /* leave out what the main menu above already has */
    const auto plain = [](QString text) {
        text = text.section('\t', 0, 0);
        text.remove('&');
        if (text.endsWith(QLatin1String("...")))
            text.chop(3);
        return text.trimmed();
    };
    const QStringList duplicates = {
        plain(qtr("Open &File...")), plain(qtr("&Open Multiple Files...")),
        plain(qfut(I_OP_OPDIR)), plain(qtr("Open &Disc...")),
        plain(qtr("Open &Network Stream...")), plain(qtr("Open &Capture Device...")),
        plain(qtr("Open &Recent Media")), plain(qtr("Conve&rt / Save...")),
        plain(qtr("Customi&ze Interface...")), plain(qtr("&Preferences")),
        plain(qfut(I_MENU_ABOUT)),
    };
    for (QMenu *classic : classicMenus)
    {
        for (QAction *item : classic->actions())
        {
            if (!item->isSeparator() && duplicates.contains(plain(item->text())))
                classic->removeAction(item);
        }
        // no separator left at the top, at the end or twice in a row
        QAction *previous = nullptr;
        for (QAction *item : classic->actions())
        {
            if (item->isSeparator() && (!previous || previous->isSeparator()))
                classic->removeAction(item);
            else
                previous = item;
        }
        if (previous && previous->isSeparator())
            classic->removeAction(previous);
    }

    m_menu->popup(pos);
}

void QmlGlobalMenu::close()
{
    if (m_menu)
        m_menu->close();
}

QmlMenuBarMenu::QmlMenuBarMenu(QmlMenuBar* menubar, QWidget* parent)
    : QMenu(parent)
    , m_menubar(menubar)
{}

QmlMenuBarMenu::~QmlMenuBarMenu()
{
}

void QmlMenuBarMenu::mouseMoveEvent(QMouseEvent* mouseEvent)
{
    QPoint globalPos =m_menubar-> m_menu->mapToGlobal(mouseEvent->pos());
    if (m_menubar->getmenubar()->contains(m_menubar->getmenubar()->mapFromGlobal(globalPos))
        && !m_menubar->m_button->contains(m_menubar->m_button->mapFromGlobal(globalPos)))
    {
        m_menubar->setopenMenuOnHover(true);
        close();
        return;
    }
    QMenu::mouseMoveEvent(mouseEvent);
}

void QmlMenuBarMenu::keyPressEvent(QKeyEvent * event)
{
    QMenu::keyPressEvent(event);
    if (!event->isAccepted()
        && (event->key() == Qt::Key_Left  || event->key() == Qt::Key_Right))
    {
        event->accept();
        emit m_menubar->navigateMenu(event->key() == Qt::Key_Left ? -1 : 1);
    }
}

void QmlMenuBarMenu::keyReleaseEvent(QKeyEvent * event)
{
    QMenu::keyReleaseEvent(event);
}

QmlMenuBar::QmlMenuBar(QObject *parent)
    : VLCMenuBar(parent)
{
}

 QString QmlMenuBar::menuEntryTitle(MenuEntry entry)
{
    switch (entry)
    {
    case MEDIA:
        return qtr("&Media");
    case PLAYBACK:
        return qtr("&Playback");
    case VIDEO:
        return qtr("&Video");
    case AUDIO:
        return qtr("&Audio");
    case SUBTITLE:
        return qtr("&Subtitle");
    case TOOL:
        return qtr("&Tools");
    case VIEW:
        return qtr("V&iew");
    case HELP:
        return qtr("&Help");
    }
    vlc_assert_unreachable();
    return "";
}

void QmlMenuBar::popupMenuCommon( QQuickItem* button, std::function<void(QMenu*)> createMenuFunc)
{
    if (!m_ctx || !m_menubar || !button)
        return;

    qt_intf_t* p_intf = m_ctx->getIntf();
    if (!p_intf)
        return;

    m_menu = std::make_unique<QmlMenuBarMenu>(this);
    createMenuFunc(m_menu.get());
    m_button = button;
    m_openMenuOnHover = false;
    connect(m_menu.get(), &QMenu::aboutToHide, this, &QmlMenuBar::onMenuClosed);
    QPointF position = button->mapToGlobal(QPoint(0, button->height()));
    m_menu->popup(position.toPoint());
}


void QmlMenuBar::setupMenuEntry(QMenu* menu, MenuEntry entry)
{
    qt_intf_t* p_intf = m_ctx->getIntf();
    switch (entry) {
    case MEDIA:
        FileMenu(p_intf, menu);
        break;
    case PLAYBACK:
        NavigMenu(p_intf, menu);
        break;
    case VIDEO:
        VideoMenu(p_intf, menu);
        break;
    case AUDIO:
        AudioMenu(p_intf, menu);
        break;
    case SUBTITLE:
        SubtitleMenu(p_intf, menu);
        break;
    case TOOL:
        ToolsMenu(p_intf, menu);
        break;
    case VIEW:
        ViewMenu( p_intf, menu );
        break;
    case HELP:
        HelpMenu( p_intf, menu );
        break;
    default:
        vlc_assert_unreachable();
    };
}

void QmlMenuBar::popupMenuEntry(QQuickItem* button, MenuEntry entry)
{
    popupMenuCommon(button, [this, entry](QMenu* menu) {
        setupMenuEntry(menu, entry);
    });
}

void QmlMenuBar::popupMediaMenu( QQuickItem* button )
{
    popupMenuCommon(button, [this](QMenu* menu) {
        qt_intf_t* p_intf = m_ctx->getIntf();
        FileMenu( p_intf, menu );
    });
}

void QmlMenuBar::popupPlaybackMenu( QQuickItem* button )
{
    popupMenuCommon(button, [this](QMenu* menu) {
        NavigMenu( m_ctx->getIntf(), menu );
    });
}

void QmlMenuBar::popupAudioMenu(QQuickItem* button )
{
    popupMenuCommon(button, [this](QMenu* menu) {
        AudioMenu( m_ctx->getIntf(), menu );
    });
}

void QmlMenuBar::popupVideoMenu( QQuickItem* button )
{
    popupMenuCommon(button, [this](QMenu* menu) {
        VideoMenu( m_ctx->getIntf(), menu );
    });
}

void QmlMenuBar::popupSubtitleMenu( QQuickItem* button )
{
    popupMenuCommon(button, [this](QMenu* menu) {
        SubtitleMenu( m_ctx->getIntf(), menu );
    });
}


void QmlMenuBar::popupToolsMenu( QQuickItem* button )
{
    popupMenuCommon(button, [this](QMenu* menu) {
        ToolsMenu( m_ctx->getIntf(), menu );
    });
}

void QmlMenuBar::popupViewMenu(QQuickItem* button )
{
    popupMenuCommon(button, [this](QMenu* menu) {
        qt_intf_t* p_intf = m_ctx->getIntf();
        ViewMenu( p_intf, menu );
    });
}

void QmlMenuBar::popupHelpMenu( QQuickItem* button )
{
    popupMenuCommon(button, [this](QMenu* menu) {
        qt_intf_t* p_intf = m_ctx->getIntf();
        HelpMenu( p_intf, menu );
    });
}

void QmlMenuBar::popupExtraActionsMenu( QQuickItem* button, const QList<MenuEntry>& extraActions )
{
    popupMenuCommon(button, [this, extraActions](QMenu* menu) {
        for (auto action: extraActions) {
            QMenu* subMenu = menu->addMenu(menuEntryTitle(action));
            setupMenuEntry(subMenu, action);
        }
    });
}

void QmlMenuBar::onMenuClosed()
{
    if (!m_openMenuOnHover)
        emit menuClosed();
}

// QmlMenuPositioner

/* explicit */ QmlMenuPositioner::QmlMenuPositioner(QObject * parent) : QObject(parent) {}

// Interface

void QmlMenuPositioner::popup(QMenu * menu, const QPoint & position, bool above)
{
    menu->removeEventFilter(this);

    if (above == false)
    {
        menu->popup(position);

        return;
    }

    m_position = position;

    menu->installEventFilter(this);

    // NOTE: QMenu::height() returns an invalid height until the initial popup call.
    menu->popup(position);
}

// Public events

bool QmlMenuPositioner::eventFilter(QObject * object, QEvent * event)
{
    if (event->type() == QEvent::Resize)
    {
        QScreen * screen = QGuiApplication::screenAt(m_position);

        if (screen == nullptr)
            return QObject::eventFilter(object, event);

        QMenu * menu = static_cast<QMenu *> (object);

        int width  = menu->width();
        int height = menu->height();

        QRect geometry = screen->availableGeometry();

        int x = geometry.x();
        int y = geometry.y();

        // NOTE: We want a position within the screen boundaries.

        x = qBound(x, m_position.x(), x + geometry.width() - width);

        y = qBound(y, m_position.y() - height, y + geometry.height() - height);

        menu->move(QPoint(x, y));
    }

    return QObject::eventFilter(object, event);
}

// QmlBookmarkMenu

/* explicit */ QmlBookmarkMenu::QmlBookmarkMenu(QObject * parent)
    : QObject(parent)
{}

// Interface

/* Q_INVOKABLE */ void QmlBookmarkMenu::popup(const QPoint & position, bool above)
{
    if (m_ctx == nullptr || m_player == nullptr)
        return;

    m_menu = std::make_unique<VLCMenu>(m_ctx->getIntf());

    connect(m_menu.get(), &QMenu::aboutToHide, this, &QmlBookmarkMenu::aboutToHide);
    connect(m_menu.get(), &QMenu::aboutToShow, this, &QmlBookmarkMenu::aboutToShow);

    QAction * sectionTitles    = m_menu->addSection(qtr("Titles"));
    QAction * sectionChapters  = m_menu->addSection(qtr("Chapters"));
    QAction * sectionBookmarks = nullptr;

    if (m_ctx->hasMediaLibrary())
        sectionBookmarks = m_menu->addSection(qtr("Bookmarks"));

    // Titles

    TitleListModel * titles = m_player->getTitles();

    sectionTitles->setVisible(titles->rowCount() != 0);

    ListMenuHelper * helper = new ListMenuHelper(m_menu.get(), titles, sectionChapters, m_menu.get());

    connect(helper, &ListMenuHelper::select, [titles](int index, bool)
    {
        titles->setData(titles->index(index), true, Qt::CheckStateRole);
    });

    connect(helper, &ListMenuHelper::countChanged, [sectionTitles](int count)
    {
        // NOTE: The section should only be visible when the model has content.
        sectionTitles->setVisible(count != 0);
    });

    // Chapters

    ChapterListModel * chapters = m_player->getChapters();

    sectionChapters->setVisible(chapters->rowCount() != 0);

    helper = new ListMenuHelper(m_menu.get(), chapters, sectionBookmarks, m_menu.get());

    connect(helper, &ListMenuHelper::select, [chapters](int index, bool)
    {
        chapters->setData(chapters->index(index), true, Qt::CheckStateRole);
    });

    connect(helper, &ListMenuHelper::countChanged, [sectionChapters](int count)
    {
        // NOTE: The section should only be visible when the model has content.
        sectionChapters->setVisible(count != 0);
    });

    // Bookmarks
    if (m_ctx->hasMediaLibrary())
    {
	m_menu->addAction(qtr("&Manage"), THEDP, &DialogsProvider::bookmarksDialog )->setShortcut(QKeySequence("Ctrl+B"));
        m_menu->addSeparator();

        MLBookmarkModel * bookmarks = new MLBookmarkModel(m_menu.get());
        bookmarks->setPlayer(m_player->getPlayer());
        bookmarks->setMl(m_ctx->getMediaLibrary());

        helper = new ListMenuHelper(m_menu.get(), bookmarks, nullptr, m_menu.get());

        connect(helper, &ListMenuHelper::select, [bookmarks](int index, bool)
        {
            bookmarks->select(bookmarks->index(index, 0));
        });
    }

    m_positioner.popup(m_menu.get(), position, above);
}

void QmlBookmarkMenu::close()
{
    if (m_menu)
        m_menu->close();
}

// QmlProgramMenu

/* explicit */ QmlProgramMenu::QmlProgramMenu(QObject * parent)
    : QObject(parent)
{}

// Interface

/* Q_INVOKABLE */ void QmlProgramMenu::popup(const QPoint & position, bool above)
{
    assert(m_ctx);
    if (m_player == nullptr)
        return;

    m_menu = std::make_unique<VLCMenu>(m_ctx->getIntf());

    connect(m_menu.get(), &QMenu::aboutToHide, this, &QmlProgramMenu::aboutToHide);
    connect(m_menu.get(), &QMenu::aboutToShow, this, &QmlProgramMenu::aboutToShow);

    m_menu->addSection(qtr("Programs"));

    ProgramListModel * programs = m_player->getPrograms();

    ListMenuHelper * helper = new ListMenuHelper(m_menu.get(), programs, nullptr, m_menu.get());

    connect(helper, &ListMenuHelper::select, [programs](int index, bool)
    {
        programs->setData(programs->index(index), true, Qt::CheckStateRole);
    });

    m_positioner.popup(m_menu.get(), position, above);
}

void QmlProgramMenu::close()
{
    if (m_menu)
        m_menu->close();
}

// QmlRendererMenu

/* explicit */ QmlRendererMenu::QmlRendererMenu(QObject * parent)
    : QObject(parent)
{}

// Interface

/* Q_INVOKABLE */ void QmlRendererMenu::popup(const QPoint & position, bool above)
{
    if (m_ctx == nullptr)
        return;

    m_menu = std::make_unique<RendererMenu>(nullptr, m_ctx->getIntf(), m_ctx->getIntf()->p_mainPlayerController);

    connect(m_menu.get(), &QMenu::aboutToHide, this, &QmlRendererMenu::aboutToHide);
    connect(m_menu.get(), &QMenu::aboutToShow, this, &QmlRendererMenu::aboutToShow);

    m_positioner.popup(m_menu.get(), position, above);
}

void QmlRendererMenu::close()
{
    if (m_menu)
        m_menu->close();
}

// Tracks

// QmlTrackMenu

/* explicit */ QmlTrackMenu::QmlTrackMenu(QObject * parent) : QObject(parent) {}

// Interface

/* Q_INVOKABLE */ void QmlTrackMenu::popup(const QPoint & position)
{
    assert(m_ctx);
    m_menu = std::make_unique<VLCMenu>(m_ctx->getIntf());

    beforePopup(m_menu.get());

    m_menu->popup(position);
}

// QmlSubtitleMenu

/* explicit */ QmlSubtitleMenu::QmlSubtitleMenu(QObject * parent) : QmlTrackMenu(parent) {}

// Protected QmlTrackMenu implementation

void QmlSubtitleMenu::beforePopup(QMenu * menu) /* override */
{
    menu->addAction(qtr("Open file"), this, [this]()
    {
        emit triggered(Open);
    });

    menu->addAction(QIcon(":/menu/sync.svg"), qtr("Synchronize"), this, [this]()
    {
        emit triggered(Synchronize);
    });

    menu->addAction(ColorizedSvgIcon::colorizedIconForWidget(":/menu/download.svg", menu), qtr("Search online"), this, [this]()
    {
        emit triggered(Download);
    });

    menu->addSeparator();

    QAction * action = menu->addAction(qtr("Select multiple"), this, [this]()
    {
        TrackListModel * tracks = this->m_player->getSubtitleTracks();

        tracks->setMultiSelect(!(tracks->getMultiSelect()));
    });

    action->setCheckable(true);

    action->setChecked(m_player->getSubtitleTracks()->getMultiSelect());
}

// QmlAudioMenu

/* explicit */ QmlAudioMenu::QmlAudioMenu(QObject * parent) : QmlTrackMenu(parent) {}

// Protected QmlTrackMenu implementation

void QmlAudioMenu::beforePopup(QMenu * menu) /* override */
{
    menu->addAction(qtr("Open file"), this, [this]()
    {
        emit triggered(Open);
    });

    menu->addAction(QIcon(":/menu/sync.svg"), qtr("Synchronize"), this, [this]()
    {
        emit triggered(Synchronize);
    });
}

QmlAudioContextMenu::QmlAudioContextMenu(QObject *parent)
    : VLCMenuBar(parent)
{
}

void QmlAudioContextMenu::popup(const QPoint & position)
{
    if (!m_ctx)
        return;

    qt_intf_t* p_intf = m_ctx->getIntf();
    if (!p_intf)
        return;

    m_menu.reset(PopupMenu(p_intf, false));
    if (m_menu)
        m_menu->popup(position);
}

//=================================================================================================
// PlaylistListContextMenu
//=================================================================================================

PlaylistListContextMenu::PlaylistListContextMenu(QObject * parent)
    : BasicMenuContainer(parent)
{}


void PlaylistListContextMenu::popup(const QModelIndexList & selected, QPoint pos, QVariantMap)
{
    assert(m_ctx);

    if (!m_model)
        return;

    QVariantList ids;

    for (const QModelIndex & modelIndex : selected)
        ids.push_back(m_model->data(modelIndex, MLPlaylistListModel::PLAYLIST_ID));

    auto menu = newMenu();

    MediaLib * ml = m_model->ml();

    // Figma "playlist context menu" (items without a VLC feature yet are
    // left out), VLC's other actions at the end
    const auto figmaIcon = [](const char *name) {
        return QIcon(QStringLiteral(":/menu/figma/%1.svg").arg(QLatin1String(name)));
    };

    QAction * action = menu->addAction(figmaIcon("playlist_play"), qtr("Play"));

    connect(action, &QAction::triggered, [ml, ids]() {
        ml->addAndPlay(ids);
    });

    bool allFavorite = !selected.isEmpty();
    for (const QModelIndex & modelIndex : selected)
        allFavorite = allFavorite && m_model->data(modelIndex, MLPlaylistListModel::PLAYLIST_FAVORITE).toBool();

    action = menu->addAction(figmaIcon("playlist_favorite"), qtr("Favorite"));
    action->setCheckable(true);
    action->setChecked(allFavorite);

    connect(action, &QAction::triggered, [ml, ids, allFavorite]() {
        for (const QVariant & id : ids)
            ml->setPlaylistFavorite(id.value<MLItemId>(), !allFavorite);
    });

    action = menu->addAction(figmaIcon("playlist_shuffle"), qtr("Shuffle"));

    connect(action, &QAction::triggered, [this, ml, ids]() {
        ml->addAndPlay(ids);
        m_ctx->getIntf()->p_mainPlaylistController->setRandom(true);
    });

    QString name;
    if (ids.count() == 1)
        name = m_model->data(selected.first(), MLPlaylistListModel::PLAYLIST_NAME).toString();
    action = menu->addAction(figmaIcon("playlist_export_playlist"), qtr("Export Playlist"));

    connect(action, &QAction::triggered, [ml, ids, name]() {
        ml->exportPlaylists(ids, name.isEmpty() ? qtr("Playlist") : name);
    });

    action = menu->addAction(figmaIcon("playlist_add_to_queue"), qtr("Add to Queue"));

    connect(action, &QAction::triggered, [ml, ids]() {
        ml->addToPlaylist(ids);
    });

    const auto addTracks = [ml, ids](bool audio) {
        ml->mediaMrls(ids, [audio](QStringList mrls) {
            DialogsProvider::getInstance()->addSubtitlesDialog(QVariantMap {
                { QStringLiteral("mode"), QStringLiteral("list") },
                { QStringLiteral("kind"), audio ? QStringLiteral("audio") : QStringLiteral("subtitles") },
                { QStringLiteral("mrls"), mrls },
            });
        });
    };
    action = menu->addAction(figmaIcon("playlist_add_subtitle_tracks"), qtr("Add Subtitle Tracks"));
    connect(action, &QAction::triggered, [addTracks]() { addTracks(false); });
    action = menu->addAction(figmaIcon("playlist_add_audio_tracks"), qtr("Add Audio Tracks"));
    connect(action, &QAction::triggered, [addTracks]() { addTracks(true); });

    if (ids.count() == 1)
    {
        const QModelIndex index = selected.first();
        const QVariantMap args {
            { QStringLiteral("id"), ids.first() },
            { QStringLiteral("name"), name },
            { QStringLiteral("thumbnail"), MediaLib::playlistThumbnail(ids.first().value<MLItemId>()) },
            { QStringLiteral("count"), m_model->data(index, MLPlaylistListModel::PLAYLIST_COUNT) },
            { QStringLiteral("video"), m_model->data(index, MLPlaylistListModel::PLAYLIST_NB_VIDEO) },
            { QStringLiteral("audio"), m_model->data(index, MLPlaylistListModel::PLAYLIST_NB_AUDIO) },
            { QStringLiteral("unknown"), m_model->data(index, MLPlaylistListModel::PLAYLIST_NB_UNKNOWN) },
            { QStringLiteral("present"), m_model->data(index, MLPlaylistListModel::PLAYLIST_NB_PRESENT) },
            { QStringLiteral("duration"), m_model->data(index, MLPlaylistListModel::PLAYLIST_DURATION).value<VLCDuration>().formatLong() },
            { QStringLiteral("created"), m_model->data(index, MLPlaylistListModel::PLAYLIST_CREATION_DATE) },
            { QStringLiteral("favorite"), allFavorite },
        };
        action = menu->addAction(figmaIcon("playlist_properties_metadata"), qtr("Properties & Metadata"));
        connect(action, &QAction::triggered, [args]() {
            DialogsProvider::getInstance()->figmaDialog(QStringLiteral("playlistProperties"), args);
        });
    }

    menu->addSeparator();

    if (ids.count() == 1)
    {
        action = menu->addAction(QIcon(QStringLiteral(":/icons/figma/edit.svg")), qtr("Rename"));

        QModelIndex index = selected.first();

        connect(action, &QAction::triggered, [this, index]() {
            m_model->showDialogRename(index);
        });
    }

    action = menu->addAction(qtr("Delete"));

    connect(action, &QAction::triggered, this, &PlaylistListContextMenu::requestDeleteSelectedPlaylists);

    action = menu->addAction(figmaIcon("main_new"), qtr("New Playlist..."));
    connect(action, &QAction::triggered, this, [this]() {
        DialogsProvider::getInstance()->newPlaylistDialog();
    });

    menu->popup(pos);
}

//=================================================================================================
// PlaylistMediaContextMenu
//=================================================================================================


void PlaylistMediaContextMenu::popup(const QModelIndexList & selected, QPoint pos,
                                     QVariantMap options)
{
    assert(m_ctx);

    if (!m_model)
        return;

    QVariantList ids;

    for (const QModelIndex& modelIndex : selected)
        ids.push_back(m_model->data(modelIndex, MLPlaylistModel::MEDIA_ID));

    auto menu =newMenu();

    MediaLib * ml = m_model->ml();

    QAction * action = menu->addAction(qtr("Add and play"));

    connect(action, &QAction::triggered, [ml, ids]() {
        ml->addAndPlay(ids);
    });

    action = menu->addAction(qtr("Enqueue"));

    connect(action, &QAction::triggered, [ml, ids]() {
        ml->addToPlaylist(ids);
    });

    action = menu->addAction(qtr("Add to playlist"));

    connect(action, &QAction::triggered, [ids]() {
        DialogsProvider::getInstance()->playlistsDialog(ids);
    });

    action = menu->addAction(qtr("Play as audio"));

    connect(action, &QAction::triggered, [ml, ids]() {
        ml->addAndPlay(ids, {":no-video"});
    });

    if (options.contains("information") && options["information"].typeId() == QMetaType::Int) {
        action = menu->addAction(qtr("Information"));

        QSignalMapper * mapper = new QSignalMapper(menu);

        connect(action, &QAction::triggered, mapper, QOverload<>::of(&QSignalMapper::map));

        mapper->setMapping(action, options["information"].toInt());
        connect(mapper, &QSignalMapper::mappedInt,
                this, &PlaylistMediaContextMenu::showMediaInformation);
    }

    menu->addSeparator();

    action = menu->addAction(qtr("Remove Selected"));

    action->setIcon(QIcon(":/menu/remove.svg"));

    connect(action, &QAction::triggered, [this, selected]() {
        m_model->remove(selected);
    });

    menu->popup(pos);
}

//=================================================================================================

void NetworkMediaContextMenu::popup(const QModelIndexList& selected, QPoint pos)
{
    assert(m_ctx);

    if (!m_model)
        return;

    auto menu = newMenu();
    QAction* action;

    action = menu->addAction( qtr("Add and play") );
    connect(action, &QAction::triggered, [this, selected]( ) {
        m_model->addAndPlay(selected);
    });

    action = menu->addAction( qtr("Enqueue") );
    connect(action, &QAction::triggered, [this, selected]( ) {
        m_model->addToPlaylist(selected);
    });

    action = menu->addAction( qtr("Information") );
    connect(action, &QAction::triggered, [this, selected]( ) {
        if (selected.isEmpty()) return;

        m_model->getItemsForIndexes(selected, [](const QVariantList& items) {
            if (items.isEmpty()) return;

            QVariant firstItem = items.first();

            if (firstItem.canConvert<SharedInputItem>()) {
                 SharedInputItem sii = firstItem.value<SharedInputItem>();
                 DialogsProvider::getInstance()->mediaInfoDialog(sii);
            }
        });
    });

    bool canBeIndexed = false;
    unsigned countIndexed = 0;
    for (const QModelIndex& idx : selected)
    {
        QVariant canIndex = m_model->data(m_model->index(idx.row()), NetworkMediaModel::NETWORK_CANINDEX );
        if (canIndex.isValid() && canIndex.toBool())
            canBeIndexed = true;
        else
            continue;
        QVariant isIndexed = m_model->data(m_model->index(idx.row()), NetworkMediaModel::NETWORK_INDEXED );
        if (!isIndexed.isValid())
            continue;
        if (isIndexed.toBool())
            ++countIndexed;
    }

    if (canBeIndexed)
    {
        bool removeFromML = countIndexed > 0;
        action = menu->addAction(removeFromML
            ? qtr("Remove from Media Library")
            : qtr("Add to Media Library"));

        connect(action, &QAction::triggered, [this, selected, removeFromML]( ) {
            for (const QModelIndex& idx : selected) {
                m_model->setData(m_model->index(idx.row()), !removeFromML, NetworkMediaModel::NETWORK_INDEXED);
            }
        });
    }

    menu->popup(pos);
}

void NetworkDeviceContextMenu::popup(const QModelIndexList& selected, QPoint pos)
{
    assert(m_ctx);

    if (!m_model)
        return;

    auto menu = newMenu();
    QAction* action;

    action = menu->addAction( qtr("Add and play") );
    connect(action, &QAction::triggered, [this, selected]( ) {
        m_model->addAndPlay(selected);
    });

    action = menu->addAction( qtr("Enqueue") );
    connect(action, &QAction::triggered, [this, selected]( ) {
        m_model->addToPlaylist(selected);
    });

    action = menu->addAction( qtr("Information") );
    connect(action, &QAction::triggered, [this, selected]( ) {
        if (selected.isEmpty()) return;

        m_model->getItemsForIndexes(selected, [](const QVariantList& items) {
            if (items.isEmpty()) return;

            QVariant firstItem = items.first();

            if (firstItem.canConvert<SharedInputItem>()) {
                 SharedInputItem sii = firstItem.value<SharedInputItem>();
                 DialogsProvider::getInstance()->mediaInfoDialog(sii);
            }
        });
    });

    menu->popup(pos);
}

PlaylistContextMenu::PlaylistContextMenu(QObject* parent)
    : QObject(parent)
{}

void PlaylistContextMenu::popup(int selectedIndex, QPoint pos )
{
    assert(m_ctx);

    if (!m_controler || !m_model || !m_selectionModel)
        return;

    m_menu = std::make_unique<VLCMenu>(m_ctx->getIntf());
    QAction* action;

    QList<QUrl> selectedUrlList;
    for (const int modelIndex : m_selectionModel->selectedIndexesFlat())
        selectedUrlList.push_back(m_model->itemAt(modelIndex).getUrl());

    PlaylistItem selectedItem;
    if (selectedIndex >= 0)
        selectedItem = m_model->itemAt(selectedIndex);

    if (selectedItem)
    {
        action = m_menu->addAction( qtr("Play") );
        connect(action, &QAction::triggered, [this, selectedIndex]( ) {
            m_controler->goTo(selectedIndex, true);
        });

        m_menu->addSeparator();
    }

    if (m_controler->currentIndex() != -1)
    {
        action = m_menu->addAction( qtr("Jump to current playing"));
        connect(action, &QAction::triggered, this, &PlaylistContextMenu::jumpToCurrentPlaying);
    }

    if (m_selectionModel->hasSelection()) {
        action = m_menu->addAction( qtr("Stream") );
        connect(action, &QAction::triggered, [selectedUrlList]( ) {
            DialogsProvider::getInstance()->streamingDialog(selectedUrlList, false);
        });

        action = m_menu->addAction( qtr("Save") );
        connect(action, &QAction::triggered, [selectedUrlList]( ) {
            DialogsProvider::getInstance()->streamingDialog(selectedUrlList, true);
        });

        m_menu->addSeparator();
    }

    if (selectedItem) {
        action = m_menu->addAction( qtr("Information") );
        action->setIcon(QIcon(":/menu/info.svg"));
        connect(action, &QAction::triggered, [selectedItem]( ) {
            DialogsProvider::getInstance()->mediaInfoDialog(selectedItem);
        });

        m_menu->addSeparator();

        action = m_menu->addAction( qtr("Show Containing Directory...") );
        action->setIcon(QIcon(":/menu/folder.svg"));
        connect(action, &QAction::triggered, [this, selectedItem]( ) {
            m_controler->explore(selectedItem);
        });

        m_menu->addSeparator();
    }

    action = m_menu->addAction( qtr("Add File...") );

    action->setIcon(ColorizedSvgIcon::colorizedIconForWidget(":/menu/add.svg", m_menu.get()));
    connect(action, &QAction::triggered, []( ) {
        DialogsProvider::getInstance()->simpleOpenDialog(false);
    });

    action = m_menu->addAction( qtr("Add Directory...") );
    action->setIcon(ColorizedSvgIcon::colorizedIconForWidget(":/menu/add.svg", m_menu.get()));
    connect(action, &QAction::triggered, []( ) {
        DialogsProvider::getInstance()->PLAppendDir();
    });

    action = m_menu->addAction( qtr("Advanced Open...") );
    action->setIcon(ColorizedSvgIcon::colorizedIconForWidget(":/menu/add.svg", m_menu.get()));
    connect(action, &QAction::triggered, []( ) {
        DialogsProvider::getInstance()->PLAppendDialog();
    });

    m_menu->addSeparator();

    if (m_selectionModel->hasSelection())
    {
        action = m_menu->addAction( qtr("Save Play Queue to File...") );
        connect(action, &QAction::triggered, []( ) {
            DialogsProvider::getInstance()->savePlayingToPlaylist();
        });

        m_menu->addSeparator();

        action = m_menu->addAction( qtr("Remove Selected") );
        action->setIcon(QIcon(":/menu/remove.svg"));
        connect(action, &QAction::triggered, [this]( ) {
            m_model->removeItems(m_selectionModel->selectedIndexesFlat());
        });
    }


    if (m_model->rowCount() > 0)
    {
        action = m_menu->addAction( qtr("Clear the play queue") );
        action->setIcon(QIcon(":/menu/clear.svg"));
        connect(action, &QAction::triggered, [this]( ) {
            m_controler->clear();
        });

        m_menu->addSeparator();

        using namespace vlc::playlist;
        PlaylistController::SortKey currentKey = m_controler->getSortKey();
        PlaylistController::SortOrder currentOrder = m_controler->getSortOrder();

        QMenu* sortMenu = m_menu->addMenu(qtr("Sort by"));
        QActionGroup * group = new QActionGroup(sortMenu);

        auto addSortAction = [&](const QString& label, PlaylistController::SortKey key, PlaylistController::SortOrder order) {
            QAction* action = sortMenu->addAction(label);
            connect(action, &QAction::triggered, this, [this, key, order]( ) {
                m_controler->sort(key, order);
            });
            action->setCheckable(true);
            action->setActionGroup(group);
            if (key == currentKey && currentOrder == order)
                action->setChecked(true);
        };

        for (const QVariant& it: m_controler->getSortKeyTitleList())
        {
            const QVariantMap varmap = it.toMap();

            auto key = static_cast<PlaylistController::SortKey>(varmap.value("key").toInt());
            QString label = varmap.value("text").toString();

            addSortAction(qtr("%1 Ascending").arg(label), key, PlaylistController::SORT_ORDER_ASC);
            addSortAction(qtr("%1 Descending").arg(label), key, PlaylistController::SORT_ORDER_DESC);
        }

        action = m_menu->addAction( qtr("Shuffle the play queue") );
        action->setIcon(ColorizedSvgIcon::colorizedIconForWidget(":/menu/ic_fluent_arrow_shuffle.svg", m_menu.get()));
        connect(action, &QAction::triggered, this, [this]( ) {
            m_controler->shuffle();
        });

        if (m_proxyModel)
        {
            if (m_proxyModel->rowCount() != m_model->rowCount())
            {
                m_menu->addSeparator();

                // Actions that are available when the view uses a proxy model:

                action = m_menu->addAction( qtr("Discard the filtered out items"));
                connect(action, &QAction::triggered, [this]( ) {
                    bool proceed = true;

                    if (const auto dp = DialogsProvider::getInstance())
                    {
                        proceed = dp->questionDialog(qtr("Do you really want to discard the items that are not displayed at the moment?"),
                                                     qtr("Discard the filtered out items"));
                    }

                    const auto count = m_model->rowCount() - m_proxyModel->rowCount();

                    if (proceed && (count > 0))
                    {
                        QList<int> items;
                        items.reserve(count);

                        for (int i = 0; i < m_model->rowCount(); ++i)
                        {
                            const auto mappedIndex = m_proxyModel->mapFromSource(m_model->index(i, 0));

                            if (!mappedIndex.isValid() || !(m_proxyModel->checkIndex(mappedIndex, QAbstractItemModel::CheckIndexOption::IndexIsValid)))
                            {
                                items.push_back(i);
                            }
                        }

                        if (items.count() > 0)
                        {
                            m_model->removeItems(items);
                            emit discardedFilteredOutItems();
                        }
                    }
                });
            }
        }
    }

    m_menu->popup(pos);
}

NavigationBarContextMenu::NavigationBarContextMenu(QObject *parent)
    : BasicMenuContainer(parent)
{

}

void NavigationBarContextMenu::popup(int index, const QPoint& pos, bool setFirstActionAsActive)
{
    assert(m_ctx);
    assert(m_model);

    QMenu *menu = newMenu();
    assert(menu);

    const auto modelIndex = m_model->index(index, 0);
    assert(modelIndex.isValid());

    const auto children = m_model->data(modelIndex, NavigationModel::CHILDREN).value<QList<NavigationModelItem>>();

    if (children.count() <= 0)
    {
        emit pageRequested(m_model->data(modelIndex, NavigationModel::URI).toStringList());
        return;
    }

    populateMenuForChildren(menu, children, setFirstActionAsActive);

    menu->popup(pos);
}

void NavigationBarContextMenu::popup(const QPoint &pos, bool setFirstActionAsActive)
{
    assert(m_ctx);
    assert(m_model);

    QMenu *menu = newMenu();
    assert(menu);

    bool activeActionSet = !setFirstActionAsActive;
    bool menuAdded = false;

    for (int i = 0; i < m_model->rowCount(); ++i)
    {
        const auto modelIndex = m_model->index(i, 0);
        assert(modelIndex.isValid());

        const auto menuTitle = m_model->data(modelIndex, NavigationModel::TITLE).toString();
        const auto menuUri = m_model->data(modelIndex, NavigationModel::URI).toStringList();
        const auto menuIcon = m_model->data(modelIndex, NavigationModel::ICON_SVG).toString();
        const auto menuExpandable = m_model->data(modelIndex, NavigationModel::EXPANDABLE).toBool();
        const auto menuChildren = m_model->data(modelIndex, NavigationModel::CHILDREN).value<QList<NavigationModelItem>>();
        const auto menuDepth = m_model->data(modelIndex, NavigationModel::DEPTH).toInt();

        // We currently do not care about deeper levels:
        if (menuDepth != 0)
            continue;

        if (menuExpandable && menuChildren.size() > 0)
        {
            const auto subMenu = menu->addMenu(menuTitle);

            if (menuIcon.length() > 0)
                subMenu->setIcon(ColorizedSvgIcon::colorizedIconForWidget(menuIcon, subMenu));

            populateMenuForChildren(subMenu, menuChildren, setFirstActionAsActive);

            menuAdded = true;
        }
        else
        {
            const auto action = menu->addAction(menuTitle, [this, menuUri]() {
                emit pageRequested(menuUri);
            });

            if (menuIcon.length() > 0)
                action->setIcon(ColorizedSvgIcon::colorizedIconForWidget(menuIcon, qobject_cast<QWidget*>(menu)));

            if (!activeActionSet && !menuAdded)
            {
                menu->setActiveAction(action);
                activeActionSet = true;
            }
        }
    }

    menu->popup(pos);
}

void NavigationBarContextMenu::populateMenuForChildren(QMenu *menu, const QList<NavigationModelItem> &children, bool setFirstActionAsActive)
{
    assert(m_ctx);
    assert(m_model);
    assert(menu);

    bool activeActionSet = !setFirstActionAsActive;

    for (const auto& child : children)
    {
        const auto childTitle = child.name();
        assert(childTitle.length() > 0);
        const auto childUri = child.uri();
        assert(childUri.length() > 0);
        const auto childIcon = child.icon_svg();

        const auto action = menu->addAction(childTitle, [this, uri = childUri]() {
            emit pageRequested(uri);
        });

        if (childIcon.length() > 0)
            action->setIcon(ColorizedSvgIcon::colorizedIconForWidget(childIcon, qobject_cast<QWidget*>(menu)));

        if (!activeActionSet)
        {
            menu->setActiveAction(action);
            activeActionSet = true;
        }
    }
}
