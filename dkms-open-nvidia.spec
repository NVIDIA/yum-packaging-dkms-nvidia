%global debug_package %{nil}
%global dkms_name nvidia-open
%global kmod_source NVIDIA-kernel-module-source

%define kmod_o_dir		%{_libdir}/nvidia/%{_target}/%{kmod_driver_version}/

Name:           kmod-%{dkms_name}-dkms
Version:        %{?version}%{?!version:515.00}
Release:        1%{?dist}
Summary:        NVIDIA driver open kernel module flavor
Epoch:          3
License:        NVIDIA License
URL:            http://www.nvidia.com/object/unix.html
# Package is not noarch as it contains pre-compiled binary code
ExclusiveArch:  x86_64 ppc64le aarch64

Source0:        dkms-nvidia.conf
Source1:        %{dkms_name}-kmod-%{version}-x86_64.tar.xz
Source2:        %{dkms_name}-kmod-%{version}-ppc64le.tar.xz
Source3:        %{dkms_name}-kmod-%{version}-aarch64.tar.xz
Source4:        %{kmod_source}-%{version}.tar.xz

BuildRequires:  sed

Conflicts:      kmod-nvidia-latest-dkms
Provides:       nvidia-kmod = %{?epoch:%{epoch}:}%{version}
Requires:       nvidia-kmod-common = %{?epoch:%{epoch}:}%{version}
Requires:       dkms

%description
This package provides the open-source Nvidia kernel driver modules.
The modules are rebuilt through the DKMS system when a new kernel or modules
become available.

%package -n nvidia-kmod-source
Summary:        NVIDIA open kernel module source files
AutoReq:        0
Conflicts:      kmod-nvidia-latest-dkms

%description -n nvidia-kmod-source
NVIDIA kernel module source files for compiling open flavor of nvidia.o and nvidia-modeset.o kernel modules.

%prep
%setup -q -T -b 4 -n %{kmod_source}-%{version}
rm -rf kernel-open

%ifarch x86_64
%setup -q -T -b 1 -n %{dkms_name}-kmod-%{version}-x86_64
cp -f %{SOURCE0} kernel-open/dkms.conf
%endif

%ifarch ppc64le
%setup -q -T -b 2 -n %{dkms_name}-kmod-%{version}-ppc64le
cp -f %{SOURCE0} kernel-open/dkms.conf
%endif

%ifarch aarch64
%setup -q -T -b 3 -n %{dkms_name}-kmod-%{version}-aarch64
cp -f %{SOURCE0} kernel-open/dkms.conf
%endif

sed -i -e 's/__VERSION_STRING/%{version}/g' kernel-open/dkms.conf
mv ../%{kmod_source}-%{version} kernel-source

%build

%install
# Create empty tree
mkdir -p %{buildroot}%{_usrsrc}/%{dkms_name}-%{version}/src
cp -fr kernel-open/* %{buildroot}%{_usrsrc}/%{dkms_name}-%{version}/
cp -fr kernel-source/* %{buildroot}%{_usrsrc}/%{dkms_name}-%{version}/src/
# Add symlink
cd %{buildroot}%{_usrsrc}/%{dkms_name}-%{version}/src/ &&
ln -sf ../../%{dkms_name}-%{version}/ kernel-open &&
cd - >/dev/null

%post
dkms add -m %{dkms_name} -v %{version} -q || :
# Rebuild and make available for the currently running kernel
dkms build -m %{dkms_name} -v %{version} -q || :
dkms install -m %{dkms_name} -v %{version} -q --force || :

%preun
# Remove all versions from DKMS registry
dkms remove -m %{dkms_name} -v %{version} -q --all || :

%files -n kmod-%{dkms_name}-dkms
%{_usrsrc}/%{dkms_name}-%{version}/common
%{_usrsrc}/%{dkms_name}-%{version}/nvidia*
%{_usrsrc}/%{dkms_name}-%{version}/Kbuild
%{_usrsrc}/%{dkms_name}-%{version}/Makefile
%{_usrsrc}/%{dkms_name}-%{version}/*.mk
%{_usrsrc}/%{dkms_name}-%{version}/conftest.sh
%{_usrsrc}/%{dkms_name}-%{version}/dkms.conf

%files -n nvidia-kmod-source
%{_usrsrc}/%{dkms_name}-%{version}/src

%changelog
* Fri Jan 07 2022 Kevin Mittman <kmittman@nvidia.com> - 3:515.00-1
- Add alternative packages for open kmod flavor.
