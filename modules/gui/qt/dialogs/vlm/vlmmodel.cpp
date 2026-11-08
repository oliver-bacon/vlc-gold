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

#include "vlmmodel.hpp"

#ifdef ENABLE_VLM
#include "vlm.hpp"
#include "dialogs/open/open.hpp"
#include "dialogs/sout/sout.hpp"
#include "util/qt_dirs.hpp"

#include <QDateTime>
#include <QFileDialog>
#endif

VlmModel::VlmModel(QObject* parent)
    : QObject(parent)
{
}

VlmModel::~VlmModel()
{
#ifdef ENABLE_VLM
    delete m_vlm;
#endif
}

void VlmModel::setCtx(MainCtx* ctx)
{
    if (m_ctx == ctx || !ctx || m_ctx)
        return;
    m_ctx = ctx;
    p_intf = ctx->getIntf();
#ifdef ENABLE_VLM
    vlm_t* p_vlm = vlm_New(vlc_object_instance(p_intf), NULL);
    if (!p_vlm)
        msg_Warn(p_intf, "Couldn't build VLM object ");
    else
        m_vlm = new VLMWrapper(p_vlm);
#endif
    emit ctxChanged();
}

#ifdef ENABLE_VLM
static QDateTime timeOf(const QVariantMap& item)
{
    return QDateTime(QDate::currentDate(),
                     QTime::fromString(item.value("time").toString(), "hh:mm:ss"));
}

static QDateTime dateOf(const QVariantMap& item)
{
    return QDateTime(QDate::fromString(item.value("date").toString(), "yyyy-MM-dd"), QTime(0, 0));
}
#endif

/* the item to VLM, as VLMBroadcast::update / VLMSchedule::update */
void VlmModel::apply(const QVariantMap& item)
{
#ifdef ENABLE_VLM
    const QString name = item.value("name").toString();
    if (item.value("type").toInt() == QVLM_Broadcast)
        m_vlm->EditBroadcast(name, item.value("input").toString(), item.value("inputOptions").toString(),
                             item.value("output").toString(), item.value("enabled").toBool(),
                             item.value("loop").toBool());
    else
        m_vlm->EditSchedule(name, item.value("input").toString(), item.value("inputOptions").toString(),
                            item.value("output").toString(), timeOf(item), dateOf(item),
                            item.value("repeat").toInt(), item.value("repeatDays").toInt(),
                            item.value("enabled").toBool());
#else
    Q_UNUSED(item);
#endif
}

QString VlmModel::add(const QVariantMap& in)
{
#ifdef ENABLE_VLM
    if (!m_vlm)
        return qtr("VLM is not available");
    QVariantMap item = in;
    const QString name = item.value("name").toString();
    if (name.isEmpty())
        return qtr("The name is empty");
    for (const QVariant& existing : m_items)
        if (existing.toMap().value("name").toString() == name)
            return qtr("This name already exists");

    QString output = item.value("output").toString();
    output.remove(":sout=");
    item["output"] = output;
    item["playing"] = 0;

    if (item.value("type").toInt() == QVLM_Broadcast)
        m_vlm->AddBroadcast(name, item.value("input").toString(), item.value("inputOptions").toString(),
                            output, item.value("enabled").toBool(), item.value("loop").toBool());
    else
        m_vlm->AddSchedule(name, item.value("input").toString(), item.value("inputOptions").toString(),
                           output, timeOf(item), dateOf(item), item.value("repeat").toInt(),
                           item.value("repeatDays").toInt(), item.value("enabled").toBool());
    m_items.append(item);
    emit itemsChanged();
    return {};
#else
    Q_UNUSED(in);
    return {};
#endif
}

void VlmModel::modify(int index, const QVariantMap& in)
{
    if (!m_vlm || index < 0 || index >= m_items.size())
        return;
    QVariantMap item = m_items[index].toMap();
    for (const QString& key : { "input", "inputOptions", "output", "enabled", "loop",
                                "time", "date", "repeat", "repeatDays" })
        if (in.contains(key))
            item[key] = in.value(key);
    QString output = item.value("output").toString();
    output.remove(":sout=");
    item["output"] = output;
    m_items[index] = item;
    apply(item);
    emit itemsChanged();
}

void VlmModel::remove(int index)
{
#ifdef ENABLE_VLM
    if (!m_vlm || index < 0 || index >= m_items.size())
        return;
    m_vlm->DeleteItem(m_items[index].toMap().value("name").toString());
    m_items.removeAt(index);
    emit itemsChanged();
#else
    Q_UNUSED(index);
#endif
}

void VlmModel::setEnabled(int index, bool enabled)
{
#ifdef ENABLE_VLM
    if (!m_vlm || index < 0 || index >= m_items.size())
        return;
    QVariantMap item = m_items[index].toMap();
    item["enabled"] = enabled;
    m_items[index] = item;
    m_vlm->EnableItem(item.value("name").toString(), enabled);
    emit itemsChanged();
#else
    Q_UNUSED(index); Q_UNUSED(enabled);
#endif
}

