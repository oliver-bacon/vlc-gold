# VLC Gold on Linux

## AppImage (recommended)

The recommended way to run VLC Gold on Linux is the AppImage, a single executable file
that requires no installation or compilation. Download
`VLC_Gold-<version>-x86_64.AppImage` from the
[Releases](https://github.com/oliver-bacon/vlc-gold/releases) page, make it executable
(right-click › Properties › "Allow executing file as program", or `chmod +x` on the file)
and run it. It does not modify an installed VLC; to remove it, delete the file. It runs on
64-bit distributions with glibc 2.35 or newer (released 2022 or later), for example
Ubuntu 22.04, Debian 12, Fedora 36 and Linux Mint 21.

Tested on Arch Linux with KDE Plasma (in a virtual machine). In automated tests without a
desktop it also starts and plays video on Debian 12, Fedora 44 and Arch Linux.

For further notes (settings folder, app menu entry), see the [README](../README.md#linux-64-bit).

The following sections describe how to build the AppImage and how to build and install
VLC Gold from source.

## Building the AppImage

The AppImage is built in an Ubuntu 22.04 container, so that it runs on distributions with
glibc 2.35 or newer. From the repository root, with Docker:

```sh
docker run --rm --user root -v "$PWD":/vlc -w /vlc ubuntu:22.04 \
  bash extras/package/appimage/build.sh
```

The script installs the build tools, Qt 6.8.3 (aqtinstall), meson 1.10, newer Wayland build
tools and medialibrary 0.13.2 inside the container, builds VLC and packages it with
[linuxdeploy](https://github.com/linuxdeploy/linuxdeploy). All downloads are pinned and
checked against SHA-256 / SHA-512 checksums. Output:
`build-appimage/VLC_Gold-<version>-x86_64.AppImage`. The first run takes long; later
runs reuse the downloads and the VLC build in `build-appimage/`. It needs about 1.3 GB of
RAM per compile job (4 jobs by default; add `-e JOBS=2` to `docker run` to use fewer). Add
`-e VERSION=1.0.0` to set the version in the file name.

## Build and install from source (experimental)

Tested on Arch Linux with the system Qt 6.12 and medialibrary 0.13.2 built from source.
It also builds on Ubuntu with Qt 6.8.3 from [aqtinstall](https://github.com/miurahr/aqtinstall)
(see the notes below).

**1. Get the source** (the default branch `ui-redesign` is the redesign):

```sh
git clone https://github.com/oliver-bacon/vlc-gold.git ~/vlc
```

**2. Install VLC's build dependencies.** On Arch:

```sh
sudo pacman -S --needed base-devel git meson ninja pkgconf cmake nasm \
  qt6-base qt6-declarative qt6-svg qt6-shadertools qt6-wayland qt6-5compat qt6-tools \
  ffmpeg libass libplacebo freetype2 fribidi harfbuzz fontconfig \
  libx11 libxcb xcb-util-keysyms xcb-util-renderutil libxkbcommon libxkbcommon-x11 libxinerama libxpm \
  wayland wayland-protocols mesa libglvnd libdrm libva libvdpau vulkan-headers vulkan-icd-loader \
  libpulse alsa-lib pipewire libsamplerate \
  libmatroska libebml taglib libvorbis opus flac libmad libmpeg2 a52dec libdca faad2 libtheora speex speexdsp \
  libdvbpsi libbluray libdvdnav libdvdread libarchive libnfs gnutls libgcrypt libsecret dbus \
  libjpeg-turbo libpng librsvg libupnp sqlite zlib zstd srt aribb24 libmodplug libmpcdec twolame lame \
  avahi libnotify gtk3 xorg-xwayland
```

On other distributions, install the same libraries under their own names (the development
packages, usually ending in `-dev` or `-devel`). A shortcut that covers most of them:

- Debian / Ubuntu: `sudo apt build-dep vlc` (needs the source repositories enabled)
- Fedora: `sudo dnf builddep vlc` (VLC is in RPM Fusion)

These install what the distribution's own VLC 3 needs, but not Qt 6 (see the Qt note below)
and not SQLite 3.33 or newer, which medialibrary needs (`libsqlite3-dev` / `sqlite-devel`).
VLC also needs meson 1.10 or newer, which most distributions don't have yet; install it with
pipx: `pipx install meson ninja`.

Only Qt 6 (with Qt Quick, Qt SVG and Qt ShaderTools) and medialibrary (step 3) are required.
Any other missing library only turns off the feature that uses it: `meson setup` lists each
dependency with `found: YES` or `found: NO`. To add a library later, install it and run
`meson setup --reconfigure build-linux`, then `ninja -C build-linux` again.

**3. Build medialibrary 0.13.2.** It is not packaged on most distributions. This uses the
same version and checksum as VLC's `contrib/src/medialibrary`, and applies this
repository's fix for a crash when quitting. `VLC_SRC` is the clone from step 1;
medialibrary is installed to `~/vlc-deps`:

```sh
VLC_SRC=$HOME/vlc
DEPS=$HOME/vlc-deps
cd ~
curl -fLO https://code.videolan.org/videolan/medialibrary/-/archive/0.13.2/medialibrary-0.13.2.tar.bz2
echo "ec04cd28a19e547debf1a911fbcd33345a53a3f963e83d6f878c9836ebfefd4045c42a670a2c076ba3767bf91884f542e48dab6a254fc29285041fa9be35fe73  medialibrary-0.13.2.tar.bz2" | sha512sum -c -
tar xf medialibrary-0.13.2.tar.bz2
cd medialibrary-0.13.2
patch -p1 < "$VLC_SRC/contrib/src/medialibrary/0001-reset-logger-on-destroy.patch"
meson setup build --prefix="$DEPS" --libdir=lib --buildtype=release -Dlibvlc=disabled
ninja -C build install
```

**4. Build VLC** (in the same shell, so `VLC_SRC` and `DEPS` are still set):

```sh
cd "$VLC_SRC"
PKG_CONFIG_PATH=$DEPS/lib/pkgconfig meson setup build-linux --buildtype=release \
  --prefix=/opt/vlc-gold --libdir=lib \
  -Dmedialibrary=enabled -Dqt=enabled -Dlua=disabled \
  -Dc_link_args="-Wl,-rpath,$DEPS/lib" -Dcpp_link_args="-Wl,-rpath,$DEPS/lib"
ninja -C build-linux
```

**5. Run it** from the repository root, without installing. `VLC_LIB_PATH` is needed so that
VLC finds its modules and helpers such as the preparser:

```sh
VLC_LIB_PATH=build-linux/modules ./build-linux/bin/vlc-static -I qt
```

**6. Install (optional).** This installs to `/opt/vlc-gold`, separate from your
distribution's VLC, adds the command `vlc-gold` and an app menu entry "VLC Gold" that
also appears under "Open with" for video and audio files. `--prefix` in step 4 sets the
location; if you set up `build-linux` without it, first run
`meson configure build-linux --prefix=/opt/vlc-gold --libdir=lib` and `ninja -C build-linux`.

```sh
cd "$VLC_SRC"
PREFIX=/opt/vlc-gold
ninja -C build-linux
sudo ninja -C build-linux install
sudo tee /usr/local/bin/vlc-gold > /dev/null <<EOF
#!/bin/sh
export LD_LIBRARY_PATH=$PREFIX/lib:$PREFIX/lib/vlc\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}
exec $PREFIX/bin/vlc "\$@"
EOF
sudo chmod 755 /usr/local/bin/vlc-gold
sudo env LD_LIBRARY_PATH=$PREFIX/lib $PREFIX/libexec/vlc/vlc-cache-gen $PREFIX/lib/vlc/plugins
sudo install -Dm644 share/vlc512x512.png $PREFIX/share/icons/vlc-gold.png
MIMETYPES=$(grep -o '^[a-z][^ #]*' share/vlc.desktop.mimetypes | paste -sd';')
sudo mkdir -p /usr/local/share/applications
sudo tee /usr/local/share/applications/vlc-gold.desktop > /dev/null <<EOF
[Desktop Entry]
Type=Application
Name=VLC Gold
GenericName=Media player
Exec=/usr/local/bin/vlc-gold --started-from-file %U
Icon=$PREFIX/share/icons/vlc-gold.png
Terminal=false
Categories=AudioVideo;Player;
MimeType=$MIMETYPES;
EOF
```

- `vlc-gold` is a small launcher script: it lets the installed VLC find its own
  libraries (`libvlc`, `libvlccore`) in `/opt/vlc-gold` without registering them
  system-wide. VLC 4's `libvlccore.so.9` has the same name as the one of the regular VLC 3,
  so a system-wide entry would make the regular VLC load the wrong library.
- **Installed as "VLC Redesign" before?** Remove the old install first:
  `sudo rm -rf /opt/vlc-redesign /usr/local/bin/vlc-redesign /usr/local/share/applications/vlc-redesign.desktop /etc/ld.so.conf.d/vlc-redesign.conf && sudo ldconfig`
- `vlc-cache-gen`: writes the plugin cache (`plugins.dat`), so VLC starts faster.
- medialibrary is still loaded from `~/vlc-deps`; don't delete that folder.
- **Update:** `cd ~/vlc && git pull && ninja -C build-linux && sudo ninja -C build-linux install`,
  then run the `vlc-cache-gen` line again.
- **Uninstall:**
  `sudo rm -rf /opt/vlc-gold /usr/local/bin/vlc-gold /usr/local/share/applications/vlc-gold.desktop`

Notes:
- **Qt:** use Qt 6.8 or newer. The system Qt works on Arch (6.12). If your distribution has an
  older Qt (for example Ubuntu 24.04 and Debian 12 have 6.4), install Qt 6.8.3, the version VLC's
  Windows build uses, with aqtinstall (`pipx install aqtinstall`):
  `aqt install-qt linux desktop 6.8.3 linux_gcc_64 -O ~/Qt -m qtshadertools`.
  Then prefix VLC's `meson setup` command (step 4) with `PATH=~/Qt/6.8.3/gcc_64/bin:$PATH` and add
  `~/Qt/6.8.3/gcc_64/lib/pkgconfig` to `PKG_CONFIG_PATH`
  (`PKG_CONFIG_PATH=$DEPS/lib/pkgconfig:$HOME/Qt/6.8.3/gcc_64/lib/pkgconfig`).
- **rpath:** the `-Wl,-rpath` link arguments let VLC find medialibrary in `~/vlc-deps`.
  Leave them out if medialibrary is installed system-wide.
- **Memory:** building needs about 8 GB of RAM with 6 parallel jobs; with less, use
  `ninja -C build-linux -j2`.
- **Virtual machines:** without GPU access, VLC logs Mesa / VA-API errors and falls back to
  software rendering; playback still works.
