tar:
	mkdir -p usr/local/bin
	cp rpmrebuild.sh usr/local/bin
	tar cvfz /usr/src/redhat/SOURCES/rpmrebuild.tar.gz --exclude CVS `ls | grep "^[A-Z]"` usr

rpm:	tar
	rpm -bb -v rpmrebuild.spec

all: tar rpm
