# quickbuild

a software build system, using GNU make, for C/C++ and web apps
that server HTML, javascript, and CSS.

## Ports

This is being developed on GNU/Linux systems: xubuntu 16.04 LTS
and Debain 8


## Usage

If your software project builds binary executables and/or libraries from C
and/or C++ source files quickbuild will create a directory named qb_build
in each build/source directory where a binary is built.


Include the quickbuild.make in your software project of get it from
a bootstrap script in your software project that downloads it.

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


## Limitations

quickbuild will only generate files in the directories in the source
directory, put another why; the build directory is the source directory.  Why?

  * quickbuild does not require a *configure* step which is where this kind
    of thing is commonly done, for example in Cmake, and autoConf

  * this is makes build and test run development cycles simpler,

  * less software build steps.


## Development


