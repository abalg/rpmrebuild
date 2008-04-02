# $Id$
TOP_DIR := ..
include $(TOP_DIR)/Makefile.include

PLUGINS :=          \
   demo.plug        \
   demofiles.plug   \
   file2pacDep.plug \
   uniq.plug        \
   nodoc.plug       \
   set_tag.plug     \
                    \

SCRIPTS :=        \
   demo.sh        \
   demofiles.sh   \
   file2pacDep.sh \
   uniq.sh        \
   nodoc.sh       \
   set_tag.sh     \
                  \

MANPAGES_BASE := $(addsuffix .1rrp,$(PLUGINS))

MANPAGES := $(foreach lang,$(LANGS),$(addprefix man/$(lang)/,$(MANPAGES_BASE)))

MANPAGES_SRC := $(addsuffix .in,$(MANPAGES))

SOURCES :=         \
   $(PLUGINS)	   \
   $(SCRIPTS)      \
   $(MANPAGES_SRC) \
   Makefile        \

all: $(MANPAGES)

$(MANPAGES): %: %.in $(TOP_DIR)/Version
	$(MakeManPage)

man: $(MANPAGES)

install:
	$(MKDIR)                   $(TARGET_PLUGIN)
	$(INSTALL_RO)  $(PLUGINS)  $(TARGET_PLUGIN)
	$(INSTALL_RUN) $(SCRIPTS)  $(TARGET_PLUGIN)
	$(InstallManPages)

clean:
	$(RM) $(MANPAGES)

tar_names:
	@echo $(addprefix plugins/,$(SOURCES))
