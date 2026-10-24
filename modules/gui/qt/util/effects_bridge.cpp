/*****************************************************************************
 * Copyright (C) 2026 the VideoLAN team
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

#include "effects_bridge.hpp"

#include <QSettings>
#include <QStringList>

#include <algorithm>

#include <vlc_common.h>
#include <vlc_aout.h>
#include <vlc_configuration.h>
#include <vlc_player.h>
#include <vlc_vout.h>

#include "player/player_controller.hpp"
#include "playlist/playlist_controller.hpp"
#include "../../../audio_filter/equalizer_presets.h"

namespace {

QStringList chainOf(const char* option)
{
    char* psz = config_GetPsz(option);
    const QStringList list = qfu(psz ? psz : "").split(':', Qt::SkipEmptyParts);
    free(psz);
    return list;
}

/* sets a variable on a live object, with the type of the variable (or of
 * the config option when the object does not have it yet: then the variable
 * is created only with create, otherwise nothing is set) */
void setVar(vlc_object_t* obj, const char* name, const QVariant& value, bool create)
{
    int type = var_Type(obj, name);
    if (type == 0)
    {
        if (!create)
            return;
        type = config_GetType(name);
    }
    switch (type & VLC_VAR_CLASS)
    {
    case VLC_VAR_BOOL:    var_Create(obj, name, VLC_VAR_BOOL);    var_SetBool(obj, name, value.toBool()); break;
    case VLC_VAR_INTEGER: var_Create(obj, name, VLC_VAR_INTEGER); var_SetInteger(obj, name, value.toLongLong()); break;
    case VLC_VAR_FLOAT:   var_Create(obj, name, VLC_VAR_FLOAT);   var_SetFloat(obj, name, value.toFloat()); break;
    case VLC_VAR_STRING:  var_Create(obj, name, VLC_VAR_STRING);  var_SetString(obj, name, qtu(value.toString())); break;
    default: break;
    }
}

/* sets a filter option on a vout; the vout has the variable only while a
 * filter with that option runs (the filter creates it, as a command
 * variable that forwards to the filter). It must not be created here: the
 * vout only removes that forwarding from command variables, so on the next
 * filter chain change (a filter on/off, deinterlacing switching on or off
 * during playback) the forwarding would stay and point to the deleted
 * filter, and the next set would crash. The filter reads the option from
 * the config when it starts. */
void setVoutVar(vout_thread_t* vout, const char* name, const QVariant& value)
{
    setVar(VLC_OBJECT(vout), name, value, false);
}

QVariant getVar(vlc_object_t* obj, const char* name)
{
    switch (var_Type(obj, name) & VLC_VAR_CLASS)
    {
    case VLC_VAR_BOOL:    return var_GetBool(obj, name);
    case VLC_VAR_INTEGER: return QVariant::fromValue<qint64>(var_GetInteger(obj, name));
    case VLC_VAR_FLOAT:   return var_GetFloat(obj, name);
    case VLC_VAR_STRING:
    {
        char* psz = var_GetString(obj, name);
        const QString str = qfu(psz ? psz : "");
        free(psz);
        return str;
    }
    default: return {};
    }
}

QVariant getConfig(const char* name)
{
    switch (config_GetType(name) & VLC_VAR_CLASS)
    {
    case VLC_VAR_BOOL:    return config_GetInt(name) != 0;
    case VLC_VAR_INTEGER: return QVariant::fromValue<qint64>(config_GetInt(name));
    case VLC_VAR_FLOAT:   return config_GetFloat(name);
    case VLC_VAR_STRING:
    {
        char* psz = config_GetPsz(name);
        const QString str = qfu(psz ? psz : "");
        free(psz);
        return str;
    }
    default: return {};
    }
}

} // namespace

