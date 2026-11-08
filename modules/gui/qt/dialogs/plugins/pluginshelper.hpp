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
#ifndef VLC_QT_PLUGINSHELPER_HPP
#define VLC_QT_PLUGINSHELPER_HPP

#include <QObject>
#include <QPointer>
#include <QTemporaryDir>
#include <QVariant>

#include <memory>

#include "qt.hpp"
#include "maininterface/mainctx.hpp"

/**
 * What the "Plugins and extensions" window of the redesign
 * (PluginsWindow.qml) needs besides AddonsModel, as the classic dialog
 * (plugins.cpp): the modules (name, capability, score) and the active
 * extensions with their details. The extension icons are written to a
 * temporary folder (no data: images in VLC's Windows Qt).
 */
class PluginsHelper : public QObject
{
    Q_OBJECT

    Q_PROPERTY(MainCtx* ctx READ getCtx WRITE setCtx NOTIFY ctxChanged FINAL)
    // { title, summary, version, author, url, file, icon }
    Q_PROPERTY(QVariantList extensions READ getExtensions NOTIFY extensionsChanged FINAL)

public:
    explicit PluginsHelper(QObject* parent = nullptr);
    ~PluginsHelper() override;

    MainCtx* getCtx() const { return m_ctx; }
    void setCtx(MainCtx* ctx);

    QVariantList getExtensions() const { return m_extensions; }

    // { name, capability, score } of every module with a capability
    Q_INVOKABLE QVariantList plugins() const;
    Q_INVOKABLE void reloadExtensions();

signals:
    void ctxChanged();
    void extensionsChanged();

private:
    void updateExtensions();

    QPointer<MainCtx> m_ctx;
    qt_intf_t* p_intf = nullptr;
    QVariantList m_extensions;
    std::unique_ptr<QTemporaryDir> m_iconDir;
    int m_iconGeneration = 0;
};

#endif
