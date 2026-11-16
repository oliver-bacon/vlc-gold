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

#include "opensubtitles.hpp"
#include "https_request.hpp"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QRegularExpression>
#include <QSettings>
#include <QUrl>

#include <algorithm>
#include <atomic>

#include <vlc_common.h>
#include <vlc_configuration.h>
#include <vlc_interrupt.h>
#include <vlc_keystore.h>
#include <vlc_tick.h>
#include <vlc_tls.h>

// autotools writes the key to this header (Makefile.am), meson passes it
// as a define (meson.build)
#if !defined(OPENSUBTITLES_API_KEY) && __has_include("util/opensubtitles_key.h")
# include "util/opensubtitles_key.h"
#endif
#ifndef OPENSUBTITLES_API_KEY
# define OPENSUBTITLES_API_KEY ""
#endif
#ifndef GOLD_VERSION
# define GOLD_VERSION "0"
#endif

namespace {

constexpr char apiKey[] = OPENSUBTITLES_API_KEY;
constexpr char userAgent[] = "VLC Gold v" GOLD_VERSION;
constexpr char keystoreServer[] = "api.opensubtitles.com";
constexpr vlc_tick_t requestTimeout = VLC_TICK_FROM_SEC(30);
// the session token lasts 24 hours; sign in again a bit before
constexpr qint64 tokenLifetime = 20 * 3600;

using Response = HttpsResponse;
using Headers = HttpsHeaders;

Response httpRequest(vlc_object_t* obj, const QByteArray& method, const QUrl& url,
                     const Headers& headers, const QByteArray& body = {})
{
    return httpsRequest(obj, method, url, headers, body, userAgent);
}

/// The OpenSubtitles hash of a local file: its size plus the 64-bit words
/// of its first and last 64 KiB
QString movieHash(const QUrl& url)
{
    if (!url.isLocalFile())
        return {};
    QFile file(url.toLocalFile());
    constexpr qint64 chunk = 65536;
    if (!file.open(QIODevice::ReadOnly) || file.size() < 2 * chunk)
        return {};

    quint64 hash = file.size();
    const auto add = [&](qint64 offset) {
        if (!file.seek(offset))
            return false;
        const QByteArray data = file.read(chunk);
        if (data.size() != chunk)
            return false;
        const auto* bytes = reinterpret_cast<const uchar*>(data.constData());
        for (qint64 i = 0; i < chunk; i += 8)
        {
            quint64 word = 0;
            for (int b = 7; b >= 0; --b)
                word = (word << 8) | bytes[i + b];
            hash += word;
        }
        return true;
    };
    if (!add(0) || !add(file.size() - chunk))
        return {};
    return QStringLiteral("%1").arg(hash, 16, 16, QLatin1Char('0'));
}

QString fileNameOf(const QUrl& url)
{
    return url.fileName(QUrl::FullyDecoded);
}

/// "Show.S01E02.720p.mkv" -> { 1, 2 }; { 0, 0 } when there is none
QPair<int, int> episodeOf(const QString& name)
{
    static const QRegularExpression sxe(QStringLiteral("[Ss](\\d{1,2})[ ._-]?[Ee](\\d{1,3})"));
    static const QRegularExpression nxn(QStringLiteral("(?:^|[ ._-])(\\d{1,2})x(\\d{2,3})(?:[ ._-]|$)"));
    QRegularExpressionMatch match = sxe.match(name);
    if (!match.hasMatch())
        match = nxn.match(name);
    if (!match.hasMatch())
        return { 0, 0 };
    return { match.captured(1).toInt(), match.captured(2).toInt() };
}

QString queryFromFileName(const QString& name)
{
    QString base = QFileInfo(name).completeBaseName();
    base.replace(QRegularExpression(QStringLiteral("[._]+")), QStringLiteral(" "));
    return base.simplified().toLower();
}

QString errorText(const Response& r, const QByteArray& message = {})
{
    if (r.status == 0)
        return qtr("Could not connect to OpenSubtitles.");
    if (r.status == 401 || r.status == 403)
        return qtr("OpenSubtitles refused the request (wrong user name, password or app key).");
    if (r.status == 429)
        return qtr("Too many requests to OpenSubtitles. Try again in a minute.");
    if (!message.isEmpty())
        return QString::fromUtf8(message);
    return qtr("OpenSubtitles answered with an error (HTTP %1).").arg(r.status);
}

QByteArray serverMessage(const QByteArray& body)
{
    const QJsonObject object = QJsonDocument::fromJson(body).object();
    const QString message = object.value(QLatin1String("message")).toString(
                                object.value(QLatin1String("errors")).toArray().first().toString());
    return message.toUtf8();
}

/// Short list used until the full one has come from the server
QVariantList builtinLanguages()
{
    static const char* const list[][2] = {
        { "ar", "Arabic" }, { "zh-cn", "Chinese (simplified)" }, { "zh-tw", "Chinese (traditional)" },
        { "cs", "Czech" }, { "da", "Danish" }, { "nl", "Dutch" }, { "en", "English" },
        { "fi", "Finnish" }, { "fr", "French" }, { "de", "German" }, { "el", "Greek" },
        { "he", "Hebrew" }, { "hu", "Hungarian" }, { "id", "Indonesian" }, { "it", "Italian" },
        { "ja", "Japanese" }, { "ko", "Korean" }, { "no", "Norwegian" }, { "fa", "Persian" },
        { "pl", "Polish" }, { "pt-pt", "Portuguese" }, { "pt-br", "Portuguese (BR)" },
        { "ro", "Romanian" }, { "ru", "Russian" }, { "sr", "Serbian" }, { "es", "Spanish" },
        { "sv", "Swedish" }, { "th", "Thai" }, { "tr", "Turkish" }, { "uk", "Ukrainian" },
        { "vi", "Vietnamese" },
    };
    QVariantList ret;
    for (const auto& entry : list)
        ret.append(QVariantMap { { QStringLiteral("code"), QString::fromLatin1(entry[0]) },
                                 { QStringLiteral("name"), QString::fromLatin1(entry[1]) } });
    return ret;
}

QByteArray keystorePassword(vlc_object_t* obj, const QString& username)
{
    vlc_keystore* keystore = vlc_keystore_create(obj);
    if (!keystore)
        return {};
    const QByteArray user = username.toUtf8();
    const char* values[KEY_MAX];
    VLC_KEYSTORE_VALUES_INIT(values);
    values[KEY_PROTOCOL] = "https";
    values[KEY_SERVER] = keystoreServer;
    values[KEY_USER] = user.constData();
    vlc_keystore_entry* entries = nullptr;
    const unsigned count = vlc_keystore_find(keystore, values, &entries);
    QByteArray password;
    if (count > 0 && entries[0].p_secret)
        password = QByteArray(reinterpret_cast<const char*>(entries[0].p_secret),
                              static_cast<qsizetype>(entries[0].i_secret_len));
    if (count > 0)
        vlc_keystore_release_entries(entries, count);
    vlc_keystore_release(keystore);
    // the string secrets are stored with their '\0'
    while (password.endsWith('\0'))
        password.chop(1);
    return password;
}

void keystoreSet(vlc_object_t* obj, const QString& username, const QByteArray& password)
{
    vlc_keystore* keystore = vlc_keystore_create(obj);
    if (!keystore)
        return;
    const QByteArray user = username.toUtf8();
    const char* values[KEY_MAX];
    VLC_KEYSTORE_VALUES_INIT(values);
    values[KEY_PROTOCOL] = "https";
    values[KEY_SERVER] = keystoreServer;
    vlc_keystore_remove(keystore, values);  // the previous account
    if (!password.isEmpty())
    {
        values[KEY_USER] = user.constData();
        vlc_keystore_store(keystore, values, reinterpret_cast<const uint8_t*>(password.constData()),
                           -1, "OpenSubtitles");
    }
    vlc_keystore_release(keystore);
}

struct Login
{
    QByteArray token;
    QByteArray host;
    int allowed = 0;
    int remaining = -1;
    QString error;
};

Login login(vlc_object_t* obj, const QString& username, const QByteArray& password)
{
    Login ret;
    QJsonObject request;
    request.insert(QLatin1String("username"), username);
    request.insert(QLatin1String("password"), QString::fromUtf8(password));
    const Headers headers {
        { "Api-Key", apiKey },
        { "Content-Type", "application/json" },
        { "Accept", "application/json" },
    };
    const Response r = httpRequest(obj, "POST", QUrl(QStringLiteral("https://api.opensubtitles.com/api/v1/login")),
                                   headers, QJsonDocument(request).toJson(QJsonDocument::Compact));
    const QJsonObject answer = QJsonDocument::fromJson(r.body).object();
    if (r.status != 200 || answer.value(QLatin1String("token")).toString().isEmpty())
    {
        ret.error = (r.status == 401) ? qtr("Wrong user name or password.") : errorText(r, serverMessage(r.body));
        return ret;
    }
    ret.token = answer.value(QLatin1String("token")).toString().toUtf8();
    ret.host = answer.value(QLatin1String("base_url")).toString(QStringLiteral("api.opensubtitles.com")).toUtf8();
    ret.allowed = answer.value(QLatin1String("user")).toObject().value(QLatin1String("allowed_downloads")).toInt();

    // downloads left today
    const Response info = httpRequest(obj, "GET", QUrl(QStringLiteral("https://%1/api/v1/infos/user").arg(QString::fromUtf8(ret.host))),
                                      { { "Api-Key", apiKey }, { "Accept", "application/json" },
                                        { "Authorization", "Bearer " + ret.token } });
    if (info.status == 200)
    {
        const QJsonObject data = QJsonDocument::fromJson(info.body).object().value(QLatin1String("data")).toObject();
        ret.remaining = data.value(QLatin1String("remaining_downloads")).toInt(-1);
    }
    return ret;
}

} // namespace

