#!/bin/bash
#
# http://wiki.openssl.org/index.php/Android
#

set -e
rm -rf ${PWD}/openssl_prebuilt

if [ ! -d android-ndk-r16b ] ; then
    if [ ! -f android-ndk-r16b-linux-x86_64.zip ] ; then
        wget -q https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip
    fi
    unzip -qq android-ndk-r16b-linux-x86_64.zip
fi
export ANDROID_NDK_ROOT="${PWD}/android-ndk-r16b"

OPENSSL_VERSION=openssl-1.1.0h

if [ ! -d "${OPENSSL_VERSION}" ] ; then
    if [ ! -f ${OPENSSL_VERSION}.tar.gz ] ; then
        wget -q https://www.openssl.org/source/${OPENSSL_VERSION}.tar.gz
    fi 
    tar xf ${OPENSSL_VERSION}.tar.gz
fi

#archs=(arm arm64 x86 x86_64 mips mips64)
if [ $# -gt 0 ] ; then
    archs=$@
else
    archs=(arm arm64 x86 x86_64)
fi

echo "Building for ${archs[@]}"

OLDPATH=$PATH

for arch in ${archs[@]}; do
    export NDK_TOOLCHAIN_DIR=${PWD}/${arch}
    if [ ! -d "${NDK_TOOLCHAIN_DIR}" ] ; then
        echo "Creating toolchain directory ${NDK_TOOLCHAIN_DIR}"
        python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch ${arch} --api 21 --install-dir ${NDK_TOOLCHAIN_DIR}
    fi
    #xLIB="/lib"
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
    mkdir -p ${TGT_DIR}
    export PATH=${OLDPATH}

    echo "Setting ${arch} environment"
    . ./setenv-android.sh

    command pushd ${OPENSSL_VERSION} > /dev/null

    xCFLAGS="-D__ANDROID_API__=21 -mandroid -O3 -lc -lgcc -ldl"

    perl -pi -e 's/install: install_sw install_ssldirs install_docs/install: install_sw install_ssldirs/g' Makefile
    ./Configure shared no-threads no-asm no-zlib no-ssl3 no-comp no-hw no-engine --prefix=${TGT_DIR} --openssldir=${TGT_DIR} ${configure_platform} ${xCFLAGS}

    # patch SONAME

    #perl -pi -e 's/SHLIB_EXT=\.so\.\$\(SHLIB_MAJOR\)\.\$\(SHLIB_MINOR\)/SHLIB_EXT=\.so/g' Makefile
    #perl -pi -e 's/SHARED_LIBS_LINK_EXTS=\.so\.\$\(SHLIB_MAJOR\) \.so//g' Makefile
    # quote injection for proper SONAME
    #perl -pi -e 's/SHLIB_MAJOR=1/SHLIB_MAJOR=`/g' Makefile
    #perl -pi -e 's/SHLIB_MINOR=0.0/SHLIB_MINOR=`/g' Makefile
    make clean
    make depend
    make CALC_VERSIONS="SHLIB_COMPAT=; SHLIB_SOVER=" all
    make install

    command popd > /dev/null

    command pushd ${TGT_DIR} > /dev/null

    for dir in bin misc openssl.cnf.dist share certs openssl.cnf private; do
        rm -rf ${dir}
    done

    command popd > /dev/null
done
exit 0
