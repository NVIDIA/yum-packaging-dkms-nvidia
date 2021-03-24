#!/usr/bin/env bash

runfile="$1"
topdir="$HOME/dkms-nvidia"
arch="x86_64"
epoch="3"

drvname=$(basename "$runfile")
version=$(echo "$drvname" | sed -e "s|NVIDIA\-Linux\-${arch}\-||" -e 's|\.run$||')

tarball=nvidia-kmod-${version}-${arch}
unpackDir="unpack"

err() { echo; echo "ERROR: $*"; exit 1; }
kmd() { echo; echo ">>> $*" | fold -s; eval "$*" || err "at line \`$*\`"; }

generate_tarballs()
{
    mkdir "${tarball}"
    sh "${runfile}" --extract-only --target ${unpackDir}
    mv "${unpackDir}/kernel" "${tarball}/"
    rm -rf ${unpackDir}
    tar --remove-files -cJf "${tarball}.tar.xz" "${tarball}"
}

build_rpm()
{
    mkdir -p "$topdir"
    (cd "$topdir" && mkdir -p BUILD BUILDROOT RPMS SRPMS SOURCES SPECS)

    cp -v -- *conf* "$topdir/SOURCES/"
    cp -v -- *tar* "$topdir/SOURCES/"
    cp -v -- *.spec "$topdir/SPECS/"
    cd "$topdir" || err "Unable to cd into $topdir"

    kmd rpmbuild \
        --define "'%_topdir $(pwd)'" \
        --define "'debug_package %{nil}'" \
        --define "'version $version'" \
        --define "'epoch $epoch'" \
        -v -bb SPECS/dkms-nvidia.spec

    cd - || err "Unable to cd into $OLDPWD"
}

# Create tarball from runfile contents
if [[ -f ${tarball}.tar.xz ]]; then
    echo "[SKIP] generate_tarballs()"
else
    echo "==> generate_tarballs()"
    generate_tarballs
fi

# Build RPMs
empty=$(find "$topdir/RPMS" -maxdepth 0 -type d -empty 2>/dev/null)
found=$(find "$topdir/RPMS" -mindepth 2 -maxdepth 2 -type f -name "*${version}*" 2>/dev/null)
if [[ ! -d "$topdir/RPMS" ]] || [[ $empty ]] || [[ ! $found ]]; then
    echo "==> build_rpm(${version})"
    build_rpm
else
    echo "[SKIP] build_rpm(${version})"
fi

echo "---"
find "$topdir/RPMS" -mindepth 2 -maxdepth 2 -type f -name "*${version}*"
