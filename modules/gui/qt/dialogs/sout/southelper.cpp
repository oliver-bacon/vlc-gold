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

#include "southelper.hpp"
#include "profile_selector.hpp"
#include "util/soutchain.hpp"
#include "util/qt_dirs.hpp"
#include "playlist/playlist_controller.hpp"

#include <QComboBox>
#include <QFileDialog>
#include <QRegularExpression>
#include <QSettings>
#include <QUrl>

#include <vlc_intf_strings.h>
#include <vlc_modules.h>

SoutHelper::SoutHelper(QObject* parent)
    : QObject(parent)
{
}

SoutHelper::~SoutHelper()
{
    /* saves the selected profile, as the classic selector */
    delete m_selector;
}

void SoutHelper::setCtx(MainCtx* ctx)
{
    if (m_ctx == ctx || !ctx || m_ctx)
        return;
    m_ctx = ctx;
    p_intf = ctx->getIntf();

    m_selector = new VLCProfileSelector(nullptr);
    m_selector->hide();
    connect(m_selector, &VLCProfileSelector::optionsChanged, this, [this]() {
        emit profilesChanged();
        emit profileChanged();
    });
    /* nothing chosen yet (first use): the first profile instead of an empty
     * box, which would convert without a format */
    if (QComboBox* box = combo(); box && box->currentIndex() < 0 && box->count() > 0)
    {
        box->setCurrentIndex(0);
        QMetaObject::invokeMethod(m_selector, "updateOptions", Q_ARG(int, 0));
    }
    emit ctxChanged();
    emit profilesChanged();
    emit profileChanged();
}

QComboBox* SoutHelper::combo() const
{
    return m_selector ? m_selector->findChild<QComboBox*>() : nullptr;
}

QVariantList SoutHelper::getProfiles() const
{
    QVariantList out;
    if (QComboBox* box = combo())
        for (int i = 0; i < box->count(); ++i)
            out.append(QVariantMap {
                { "name", box->itemText(i) },
                { "value", box->itemData(i).toString() }
            });
    return out;
}

int SoutHelper::getCurrentProfile() const
{
    QComboBox* box = combo();
    return box ? box->currentIndex() : -1;
}

void SoutHelper::setCurrentProfile(int index)
{
    QComboBox* box = combo();
    if (!box || index < 0 || index >= box->count())
        return;
    box->setCurrentIndex(index);
    /* as QComboBox::activated in the classic selector */
    QMetaObject::invokeMethod(m_selector, "updateOptions", Q_ARG(int, index));
    saveSelected();
    emit profileChanged();
}

void SoutHelper::saveSelected() const
{
    if (QComboBox* box = combo())
    {
        QSettings settings(
#ifdef _WIN32
                QSettings::IniFormat,
#else
                QSettings::NativeFormat,
#endif
                QSettings::UserScope, "vlc", "vlc-qt-interface" );
        settings.setValue( "codecs-profiles-selected", box->currentText() );
    }
}

QString SoutHelper::getMux() const
{
    return m_selector ? m_selector->getMux() : QString();
}

QString SoutHelper::getTranscode() const
{
    return m_selector ? m_selector->getTranscode().to_string() : QString();
}

void SoutHelper::newProfile()
{
    if (m_selector)
        QMetaObject::invokeMethod(m_selector, "newProfile");
}

void SoutHelper::editProfile()
{
    if (m_selector)
        QMetaObject::invokeMethod(m_selector, "editProfile");
}

void SoutHelper::deleteProfile()
{
    if (!m_selector)
        return;
    QMetaObject::invokeMethod(m_selector, "deleteProfile");
    if (QComboBox* box = combo())
        QMetaObject::invokeMethod(m_selector, "updateOptions", Q_ARG(int, qMax(box->currentIndex(), 0)));
    emit profilesChanged();
    emit profileChanged();
}

