# This make file will make everything in this package

# This makefile does not use quickbuild.

SHELL = /bin/bash

subdirs :=\
 $(sort\
 $(patsubst %/GNUmakefile,%,$(wildcard */GNUmakefile))\
 $(patsubst %/GNUmakefile.in,%,$(wildcard */GNUmakefile.in))\
)

bootstrap_dirs := $(strip\
 $(filter-out $(patsubst %/GNUmakefile,%,$(wildcard */GNUmakefile)),\
 $(patsubst %/GNUmakefile.in,%,$(wildcard */GNUmakefile.in))))

built_makefiles := $(sort\
 $(patsubst %/GNUmakefile.in,%/GNUmakefile,\
 $(wildcard */GNUmakefile.in)))

installed := $(wildcard */installed)
qb_copies := $(patsubst %,%/quickbuild.make,$(subdirs))
qb_copies_exist := $(strip $(wildcard $(qb_copies)))


build install config test: $(qb_copies)
	for d in $(subdirs) ; do\
	    if ! $(MAKE) -C $$d $@ ; then exit 1; fi;\
	    done

ifneq ($(bootstrap_dirs),)
bootstrap:
	for d in $(bootstrap_dirs) ; do\
	    if !(cd $$d && ./bootstrap.bash) ; then exit 1; fi;\
	    done
build: | bootstrap
endif


install: | build
test: | install 

$(qb_copies):
	cd $(dir $@) && ln -s ../../quickbuild.make .


clean cleaner distclean:
ifneq ($(qb_copies_exist),)
ifneq ($(strip $(installed)),)
	rm -rf $(installed)
endif
	for d in $(subdirs) ; do\
	    $(MAKE) -C $$d cleaner ; done
	rm -f $(qb_copies)
endif
ifeq ($(bootstrap_dirs),)
	rm -f $(built_makefiles)
endif

