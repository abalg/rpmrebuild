BASE=../build/rpmrebuild
PWD=$(shell pwd)
RPM_SOURCE_DIR = $(PWD)
RPM_BUILD_DIR = $(PWD)/BUILD
RPM_RPMS_DIR  = $(PWD)
RPM_SRPMS_DIR = $(PWD)

RPM_DEFINES =                              \
   --define '_sourcedir $(RPM_SOURCE_DIR)' \
   --define '_builddir  $(RPM_BUILD_DIR)'  \
   --define '_rpmdir    $(RPM_RPMS_DIR)'   \
   --define '_srcrpmdir $(RPM_SRPMS_DIR)'  \
   --define '_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm'


TAR_FILE=$(PWD)/rpmrebuild.tar.gz

all: rpm

tar:	clean
	# rebuild
	mkdir -p $(BASE)/usr/local/bin
	cp `cat < MANIFEST` $(BASE)
	cp rpmrebuild.sh $(BASE)/usr/local/bin
	ls $(BASE)
	cd $(BASE) && tar cvzf $(TAR_FILE) *

rpm:	tar
	mkdir -p $(RPM_BUILD_DIR)
	rpm -bb -v $(RPM_DEFINES) rpmrebuild.spec
	rpm --resign rpmrebuild*.rpm

clean:
	rm -rf $(BASE) $(RPM_BUILD_DIR)
