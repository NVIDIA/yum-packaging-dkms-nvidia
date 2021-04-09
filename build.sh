#!/usr/bin/env bash

runfile="$1"
distro="$2"
topdir="$HOME/dkms-nvidia"
epoch="3"

[[ -n $distro ]] ||
distro=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
[[ $distro == "main" ]] && distro="rhel8"

drvname=$(basename "$runfile")
arch=$(echo "$drvname" | awk -F "-" '{print $3}')
version=$(echo "$drvname" | sed -e "s|NVIDIA\-Linux\-${arch}\-||" -e 's|\.run$||' -e 's|\-grid$||')
drvbranch=$(echo "$version" | awk -F "." '{print $1}')

tarball="nvidia-kmod-${version}-${arch}"
unpackDir="unpack"

err() { echo; echo "ERROR: $*"; exit 1; }
kmd() { echo; echo ">>> $*" | fold -s; eval "$*" || err "at line \`$*\`"; }
dep() { type -p "$1" >/dev/null || err "missing dependency $1"; }

generate_tarballs()
{
    mkdir "${tarball}"
    sh "${runfile}" --extract-only --target ${unpackDir}
    mv "${unpackDir}/kernel" "${tarball}/"
    rm -rf ${unpackDir}
    tar --remove-files -cJf "${tarball}.tar.xz" "${tarball}"
}

build_dnf_rpm()
{
    mkdir -p "$topdir"
    (cd "$topdir" && mkdir -p BUILD BUILDROOT RPMS SRPMS SOURCES SPECS)

    cp -v -- *conf* "$topdir/SOURCES/"
    cp -v -- *.tar* "$topdir/SOURCES/"
    cp -v -- *.spec "$topdir/SPECS/"
    cd "$topdir" || err "Unable to cd into $topdir"

    kmd rpmbuild \
        --define "'%_topdir $(pwd)'" \
        --define "'debug_package %{nil}'" \
        --define "'version $version'" \
        --define "'epoch $epoch'" \
        --target "$arch" \
        -v -bb SPECS/dkms-nvidia.spec

    cd - || err "Unable to cd into $OLDPWD"
}

build_yum_rpm()
{
    mkdir -p "$topdir"
    (cd "$topdir" && mkdir -p BUILD BUILDROOT RPMS SRPMS SOURCES SPECS)

    cp -v -- *conf* "$topdir/SOURCES/"
    cp -v -- *.tar* "$topdir/SOURCES/"
    cp -v -- *.spec "$topdir/SPECS/"

    #
    # NOTE: to build kmod-nvidia-branch-XXX and kmod-nvidia-latest packages
    #       see https://github.com/NVIDIA/yum-packaging-precompiled-kmod
    flavor="latest-dkms"
    is_latest=1
    is_dkms=1

    cd "$topdir" || err "Unable to cd into $topdir"
    echo -e "\n:: flavor $flavor [$is_latest] [$is_dkms]"

    kmd rpmbuild \
        --define "'%_topdir $(pwd)'" \
        --define "'debug_package %{nil}'" \
        --define "'version $version'" \
        --define "'driver_branch $flavor'" \
        --define "'is_dkms $is_dkms'" \
        --define "'is_latest $is_latest'" \
        --define "'epoch $epoch'" \
        --target "$arch" \
        -v -bb SPECS/dkms-nvidia.spec

    cd - || err "Unable to cd into $OLDPWD"
}

build_wrapper()
{
    echo ":: Building $distro packages"
    if [[ $distro == "rhel7" ]]; then
        build_yum_rpm
    else
        build_dnf_rpm
    fi
}


# Create tarball from runfile contents
if [[ -f ${tarball}.tar.xz ]]; then
    echo "[SKIP] generate_tarballs()"
else
    echo "==> generate_tarballs()"
    [[ -f $runfile ]] || err "Usage: $0 /path/to/NVIDIA-Linux-*.run"
    generate_tarballs
fi

# Sanity check
[[ -n $version ]] || err "version could not be determined"

# Build RPMs
empty=$(find "$topdir/RPMS" -maxdepth 0 -type d -empty 2>/dev/null)
found=$(find "$topdir/RPMS" -mindepth 2 -maxdepth 2 -type f -name "*${version}*" 2>/dev/null)
if [[ ! -d "$topdir/RPMS" ]] || [[ $empty ]] || [[ ! $found ]]; then
    echo "==> build_rpm(${version})"
    dep rpmbuild
    build_wrapper
else
    echo "[SKIP] build_rpm(${version})"
fi

echo "---"
find "$topdir/RPMS" -mindepth 2 -maxdepth 2 -type f -name "*${version}*"
