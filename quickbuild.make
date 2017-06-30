#! This is a GNU make file that uses GNU make extensions.

# This file is part of the quickbuild software package
# https://github.com/lanceman2/quickbuild


ifndef top_srcdir
    $(error top_srcdir was not defined)
endif


-include $(topsrc_dir)/qb_package.make

###################################################################
#  Common variables that are set with the package
###################################################################

ifndef PACKAGE_NAME
  $(error PACKAGE_NAME was not defined)
endif

VERSION ?= 0.1.0

TAR_NAME ?= $(PACKAGE_NAME)-$(VERSION)


###################################################################

-include $(topsrc_dir)/qb_config.make

###################################################################
#  Common variables that are set and saved by the configure step
###################################################################

PREFIX ?= $(HOME)/installed/$(TAR_NAME)

# How to convert .cs to .css
#   yui-compressor --line-break 60 --type css
# or for debug
#   cat
JS_COMPRESS ?= cat

# How to convert .jsp to .js
#   yui-compressor --line-break 60 --type js
# or for debug
#   cat
JS_COMPRESS ?= cat

# How to run node js with the system #! at the top of the
# file that is being run
NODEJS_SHABANG ?= /usr/bin/env node


###################################################################

# Any time the CC compiler is run
CFLAGS ?= -g -Wall

# Any time the CXX compiler is run
CXXFLAGS ?= -g -Wall


# .ONESHELL = all the lines in the recipe be passed to a single invocation
# of the shell
.ONESHELL:

.SUFFIXES: # Delete the default suffixes
# Define our suffix list
.SUFFIXES: .js .css .html .js .css .jsp .cs .dl .bl .c .cpp .h .hpp .d .o .lo .so

# .jsp is javaScript before compressing to .js
# .cs is CSS before compress to .css
# *.in makes * from sed replace command
# *.dl is a script that downloads *
# *.bl is a script that makes *
# .js, .css, .html are all installed and served


.DEFAULT_GOAL := build

subdirs := $(sort $(patsubst %/GNUmakefile,%,$(wildcard */GNUmakefile)))


config_vars :=\
 PREFIX\
 JS_COMPRESS\
 CSS_COMPRESS\
 NODEJS_SHABANG\
 CFLAGS\
 CXXFLAGS

# Strings we replace all *.in files.  For example: we replace
# @SERVER_PORT@ with the value of $(SERVER_PORT) in "foo.in" to make
# file "foo".
seds :=\
 NODEJS_SHABANG

sed_commands :=
define Seds
  sed_commands := $$(sed_commands) -e 's!@$(1)@!$$(strip $$($(1)))!g'
endef
$(foreach cmd,$(seds),$(eval $(call Seds,$(cmd))))
undefine Seds
undefine seds
# now we have the sed_commands for making * from *.in files

define Dependify
  $(1): $(1).$(2)
endef

# download (dl) scripts FILE.dl that download FILE
# dl_scripts is the things downloaded
dl_scripts := $(patsubst %.dl,%,$(wildcard *.dl))
$(foreach targ,$(dl_scripts),$(eval $(call Dependify,$(targ),dl)))

# In files, FILE.in, that build files named FILE
# in_files is the things built
in_files := $(patsubst %.in,%,$(wildcard *.in))
$(foreach targ,$(in_files),$(eval $(call Dependify,$(targ),in $(top_srcdir)/config.make)))

# build (bl) scripts FILE.bl that build files named FILE
# bl_scripts is the files built
bl_scripts := $(sort\
 $(patsubst %.bl,%,$(wildcard *.bl))\
 $(patsubst %.bl.in,%,$(wildcard *.bl.in))\
)
$(foreach targ,$(bl_scripts),$(eval $(call Dependify,$(targ),bl)))

undefine Dependify


downloaded := $(sort\
 $(dl_scripts)\
 $(DOWNLOADED)\
)

# We tally up all the files that are built
# including all possible intermediate files:
built := $(sort\
 $(patsubst %.jsp,%.js,$(wildcard *.jsp))\
 $(patsubst %.cs,%.css,$(wildcard *.cs))\
 $(patsubst %.in,%,$(wildcard *.in))\
 $(patsubst %.bl.in,%.bl,$(wildcard *.bl.in))\
 $(bl_scripts)\
 $(in_files)\
)

