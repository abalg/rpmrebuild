ROOT=../build/rpmrebuild
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


TAR_FILE=$(RPM_SOURCE_DIR)/rpmrebuild.tar.gz
TARGET_DIR = $(ROOT)/usr/local/bin

SCRIPTS = rpmrebuild.sh rpmrebuild_files.sh
SOURCES = $(SCRIPTS) .popt MANIFEST Makefile Changelog rpmrebuild.spec
all: 

install:
	mkdir --parent $(TARGET_DIR)
	install --mode=555 $(SCRIPTS) $(TARGET_DIR)
	install --mode=444 .popt      $(TARGET_DIR)
	cd $(TARGET_DIR) && ln -sfd .popt rpmrebuild_popt

tar:
	List=`cat MANIFEST` && tar -cvzf $(TAR_FILE) $(SOURCES) $$List

rpm:	tar
	mkdir --parent $(RPM_BUILD_DIR)
	rpm -ba -v $(RPM_DEFINES) rpmrebuild.spec
	rpm --resign rpmrebuild*.rpm

clean:
	rm -rf $(ROOT) $(RPM_BUILD_DIR)
