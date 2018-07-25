#!/bin/bash

set -e

GREEN="[0;32m"
BLUE="[0;34m"
NC="[0m"
ESCAPE="\e"
NDK=android-ndk-r17b-linux-x86_64

UNAME=$(uname | tr '[:upper:]' '[:lower:]')

if [ ${UNAME} = "darwin" ] ; then
    ESCAPE="\x1B"
    NDK=android-ndk-r17b-darwin-x86_64
fi

if [ ! -d "${UNAME}-android-ndk-r17b" ] ; then
    if [ ! -f "${NDK}.zip" ] ; then
        echo "Downloading ${NDK}"
        wget -q https://dl.google.com/android/repository/${NDK}.zip
    fi
    echo "Extracting ${NDK}"
    unzip -qq -o ${UNAME}-android-ndk-r17b ${NDK}.zip
fi
export ANDROID_NDK_ROOT="${PWD}/${UNAME}-android-ndk-r17b"

SODIUM_VERSION=1.0.14

if [ ! -d "libsodium-${SODIUM_VERSION}" ] ; then
    if [ ! -f "libsodium-${SODIUM_VERSION}.tar.gz" ] ; then
        echo "Downloading libsodium-${SODIUM_VERSION}"
        wget -q https://github.com/jedisct1/libsodium/releases/download/${SODIUM_VERSION}/libsodium-${SODIUM_VERSION}.tar.gz || exit 1
    fi 
    if [ ! -f "libsodium-${SODIUM_VERSION}.tar.gz" ] ; then
        echo "Can't find libsodium-${SODIUM_VERSION}.tar.gz"
        exit 1
    fi
    echo "Extracting libsodium-${SODIUM_VERSION}"
    tar xf libsodium-${SODIUM_VERSION}.tar.gz
fi

#archs=(arm arm64 x86 x86_64 mips mips64)
if [ $# -gt 0 ] ; then
    archs=$@
else
    archs=(arm armv7 arm64 x86 x86_64)
fi

echo -e "${ESCAPE}${GREEN}Building for ${archs[@]}${ESCAPE}${NC}"
OLDPATH=${PATH}

for arch in ${archs[@]}; do
    case ${arch} in
        "arm")
            export CFLAGS="-Os -mthumb -marm -march=armv6"
            TARGET_HOST="arm-linux-androideabi"
            TARGET_ARCH="arm"
            ;;
        "armv7")
            export CFLAGS="-Os -mfloat-abi=softfp -mfpu=vfpv3-d16 -mthumb -marm -march=armv7-a"
            export LDFLAGS="-march=armv7-a -Wl,--fix-cortex-a8"
            TARGET_HOST="arm-linux-androideabi"
            TARGET_ARCH="arm"
            ;;
        "arm64")
            export CFLAGS="-Os -march=armv8-a"
            TARGET_HOST="aarch64-linux-android"
            TARGET_ARCH="arm64"
            ;;
        "mips")
            export CFLAGS="-Os"
            TARGET_HOST="mipsel-linux-android"
            TARGET_ARCH="mips"
            ;;
        "mips64")
            export CFLAGS="-Os -march=mips64r6"
            TARGET_HOST="mips64el-linux-android"
            TARGET_ARCH="mips64"
            ;;
        "x86")
            export CFLAGS="-Os -march=i686"
	        TARGET_HOST="i686-linux-android"
            TARGET_ARCH="x86"
            ;;
        "x86_64")
            export CFLAGS="-Os -march=westmere"
	        TARGET_HOST="x86_64-linux-android"
            TARGET_ARCH="x86_64"
            ;;
        *)
            echo "Unknown architecture"
            exit 1
            ;;
    esac

    export NDK_TOOLCHAIN_DIR="${PWD}/${UNAME}-${TARGET_ARCH}"
    if [ ! -d "${NDK_TOOLCHAIN_DIR}" ] ; then
        echo "Creating toolchain directory ${NDK_TOOLCHAIN_DIR}"
        python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch ${TARGET_ARCH} --api 21 --install-dir ${NDK_TOOLCHAIN_DIR}
    fi
    export PATH=${NDK_TOOLCHAIN_DIR}/bin:${OLDPATH}
    TGT_DIR="${PWD}/sodium_prebuilt/${arch}"
    rm -rf ${TGT_DIR}
    mkdir -p ${TGT_DIR}

    echo -e "${ESCAPE}${BLUE}Making ${arch}${ESCAPE}${NC}"

    command pushd "libsodium-${SODIUM_VERSION}" > /dev/null

    ./autogen.sh
    ./configure --prefix=${TGT_DIR} --disable-soname-versions --host=${TARGET_HOST}
    make clean
    make
    make install

    command popd > /dev/null

    rm -rf ${TGT_DIR}/lib/pkgconfig
    unset CFLAGS
    unset LDFLAGS
done
exit 0
