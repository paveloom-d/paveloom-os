# Define the build arguments
ARG FEDORA_MAJOR_VERSION=37

# Prepare an image with build tools
FROM docker.io/fedora:${FEDORA_MAJOR_VERSION} AS builder

RUN set -e; \
    echo "keepcache=1" | sudo tee -a /etc/dnf/dnf.conf >/dev/null; \
    echo "cachedir=/dnf-cache" | sudo tee -a /etc/dnf/dnf.conf >/dev/null; \
    dnf -y update; \
    dnf -y install \
      gcc \
      meson \
      ninja-build \
      wget

# Build the `pixman-1` library
FROM builder AS pixman

RUN set -e; \
    VERSION=0.42.2; \
    wget https://github.com/freedesktop/pixman/archive/refs/tags/pixman-"${VERSION}".tar.gz -O source.tar.gz; \
    tar --strip-components=1 --overwrite -xf source.tar.gz; \
    meson --prefix=/prefix --buildtype=release build; \
    ninja -C build; \
    ninja -C build test; \
    ninja -C build install

# Build the final image
FROM ghcr.io/cgwalters/fedora-silverblue:${FEDORA_MAJOR_VERSION}
COPY --from=pixman /prefix/ /usr/
RUN ostree container commit
