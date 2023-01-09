# Define the build arguments
ARG FEDORA_MAJOR_VERSION=37
ARG SAVE_RPM_OSTREE_CACHE=false

# Prepare an image with build tools
FROM docker.io/fedora:${FEDORA_MAJOR_VERSION} AS builder

RUN set -e; \
  echo "keepcache=1" | sudo tee -a /etc/dnf/dnf.conf >/dev/null; \
  echo "cachedir=/cache/dnf" | sudo tee -a /etc/dnf/dnf.conf >/dev/null; \
  dnf -y update; \
  dnf -y install \
  cmake \
  g++ \
  gcc \
  git \
  jq \
  meson \
  ninja-build \
  wget

# Build the `pixman-1` library
FROM builder AS pixman

WORKDIR /source

RUN set -e; \
  VERSION=0.42.2; \
  wget https://github.com/freedesktop/pixman/archive/refs/tags/pixman-"${VERSION}".tar.gz -O source.tar.gz; \
  tar --strip-components=1 -xf source.tar.gz
RUN set -e; \
  meson --prefix=/usr --buildtype=release build; \
  ninja -C build; \
  ninja -C build test; \
  DESTDIR=/build ninja -C build install

# Build the `libxcb-errors` library
FROM builder AS xcb-errors

WORKDIR /source

RUN set -e; \
  git clone --recursive https://gitlab.freedesktop.org/xorg/lib/libxcb-errors .
RUN set -e; \
  dnf -y install \
    libxcb-devel \
    xcb-proto \
    xorg-x11-util-macros
RUN set -e; \
  ./autogen.sh --prefix=/usr; \
  DESTDIR=/build make install

# Build the `hyprland` binary
FROM builder AS hyprland

WORKDIR /source

RUN set -e; \
  VERSION=0.20.1beta; \
  git clone --recursive -b v"${VERSION}" https://github.com/hyprwm/Hyprland .
RUN set -e; \
  dnf -y install \
    cairo-devel \
    glslang-devel \
    libX11-devel \
    libdrm-devel \
    libinput-devel \
    libseat-devel \
    libxcb-devel \
    libxkbcommon-devel \
    mesa-libEGL-devel \
    mesa-libgbm-devel \
    pango-devel \
    systemd-devel \
    vulkan-headers \
    vulkan-loader-devel \
    wayland-devel \
    wayland-protocols-devel \
    xcb-util-renderutil-devel \
    xcb-util-wm-devel \
    xorg-x11-server-Xwayland-devel
COPY --from=pixman /build/usr/ /usr/
COPY --from=xcb-errors /build/usr/ /usr/
COPY --from=xcb-errors /build/usr/ /build/usr/
RUN set -e; \
  meson --prefix=/usr --buildtype=release build; \
  ninja -C build; \
  ninja -C build test; \
  DESTDIR=/build ninja -C build install

# Build the final image
FROM ghcr.io/cgwalters/fedora-silverblue:${FEDORA_MAJOR_VERSION}
COPY --from=hyprland /build/usr/ /usr/
RUN set -e; \
  rpm-ostree install libseat; \
  if [ "$SAVE_RPM_OSTREE_CACHE" = "false" ]; then \
    rpm-ostree cleanup -m; \
    ostree container commit; \
  fi
