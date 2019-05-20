# quickbuild

a software build system, using GNU make, for C/C++ and web apps
that serve HTML, javascript, and CSS.

## Ports

This is being developed on GNU/Linux systems: Ubuntu 16.04 LTS, Ubuntu
18.04 LTS and Debain 8 and 9.

## About

In short, quickbuild uses files suffix rules to build files from source
via GNU make.

quickbuild is currently not intended to port code between operating
systems.

Some familiarly with GNU make and bash is required to use it.

Some of the make variables it defines and uses are like those in GNU automake.

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
commit, like 1e98252310917008b3a8fb675539e7df435d7b9b, or a tag like 0.1


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

You cannot make a separate build tree for a source tree that you have
already built the source in.  Trying to do so will cause GNU make to
use built files that are in the source, and mix them will files built
files in the build tree.  You may as well stir the code with a stick.


## GNUmakefile

GNUmakefile is used as the file name of the make files because we use GNU
make make extensions and these make files will only work with GNU make.


## Examples

There are examples in the examples directory.  These examples also serve
as a development test suite.  Each sub directory in examples is a complete
package that uses quickbuild, but needs the file quickbuild.make copied to
it.  This is the best place to see how to use the quickbuild software
package build system.  You can run 'make test' in the examples directory
to build and test all the example packages.

Each examples directory contains a script file names test, which is
particular to this test suite and is not part of the example package.
The examples do not need this, test, file to be working package examples.

If you wish to make independent working package examples in the examples
directory run
```
make quickbuild_copies
```
to copy the quickbuild.make file and complete all the example packages; or
just copy quickbuild.make to the top of all the example package directory
yourself.


The top examples directory cannot be built in an alternate build
directory, like the example projects sub-directories can, because it's
subdirectories are setup like independent software projects, so that each
example (subdirectory) can stand on it's own as an independent project.


## Development Notes

We intend to keep the compressed (comments and blanks lines removed) copy
of quickbuild.make by under 1000 lines.  2019 May 20 compressed line
count is 339 with 909 before compressing.

