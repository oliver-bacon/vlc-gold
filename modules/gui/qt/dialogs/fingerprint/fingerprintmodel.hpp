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
#ifndef VLC_QT_FINGERPRINTMODEL_HPP
#define VLC_QT_FINGERPRINTMODEL_HPP

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <QObject>
#include <QVariant>

#include "qt.hpp"
#include "util/shared_input_item.hpp"

class Chromaprint;
extern "C" {
    typedef struct fingerprint_request_t fingerprint_request_t;
};

/**
 * Audio fingerprinting of the redesign's Media Information window, as the
 * classic FingerprintDialog: fingerprints an item (Chromaprint), lists the
 * matching identities, applies the picked one to the item.
 */
class FingerprintModel : public QObject
{
    Q_OBJECT

    // Idle, Working ("Fingerprinting track..."), Results, NotFound
    Q_PROPERTY(State state READ getState NOTIFY stateChanged FINAL)
    // { title, artist, link } of each identity
    Q_PROPERTY(QVariantList results READ getResults NOTIFY stateChanged FINAL)

public:
    enum State { Idle, Working, Results, NotFound };
    Q_ENUM(State)

    explicit FingerprintModel(QObject* parent = nullptr);
    ~FingerprintModel() override;

    State getState() const { return m_state; }
    QVariantList getResults() const { return m_results; }

    void start(qt_intf_t* p_intf, input_item_t* item);

    // applies the identity at `index` to the item
    Q_INVOKABLE void apply(int index);
    // drops the results ("Discard all identities", Close)
    Q_INVOKABLE void discard();

signals:
    void stateChanged();
    void applied(const SharedInputItem& item);

private:
    void handleResults();
    void cleanup();
    void setState(State state);

    State m_state = Idle;
    QVariantList m_results;
    Chromaprint* m_chromaprint = nullptr;
    fingerprint_request_t* m_request = nullptr;
};

#endif
