
-include config_pre.make

ifdef TESTS

BUILD_NO_INSTALL := test1
test1_SOURCES := test1.c

endif

CLEANFILES := config_pre.make

hello_SOURCES := hello.c

INSTALL_DIR = $(PREFIX)/bin

include ./quickbuild.make
