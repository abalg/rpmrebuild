BASE=../build/rpmrebuild
all: tar rpm

tar:	clean
	# rebuild
	mkdir -p $(BASE)/usr/local/bin
	cp `cat MANIFEST` $(BASE)
	cp rpmrebuild.sh $(BASE)/usr/local/bin
	ls $(BASE)
	cd $(BASE); tar cvfz /usr/src/redhat/SOURCES/rpmrebuild.tar.gz  *

rpm:	tar
	rpm -bb -v rpmrebuild.spec
	mv /usr/src/redhat/RPMS/noarch/rpmrebuild*.rpm .
	rpm --resign rpmrebuild*.rpm
	rm -rf $(BASE)

clean:
	rm -rf $(BASE)
