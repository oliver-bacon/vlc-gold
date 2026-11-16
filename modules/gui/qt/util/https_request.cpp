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

#include "https_request.hpp"

#include <QList>

#include <vlc_common.h>
#include <vlc_interrupt.h>
#include <vlc_tls.h>

namespace {

bool writeAll(vlc_tls_t* tls, const QByteArray& data)
{
    return vlc_tls_Write(tls, data.constData(), data.size()) == data.size();
}

QByteArray readLine(vlc_tls_t* tls, bool* ok)
{
    char* line = vlc_tls_GetLine(tls);
    *ok = (line != nullptr);
    const QByteArray ret(line ? line : "");
    free(line);
    return ret;
}

bool readBytes(vlc_tls_t* tls, QByteArray& out, qint64 count)
{
    constexpr qint64 maxBody = 16 * 1024 * 1024;
    if (count < 0 || out.size() + count > maxBody)
        return false;
    const qsizetype start = out.size();
    out.resize(start + count);
    return vlc_tls_Read(tls, out.data() + start, count, true) == count;
}

} // namespace

HttpsResponse httpsRequest(vlc_object_t* obj, const QByteArray& method, const QUrl& url,
                           const HttpsHeaders& headers, const QByteArray& body,
                           const QByteArray& userAgent)
{
    HttpsResponse response;
    if (url.scheme() != QLatin1String("https") || url.host().isEmpty())
        return response;

    vlc_tls_client_t* creds = vlc_tls_ClientCreate(obj);
    if (!creds)
        return response;

    const QByteArray host = url.host(QUrl::FullyEncoded).toLatin1();
    static const char* const alpn[] = { "http/1.1", nullptr };
    vlc_tls_t* tls = vlc_tls_SocketOpenTLS(creds, host.constData(), url.port(443),
                                           "https", alpn, nullptr);
    if (!tls)
    {
        vlc_tls_ClientDelete(creds);
        return response;
    }

    QByteArray target = url.path(QUrl::FullyEncoded).toLatin1();
    if (target.isEmpty())
        target = "/";
    if (url.hasQuery())
        target += '?' + url.query(QUrl::FullyEncoded).toLatin1();

    QByteArray request = method + ' ' + target + " HTTP/1.1\r\n"
                       + "Host: " + host + "\r\n"
                       + "User-Agent: " + userAgent + "\r\n"
                       + "Connection: close\r\n";
    for (const auto& header : headers)
        request += header.first + ": " + header.second + "\r\n";
    if (!body.isEmpty() || method == "POST")
        request += "Content-Length: " + QByteArray::number(body.size()) + "\r\n";
    request += "\r\n" + body;

    bool ok = writeAll(tls, request);
    QByteArray line = ok ? readLine(tls, &ok) : QByteArray();
    // "HTTP/1.1 200 OK"
    const QList<QByteArray> statusLine = line.split(' ');
    const int status = (ok && statusLine.size() >= 2 && line.startsWith("HTTP/"))
                     ? statusLine[1].toInt() : 0;

    qint64 contentLength = -1;
    bool chunked = false;
    while (ok && status > 0)
    {
        line = readLine(tls, &ok);
        if (!ok || line.isEmpty())
            break;
        const int colon = line.indexOf(':');
        if (colon <= 0)
            continue;
        const QByteArray name = line.left(colon).trimmed().toLower();
        const QByteArray value = line.mid(colon + 1).trimmed();
        if (name == "content-length")
            contentLength = value.toLongLong();
        else if (name == "transfer-encoding")
            chunked = value.toLower().contains("chunked");
        else if (name == "location")
            response.location = value;
        else if (name == "retry-after")
            response.retryAfter = value.toInt();
    }

    if (ok && status > 0 && method != "HEAD" && status != 204 && status != 304)
    {
        if (chunked)
        {
            for (;;)
            {
                line = readLine(tls, &ok);
                const qint64 size = ok ? line.split(';').first().trimmed().toLongLong(&ok, 16) : 0;
                if (!ok || size == 0 || !readBytes(tls, response.body, size))
                    break;
                readLine(tls, &ok); // CRLF after the chunk
                if (!ok)
                    break;
            }
        }
        else if (contentLength >= 0)
        {
            ok = readBytes(tls, response.body, contentLength);
        }
        else
        {
            char buffer[16384];
            ssize_t n;
            while ((n = vlc_tls_Read(tls, buffer, sizeof(buffer), false)) > 0
                   && response.body.size() < 16 * 1024 * 1024)
                response.body.append(buffer, n);
        }
    }

    vlc_tls_Close(tls);
    vlc_tls_ClientDelete(creds);

    if (ok || status > 0)
        response.status = vlc_killed() ? 0 : status;
    return response;
}
