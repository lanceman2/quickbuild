#! This is a GNU make file that uses GNU make extensions.

# This file is part of the quickbuild software package
# https://github.com/lanceman2/quickbuild

# A software build system based on GNU make.
# A software build system for web apps with served public static files and
# installed executables.
# Has build rules based on file suffixes.
#
#
##########################################################################
# Compressing this file:
#
# Run:
#
#   sed -e 's/^\s*\#.*$//g' -e '/^$/d' quickbuild.make
#
#
# Making a networked bootstrap script that gets this file and compresses
# it:
#
# Run (bash without leading #)):
#
#   set -ex
#
#   tag=master
#   wget https://raw.githubusercontent.com/lanceman2/quickbuild/$tag/quickbuild.make -O - |\
#   sed -e 's/^\s*\#.*$//g' -e '/^$/d' > quickbuild.make
#
#
# Consider adding sha512sum check if you use a particular tag with:
#
#   sha512sum quickbuild.make > quickbuild.make.sha512
#
#
# and later:
#
#   sha512sum -c quickbuild.make.sha512
#
#
##########################################################################

SHELL = /bin/bash

ifndef top_srcdir
    $(error top_srcdir was not defined)
endif


-include $(top_srcdir)/package.make

###################################################################
#  Common variables that are set with the package
###################################################################


# we are avoiding package specific constants


###################################################################


-include $(top_srcdir)/config.make


###################################################################
#  Common variables that are set and saved by the configure step
###################################################################

ifdef TAR_NAME
# TAR_NAME is usually from PACKAGE-VERSION
PREFIX ?= $(HOME)/installed/$(TAR_NAME)
else
PREFIX ?= $(HOME)/installed
endif

# How to convert .cs to .css
#   yui-compressor --line-break 60 --type css
# or for debug
#   cat
CSS_COMPRESS ?= cat

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

##############################################################
# List of suffixes
##############################################################
#
#  .jsp is javaScript before compressing to .js
#  .cs is CSS before compress to .css
#  .htm HTML fragment
#  .html HTML file to install
#  *.in makes * from sed replace command
#  *.dl is a script that downloads *
#  *.bl is a script that makes *
#  .js, .css, .html are all installed and served
#  .d C or C++ depend file
#  .o object file to build compiled C/C++ program
#  .lo shared object file to compile shared library
#  .so dynamic shared object library
#  .cpp C++ source
#  .c C source
#  compiled programs and scripts have no particular suffix
#
# -----------------------------------------------------------
#   Installed file types if INSTALL_DIR is defined
# -----------------------------------------------------------
#
#   Files are installed from a given source directory
#   to one installation directory given by user setting
#   INSTALL_DIR.
#
#  .js .css .so .html compiled-programs are installed if
#  INSTALL_DIR is defined
#
##############################################################


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


# C or C++ compiled programs
bins := $(filter-out %.so, $(patsubst %_SOURCES,%,$(filter %_SOURCES, $(.VARIABLES))))

# C or C++ shared libraries
libs := $(filter-out %_SOURCES, $(patsubst %.so_SOURCES,%.so,$(filter %_SOURCES, $(.VARIABLES))))

dependfiles :=
id :=
objects :=
c_compile := $(CC)
cpp_compile := $(CXX)

# GNU make function to make dependency (*.d) files and object (*.o, *.lo) files.
define Mkdepend
 # $(1) = program_name or libfoo.so
 # $(2) = C/C++ source filename without .c or .cpp suffix
 # $(3) = c or cpp
 # $(4) = object type o or lo
 # name needs to be unique
 id := $(words $(counter))
 name := $$(patsubst %.so,%_so,qb_build/$$(notdir $(2)-$$(id)-$(1)))
 counter := $$(counter) x
 $$(name).d $$(name).o: $(2).$(3) # rule below
 $$(name).d_target := $$(name).$(4)
 $$(name).$(4)_compile := $$($(3)_compile)
 $$(name).d_compile := $$($(3)_compile)
 $$(name).d $$(name).$(4): $(2).$(3)
 dependfiles := $(dependfiles) $$(name).d
 $(1)_objects := $$($(1)_objects) $$(name).$(4)
 common_cflags := $(CPPFLAGS) $$($$(name).$(4)_CPPFLAGS) $$($(1)_CPPFLAGS)
 ifeq ($(3),c)
   $$(name).$(4)_cflags := $$(strip $(CFLAGS) $$(common_cflags) $$($(1)_CFLAGS) $$($$(name).$(4)_CFLAGS))
 else
   $$(name).$(4)_cflags := $$(strip $(CXXFLAGS) $$(common_cflags) $$($(1)_CXXFLAGS) $$($$(name).$(4)_CXXFLAGS))
 endif
 $$(name).d_cflags := $$($$(name).$(4)_cflags)
