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
#ifndef VLC_QT_EFFECTS_BRIDGE_HPP
#define VLC_QT_EFFECTS_BRIDGE_HPP

#include <QObject>
#include <QTimer>
#include <QVariant>

#include "qt.hpp"

/**
 * Audio and video effects for the player settings panel of the VLC
 * Redesign Figma file (Equalizer, Compressor, Spatializer, Stereo Widener,
 * Essential / Crop / Colors video filters).
 *
 * Values are applied live to the current audio output / video outputs,
 * like VLC's "Adjustments and Effects" dialog does, and saved to the
 * configuration so that they are kept for the next media.
 */
class EffectsBridge : public QObject
{
    Q_OBJECT

    /// sleep timer of the player settings panel: minutes, 0 when off
    Q_PROPERTY(int sleepMinutes READ sleepMinutes NOTIFY sleepTimerChanged FINAL)

public:
    explicit EffectsBridge(qt_intf_t* intf, QObject* parent = nullptr);
    ~EffectsBridge() override;

    /// audio filter modules ("equalizer", "compressor"...)
    Q_INVOKABLE bool audioFilterEnabled(const QString& module) const;
    Q_INVOKABLE void setAudioFilterEnabled(const QString& module, bool enabled);
    /// video filter modules ("adjust", "sharpen", "invert"...)
    Q_INVOKABLE bool videoFilterEnabled(const QString& module) const;
    Q_INVOKABLE void setVideoFilterEnabled(const QString& module, bool enabled);
    /// whole filter chains ("module:module"), for the presets of the panel
    Q_INVOKABLE QString filterChain(bool audio) const;
    Q_INVOKABLE void setFilterChain(bool audio, const QString& chain);

    /// filter options: current value (live object first, then config)
    Q_INVOKABLE QVariant audioValue(const QString& option) const;
    Q_INVOKABLE void setAudioValue(const QString& option, const QVariant& value);
    // only on the audio output that is playing, not saved (the settings
    // window saves the option itself)
    Q_INVOKABLE void applyAudioFilter(const QString& module, bool enabled);
    Q_INVOKABLE void applyAudioValue(const QString& option, const QVariant& value);
    Q_INVOKABLE QVariant videoValue(const QString& option) const;
    Q_INVOKABLE void setVideoValue(const QString& option, const QVariant& value);

    /// equalizer presets: list of { name, text }; applying one returns
    /// { preamp, bands: [10 values] }
    Q_INVOKABLE QVariantList equalizerPresets() const;
    Q_INVOKABLE QVariantMap applyEqualizerPreset(const QString& name);
    /// the 10 band gains, from the "equalizer-bands" string
    Q_INVOKABLE QVariantList equalizerBands() const;
    Q_INVOKABLE void setEqualizerBand(int band, double gain);

    int sleepMinutes() const { return m_sleepMinutes; }
    /// pauses playback after this many minutes (0 turns the timer off)
    Q_INVOKABLE void setSleepTimer(int minutes);

    /// crop in pixels of the current video (not saved, like VLC's dialog)
    Q_INVOKABLE void setCrop(int top, int bottom, int left, int right);

    /// flip (0 none, 1 horizontal, 2 vertical) and clockwise rotation in
    /// degrees, as { flip, angle }; saved, through the "transform" and
    /// "rotate" video filters
    Q_INVOKABLE QVariantMap orientation() const;
    Q_INVOKABLE void setOrientation(int flip, int angle);

    /// "Test" of the stereo mode: a tone on the left, then on the right
    /// channel, through a player of its own (the saved stereo mode applies)
    Q_INVOKABLE void testStereo();

signals:
    void changed();
    void sleepTimerChanged();

private:
    void putConfig(const QString& option, const QVariant& value);
    void scheduleSave();
    void applyVideoFilters(const QStringList& list, bool restart);

    void stopStereoTest();

    qt_intf_t* m_intf;
    struct vlc_player_t* m_testPlayer = nullptr;
    struct vlc_player_listener_id* m_testListener = nullptr;
    QTimer m_saveTimer;
    QTimer m_sleepTimer;
    int m_sleepMinutes = 0;
};

#endif // VLC_QT_EFFECTS_BRIDGE_HPP