// ---------------------------------------------------------------------------

struct OpenSubtitles::Job
{
    int id = 0;
    vlc_interrupt_t* interrupt = nullptr;
    std::atomic<bool> cancelled { false };
    std::atomic<vlc_tick_t> deadline { 0 };
    Session session;
    QString username;
};

OpenSubtitles::OpenSubtitles(qt_intf_t* intf, QObject* parent)
    : QObject(parent)
    , m_intf(intf)
{
    m_pool.setMaxThreadCount(2);

    // stop requests that hang
    m_watchdog.setInterval(1000);
    connect(&m_watchdog, &QTimer::timeout, this, [this]() {
        QMutexLocker locker(&m_lock);
        const vlc_tick_t now = vlc_tick_now();
        for (const auto& job : m_jobs)
        {
            const vlc_tick_t deadline = job->deadline.load();
            if (deadline != 0 && now > deadline)
                vlc_interrupt_kill(job->interrupt);
        }
    });

    loadAccount();
}

OpenSubtitles::~OpenSubtitles()
{
    {
        QMutexLocker locker(&m_lock);
        for (const auto& job : m_jobs)
        {
            job->cancelled = true;
            vlc_interrupt_kill(job->interrupt);
        }
    }
    m_pool.waitForDone();
}

bool OpenSubtitles::available() const
{
    return apiKey[0] != '\0';
}

