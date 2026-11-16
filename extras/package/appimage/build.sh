#!/bin/bash
# Copyright (C) 2026 VLC authors and VideoLAN
#
# Builds VLC Gold as an AppImage for x86_64 Linux.
#
# Run from the repository root, inside Ubuntu 22.04 (its glibc 2.35 is old enough for
# most current distributions):
#
#   docker run --rm --user root -v "$PWD":/vlc -w /vlc ubuntu:22.04 \
#     bash extras/package/appimage/build.sh
#
# Output: build-appimage/VLC_Gold-<version>-x86_64.AppImage. The version comes from
# `git describe` (redesign-v* tags); set it with `-e VERSION=1.0.0` on docker run.
# Other settings: `-e JOBS=2` (parallel compile jobs, default 4).

set -euo pipefail

QT_VERSION=6.8.3
MEDIALIBRARY_VERSION=0.13.2
MEDIALIBRARY_SHA512=ec04cd28a19e547debf1a911fbcd33345a53a3f963e83d6f878c9836ebfefd4045c42a670a2c076ba3767bf91884f542e48dab6a254fc29285041fa9be35fe73
WAYLAND_VERSION=1.23.1
WAYLAND_SHA256=864fb2a8399e2d0ec39d56e9d9b753c093775beadc6022ce81f441929a81e5ed
WAYLAND_PROTOCOLS_VERSION=1.38
WAYLAND_PROTOCOLS_SHA256=ff17292c05159d2b20ce6cacfe42d7e31a28198fa1429a769b03af7c38581dbe
LINUXDEPLOY_TAG=1-alpha-20251107-1
LINUXDEPLOY_SHA256=c20cd71e3a4e3b80c3483cef793cda3f4e990aca14014d23c544ca3ce1270b4d
LINUXDEPLOY_QT_TAG=1-alpha-20250213-1
LINUXDEPLOY_QT_SHA256=15106be885c1c48a021198e7e1e9a48ce9d02a86dd0a1848f00bdbf3c1c92724

SRC=$PWD
OUT=$SRC/build-appimage
APPDIR=$OUT/AppDir
TOOLS=$OUT/tools
mkdir -p "$OUT" "$TOOLS"

export DEBIAN_FRONTEND=noninteractive
# The linuxdeploy tools are AppImages themselves; there is no FUSE in a container.
export APPIMAGE_EXTRACT_AND_RUN=1

### 1. Build tools and libraries
apt-get update
apt-get install -y --no-install-recommends \
  build-essential pkg-config cmake nasm git curl ca-certificates file patch bzip2 xz-utils \
  flex bison gettext \
  python3-pip python3-venv \
  libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libswresample-dev libpostproc-dev \
  libass-dev libplacebo-dev libfreetype-dev libfribidi-dev libharfbuzz-dev libfontconfig-dev \
  libx11-dev libx11-xcb-dev libxcb1-dev libxcb-keysyms1-dev libxcb-render-util0-dev libxcb-shm0-dev \
  libxcb-composite0-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-render0-dev libxcb-xkb-dev libxcb-randr0-dev libxkbcommon-dev libxkbcommon-x11-dev \
  libxinerama-dev libxpm-dev libxext-dev \
  libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-xinerama0 libxcb-xinput0 libxcb-util1 \
  libwayland-dev libexpat1-dev libegl-dev libgl-dev libgles-dev libdrm-dev \
  libva-dev libvdpau-dev libvulkan-dev \
  libpulse-dev libasound2-dev libpipewire-0.3-dev libsamplerate0-dev \
  libmatroska-dev libebml-dev libtag1-dev libvorbis-dev libopus-dev libflac-dev libmad0-dev \
  libmpeg2-4-dev liba52-0.7.4-dev libdca-dev libfaad-dev libtheora-dev libspeex-dev libspeexdsp-dev \
  libdvbpsi-dev libbluray-dev libdvdnav-dev libdvdread-dev libarchive-dev libnfs-dev \
  libgnutls28-dev libgcrypt20-dev libsecret-1-dev libdbus-1-dev \
  liblua5.4-dev lua5.4 \
  libjpeg-dev libpng-dev librsvg2-dev libupnp-dev libsqlite3-dev zlib1g-dev libzstd-dev \
  libsrt-gnutls-dev libaribb24-dev libmodplug-dev libmpcdec-dev libtwolame-dev libmp3lame-dev \
  libavahi-client-dev

# VLC needs meson 1.10; Ubuntu 22.04 has 0.61. Qt 6.8 comes from aqtinstall.
python3 -m venv "$TOOLS/venv"
"$TOOLS/venv/bin/pip" install --quiet meson==1.10.2 ninja==1.13.0 aqtinstall==3.3.0
export PATH=$TOOLS/venv/bin:$PATH

