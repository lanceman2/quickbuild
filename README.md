# quickbuild

a software build system, using GNU make, for C/C++ and web apps
that serve HTML, javascript, and CSS.  It's the build system used
by potato, https://github.com/lanceman2/potato.

## Ports

This is being developed on GNU/Linux systems: xubuntu 16.04 LTS
and Debain 8.

## About

In short, quickbuild uses files suffix rules to build files from source
via GNU make.

quickbuild is currently not intended to port code between operating
systems.

Some familiarly with GNU make and bash is required to use it.


## Usage

If your software project builds binary executables and/or libraries from C
and/or C++ source files quickbuild will create a directory named qb_build
in each build/source directory where a binary is built.

You only need the one file, quickbuild.make, in the top of your source
directory tree.  Include the quickbuild.make in your software project, or
get it from a bootstrap script in your software project that downloads
it.

For example:
```
wget https://raw.github.com/lanceman2/quickbuild/master/quickbuild.make
```

or for a given commit
```
wget https://raw.github.com/lanceman2/quickbuild/FULL_GIT_HASH/quickbuild.make
```
where FULL_GIT_HASH is the full lower case hex encoded git hash for the
commit, like 1e98252310917008b3a8fb675539e7df435d7b9b.

In short, quickbuild uses files suffix rules to build files from source
via GNU make.


## Separate Build Trees

At your option quickbuild can build yours packages in directories that are
separate from the source tree, like CMake and GNU autotools do.  You can
run:

```
make BUILD_PREFIX=../MY_BUILD
```
in the top source directory to generate a build directory tree in
```
../MY_BUILD
```
You can cd (change your working directory) to
```
../MY_BUILD
```
and run
```
make
```
to build the code there.

## GNUmakefile

GNUmakefile is used as the file name of the make files because we use GNU
make make extensions and these make files will only work with GNU make.


## Examples

There are examples in the examples directory.  These examples also serve
as a development test suite.  Each sub directory in examples is a complete
package that uses quickbuild.  This is the best place to see how to use
the quickbuild software package build system.  You can run 'make test' in
the examples directory to build/test all the example packages.


## Development Notes


We intend to keep the compressed (comments and blanks lines removed) copy
of quickbuild.make by under 1000 lines.
