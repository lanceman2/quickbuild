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

bootstrap_dirs := $(patsubst %/bootstrap,%,$(wildcard */bootstrap))

# We assume that all the example that have a bootstrap
# will download their copy of quickbuild.make
quickbuild_copies :=\
 $(patsubst %,%/quickbuild.make,\
 $(filter-out $(bootstrap_dirs), $(subdirs)))

builddirs := $(patsubst %,BUILD_%,$(subdirs))


bootstrap_dirs := $(strip\
 $(patsubst %/bootstrap,%,$(wildcard */bootstrap)))

quickbuild_downloads := $(patsubst %,%/quickbuild.make,$(bootstrap_dirs))

repoclean_dirs := $(strip\
 $(patsubst %/RepoClean,%,$(wildcard */RepoClean)))

test_dirs := $(strip\
 $(filter-out BUILD_%,\
 $(patsubst %/test,%,$(wildcard */test))))
#test_dirs := $(test_dirs) $(patsubst %,BUILD_%,$(test_dirs))


installed := $(wildcard */installed)

.PHONY: build clean cleaner distclean repoclean test

.DEFAULT_GOAL := test

$(builddirs): $(quickbuild_downloads)
	set -e
	$(MAKE) -C $(patsubst BUILD_%,%,$@) BUILD_PREFIX=../$@
	if [ -x $(patsubst BUILD_%,%,$@)/test ] ; then\
          cp $(patsubst BUILD_%,%,$@)/test $@ ; fi

$(quickbuild_copies):
	cp ../quickbuild.make $@

quickbuild_copies: $(quickbuild_copies)

# We must build and install it in the BUILD_ directories before we
# build and install them in the source directories.
build: $(quickbuild_copies) $(builddirs)
	set -e
	for d in $(builddirs) $(subdirs) ; do\
	    PREFIX=$(PWD)/$$d/installed $(MAKE) -C $$d $@;\
	    $(MAKE) -C $$d install $@;\
	    done

$(quickbuild_downloads):
	set -e
	for d in $(bootstrap_dirs) ; do\
	    if [ -e "$$d/quickbuild.make" ] ; then continue; fi;\
	    cd $$d && ./bootstrap && cd - ;\
	    done

debug:
	@echo "bootstrap_dirs = $(bootstrap_dirs)"
	@echo "repoclean_dirs = $(repoclean_dirs)"


test: build
	err= ; fcount=0 ; tcount=0;
	for d in $(test_dirs) $(builddirs) ; do\
	  cd $$d ;\
	  if [ -x test ] ; then \
            let tcount=$${tcount}+1 ;\
            echo -e "\n    ----- Running test in $$d -----\n";\
            if ! ./test ; then\
              let fcount=$${fcount}+1 ;\
              err="$${err}\n   test in $$d FAILED\n";\
              echo -e "\n   test in $$d FAILED\n";\
            fi ;\
          fi ;\
          cd .. ;\
          done ;\
          if [ -n "$$err" ] ; then echo -e "\n\n  $${fcount}/$${tcount} test(s) failed\n$${err}\n"; exit 1; fi;\
          echo -e "\n\n   All $${tcount}/$${tcount} tests Succeeded\n"


clean cleaner distclean:
	rm -rf $(builddirs)
ifneq ($(strip $(installed)),)
	rm -rf $(installed)
endif
	for d in $(subdirs) ; do\
          if [ -f $$d/quickbuild.make ] ; then\
            $(MAKE) -C $$d cleaner ; fi ;\
          done
	for d in $(repoclean_dirs) ; do\
          if !(cd $$d && ./RepoClean) ; then exit 1; fi;\
          done
	rm -rf $(quickbuild_copies)

