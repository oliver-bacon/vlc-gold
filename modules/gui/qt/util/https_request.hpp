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
#ifndef VLC_QT_HTTPS_REQUEST_HPP
#define VLC_QT_HTTPS_REQUEST_HPP

#include <QByteArray>
#include <QList>
#include <QPair>
#include <QUrl>

#include "qt.hpp"

// VLC's Windows Qt has no network module: HTTPS over VLC's own TLS
// (vlc_tls). Used by OpenSubtitles and the update check.

struct HttpsResponse
{
    int status = 0;          // 0: no answer (connection failed or stopped)
    QByteArray body;
    QByteArray location;
    int retryAfter = 0;
};

using HttpsHeaders = QList<QPair<QByteArray, QByteArray>>;

/// One HTTPS/1.1 request ("Connection: close", no compression). Blocks:
/// call it from a worker thread; a vlc_interrupt stops it.
HttpsResponse httpsRequest(vlc_object_t* obj, const QByteArray& method, const QUrl& url,
                           const HttpsHeaders& headers, const QByteArray& body,
                           const QByteArray& userAgent);

#endif // VLC_QT_HTTPS_REQUEST_HPP
