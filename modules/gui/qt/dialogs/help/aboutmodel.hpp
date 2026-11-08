/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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
#ifndef ABOUTMODEL_HPP
#define ABOUTMODEL_HPP

#include <QObject>
#include <QtQml>

#include "qt.hpp"

#include <vlc_about.h>
#include <vlc_intf_strings.h>
#include "config.h"

class AboutModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString license READ getLicense CONSTANT FINAL)
    Q_PROPERTY(QString authors READ getAuthors CONSTANT FINAL)
    Q_PROPERTY(QString thanks  READ getThanks  CONSTANT FINAL)
    Q_PROPERTY(QString version  READ getVersion  CONSTANT FINAL)
    Q_PROPERTY(QString vlcVersion READ getVlcVersion CONSTANT FINAL)
    // shown when the version is clicked in the About window
    Q_PROPERTY(QString compiledBy READ getCompiledBy CONSTANT FINAL)
    // text of the Help window (HTML)
    Q_PROPERTY(QString help READ getHelp CONSTANT FINAL)

    QML_ELEMENT
    QML_UNCREATABLE("AboutModel is meant to be a singleton.")
    QML_SINGLETON

public:
    explicit AboutModel(QObject *parent = nullptr)
        : QObject(parent)
    { }

    static AboutModel *create(class QQmlEngine *, class QJSEngine *)
    {
        return new AboutModel;
    }

    static QString getLicense()
    {
        return QString::fromUtf8(psz_license);
    }

    static QString getAuthors()
    {
        return QString::fromUtf8(psz_authors);
    }

    static QString getThanks()
    {
        return QString::fromUtf8(psz_thanks);
    }

    static QString getVersion()
    {
        return QString::fromUtf8(GOLD_VERSION);
    }

    static QString getVlcVersion()
    {
        return QString::fromUtf8(VERSION);
    }

    static QString getCompiledBy()
    {
        return qfu( VLC_CompileBy() ) + "@" + qfu( VLC_CompileHost() )
            + " " + __DATE__ + " " + __TIME__;
    }

    static QString getHelp()
    {
        return qfut( I_LONGHELP );
    }
};

#endif // ABOUTMODEL_HPP