QString SoutHelper::destinationChain(const QString& type, const QVariantMap& f) const
{
    const QString mux = getMux();
    const QString address = f.value("address").toString();
    const int port = f.value("port").toInt();
    const QString name = f.value("name").toString();
    SoutChain m;

    if (type == "file")
    {
        /* FileDestBox */
        if (f.value("path").toString().isEmpty()) return "";
        m.begin( "file" );
        QString outputfile = f.value("path").toString();
        if( !mux.isEmpty() )
        {
            if( outputfile.contains( QRegularExpression(QStringLiteral("\\..{2,4}$"))) &&
                !outputfile.endsWith(mux) )
                outputfile.replace(QRegularExpression(QStringLiteral("\\..{2,4}$")),"."+mux);
            else if (!outputfile.endsWith( mux ) )
                m.option( "mux", mux );
        }
        m.option( "dst", outputfile );
        m.option( "no-overwrite" );
        m.end();
    }
    else if (type == "http")
    {
        /* HTTPDestBox */
        QString path = f.value("path").toString();
        if( path.isEmpty() ) return "";
        if( path[0] != '/' )
            path.prepend( qfu("/") );
        const QString dst = ":" + QString::number( port ) + path;
        m.begin( "http" );
        if ( !path.contains(QRegularExpression(QStringLiteral("\\..{2,3}$")) ) )
        {
            if( !mux.isEmpty() && mux.compare("mp4") )
               m.option( "mux", mux );
            else
               m.option( "mux", "ffmpeg{mux=flv}" );
        }
        m.option( "dst", dst );
        m.end();
    }
    else if (type == "mmsh")
    {
        /* MMSHDestBox */
        if( address.isEmpty() ) return "";
        m.begin( "std" );
        m.option( "access", "mmsh" );
        m.option( "mux", "asfh" );
        m.option( "dst", address, port );
        m.end();
    }
    else if (type == "rtsp")
    {
        /* RTSPDestBox */
        QString path = f.value("path").toString();
        if( path.isEmpty() ) return "";
        if( path[0] != '/' )
            path.prepend( qfu("/") );
        m.begin( "rtp" );
        m.option( "sdp", "rtsp://:" + QString::number( port ) + path );
        m.end();
    }
    else if (type == "srt")
    {
        /* SRTDestBox, TS */
        if (address.isEmpty()) return "";
        m.begin( "srt" );
        m.option( "dst", address + ":" + QString::number( port ) );
        m.option( "mux", "ts" );
        if (!name.isEmpty()) {
            m.option( "sap" );
            m.option( "name", name );
        }
        m.end();
    }
    else if (type == "rist")
    {
        /* RISTDestBox */
        if( address.isEmpty() ) return "";
        m.begin( "std" );
        m.option( "access", name.isEmpty() ? QString("rist") : "rist{cname=" + name + "}" );
        m.option( "mux", "ts" );
        m.option( "dst", address + ":" + QString::number( port ) );
        m.end();
    }
    else if (type == "rtp-ts" || type == "rtp-avp")
    {
        /* RTPDestBox: TS, or the RTP audio/video profile without a muxer */
        if( address.isEmpty() ) return "";
        m.begin( "rtp" );
        m.option( "dst", address );
        m.option( "port", port );
        if( type == "rtp-ts" )
            m.option( "mux", "ts" );
        if( !name.isEmpty() )
        {
            m.option( "sap" );
            m.option( "name", name );
        }
        m.end();
    }
    else if (type == "udp")
    {
        /* UDPDestBox */
        if( address.isEmpty() ) return "";
        m.begin( "udp" );
        if( !mux.isEmpty() && !mux.compare("ts" ) )
            m.option( "mux", mux );
        m.option( "dst", address, port );
        m.end();
    }
    else if (type == "icecast")
    {
        /* ICEDestBox */
        if( address.isEmpty() ) return "";
        m.begin( "std" );
        m.option( "access", "shout" );
        m.option( "mux", "ogg" );
        m.option( "dst", "//" + f.value("password").toString() + "@" + address
                         + ":" + QString::number( port, 10 )
                         + "/" + f.value("mount").toString() );
        m.end();
    }
    else
        return "";
    return m.to_string();
}

