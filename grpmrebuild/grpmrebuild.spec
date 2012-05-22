%define version 0.1
%define release 1
Version: %{version}
Release: %{release}
Summary: grpmrebuild is a graphical interface for rpmrebuild
Summary(fr): grpmrebuild est une interface graphique pour rpmrebuild
# The Summary: line should be expanded to about here -----^
Name: grpmrebuild
License: GPL
Group: Development/Tools
BuildRoot: %{_topdir}/installroots/%{name}-%{version}-%{release}
Source: grpmrebuild.tar.gz
# Following are optional fields
Url: http://rpmrebuild.sourceforge.net
Packager: Eric Gerbier <gerbier@users.sourceforge.net>
#Distribution: Red Hat Contrib-Net
BuildArch: noarch
Requires: bash
Requires: /usr/bin/dialog
Requires: rpmrebuild
Requires: coreutils

%description
grpmrebuild is a graphical interface for rpmrebuild.
if will allow to select an installed rpm packages, or select
an rpm file

%description -l fr
grpmrebuild est une interface graphique pour rpmrebuild.
il permet de choisir parmi les packages rpm installés, ou parmi les
des fichiers rpm.

%prep
%setup -c rpmrebuild

%build
make

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"
make DESTDIR="$RPM_BUILD_ROOT" install

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"

%files -f grpmrebuild.files


%changelog
* Wed Feb 17 2011 <gerbier@users.sourceforge.net> 0.1-1
- first public release

