### Notices

#### Mirrors

Repository:
- [Codeberg](https://codeberg.org/paveloom-d/paveloom-os)
- [GitHub](https://github.com/paveloom-d/paveloom-os)
- [GitLab](https://gitlab.com/paveloom-g/docker/paveloom-os)

#### Description

[OSTree native containers](https://coreos.github.io/rpm-ostree/container) are OCI/Docker container images that contain a bootable operating system.

#### Rebase

To switch to booting from this container image, run

```
rpm-ostree rebase ostree-unverified-registry:ghcr.io/paveloom-d/paveloom-os:latest
```

The image is updated daily. You can use dates as [tags](https://github.com/paveloom-d/paveloom-os/pkgs/container/paveloom-os), too.
