#!/bin/bash

set -e
JOBS=$(nproc)
for target in {i686-elf,x86_64-elf}; do
	binutils-*/configure \
		 --prefix=/usr \
		 --target="$target" \
		 --disable-werror \
		 --disable-doc \
		 --enable-64-bit-bfd
	make -j$JOBS
	make install
	make distclean
done
