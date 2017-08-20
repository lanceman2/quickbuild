# This make file will make everything in this package

# This makefile does not use quickbuild but sub-processes
# that this starts do.

SHELL = /bin/bash

subdirs :=\
 $(sort\
 $(filter-out BUILD_%,\
 $(patsubst %/GNUmakefile,%,$(wildcard */GNUmakefile))\
 $(patsubst %/bootstrap,%,$(wildcard */bootstrap))\
 )\
)

builddirs := $(patsubst %,BUILD_%,$(subdirs))


bootstrap_dirs := $(strip\
 $(patsubst %/bootstrap,%,$(wildcard */bootstrap)))

repoclean_dirs := $(strip\
 $(patsubst %/RepoClean,%,$(wildcard */RepoClean)))

test_dirs := $(strip\
 $(filter-out BUILD_%,\
 $(patsubst %/test,%,$(wildcard */test))))
#test_dirs := $(test_dirs) $(patsubst %,BUILD_%,$(test_dirs))


installed := $(wildcard */installed)

.PHONY: build clean cleaner distclean bootstrap repoclean test

$(builddirs): bootstrap
	$(MAKE) -C $(patsubst BUILD_%,%,$@) BUILD_PREFIX=../$@


# We must build and install it in the BUILD_ directories before we
# build and install them in the source directories.
build: $(builddirs)
	set -e
	for d in $(builddirs) $(subdirs) ; do\
	    PREFIX=$(PWD)/$$d/installed $(MAKE) -C $$d $@;\
	    $(MAKE) -C $$d install $@;\
	    done


bootstrap:
	set -e
	for d in $(bootstrap_dirs) ; do\
	    if [ -e "$$d/quickbuild.make" ] ; then continue; fi;\
	    cd $$d && ./bootstrap && cd - ;\
	    done

debug:
	@echo "bootstrap_dirs = $(bootstrap_dirs)"
	@echo "repoclean_dirs = $(repoclean_dirs)"


test: build
	err= ; fcount=0 ;\
	for d in $(test_dirs) $(builddirs) ; do\
	    echo -e "\n    ----- Running test in $$d -----\n";\
	    if !(cd $$d && ./test) ; then\
	    err="$${err}\n test in $$d FAILED\n";\
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
	for d in $(repoclean_dirs) ; do\
          if !(cd $$d && ./RepoClean) ; then exit 1; fi;\
          done