void OpenSubtitles::loadAccount()
{
    QSettings* settings = m_intf->mainSettings;
    if (!settings)
        return;
    m_username = settings->value(QStringLiteral("OpenSubtitles/Username")).toString();
    const qint64 issued = settings->value(QStringLiteral("OpenSubtitles/TokenTime")).toLongLong();
    if (!m_username.isEmpty() && QDateTime::currentSecsSinceEpoch() - issued < tokenLifetime)
    {
        m_token = settings->value(QStringLiteral("OpenSubtitles/Token")).toByteArray();
        m_host = settings->value(QStringLiteral("OpenSubtitles/Host"), m_host).toByteArray();
    }
    m_allowed = settings->value(QStringLiteral("OpenSubtitles/Allowed")).toInt();
}

OpenSubtitles::Session OpenSubtitles::session() const
{
    return { m_host, m_token };
}

void OpenSubtitles::setRemaining(int remaining)
{
    if (remaining == m_remaining)
        return;
    m_remaining = remaining;
    emit remainingChanged();
}

int OpenSubtitles::start(std::function<void(Job&)> work)
{
    auto job = std::make_shared<Job>();
    job->interrupt = vlc_interrupt_create();
    if (!job->interrupt)
        return 0;
    job->id = ++m_lastId;
    job->session = session();
    job->username = m_username;

    {
        QMutexLocker locker(&m_lock);
        m_jobs.push_back(job);
    }
    m_watchdog.start();

    m_pool.start([this, job, work = std::move(work)]() {
        vlc_interrupt_t* previous = vlc_interrupt_set(job->interrupt);
        work(*job);
        vlc_interrupt_set(previous);

        QMutexLocker locker(&m_lock);
        m_jobs.erase(std::remove(m_jobs.begin(), m_jobs.end(), job), m_jobs.end());
        vlc_interrupt_destroy(job->interrupt);
        job->interrupt = nullptr;
    });
    return job->id;
}

