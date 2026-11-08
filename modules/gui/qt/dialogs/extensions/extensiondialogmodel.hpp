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
#ifndef VLC_QT_EXTENSIONDIALOGMODEL_HPP
#define VLC_QT_EXTENSIONDIALOGMODEL_HPP

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <QAbstractListModel>
#include <QVector>

#include "qt.hpp"

extern "C" {
    typedef struct extension_dialog_t extension_dialog_t;
    struct extension_widget_t;
};

/**
 * A dialog of a Lua extension for the redesign (ExtensionWindow.qml): its
 * widgets as rows, placed on a grid as the classic ExtensionDialog
 * (extensions.cpp) does, and the user's input written back the same way
 * (under the dialog lock: text, check state, selection, clicks).
 * Created and updated by ExtensionsDialogProvider with the lock held.
 */
class ExtensionDialogModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(QString title READ getTitle NOTIFY dialogChanged FINAL)
    // !b_hide of the dialog
    Q_PROPERTY(bool shown READ isShown NOTIFY dialogChanged FINAL)
    Q_PROPERTY(int widthHint READ getWidthHint NOTIFY dialogChanged FINAL)
    Q_PROPERTY(int heightHint READ getHeightHint NOTIFY dialogChanged FINAL)

public:
    enum Roles {
        TypeRole = Qt::UserRole + 1, // "label", "button", "image", "html", "text",
                                     // "password", "dropdown", "list", "check", "spin"
        TextRole,
        CheckedRole,
        // [{ id, text, selected }]
        ValuesRole,
        RowRole,
        ColumnRole,
        RowSpanRole,
        ColumnSpanRole,
        WidthRole,
        HeightRole,
        HiddenRole,
        // spinning icon: loops to play (-1 forever, 0 stopped)
        SpinRole
    };

    ExtensionDialogModel(qt_intf_t* p_intf, extension_dialog_t* p_dialog);
    ~ExtensionDialogModel() override;

    QString getTitle() const { return m_title; }
    bool isShown() const { return m_shown; }
    int getWidthHint() const { return m_widthHint; }
    int getHeightHint() const { return m_heightHint; }

    int rowCount(const QModelIndex& parent = {}) const override;
    QVariant data(const QModelIndex& index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    // reads the dialog and its widgets (p_dialog->lock held)
    void update();
    // the dialog is killed (lock held): forget it, the window goes away
    void detach();
    // the caller holds p_dialog->lock (while the window is created)
    void setLocked(bool locked) { m_hasLock = locked; }

    Q_INVOKABLE void click(int row);
    Q_INVOKABLE void setText(int row, const QString& text);
    Q_INVOKABLE void setChecked(int row, bool checked);
    // drop-down: the picked value; list: the selected values
    Q_INVOKABLE void select(int row, const QVariantList& valueIds);
    // the user closed the window
    Q_INVOKABLE void close();

signals:
    void dialogChanged();
    // the dialog is gone (detach)
    void killed();

private:
    struct Entry {
        extension_widget_t* widget;
        int row;
        int column;
        QVariantMap state;
    };

    static QVariantMap readState(const extension_widget_t* widget);
    int indexOf(const extension_widget_t* widget) const;
    // locks p_dialog->lock unless update() holds it
    bool lock();
    void unlock(bool locked);

    qt_intf_t* p_intf;
    extension_dialog_t* p_dialog;
    bool m_hasLock = false;

    QString m_title;
    bool m_shown = false;
    int m_widthHint = 0;
    int m_heightHint = 0;
    QVector<Entry> m_entries;
    int m_rowCount = 0;
    int m_columnCount = 0;
};

#endif
