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
#ifndef VLC_QT_V4L2CONTROLS_HPP
#define VLC_QT_V4L2CONTROLS_HPP

#include <QObject>
#include <QPointer>
#include <QVariant>

#include "qt.hpp"
#include "maininterface/mainctx.hpp"

/**
 * The "v4l2 controls" of the redesigned Effects and Filters window, as the
 * classic ExtV4l2 (extended_panels.cpp): the controls of the playing v4l2
 * device (sliders, choices, check boxes, buttons) and their changes.
 */
class V4l2Controls : public QObject
{
    Q_OBJECT

    Q_PROPERTY(MainCtx* ctx READ getCtx WRITE setCtx NOTIFY ctxChanged FINAL)
    // the v4l2 module exists (the tab is shown)
    Q_PROPERTY(bool available READ isAvailable CONSTANT FINAL)

public:
    explicit V4l2Controls(QObject* parent = nullptr);

    MainCtx* getCtx() const { return m_ctx; }
    void setCtx(MainCtx* ctx);
    bool isAvailable() const;

    // { found, controls: [{ name, text, kind ("int", "choice", "bool",
    //   "button", "label"), value, min, max, step, choices: [{ value, text }] }] }
    Q_INVOKABLE QVariantMap read() const;
    // sets a control (an int, a bool; nothing for a button)
    Q_INVOKABLE void setValue(const QString& name, const QVariant& value);

signals:
    void ctxChanged();

private:
    QPointer<MainCtx> m_ctx;
    qt_intf_t* p_intf = nullptr;
};

#endif
