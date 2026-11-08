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
#ifndef VLC_QT_EPGMODEL_HPP
#define VLC_QT_EPGMODEL_HPP

#include <QObject>
#include <QPointer>
#include <QSet>
#include <QTimer>
#include <QVariant>

#include "qt.hpp"
#include "maininterface/mainctx.hpp"

/**
 * The program guide of the playing media for the redesign's Program Guide
 * window (EpgWindow.qml), as the classic EPG dialog (dialogs/epg): the
 * programs (channels) with their events, refreshed 5 seconds after the
 * player reports a change.
 */
class EpgModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(MainCtx* ctx READ getCtx WRITE setCtx NOTIFY ctxChanged FINAL)
    // [{ id, name, events: [{ start, duration, name, description, rating,
    //    items: [{ key, value }], current }] }], times in seconds since 1970
    Q_PROPERTY(QVariantList programs READ getPrograms NOTIFY changed FINAL)
    // first start and last end of the events
    Q_PROPERTY(qint64 startTime READ getStartTime NOTIFY changed FINAL)
    Q_PROPERTY(qint64 endTime READ getEndTime NOTIFY changed FINAL)
    // the time of the stream (0 when unknown)
    Q_PROPERTY(qint64 epgTime READ getEpgTime NOTIFY changed FINAL)

public:
    explicit EpgModel(QObject* parent = nullptr);

    MainCtx* getCtx() const { return m_ctx; }
    void setCtx(MainCtx* ctx);

    QVariantList getPrograms() const { return m_programs; }
    qint64 getStartTime() const { return m_startTime; }
    qint64 getEndTime() const { return m_endTime; }
    qint64 getEpgTime() const { return m_epgTime; }

    // reads the guide now
    Q_INVOKABLE void update();
    // reads it in 5 seconds (unless already planned)
    Q_INVOKABLE void scheduleUpdate();
    // switches to a program (its source id)
    Q_INVOKABLE void activateProgram(int id);

signals:
    void ctxChanged();
    void changed();

private:
    void reset();

    QPointer<MainCtx> m_ctx;
    qt_intf_t* p_intf = nullptr;
    QTimer m_timer;

    QVariantList m_programs;
    qint64 m_startTime = 0;
    qint64 m_endTime = 0;
    qint64 m_epgTime = 0;
};

#endif