EffectsBridge::EffectsBridge(qt_intf_t* intf, QObject* parent)
    : QObject(parent)
    , m_intf(intf)
{
    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(800);
    connect(&m_saveTimer, &QTimer::timeout, this, [this]() {
        config_SaveConfigFile(m_intf);
    });

    m_sleepTimer.setSingleShot(true);
    connect(&m_sleepTimer, &QTimer::timeout, this, [this]() {
        m_intf->p_mainPlaylistController->pause();
        m_sleepMinutes = 0;
        emit sleepTimerChanged();
    });
}

void EffectsBridge::setSleepTimer(int minutes)
{
    m_sleepMinutes = std::max(0, minutes);
    if (m_sleepMinutes == 0)
        m_sleepTimer.stop();
    else
        m_sleepTimer.start(m_sleepMinutes * 60 * 1000);
    emit sleepTimerChanged();
}

void EffectsBridge::scheduleSave()
{
    m_saveTimer.start();
    emit changed();
}

void EffectsBridge::putConfig(const QString& option, const QVariant& value)
{
    const QByteArray name = option.toUtf8();
    switch (config_GetType(name.constData()) & VLC_VAR_CLASS)
    {
    case VLC_VAR_BOOL:    config_PutInt(name.constData(), value.toBool() ? 1 : 0); break;
    case VLC_VAR_INTEGER: config_PutInt(name.constData(), value.toLongLong()); break;
    case VLC_VAR_FLOAT:   config_PutFloat(name.constData(), value.toFloat()); break;
    case VLC_VAR_STRING:  config_PutPsz(name.constData(), qtu(value.toString())); break;
    default: return;
    }
    scheduleSave();
}

bool EffectsBridge::audioFilterEnabled(const QString& module) const
{
    return chainOf("audio-filter").contains(module);
}

void EffectsBridge::setAudioFilterEnabled(const QString& module, bool enabled)
{
    QStringList list = chainOf("audio-filter");
    if (enabled == list.contains(module))
        return;
    if (enabled)
        list.append(module);
    else
        list.removeAll(module);
    putConfig(QStringLiteral("audio-filter"), list.join(':'));
    vlc_player_aout_EnableFilter(m_intf->p_player, qtu(module), enabled);
}

bool EffectsBridge::videoFilterEnabled(const QString& module) const
{
    return chainOf("video-filter").contains(module);
}

void EffectsBridge::setVideoFilterEnabled(const QString& module, bool enabled)
{
    QStringList list = chainOf("video-filter");
    if (enabled == list.contains(module))
        return;
    if (enabled)
        list.append(module);
    else
        list.removeAll(module);
    applyVideoFilters(list, false);
}

void EffectsBridge::applyVideoFilters(const QStringList& filters, bool restart)
{
    // rotate and transform (flip) go last: transform changes the orientation
    // of the picture format, and the filters after it would get a different
    // input and output format (the Direct3D11 ones then refuse to load)
    QStringList list = filters;
    for (const QString& name : { QStringLiteral("rotate"), QStringLiteral("transform") })
        if (list.removeAll(name) > 0)
            list.append(name);

    const QString chain = list.join(':');
    putConfig(QStringLiteral("video-filter"), chain);
    for (const auto& vout : m_intf->p_mainPlayerController->getVouts())
    {
        // the vout only rebuilds its filters when the chain changes: an
        // empty chain first makes filters read their options again
        if (restart)
            var_SetString(vout.get(), "video-filter", "");
        var_SetString(vout.get(), "video-filter", qtu(chain));
    }
}

QString EffectsBridge::filterChain(bool audio) const
{
    return chainOf(audio ? "audio-filter" : "video-filter").join(':');
}

void EffectsBridge::setFilterChain(bool audio, const QString& chain)
{
    const QStringList list = chain.split(':', Qt::SkipEmptyParts);
    if (!audio)
    {
        applyVideoFilters(list, true);
        return;
    }
    putConfig(QStringLiteral("audio-filter"), list.join(':'));
    // the audio output rebuilds its filters when the variable is set
    if (SharedAOut aout = m_intf->p_mainPlayerController->getAout())
        var_SetString(aout.get(), "audio-filter", qtu(list.join(':')));
}

