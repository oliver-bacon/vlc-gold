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

#include "mediainfomodel.hpp"

#include <QFileDialog>

#include <vlc_common.h>
#include <vlc_url.h>
#include <vlc_meta.h>
#include <vlc_input_item.h>

#include "maininterface/mainctx.hpp"
#include "player/player_controller.hpp"
#include "dialogs/fingerprint/chromaprint.hpp"

namespace {

constexpr int STATS_LENGTH = 60;

QString metaString(char* psz)
{
    const QString s = !EMPTY_STR(psz) ? qfu(psz) : QString();
    free(psz);
    return s;
}

QVariantMap nameValue(const QString& name, const QString& value)
{
    return QVariantMap {
        { QStringLiteral("name"), name },
        { QStringLiteral("value"), value },
    };
}

}

MediaInfoModel::MediaInfoModel(QObject* parent)
    : QObject(parent)
    , m_fingerprinter(new FingerprintModel(this))
{
    connect(m_fingerprinter, &FingerprintModel::applied, this, [this](const SharedInputItem& item) {
        if (item != m_item)
            return;
        updateMeta();
        emit fingerprintApplied();
    });
}

void MediaInfoModel::setCtx(MainCtx* ctx)
{
    if (m_ctx == ctx)
        return;
    m_ctx = ctx;
    p_intf = ctx ? ctx->getIntf() : nullptr;
    connectPlayer();
    emit ctxChanged();
}

void MediaInfoModel::setCurrent(bool current)
{
    if (m_current == current)
        return;
    m_current = current;
    connectPlayer();
    followPlayer();
    emit currentChanged();
}

QVariant MediaInfoModel::getItem() const
{
    return QVariant::fromValue(m_item);
}

void MediaInfoModel::setItem(const QVariant& item)
{
    const SharedInputItem p_item = item.value<SharedInputItem>();
    if (p_item == m_item)
        return;
    m_item = p_item;
    emit itemChanged();
    reload();
}

void MediaInfoModel::setEditing(bool editing)
{
    if (m_editing == editing)
        return;
    m_editing = editing;
    emit editingChanged();
    // the playing item may have changed meanwhile
    if (!m_editing)
        followPlayer();
}

// takes the playing item, unless the fields are being edited
void MediaInfoModel::followPlayer()
{
    if (!m_current || m_editing || !p_intf)
        return;
    SharedInputItem playing { THEMIM->getInput() };
    if (playing != m_item)
    {
        m_item = std::move(playing);
        emit itemChanged();
    }
    reload();
}

void MediaInfoModel::connectPlayer()
{
    if (!p_intf || m_playerConnected)
        return;
    m_playerConnected = true;

    PlayerController* player = THEMIM;

    // the playing item: same signals as the classic dialog
    connect(player, &PlayerController::inputChanged, this, [this]() {
        followPlayer();
    });
    connect(player, &PlayerController::infoChanged, this, [this](input_item_t* item) {
        if (m_current || (item && item == m_item.get()))
            updateCodecInfo();
    });
    connect(player, &PlayerController::currentMetaChanged, this, [this](input_item_t* item) {
        if (m_current || (item && item == m_item.get()))
        {
            updateMeta();
            updateExtraMeta();
        }
    });
    connect(player, &PlayerController::statisticsUpdated, this, [this](const input_stats_t& stats) {
        if (m_current)
            updateStats(stats);
    });
    connect(player, QOverload<QString>::of(&PlayerController::artChanged), this, [this](QString) {
        if (m_current)
            updateArtwork();
    });
    // art fetched for an item that is not playing
    connect(player, QOverload<input_item_t*>::of(&PlayerController::artChanged), this, [this](input_item_t* item) {
        if (item && item == m_item.get())
            updateArtwork();
    });

    followPlayer();
}

void MediaInfoModel::reload()
{
    updateMeta();
    updateArtwork();
    updateExtraMeta();
    updateCodecInfo();
}

