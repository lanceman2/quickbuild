# This is a GNU make file that uses GNU make extensions.

# This file is from the quickbuild software package
# https://github.com/lanceman2/quickbuild/
#
# quickbuild is free software that is distributed under the free software
# foundation's GNU Affero General Public License (AGPL) version 3.
#
# quickbuild is a software build system based on GNU make.
# A software build system for web apps with served public static files and
# installed executables.
# Has build rules based on file suffixes.  It's just a short (<1000 lines)
# make file that you include in your make files.
#
#
##########################################################################
# Compressing this file (removing comments and extra lines):
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

# .ONESHELL = all the lines in the recipe be passed to a single invocation
# of the shell.  This is very important.
.ONESHELL:

#########################################################################
#########################################################################
# We define this to setup for building in separate build tree with a
# command like (differently to how autotools configure does this):
#
#     make BUILD_PREFIX=$build_prefix
#
# This can't be like autotool method (cd build && $path_to_configure)
# because we are running make already.
#

# We don't let a generated copy of this file use the BUILD_PREFIX
# functionality because the source files would not be in the directory is
# and this file has already been hacked up.  The generated copy has
# top_srcdir defined.
ifdef top_srcdir
# this is a build tree copy
ifdef BUILD_PREFIX
$(error You cannot make a build tree with a directory that is not a source tree)
endif

# Make sure that the source tree that we are using has not been built yet.
# If make ever ran in the top_srcdir then config.make will exist.
ifneq ($(strip $(wildcard $(top_srcdir)/config.make)),)
$(error You have already built this package in $(top_srcdir)\
 so now you cannot build it here too)
endif

endif


ifdef BUILD_PREFIX

# someone ran:
#
#    make BUILD_PREFIX=bla_bla_bla
#
# So now we make a new build directory tree:

ifneq ($(strip $(wildcard $(BUILD_PREFIX)/GNUmakefile)),)
$(error BUILD_PREFIX makefile $(BUILD_PREFIX)/GNUmakefile exists already)
endif

this_file := $(notdir $(lastword $(MAKEFILE_LIST)))
top_srcdir := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
abs_top_srcdir := $(abspath $(top_srcdir))

# build_prefix is the only target in this case: just running a bash script
# that creates a build directory that mirrors the source tree.

build_prefix:
	set -e
	mkdir -p $(BUILD_PREFIX)
	echo -e "# This is a generated file\n" > $(BUILD_PREFIX)/$(this_file)
	echo -e "ifdef top_srcdir\n\$$(error top_srcdir should not be defined)\nendif\n" >> $(BUILD_PREFIX)/$(this_file)
	echo -e "\ntop_srcdir := $(abs_top_srcdir)\n\n" >> $(BUILD_PREFIX)/$(this_file)
	cat $(abs_top_srcdir)/$(this_file) >> $(BUILD_PREFIX)/$(this_file)
	function cp_make()\
 {\
 while [ -n "$$1" ] ; do \
 if [ -f $(abs_top_srcdir)/$$1 ] ; then\
 mkdir -p $$(dirname $(BUILD_PREFIX)/$$1) ;\
 cp $(abs_top_srcdir)/$$1 $(BUILD_PREFIX)/$$1 ;\
 cp_make $$1/*/GNUmakefile ;\
 fi ; shift ; done ;\
}
	cp_make */GNUmakefile
	cp $(abs_top_srcdir)/GNUmakefile $(BUILD_PREFIX)
	set -x
	echo -e "\n  made build directory: $(BUILD_PREFIX)\n"



#########################################################################
else # ifdef BUILD_PREFIX
#########################################################################


.DEFAULT_GOAL := build


ifndef subdirs
subdirs := $(sort $(patsubst %/GNUmakefile,%,$(wildcard */GNUmakefile)))
endif

ifneq ($(subdirs),)

ifdef SUBDIRS # user interface to reorder the sub-directories
subdirs := $(SUBDIRS)
endif

#$(error subdirs=$(subdirs))

#########################################################################
#                  recursion
#########################################################################
#
# if subdirs is not an empty string we recurse and then call the
# non-recursing make (subdirs=) as we pop back out of the recurse.
#

build: rec_build
install: rec_install
download: rec_download
debug: rec_debug
clean: rec_clean
cleaner: rec_cleaner
distclean: rec_distclean

rec_build rec_clean rec_cleaner\
 rec_distclean rec_install rec_download\
 rec_config rec_debug:
	set -e
	for d in $(subdirs) ; do\
          $(MAKE) -C $$d $(patsubst rec_%,%,$(@)); done
	$(MAKE) subdirs= $(patsubst rec_%,%,$(@))


else # ifneq ($(subdirs),)

#########################################################################
#                  NO recursion
#########################################################################


# We define top_builddir this way which assumes that
# this file is in the top build directory.
top_builddir := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))