void OpenSubtitles::cancel(int id)
{
    QMutexLocker locker(&m_lock);
    for (const auto& job : m_jobs)
    {
        if (job->id == id)
        {
            job->cancelled = true;
            vlc_interrupt_kill(job->interrupt);
        }
    }
}

bool OpenSubtitles::relogin(Job& job, QString* error)
{
    vlc_object_t* obj = VLC_OBJECT(m_intf);
    const QByteArray password = keystorePassword(obj, job.username);
    if (password.isEmpty())
    {
        *error = qtr("The OpenSubtitles password is missing. Sign in again in Settings > Network.");
        return false;
    }
    job.deadline = vlc_tick_now() + requestTimeout;
    const Login result = login(obj, job.username, password);
    if (result.token.isEmpty())
    {
        *error = result.error;
        return false;
    }
    job.session = { result.host, result.token };
    QMetaObject::invokeMethod(this, [this, result]() {
        m_token = result.token;
        m_host = result.host;
        m_allowed = result.allowed;
        if (QSettings* settings = m_intf->mainSettings)
        {
            settings->setValue(QStringLiteral("OpenSubtitles/Token"), m_token);
            settings->setValue(QStringLiteral("OpenSubtitles/Host"), m_host);
            settings->setValue(QStringLiteral("OpenSubtitles/TokenTime"), QDateTime::currentSecsSinceEpoch());
            settings->setValue(QStringLiteral("OpenSubtitles/Allowed"), m_allowed);
        }
        if (result.remaining >= 0)
            setRemaining(result.remaining);
        emit accountChanged();
    }, Qt::QueuedConnection);
    return true;
}

// ---- account -----------------------------------------------------------

void OpenSubtitles::signIn(const QString& username, const QString& password)
{
    const QString user = username.trimmed();
    if (!available() || m_signingIn || user.isEmpty() || password.isEmpty())
        return;
    m_signingIn = true;
    m_accountError.clear();
    emit accountChanged();

    const QByteArray secret = password.toUtf8();
    start([this, user, secret](Job& job) {
        vlc_object_t* obj = VLC_OBJECT(m_intf);
        job.deadline = vlc_tick_now() + requestTimeout;
        const Login result = login(obj, user, secret);
        if (!result.token.isEmpty())
            keystoreSet(obj, user, secret);
        if (job.cancelled)
            return;
        QMetaObject::invokeMethod(this, [this, user, result]() {
            m_signingIn = false;
            m_accountError = result.error;
            if (!result.token.isEmpty())
            {
                m_username = user;
                m_token = result.token;
                m_host = result.host;
                m_allowed = result.allowed;
                if (QSettings* settings = m_intf->mainSettings)
                {
                    settings->setValue(QStringLiteral("OpenSubtitles/Username"), m_username);
                    settings->setValue(QStringLiteral("OpenSubtitles/Token"), m_token);
                    settings->setValue(QStringLiteral("OpenSubtitles/Host"), m_host);
                    settings->setValue(QStringLiteral("OpenSubtitles/TokenTime"), QDateTime::currentSecsSinceEpoch());
                    settings->setValue(QStringLiteral("OpenSubtitles/Allowed"), m_allowed);
                }
                setRemaining(result.remaining);
            }
            emit accountChanged();
        }, Qt::QueuedConnection);
    });
}

