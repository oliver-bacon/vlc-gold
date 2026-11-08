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

#include "v4l2controls.hpp"

#include <vlc_common.h>
#include <vlc_modules.h>
#include <vlc_player.h>
#include <vlc_variables.h>

#include <climits>

V4l2Controls::V4l2Controls(QObject* parent)
    : QObject(parent)
{
}

void V4l2Controls::setCtx(MainCtx* ctx)
{
    if (m_ctx == ctx || !ctx || m_ctx)
        return;
    m_ctx = ctx;
    p_intf = ctx->getIntf();
    emit ctxChanged();
}

bool V4l2Controls::isAvailable() const
{
    return module_exists("v4l2");
}

QVariantMap V4l2Controls::read() const
{
    if (!p_intf)
        return { { "found", false } };

    QVariantList controls;
    bool found = false;

    vlc_player_Lock(p_intf->p_player);
    vlc_object_t* obj = vlc_player_GetV4l2Object(p_intf->p_player);
    if (obj)
    {
        vlc_value_t* val;
        char** text;
        size_t count;
        if (var_Change(obj, "controls", VLC_VAR_GETCHOICES, &count, &val, &text) < 0)
            msg_Err(p_intf, "Oops, v4l2 object doesn't have a 'controls' variable.");
        else
        {
            found = true;
            for (size_t i = 0; i < count; i++)
            {
                char* vartext;
                char* var = text[i];
                QString name;
                if (!var_Change(obj, var, VLC_VAR_GETTEXT, &vartext))
                {
                    name = qfut(vartext);
                    free(vartext);
                }
                else
                    name = qfu(var);

                QVariantMap control { { "name", qfu(var) }, { "text", name } };
                const int type = var_Type(obj, var);
                switch (type & VLC_VAR_TYPE)
                {
                case VLC_VAR_INTEGER:
                {
                    const int64_t value = var_GetInteger(obj, var);
                    control["value"] = (qlonglong)value;
                    if (type & VLC_VAR_HASCHOICE)
                    {
                        vlc_value_t* val2;
                        char** text2;
                        size_t count2;
                        QVariantList choices;
                        if (!var_Change(obj, var, VLC_VAR_GETCHOICES, &count2, &val2, &text2))
                        {
                            for (size_t j = 0; j < count2; j++)
                            {
                                choices.append(QVariantMap {
                                    { "value", (qlonglong)val2[j].i_int },
                                    { "text", qfu(text2[j]) }
                                });
                                free(text2[j]);
                            }
                            free(text2);
                            free(val2);
                        }
                        control["kind"] = "choice";
                        control["choices"] = choices;
                    }
                    else
                    {
                        vlc_value_t val2;
                        var_Change(obj, var, VLC_VAR_GETMIN, &val2);
                        control["min"] = (qlonglong)std::max<int64_t>(val2.i_int, INT_MIN);
                        var_Change(obj, var, VLC_VAR_GETMAX, &val2);
                        control["max"] = (qlonglong)std::min<int64_t>(val2.i_int, INT_MAX);
                        control["step"] = !var_Change(obj, var, VLC_VAR_GETSTEP, &val2)
                                          ? (qlonglong)val2.i_int : 1;
                        control["kind"] = "int";
                    }
                    break;
                }
                case VLC_VAR_BOOL:
                    control["kind"] = "bool";
                    control["value"] = var_GetBool(obj, var);
                    break;
                case VLC_VAR_VOID:
                    control["kind"] = (type & VLC_VAR_ISCOMMAND) ? "button" : "label";
                    break;
                default:
                    msg_Warn(p_intf, "Unhandled var type for %s", var);
                    free(var);
                    continue;
                }
                controls.append(control);
                free(var);
            }
            free(text);
            free(val);
        }
    }
    else
        msg_Dbg(p_intf, "Couldn't find v4l2 instance");
    vlc_player_Unlock(p_intf->p_player);

    return { { "found", found }, { "controls", controls } };
}

/* as ExtV4l2::ValueChange */
void V4l2Controls::setValue(const QString& name, const QVariant& value)
{
    if (!p_intf)
        return;
    vlc_player_Lock(p_intf->p_player);
    vlc_object_t* obj = vlc_player_GetV4l2Object(p_intf->p_player);
    if (obj)
    {
        const QByteArray var = name.toUtf8();
        const int type = var_Type(obj, var.constData());
        switch (type & VLC_VAR_TYPE)
        {
        case VLC_VAR_INTEGER:
            var_SetInteger(obj, var.constData(), value.toLongLong());
            break;
        case VLC_VAR_BOOL:
            var_SetBool(obj, var.constData(), value.toBool());
            break;
        case VLC_VAR_VOID:
            var_TriggerCallback(obj, var.constData());
            break;
        default:
            msg_Warn(p_intf, "Oops, %s, %s %d", __FILE__, __func__, __LINE__);
        }
    }
    else
        msg_Warn(p_intf, "Oops, %s, %s %d", __FILE__, __func__, __LINE__);
    vlc_player_Unlock(p_intf->p_player);
}
