# This make file will make everything in this package

# This makefile does not use quickbuild but sub-processes
# that this starts do.

SHELL = /bin/bash

subdirs :=\
 $(sort\
 $(patsubst %/GNUmakefile,%,$(wildcard */GNUmakefile))\
 $(patsubst %/GNUmakefile.am,%,$(wildcard */GNUmakefile.am))\
)

# We make a config.make file for each example directory.
config_makes := $(patsubst %,%/config.make,$(subdirs))

bootstrap_dirs := $(strip\
 $(patsubst %/bootstrap,%,$(wildcard */bootstrap)))

repoclean_dirs := $(strip\
 $(patsubst %/RepoClean,%,$(wildcard */RepoClean)))

test_dirs := $(strip\
 $(patsubst %/test,%,$(wildcard */test)))



built_makefiles := $(sort\
 $(patsubst %/GNUmakefile.am,%/GNUmakefile,\
 $(wildcard */GNUmakefile.am)))

installed := $(wildcard */installed)

.PHONY: build clean bootstrap repoclean

build: $(config_makes)

build install:
	for d in $(subdirs) ; do\
	    if ! $(MAKE) -C $$d $@ ; then exit 1; fi;\
	    done

config: $(config_makes)

$(config_makes): | bootstrap
	PREFIX=$(abspath $(dir $@))/installed $(MAKE) -C $(dir $@) config



bootstrap:
	for d in $(bootstrap_dirs) ; do\
	    if [ -e "$$d/quickbuild.make" ] ; then continue; fi;\
	    if !(cd $$d && ./bootstrap) ; then exit 1; fi;\
	    done

debug:
	@echo "bootstrap_dirs = $(bootstrap_dirs)"
	@echo "repoclean_dirs = $(repoclean_dirs)"


repoclean:
	for d in $(repoclean_dirs) ; do\
	    if !(cd $$d && ./RepoClean) ; then exit 1; fi;\
	    done
clean: | repoclean


install: build
test: install

test:
	err= ; fcount=0 ;\
	for d in $(test_dirs) ; do\
	    echo -e "\n    ----- Running test in $$d -----\n";\
	    if !(cd $$d && ./test) ; then\
	    err="${err}\n test in $$d FAILED\n";\
	    echo -e "\n   test in $$d FAILED\n";\
	    let fcount=$${fcount}+1; fi;\
	    done;\
	if [ -n "$$err" ] ; then echo -e "\n\n  $${fcount} test(s) failed\n$${err}\n"; exit 1; fi;
	@echo -e "\n\n   All $(words $(test_dirs)) tests Succeeded\n"

clean cleaner distclean:
ifneq ($(strip $(installed)),)
	rm -rf $(installed)
endif
	for d in $(subdirs) ; do\
	    $(MAKE) -C $$d cleaner ; done
ifeq ($(bootstrap_dirs),)
	rm -f $(built_makefiles)
endif
	for d in $(subdirs) ; do rm -rf $$d/installed ; done

