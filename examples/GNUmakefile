# This make file will make everything in this package

# This makefile does not use quickbuild but sub-processes
# that this starts do.

SHELL = /bin/bash

subdirs :=\
 $(sort\
 $(patsubst %/GNUmakefile,%,$(wildcard */GNUmakefile))\
 $(patsubst %/GNUmakefile.in,%,$(wildcard */GNUmakefile.in))\
)

bootstrap_dirs := $(strip\
 $(patsubst %/bootstrap,%,$(wildcard */bootstrap)))

repoclean_dirs := $(strip\
 $(patsubst %/RepoClean,%,$(wildcard */RepoClean)))

test_dirs := $(strip\
 $(patsubst %/test,%,$(wildcard */test)))


built_makefiles := $(sort\
 $(patsubst %/GNUmakefile.in,%/GNUmakefile,\
 $(wildcard */GNUmakefile.in)))

installed := $(wildcard */installed)

.PHONY: build clean bootstrap repoclean

build install config:
	for d in $(subdirs) ; do\
	    if ! $(MAKE) -C $$d $@ ; then exit 1; fi;\
	    done

bootstrap:
	for d in $(bootstrap_dirs) ; do\
	    if [ -e "$$d/quickbuild.make" ] ; then continue; fi;\
	    if !(cd $$d && ./bootstrap) ; then exit 1; fi;\
	    done
build: | bootstrap

debug:
	@echo "bootstrap_dirs = $(bootstrap_dirs)"
	@echo "repoclean_dirs = $(repoclean_dirs)"


repoclean:
	for d in $(repoclean_dirs) ; do\
	    if !(cd $$d && ./RepoClean) ; then exit 1; fi;\
	    done
clean: | repoclean


install: | build
test: | install

test:
	err= ;\
	for d in $(test_dirs) ; do\
	    if !(cd $$d && ./test) ; then err="${err}\n $$d FAILED\n"; fi;\
	    done;\
	if [ -n "$$err" ] ; then echo -e "$${err}"; exit 1; fi;\

clean cleaner distclean:
ifneq ($(strip $(installed)),)
	rm -rf $(installed)
endif
	for d in $(subdirs) ; do\
	    $(MAKE) -C $$d cleaner ; done
ifeq ($(bootstrap_dirs),)
	rm -f $(built_makefiles)
endif

