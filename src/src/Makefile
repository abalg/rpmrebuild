tar:
	mkdir -p usr/local/bin
	cp rebuild_rpm.sh usr/local/bin
	tar cvfz rpmrebuild.tar.gz --exclude CVS `ls | grep "^[A-Z]"` usr

rpm:	tar
	cp rpmrebuild.tar.gz /usr/src/redhat/SOURCES
	rpm -bb -v rpmrebuild.spec

all: tar rpm