void OpenSubtitles::signOut()
{
    const QString user = m_username;
    const Session previous = session();
    m_username.clear();
    m_token.clear();
    m_host = "api.opensubtitles.com";
    m_allowed = 0;
    m_accountError.clear();
    if (QSettings* settings = m_intf->mainSettings)
    {
        for (const char* key : { "Username", "Token", "Host", "TokenTime", "Allowed" })
            settings->remove(QStringLiteral("OpenSubtitles/") + QLatin1String(key));
    }
    setRemaining(-1);
    emit accountChanged();

    // forget the password, and end the session on the server
    start([this, user, previous](Job& job) {
        vlc_object_t* obj = VLC_OBJECT(m_intf);
        keystoreSet(obj, user, {});
        if (previous.token.isEmpty())
            return;
        job.deadline = vlc_tick_now() + requestTimeout;
        httpRequest(obj, "DELETE", QUrl(QStringLiteral("https://%1/api/v1/logout").arg(QString::fromUtf8(previous.host))),
                    { { "Api-Key", apiKey }, { "Accept", "application/json" },
                      { "Authorization", "Bearer " + previous.token } });
    });
}

// ---- languages ---------------------------------------------------------

QVariantList OpenSubtitles::languages()
{
    if (m_languages.isEmpty())
        m_languages = builtinLanguages();
    if (!m_languagesRequested && available())
        fetchLanguages();
    return m_languages;
}

void OpenSubtitles::fetchLanguages()
{
    m_languagesRequested = true;
    start([this](Job& job) {
        job.deadline = vlc_tick_now() + requestTimeout;
        const Response r = httpRequest(VLC_OBJECT(m_intf), "GET",
                                       QUrl(QStringLiteral("https://%1/api/v1/infos/languages").arg(QString::fromUtf8(job.session.host))),
                                       { { "Api-Key", apiKey }, { "Accept", "application/json" } });
        if (r.status != 200 || job.cancelled)
            return;
        QVariantList list;
        for (const QJsonValue& value : QJsonDocument::fromJson(r.body).object().value(QLatin1String("data")).toArray())
        {
            const QJsonObject entry = value.toObject();
            const QString code = entry.value(QLatin1String("language_code")).toString();
            const QString name = entry.value(QLatin1String("language_name")).toString();
            if (!code.isEmpty() && !name.isEmpty())
                list.append(QVariantMap { { QStringLiteral("code"), code }, { QStringLiteral("name"), name } });
        }
        if (list.isEmpty())
            return;
        std::sort(list.begin(), list.end(), [](const QVariant& a, const QVariant& b) {
            return a.toMap().value(QStringLiteral("name")).toString().localeAwareCompare(
                       b.toMap().value(QStringLiteral("name")).toString()) < 0;
        });
        QMetaObject::invokeMethod(this, [this, list]() {
            m_languages = list;
            emit languagesChanged();
        }, Qt::QueuedConnection);
    });
}

QString OpenSubtitles::defaultLanguage() const
{
    if (QSettings* settings = m_intf->mainSettings)
    {
        const QString saved = settings->value(QStringLiteral("OpenSubtitles/Language")).toString();
        if (!saved.isEmpty())
            return saved;
    }
    // the system's language: "pt-BR" -> "pt-br", "de-DE" -> "de". The "C"
    // locale (e.g. LANG=C.UTF-8) names no language: English then.
    QString ui;
    for (const QString& entry : QLocale::system().uiLanguages())
    {
        const QString language = entry.toLower();
        if (language.isEmpty() || language == QLatin1String("c") || language.startsWith(QLatin1String("c-"))
            || language.startsWith(QLatin1String("c."))  || language == QLatin1String("posix"))
            continue;
        ui = language;
        break;
    }
    if (ui.isEmpty())
        return QStringLiteral("en");
    if (ui.startsWith(QLatin1String("pt")))
        return ui.contains(QLatin1String("br")) ? QStringLiteral("pt-br") : QStringLiteral("pt-pt");
    if (ui.startsWith(QLatin1String("zh")))
        return (ui.contains(QLatin1String("tw")) || ui.contains(QLatin1String("hant")) || ui.contains(QLatin1String("hk")))
                 ? QStringLiteral("zh-tw") : QStringLiteral("zh-cn");
    return ui.section(QLatin1Char('-'), 0, 0);
}

