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
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "messagesmodel.hpp"
#include "dialogs/dialogs_provider.hpp"

#include <QClipboard>
#include <QFile>
#include <QGuiApplication>
#include <QMutexLocker>
#include <QTextStream>
#include <QUrl>

#include <vlc_common.h>
#include <vlc_playlist.h>
#include <vlc_interface.h>
#include <vlc_input_item.h>

#include <cstdarg>

MessagesModel::MessagesModel(QObject* parent)
    : QAbstractListModel(parent)
{
}

MessagesModel::~MessagesModel()
{
    if (m_logging)
        vlc_LogSet(vlc_object_instance(p_intf), nullptr, nullptr);
}

void MessagesModel::setCtx(MainCtx* ctx)
{
    if (m_ctx == ctx || !ctx || m_ctx)
        return;
    m_ctx = ctx;
    p_intf = ctx->getIntf();

    const int verbosity = var_InheritInteger(p_intf, "verbose");
    m_verbosity = verbosity;
    m_filter = getSettings()->value("Messages/messages-filter").toString();

    /* Hook up to LibVLC messaging, as the classic dialog */
    static const struct vlc_logger_operations log_ops =
    {
        MessagesModel::logCallback,
        nullptr
    };
    vlc_LogSet(vlc_object_instance(p_intf), &log_ops, this);
    m_logging = true;

    emit ctxChanged();
    emit verbosityChanged();
    emit filterChanged();
}

int MessagesModel::getVerbosity() const
{
    return qBound(0, m_verbosity.load(), 2);
}

void MessagesModel::setVerbosity(int verbosity)
{
    if (verbosity == m_verbosity.load())
        return;
    m_verbosity = verbosity;
    emit verbosityChanged();
}

void MessagesModel::setFilter(const QString& filter)
{
    if (filter == m_filter)
        return;
    m_filter = filter;
    if (p_intf)
        getSettings()->setValue("Messages/messages-filter", filter);
    rebuild();
    emit filterChanged();
}

bool MessagesModel::isDebugBuild() const
{
#ifndef NDEBUG
    return true;
#else
    return false;
#endif
}

void MessagesModel::logCallback(void* self, int type, const vlc_log_t* item,
                                const char* format, va_list ap)
{
    auto that = static_cast<MessagesModel*>(self);
    const int verbosity = that->m_verbosity.load();
    if (verbosity < 0 || verbosity < (type - VLC_MSG_ERR))
        return;

    char* str;
    if (unlikely(vasprintf(&str, format, ap) == -1))
        return;

    int canc = vlc_savecancel();
    bool first;
    {
        QMutexLocker locker(&that->m_pendingLock);
        first = that->m_pending.isEmpty();
        that->m_pending.push_back({ type, qfu(item->psz_module), qfu(str) });
    }
    if (first)
        QMetaObject::invokeMethod(that, "flush", Qt::QueuedConnection);
    vlc_restorecancel(canc);
    free(str);
}

void MessagesModel::flush()
{
    QVector<Line> lines;
    {
        QMutexLocker locker(&m_pendingLock);
        lines.swap(m_pending);
    }
    if (lines.isEmpty())
        return;

    QVector<int> added;
    for (const Line& line : lines)
    {
        m_lines.push_back(line);
        if (matches(line))
            added.push_back(m_lines.size() - 1);
    }
    if (added.isEmpty())
        return;
    beginInsertRows({}, m_rows.size(), m_rows.size() + added.size() - 1);
    m_rows += added;
    endInsertRows();
    emit appended();
}

static QString typeName(int type)
{
    switch (type)
    {
    case VLC_MSG_INFO: return QStringLiteral("info");
    case VLC_MSG_ERR:  return QStringLiteral("error");
    case VLC_MSG_WARN: return QStringLiteral("warning");
    case VLC_MSG_DBG:
    default:           return QStringLiteral("debug");
    }
}

QString MessagesModel::lineText(const Line& line) const
{
    return line.module + " " + typeName(line.type) + ": " + line.text;
}

bool MessagesModel::matches(const Line& line) const
{
    return m_filter.isEmpty()
        || lineText(line).contains(m_filter, Qt::CaseInsensitive);
}

