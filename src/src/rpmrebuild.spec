# Initial spec file created by autospec ver. 0.6 with rpm 2.5 compatibility
Summary: a tool to build rpm file from rpm database
# The Summary: line should be expanded to about here -----^
Name: rpmrebuild
Version: 0.4
Release: 1
License: GPL
Group: Utilities/System
#BuildRoot: /tmp/rpm-root
Buildroot: %{_tmppath}/%{name}-%{version}-root
Source: rpmrebuild.tar.gz
# Following are optional fields
Url: http://rpmrebuild.sourceforge.net
Packager: Eric Gerbier <gerbier@users.sourceforge.net>
#Distribution: Red Hat Contrib-Net
#Patch: rpm.patch
#Prefix: /
BuildArchitectures: noarch
Requires: rpm
#Obsoletes: 
%description
you have an installed package on a computer, want to install on other
one, and do not find the rpm file anymore. this tool is for you


%prep
%setup -c rpm
#%patch

%install
cp -a . ${RPM_BUILD_ROOT-/}

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"

%files
%defattr(-,root,root)
%dir /usr/local/bin/
/usr/local/bin/rebuild_rpm.sh
%doc AUTHORS
%doc Changelog
%doc COPYING
%doc COPYRIGHT
%doc LISEZ.MOI

%changelog
* Mon Sep 17 2002  <gerbier@users.sourceforge.net>
- suppress useless exit
- shell cosmetic changes

* Sun Jul 14 2002  <gerbier@users.sourceforge.net>
- Initial spec file created by autospec ver. 0.6 with rpm 2.5 compatibility
- check changes (rpm -V)
- check for multiples rpm
- simplify pre post tag
- add type doc and config files
