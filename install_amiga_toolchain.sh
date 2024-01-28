#!/bin/sh

if [ -z ${VBCC} ]
then
  echo "Environment variable VBCC not set; please define it."
  exit 1
fi

echo "Environment variable VBCC points to ${VBCC}."

mkdir -p $VBCC

command -v curl &> /dev/null && fetch=curl
command -v wget &> /dev/null && fetch=wget
command -v wget2 &> /dev/null && fetch=wget2

if [ -z "${fetch}" ]
then
  echo "Could not find wget, wget2 nor curl; please install either one."
  exit 1
fi

echo "Command to fetch is ${fetch}."

command -v lhasa &> /dev/null && lha=lhasa
command -v lha &> /dev/null && lha=lha

if [ -z "${lha}" ]
then
  echo "Could not find lha nor lhasa; please install either one."
  exit 1
fi

echo "Command to unpack .lha is ${lha}."

mkdir -p vbcc_tools
mkdir -p vbcc

cd vbcc_tools

${fetch} http://sun.hasenbraten.de/vasm/release/vasm.tar.gz
${fetch} http://sun.hasenbraten.de/vlink/release/vlink.tar.gz
${fetch} http://www.ibaug.de/vbcc/vbcc.tar.gz
${fetch} http://phoenix.owl.de/vbcc/current/vbcc_target_m68k-amigaos.lha
${fetch} http://phoenix.owl.de/vbcc/current/vbcc_unix_config.tar.gz

tar -zxpf vbcc.tar.gz
cd vbcc
mkdir -p bin
ln -s ucpp vcpp
TARGET=m68k
make CC='gcc -std=c9x -g' TARGET=${TARGET} bin/dtgen bin/vc bin/vprof bin/vbcc${TARGET}
cp -prf bin ../../vbcc
TARGET=m68ks
make CC='gcc -std=c9x -g' TARGET=${TARGET} bin/vbcc${TARGET}
cp -prf bin ../../vbcc

cd ..
${lha} -x -qf vbcc_target_m68k-amigaos.lha
cp -pr vbcc_target_m68k-amigaos/* ../vbcc

cd ../vbcc
tar -zxpf ../vbcc_tools/vbcc_unix_config.tar.gz

cd ../vbcc_tools
tar -zxpf vasm.tar.gz
cd vasm
make CPU=m68k SYNTAX=mot ; make clean
make CPU=m68k SYNTAX=oldstyle ; make clean
make CPU=m68k SYNTAX=std
cp -pf vasmm68k_mot vasmm68k_oldstyle vasmm68k_std vobjdump ../../vbcc/bin

cd ..
tar -zxpf vlink.tar.gz
cd vlink
make
cp -pf vlink ../../vbcc/bin

cd ../../vbcc
mkdir -p NDK_3.2

cd NDK_3.2
${fetch} https://aminet.net/dev/misc/NDK3.2.lha
${lha} -x -qf NDK3.2.lha
cd ..
cp -prf NDK_3.2/Include_h/* targets/m68k-amigaos/include
rm -rf NDK_3.2

cd ..

rm -rf vbcc/Install* vbcc/bin/.dummy vbcc/bin/*.dSYM
chmod 644 vbcc/config/*

cp -pfr vbcc/* $VBCC/

unset TARGET fetch lha
