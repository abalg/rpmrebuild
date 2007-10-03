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
   spec_func.src

LANG_DATA :=		\
    rpmrebuild_lang.en	\
    rpmrebuild_lang.fr

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

MANPAGES_FR := $(addsuffix .fr,$(MANPAGES))

MANPAGES_SRC := $(addsuffix .in,$(MANPAGES) $(MANPAGES_FR))


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
   $(LANG_DATA)		\
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
   Version="`cat Version`"             && \
   Release="`cat Release`"             && \
   {                                      \
      echo "Version: $$Version"        && \
      echo "%define release $$Release" && \
      cat rpmrebuild.spc               && \
      cat spec.scripts                 && \
      echo "%changelog"                && \
      cat Changelog                    && \
      :                                ;  \
   }
endef

all: rpmrebuild.spec VERSION $(MANPAGES) $(MANPAGES_FR)
	$(LN) rpmrebuild_popt .popt
	$(MAKE) -C plugins $@

rpmrebuild.spec: rpmrebuild.spc spec.scripts Version Release Changelog 
	$(RM) $@
	$(Spec) > $@ || { $(RM) $@; exit 1; }

$(MANPAGES) $(MANPAGES_FR): %: %.in $(TOP_DIR)/Version
	$(MakeManPage)

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
	$(INSTALL_RO)  $(LANG_DATA)               $(TARGET_LIB)
	cd $(TARGET_LIB) && $(LN) rpmrebuild_popt .popt

	$(MKDIR)                                  $(TARGET_MAN)
	$(INSTALL_MAN) $(MANPAGES)                $(TARGET_MAN)
	$(MKDIR)                                  $(TARGET_MAN_FR)
	$(INSTALL_MAN) $(MANPAGES_FR)             $(TARGET_MAN_FR)
	- $(shell cd $(TARGET_MAN_FR); for m in $(MANPAGES_FR) do; mv $m `basename $m .fr`;done)

	$(MAKE) -C plugins $@

tar:	rpmrebuild.spec man
	tar -cvzf $(TAR_FILE) $(TAR_NAMES)

rpm rpmbuild:	tar
	$(MKDIR) $(RPM_BUILD_DIR)
	$@ -ba $(RPM_DEFINES) rpmrebuild.spec
	export RPMOLD=y && $@ -ba $(RPM_DEFINES) rpmrebuild.spec
	rpm --resign rpmrebuild*.rpm

clean:
	$(RMDIR) $(ROOT) $(RPM_BUILD_DIR)
	$(RM)    VERSION rpmrebuild.spec spec.scripts *.rpm rpmrebuild.tar.gz 
	$(RM)    $(MANPAGES) $(MANPAGES_FR)
	$(MAKE) -C plugins $@

man: $(MANPAGES) $(MANPAGES_FR)

help:
	@echo "list of targets :"
	@echo "- tar : build tar.gz"
	@echo "- rpmbuild : build rpm packages with rpm 4.x release"
	@echo "- rpm : build rpm packages with rpm 3.x release (deprecated)"
	@echo "- install : install software"
	@echo "- man : build man pages"
