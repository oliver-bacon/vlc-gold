/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
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
#ifndef VLC_QT_UPDATE_CHECK_HPP
#define VLC_QT_UPDATE_CHECK_HPP

#include <QObject>
#include <QPointer>
#include <QThreadPool>
#include <QTimer>

#include <memory>

#include "qt.hpp"
#include "maininterface/mainctx.hpp"

// "Check for Updates": asks GitHub for the latest release of VLC Gold and
// compares its tag (redesign-vX.Y.Z) with this build. Only when asked (the
// menu entry); nothing is downloaded, the release page opens in the browser.
class UpdateCheck : public QObject
{
    Q_OBJECT

    Q_PROPERTY(MainCtx* ctx READ getCtx WRITE setCtx NOTIFY ctxChanged FINAL)
    Q_PROPERTY(State state READ state NOTIFY changed FINAL)
    Q_PROPERTY(QString currentVersion READ currentVersion CONSTANT FINAL)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY changed FINAL)
    /// release notes (Markdown)
    Q_PROPERTY(QString notes READ notes NOTIFY changed FINAL)
    Q_PROPERTY(QString error READ error NOTIFY changed FINAL)

public:
    enum State { Idle, Checking, UpToDate, Available, Failed };
    Q_ENUM(State)

    explicit UpdateCheck(QObject* parent = nullptr);
    ~UpdateCheck() override;

    MainCtx* getCtx() const { return m_ctx; }
    void setCtx(MainCtx* ctx);

    State state() const { return m_state; }
    QString currentVersion() const;
    QString latestVersion() const { return m_latest; }
    QString notes() const { return m_notes; }
    QString error() const { return m_error; }

    Q_INVOKABLE void check();
    /// the page of the new release, in the browser
    Q_INVOKABLE void openPage() const;

    /// "redesign-v1.0.1" / "1.0.1" newer than "1.0.0"
    static bool isNewer(const QString& tag, const QString& current);

signals:
    void ctxChanged();
    void changed();

private:
    struct Job;

    void finish(const std::shared_ptr<Job>& job);
    void stop();

    QPointer<MainCtx> m_ctx;
    QThreadPool m_pool;
    QTimer m_timeout;
    std::shared_ptr<Job> m_job;

    State m_state = Idle;
    QString m_latest;
    QString m_notes;
    QString m_pageUrl;
    QString m_error;
};

#endif // VLC_QT_UPDATE_CHECK_HPP