QVariant EffectsBridge::audioValue(const QString& option) const
{
    const QByteArray name = option.toUtf8();
    if (SharedAOut aout = m_intf->p_mainPlayerController->getAout())
        if (var_Type(aout.get(), name.constData()) != 0)
            return getVar(VLC_OBJECT(aout.get()), name.constData());
    return getConfig(name.constData());
}

void EffectsBridge::setAudioValue(const QString& option, const QVariant& value)
{
    const QByteArray name = option.toUtf8();
    if (SharedAOut aout = m_intf->p_mainPlayerController->getAout())
        setVar(VLC_OBJECT(aout.get()), name.constData(), value, true);
    putConfig(option, value);
}

void EffectsBridge::applyAudioFilter(const QString& module, bool enabled)
{
    vlc_player_aout_EnableFilter(m_intf->p_player, qtu(module), enabled);
    emit changed();
}

void EffectsBridge::applyAudioValue(const QString& option, const QVariant& value)
{
    const QByteArray name = option.toUtf8();
    if (SharedAOut aout = m_intf->p_mainPlayerController->getAout())
        setVar(VLC_OBJECT(aout.get()), name.constData(), value, true);
    emit changed();
}

QVariant EffectsBridge::videoValue(const QString& option) const
{
    const QByteArray name = option.toUtf8();
    if (SharedVOutThread vout = m_intf->p_mainPlayerController->getVout())
        if (var_Type(vout.get(), name.constData()) != 0)
            return getVar(VLC_OBJECT(vout.get()), name.constData());
    return getConfig(name.constData());
}

void EffectsBridge::setVideoValue(const QString& option, const QVariant& value)
{
    const QByteArray name = option.toUtf8();
    for (const auto& vout : m_intf->p_mainPlayerController->getVouts())
        setVoutVar(vout.get(), name.constData(), value);
    putConfig(option, value);
}

QVariantList EffectsBridge::equalizerPresets() const
{
    QVariantList ret;
    for (int i = 0; i < NB_PRESETS; ++i)
        ret.append(QVariantMap {
            { QStringLiteral("name"), qfu(preset_list[i]) },
            { QStringLiteral("text"), qfut(preset_list_text[i]) },
        });
    return ret;
}

QVariantMap EffectsBridge::applyEqualizerPreset(const QString& name)
{
    for (int i = 0; i < NB_PRESETS; ++i)
    {
        if (name != qfu(preset_list[i]))
            continue;
        const eqz_preset_t& preset = eqz_preset_10b[i];
        QVariantList bands;
        QStringList text;
        for (int b = 0; b < preset.i_band && b < EQZ_BANDS_MAX; ++b)
        {
            bands.append(preset.f_amp[b]);
            text.append(QString::number(preset.f_amp[b], 'f', 1));
        }
        setAudioValue(QStringLiteral("equalizer-preamp"), preset.f_preamp);
        setAudioValue(QStringLiteral("equalizer-bands"), text.join(' '));
        setAudioValue(QStringLiteral("equalizer-preset"), name);
        return { { QStringLiteral("preamp"), preset.f_preamp }, { QStringLiteral("bands"), bands } };
    }
    return {};
}

QVariantList EffectsBridge::equalizerBands() const
{
    QVariantList ret;
    const QStringList bands = audioValue(QStringLiteral("equalizer-bands")).toString()
                                  .split(' ', Qt::SkipEmptyParts);
    for (int b = 0; b < EQZ_BANDS_MAX; ++b)
        ret.append(b < bands.size() ? bands[b].toDouble() : 0.0);
    return ret;
}

void EffectsBridge::setEqualizerBand(int band, double gain)
{
    if (band < 0 || band >= EQZ_BANDS_MAX)
        return;
    QStringList text;
    const QVariantList bands = equalizerBands();
    for (int b = 0; b < EQZ_BANDS_MAX; ++b)
        text.append(QString::number(b == band ? gain : bands[b].toDouble(), 'f', 1));
    setAudioValue(QStringLiteral("equalizer-bands"), text.join(' '));
}

