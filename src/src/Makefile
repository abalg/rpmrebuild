all: tar rpm

tar:
	mkdir -p usr/local/bin
	cp rpmrebuild.sh usr/local/bin
	tar cvfz /usr/src/redhat/SOURCES/rpmrebuild.tar.gz --exclude CVS --exclude Makefile `ls | grep "^[A-Z]"` usr

rpm:	tar
	rpm -bb -v rpmrebuild.spec
	mv /usr/src/redhat/RPMS/noarch/rpmrebuild*.rpm .
	rpm --resign rpmrebuild*.rpm