endef


# GNU make function to make C/C++ program dependencies.
define Mkcpprules
  # $(1) = program_name
  # $(2) = object suffix o or lo
  # $(3) = nothing or -shared
  counter := x
  # list os object files for this program
  objects :=
  cpp_srcfiles :=  $$(patsubst %.cpp,%,$$(filter %.cpp,$$($(1)_SOURCES)))
  ifneq ($$(strip $$(cpp_srcfiles)),)
    $(1)_compile := $(CXX)
    $(1)_cflags := $$(strip $(3) $(CXXFLAGS) $$($(1)_CXXFLAGS))
  else
    $(1)_compile := $(CC)
    $(1)_cflags := $$(strip $(3) $(CFLAGS) $$($(1)_CFLAGS))
  endif
  c_srcfiles :=  $$(patsubst %.c,%,$$(filter %.c,$$($(1)_SOURCES)))
  $$(foreach src,$$(cpp_srcfiles),$$(eval $$(call Mkdepend,$(1),$$(src),cpp,$(2))))
  $$(foreach src,$$(c_srcfiles),$$(eval $$(call Mkdepend,$(1),$$(src),c,$(2))))
  # programs depend on object files
  $(1): $$($(1)_objects)
  ldadd :=
  ifneq ($$(strip $$($(1)_ADDLIBS)),)
    dirr := $$(patsubst %/,%,$(CURDIR)/$$(dir $$($(1)_ADDLIBS)))
    name := $$(patsubst lib%.so,%,$$(notdir $$($(1)_ADDLIBS)))
    ldadd := -l$$(name) -L$$(dirr) -Wl,-rpath,$$(dirr)
    undefine dirr
    undefine name
  endif
  $(1)_ldflags := $$(strip $$(ldadd) $(LDFLAGS) $$($(1)_LDFLAGS))
  objects := $$(objects) $$($(1)_objects)

  ifneq ($$(strip $$($(1)_INSTALL_RPATH)),)
    ifneq ($$(strip $$(POST_INSTALL_COMMAND)),)
      POST_INSTALL_COMMAND := $$(POST_INSTALL_COMMAND) &&
    endif
    POST_INSTALL_COMMAND :=\
 $$(POST_INSTALL_COMMAND) patchelf --set-rpath $$($(1)_INSTALL_RPATH)\
 $(INSTALL_DIR)/$(1)
  endif
endef

# GNU make for loop sets up make dependencies.
$(foreach prog,$(bins),$(eval $(call Mkcpprules,$(prog),o,)))
$(foreach lib,$(libs),$(eval $(call Mkcpprules,$(lib),lo,-shared)))


# We are done with these variables:
undefine ldadd
undefine id
undefine counter
undefine srcfiles
undefine Mkdepend
undefine Mkcpprules
undefine cpp_srcfiles
undefine c_srcfiles
undefine c_compile
undefine cpp_compile



installed := $(sort $(filter-out $(BUILD_NO_INSTALL),\
 $(bins)\
 $(libs)\
 $(BUILD)\
\
 $(patsubst %.jsp,%.js,$(wildcard *.jsp))\
 $(patsubst %.cs,%.css,$(wildcard *.cs))\
\
 $(patsubst %.jsp.bl,%.js,$(wildcard *.jsp.bl))\
 $(patsubst %.cs.bl,%.css,$(wildcard *.cs.bl))\
\
 $(patsubst %.jsp.in,%.js,$(wildcard *.jsp.in))\
 $(patsubst %.cs.in,%.css,$(wildcard *.cs.in))\
\
 $(patsubst %.jsp.bl.in,%.js,$(wildcard *.jsp.bl.in))\
 $(patsubst %.cs.bl.in,%.css,$(wildcard *.cs.bl.in))\
\
 $(patsubst %.js.bl,%.js,$(wildcard *.js.bl))\
 $(patsubst %.css.bl,%.css,$(wildcard *.css.bl))\
\
 $(patsubst %.js.in,%.js,$(wildcard *.js.in))\
 $(patsubst %.css.in,%.css,$(wildcard *.css.in))\
\
 $(patsubst %.js.bl.in,%.js,$(wildcard *.js.bl.in))\
 $(patsubst %.css.bl.in,%.css,$(wildcard *.css.bl.in))\
\
 $(patsubst %.html.in,%.html,$(wildcard *.html.in))\
 $(patsubst %.html.bl,%.html,$(wildcard *.html.bl))\
 $(patsubst %.html.bl.in,%.html,$(wildcard *.html.bl.in))\
 $(wildcard *.js *.css *.html *.gif *.jpg *.png)\
 $(INSTALLED)\
))


