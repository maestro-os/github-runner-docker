#!/bin/sh

set -e
JOBS=$(nproc)
binutils-*/configure \
	--prefix=/usr \
	--target="i686-elf" \
	--disable-werror \
	--disable-doc \
	--enable-64-bit-bfd
make -j$JOBS
