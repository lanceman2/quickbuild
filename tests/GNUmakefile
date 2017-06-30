
subdirs := $(sort $(patsubst %/GNUmakefile,%,$(wildcard */GNUmakefile)))

build clean cleaner distclean:
	for i in $(subdirs) ; do $(MAKE) -C $$i $@ ; done

