TOP_DIR := .
include $(TOP_DIR)/Makefile.include

PWD := $(shell pwd)
RPM_TOP_DIR    := $(PWD)/BUILD
RPM_SOURCE_DIR := $(PWD)
RPM_BUILD_DIR  := $(PWD)/BUILD
RPM_RPMS_DIR   := $(PWD)
RPM_SRPMS_DIR  := $(PWD)

RPM_DEFINES :=                             \
   --define '_topdir    $(RPM_TOP_DIR)'    \
   --define '_sourcedir $(RPM_SOURCE_DIR)' \
   --define '_builddir  $(RPM_BUILD_DIR)'  \
   --define '_rpmdir    $(RPM_RPMS_DIR)'   \
   --define '_srcrpmdir $(RPM_SRPMS_DIR)'  \
   --define '_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm'

TAR_FILE := $(RPM_SOURCE_DIR)/rpmrebuild.tar.gz

TARGET_DIR    := $(ROOT)/usr/bin
TARGET_LIB    := $(ROOT)/usr/lib/rpmrebuild
TARGET_PLUGIN := $(ROOT)/usr/lib/rpmrebuild/plugins
TARGET_MAN    := $(ROOT)/usr/share/man/man1

SCRIPTS     := rpmrebuild 

LIB_SCRIPTS :=             \
   rpmrebuild.sh           \
   rpmrebuild_files.sh     \
   rpmrebuild_buildroot.sh \
   rpmrebuild_ghost.sh     \
   run.sh

INCLUDE_SCRIPTS :=       \
   processing_func.src   \
   rpmrebuild_parser.src \
   spec_func.src         \

POPTS :=                 \
   rpmrebuild_popt       \
   popt-without-POPTdesc \
   popt-with-POPTdesc    \

SPEC_SCRIPTS :=                  \
   spec.scripts.input            \
   spec.scripts.make.sh          \
   remove_from_popt.make.include \

MANPAGES :=             \
   rpmrebuild.1         \
   rpmrebuild_plugins.1 \

DOC_FILES :=      \
   AUTHORS        \
   Changelog      \
   COPYING        \
   COPYRIGHT      \
   LISEZ.MOI      \
   News           \
   README         \
   rpmrebuild.lsm \
   Todo           \

SOURCES :=               \
   $(SCRIPTS)            \
   $(LIB_SCRIPTS)        \
   $(INCLUDE_SCRIPTS)    \
   $(POPTS)              \
   $(SPEC_SCRIPTS)       \
   $(MANPAGES_SRC)	 \
   $(DOC_FILES)          \
   Makefile              \
   Makefile.include      \
   Changelog             \
   rpmrebuild.spc        \
   rpmrebuild.files      \
   Version               \
   Release               \

TAR_NAMES_PLUGINS := $(shell $(MAKE) --quiet -C plugins tar_names)
TAR_NAMES := $(SOURCES) rpmrebuild.spec $(TAR_NAMES_PLUGINS)

define Spec
   Version="`cat Version`"      && \
   Release="`cat Release`"      && \
   {                               \
      echo "Version: $$Version" && \
      echo "%define release $$Release" && \
      cat rpmrebuild.spc        && \
      cat spec.scripts          && \
      echo "%changelog"         && \
      cat Changelog             && \
      :                         ;  \
   }
endef

all: rpmrebuild.spec VERSION
	$(LN) rpmrebuild_popt .popt
	$(MAKE) -C plugins $@

rpmrebuild.spec: rpmrebuild.spc spec.scripts Version Release Changelog 
	$(RM) $@
	$(Spec) > $@ || { $(RM) $@; exit 1; }

spec.scripts:
	$(RM) $@
	/bin/sh spec.scripts.make.sh < $@.input > $@ || { $(RM) $@; exit 1; }

VERSION: Version
	$(RM) $@
	read VERSION < $< && echo "VERSION='$$VERSION'" > $@ || { $(RM) $@; exit 1; }


install:
	$(MKDIR)                                  $(TARGET_DIR)
	$(INSTALL_RUN) $(SCRIPTS)                 $(TARGET_DIR)

	$(MKDIR)                                  $(TARGET_LIB)
	$(INSTALL_RUN) $(LIB_SCRIPTS)             $(TARGET_LIB)
	$(INSTALL_RO)  $(INCLUDE_SCRIPTS) VERSION $(TARGET_LIB)
	$(INSTALL_RO)  $(POPTS)                   $(TARGET_LIB)
	cd $(TARGET_LIB) && $(LN) rpmrebuild_popt .popt

	$(MKDIR)                                  $(TARGET_MAN)
	$(INSTALL_MAN) $(MANPAGES)                $(TARGET_MAN)

	$(MAKE) -C plugins $@

tar:	rpmrebuild.spec
	tar -cvzf $(TAR_FILE) $(TAR_NAMES)

rpm rpmbuild:	tar
	$(MKDIR) $(RPM_BUILD_DIR)
	$@ -ba $(RPM_DEFINES) rpmrebuild.spec
	export RPMOLD=y && $@ -ba $(RPM_DEFINES) rpmrebuild.spec
	rpm --resign rpmrebuild*.rpm

clean:
	$(RMDIR) $(ROOT) $(RPM_BUILD_DIR)
	$(RM)    VERSION rpmrebuild.spec spec.scripts *.rpm rpmrebuild.tar.gz
	$(MAKE) -C plugins $@
