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

# See https://github.com/zeromq/libzmq/issues/3131 if you can't build it for 64-bit
ZMQ_VERSION=4.2.5

if [ ! -d "zeromq-${ZMQ_VERSION}" ] ; then
    if [ ! -f "zeromq-${ZMQ_VERSION}.tar.gz" ] ; then
        echo "Downloading zeromq-${ZMQ_VERSION}"
        wget -q https://github.com/zeromq/libzmq/releases/download/v${ZMQ_VERSION}/zeromq-${ZMQ_VERSION}.tar.gz || exit 1
    fi 
    if [ ! -f "zeromq-${ZMQ_VERSION}.tar.gz" ] ; then
        echo "Can't find zeromq-${ZMQ_VERSION}.tar.gz"
        exit 1
    fi
    echo "Extracting zeromq-${ZMQ_VERSION}"
    tar xf zeromq-${ZMQ_VERSION}.tar.gz
fi

#archs=(arm arm64 x86 x86_64 mips mips64)
if [ $# -gt 0 ] ; then
    archs=$@
else
    archs=(arm armv7 arm64 x86 x86_64)
fi

echo -e "${ESCAPE}${GREEN}Building for ${archs[@]}${ESCAPE}${NC}"
OLDPATH=${PATH}

export ZMQ_HAVE_ANDROID=1

for arch in ${archs[@]}; do
    case ${arch} in
        "arm")
            export CFLAGS="-Os -mthumb -marm -march=armv6"
            export CXXFLAGS="-Os -mthumb -marm -march=armv6"
            TARGET_HOST="arm-linux-androideabi"
            TARGET_ARCH="arm"
            ;;
        "armv7")
            export CFLAGS="-Os -mfloat-abi=softfp -mfpu=vfpv3-d16 -mthumb -marm -march=armv7-a"
            export CXXFLAGS="-Os -mfloat-abi=softfp -mfpu=vfpv3-d16 -mthumb -marm -march=armv7-a"
            export LDFLAGS="-march=armv7-a -Wl,--fix-cortex-a8"
            TARGET_HOST="arm-linux-androideabi"
            TARGET_ARCH="arm"
            ;;
        "arm64")
            export CFLAGS="-Os -march=armv8-a"
            export CXXFLAGS="-Os -march=armv8-a"
            TARGET_HOST="aarch64-linux-android"
            TARGET_ARCH="arm64"
            ;;
        "mips")
            export CFLAGS="-Os"
            export CXXFLAGS="-Os"
            TARGET_HOST="mipsel-linux-android"
            TARGET_ARCH="mips"
            ;;
        "mips64")
            export CFLAGS="-Os -march=mips64r6"
            export CXXFLAGS="-Os -march=mips64r6"
            TARGET_HOST="mips64el-linux-android"
            TARGET_ARCH="mips64"
            ;;
        "x86")
            export CFLAGS="-Os"
            export CXXFLAGS="-Os"
	        TARGET_HOST="i686-linux-android"
            TARGET_ARCH="x86"
            ;;
        "x86_64")
            export CFLAGS="-Os"
            export CXXFLAGS="-Os"
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
    SODIUM_DIR="${PWD}/sodium_prebuilt/${arch}"
    if [ ! -d "${SODIUM_DIR}" ] ; then
        echo "Cannot find ${SODIUM_DIR}"
        echo "ZeroMQ depends on libsodium"
        exit 1
    fi
    export PATH=${NDK_TOOLCHAIN_DIR}/bin:${OLDPATH}
    export SODIUM_LIB_DIR=${SODIUM_DIR}/lib
    TGT_DIR="${PWD}/zmq_prebuilt/${arch}"
    rm -rf ${TGT_DIR}
    mkdir -p ${TGT_DIR}

    echo -e "${ESCAPE}${BLUE}Making ${arch}${ESCAPE}${NC}"

    command pushd "zeromq-${ZMQ_VERSION}" > /dev/null

    ./autogen.sh
    ./configure CPP=${NDK_TOOLCHAIN_DIR}/bin/${TARGET_HOST}-cpp \
                 CC=${NDK_TOOLCHAIN_DIR}/bin/${TARGET_HOST}-clang \
                CXX=${NDK_TOOLCHAIN_DIR}/bin/${TARGET_HOST}-clang++ \
                 LD=${NDK_TOOLCHAIN_DIR}/bin/${TARGET_HOST}-ld \
                 AS=${NDK_TOOLCHAIN_DIR}/bin/${TARGET_HOST}-as \
                 AR=${NDK_TOOLCHAIN_DIR}/bin/${TARGET_HOST}-ar \
             RANLIB=${NDK_TOOLCHAIN_DIR}/bin/${TARGET_HOST}-ranlib \
             CFLAGS="-I${TGT_DIR}/include/ -D__ANDROID_API__=21 -fPIC" \
           CPPFLAGS="-I${TGT_DIR}/include/ -D__ANDROID_API__=21 -fPIC" \
           CXXFLAGS="-I${TGT_DIR}/include/ -D__ANDROID_API__=21 -fPIC" \
            LDFLAGS="-I${TGT_DIR}/lib/ -D__ANDROID_API__=21" \
               LIBS="-lc -lgcc -ldl -lc++abi -latomic" \
    PKG_CONFIG_PATH="${TGT_DIR}/lib/pkgconfig" \
                --host=${TARGET_HOST} \
                --prefix=${TGT_DIR} \
                --with-libsodium=${SODIUM_DIR} \
                --without-docs \
                --enable-static \
                --with-sysroot=${NDK_TOOLCHAIN_DIR}/sysroot
    make clean
    make
    make install

    command popd > /dev/null

    rm -rf ${TGT_DIR}/lib/pkgconfig
    rm -rf ${TGT_DIR}/bin
    unset CFLAGS
    unset CXXFLAGS
    unset LDFLAGS

done
exit 0
