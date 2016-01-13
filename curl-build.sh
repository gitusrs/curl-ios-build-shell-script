#!/bin/bash

#  Created by FangYuan Gui on 13.01.16.
#  Copyright 2011 FangYuan Gui. All rights reserved.
#
#  Licensed under the Apache License

set -u

CURL_SRC_DIR=""
UNCOMPRESSED_CMD=""
CURL_COMPRESSED_FN="curl-7.46.0.tar.bz2"

MIME_TYPE=$(file ${CURL_COMPRESSED_FN} -b --mime-type) || exit 1

if [ "application/zip" == "${MIME_TYPE}" ]; then
    CURL_SRC_DIR=${CURL_COMPRESSED_FN//.zip*/}
    UNCOMPRESSED_CMD="unzip -q ${CURL_COMPRESSED_FN} || exit 1"
elif [ "application/x-gzip" == "${MIME_TYPE}" ]; then
    CURL_SRC_DIR=${CURL_COMPRESSED_FN//.tar*/}
    UNCOMPRESSED_CMD="tar xfz ${CURL_COMPRESSED_FN} || exit 1"
elif [ "application/x-bzip2" == "${MIME_TYPE}" ]; then
    CURL_SRC_DIR=${CURL_COMPRESSED_FN//.tar*/}
    UNCOMPRESSED_CMD="tar jxf ${CURL_COMPRESSED_FN} || exit 1"
else
    echo "can't uncompress ${CURL_COMPRESSED_FN}"
    exit 1
fi

CURL_BUILD_DIR=${PWD}/${CURL_SRC_DIR}-build
CURL_BUILD_LOG_DIR=${CURL_BUILD_DIR}/log
CURL_BUILD_UNIVERSAL_DIR=${CURL_BUILD_DIR}/universal

rm -rf ${CURL_SRC_DIR}
rm -rf ${CURL_BUILD_DIR}
eval "${UNCOMPRESSED_CMD}"

if [ ! -d "${CURL_BUILD_UNIVERSAL_DIR}" ]; then
    mkdir -p "${CURL_BUILD_UNIVERSAL_DIR}"
fi

if [ ! -d "${CURL_BUILD_LOG_DIR}" ]; then
    mkdir "${CURL_BUILD_LOG_DIR}"
fi

pushd .
cd ${CURL_SRC_DIR}

GCC=$(xcrun --find gcc)
export CC="${GCC}"

IPHONE_OS_SDK_PATH=$(xcrun -sdk iphoneos --show-sdk-path)
IPHONE_SIMULATOR_SDK_PATH=$(xcrun -sdk iphonesimulator --show-sdk-path)

ARCH_LIST=("armv7" "armv7s" "arm64" "i386" "x86_64")
ARCH_COUNT=${#ARCH_LIST[@]}
HOST_LIST=("armv7-apple-darwin" "armv7s-apple-darwin" "arm-apple-darwin" "i386-apple-darwin" "x86_64-apple-darwin")
IOS_SDK_PATH_LIST=(${IPHONE_OS_SDK_PATH} ${IPHONE_OS_SDK_PATH} ${IPHONE_OS_SDK_PATH} ${IPHONE_SIMULATOR_SDK_PATH} ${IPHONE_SIMULATOR_SDK_PATH})

config_make()
{
ARCH=$1
HOST_VAL=$3
IOS_SDK_PATH=$2
#export CFLAGS="-arch ${ARCH} -isysroot ${IOS_SDK_PATH} -fembed-bitcode -miphoneos-version-min=6.0"
export CFLAGS="-arch ${ARCH} -isysroot ${IOS_SDK_PATH} -miphoneos-version-min=6.0"

make clean &> ${CURL_BUILD_LOG_DIR}/make_clean.log

echo "configure for ${ARCH}..."

#./configure --host=${HOST_VAL} --prefix=${CURL_BUILD_DIR}/${ARCH} --disable-shared --enable-static --disable-manual --disable-verbose --without-ldap --disable-ldap --enable-ipv6 --enable-threaded-resolver --with-zlib="${IOS_SDK_PATH}/usr" --without-ssl &> ${CURL_BUILD_LOG_DIR}/${ARCH}-conf.log
./configure --host=${HOST_VAL} --prefix=${CURL_BUILD_DIR}/${ARCH} --disable-shared --enable-static --disable-manual --disable-verbose --without-ldap --disable-ldap --enable-ipv6 --enable-threaded-resolver --with-zlib="${IOS_SDK_PATH}/usr" --with-ssl="/Users/x/Desktop/openssl-1.0.2e-build/universal" &> ${CURL_BUILD_LOG_DIR}/${ARCH}-conf.log

echo "build for ${ARCH}..."
make &> ${CURL_BUILD_LOG_DIR}/${ARCH}-make.log
make install &> ${CURL_BUILD_LOG_DIR}/${ARCH}-make-install.log

unset CFLAGS

echo -e "\n"
}

for ((i=0; i < ${ARCH_COUNT}; i++))
do
config_make ${ARCH_LIST[i]} ${IOS_SDK_PATH_LIST[i]} ${HOST_LIST[i]}
done

unset CC

LIB_PATHS=( ${ARCH_LIST[@]/#/${CURL_BUILD_DIR}/} )
LIB_PATHS=( ${LIB_PATHS[@]/%//lib/libcurl.a} )
lipo ${LIB_PATHS[@]} -create -output ${CURL_BUILD_UNIVERSAL_DIR}/libcurl.a

cp -R ${CURL_BUILD_DIR}/armv7/include/curl ${CURL_BUILD_UNIVERSAL_DIR}
mv ${CURL_BUILD_UNIVERSAL_DIR}/curl/curlbuild.h  ${CURL_BUILD_UNIVERSAL_DIR}/curl/curlbuild-32.h
cp ${CURL_BUILD_DIR}/arm64/include/curl/curlbuild.h ${CURL_BUILD_UNIVERSAL_DIR}/curl/curlbuild-64.h
echo -e "#if defined(__LP64__) && __LP64__ \n#include \"curlbuild-64.h\" \n#else \n#include \"curlbuild-32.h\" \n#endif" &> ${CURL_BUILD_UNIVERSAL_DIR}/curl/curlbuild.h

popd

rm -rf ${CURL_SRC_DIR}

echo "done."