QString SoutHelper::streamChain(const QStringList& destinations, bool transcode,
                                bool displayLocally, bool allStreams) const
{
    /* SoutDialog::updateChain; destinations = the "tabs" after the first */
    SoutChain smrl( ":sout=#" );
    const QString transcodeChain = getTranscode();
    if( !transcodeChain.isEmpty() && transcode )
    {
        smrl.begin( transcodeChain );
        smrl.end();
    }

    const int tabs = destinations.size() + 1;
    const bool multi = tabs >= 3 || ( tabs == 2 && displayLocally );
    if( multi )
        smrl.begin( "duplicate" );
    for( const QString& dest : destinations )
    {
        if( dest.isEmpty() ) continue;
        if( multi )
            smrl.option( "dst", dest, true );
        else
        {
            smrl.begin( dest );
            smrl.end();
        }
    }
    if( displayLocally )
    {
        if( multi )
            smrl.option( "dst", "display" );
        else
        {
            smrl.begin( "display" );
            smrl.end();
        }
    }
    if ( multi ) smrl.end();

    QString chain = smrl.to_string();
    chain.append( allStreams ? " :sout-all" : " :no-sout-all" );
    chain.append( " :sout-keep" );
    return chain;
}

QVariantMap SoutHelper::describeSource(const QString& mrl) const
{
    /* SoutInputBox::setMRL */
    QUrl uri( mrl );
    QString type = uri.scheme();
    if( !uri.isValid() && !mrl.startsWith("http") && !mrl.startsWith("ftp") && !mrl.startsWith("/") )
    {
        const int pos = mrl.indexOf("://");
        return { { "text", mrl }, { "type", pos != -1 ? mrl.left( pos ) : QString() } };
    }
    if ( type == "window" )
        return { { "text", mrl }, { "type", type } };
    if ( type.isEmpty() )
        type = qfut( I_DIR_OR_FOLDER( N_("File/Directory"), N_("File/Folder") ) );
    return { { "text", toNativeSeparators( uri.toDisplayString(
                 QUrl::RemovePassword | QUrl::PreferLocalFile | QUrl::NormalizePathSegments ) ) },
             { "type", type } };
}

void SoutHelper::startStream(const QStringList& mrls, const QStringList& options, const QString& chain)
{
    if (mrls.isEmpty() || !p_intf)
        return;
    saveSelected();
    /* DialogsProvider::streamingDialog: the first media, with the chain */
    QVector<vlc::playlist::Media> outputMedias;
    const QString& mrl = mrls[0];
    outputMedias.append(vlc::playlist::Media(mrl, "Converting " + mrl, options + chain.split(" :")));
    THEMPL->append(outputMedias, true);
}

