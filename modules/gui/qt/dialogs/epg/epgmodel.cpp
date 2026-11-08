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

#include "epgmodel.hpp"
#include "player/player_controller.hpp"

#include <vlc_common.h>
#include <vlc_input_item.h>
#include <vlc_epg.h>
#include <vlc_player.h>

#include <limits>

EpgModel::EpgModel(QObject* parent)
    : QObject(parent)
{
    m_timer.setSingleShot(true);
    m_timer.setInterval(5000);
    connect(&m_timer, &QTimer::timeout, this, &EpgModel::update);
}

void EpgModel::setCtx(MainCtx* ctx)
{
    if (m_ctx == ctx || !ctx || m_ctx)
        return;
    m_ctx = ctx;
    p_intf = ctx->getIntf();

    PlayerController* player = p_intf->p_mainPlayerController;
    connect(player, &PlayerController::epgChanged, this, &EpgModel::scheduleUpdate);
    connect(player, &PlayerController::inputChanged, this, [this]() {
        reset();
        scheduleUpdate();
    });
    emit ctxChanged();
}

void EpgModel::scheduleUpdate()
{
    if (!m_timer.isActive())
        m_timer.start();
}

void EpgModel::reset()
{
    m_programs.clear();
    m_startTime = m_endTime = m_epgTime = 0;
    emit changed();
}

void EpgModel::update()
{
    if (!p_intf)
        return;

    input_item_t* media;
    {
        vlc_player_locker lock{ p_intf->p_player };
        media = vlc_player_HoldCurrentMedia(p_intf->p_player);
    }
    if (!media)
    {
        reset();
        return;
    }

    QVariantList programs;
    qint64 first = std::numeric_limits<qint64>::max();
    qint64 last = 0;

    vlc_mutex_lock(&media->lock);
    for (int i = 0; i < media->i_epg; ++i)
    {
        const vlc_epg_t* epg = media->pp_epg[i];
        QVariantList events;
        QSet<qint64> starts;
        for (size_t j = 0; j < epg->i_event; ++j)
        {
            const vlc_epg_event_t* event = epg->pp_event[j];
            /* one event per start time, as the classic view */
            if (starts.contains(event->i_start))
                continue;
            starts.insert(event->i_start);

            QString description = qfu(event->psz_description);
            const QString shortDescription = qfu(event->psz_short_description);
            if (description.isEmpty())
                description = shortDescription;
            else if (!shortDescription.isEmpty())
                description += " - " + shortDescription;

            QVariantList items;
            for (int k = 0; k < event->i_description_items; ++k)
                items.append(QVariantMap {
                    { "key", qfu(event->description_items[k].psz_key) },
                    { "value", qfu(event->description_items[k].psz_value) }
                });

            events.append(QVariantMap {
                { "start", (qint64)event->i_start },
                { "duration", (qint64)event->i_duration },
                { "name", qfu(event->psz_name) },
                { "description", description },
                { "rating", event->i_rating },
                { "items", items },
                { "current", event == epg->p_current }
            });
            first = std::min<qint64>(first, event->i_start);
            last = std::max<qint64>(last, event->i_start + event->i_duration);
        }
        if (events.isEmpty())
            continue;
        std::sort(events.begin(), events.end(), [](const QVariant& a, const QVariant& b) {
            return a.toMap().value("start").toLongLong() < b.toMap().value("start").toLongLong();
        });
        programs.append(QVariantMap {
            { "id", (int)epg->i_source_id },
            { "name", qfu(epg->psz_name) },
            { "events", events }
        });
    }
    m_epgTime = media->i_epg_time;
    vlc_mutex_unlock(&media->lock);
    input_item_Release(media);

    m_programs = programs;
    m_startTime = programs.isEmpty() ? 0 : first;
    m_endTime = programs.isEmpty() ? 0 : last;
    emit changed();
}

void EpgModel::activateProgram(int id)
{
    if (p_intf)
        p_intf->p_mainPlayerController->changeProgram(id);
}