void MediaInfoModel::updateMeta()
{
    input_item_t* item = m_item.get();
    QVariantMap meta;
    QString location;
    bool fingerprint = false;

    if (item)
    {
        meta[QStringLiteral("title")] = metaString(input_item_GetTitleFbName(item));
        meta[QStringLiteral("artist")] = metaString(input_item_GetArtist(item));
        meta[QStringLiteral("album")] = metaString(input_item_GetAlbum(item));
        meta[QStringLiteral("genre")] = metaString(input_item_GetGenre(item));
        meta[QStringLiteral("trackNumber")] = metaString(input_item_GetTrackNum(item));
        meta[QStringLiteral("trackTotal")] = metaString(input_item_GetTrackTotal(item));
        meta[QStringLiteral("date")] = metaString(input_item_GetDate(item));
        meta[QStringLiteral("language")] = metaString(input_item_GetLanguage(item));
        meta[QStringLiteral("nowPlaying")] = metaString(input_item_GetNowPlayingFb(item));
        meta[QStringLiteral("publisher")] = metaString(input_item_GetPublisher(item));
        meta[QStringLiteral("copyright")] = metaString(input_item_GetCopyright(item));
        meta[QStringLiteral("encodedBy")] = metaString(input_item_GetEncodedBy(item));
        meta[QStringLiteral("description")] = metaString(input_item_GetDescription(item));

        const QString uri = metaString(input_item_GetURI(item));
        fingerprint = Chromaprint::isSupported(uri);

        // the path of a local file, as the classic "Location"
        char* path = uri.isEmpty() ? nullptr : vlc_uri2path(qtu(uri));
        location = path ? qfu(path) : uri;
        free(path);
    }

    m_meta = meta;
    m_location = location;
    m_canFingerprint = fingerprint;
    emit metaChanged();
}

void MediaInfoModel::updateArtwork()
{
    const QString art = m_item ? metaString(input_item_GetArtURL(m_item.get())) : QString();
    if (art == m_artwork)
        return;
    m_artwork = art;
    emit artworkChanged();
}

void MediaInfoModel::updateExtraMeta()
{
    QVariantList rows;
    input_item_t* item = m_item.get();

    if (item)
    {
        vlc_mutex_locker lock(&item->lock);
        if (vlc_meta_t* meta = item->p_meta)
        {
            if (const char* disc = vlc_meta_Get(meta, vlc_meta_DiscNumber))
                rows.append(nameValue(qfu(VLC_META_DISCNUMBER), qfu(disc)));
            if (const char* url = vlc_meta_Get(meta, vlc_meta_URL))
                rows.append(nameValue(qfu(VLC_META_URL), qfu(url)));

            if (char** keys = vlc_meta_CopyExtraNames(meta))
            {
                for (int i = 0; keys[i]; ++i)
                {
                    rows.append(nameValue(qfu(keys[i]), qfu(vlc_meta_GetExtra(meta, keys[i]))));
                    free(keys[i]);
                }
                free(keys);
            }
        }
    }

    m_extraMeta = rows;
    emit extraMetaChanged();
}

void MediaInfoModel::updateCodecInfo()
{
    QVariantList categories;
    input_item_t* item = m_item.get();

    if (item)
    {
        vlc_mutex_locker lock(&item->lock);
        // (vlc_list.hpp can only be included once in the plugin: its
        // operators are not inline, info_panels.cpp has it)
        info_category_t* cat;
        vlc_list_foreach(cat, &item->categories, node)
        {
            if (info_category_IsHidden(cat))
                continue;

            QVariantList infos;
            info_t* info;
            vlc_list_foreach(info, &cat->infos, node)
                infos.append(nameValue(qfu(info->psz_name), qfu(info->psz_value)));

            categories.append(QVariantMap {
                { QStringLiteral("name"), qfu(cat->psz_name) },
                { QStringLiteral("infos"), infos },
            });
        }
    }

    m_codecInfo = categories;
    emit codecInfoChanged();
}

