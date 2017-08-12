top_srcdir := .

PREFIX = $(CURDIR)/installed

hello_SOURCES := hello.c
hello_ADDLIBS := lib/libhello.so
hello_LDFLAGS := -lm
hello_INSTALL_RPATH = $(PREFIX)/lib


INSTALL_DIR = $(PREFIX)/bin

include $(top_srcdir)/quickbuild.make