void EffectsBridge::setCrop(int top, int bottom, int left, int right)
{
    for (const auto& vout : m_intf->p_mainPlayerController->getVouts())
    {
        var_SetInteger(vout.get(), "crop-top", top);
        var_SetInteger(vout.get(), "crop-bottom", bottom);
        var_SetInteger(vout.get(), "crop-left", left);
        var_SetInteger(vout.get(), "crop-right", right);
    }
}

namespace {

/* "transform-type" for a flip of the picture as shown after a clockwise
 * rotation by a multiple of 90 degrees (index: flip * 4 + angle / 90) */
const char* const kTransformTypes[] = {
    "",      "90",            "180",   "270",
    "hflip", "transpose",     "vflip", "antitranspose",
    "vflip", "antitranspose", "hflip", "transpose",
};

} // namespace

QVariantMap EffectsBridge::orientation() const
{
    const QStringList list = chainOf("video-filter");
    const QString type = list.contains(QStringLiteral("transform"))
                             ? getConfig("transform-type").toString() : QString();
    const int rest = list.contains(QStringLiteral("rotate"))
                         ? qRound(-getConfig("rotate-angle").toDouble()) : 0;

    // the values chosen in the panel, when the filters still match them
    // (a flip with a rotation has two names, e.g. transpose)
    QSettings* const settings = m_intf->mainSettings;
    const int savedFlip = settings ? settings->value(QStringLiteral("Player/VideoFlip"), 0).toInt() : -1;
    const int savedAngle = settings ? settings->value(QStringLiteral("Player/VideoRotate"), 0).toInt() : -1;
    if (savedFlip >= 0 && savedFlip <= 2 && savedAngle >= 0 && savedAngle < 360
        && type == QLatin1String(kTransformTypes[savedFlip * 4 + savedAngle / 90])
        && rest == savedAngle % 90)
        return { { QStringLiteral("flip"), savedFlip }, { QStringLiteral("angle"), savedAngle } };

    for (int i = 0; i < 12; ++i)
        if (type == QLatin1String(kTransformTypes[i]))
            return { { QStringLiteral("flip"), i / 4 },
                     { QStringLiteral("angle"), ((i % 4) * 90 + rest + 360) % 360 } };
    return { { QStringLiteral("flip"), 0 }, { QStringLiteral("angle"), (rest + 360) % 360 } };
}

void EffectsBridge::setOrientation(int flip, int angle)
{
    flip = std::clamp(flip, 0, 2);
    angle = ((angle % 360) + 360) % 360;
    if (QSettings* const settings = m_intf->mainSettings)
    {
        settings->setValue(QStringLiteral("Player/VideoFlip"), flip);
        settings->setValue(QStringLiteral("Player/VideoRotate"), angle);
    }

    // flips and multiples of 90 degrees only change the orientation of the
    // picture (applied when it is shown, after the pixel filters); the rest
    // goes to the rotate filter (counter-clockwise, in place: corners are cut)
    const char* type = kTransformTypes[flip * 4 + angle / 90];
    const int rest = angle % 90;

    QStringList list = chainOf("video-filter");
    list.removeAll(QStringLiteral("transform"));
    list.removeAll(QStringLiteral("rotate"));
    if (rest != 0)
    {
        putConfig(QStringLiteral("rotate-angle"), -rest);
        list.append(QStringLiteral("rotate"));
    }
    if (*type)
    {
        putConfig(QStringLiteral("transform-type"), QString::fromLatin1(type));
        list.append(QStringLiteral("transform"));
    }
    for (const auto& vout : m_intf->p_mainPlayerController->getVouts())
    {
        if (rest != 0)
            setVoutVar(vout.get(), "rotate-angle", -rest);
        if (*type)
            setVoutVar(vout.get(), "transform-type", QString::fromLatin1(type));
    }
    applyVideoFilters(list, true);
}
