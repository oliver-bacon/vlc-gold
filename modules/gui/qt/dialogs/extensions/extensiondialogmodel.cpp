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

#include "extensiondialogmodel.hpp"

#include <vlc_extensions.h>

#include <QUrl>

#include <algorithm>

ExtensionDialogModel::ExtensionDialogModel(qt_intf_t* intf, extension_dialog_t* dialog)
    : QAbstractListModel(nullptr)
    , p_intf(intf)
    , p_dialog(dialog)
{
    assert(p_dialog);
    msg_Dbg(p_intf, "Creating a new dialog: '%s'", p_dialog->psz_title);
    p_dialog->p_sys_intf = static_cast<QObject*>(this);
}

ExtensionDialogModel::~ExtensionDialogModel()
{
    if (p_dialog)
    {
        p_dialog->p_sys_intf = nullptr;
        vlc_cond_signal(&p_dialog->cond);
    }
}

void ExtensionDialogModel::detach()
{
    if (!p_dialog)
        return;
    msg_Dbg(p_intf, "Deleting extension dialog '%s'", qtu(m_title));
    for (const Entry& entry : m_entries)
        entry.widget->p_sys_intf = nullptr;
    p_dialog->p_sys_intf = nullptr;
    vlc_cond_signal(&p_dialog->cond);
    p_dialog = nullptr;
    beginResetModel();
    m_entries.clear();
    endResetModel();
    emit killed();
}

static QString typeName(int type)
{
    switch (type)
    {
    case EXTENSION_WIDGET_LABEL:      return QStringLiteral("label");
    case EXTENSION_WIDGET_BUTTON:     return QStringLiteral("button");
    case EXTENSION_WIDGET_IMAGE:      return QStringLiteral("image");
    case EXTENSION_WIDGET_HTML:       return QStringLiteral("html");
    case EXTENSION_WIDGET_TEXT_FIELD: return QStringLiteral("text");
    case EXTENSION_WIDGET_PASSWORD:   return QStringLiteral("password");
    case EXTENSION_WIDGET_DROPDOWN:   return QStringLiteral("dropdown");
    case EXTENSION_WIDGET_LIST:       return QStringLiteral("list");
    case EXTENSION_WIDGET_CHECK_BOX:  return QStringLiteral("check");
    case EXTENSION_WIDGET_SPIN_ICON:  return QStringLiteral("spin");
    default:                          return {};
    }
}

QVariantMap ExtensionDialogModel::readState(const extension_widget_t* widget)
{
    QVariantList values;
    for (auto value = widget->p_values; value != nullptr; value = value->p_next)
        values.append(QVariantMap {
            { "id", value->i_id },
            { "text", qfu(value->psz_text) },
            { "selected", value->b_selected }
        });

    QString text = qfu(widget->psz_text);
    /* images: a local path or URI */
    if (widget->type == EXTENSION_WIDGET_IMAGE && !text.isEmpty() && !text.contains("://"))
        text = QUrl::fromLocalFile(text).toString();

    return {
        { "type", typeName(widget->type) },
        { "text", text },
        { "checked", widget->b_checked },
        { "values", values },
        { "width", widget->i_width },
        { "height", widget->i_height },
        { "hidden", widget->b_hide },
        { "spin", widget->i_spin_loops },
        { "rowSpan", std::max(1, widget->i_vert_span) },
        { "columnSpan", std::max(1, widget->i_horiz_span) }
    };
}

int ExtensionDialogModel::indexOf(const extension_widget_t* widget) const
{
    for (int i = 0; i < m_entries.size(); ++i)
        if (m_entries[i].widget == widget)
            return i;
    return -1;
}

/* as ExtensionDialog::UpdateWidgets */
void ExtensionDialogModel::update()
{
    assert(p_dialog);
    vlc_mutex_assert(&p_dialog->lock);
    m_hasLock = true;

    const QString title = qfu(p_dialog->psz_title);
    const bool shown = !p_dialog->b_hide;
    if (title != m_title || shown != m_shown
        || m_widthHint != p_dialog->i_width || m_heightHint != p_dialog->i_height)
    {
        m_title = title;
        m_shown = shown;
        m_widthHint = p_dialog->i_width;
        m_heightHint = p_dialog->i_height;
        emit dialogChanged();
    }

    extension_widget_t* widget;
    ARRAY_FOREACH(widget, p_dialog->widgets)
    {
        if (!widget)
            continue; /* Some widgets may be NULL at this point */

        if (!widget->p_sys_intf && !widget->b_kill)
        {
            if (typeName(widget->type).isEmpty())
            {
                msg_Err(p_intf, "Widget type %d unknown", widget->type);
                continue;
            }
            /* the grid place, as the classic QGridLayout */
            int row = widget->i_row - 1;
            int column = widget->i_column - 1;
            if (row < 0)
            {
                row = m_rowCount;
                column = 0;
            }
            else if (column < 0)
                column = m_columnCount;
            const QVariantMap state = readState(widget);
            m_rowCount = std::max(m_rowCount, row + state.value("rowSpan").toInt());
            m_columnCount = std::max(m_columnCount, column + state.value("columnSpan").toInt());

            beginInsertRows({}, m_entries.size(), m_entries.size());
            m_entries.push_back({ widget, row, column, state });
            endInsertRows();

            widget->p_sys_intf = static_cast<QObject*>(this);
            /* If an update was required, cancel it as we just created the widget */
            widget->b_update = false;
        }
        else if (widget->p_sys_intf && !widget->b_kill && widget->b_update)
        {
            const int i = indexOf(widget);
            if (i >= 0)
            {
                m_entries[i].state = readState(widget);
                emit dataChanged(index(i), index(i));
            }
            /* Do not update again */
            widget->b_update = false;
        }
        else if (widget->p_sys_intf && widget->b_kill)
        {
            const int i = indexOf(widget);
            if (i >= 0)
            {
                beginRemoveRows({}, i, i);
                m_entries.removeAt(i);
                endRemoveRows();
            }
            widget->p_sys_intf = nullptr;
            vlc_cond_signal(&p_dialog->cond);
        }
    }
    m_hasLock = false;
}

