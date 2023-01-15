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
  if [ "$SAVE_RPM_OSTREE_CACHE" == "false" ]; then \
    echo "Cleaning the cache..."; \
    rpm-ostree cleanup -m; \
    ostree container commit; \
  fi
