# This make file will make everything in this package

# This makefile does not use quickbuild but sub-processes
# that this starts do.

SHELL = /bin/bash

subdirs :=\
 $(sort\
 $(filter-out BUILD_%,\
 $(patsubst %/GNUmakefile,%,$(wildcard */GNUmakefile))\
 $(patsubst %/GNUmakefile.am,%,$(wildcard */GNUmakefile.am))\
 )\
)

builddirs := $(patsubst %,BUILD_%,$(subdirs))

# We make a config.make file for each example directory.
config_makes := $(patsubst %,%/config.make,$(subdirs))

bootstrap_dirs := $(strip\
 $(patsubst %/bootstrap,%,$(wildcard */bootstrap)))

repoclean_dirs := $(strip\
 $(patsubst %/RepoClean,%,$(wildcard */RepoClean)))

test_dirs := $(strip\
 $(filter-out BUILD_%,\
 $(patsubst %/test,%,$(wildcard */test))))
#test_dirs := $(test_dirs) $(patsubst %,BUILD_%,$(test_dirs))


built_makefiles := $(sort\
 $(patsubst %/GNUmakefile.am,%/GNUmakefile,\
 $(wildcard */GNUmakefile.am)))

installed := $(wildcard */installed)

.PHONY: build clean cleaner distclean bootstrap repoclean install

build: $(config_makes)

$(builddirs): bootstrap
	$(MAKE) -C $(patsubst BUILD_%,%,$@) BUILD_PREFIX=../$@


# We must build and run it in the BUILD_ directories before we
# build them in the source directories.
build install: $(builddirs)
	for d in $(builddirs) $(subdirs) ; do\
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
	for d in $(test_dirs) $(builddirs) ; do\
	    echo -e "\n    ----- Running test in $$d -----\n";\
	    if !(cd $$d && ./test) ; then\
	    err="${err}\n test in $$d FAILED\n";\
	    echo -e "\n   test in $$d FAILED\n";\
	    let fcount=$${fcount}+1; fi;\
	    done;\
	if [ -n "$$err" ] ; then echo -e "\n\n  $${fcount} test(s) failed\n$${err}\n"; exit 1; fi;
	@echo -e "\n\n   All $(words $(test_dirs)) tests Succeeded\n"

clean cleaner distclean:
	rm -rf $(builddirs)
ifneq ($(strip $(installed)),)
	rm -rf $(installed)
endif
	for d in $(subdirs) ; do\
	    $(MAKE) -C $$d cleaner ; done
ifeq ($(bootstrap_dirs),)
	rm -f $(built_makefiles)
endif
	for d in $(subdirs) ; do rm -rf $$d/installed ; done

