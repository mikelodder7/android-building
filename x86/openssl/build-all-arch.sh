#!/bin/bash

set -e

GREEN="[0;32m"
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

OPENSSL_VERSION=openssl-1.1.0h

if [ ! -d "${OPENSSL_VERSION}" ] ; then
    if [ ! -f ${OPENSSL_VERSION}.tar.gz ] ; then
        echo "Downloading ${OPENSSL_VERSION}"
        wget -q https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz
    fi 
    if [ ! -f ${OPENSSL_VERSION}.tar.gz ] ; then
        echo "Can't find ${OPENSSL_VERSION}.tar.gz"
        exit 1
    fi
    echo "Extracting ${OPENSSL_VERSION}"
    tar xf ${OPENSSL_VERSION}.tar.gz
fi

#archs=(arm arm64 x86 x86_64 mips mips64)
if [ $# -gt 0 ] ; then
    archs=$@
else
    archs=(arm arm64 x86 x86_64)
fi

echo -e "${ESCAPE}${GREEN}Building for ${archs[@]}${ESCAPE}${NC}"

OLDPATH=$PATH

for arch in ${archs[@]}; do
    export NDK_TOOLCHAIN_DIR="${PWD}/${UNAME}-${arch}"
    if [ ! -d "${NDK_TOOLCHAIN_DIR}" ] ; then
        echo "Creating toolchain directory ${NDK_TOOLCHAIN_DIR}"
        python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch ${arch} --api 21 --install-dir ${NDK_TOOLCHAIN_DIR}
    fi
    #xLIB="/lib"
    xCFLAGS="-D__ANDROID_API__=21 -mandroid -O3 -lc -lgcc -ldl"
    case ${arch} in
        "arm")
            _ANDROID_TARGET_SELECT=arch-arm
            _ANDROID_ARCH=arch-arm
            _ANDROID_EABI=arm-linux-androideabi-4.9
            #configure_platform="android-armv7"
            configure_platform="android-armeabi"
            ;;
        "arm64")
            _ANDROID_TARGET_SELECT=arch-arm64
            _ANDROID_ARCH=arch-arm64
            _ANDROID_EABI=aarch64-linux-android-4.9
            #no xLIB="/lib64"
            #configure_platform="linux-generic64 -DB_ENDIAN"
            configure_platform="android64-aarch64"
            ;;
        "mips")
            _ANDROID_TARGET_SELECT=arch-mips
            _ANDROID_ARCH=arch-mips
            _ANDROID_EABI=mipsel-linux-android-4.9
            configure_platform="android-mips"
            ;;
        "mips64")
            _ANDROID_TARGET_SELECT=arch-mips64
            _ANDROID_ARCH=arch-mips64
            _ANDROID_EABI=mips64el-linux-android-4.9
            xLIB="/lib64"
            configure_platform="linux-generic64 -DB_ENDIAN"
            ;;
        "x86")
            _ANDROID_TARGET_SELECT=arch-x86
            _ANDROID_ARCH=arch-x86
            _ANDROID_EABI=x86-4.9
            configure_platform="android-x86"
            ;;
        "x86_64")
            _ANDROID_TARGET_SELECT=arch-x86_64
            _ANDROID_ARCH=arch-x86_64
            _ANDROID_EABI=x86_64-4.9
            xLIB="/lib64"
            #configure_platform="linux-generic64"
            configure_platform="android64"
            ;;
        *)
            configure_platform="linux-elf" ;;
    esac

    TGT_DIR="${PWD}/openssl_prebuilt/${arch}"
    rm -rf ${TGT_DIR}
    mkdir -p ${TGT_DIR}
    export PATH=${OLDPATH}

    echo -e "${ESCAPE}${GREEN}Setting ${arch} environment${ESCAPE}${NC}"
    . ./setenv-android.sh

    command pushd ${OPENSSL_VERSION} > /dev/null

    perl -pi -e 's/install: install_sw install_ssldirs install_docs/install: install_sw install_ssldirs/g' Makefile
    ./Configure shared no-threads no-asm no-zlib no-ssl3 no-comp no-hw no-engine --prefix=${TGT_DIR} --openssldir=${TGT_DIR} ${configure_platform} ${xCFLAGS}

    make clean
    make depend
    make CALC_VERSIONS="SHLIB_COMPAT=; SHLIB_SOVER=" all
    make install

    command popd > /dev/null

    command pushd ${TGT_DIR} > /dev/null

    for dir in bin misc openssl.cnf.dist share certs openssl.cnf private lib/engines-* lib/pkgconfig; do
        rm -rf ${dir}
    done

    rm -f lib/libcrypto.so
    mv lib/libcrypto.so.1.1 lib/libcrypto.so
    rm -f lib/libssl.so
    mv lib/libssl.so.1.1 lib/libssl.so

    command popd > /dev/null

    if [ ${arch} = "arm" ] ; then
        cp -R ${TGT_DIR} ${PWD}/openssl_prebuilt/armv7
    fi
done
exit 0
