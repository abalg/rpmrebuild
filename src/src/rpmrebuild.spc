# Initial spec file created by autospec ver. 0.6 with rpm 2.5 compatibility
Summary: a tool to build rpm file from rpm database
# The Summary: line should be expanded to about here -----^
Name: rpmrebuild
License: GPL
Group: Utilities/System
BuildRoot: /tmp/rpmrebuild-root
Source: rpmrebuild.tar.gz
# Following are optional fields
Url: http://rpmrebuild.sourceforge.net
Packager: Eric Gerbier <gerbier@users.sourceforge.net>
#Distribution: Red Hat Contrib-Net
BuildArchitectures: noarch
Requires: rpm

%description
you have an installed package on a computer, want to install on other
one, and do not find the rpm file anymore. this tool is for you

%prep
%setup -c rpmrebuild

%build
make

%install
make ROOT="$RPM_BUILD_ROOT" install

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"

%files -f rpmrebuild.files

