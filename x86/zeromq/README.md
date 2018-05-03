# Building on Ubuntu 16.04
These instructions are for building zeromq for an x86 android system. The Android API version can be changed to suit your needs.
You will need a build for libsodium targeting the same platform. If you need to build it, see [Building libsodium](https://github.com/mikelodder7/android-building/tree/master/x86/libsodium).

## Prep work
```
sudo apt-get update
sudo apt-get install -y zip unzip autoconf cmake libtool pkg-config
```

## Download and extract NDK
```
wget https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip
unzip android-ndk-r16b-linux-x86_64.zip
```

## Setup toolchain
```
export ANDROID_NDK_ROOT=~/android-ndk-r16b
export NDK_TOOLCHAIN_DIR=~/x86
export PATH=$HOME/x86/bin:$PATH
export SODIUM_LIB_DIR=$HOME/libsodium_x86
export ZMQ_HAVE_ANDROID=1
python3 ~/android-ndk-r16b/build/tools/make_standalone_toolchain.py --stl=libc++ --arch x86 --api 21 --install-dir $NDK_TOOLCHAIN_DIR
```

## Download and extract zeromq
```
wget https://github.com/zeromq/libzmq/releases/download/v4.2.5/zeromq-4.2.5.tar.gz
tar xf zeromq-4.2.5.tar.gz
```

## Configure and build zeromq
```
cd zeromq-4.2.5
./autogen.sh
./configure \
CPP=/home/vagrant/x86/bin/i686-linux-android-cpp \
CC=/home/vagrant/x86/bin/i686-linux-android-gcc \
CXX=/home/vagrant/x86/bin/i686-linux-android-g++ \
LD=/home/vagrant/x86/bin/i686-linux-android-ld \
AS=/home/vagrant/x86/bin/i686-linux-android-as \
AR=/home/vagrant/x86/bin/i686-linux-android-ar \
RANLIB=/home/vagrant/x86/bin/i686-linux-android-ranlib \
CFLAGS="-I/home/vagrant/zeromq-4.2.5/prefix/i686-linux-android-4.9/include -D__ANDROID_API__=21 -fPIC" \
CPPFLAGS="-I/home/vagrant/zeromq-4.2.5/prefix/i686-linux-android-4.9/include -D__ANDROID_API__=21 -fPIC" \
CXXFLAGS="-I/home/vagrant/zeromq-4.2.5/prefix/i686-linux-android-4.9/include -D__ANDROID_API__=21 -fPIC" \
LDFLAGS="-L/home/vagrant/zeromq-4.2.5/prefix/i686-linux-android-4.9/lib -D__ANDROID_API__=21" \
LIBS="-lc -lgcc -ldl -static-libstdc++ -latomic" \
PKG_CONFIG_PATH=/home/vagrant/zeromq-4.2.5/prefix/i686-linux-android-4.9/lib/pkgconfig \
--host=i686-linux-android \
--prefix=/home/vagrant/libzmq_x86 \
--with-libsodium=/home/vagrant/libsodium_x86 \
--without-docs \
--enable-static \
--with-sysroot=/home/vagrant/x86/sysroot
make
make install
```
