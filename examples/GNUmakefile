# This make file will make everything in this package: quickbuild in ..,
# and all the examples which are example packages.

SHELL = /bin/bash

subdirs := $(patsubst %/GNUmakefile,%,$(wildcard */GNUmakefile))

installed := $(wildcard */installed)
qb_copies := $(patsubst %,%/quickbuild.make,$(subdirs))

build config: $(qb_copies)
	for d in $(subdirs) ; do\
	    if ! $(MAKE) -C $$d $@ ; then exit 1; fi;\
	    done

# TODO: test
test: build

$(qb_copies):
	cd $(dir $@) && ln -s ../../quickbuild.make .


clean cleaner distclean:
ifneq ($(strip $(installed)),)
	rm -rf $(installed)
endif
	for d in $(subdirs) ; do\
	    $(MAKE) -C $$d cleaner ; done
	rm -f $(qb_copies)

