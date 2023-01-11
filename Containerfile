# Until the `latest` tag is available for the Silverblue image,
# we would like to synchronize the major versions here
ARG FEDORA_MAJOR_VERSION=37

# Prepare an image with build tools
FROM docker.io/fedora:${FEDORA_MAJOR_VERSION} AS builder

RUN set -e; \
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain none --no-modify-path; \
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
  ninja-build

# Build the `pixman-1` library
FROM builder AS pixman

WORKDIR /source

RUN set -e; \
  VERSION=0.42.2; \
  curl https://github.com/freedesktop/pixman/archive/refs/tags/pixman-"${VERSION}".tar.gz -Lo source.tar.gz; \
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
  git clone --recursive https://github.com/hyprwm/Hyprland .
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

# Build the `xdg-desktop-portal-hyprland` library
FROM builder AS xdg-desktop-portal-hyprland

WORKDIR /source

RUN set -e; \
  git clone --recursive https://github.com/hyprwm/xdg-desktop-portal-hyprland .
RUN set -e; \
  dnf -y install \
    inih-devel \
    libdrm-devel \
    libxkbcommon-devel \
    mesa-libgbm-devel \
    pipewire-devel \
    qt6-qtwayland-devel \
    systemd-devel \
    wayland-devel \
    wayland-protocols-devel
RUN set -e; \
  meson --prefix=/usr --buildtype=release build; \
  ninja -C build; \
  ninja -C build test; \
  cd hyprland-share-picker && make all && cd ..;\
  DESTDIR=/build ninja -C build install; \
  mkdir -p /build/usr/bin; \
  cp hyprland-share-picker/build/hyprland-share-picker /build/usr/bin/

# Build the `eww` binary
FROM builder AS eww

WORKDIR /source
ENV PATH "$HOME/.cargo/bin:$PATH"

RUN set -e; \
  VERSION=0.4.0; \
  curl https://github.com/elkowar/eww/archive/refs/tags/v"${VERSION}".tar.gz -Lo source.tar.gz; \
  tar --strip-components=1 -xf source.tar.gz
RUN set -e; \
  source "$HOME/.cargo/env"; \
  cargo fetch
RUN set -e; \
  dnf -y install \
    gtk-layer-shell-devel \
    gtk3-devel;
RUN set -e; \
  source "$HOME/.cargo/env"; \
  cargo build --release --no-default-features --features=wayland; \
  chmod +x target/release/eww; \
  mkdir -p /build/usr/bin; \
  cp target/release/eww /build/usr/bin

# Build the final image
FROM ghcr.io/cgwalters/fedora-silverblue:${FEDORA_MAJOR_VERSION}

# Define whether to save the `rpm-ostree`'s cache
ARG SAVE_RPM_OSTREE_CACHE=false

COPY --from=hyprland /build/usr/ /usr/
COPY --from=eww /build/usr/ /usr/
COPY --from=xdg-desktop-portal-hyprland /build/usr/ /usr/

RUN set -e; \
  rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm; \
  rpm-ostree install \
    rpmfusion-free-release \
    rpmfusion-nonfree-release \
    --uninstall rpmfusion-free-release \
    --uninstall rpmfusion-nonfree-release; \
  rpm-ostree override remove mesa-va-drivers --install mesa-va-drivers-freeworld; \
  rpm-ostree install \
    dunst \
    gtk-layer-shell \
    libseat \
    playerctl \
    qt6-qtwayland \
    slurp \
    wofi; \
  if [ "$SAVE_RPM_OSTREE_CACHE" == "false" ]; then \
    echo "Cleaning the cache..."; \
    rpm-ostree cleanup -m; \
    ostree container commit; \
  fi
