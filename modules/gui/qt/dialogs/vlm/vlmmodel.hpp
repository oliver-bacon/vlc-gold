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
#ifndef VLC_QT_VLMMODEL_HPP
#define VLC_QT_VLMMODEL_HPP

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <QObject>
#include <QPointer>
#include <QVariant>

#include <memory>

#include "qt.hpp"
#include "maininterface/mainctx.hpp"

class VLMWrapper;

/**
 * The VLM (VideoLAN Manager) media of the redesign's VLM window
 * (VlmWindow.qml), as the classic VLM dialog (dialogs/vlm): broadcasts and
 * schedules added, changed, controlled, imported and exported.
 */
class VlmModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(MainCtx* ctx READ getCtx WRITE setCtx NOTIFY ctxChanged FINAL)
    // the VLM object could be created
    Q_PROPERTY(bool available READ isAvailable NOTIFY ctxChanged FINAL)
    // { name, type (0 broadcast, 1 schedule), input, inputOptions, output,
    //   enabled, loop, playing (0 stopped, 1 playing, 2 paused), time
    //   "hh:mm:ss", date "yyyy-MM-dd", repeat, repeatDays }
    Q_PROPERTY(QVariantList items READ getItems NOTIFY itemsChanged FINAL)

public:
    explicit VlmModel(QObject* parent = nullptr);
    ~VlmModel() override;

    MainCtx* getCtx() const { return m_ctx; }
    void setCtx(MainCtx* ctx);
    bool isAvailable() const { return m_vlm != nullptr; }
    QVariantList getItems() const { return m_items; }

    // adds an item (same keys as `items`); "" or why not
    Q_INVOKABLE QString add(const QVariantMap& item);
    // changes the item at `index` (not its name nor type)
    Q_INVOKABLE void modify(int index, const QVariantMap& item);
    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void setEnabled(int index, bool enabled);
    Q_INVOKABLE void playPause(int index);
    Q_INVOKABLE void stop(int index);
    Q_INVOKABLE void toggleLoop(int index);

    // the classic Open dialog to pick the input: { mrl, options } or {}
    Q_INVOKABLE QVariantMap selectInput();
    // the classic Stream dialog to pick the output: the chain or ""
    Q_INVOKABLE QString selectOutput();

    Q_INVOKABLE bool exportConfig();
    Q_INVOKABLE bool importConfig();

signals:
    void ctxChanged();
    void itemsChanged();

private:
    void apply(const QVariantMap& item);

    QPointer<MainCtx> m_ctx;
    qt_intf_t* p_intf = nullptr;
    VLMWrapper* m_vlm = nullptr;
    QVariantList m_items;
};

#endif
