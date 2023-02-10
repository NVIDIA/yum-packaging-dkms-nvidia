%global dkms_name nvidia-open

Name:           kmod-%{dkms_name}-dkms
Version:        %{?version}%{?!version:525.89.02}
Release:        1%{?dist}
Summary:        NVIDIA driver open kernel module flavor
Epoch:          3
License:        MIT
URL:            https://github.com/NVIDIA/open-gpu-kernel-modules
BuildArch:      noarch

Source0:        %{url}/archive/refs/tags/%{version}.tar.gz
Source1:        dkms-open-nvidia.conf

BuildRequires:  sed

Requires:       dkms

Provides:       nvidia-kmod = %{?epoch:%{epoch}:}%{version}
Provides:       nvidia-kmod-common = %{?epoch:%{epoch}:}%{version}
Conflicts:      kmod-nvidia-latest-dkms

%description
This package provides the open-source Nvidia kernel driver modules.
The modules are rebuilt through the DKMS system when a new kernel or modules
become available.

%prep
%setup -q -n open-gpu-kernel-modules-%{version}

%install
mkdir -p %{buildroot}/%{_usrsrc}/%{dkms_name}-%{version}
cp -r * %{buildroot}/%{_usrsrc}/%{dkms_name}-%{version}/
cp -f %{SOURCE1} %{buildroot}/%{_usrsrc}/%{dkms_name}-%{version}/dkms.conf
sed -i -e 's/__VERSION_STRING/%{version}/g' %{buildroot}/%{_usrsrc}/%{dkms_name}-%{version}/dkms.conf

%post

dkms add -m %{dkms_name} -v %{version} -q
# Rebuild and make available for the currently running kernel
dkms build -m %{dkms_name} -v %{version} -q
dkms install -m %{dkms_name} -v %{version} -q --force

%preun
# Remove all versions from DKMS registry
dkms remove -m %{dkms_name} -v %{version} -q --all || :

%files
%{_usrsrc}/%{dkms_name}-%{version}

%changelog
* Fri Feb 10 2023 Tom Rix <trix@redhat.com> - 3:525.89.02
- Use the open gpu release from github
- Rework to build everything with dkms
- Update license to MIT

* Fri Jan 07 2022 Kevin Mittman <kmittman@nvidia.com> - 3:515.00-1
- Add alternative packages for open kmod flavor.
