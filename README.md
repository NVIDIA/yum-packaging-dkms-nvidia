# yum packaging dkms nvidia

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Contributing](https://img.shields.io/badge/Contributing-Developer%20Certificate%20of%20Origin-violet)](https://developercertificate.org)

## Overview

Packaging templates using [DKMS](https://en.wikipedia.org/wiki/Dynamic_Kernel_Module_Support) on `yum` and `dnf` based Linux distros to manage NVIDIA driver kernel module compilation.

For pre-compiled packaging see: [yum-packaging-precompiled-kmod](https://github.com/NVIDIA/yum-packaging-precompiled-kmod)

The `main` branch contains this README and a sample build script. The `.spec` and `.conf` files can be found in the appropriate [rhel7](../../tree/rhel7), [rhel8](../../tree/rhel8), and [fedora](../../tree/fedora) branches.

## Table of Contents

- [Overview](#Overview)
- [Deliverables](#Deliverables)
- [Prerequisites](#Prerequisites)
  * [Clone this git repository](#Clone-this-git-repository)
  * [Install build dependencies](#Install-build-dependencies)
- [Building with script](#Building-with-script)
- [Building Manually](#Building-Manually)
- [Related](#Other-NVIDIA-driver-packages)
  * [Precompiled kernel modules](#Precompiled-kernel-modules)
  * [NVIDIA driver](#NVIDIA-driver)
  * [NVIDIA kmod common](#NVIDIA-kmod-common)
  * [NVIDIA modprobe](#NVIDIA-modprobe)
  * [NVIDIA persistenced](#NVIDIA-persistenced)
  * [NVIDIA plugin](#NVIDIA-plugin)
  * [NVIDIA settings](#NVIDIA-settings)
  * [NVIDIA xconfig](#NVIDIA-xconfig)
- [Contributing](#Contributing)


## Deliverables

This repo contains the `.spec` file(s) used to build the following **RPM** packages:

> *note:* `XXX` is the first `.` delimited field in the driver version, ex: `460` in `460.32.03`

* **RHEL8** or **Fedora** streams: `latest-dkms` and `XXX-dkms`
  ```shell
  kmod-nvidia-latest-dkms-${version}-${rel}.${dist}.${arch}.rpm
  > ex: kmod-nvidia-latest-dkms-460.32.03-1.el8.x86_64.rpm
  > ex: kmod-nvidia-latest-dkms-460.27.04-1.fc33.x86_64.rpm
  ```

* **RHEL7** flavor: `latest-dkms`
  ```shell
  kmod-nvidia-latest-dkms-${version}-${rel}.${dist}.${arch}.rpm
  > ex: kmod-nvidia-latest-dkms-460.32.03-1.el7.x86_64.rpm
  ```

* [Open GPU Kernel Modules](https://github.com/NVIDIA/open-gpu-kernel-modules) streams available in `515` and newer: `open-dkms` and `XXX-open`
  ```shell
  kmod-nvidia-open-dkms-${version}-${rel}.${dist}.${arch}.rpm
  > ex: kmod-nvidia-open-dkms-515.48.07-1.el9.x86_64.rpm
  > ex: kmod-nvidia-open-dkms-515.43.04-1.fc35.x86_64.rpm
  ```

---

The `latest` and `latest-dkms` streams/flavors always update to the highest versioned driver, while the `XXX` and `XXX-dkms` streams/flavors lock driver updates to the specified driver branch.

> *note:* `XXX-dkms` is not available for RHEL7

These packages can be used in place of their equivalent [pre-compiled](https://github.com/NVIDIA/yum-packaging-precompiled-kmod) packages:

* **RHEL8** or **Fedora** streams: `latest` and `XXX`
  ```shell
  kmod-nvidia-${driver}-${kernel}-${driver}-${rel}.${dist}.${arch}.rpm
  > ex: kmod-nvidia-460.32.03-4.18.0-240.15.1-460.32.03-3.el8_3.x86_64.rpm
  ```

* **RHEL7** flavor: `latest`
  ```shell
  kmod-nvidia-latest-${kernel}.r${driver}.${dist}.${arch}.rpm
  > ex: kmod-nvidia-latest-3.10.0-1160.15.2.r460.32.03.el7.x86_64.rpm
  ```

* **RHEL7** flavor: `branch-XXX`
  ```shell
  kmod-nvidia-branch-XXX-${kernel}.r${driver}.${dist}.${arch}.rpm
  > ex: kmod-nvidia-branch-460-3.10.0-1160.r460.32.03.el7.x86_64.rpm
  ```


## Prerequisites

### Clone this git repository:

Supported branches: `rhel7`, `rhel8` & `fedora`

```shell
git clone -b ${branch} https://github.com/NVIDIA/yum-packaging-dkms-nvidia
> ex: git clone -b rhel8 https://github.com/NVIDIA/yum-packaging-dkms-nvidia
```

### Install build dependencies

```shell
# Packaging
yum install rpm-build dkms

# Optional: compile open kernel modules from source
yum install g++
```


## Building with script

### Fetch script from `main` branch

```shell
cd yum-packaging-dkms-nvidia
git checkout remotes/origin/main -- build.sh
```

### Usage

```shell
./build.sh path/to/*.run
> ex: time ./build.sh ~/Downloads/NVIDIA-Linux-x86_64-450.102.04.run
```


## Building Manually (legacy modules)

### Generate tarball from runfile

> _note:_ architecture is `x86_64`, `ppc64le`, or `aarch64` (sbsa)

```shell
version="450.102.04"
sh NVIDIA-Linux-${arch}-${version}.run --extract-only --target extract
mkdir nvidia-kmod-${version}-${arch}
mv extract/kernel nvidia-kmod-${version}-${arch}/
tar -cJf nvidia-kmod-${version}-${arch}.tar.xz nvidia-kmod-${version}-${arch}
```


### Packaging (`dnf` distros)
> note: `fedora` & `rhel8`-based distros

```shell
mkdir BUILD BUILDROOT RPMS SRPMS SOURCES SPECS
cp dkms-nvidia.conf SOURCES/
cp nvidia-kmod-${version}-${arch}.tar.xz SOURCES/
cp dkms-nvidia.spec SPECS/

rpmbuild \
    --define "%_topdir $(pwd)" \
    --define "debug_package %{nil}" \
    --define "version $version" \
    --define "epoch 3" \
    --target "${arch}" \
    -v -bb SPECS/dkms-nvidia.spec
```

### Packaging (`yum` distros)
> note: `rhel7`-based distros

```shell
mkdir BUILD BUILDROOT RPMS SRPMS SOURCES SPECS
cp dkms-nvidia.conf SOURCES/
cp nvidia-kmod-${version}-${arch}.tar.xz SOURCES/
cp dkms-nvidia.spec SPECS/

# latest-dkms
rpmbuild \
    --define "%_topdir $(pwd)" \
    --define "debug_package %{nil}" \
    --define "version $version" \
    --define "driver_branch latest-dkms" \
    --define "is_dkms 1" \
    --define "is_latest 1" \
    --define "epoch 3" \
    --target "${arch}" \
    -v -bb SPECS/dkms-nvidia.spec
```

> _note:_ to build `kmod-nvidia-branch-XXX` and `kmod-nvidia-latest` packages see [yum-packaging-precompiled-kmod](https://github.com/NVIDIA/yum-packaging-precompiled-kmod)



## Building Manually (open modules)

### Generate input

> _note:_ architecture is `x86_64`, or `aarch64` (sbsa)

#### Use runfile

This method uses pre-build nvidia.o and nvidia-drm.o modules included with the NVIDIA driver runfile

```shell
version="515.48.07"
sh NVIDIA-Linux-${arch}-${version}.run --extract-only --target extract
mkdir nvidia-open-kmod-${version}-${arch}
mv extract/kernel-open nvidia-open-kmod-${version}-${arch}/
tar -cJf nvidia-open-kmod-${version}-${arch}.tar.xz nvidia-open-kmod-${version}-${arch}
```

**or**

#### Use NVIDIA-kernel-module-source tarball

This method builds nvidia.o and nvidia-drm.o modules from [NVIDIA-kernel-module-source*.tar.xz](https://download.nvidia.com/XFree86/NVIDIA-kernel-module-source/)

Compile from source code
```shell
version="515.48.07"
tar -xf NVIDIA-kernel-module-source-${version}.tar.xz
cd NVIDIA-kernel-module-source-${version}
make -j6 modules
```

Copy .o modules to expected location (work-in-progress)
```shell
rm -f kernel-open/nvidia/nv-kernel.o_binary &&
cp -av src/nvidia/_out/Linux_${arch}/nv-kernel.o kernel-open/nvidia/nv-kernel.o_binary
rm -f kernel-open/nvidia-modeset/nv-modeset-kernel.o_binary &&
cp -av src/nvidia-modeset/_out/Linux_${arch}/nv-modeset-kernel.o kernel-open/nvidia-modeset/nv-modeset-kernel.o_binary
```

Create input tarball
```
cd ..
mkdir nvidia-open-kmod-${version}-${arch}
mv NVIDIA-kernel-module-source-${version}/kernel-open nvidia-open-kmod-${version}-${arch}/
tar -cJf nvidia-open-kmod-${version}-${arch}.tar.xz nvidia-open-kmod-${version}-${arch}
```

### Packaging (open modules)

```shell
mkdir BUILD BUILDROOT RPMS SRPMS SOURCES SPECS
cp dkms-nvidia.conf SOURCES/
cp nvidia-open-kmod-${version}-${arch}.tar.xz SOURCES/
cp NVIDIA-kernel-module-source-${version}.tar.xz SOURCES/
cp dkms-open-nvidia.spec SPECS/

rpmbuild \
    --define "%_topdir $(pwd)" \
    --define "debug_package %{nil}" \
    --define "version $version" \
    --define "epoch 3" \
    --target "${arch}" \
    -v -bb SPECS/dkms-open-nvidia.spec
```


## Related

### Precompiled kernel modules

- Alternative to DKMS
  * [https://github.com/NVIDIA/yum-packaging-precompiled-kmod](https://github.com/NVIDIA/yum-packaging-precompiled-kmod)

### NVIDIA driver

- nvidia-driver
  * [https://github.com/NVIDIA/yum-packaging-nvidia-driver](https://github.com/NVIDIA/yum-packaging-nvidia-driver)

### NVIDIA kmod common

- Common files
  * [https://github.com/NVIDIA/yum-packaging-nvidia-kmod-common](https://github.com/NVIDIA/yum-packaging-nvidia-kmod-common)

### NVIDIA modprobe

- nvidia-modprobe
  * [https://github.com/NVIDIA/yum-packaging-nvidia-modprobe](https://github.com/NVIDIA/yum-packaging-nvidia-modprobe)

### NVIDIA persistenced

- nvidia-persistenced
  * [https://github.com/NVIDIA/yum-packaging-nvidia-persistenced](https://github.com/NVIDIA/yum-packaging-nvidia-persistenced)

### NVIDIA plugin

- _dnf-plugin-nvidia_ & _yum-plugin-nvidia_
  * [https://github.com/NVIDIA/yum-packaging-nvidia-plugin](https://github.com/NVIDIA/yum-packaging-nvidia-plugin)

### NVIDIA settings

- nvidia-settings
  * [https://github.com/NVIDIA/yum-packaging-nvidia-settings](https://github.com/NVIDIA/yum-packaging-nvidia-settings)

### NVIDIA xconfig

- nvidia-xconfig
  * [https://github.com/NVIDIA/yum-packaging-nvidia-xconfig](https://github.com/NVIDIA/yum-packaging-nvidia-xconfig)


## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)