void MessagesModel::rebuild()
{
    beginResetModel();
    m_rows.clear();
    for (int i = 0; i < m_lines.size(); ++i)
        if (matches(m_lines[i]))
            m_rows.push_back(i);
    endResetModel();
}

int MessagesModel::rowCount(const QModelIndex& parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QVariant MessagesModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() >= m_rows.size())
        return {};
    const Line& line = m_lines[m_rows[index.row()]];
    switch (role)
    {
    case ModuleRole: return line.module;
    case TypeRole:   return typeName(line.type);
    case TextRole:   return line.text;
    case Qt::DisplayRole:
    case LineRole:   return lineText(line);
    default:         return {};
    }
}

QHash<int, QByteArray> MessagesModel::roleNames() const
{
    return {
        { ModuleRole, "module" },
        { TypeRole, "type" },
        { TextRole, "text" },
        { LineRole, "line" }
    };
}

void MessagesModel::clear()
{
    beginResetModel();
    m_lines.clear();
    m_rows.clear();
    endResetModel();
}

QString MessagesModel::save()
{
    const QString fileName = DialogsProvider::getSaveFileName(
            nullptr, qtr( "Save log file as..." ),
            QUrl::fromLocalFile( QVLCUserDir( VLC_DOCUMENTS_DIR ) ),
            qtr( "Texts/Logs (*.log *.txt);; All (*.*)" ) );
    if (fileName.isEmpty())
        return {};

    QFile file(fileName);
    if (!file.open(QFile::WriteOnly | QFile::Text))
        return qtr( "Cannot write to file %1:\n%2." ).arg( fileName ).arg( file.errorString() );

    QTextStream out(&file);
    for (int row : m_rows)
        out << lineText(m_lines[row]) << "\n";
    return {};
}

void MessagesModel::copyRows(const QList<int>& rows) const
{
    QList<int> sorted = rows;
    std::sort(sorted.begin(), sorted.end());
    QStringList text;
    for (int row : sorted)
        if (row >= 0 && row < m_rows.size())
            text << lineText(m_lines[m_rows[row]]);
    if (!text.isEmpty())
        QGuiApplication::clipboard()->setText(text.join('\n'));
}

void MessagesModel::buildTree(QVariantList& out, vlc_object_t* obj, int depth) const
{
    char* name = vlc_object_get_name(obj);
    out.append(QVariantMap {
        { "text", QString("%1%2 (0x%3)")
                      .arg( qfu( vlc_object_typename(obj) ) )
                      .arg( ( name != nullptr ) ? QString( " \"%1\"" ).arg( qfu( name ) ) : "" )
                      .arg( (uintptr_t)obj, 0, 16 ) },
        { "depth", depth }
    });
    free(name);

    size_t count = 0, size;
    vlc_object_t** tab = nullptr;
    do
    {
        delete[] tab;
        size = count;
        tab = new vlc_object_t*[size];
        count = vlc_list_children(obj, tab, size);
    }
    while (size < count);

    for (size_t i = 0; i < count; i++)
    {
        buildTree(out, tab[i], depth + 1);
        vlc_object_release(tab[i]);
    }
    delete[] tab;
}

QVariantList MessagesModel::objectTree() const
{
    QVariantList out;
    if (p_intf)
        buildTree(out, VLC_OBJECT(vlc_object_instance(p_intf)), 0);
    return out;
}

QVariantList MessagesModel::playlistTree() const
{
    QVariantList out;
#ifndef NDEBUG
    if (!p_intf)
        return out;
    vlc_playlist_t* playlist = p_intf->p_playlist;
    vlc_playlist_Lock(playlist);
    const size_t count = vlc_playlist_Count(playlist);
    for (size_t i = 0; i < count; i++)
    {
        vlc_playlist_item_t* item = vlc_playlist_Get(playlist, i);
        input_item_t* media = vlc_playlist_item_GetMedia(item);
        out.append(QVariantMap {
            { "name", qfu(media->psz_name) },
            { "uri", qfu(media->psz_uri) },
            { "index", QString::number(i) },
            { "item", QString::number((uintptr_t)media) },
            { "type", QString("0x%1").arg(media->i_type, 0, 16) }
        });
    }
    vlc_playlist_Unlock(playlist);
#endif
    return out;
}
