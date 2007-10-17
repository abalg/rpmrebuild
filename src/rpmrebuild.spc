%{expand:%%define rpmold   %(if [ -n "$RPMOLD" ]; then echo 1; else echo 0; fi)}
# Initial spec file created by autospec ver. 0.6 with rpm 2.5 compatibility
Summary: A tool to build rpm file from rpm database
Summary(fr): Un outil pour construire un package depuis une base rpm
# The Summary: line should be expanded to about here -----^
Name: rpmrebuild
License: GPL
Group: Development/Tools
BuildRoot: %{_topdir}/installroots/%{name}-%{version}-%{release}
Source: rpmrebuild.tar.gz
# Following are optional fields
Url: http://rpmrebuild.sourceforge.net
Packager: Eric Gerbier <gerbier@users.sourceforge.net>
#Distribution: Red Hat Contrib-Net
BuildArchitectures: noarch
Requires: bash
Requires: cpio
# mkdir ...
Requires: fileutils
Requires: sed
# sort
Requires: textutils
%if %rpmold
Requires: rpm < 4.0
Release: %{release}rpm3
%else
Requires: rpm >= 4.0, /usr/bin/rpmbuild
Release: %{release}rpm4
%endif

%description
rpmrebuild allow to build an rpm file from an installed rpm, or from
another rpm file, with or without changes (batch or interactive).
It can be extended by a plugin system.
A typical use is to easy repackage a software after some configuration's
change.

%description -l fr
rpmbuild permet de fabriquer un package rpm à partir d'un 
package installé ou d'un fichier rpm, avec ou sans modifications 
(interactives ou batch).
Un système de plugin permet d'étendre ses fonctionnalités.
Une utilisation typique est la fabrication d'un package suite à des modifications
de configuration.

%prep
%setup -c rpmrebuild

%build
make

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"
make DESTDIR="$RPM_BUILD_ROOT" install

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"

%files -f rpmrebuild.files