void OpenSubtitles::setDefaultLanguage(const QString& code)
{
    if (QSettings* settings = m_intf->mainSettings)
        settings->setValue(QStringLiteral("OpenSubtitles/Language"), code);
}

// ---- search ------------------------------------------------------------

int OpenSubtitles::search(const QString& mediaUrl, const QString& query, const QString& language)
{
    if (!available())
        return 0;
    const QUrl url(mediaUrl);
    const QString text = query.trimmed().toLower();
    const QString lang = language.trimmed().toLower();

    return start([this, url, text, lang](Job& job) {
        const QString name = fileNameOf(url);
        const QString hash = text.isEmpty() ? movieHash(url) : QString();
        const QPair<int, int> episode = episodeOf(text.isEmpty() ? name : text);

        // parameters sorted by name, in lower case (else the server redirects)
        QString params;
        const auto add = [&](const char* key, const QString& value) {
            if (value.isEmpty())
                return;
            if (!params.isEmpty())
                params += QLatin1Char('&');
            params += QLatin1String(key) + QLatin1Char('=') + QString::fromLatin1(QUrl::toPercentEncoding(value));
        };
        add("languages", lang);
        add("moviehash", hash);
        add("query", text.isEmpty() ? queryFromFileName(name) : text);

        QUrl requestUrl(QStringLiteral("https://%1/api/v1/subtitles?%2").arg(QString::fromUtf8(job.session.host), params));
        Headers headers { { "Api-Key", apiKey }, { "Accept", "application/json" } };
        if (!job.session.token.isEmpty())
            headers.append({ "Authorization", "Bearer " + job.session.token });

        Response r;
        for (int attempt = 0; attempt < 6 && !job.cancelled; ++attempt)
        {
            job.deadline = vlc_tick_now() + requestTimeout;
            r = httpRequest(VLC_OBJECT(m_intf), "GET", requestUrl, headers);
            if ((r.status == 301 || r.status == 302 || r.status == 307 || r.status == 308) && !r.location.isEmpty())
            {
                requestUrl = requestUrl.resolved(QUrl::fromEncoded(r.location));
                continue;
            }
            if (r.status == 429 && attempt < 3)
            {
                job.deadline = 0;
                vlc_msleep_i11e(VLC_TICK_FROM_SEC(std::clamp(r.retryAfter, 1, 5)));
                continue;
            }
            break;
        }
        job.deadline = 0;
        if (job.cancelled)
            return;

        QVariantList results;
        QString error;
        if (r.status != 200)
            error = errorText(r, serverMessage(r.body));
        else
        {
            for (const QJsonValue& value : QJsonDocument::fromJson(r.body).object().value(QLatin1String("data")).toArray())
            {
                const QJsonObject attributes = value.toObject().value(QLatin1String("attributes")).toObject();
                const QJsonArray files = attributes.value(QLatin1String("files")).toArray();
                // subtitles split over several CDs don't fit one video
                if (files.size() != 1)
                    continue;
                const QJsonObject file = files.first().toObject();
                const QJsonObject feature = attributes.value(QLatin1String("feature_details")).toObject();
                const int season = feature.value(QLatin1String("season_number")).toInt();
                const int number = feature.value(QLatin1String("episode_number")).toInt();
                const bool episodeMatch = episode.second > 0 && season == episode.first && number == episode.second;
                // another episode of the same show is never the right one
                if (episode.second > 0 && number > 0 && !episodeMatch)
                    continue;

                QString release = attributes.value(QLatin1String("release")).toString();
                const QString fileName = file.value(QLatin1String("file_name")).toString();
                if (release.isEmpty())
                    release = fileName;
                results.append(QVariantMap {
                    { QStringLiteral("fileId"), file.value(QLatin1String("file_id")).toInteger() },
                    { QStringLiteral("fileName"), fileName },
                    { QStringLiteral("release"), release },
                    { QStringLiteral("language"), attributes.value(QLatin1String("language")).toString() },
                    { QStringLiteral("downloads"), attributes.value(QLatin1String("download_count")).toInteger() },
                    { QStringLiteral("hashMatch"), attributes.value(QLatin1String("moviehash_match")).toBool() },
                    { QStringLiteral("episodeMatch"), episodeMatch },
                    { QStringLiteral("hearingImpaired"), attributes.value(QLatin1String("hearing_impaired")).toBool() },
                    { QStringLiteral("trusted"), attributes.value(QLatin1String("from_trusted")).toBool() },
                    { QStringLiteral("machine"), attributes.value(QLatin1String("machine_translated")).toBool()
                                                 || attributes.value(QLatin1String("ai_translated")).toBool() },
                    { QStringLiteral("title"), feature.value(QLatin1String("movie_name")).toString(
                                                   feature.value(QLatin1String("title")).toString()) },
                });
            }
            // best first: same file (hash), same episode, people's own
            // translations, trusted uploaders, then the most downloaded
            std::stable_sort(results.begin(), results.end(), [](const QVariant& va, const QVariant& vb) {
                const QVariantMap a = va.toMap(), b = vb.toMap();
                for (const char* key : { "hashMatch", "episodeMatch" })
                {
                    const bool x = a.value(QLatin1String(key)).toBool(), y = b.value(QLatin1String(key)).toBool();
                    if (x != y)
                        return x;
                }
                const bool ma = a.value(QStringLiteral("machine")).toBool(), mb = b.value(QStringLiteral("machine")).toBool();
                if (ma != mb)
                    return !ma;
                const bool ta = a.value(QStringLiteral("trusted")).toBool(), tb = b.value(QStringLiteral("trusted")).toBool();
                if (ta != tb)
                    return ta;
                return a.value(QStringLiteral("downloads")).toLongLong() > b.value(QStringLiteral("downloads")).toLongLong();
            });
        }

        const int id = job.id;
        QMetaObject::invokeMethod(this, [this, id, results, error]() {
            emit searchFinished(id, results, error);
        }, Qt::QueuedConnection);
    });
}