# built and installed
built := $(sort $(built) $(BUILD))

# We could build intermediate files, so we filter them out
installed := $(sort\
 $(built)\
 $(INSTALLED)\
 $(downloaded)\
 $(wildcard *.js *.css *.html *.gif *.jpg *.png)\
 $(filter-out %.jsp,$(filter-out %.cs,$(filter-out %.in,$(built))))\
)

# now add the stuff not installed
built := $(sort $(built) $(BUILD_NO_INSTALL))


cleanfiles := $(sort $(built) $(CLEANFILES))
cleanerfiles := $(sort $(CLEANERFILES) $(wildcard *.pyc))



# this will make config.make automatically
config:


ifneq ($(subdirs),)
# directory recursive makes
define Rec
  $$(patsubst rec_%,%,$(1)): | $(1)
  # We wish to recurse before local
endef
rec := rec_build rec_clean rec_cleaner\
 rec_distclean rec_install rec_download\
 rec_config rec_debug
$(foreach targ,$(rec),$(eval $(call Rec,$(targ))))
# Keep the building in sub-directories first
#$(downloaded) $(built): | rec_build
undefine Rec

$(rec):
	for d in $(subdirs) ; do\
 $(MAKE) -C $$d $(patsubst rec_%,%,$(@)) || exit 1 ;\
 done
endif

# default target
build: $(downloaded) $(built)
# download before building
$(built): | $(downloaded)


# run 'make debug' to just spew this stuff:
debug:
	@echo "cleanerfiles=$(cleanerfiles)"
	@echo "INSTALL_DIR=$(INSTALL_DIR)"
	@echo "built=$(built)"
	@echo "downloaded=$(downloaded)"
	@echo "installed=$(installed)"

help:
	@echo -e "  $(MAKE) [TARGET]\n"
	@echo -e "  Common TRAGETs are:"
	@echo -e '$(foreach \
	    var,build install download clean distclean,\n   $(var))' 

# some suffix recipes

# download script to targets
# *.dl -> *
$(dl_scripts):
	./$@.dl || (rm -rf $@ ; exit 1)

$(bl_scripts):
	./$@.bl || (rm -rf $@ ; exit 1)

# It's very important to say: "This is a generated file" in the upper
# comments of generated files, hence this messy 'bash/sed' code just
# below.
# *.in -> *
$(in_files):
	if head -1 $@.in | grep -E '^#!' ; then\
	     sed -n '1,1p' $@.in | sed $(sed_commands) > $@ &&\
	     echo -e "// This is a generated file\n" >> $@ &&\
	     sed '1,1d' $@.in | sed $(sed_commands) >> $@ ;\
	   elif [[ "$@" =~ \.jsp$$|\.js$$|\.cs$$|\.css$$ ]] ; then\
	     echo -e "/* This is a generated file */\n" > $@ &&\
	     sed $@.in $(sed_commands) >> $@ ;\
	   else\
	     sed $@.in $(sed_commands) > $@ ;\
	   fi
	if [[ $@ == *.bl ]] ; then chmod 755 $@ ; fi
	if [ -n "$($@_MODE)" ] ; then chmod $($@_MODE) $@ ; fi

# *.jsp -> *.js
%.js: %.jsp
	echo "/* This is a generated file */" > $@
	$(JS_COMPRESS) $< >> $@

# *.cs -> *.css
%.css: %.cs
	echo "/* This is a generated file */" > $@
	$(CSS_COMPRESS) $< >> $@


# We have just one install directory for a given source directory
install: build 
ifneq ($(INSTALL_DIR),)
	mkdir -p $(INSTALL_DIR)
ifneq ($(installed),)
	cp -r $(installed) $(INSTALL_DIR)
endif
ifneq ($(POST_INSTALL_COMMAND),)
	$(POST_INSTALL_COMMAND)
endif
endif


$(top_srcdir)/config.make:
	echo -e "# This is a generated file\n" > $@
	echo -e '$(foreach \
	    var,$(config_vars),\n$(var) := $(strip $($(var))\n))' |\
	    sed -e 's/^ $$//' >> $@

download: $(downloaded)

clean:
ifneq ($(cleanfiles),)
	rm -f $(cleanfiles)
endif

distclean cleaner: clean
ifneq ($(CLEANERDIRS),)
	rm -rf $(CLEANERDIRS)
