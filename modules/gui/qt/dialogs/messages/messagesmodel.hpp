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
#ifndef VLC_QT_MESSAGESMODEL_HPP
#define VLC_QT_MESSAGESMODEL_HPP

#include <QAbstractListModel>
#include <QMutex>
#include <QPointer>
#include <QVariant>
#include <QVector>

#include <atomic>

#include "qt.hpp"
#include "maininterface/mainctx.hpp"

/**
 * The log of the Messages window of the redesign (MessagesWindow.qml), as
 * the classic dialog (messages.cpp): receives VLC's messages once created
 * (vlc_LogSet), up to the chosen verbosity; the rows match the filter.
 * Also the modules tree and (debug builds) the playlist tree.
 */
class MessagesModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(MainCtx* ctx READ getCtx WRITE setCtx NOTIFY ctxChanged FINAL)
    // 0 errors, 1 warnings, 2 debug (as the classic spin box)
    Q_PROPERTY(int verbosity READ getVerbosity WRITE setVerbosity NOTIFY verbosityChanged FINAL)
    Q_PROPERTY(QString filter READ getFilter WRITE setFilter NOTIFY filterChanged FINAL)
    Q_PROPERTY(bool debugBuild READ isDebugBuild CONSTANT FINAL)

public:
    enum Roles {
        ModuleRole = Qt::UserRole + 1,
        // "info", "error", "warning", "debug"
        TypeRole,
        TextRole,
        // the whole line, as saved
        LineRole
    };

    explicit MessagesModel(QObject* parent = nullptr);
    ~MessagesModel() override;

    MainCtx* getCtx() const { return m_ctx; }
    void setCtx(MainCtx* ctx);

    int getVerbosity() const;
    void setVerbosity(int verbosity);

    QString getFilter() const { return m_filter; }
    void setFilter(const QString& filter);

    bool isDebugBuild() const;

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void clear();
    // asks for a file and writes the shown lines; "" or the error
    Q_INVOKABLE QString save();
    // the given rows as text, copied to the clipboard
    Q_INVOKABLE void copyRows(const QList<int>& rows) const;
    // { text, depth } of the VLC objects, from libvlc
    Q_INVOKABLE QVariantList objectTree() const;
    // { name, uri, index, item, type } of the queue (debug builds)
    Q_INVOKABLE QVariantList playlistTree() const;

signals:
    void ctxChanged();
    void verbosityChanged();
    void filterChanged();
    // lines were added at the end
    void appended();

private:
    struct Line {
        int type;
        QString module;
        QString text;
    };

    static void logCallback(void* self, int type, const vlc_log_t* item,
                            const char* format, va_list ap);
    Q_INVOKABLE void flush();
    bool matches(const Line& line) const;
    QString lineText(const Line& line) const;
    void rebuild();
    void buildTree(QVariantList& out, vlc_object_t* obj, int depth) const;

    QPointer<MainCtx> m_ctx;
    qt_intf_t* p_intf = nullptr;
    bool m_logging = false;

    std::atomic<int> m_verbosity { 2 };
    QString m_filter;

    QVector<Line> m_lines;
    // indexes in m_lines of the rows that match the filter
    QVector<int> m_rows;

    QMutex m_pendingLock;
    QVector<Line> m_pending;
};

#endif
