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
TARGET_ETC = $(ROOT)/etc/rpmrebuild
TARGET_LIB = $(ROOT)/usr/lib/rpmrebuild

SCRIPTS = rpmrebuild.sh rpmrebuild_files.sh
SOURCES =           \
   $(SCRIPTS)       \
   rpmrebuild_popt  \
   MANIFEST         \
   Makefile         \
   Changelog        \
   rpmrebuild.spc   \
   rpmrebuild.files \
   Version          \
   Release          \

TAR_NAMES = $(SOURCES) rpmrebuild.spec

all: rpmrebuild.spec

rpmrebuild.spec: rpmrebuild.spc Version Release Changelog 
	rm --force $@
	Version="`cat Version`" && Release="`cat Release`" && { echo "Version: $$Version" && echo "Release: $$Release" && cat rpmrebuild.spc && echo "%changelog" && cat Changelog; } > $@ 

install:
	mkdir --parent                   $(TARGET_DIR)
	install --mode=555 rpmrebuild.sh $(TARGET_DIR)
	cd $(TARGET_DIR) && ln -sf rpmrebuild.sh rpmrebuild

	mkdir --parent                         $(TARGET_LIB)
	install --mode=555 rpmrebuild_files.sh $(TARGET_LIB)
	install --mode=444 rpmrebuild_popt     $(TARGET_LIB)
	cd $(TARGET_LIB) && ln -sf rpmrebuild_popt .popt

tar:	rpmrebuild.spec
	List=`cat MANIFEST` && tar -cvzf $(TAR_FILE) $(TAR_NAMES) $$List

rpm:	tar
	mkdir --parent $(RPM_BUILD_DIR)
	rpm -ba -v $(RPM_DEFINES) rpmrebuild.spec
	rpm --resign rpmrebuild*.rpm

clean:
	rm -rf $(ROOT) $(RPM_BUILD_DIR) rpmrebuild.spec *.rpm rpmrebuild.tar.gz