endif
ifneq ($(downloaded),)
	rm -rf $(downloaded)
endif
ifneq ($(cleanerfiles),)
	rm -f $(cleanerfiles)
endif




# After we install the programs we reset the RPATH so that the programs
# can find the libliquid and libfec shared libraries using patchelf.
INSTALL_RPATH = patchelf --set-rpath '$(PREFIX)/lib'

POST_INSTALL_COMMAND =\
 $(INSTALL_RPATH) $(BIN)/config_scenario_controllers &&\
 $(INSTALL_RPATH) $(BIN)/config_cognitive_engines &&\
 $(INSTALL_RPATH) $(BIN)/crts_interferer &&\
 $(INSTALL_RPATH) $(BIN)/crts_cognitive_radio &&\
 $(INSTALL_RPATH) $(BIN)/crts_controller



################################################################################
# butt ugly from here down

cpp_programs = $(patsubst %_SOURCES,%,$(filter %_SOURCES, $(.VARIABLES)))

dependfiles :=
id :=
objects :=
cppbins :=

# GNU make function to make dependency (*.d) files and object (*.o) files.
define Mkdepend
 # $(1) = program_name
 # $(2) = C++ source filename without .cpp suffix
 # name needs to be unique
 name := build/$$(notdir $(2)-$$(id)-$(1))
 id := $(words $(counter))
 counter := $$(counter) x
 $$(name).d $$(name).o: $(2).cpp
 $$(name).d_target := $$(name).o
 $$(warn $$(name).d $$(name).o: $(2).cpp)
 dependfiles := $(dependfiles) $$(name).d
 objects := $$(objects) $$(name).o
endef

# GNU make function to make C++ program dependencies.
define Mkcpprules
  # $(1) = program_name
  counter := x
  # list os object files for this program
  objects :=
  srcfiles :=  $$(patsubst %.cpp,%,$$(filter %.cpp,$$($(1)_SOURCES)))
  $$(foreach src,$$(srcfiles),$$(eval $$(call Mkdepend,$(1),$$(src))))
  # programs depend on object files
  $(1): $$(objects)
  $(1)_objects := $$(objects)
  cppbins := $$(cppbins) $(1)
  CLEANFILES := $$(CLEANFILES) $(1)
endef

# GNU make for loop sets up make dependencies.
$(foreach prog,$(cpp_programs),$(eval $(call Mkcpprules,$(prog))))

# We are done with these variables:
undefine objects
undefine id
undefine counter
undefine srcfiles
undefine Mkdepend
undefine Mkcpprules


# Add the compiled C++ programs to the list of things to build and
# install:
BUILD := $(cppbins)

# Rules to build C++ programs

# How to build object files
%.o:
	$(CXX) $(CXXFLAGS) -c $< -o $@

# How to build depend files that track dependencies so that the objects
# and programs get automatically rebuilt when a depending source file
# changes.  By auto-generating dependencies we can come closer to
# guaranteeing things are rebuilt when they need to be.
%.d:
	$(CXX) $(CPPFLAGS) -MM $< -MF $@ -MT $($@_target)

# How to build a C++ program.
$(cppbins):
	$(CXX) $(CXXFLAGS) $($@_objects) -o $@ $($@_LDFLAGS)


# We do not build depend files *.d if we have a command line target with
# clean or config in it.
nodepend := $(strip\
 $(findstring clean, $(MAKECMDGOALS))\
 $(findstring config, $(MAKECMDGOALS))\
)

ifeq ($(nodepend),)
BUILD_NO_INSTALL := $(dependfiles)
ifneq ($(strip $(wildcard $(dependfiles))),)
# include with no error if we need to build them
-include $(dependfiles)
endif
endif

BUILD_NO_INSTALL := $(BUILD_NO_INSTALL) logs/convert_logs_bin_to_octave

build: $(dependfiles)

clean: localclean

localclean:
	rm -f build/*.o build/*.d


logs/convert_logs_bin_to_octave: convert_logs_bin_to_octave
	cp $< $@


# Add this directory to the recursive build system.  This make file is the
# only compiled code in this project, so this make file is larger than
# others.  If more compiled C/C++ program are added to other directories
# this file should spill some into common.make
include $(top_srcdir)/common.make

