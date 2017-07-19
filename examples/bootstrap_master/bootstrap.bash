#!/bin/bash

set -ex

cd $(dirname ${BASH_SOURCE[0]})

cp GNUmakefile.in GNUmakefile

rm -f quickbuild.make

wget https://raw.githubusercontent.com/lanceman2/quickbuild/master/quickbuild.make