void SoutHelper::startConvert(const QStringList& mrls, const QStringList& options, const QVariantMap& s)
{
    if (mrls.isEmpty() || !p_intf)
        return;
    saveSelected();

    const bool dump = s.value("dump").toBool();
    /* the destination as a file URL (from the window) or a path */
    const QUrl destinationUrl( s.value("destination").toString() );
    const QString destination = destinationUrl.isLocalFile() ? destinationUrl.toLocalFile()
                                                             : s.value("destination").toString();
    const bool single = mrls.size() == 1;
    QStringList outputs;
    for (int i = 0; i < mrls.size(); i++)
    {
        /* ConvertDialog::accept */
        SoutChain mrl;
        if( dump )
        {
            mrl.header(" :demux=dump :demuxdump-file=" + toNativeSeparators( destination ));
        }
        else
        {
            mrl = m_selector->getTranscode();
            mrl.header( " :sout=#" + mrl.getHeader() );
            if( s.value("deinterlace").toBool() )
                mrl.option("deinterlace");

            QString newFileName;
            if( single )
                newFileName = destination;
            else
            {
                const QString fileExtension = QStringLiteral(".") + getMux();
                newFileName = QUrl(mrls.at(i)).toLocalFile();
                const int extentionPos = newFileName.lastIndexOf('.');
                if( extentionPos >= 0 )
                    newFileName = newFileName.remove(extentionPos, newFileName.length() - extentionPos);
                if( s.value("appendConverted").toBool() )
                    newFileName = newFileName.append("-converted");
                newFileName = newFileName.append(fileExtension);
            }
            mrl.end();

            SoutModule dstModule("std");
            SoutModule file("file");
            file.option("no-overwrite");
            dstModule.option("access", file);
            dstModule.option("mux", getMux());
            dstModule.option("dst", newFileName);

            if( s.value("display").toBool() )
            {
                SoutModule duplicate("duplicate");
                duplicate.option("dst", "display");
                duplicate.option("dst", dstModule);
                mrl.module(duplicate);
            }
            else
                mrl.module(dstModule);
        }
        msg_Dbg( p_intf, "Transcode chain: %s", qtu( mrl.to_string() ) );
        outputs.append(mrl.to_string());
    }

    /* DialogsProvider::streamingDialog: the play queue is replaced */
    THEMPL->clear();
    QVector<vlc::playlist::Media> outputMedias;
    for (int i = 0; i < outputs.size(); ++i)
    {
        const QString& mrl = mrls[i];
        outputMedias.append(vlc::playlist::Media(mrl, "Converting " + mrl, options + outputs[i].split(" :")));
    }
    if (!outputMedias.empty())
        THEMPL->append(outputMedias, true);
}

QString SoutHelper::browseSaveFile(const QString& title, const QString& filter) const
{
    const QStringList schemes = QStringList(QStringLiteral("file"));
    const QUrl url = QFileDialog::getSaveFileUrl( nullptr, title,
        p_intf && p_intf->p_mi ? p_intf->p_mi->getDialogFilePath() : QUrl(), filter,
        nullptr, QFileDialog::DontConfirmOverwrite, schemes );
    return url.isEmpty() ? QString() : url.toString();
}

QString SoutHelper::displayPath(const QString& url) const
{
    return toNativeSeparators(QUrl(url).toDisplayString(
        QUrl::RemovePassword | QUrl::PreferLocalFile | QUrl::NormalizePathSegments));
}

QVariantMap SoutHelper::profileEditorData() const
{
    /* VLCProfileEditor::loadCapabilities and registerFilters */
    QStringList muxers;
    QVariantList videoFilters, audioFilters;
    size_t count;
    module_t** all = module_list_get(&count);
    for (size_t i = 0; i < count; i++)
    {
        module_t* module = all[i];
        if (module_provides(module, "sout mux"))
            muxers.append(qfu(module_get_object(module)));
        if (module_get_score(module) > 0)
            continue;
        const QString capability = qfu(module_get_capability(module));
        QVariantList* list = capability == "video filter" ? &videoFilters
                           : capability == "audio filter" ? &audioFilters : nullptr;
        if (!list)
            continue;
        list->append(QVariantMap {
            { "value", qfu(module_get_object(module)) },
            { "text", qfu(module_GetLongName(module)) },
            { "help", qfu(module_get_help(module)) }
        });
    }
    module_list_free(all);

    const auto byText = [](const QVariant& a, const QVariant& b) {
        return a.toMap().value("text").toString() < b.toMap().value("text").toString();
    };
    std::sort(videoFilters.begin(), videoFilters.end(), byText);
    std::sort(audioFilters.begin(), audioFilters.end(), byText);
    return { { "muxers", muxers }, { "videoFilters", videoFilters }, { "audioFilters", audioFilters } };
}

void SoutHelper::storeProfile(const QString& oldName, const QString& name, const QString& value)
{
    if (!m_selector)
        return;
    m_selector->storeProfile(oldName, name, value);
    saveSelected();
}

QString SoutHelper::percentEncode(const QString& text) const
{
    return QString::fromLatin1(QUrl::toPercentEncoding(text, "", "_;"));
}

QString SoutHelper::percentDecode(const QString& text) const
{
    return QUrl::fromPercentEncoding(text.toLatin1());
}
