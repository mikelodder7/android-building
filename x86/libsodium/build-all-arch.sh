#!/bin/bash
set -e
rm -rf ${PWD}/sodium_prebuilt

if [ ! -d android-ndk-r16b ] ; then
    if [ ! -f android-ndk-r16b-linux-x86_64.zip ] ; then
        wget -q https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip
    fi
    unzip -qq android-ndk-r16b-linux-x86_64.zip
fi
export ANDROID_NDK_ROOT="${PWD}/android-ndk-r16b"

SODIUM_VERSION=1.0.14

if [ ! -d "libsodium-${SODIUM_VERSION}" ] ; then
    if [ ! -f ${SODIUM_VERSION}.tar.gz ] ; then
        wget -q https://github.com/jedisct1/libsodium/releases/download/${SODIUM_VERSION}/libsodium-${SODIUM_VERSION}.tar.gz || exit 1
    fi 
    if [ ! -f ${SODIUM_VERSION}.tar.gz ] ; then
        echo "Can't find ${SODIUM_VERSION}.tar.gz"
        exit 1
    fi
    tar xf ${SODIUM_VERSION}.tar.gz
fi

#archs=(arm arm64 x86 x86_64 mips mips64)
if [ $# -gt 0 ] ; then
    archs=$@
else
    archs=(arm arm64 x86 x86_64)
fi

OLDPATH=${PATH}

for arch in ${archs[@]}; do
    export NDK_TOOLCHAIN_DIR=${PWD}/${arch}
    if [ ! -d "${NDK_TOOLCHAIN_DIR}" ] ; then
        echo "Creating toolchain directory ${NDK_TOOLCHAIN_DIR}"
        python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch ${arch} --api 21 --install-dir ${NDK_TOOLCHAIN_DIR}
    fi
    export PATH=${NDK_TOOLCHAIN_DIR}/bin:${OLDPATH}
    case ${arch} in
        "arm")
            TARGET_HOST="arm-linux-androideabi"
            ;;
        "arm64")
            TARGET_HOST="aarch64-linux-android"
            ;;
        "mips")
            TARGET_HOST="mipsel-linux-android"
            ;;
        "mips64")
            TARGET_HOST="mips64el-linux-android"
            ;;
        "x86")
	        TARGET_HOST="i686-linux-android"
            ;;
        "x86_64")
	        TARGET_HOST="x86_64-linux-android"
            ;;
        *)
            echo "Unknown architecture"
            exit 1
            ;;
    esac

    TGT_DIR="${PWD}/sodium_prebuilt/${arch}"
    mkdir -p ${TGT_DIR}

    command pushd "libsodium-${SODIUM_VERSION}" > /dev/null

    make clean
    ./autogen.sh
    ./configure --prefix=${TGT_DIR} --disable-soname-versions --host=${TARGET_HOST}
    make
    make install

    command popd > /dev/null
done
exit 0