void VlmModel::playPause(int index)
{
#ifdef ENABLE_VLM
    if (!m_vlm || index < 0 || index >= m_items.size())
        return;
    QVariantMap item = m_items[index].toMap();
    const int playing = item.value("playing").toInt();
    m_vlm->ControlBroadcast(item.value("name").toString(),
                            playing == 1 ? ControlBroadcastPause : ControlBroadcastPlay);
    item["playing"] = playing == 1 ? 2 : 1;
    m_items[index] = item;
    emit itemsChanged();
#else
    Q_UNUSED(index);
#endif
}

void VlmModel::stop(int index)
{
#ifdef ENABLE_VLM
    if (!m_vlm || index < 0 || index >= m_items.size())
        return;
    QVariantMap item = m_items[index].toMap();
    m_vlm->ControlBroadcast(item.value("name").toString(), ControlBroadcastStop);
    item["playing"] = 0;
    m_items[index] = item;
    emit itemsChanged();
#else
    Q_UNUSED(index);
#endif
}

void VlmModel::toggleLoop(int index)
{
    if (!m_vlm || index < 0 || index >= m_items.size())
        return;
    QVariantMap item = m_items[index].toMap();
    item["loop"] = !item.value("loop").toBool();
    m_items[index] = item;
    apply(item);
    emit itemsChanged();
}

QVariantMap VlmModel::selectInput()
{
#ifdef ENABLE_VLM
    if (!p_intf)
        return {};
    QWindow* parentWindow = p_intf->p_mi ? p_intf->p_mi->intfMainWindow() : nullptr;
    OpenDialog o( p_intf, parentWindow );
    o.setActionFlag(OpenDialog::SELECT);
    o.exec();
    return { { "mrl", o.getMRL( false ) }, { "options", o.getOptions() } };
#else
    return {};
#endif
}

QString VlmModel::selectOutput()
{
#ifdef ENABLE_VLM
    if (!p_intf)
        return {};
    QWindow* parentWindow = p_intf->p_mi ? p_intf->p_mi->intfMainWindow() : nullptr;
    SoutDialog s( parentWindow, p_intf );
    if( s.exec() != QDialog::Accepted )
        return {};
    const int i = s.getChain().indexOf( " " );
    return s.getChain().left( i );
#else
    return {};
#endif
}

bool VlmModel::exportConfig()
{
#ifdef ENABLE_VLM
    if (!m_vlm)
        return false;
    const QString fileName = QFileDialog::getSaveFileName( nullptr,
                                        qtr( "Save VLM configuration as..." ),
                                        QVLCUserDir( VLC_DOCUMENTS_DIR ),
                                        qtr( "VLM conf (*.vlm);;All (*)" ) );
    if( fileName.isEmpty() )
        return false;
    m_vlm->SaveConfig( fileName );
    return true;
#else
    return false;
#endif
}

bool VlmModel::importConfig()
{
#ifdef ENABLE_VLM
    if (!m_vlm)
        return false;
    const QString fileName = toNativeSeparators( QFileDialog::getOpenFileName(
            nullptr, qtr( "Open VLM configuration..." ),
            QVLCUserDir( VLC_DOCUMENTS_DIR ),
            qtr( "VLM conf (*.vlm);;All (*)" ) ) );
    if( fileName.isEmpty() )
        return false;
    if( !m_vlm->LoadConfig( fileName ) )
    {
        msg_Warn( p_intf, "Failed to import vlm configuration file : %s", qtu( fileName ) );
        return false;
    }

    /* as VLMDialog::mediasPopulator: every media as a broadcast */
    vlm_media_t** pp_dsc;
    const int count = m_vlm->GetMedias( pp_dsc );
    for( int i = 0; i < count; i++ )
    {
        const QString name = qfu( pp_dsc[i]->psz_name );
        bool known = false;
        for (const QVariant& existing : m_items)
            known |= existing.toMap().value("name").toString() == name;
        if (known)
            continue;
        m_items.append(QVariantMap {
            { "name", name },
            { "type", (int)QVLM_Broadcast },
            { "input", pp_dsc[i]->i_input > 0 ? qfu( pp_dsc[i]->ppsz_input[0] ) : QString() },
            { "inputOptions", QString() },
            { "output", qfu( pp_dsc[i]->psz_output ) },
            { "enabled", pp_dsc[i]->b_enabled },
            { "loop", pp_dsc[i]->broadcast.b_loop },
            { "playing", 0 },
            { "time", QTime::currentTime().toString("hh:mm:ss") },
            { "date", QDate::currentDate().toString("yyyy-MM-dd") },
            { "repeat", 0 },
            { "repeatDays", 0 }
        });
    }
    for( int i = 0; i < count; i++ )
        vlm_media_Delete( pp_dsc[i] );
    free( pp_dsc );
    emit itemsChanged();
    return true;
#else
    return false;
#endif
}