ifeq ($(top_builddir),.)
configmakefile := config.make
else
configmakefile := $(top_builddir)/config.make
endif


ifndef top_srcdir
# We are building in the source tree
top_srcdir := $(top_builddir)
srcdir := .
else
# We are NOT building in the source tree
# We should have both top_srcdir and srcdir be full path
ifeq ($(top_builddir),.)
# We are in the top build directory
srcdir := $(top_srcdir)
else
srcdir := $(patsubst $(abspath $(top_builddir))/%, $(abspath $(top_srcdir))/%,\
 $(abspath $(dir $(firstword $(MAKEFILE_LIST)))))
endif
endif # ifndef top_srcdir


ifneq ($(strip $(srcdir)),.)
# Tell make where to find source files, because we are building
# from a directory different than the source directory.
VPATH := .:$(srcdir)
#vpath %.cpp $(srcdir)
endif




ifneq ($(strip $(patsubst clean%,foobar, $(MAKECMDGOALS))),foobar)
#$(warning including config.make)
-include $(configmakefile)
endif

-include $(top_srcdir)/package.make

###################################################################
#  Common variables that are set with the package
###################################################################


# we are avoiding package specific constants


###################################################################



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




config_vars := $(strip\
 PREFIX\
 JS_COMPRESS\
 CSS_COMPRESS\
 NODEJS_SHABANG\
 CFLAGS\
 CXXFLAGS\
 CPPFLAGS\
 TOP_BUILDDIR\
 $(CONFIG_VARS)\
)

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
undefine Sedsinstalled
undefine seds
# now we have the sed_commands for making * from *.in files

define Dependify
  $(1): $(1).$(2)
endef