QTDIR=$TOOLS/Qt/$QT_VERSION/gcc_64
if [ ! -x "$QTDIR/bin/qmake" ]; then
  aqt install-qt linux desktop $QT_VERSION linux_gcc_64 -O "$TOOLS/Qt" -m qtshadertools
fi
export PATH=$QTDIR/bin:$PATH
export PKG_CONFIG_PATH=$QTDIR/lib/pkgconfig

fetch() { # url sha file
  [ -f "$TOOLS/$3" ] || curl -fL -o "$TOOLS/$3" "$1"
  echo "$2  $TOOLS/$3" | "${4:-sha256sum}" -c -
}
fetch https://github.com/linuxdeploy/linuxdeploy/releases/download/$LINUXDEPLOY_TAG/linuxdeploy-x86_64.AppImage \
  $LINUXDEPLOY_SHA256 linuxdeploy-x86_64.AppImage
fetch https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/$LINUXDEPLOY_QT_TAG/linuxdeploy-plugin-qt-x86_64.AppImage \
  $LINUXDEPLOY_QT_SHA256 linuxdeploy-plugin-qt-x86_64.AppImage
chmod +x "$TOOLS"/*.AppImage

### 2. Wayland build tools: VLC needs wayland-scanner 1.23 and wayland-protocols 1.33,
# Ubuntu 22.04 has 1.20 and 1.25. Only the scanner and the protocol files are installed;
# the Wayland libraries themselves come from the user's system at run time.
WL=wayland-$WAYLAND_VERSION
fetch https://gitlab.freedesktop.org/wayland/wayland/-/releases/$WAYLAND_VERSION/downloads/$WL.tar.xz \
  $WAYLAND_SHA256 $WL.tar.xz
rm -rf "$OUT/$WL" && tar xf "$TOOLS/$WL.tar.xz" -C "$OUT"
meson setup "$OUT/$WL/build" "$OUT/$WL" --prefix=/usr/local -Dlibraries=false \
  -Ddocumentation=false -Dtests=false -Ddtd_validation=false
ninja -C "$OUT/$WL/build" install

WP=wayland-protocols-$WAYLAND_PROTOCOLS_VERSION
fetch https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/$WAYLAND_PROTOCOLS_VERSION/downloads/$WP.tar.xz \
  $WAYLAND_PROTOCOLS_SHA256 $WP.tar.xz
rm -rf "$OUT/$WP" && tar xf "$TOOLS/$WP.tar.xz" -C "$OUT"
meson setup "$OUT/$WP/build" "$OUT/$WP" --prefix=/usr/local -Dtests=false
ninja -C "$OUT/$WP/build" install

### 3. medialibrary (not packaged in Ubuntu), with the redesign's quit-crash fix
ML=medialibrary-$MEDIALIBRARY_VERSION
fetch https://code.videolan.org/videolan/medialibrary/-/archive/$MEDIALIBRARY_VERSION/$ML.tar.bz2 \
  $MEDIALIBRARY_SHA512 $ML.tar.bz2 sha512sum
rm -rf "$OUT/$ML"
tar xf "$TOOLS/$ML.tar.bz2" -C "$OUT"
patch -d "$OUT/$ML" -p1 < contrib/src/medialibrary/0001-reset-logger-on-destroy.patch
meson setup "$OUT/$ML/build" "$OUT/$ML" --prefix=/usr/local --libdir=lib --buildtype=release -Dlibvlc=disabled
ninja -C "$OUT/$ML/build" install
ldconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig

### 4. VLC
git config --global --add safe.directory "$SRC"
VERSION=${VERSION:-$(git describe --tags --match 'redesign-v*' 2>/dev/null | sed 's/^redesign-v//' || echo dev)}

# flex and bison build VLC's JSON library: without it the preparser plugin is skipped and
# VLC 4 can't start any interface. --reconfigure picks up newly installed tools.
RECONFIGURE=
[ -f "$OUT/vlc/build.ninja" ] && RECONFIGURE=--reconfigure
meson setup $RECONFIGURE "$OUT/vlc" --prefix=/usr --libdir=lib --buildtype=release \
  -Dmedialibrary=enabled -Dqt=enabled -Dlua=enabled -Dwayland=enabled -Dxcb=enabled
if [ ! -f "$OUT/vlc/modules/libpreparserserializer_json_plugin.so" ] && ! grep -q preparserserializer_json "$OUT/vlc/build.ninja"; then
  echo "preparserserializer_json plugin is disabled (flex/bison missing?)" >&2
  exit 1
fi
# Without these the video opens in a separate window instead of inside the player.
for c in x11 wayland; do
  if ! grep -q "compositor_$c.cpp" "$OUT/vlc/build.ninja"; then
    echo "Qt $c compositor is disabled (missing development package?)" >&2
    exit 1
  fi
done
# About 1.3 GB of RAM per job; set JOBS to change it.
ninja -C "$OUT/vlc" -j "${JOBS:-4}"
rm -rf "$APPDIR"
DESTDIR="$APPDIR" ninja -C "$OUT/vlc" install

# Only the redesign's own menu entry; headers and pkg-config files are not needed.
rm -rf "$APPDIR/usr/include" "$APPDIR/usr/lib/pkgconfig" "$APPDIR/usr/share/applications" \
       "$APPDIR/usr/share/metainfo" "$APPDIR/usr/share/icons"

### 5. AppDir: menu entry, icon, bundled libraries
install -Dm644 share/vlc512x512.png "$APPDIR/usr/share/icons/hicolor/512x512/apps/vlc-gold.png"
MIMETYPES=$(grep -o '^[a-z][^ #]*' share/vlc.desktop.mimetypes | paste -sd';')
mkdir -p "$APPDIR/usr/share/applications"
cat > "$APPDIR/usr/share/applications/vlc-gold.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=VLC Gold
GenericName=Media player
Comment=Media player with a redesigned interface, based on VLC
Exec=vlc --started-from-file %U
Icon=vlc-gold
Terminal=false
Categories=AudioVideo;Player;
MimeType=$MIMETYPES;
EOF

# VLC's plugins and helper programs are loaded at run time, so linuxdeploy can't see
# them through vlc itself: pass each folder so their libraries are bundled too.
DEPS_ARGS=()
while IFS= read -r dir; do
  DEPS_ARGS+=(--deploy-deps-only="$dir")
done < <(find "$APPDIR/usr/lib/vlc" "$APPDIR/usr/libexec/vlc" -type f \( -name '*.so' -o -perm -u+x \) -printf '%h\n' | sort -u)

export QMAKE=$QTDIR/bin/qmake
export QML_SOURCES_PATHS=$SRC/modules/gui/qt
export EXTRA_PLATFORM_PLUGINS="libqwayland-egl.so;libqwayland-generic.so"
export LD_LIBRARY_PATH=$APPDIR/usr/lib:$APPDIR/usr/lib/vlc:$QTDIR/lib:/usr/local/lib
export LDAI_OUTPUT="$OUT/VLC_Gold-$VERSION-x86_64.AppImage"
export OUTPUT=$LDAI_OUTPUT

"$TOOLS/linuxdeploy-x86_64.AppImage" --appdir "$APPDIR" \
  --executable "$APPDIR/usr/bin/vlc" \
  --desktop-file "$APPDIR/usr/share/applications/vlc-gold.desktop" \
  --icon-file "$APPDIR/usr/share/icons/hicolor/512x512/apps/vlc-gold.png" \
  "${DEPS_ARGS[@]}" \
  --plugin qt

# Qt plugins that linuxdeploy-plugin-qt leaves out: Wayland needs the shell integration
# (xdg-shell) and decorations to open a window; iconengines renders SVG icons.
EXTRA_PLUGINS=(wayland-shell-integration wayland-decoration-client wayland-graphics-integration-client iconengines)
for d in "${EXTRA_PLUGINS[@]}"; do
  cp -r "$QTDIR/plugins/$d" "$APPDIR/usr/plugins/"
done

# VLC's helper libraries (libvlc_xcb_events, libvlc_pulse, …) are in usr/lib/vlc, which
# the plugins have no search path for. linuxdeploy's AppRun sources apprun-hooks/*.sh.
mkdir -p "$APPDIR/apprun-hooks"
cat > "$APPDIR/apprun-hooks/vlc-libs.sh" <<'EOF'
export LD_LIBRARY_PATH="$APPDIR/usr/lib/vlc${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
EOF

"$TOOLS/linuxdeploy-x86_64.AppImage" --appdir "$APPDIR" \
  $(printf -- '--deploy-deps-only=%s ' "${EXTRA_PLUGINS[@]/#/$APPDIR/usr/plugins/}")

# Plugin cache (plugins.dat), so VLC starts faster. Written after the last change to the
# plugins (VLC ignores the cache when a plugin's size or time changed), so the last
# linuxdeploy run must not strip anything.
LD_LIBRARY_PATH=$APPDIR/usr/lib:$APPDIR/usr/lib/vlc \
  "$APPDIR/usr/libexec/vlc/vlc-cache-gen" "$APPDIR/usr/lib/vlc/plugins"

NO_STRIP=1 "$TOOLS/linuxdeploy-x86_64.AppImage" --appdir "$APPDIR" --output appimage
ls -l "$OUTPUT"
