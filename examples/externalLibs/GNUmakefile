
x11_hello_SOURCES := x11_hello.c

# We link with the external X11 library finding the necessary compiler
# linker options via the pkg-config program.
x11_hello_LDFLAGS := $(shell pkg-config --libs x11)
# Tell the compiler where to find X11 include files and whatever other
# compiler pre-processor options that are deemed necessary.
x11_hello_CPPFLAGS := $(shell pkg-config --cflags x11)

INSTALL_DIR = $(PREFIX)/bin

include ./quickbuild.make