int ExtensionDialogModel::rowCount(const QModelIndex& parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant ExtensionDialogModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() >= m_entries.size())
        return {};
    const Entry& entry = m_entries[index.row()];
    switch (role)
    {
    case TypeRole:       return entry.state.value("type");
    case TextRole:       return entry.state.value("text");
    case CheckedRole:    return entry.state.value("checked");
    case ValuesRole:     return entry.state.value("values");
    case RowRole:        return entry.row;
    case ColumnRole:     return entry.column;
    case RowSpanRole:    return entry.state.value("rowSpan");
    case ColumnSpanRole: return entry.state.value("columnSpan");
    case WidthRole:      return entry.state.value("width");
    case HeightRole:     return entry.state.value("height");
    case HiddenRole:     return entry.state.value("hidden");
    case SpinRole:       return entry.state.value("spin");
    default:             return {};
    }
}

QHash<int, QByteArray> ExtensionDialogModel::roleNames() const
{
    return {
        { TypeRole, "widgetType" },
        { TextRole, "widgetText" },
        { CheckedRole, "checked" },
        { ValuesRole, "values" },
        { RowRole, "gridRow" },
        { ColumnRole, "gridColumn" },
        { RowSpanRole, "rowSpan" },
        { ColumnSpanRole, "columnSpan" },
        { WidthRole, "widthHint" },
        { HeightRole, "heightHint" },
        { HiddenRole, "hidden" },
        { SpinRole, "spinLoops" }
    };
}

bool ExtensionDialogModel::lock()
{
    if (m_hasLock)
        return false;
    vlc_mutex_lock(&p_dialog->lock);
    m_hasLock = true;
    return true;
}

void ExtensionDialogModel::unlock(bool locked)
{
    if (!locked)
        return;
    m_hasLock = false;
    vlc_mutex_unlock(&p_dialog->lock);
}

void ExtensionDialogModel::click(int row)
{
    if (!p_dialog || row < 0 || row >= m_entries.size())
        return;
    const bool locked = lock();
    extension_widget_t* widget = m_entries[row].widget;
    if (widget->type == EXTENSION_WIDGET_BUTTON)
        extension_WidgetClicked(p_dialog, widget);
    else
        msg_Dbg(p_intf, "A click event was triggered by a wrong widget");
    unlock(locked);
}

void ExtensionDialogModel::setText(int row, const QString& text)
{
    if (!p_dialog || row < 0 || row >= m_entries.size())
        return;
    const bool locked = lock();
    extension_widget_t* widget = m_entries[row].widget;
    if (widget->type == EXTENSION_WIDGET_TEXT_FIELD || widget->type == EXTENSION_WIDGET_PASSWORD)
    {
        /* Synchronize psz_text with the new value */
        free(widget->psz_text);
        widget->psz_text = text.isNull() ? nullptr : strdup(qtu(text));
        m_entries[row].state["text"] = text;
    }
    unlock(locked);
}

void ExtensionDialogModel::setChecked(int row, bool checked)
{
    if (!p_dialog || row < 0 || row >= m_entries.size())
        return;
    const bool locked = lock();
    extension_widget_t* widget = m_entries[row].widget;
    if (widget->type == EXTENSION_WIDGET_CHECK_BOX)
    {
        widget->b_checked = checked;
        m_entries[row].state["checked"] = checked;
    }
    unlock(locked);
}

void ExtensionDialogModel::select(int row, const QVariantList& valueIds)
{
    if (!p_dialog || row < 0 || row >= m_entries.size())
        return;
    const bool locked = lock();
    extension_widget_t* widget = m_entries[row].widget;
    QString picked;
    QVariantList values;
    for (auto value = widget->p_values; value != nullptr; value = value->p_next)
    {
        value->b_selected = valueIds.contains(value->i_id);
        if (value->b_selected && picked.isNull())
            picked = qfu(value->psz_text);
        values.append(QVariantMap {
            { "id", value->i_id },
            { "text", qfu(value->psz_text) },
            { "selected", value->b_selected }
        });
    }
    /* the drop-down's text is the picked value */
    if (widget->type == EXTENSION_WIDGET_DROPDOWN)
    {
        free(widget->psz_text);
        widget->psz_text = strdup(qtu(picked));
        m_entries[row].state["text"] = picked;
    }
    m_entries[row].state["values"] = values;
    unlock(locked);
}

void ExtensionDialogModel::close()
{
    if (!p_dialog)
        return;
    msg_Dbg(p_intf, "Dialog '%s' received a closeEvent", qtu(m_title));
    extension_DialogClosed(p_dialog);
}