# We tally up all the files that are built including all possible
# intermediate files, and exclude $(dependfiles) $(objects) which are
# handled in qb_build/
built := $(sort\
 $(bins)\
 $(libs)\
 $(BUILD)\
 $(patsubst %.jsp,%.js,$(wildcard *.jsp))\
 $(patsubst %.cs,%.css,$(wildcard *.cs))\
 $(bl_scripts)\
 $(in_files)\
)

cleanfiles := $(sort $(built) $(CLEANFILES))

cleanerfiles := $(sort $(CLEANERFILES) $(wildcard *.pyc))

ifeq ($(strip $(top_srcdir)),.)
    cleanerfiles := $(cleanerfiles) config.make
endif


cleandirs := $(CLEANDIRS)

ifneq ($(strip $(objects)),)
  cleandirs := $(sort $(cleandirs) qb_build)

$(dependfiles) $(objects): | qb_build
qb_build:
	mkdir qb_build



# Rules to build C/C++ programs

# How to build object files
qb_build/%.o:
	$($@_compile) $($@_cflags) -c $< -o $@
# How to build library shared object files
qb_build/%.lo:
	$($@_compile) $($@_cflags) -fPIC $(CFLAGS) -c $< -o $@


# How to build depend files that track dependencies so that the objects
# and programs get automatically rebuilt when a depending source file
# changes.  By auto-generating dependencies we can come closer to
# guaranteeing things are rebuilt when they need to be.
qb_build/%.d:
	$($@_compile) $($@_cflags) -MM $< -MF $@ -MT $($@_target)


# How to build a C/C++ program.
$(bins) $(libs):
	$($@_compile) $($@_cflags) $($@_objects) -o $@ $($@_ldflags)


# We do not build depend files *.d if we have a command line target with
# clean or config in it.
nodepend := $(strip\
 $(findstring clean, $(MAKECMDGOALS))\
 $(findstring config, $(MAKECMDGOALS))\
)

ifeq ($(nodepend),)
ifneq ($(strip $(wildcard $(dependfiles))),)
# include with no error if we need to build them
-include $(dependfiles)
endif
endif

undefine nodepend
endif # ifneq ($(strip $(objects)),)



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
build: $(downloaded) $(built) $(top_srcdir)/config.make
# download before building
$(built): | $(downloaded) $(dependfiles)


# run 'make debug' to just spew this stuff:
debug:
	@echo "cleanerfiles=$(cleanerfiles)"
	@echo "INSTALL_DIR=$(INSTALL_DIR)"
	@echo "built=$(built)"
	@echo "downloaded=$(downloaded)"
	@echo "installed=$(installed)"
	@echo "dependfiles=$(dependfiles)"

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
install: $(built)
ifneq ($(INSTALL_DIR),)
	mkdir -p $(INSTALL_DIR)
ifneq ($(installed),)
	cp -r $(installed) $(INSTALL_DIR)
endif
ifneq ($(strip $(POST_INSTALL_COMMAND)),)
	$(POST_INSTALL_COMMAND)
endif
endif



config: $(top_srcdir)/config.make

$(top_srcdir)/config.make:
	echo -e "# This is a generated file\n" > $@
	echo -e "$(foreach var,$(config_vars),\n$(var) := $(strip $($(var))\n))" |\
	    sed -e 's/^ $$//' >> $@

download: $(downloaded)


clean:
ifneq ($(cleanfiles),)
	rm -f $(cleanfiles)
endif
ifneq ($(cleandirs),)
	rm -rf $(cleandirs)
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

