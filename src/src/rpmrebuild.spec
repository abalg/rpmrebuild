# Initial spec file created by autospec ver. 0.6 with rpm 2.5 compatibility
Summary: a tool to build rpm file from rpm database
# The Summary: line should be expanded to about here -----^
Name: rpmrebuild
Version: 0.7
Release: 1
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
#%patch

%install
cp -a . ${RPM_BUILD_ROOT-/}

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"

%files
%defattr(-,root,root)
%dir /usr/
%dir /usr/local/
%dir /usr/local/bin/
/usr/local/bin/rpmrebuild.sh
/usr/local/bin/rpmrebuild_files.sh
/usr/local/bin/rpmrebuild_popt
/usr/local/bin/.popt
%doc AUTHORS
%doc COPYING
%doc COPYRIGHT
%doc Changelog
%doc LISEZ.MOI
%doc README
%doc Todo

%changelog
* Mon Sep 30 2002  <gerbier@users.sourceforge.net> 0.7.0
- work on local dir (thanks Valery Reznic <valery_reznic@users.sourceforge.net>)

* Mon Sep 23 2002  <gerbier@users.sourceforge.net> 0.6.0
- add triggers (thanks to Han Holl <han.holl@prismant.nl>
- add many other spec tags (icon, exlude*, serial, provides, conflicts ...)

* Sun Sep 20 2002  <gerbier@users.sourceforge.net> 0.5.0
- try to have it work on any distribution
- the rpm package is now signed with my gpg key

* Mon Sep 17 2002  <gerbier@users.sourceforge.net> 0.4.2
- add architecture support (thanks to Han Holl <han.holl@prismant.nl>)
- add add require, obsolete tags
- force time format with LC_TIME to POSIX
- change shell name to match project name
- full english messages

* Mon Sep 17 2002  <gerbier@users.sourceforge.net> 0.4.1
- suppress useless exit
- shell cosmetic changes

* Sun Jul 14 2002  <gerbier@users.sourceforge.net>
- Initial spec file created by autospec ver. 0.6 with rpm 2.5 compatibility
- check changes (rpm -V)
- check for multiples rpm
- simplify pre post tag
- add type doc and config files
