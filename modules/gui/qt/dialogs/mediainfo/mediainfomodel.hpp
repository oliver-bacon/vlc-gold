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
#ifndef VLC_QT_MEDIAINFOMODEL_HPP
#define VLC_QT_MEDIAINFOMODEL_HPP

#include <QObject>
#include <QUrl>
#include <QVariant>
#include <QPointer>

#include "qt.hpp"
#include "util/shared_input_item.hpp"
#include "maininterface/mainctx.hpp"
#include "dialogs/fingerprint/fingerprintmodel.hpp"

/**
 * What the Media Information window of the redesign (MediaInfoDialog.qml)
 * shows: the metadata of one item (General, editable), its extra metadata,
 * the codec details and, for the playing item, the statistics. Same data
 * and saving as the classic dialog (info_panels.cpp).
 */
class MediaInfoModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(MainCtx* ctx READ getCtx WRITE setCtx NOTIFY ctxChanged FINAL)
    /// follows the playing item (and has statistics)
    Q_PROPERTY(bool current READ isCurrent WRITE setCurrent NOTIFY currentChanged FINAL)
    /// a SharedInputItem (from DialogsProvider) when not `current`
    Q_PROPERTY(QVariant item READ getItem WRITE setItem NOTIFY itemChanged FINAL)
    /// the fields are being edited: `current` keeps its item until done (as
    /// the classic dialog), so the changes are not saved into the next one
    Q_PROPERTY(bool editing READ isEditing WRITE setEditing NOTIFY editingChanged FINAL)

    Q_PROPERTY(bool hasItem READ hasItem NOTIFY metaChanged FINAL)
    /// title, artist, album, genre, trackNumber, trackTotal, date, language,
    /// nowPlaying, publisher, copyright, encodedBy, description
    Q_PROPERTY(QVariantMap meta READ getMeta NOTIFY metaChanged FINAL)
    Q_PROPERTY(QString artwork READ getArtwork NOTIFY artworkChanged FINAL)
    /// local path of a file, the MRL otherwise
    Q_PROPERTY(QString location READ getLocation NOTIFY metaChanged FINAL)
    Q_PROPERTY(bool canFingerprint READ canFingerprint NOTIFY metaChanged FINAL)
    /// the fingerprinting started by fingerprint() (its window)
    Q_PROPERTY(FingerprintModel* fingerprinter READ getFingerprinter CONSTANT FINAL)
    /// [{ name, value }]
    Q_PROPERTY(QVariantList extraMeta READ getExtraMeta NOTIFY extraMetaChanged FINAL)
    /// [{ name, infos: [{ name, value }] }]
    Q_PROPERTY(QVariantList codecInfo READ getCodecInfo NOTIFY codecInfoChanged FINAL)
    /// counters of input_stats_t, bitrates in kb/s, sizes in KiB
    Q_PROPERTY(QVariantMap stats READ getStats NOTIFY statsChanged FINAL)
    /// input bitrate in kb/s: the last 60 samples, and the whole playback
    /// in 60 averaged blocks (as the classic graph)
    Q_PROPERTY(QVariantList recentBitrates READ getRecentBitrates NOTIFY statsChanged FINAL)
    Q_PROPERTY(QVariantList overallBitrates READ getOverallBitrates NOTIFY statsChanged FINAL)

public:
    explicit MediaInfoModel(QObject* parent = nullptr);

    MainCtx* getCtx() const { return m_ctx; }
    void setCtx(MainCtx* ctx);
    bool isCurrent() const { return m_current; }
    void setCurrent(bool current);
    QVariant getItem() const;
    void setItem(const QVariant& item);
    bool isEditing() const { return m_editing; }
    void setEditing(bool editing);

    bool hasItem() const { return !!m_item; }
    QVariantMap getMeta() const { return m_meta; }
    QString getArtwork() const { return m_artwork; }
    QString getLocation() const { return m_location; }
    bool canFingerprint() const { return m_canFingerprint; }
    FingerprintModel* getFingerprinter() const { return m_fingerprinter; }
    QVariantList getExtraMeta() const { return m_extraMeta; }
    QVariantList getCodecInfo() const { return m_codecInfo; }
    QVariantMap getStats() const { return m_stats; }
    QVariantList getRecentBitrates() const { return m_recent; }
    QVariantList getOverallBitrates() const { return m_overall; }

    /// writes the fields (keys of `meta`) and the cover art (a file URL, or
    /// empty to keep it) to the item and its file; "" on success, the error
    /// otherwise
    Q_INVOKABLE QString save(const QVariantMap& meta, const QString& artUrl);
    /// "Download cover art"
    Q_INVOKABLE void downloadArt();
    /// "Add cover art from file": the URL of the picked picture, or ""
    Q_INVOKABLE QString pickArtFile();
    /// the classic Fingerprint dialog; fingerprintApplied() after "Apply"
    Q_INVOKABLE void fingerprint();
    /// re-reads everything (after closing without saving)
    Q_INVOKABLE void reload();
    /// starts the bitrate graph again (the window was hidden)
    Q_INVOKABLE void resetStats();

signals:
    void ctxChanged();
    void currentChanged();
    void itemChanged();
    void editingChanged();
    void metaChanged();
    void artworkChanged();
    void extraMetaChanged();
    void codecInfoChanged();
    void statsChanged();
    void fingerprintApplied();

private:
    void connectPlayer();
    void followPlayer();
    void updateMeta();
    void updateArtwork();
    void updateExtraMeta();
    void updateCodecInfo();
    void updateStats(const input_stats_t& stats);
    void addHistoryValue(double value);

    QPointer<MainCtx> m_ctx;
    qt_intf_t* p_intf = nullptr;
    bool m_current = false;
    bool m_playerConnected = false;
    bool m_editing = false;
    SharedInputItem m_item;

    QVariantMap m_meta;
    QString m_artwork;
    QString m_location;
    bool m_canFingerprint = false;
    FingerprintModel* m_fingerprinter = nullptr;
    QVariantList m_extraMeta;
    QVariantList m_codecInfo;
    QVariantMap m_stats;

    QVariantList m_recent;
    QVariantList m_overall;
    int m_historyMerge = 0;
    int m_blockSize = 4;
    double m_accumulator = 0;
    int m_accumulated = 0;
};

#endif