# download (dl) scripts FILE.dl that download FILE
# dl_scripts is the things downloaded
dl_scripts := $(patsubst $(srcdir)/%.dl,%,$(wildcard $(srcdir)/*.dl))
$(foreach targ,$(dl_scripts),$(eval $(call Dependify,$(targ),dl)))

# In files, FILE.in, that build files named FILE
# in_files is the things built
in_files := $(patsubst $(srcdir)/%.in,%,$(wildcard $(srcdir)/*.in))
$(foreach targ,$(in_files),$(eval $(call Dependify,$(targ),in $(configmakefile))))

# *.bl.in
bl_in_scripts := $(sort\
 $(patsubst $(srcdir)/%.bl.in,%,$(wildcard $(srcdir)/*.bl.in))\
)
$(foreach targ,$(bl_in_scripts),$(eval $(call Dependify,$(targ),bl)))

# build (bl) scripts FILE.bl that build files named FILE
# bl_scripts is the files built
bl_scripts := $(sort\ $(filter-out $(bl_in_scripts),\
 $(patsubst $(srcdir)/%.bl,%,$(wildcard $(srcdir)/*.bl))\
))
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
 $$(name).d_target := $$(name).$(4)
 $$(name).$(4)_compile := $$($(3)_compile)
 $$(name).d_compile := $$($(3)_compile)
 $$(name).d $$(name).$(4): $(2).$(3)
 dependfiles := $(dependfiles) $$(name).d
 $(1)_objects := $$(strip $$($(1)_objects) $$(name).$(4))
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
  # list object files for this program is $(1)_objects
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

# files that are built via BUILD and unless listed in
# $(BUILD_NO_INSTALL) are installed too.
common_built := $(strip\
\
 $(patsubst $(srcdir)/%.jsp,%.js,$(wildcard $(srcdir)/*.jsp))\
 $(patsubst $(srcdir)/%.cs,%.css,$(wildcard $(srcdir)/*.cs))\
\
 $(patsubst $(srcdir)/%.jsp.in,%.js,$(wildcard $(srcdir)/*.jsp.in))\
 $(patsubst $(srcdir)/%.cs.in,%.css,$(wildcard $(srcdir)/*.cs.in))\
\
 $(patsubst $(srcdir)/%.jsp.bl.in,%.js,$(wildcard $(srcdir)/*.jsp.bl.in))\
 $(patsubst $(srcdir)/%.cs.bl.in,%.css,$(wildcard $(srcdir)/*.cs.bl.in))\
\
 $(patsubst $(srcdir)/%.js.bl,%.js,$(wildcard $(srcdir)/*.js.bl))\
 $(patsubst $(srcdir)/%.css.bl,%.css,$(wildcard $(srcdir)/*.css.bl))\
\
 $(patsubst $(srcdir)/%.js.in,%.js,$(wildcard $(srcdir)/*.js.in))\
 $(patsubst $(srcdir)/%.css.in,%.css,$(wildcard $(srcdir)/*.css.in))\
\
 $(patsubst $(srcdir)/%.js.bl.in,%.js,$(wildcard $(srcdir)/*.js.bl.in))\
 $(patsubst $(srcdir)/%.css.bl.in,%.css,$(wildcard $(srcdir)/*.css.bl.in))\
\
 $(patsubst $(srcdir)/%.jsp.bl,%.js,$(wildcard $(srcdir)/*.jsp.bl))\
 $(patsubst $(srcdir)/%.cs.bl,%.css,$(wildcard $(srcdir)/*.cs.bl))\
\
 $(patsubst $(srcdir)/%.js.dl,%.js,$(wildcard $(srcdir)/*.js.dl))\
 $(patsubst $(srcdir)/%.css.dl,%.css,$(wildcard $(srcdir)/*.css.dl))\
\
 $(patsubst $(srcdir)/%.html.in,%.html,$(wildcard $(srcdir)/*.html.in))\
 $(patsubst $(srcdir)/%.html.bl,%.html,$(wildcard $(srcdir)/*.html.bl))\
 $(patsubst $(srcdir)/%.html.bl.in,%.html,$(wildcard $(srcdir)/*.html.bl.in))\
\
 $(bins)\
 $(libs)\
 $(BUILD)\
 $(BUILD_NO_INSTALL)\
)


installed := $(sort $(filter-out $(BUILD_NO_INSTALL),\
 $(common_built)\
 $(wildcard *.js *.css *.html *.gif *.jpg *.png)\
 $(INSTALLED)\
))

# We tally up all the files that are built including all possible
# intermediate files, and exclude $(dependfiles) $(objects) which are
# handled in qb_build/
built := $(sort $(filter-out $(downloaded),\
 $(common_built)\
 $(bl_scripts)\
 $(bl_in_scripts)\
 $(in_files)\
))


installed_src := $(sort $(filter-out $(built), $(installed)))

installed_built := $(sort $(filter-out $(installed_src), $(installed)))

installed_src := $(sort $(patsubst %,$(srcdir)/%,$(installed_src)))

installed := $(sort $(installed_built) $(installed_src))


cleanfiles := $(sort $(built) $(CLEANFILES))

cleanerfiles := $(sort $(CLEANERFILES) $(wildcard *.pyc))

ifeq ($(strip $(top_builddir)),.)
    cleanerfiles := $(cleanerfiles) $(configmakefile)
endif


cleandirs := $(CLEANDIRS)

ifneq ($(strip $(objects)),)
  cleandirs := $(sort $(cleandirs) qb_build)

# We cannot use a directory as a dependency since it's modification date
# changed as files in it change, so we use a touch file in the
# directory.
$(dependfiles) $(objects): qb_build/depend.touch
qb_build/depend.touch:
	mkdir qb_build
	touch $@

# Rules to build C/C++ programs

# How to build object files
qb_build/%.o:
	$($@_compile) $($@_cflags) -c $< -o $@
# How to build library shared object files
qb_build/%.lo:
	$($@_compile) $($@_cflags) -fPIC -c $< -o $@


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
# We do not want to include depend files for target "download"
ifneq ($(strip $(MAKECMDGOALS)),download)
# include with no error if we need to build them
-include $(dependfiles)

endif
endif


undefine nodepend
endif # ifneq ($(strip $(objects)),)



# default target
build: $(downloaded) $(built) $(configmakefile)
# download before building
$(built): | $(downloaded)


# run 'make debug' to just spew this stuff:
debug:
	@echo "configmakefile=$(configmakefile)"
	@echo "objects=$(objects)"
	@echo "cleanerfiles=$(cleanerfiles)"
	@echo "cleanfiles=$(cleanfiles)"
	@echo "INSTALL_DIR=$(INSTALL_DIR)"
	@echo "built=$(built)"
	@echo "downloaded=$(downloaded)"
	@echo "installed=$(installed)"
	@echo "installed_built=$(installed_built)"
	@echo "installed_src=$(installed_src)"
	@echo "dependfiles=$(dependfiles)"
	@echo "srcdir=$(srcdir)"
	@echo "top_srcdir=$(top_srcdir)"
	@echo "top_builddir=$(top_builddir)"


help:
	@echo -e "  $(MAKE) [TARGET]\n"
	@echo -e "  Common TRAGETs are:"
	@echo -e '$(foreach \
	    var,build install download clean distclean,\n   $(var))' 


# some recipes not based on suffix

# download script to targets
# *.dl -> *
$(dl_scripts):
	$(srcdir)/$@.dl || (rm -rf $@ ; exit 1)

# *.bl -> *
$(bl_scripts):
	$(srcdir)/$@.bl || (rm -rf $@ ; exit 1)

# *.bl -> * that have *.bl.in files in the source
# so the *.bl file will be in the build tree.
$(bl_in_scripts):
	./$@.bl || (rm -rf $@ ; exit 1)

# It's very important to say: "This is a generated file" in the upper
# comments of generated files, hence this messy 'bash/sed' code just
# below.
# *.in -> *
$(in_files):
	if head -1 $< | grep -E '^#!' ; then\
	  sed -n '1,1p' $< | sed $(sed_commands) > $@ &&\
          if [ -n "$($@_GEN_COMMENT)" ] ; then\
            echo -e "$($@_GEN_COMMENT)"  >> $@ ;\
          else\
	    echo -e "# This is a generated file\n" >> $@ ; fi ;\
	  sed '1,1d' $< | sed $(sed_commands) >> $@ ;\
	elif [[ "$@" =~ \.jsp$$|\.js$$|\.cs$$|\.css$$ ]] ; then\
	  echo -e "/* This is a generated file */\n" > $@ &&\
	  sed $< $(sed_commands) >> $@ ;\
	else\
	  sed $< $(sed_commands) > $@ ; fi
	if [[ $@ == *.bl ]] ; then chmod 755 $@ ; fi
	if [ -n "$($@_MODE)" ] ; then chmod $($@_MODE) $@ ; fi


# some suffix rules the find source from VPATH

# *.jsp -> *.js
%.js: %.jsp
	echo "/* This is a generated file */" > $@
	$(JS_COMPRESS) $< >> $@

# *.cs -> *.css
%.css: %.cs
	echo "/* This is a generated file */" > $@
	$(CSS_COMPRESS) $< >> $@


# We have just one install directory for a given source directory
# TODO: If the 'build' target has targets in other directories
# the install needs, this will fail without running:
#   make   before   make install
#
install: $(installed)
ifneq ($(INSTALL_DIR),)
	mkdir -p $(INSTALL_DIR)
ifneq ($(installed),)
	cp -r $(installed) $(INSTALL_DIR)
endif
ifneq ($(strip $(POST_INSTALL_COMMAND)),)
	$(POST_INSTALL_COMMAND)
endif
endif


ifneq ($(strip $(dependfiles)),)
$(dependfiles): $(configmakefile)
endif

ifeq ($(top_builddir),.)
config:
	@echo -e "\nForcing a remaking of config.make\n"
	rm -f config.make
	$(MAKE) config.make
config.make:
	echo -e "# This is a generated file\n" > $@
	echo -e "$(foreach var,$(config_vars),\n$(var) := $(strip $($(var))\n))" |\
	    sed -e 's/^ $$//' >> $@
else
# Use make in the top build directory and not do recursion
# so subdirs is set to nothing.
$(configmakefile):
	$(MAKE) -C $(top_builddir) subdirs= config.make
endif


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


endif # ifneq ($(subdirs),)  else

endif # ifdef BUILD_PREFIX   else
