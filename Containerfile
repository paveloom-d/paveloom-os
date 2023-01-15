# Build the final image
FROM ghcr.io/cgwalters/fedora-silverblue:37

# I used to build Hyprland here,
# check commit history to see how

# Define whether to save the `rpm-ostree`'s cache
ARG SAVE_RPM_OSTREE_CACHE=false

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
  sudo curl -o /etc/yum.repos.d/skype-stable.repo https://repo.skype.com/rpm/stable/skype-stable.repo; \
  rpm-ostree install \
    baobab \
    distrobox \
    espeak-ng-devel \
    festival \
    fish \
    flatpak-builder \
    gnome-console \
    gnome-tweaks \
    gparted \
    gstreamer1-plugin-libav \
    gstreamer1-plugins-bad-free-extras \
    gstreamer1-plugins-bad-freeworld \
    gstreamer1-plugins-ugly \
    gstreamer1-vaapi \
    libva-utils \
    nautilus-gsconnect \
    openssl \
    python3-pip \
    python3.9 \
    quiterss \
    radeontop \
    samba \
    skypeforlinux \
    wireguard-tools \
    xrandr; \
  if [ "$SAVE_RPM_OSTREE_CACHE" == "false" ]; then \
    echo "Cleaning the cache..."; \
    rpm-ostree cleanup -m; \
    ostree container commit; \
  fi
