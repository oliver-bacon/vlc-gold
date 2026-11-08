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
#ifndef VLC_QT_SOUTHELPER_HPP
#define VLC_QT_SOUTHELPER_HPP

#include <QObject>
#include <QPointer>
#include <QVariant>

#include "qt.hpp"
#include "maininterface/mainctx.hpp"

class VLCProfileSelector;

/**
 * What the redesign's Convert and Stream windows (ConvertWindow.qml,
 * StreamWindow.qml) need, with the same results as the classic dialogs
 * (convert.cpp, sout.cpp, sout_widgets.cpp): the transcoding profiles
 * (through a hidden VLCProfileSelector, so they are read, saved, edited and
 * applied the same way), the chains of the stream destinations, and adding
 * the converted / streamed media to the play queue.
 */
class SoutHelper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(MainCtx* ctx READ getCtx WRITE setCtx NOTIFY ctxChanged FINAL)
    // [{ name, value }] of the profiles
    Q_PROPERTY(QVariantList profiles READ getProfiles NOTIFY profilesChanged FINAL)
    Q_PROPERTY(int currentProfile READ getCurrentProfile WRITE setCurrentProfile NOTIFY profileChanged FINAL)
    // of the current profile
    Q_PROPERTY(QString mux READ getMux NOTIFY profileChanged FINAL)
    Q_PROPERTY(QString transcode READ getTranscode NOTIFY profileChanged FINAL)

public:
    explicit SoutHelper(QObject* parent = nullptr);
    ~SoutHelper() override;

    MainCtx* getCtx() const { return m_ctx; }
    void setCtx(MainCtx* ctx);

    QVariantList getProfiles() const;
    int getCurrentProfile() const;
    void setCurrentProfile(int index);
    QString getMux() const;
    QString getTranscode() const;

    // the classic profile editor, for a new or the current profile
    Q_INVOKABLE void newProfile();
    Q_INVOKABLE void editProfile();
    Q_INVOKABLE void deleteProfile();

    // the chain of one destination (VirtualDestBox::getMRL): type "file",
    // "http", "mmsh", "rtsp", "srt", "rist", "rtp-ts", "rtp-avp", "udp",
    // "icecast"; fields { path, address, port, name, mount, password }
    Q_INVOKABLE QString destinationChain(const QString& type, const QVariantMap& fields) const;
    // the whole stream output string (SoutDialog::updateChain)
    Q_INVOKABLE QString streamChain(const QStringList& destinations, bool transcode,
                                    bool displayLocally, bool allStreams) const;
    // the source as shown (SoutInputBox): { text, type }
    Q_INVOKABLE QVariantMap describeSource(const QString& mrl) const;

    // Stream: the media with the chain (DialogsProvider::streamingDialog)
    Q_INVOKABLE void startStream(const QStringList& mrls, const QStringList& options,
                                 const QString& chain);
    // Convert / Save (ConvertDialog::accept): { destination, dump,
    // deinterlace, display, appendConverted }
    Q_INVOKABLE void startConvert(const QStringList& mrls, const QStringList& options,
                                  const QVariantMap& settings);

    // a file to save to; "" when cancelled
    Q_INVOKABLE QString browseSaveFile(const QString& title, const QString& filter) const;
    // the local path of a file URL, with native separators
    Q_INVOKABLE QString displayPath(const QString& url) const;

signals:
    void ctxChanged();
    void profilesChanged();
    void profileChanged();

private:
    class QComboBox* combo() const;
    void saveSelected() const;

    QPointer<MainCtx> m_ctx;
    qt_intf_t* p_intf = nullptr;
    VLCProfileSelector* m_selector = nullptr;
};

#endif
