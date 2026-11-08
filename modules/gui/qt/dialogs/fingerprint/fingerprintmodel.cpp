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

#include "fingerprintmodel.hpp"
#include "chromaprint.hpp"

#include <vlc_meta.h>
#include <vlc_fingerprinter.h>

FingerprintModel::FingerprintModel(QObject* parent)
    : QObject(parent)
{
}

FingerprintModel::~FingerprintModel()
{
    cleanup();
}

void FingerprintModel::cleanup()
{
    delete m_chromaprint;
    m_chromaprint = nullptr;
    if (m_request)
        fingerprint_request_Delete(m_request);
    m_request = nullptr;
    m_results.clear();
}

void FingerprintModel::setState(State state)
{
    m_state = state;
    emit stateChanged();
}

void FingerprintModel::start(qt_intf_t* p_intf, input_item_t* item)
{
    cleanup();
    m_chromaprint = new (std::nothrow) Chromaprint(p_intf);
    if (!m_chromaprint)
    {
        setState(Idle);
        return;
    }
    connect(m_chromaprint, &Chromaprint::finished, this, &FingerprintModel::handleResults);
    m_chromaprint->enqueue(item);
    setState(Working);
}

void FingerprintModel::handleResults()
{
    if (!m_chromaprint)
        return;
    m_request = m_chromaprint->fetchResults();
    if (!m_request)
    {
        setState(NotFound);
        return;
    }
    if (vlc_array_count(&m_request->results.metas_array) == 0)
    {
        fingerprint_request_Delete(m_request);
        m_request = nullptr;
        setState(NotFound);
        return;
    }

    m_results.clear();
    for (size_t i = 0; i < vlc_array_count(&m_request->results.metas_array); i++)
    {
        vlc_meta_t* meta = (vlc_meta_t*) vlc_array_item_at_index(&m_request->results.metas_array, i);
        const QString mbId = qfu(vlc_meta_GetExtra(meta, "musicbrainz-id"));
        m_results.append(QVariantMap {
            { "title", qfu(vlc_meta_Get(meta, vlc_meta_Title)) },
            { "artist", qfu(vlc_meta_Get(meta, vlc_meta_Artist)) },
            { "link", QString("https://mb.videolan.org/recording/%1").arg(mbId) }
        });
    }
    setState(Results);
}

void FingerprintModel::apply(int index)
{
    if (!m_request || !m_chromaprint)
        return;
    if (index >= 0 && (size_t)index < vlc_array_count(&m_request->results.metas_array))
        m_chromaprint->apply(m_request, index);
    const SharedInputItem item { m_request->p_item };
    cleanup();
    setState(Idle);
    emit applied(item);
}

void FingerprintModel::discard()
{
    cleanup();
    setState(Idle);
}