void MediaInfoModel::updateStats(const input_stats_t& stats)
{
    const double inputBitrate = stats.f_input_bitrate * 8000;

    m_stats = QVariantMap {
        { QStringLiteral("readBytes"), qulonglong(stats.i_read_bytes / 1024) },
        { QStringLiteral("inputBitrate"), qRound(inputBitrate) },
        { QStringLiteral("demuxBytes"), qulonglong(stats.i_demux_read_bytes / 1024) },
        { QStringLiteral("demuxBitrate"), qRound(stats.f_demux_bitrate * 8000) },
        { QStringLiteral("demuxCorrupted"), qulonglong(stats.i_demux_corrupted) },
        { QStringLiteral("demuxDiscontinuity"), qulonglong(stats.i_demux_discontinuity) },
        { QStringLiteral("decodedVideo"), qulonglong(stats.i_decoded_video) },
        { QStringLiteral("displayedPictures"), qulonglong(stats.i_displayed_pictures) },
        { QStringLiteral("latePictures"), qulonglong(stats.i_late_pictures) },
        { QStringLiteral("lostPictures"), qulonglong(stats.i_lost_pictures) },
        { QStringLiteral("decodedAudio"), qulonglong(stats.i_decoded_audio) },
        { QStringLiteral("playedBuffers"), qulonglong(stats.i_played_abuffers) },
        { QStringLiteral("lostBuffers"), qulonglong(stats.i_lost_abuffers) },
    };

    m_recent.append(inputBitrate);
    while (m_recent.size() > STATS_LENGTH)
        m_recent.removeFirst();
    addHistoryValue(inputBitrate);

    emit statsChanged();
}

// the whole playback in STATS_LENGTH values, as VLCStatsView: each value is
// the mean of a block of samples; when full, the oldest values are merged
// two by two and the blocks grow
void MediaInfoModel::addHistoryValue(double value)
{
    m_accumulator += value / m_blockSize;
    if (++m_accumulated < m_blockSize)
        return;

    const double mean = m_accumulator;
    m_accumulator = 0;
    m_accumulated = 0;

    if (m_overall.size() >= STATS_LENGTH)
    {
        const double merged = (m_overall[m_historyMerge].toDouble()
                               + m_overall[m_historyMerge + 1].toDouble()) / 2;
        m_overall[m_historyMerge] = merged;
        m_overall.removeAt(m_historyMerge + 1);
        if (++m_historyMerge > STATS_LENGTH - 2)
        {
            m_historyMerge = 0;
            m_blockSize *= 2;
        }
    }
    m_overall.append(mean);
}

void MediaInfoModel::resetStats()
{
    m_recent.clear();
    m_overall.clear();
    m_historyMerge = 0;
    m_blockSize = 4;
    m_accumulator = 0;
    m_accumulated = 0;
    m_stats.clear();
    emit statsChanged();
}

QString MediaInfoModel::save(const QVariantMap& meta, const QString& artUrl)
{
    input_item_t* item = m_item.get();
    if (!item || !p_intf)
        return qtr("Not editing a file");

    using Setter = void (*)(input_item_t*, const char*);
    const auto set = [&](Setter setter, const char* key) {
        const QByteArray value = meta.value(QLatin1String(key)).toString().toUtf8();
        setter(item, value.constData());
    };

    set(input_item_SetTitle, "title");
    set(input_item_SetArtist, "artist");
    set(input_item_SetAlbum, "album");
    set(input_item_SetGenre, "genre");
    set(input_item_SetTrackNum, "trackNumber");
    set(input_item_SetTrackTotal, "trackTotal");
    set(input_item_SetDate, "date");
    set(input_item_SetLanguage, "language");
    set(input_item_SetCopyright, "copyright");
    set(input_item_SetPublisher, "publisher");
    set(input_item_SetEncodedBy, "encodedBy");
    set(input_item_SetDescription, "description");
    if (!artUrl.isEmpty())
        input_item_SetArtURL(item, qtu(artUrl));

    if (input_item_WriteMeta(VLC_OBJECT(p_intf), item) != VLC_SUCCESS)
        return qtr("Failed to save metadata");

    // the player's caches for the playing item (cover, title)
    THEMIM->refreshMediaMeta(item);
    reload();
    return QString();
}

void MediaInfoModel::downloadArt()
{
    if (m_item && p_intf)
        THEMIM->requestArtUpdate(m_item.get());
}

QString MediaInfoModel::pickArtFile()
{
    if (!m_item || !p_intf)
        return QString();

    const QUrl url = QFileDialog::getOpenFileUrl(nullptr, qtr("Choose Cover Art"),
        p_intf->p_mi ? p_intf->p_mi->getDialogFilePath() : QUrl(),
        qtr("Image Files (*.gif *.jpg *.jpeg *.png)"));
    return url.isEmpty() ? QString() : url.toString();
}

void MediaInfoModel::fingerprint()
{
    if (!m_item || !p_intf)
        return;
    // shown by the Media Information window (FingerprintWindow.qml)
    m_fingerprinter->start(p_intf, m_item.get());
}
