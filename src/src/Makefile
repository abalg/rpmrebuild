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
TARGET_PLUGIN = $(ROOT)/usr/lib/rpmrebuild/plugins
TARGET_MAN = $(ROOT)/usr/local/man/man1

SCRIPTS     = rpmrebuild.sh 
LIB_SCRIPTS = rpmrebuild_dep.sh rpmrebuild_files.sh run.sh
POPTS       = rpmrebuild_popt popt-without-POPTdesc popt-with-POPTdesc
SPEC_SCRIPTS = spec.scripts.input spec.scripts.make.sh remove_from_popt.make.include
MANPAGES     = rpmrebuild.1
PLUGINS      = file2pacDep

SOURCES =                \
   $(SCRIPTS)            \
   $(LIB_SCRIPTS)        \
   $(POPTS)              \
   $(SPEC_SCRIPTS)       \
   $(MANPAGES)		 \
   $(PLUGINS)		 \
   MANIFEST              \
   Makefile              \
   Changelog             \
   rpmrebuild.spc        \
   rpmrebuild.files      \
   Version               \
   Release               \

TAR_NAMES = $(SOURCES) rpmrebuild.spec

define Spec
   Version="`cat Version`"      && \
   Release="`cat Release`"      && \
   {                               \
      echo "Version: $$Version" && \
      echo "Release: $$Release" && \
      cat rpmrebuild.spc        && \
      cat spec.scripts          && \
      echo "%changelog"         && \
      cat Changelog             && \
      :                         ;  \
   }
endef

all: rpmrebuild.spec

rpmrebuild.spec: rpmrebuild.spc spec.scripts Version Release Changelog 
	rm --force $@
	$(Spec) > $@

spec.scripts:
	rm --force $@
	/bin/sh spec.scripts.make.sh < $@.input > $@

install:
	mkdir --parent                   $(TARGET_DIR)
	install --mode=555 $(SCRIPTS)    $(TARGET_DIR)
	cd $(TARGET_DIR) && ln -sf rpmrebuild.sh rpmrebuild

	mkdir --parent                                $(TARGET_LIB)
	install --mode=555 $(LIB_SCRIPTS)             $(TARGET_LIB)
	install --mode=444 $(POPTS)                   $(TARGET_LIB)
	cd $(TARGET_LIB) && ln -sf rpmrebuild_popt .popt

	mkdir --parent                                $(TARGET_PLUGIN)
	install --mode=555 $(PLUGINS)		      $(TARGET_PLUGIN)

	mkdir --parent                                  $(TARGET_MAN)
	install --mode=644 ${MANPAGES}  		$(TARGET_MAN)

tar:	rpmrebuild.spec
	List=`cat MANIFEST` && tar -cvzf $(TAR_FILE) $(TAR_NAMES) $$List

rpm:	tar
	mkdir --parent $(RPM_BUILD_DIR)
	rpm -ba $(RPM_DEFINES) rpmrebuild.spec
	rpm --resign rpmrebuild*.rpm

t:
	rpm -bb -v $(RPM_DEFINES) a.a

clean:
	rm -rf $(ROOT) $(RPM_BUILD_DIR)
	rm  -f rpmrebuild.spec spec.scripts *.rpm rpmrebuild.tar.gz
