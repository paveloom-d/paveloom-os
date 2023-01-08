# Define the build arguments
ARG FEDORA_MAJOR_VERSION=37

# Define the base image
FROM ghcr.io/cgwalters/fedora-silverblue:${FEDORA_MAJOR_VERSION}

# Commit nothing
RUN ostree container commit
