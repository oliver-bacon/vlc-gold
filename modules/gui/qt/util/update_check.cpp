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
#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "update_check.hpp"
#include "https_request.hpp"

#include <QDesktopServices>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QUrl>

#include <atomic>

#include <vlc_common.h>
#include <vlc_interrupt.h>

#ifndef GOLD_VERSION
# define GOLD_VERSION "0"
#endif

namespace {

constexpr char userAgent[] = "VLC Gold v" GOLD_VERSION;
constexpr char latestUrl[] = "https://api.github.com/repos/oliver-bacon/vlc-gold/releases/latest";
constexpr char releasesPage[] = "https://github.com/oliver-bacon/vlc-gold/releases";

QList<int> versionNumbers(const QString& text)
{
    // the first "1.2.3" in the text
    static const QRegularExpression re(QStringLiteral("(\\d+(?:\\.\\d+)*)"));
    QList<int> numbers;
    const QRegularExpressionMatch match = re.match(text);
    if (match.hasMatch())
    {
        for (const QString& part : match.captured(1).split('.'))
            numbers.append(part.toInt());
    }
    return numbers;
}

} // namespace

struct UpdateCheck::Job
{
    vlc_interrupt_t* interrupt = nullptr;
    std::atomic<bool> cancelled { false };
    // the answer, written by the worker before finish() is queued
    int status = 0;
    QByteArray body;
};

UpdateCheck::UpdateCheck(QObject* parent)
    : QObject(parent)
{
    m_pool.setMaxThreadCount(1);

    // a request that hangs
    m_timeout.setSingleShot(true);
    m_timeout.setInterval(30000);
    connect(&m_timeout, &QTimer::timeout, this, [this]() {
        if (m_job && m_job->interrupt)
            vlc_interrupt_kill(m_job->interrupt);
    });
}

UpdateCheck::~UpdateCheck()
{
    stop();
}

void UpdateCheck::stop()
{
    std::shared_ptr<Job> job = std::move(m_job);
    m_job.reset();
    m_timeout.stop();
    if (!job)
        return;
    job->cancelled = true;
    if (job->interrupt)
        vlc_interrupt_kill(job->interrupt);
    m_pool.waitForDone();
    if (job->interrupt)
    {
        vlc_interrupt_destroy(job->interrupt);
        job->interrupt = nullptr;
    }
}

void UpdateCheck::setCtx(MainCtx* ctx)
{
    if (m_ctx == ctx)
        return;
    m_ctx = ctx;
    emit ctxChanged();
}

QString UpdateCheck::currentVersion() const
{
    return QString::fromUtf8(GOLD_VERSION);
}

bool UpdateCheck::isNewer(const QString& tag, const QString& current)
{
    const QList<int> a = versionNumbers(tag);
    const QList<int> b = versionNumbers(current);
    if (a.isEmpty())
        return false;
    for (qsizetype i = 0; i < qMax(a.size(), b.size()); ++i)
    {
        const int x = a.value(i, 0);
        const int y = b.value(i, 0);
        if (x != y)
            return x > y;
    }
    return false;
}

void UpdateCheck::check()
{
    if (m_state == Checking || !m_ctx)
        return;

    auto job = std::make_shared<Job>();
    job->interrupt = vlc_interrupt_create();
    if (!job->interrupt)
        return;
    m_job = job;

    m_state = Checking;
    m_error.clear();
    emit changed();
    m_timeout.start();

    vlc_object_t* obj = VLC_OBJECT(m_ctx->getIntf());
    m_pool.start([this, job, obj]() {
        vlc_interrupt_t* previous = vlc_interrupt_set(job->interrupt);
        const HttpsResponse r = httpsRequest(obj, "GET", QUrl(QString::fromLatin1(latestUrl)),
                                             { { "Accept", "application/vnd.github+json" },
                                               { "X-GitHub-Api-Version", "2022-11-28" } },
                                             {}, userAgent);
        vlc_interrupt_set(previous);
        job->status = r.status;
        job->body = r.body;
        // dropped when the checker is gone (its destructor waits for this thread)
        QMetaObject::invokeMethod(this, [this, job]() { finish(job); }, Qt::QueuedConnection);
    });
}

void UpdateCheck::finish(const std::shared_ptr<Job>& job)
{
    if (job != m_job)
        return; // stopped
    m_job.reset();
    m_timeout.stop();
    vlc_interrupt_destroy(job->interrupt);
    job->interrupt = nullptr;

    const QJsonObject release = QJsonDocument::fromJson(job->body).object();
    const QString tag = release.value(QLatin1String("tag_name")).toString();

    if (job->status == 200 && !versionNumbers(tag).isEmpty())
    {
        QStringList parts;
        for (int n : versionNumbers(tag))
            parts.append(QString::number(n));
        m_latest = parts.join('.');
        m_notes = release.value(QLatin1String("body")).toString();
        // only a page of the project
        const QString page = release.value(QLatin1String("html_url")).toString();
        m_pageUrl = page.startsWith(QLatin1String(releasesPage)) ? page : QString::fromLatin1(releasesPage);
        m_state = isNewer(tag, currentVersion()) ? Available : UpToDate;
    }
    else
    {
        if (job->status == 0)
            m_error = qtr("GitHub could not be reached. Check the internet connection.");
        else if (job->status == 403 || job->status == 429)
            m_error = qtr("GitHub refused the request for now (too many requests). Try again later.");
        else if (job->status == 404)
            m_error = qtr("No release was found.");
        else
            m_error = qtr("GitHub answered with an error (%1).").arg(job->status);
        m_state = Failed;
    }
    emit changed();
}

void UpdateCheck::openPage() const
{
    QDesktopServices::openUrl(QUrl(m_pageUrl.isEmpty() ? QString::fromLatin1(releasesPage) : m_pageUrl));
}
