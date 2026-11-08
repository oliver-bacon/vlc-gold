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

#include "pluginshelper.hpp"
#include "dialogs/extensions/extensions_manager.hpp"

#include <QImage>
#include <QUrl>

#include <vlc_modules.h>
#include <vlc_extensions.h>

PluginsHelper::PluginsHelper(QObject* parent)
    : QObject(parent)
{
}

PluginsHelper::~PluginsHelper() = default;

void PluginsHelper::setCtx(MainCtx* ctx)
{
    if (m_ctx == ctx || !ctx || m_ctx)
        return;
    m_ctx = ctx;
    p_intf = ctx->getIntf();

    ExtensionsManager* manager = ExtensionsManager::getInstance(p_intf);
    connect(manager, &ExtensionsManager::extensionsUpdated, this, &PluginsHelper::updateExtensions);
    /* Load extensions now if not already loaded (ExtensionListModel) */
    if (!manager->isLoaded())
        manager->loadExtensions();
    updateExtensions();

    emit ctxChanged();
}

QVariantList PluginsHelper::plugins() const
{
    QVariantList out;
    size_t count;
    module_t** list = module_list_get(&count);
    for (size_t i = 0; i < count; i++)
    {
        module_t* module = list[i];
        const QString capability = qfu(module_get_capability(module));
#ifndef DEBUG
        if (capability.isEmpty())
            continue;
#endif
        out.append(QVariantMap {
            { "name", qfu(module_GetLongName(module)) },
            { "capability", capability },
            { "score", module_get_score(module) }
        });
    }
    module_list_free(list);
    return out;
}

void PluginsHelper::reloadExtensions()
{
    if (p_intf)
        ExtensionsManager::getInstance(p_intf)->reloadExtensions();
}

void PluginsHelper::updateExtensions()
{
    m_extensions.clear();

    extensions_manager_t* mgr = p_intf ? ExtensionsManager::getInstance(p_intf)->getManager() : nullptr;
    if (mgr)
    {
        if (!m_iconDir)
            m_iconDir = std::make_unique<QTemporaryDir>();
        ++m_iconGeneration;

        vlc_mutex_lock(&mgr->lock);
        extension_t* ext;
        int index = 0;
        ARRAY_FOREACH(ext, mgr->extensions)
        {
            /* as ExtensionListModel::ExtensionCopy */
            QString description = qfu(ext->psz_description);
            QString shortdesc = qfu(ext->psz_shortdescription);
            if (description.isEmpty())
                description = shortdesc;
            if (shortdesc.isEmpty() && !description.isEmpty())
                shortdesc = description;

            QString icon = QStringLiteral("qrc:///logo/vlc48.png");
            if (ext->p_icondata && ext->i_icondata_size > 0 && m_iconDir->isValid())
            {
                QImage image;
                if (image.loadFromData((const uchar*)ext->p_icondata, (uint)ext->i_icondata_size))
                {
                    const QString path = m_iconDir->filePath(
                        QString("ext-%1-%2.png").arg(m_iconGeneration).arg(index));
                    if (image.save(path, "PNG"))
                        icon = QUrl::fromLocalFile(path).toString();
                }
            }

            m_extensions.append(QVariantMap {
                { "title", qfu(ext->psz_title) },
                { "summary", shortdesc },
                { "version", qfu(ext->psz_version) },
                { "author", qfu(ext->psz_author) },
                { "url", qfu(ext->psz_url) },
                { "file", qfu(ext->psz_name) },
                { "icon", icon }
            });
            ++index;
        }
        vlc_mutex_unlock(&mgr->lock);
    }
    emit extensionsChanged();
}
