TOP_DIR := ..
include $(TOP_DIR)/Makefile.include

PLUGINS :=          \
   demo.plug        \
   file2pacDep.plug \
   uniq.plug        \
   nodoc.plug        \
                    \

SCRIPTS :=        \
   demo.sh        \
   demofiles.sh   \
   file2pacDep.sh \
   uniq.sh        \
   nodoc.sh        \
                  \

MANPAGES :=              \
   file2pacDep.plug.1rrp \
   demo.plug.1rrp        \
   uniq.plug.1rrp        \
   nodoc.plug.1rrp        \

MANPAGES_SRC := $(addsuffix .in,$(MANPAGES))

SOURCES :=         \
   $(PLUGINS)	   \
   $(SCRIPTS)      \
   $(MANPAGES_SRC) \
   Makefile        \

all: $(MANPAGES)

$(MANPAGES): %: %.in $(TOP_DIR)/Version
	$(MakeManPage)

install:
	$(MKDIR)                   $(TARGET_PLUGIN)
	$(INSTALL_RO)  $(PLUGINS)  $(TARGET_PLUGIN)
	$(INSTALL_RUN) $(SCRIPTS)  $(TARGET_PLUGIN)

	$(MKDIR)                   $(TARGET_MAN)
	$(INSTALL_MAN) $(MANPAGES) $(TARGET_MAN)

clean:
	$(RM) $(MANPAGES)

tar_names:
	@echo $(addprefix plugins/,$(SOURCES))
