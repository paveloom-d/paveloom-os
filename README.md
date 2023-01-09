### Notices

#### Mirrors

Repository:
- [Codeberg](https://codeberg.org/paveloom-d/paveloom-os)
- [GitHub](https://github.com/paveloom-d/paveloom-os)
- [GitLab](https://gitlab.com/paveloom-g/docker/paveloom-os)

#### Description

[OSTree native containers](https://coreos.github.io/rpm-ostree/container) are OCI/Docker container images that contain a bootable operating system.

#### Build and run

To build the image locally, run

```bash
mkdir -p cache/dnf cache/rpm-ostree
podman build \
  -v $(pwd)/cache/dnf:/cache/dnf:Z \
  -v $(pwd)/cache/rpm-ostree:/var/cache/rpm-ostree:Z \
  --build-arg SAVE_RPM_OSTREE_CACHE=true \
  -t paveloom-os .
```

To delete dangling images (in case a build is unsuccessful), run

```bash
podman rmi $(podman images -f "dangling=true" -q)
```

Alternatively, you can provide the `--no-cache` flag when building.

To start a container based off of this image, run

```bash
podman run -td --entrypoint=/bin/bash --name paveloom-os paveloom-os
```

To enter the container, run

```bash
podman exec -it paveloom-os /bin/bash
```

When you're done, delete both the container and the image

```bash
podman stop -t 1 paveloom-os && podman rm paveloom-os
podman rmi paveloom-os
```

#### Rebase

To switch to booting from this container image (hosted on [Docker Hub](https://hub.docker.com/r/paveloom/paveloom-os)), run

```bash
sudo rpm-ostree rebase --experimental ostree-unverified-registry:docker.io/paveloom/paveloom-os:latest
```

The image is updated daily. You can use dates and short SHAs as [tags](https://hub.docker.com/r/paveloom/paveloom-os/tags), too.