// ---- download ----------------------------------------------------------

int OpenSubtitles::download(const QVariantList& items)
{
    if (!available() || items.isEmpty())
        return 0;

    return start([this, items](Job& job) {
        vlc_object_t* obj = VLC_OBJECT(m_intf);
        QVariantList saved;
        QString error;
        int done = 0;
        const int id = job.id;

        // with an account, use its quota (sign in first if needed; when that
        // fails, the download is tried without the account)
        if (!job.username.isEmpty() && job.session.token.isEmpty())
        {
            QString ignored;
            relogin(job, &ignored);
        }

        for (const QVariant& variant : items)
        {
            if (job.cancelled)
                return;
            const QVariantMap item = variant.toMap();
            const QUrl media(item.value(QStringLiteral("media")).toString());

            // 1. ask for a download link (this is what counts in the quota)
            QJsonObject request;
            request.insert(QLatin1String("file_id"), item.value(QStringLiteral("fileId")).toLongLong());
            Response r;
            bool retried = false;
            for (int attempt = 0; attempt < 4 && !job.cancelled; ++attempt)
            {
                Headers headers { { "Api-Key", apiKey }, { "Accept", "application/json" },
                                  { "Content-Type", "application/json" } };
                if (!job.session.token.isEmpty())
                    headers.append({ "Authorization", "Bearer " + job.session.token });
                job.deadline = vlc_tick_now() + requestTimeout;
                r = httpRequest(obj, "POST", QUrl(QStringLiteral("https://%1/api/v1/download").arg(QString::fromUtf8(job.session.host))),
                                headers, QJsonDocument(request).toJson(QJsonDocument::Compact));
                if (r.status == 401 && !job.username.isEmpty() && !retried)
                {
                    retried = true; // the token has expired
                    if (!relogin(job, &error))
                        break;
                    continue;
                }
                if (r.status == 429 && attempt < 3)
                {
                    job.deadline = 0;
                    vlc_msleep_i11e(VLC_TICK_FROM_SEC(std::clamp(r.retryAfter, 1, 5)));
                    continue;
                }
                break;
            }
            if (job.cancelled)
                return;
            const QJsonObject answer = QJsonDocument::fromJson(r.body).object();
            if (answer.contains(QLatin1String("remaining")))
            {
                const int remaining = answer.value(QLatin1String("remaining")).toInt();
                QMetaObject::invokeMethod(this, [this, remaining]() { setRemaining(remaining); }, Qt::QueuedConnection);
            }
            const QString link = answer.value(QLatin1String("link")).toString();
            if (r.status != 200 || link.isEmpty())
            {
                if (error.isEmpty())
                    error = (r.status == 406 || answer.value(QLatin1String("remaining")).toInt(1) <= 0)
                          ? qtr("No downloads left today. %1").arg(QString::fromUtf8(serverMessage(r.body)))
                          : errorText(r, serverMessage(r.body));
                break;
            }

            // 2. the file itself
            QUrl fileUrl(link);
            Response file;
            for (int hop = 0; hop < 5 && !job.cancelled; ++hop)
            {
                job.deadline = vlc_tick_now() + requestTimeout;
                file = httpRequest(obj, "GET", fileUrl, {});
                if ((file.status / 100) == 3 && !file.location.isEmpty())
                {
                    fileUrl = fileUrl.resolved(QUrl::fromEncoded(file.location));
                    continue;
                }
                break;
            }
            job.deadline = 0;
            if (job.cancelled)
                return;
            if (file.status != 200 || file.body.isEmpty())
            {
                error = errorText(file);
                break;
            }

            // 3. save it next to the video, "<video>.<language>.<ext>",
            //    or in VLC's data folder when that folder can't be written
            QString suffix = QFileInfo(answer.value(QLatin1String("file_name")).toString(
                                 item.value(QStringLiteral("fileName")).toString())).suffix().toLower();
            if (suffix.isEmpty() || suffix.size() > 4)
                suffix = QStringLiteral("srt");
            const QString language = item.value(QStringLiteral("language")).toString().toLower();
            const QString base = QFileInfo(fileNameOf(media)).completeBaseName();

            QStringList folders;
            if (media.isLocalFile())
                folders << QFileInfo(media.toLocalFile()).absolutePath();
            if (char* dir = config_GetUserDir(VLC_USERDATA_DIR))
            {
                folders << QDir(QString::fromUtf8(dir)).filePath(QStringLiteral("subtitles"));
                free(dir);
            }

            QString savedPath;
            for (const QString& folder : folders)
            {
                if (!QDir().mkpath(folder))
                    continue;
                const QString stem = QDir(folder).filePath(base + (language.isEmpty() ? QString() : QLatin1Char('.') + language));
                QString path = stem + QLatin1Char('.') + suffix;
                // keep other subtitles, reuse the same one downloaded before
                for (int n = 2; QFileInfo::exists(path); ++n)
                {
                    QFile existing(path);
                    if (existing.open(QIODevice::ReadOnly) && existing.readAll() == file.body)
                        break;
                    path = stem + QLatin1Char('.') + QString::number(n) + QLatin1Char('.') + suffix;
                }
                QFile out(path);
                if (out.open(QIODevice::WriteOnly | QIODevice::Truncate) && out.write(file.body) == file.body.size())
                {
                    savedPath = path;
                    break;
                }
                out.remove();
            }
            if (savedPath.isEmpty())
            {
                error = qtr("Could not save the subtitles of %1.").arg(fileNameOf(media));
                break;
            }
            saved.append(QVariantMap { { QStringLiteral("media"), media.toString() },
                                       { QStringLiteral("subtitle"), QUrl::fromLocalFile(savedPath).toString() } });

            ++done;
            const int total = items.size();
            QMetaObject::invokeMethod(this, [this, id, done, total]() {
                emit downloadProgress(id, done, total);
            }, Qt::QueuedConnection);
        }

        if (job.cancelled)
            return;
        QMetaObject::invokeMethod(this, [this, id, saved, error]() {
            emit downloadFinished(id, saved, error);
        }, Qt::QueuedConnection);
    });
}
