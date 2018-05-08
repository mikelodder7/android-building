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
export NDK_TOOLCHAIN_DIR=~/arm
export PATH=$HOME/arm/bin:$PATH
export SODIUM_LIB_DIR=$HOME/libsodium_arm
export ZMQ_HAVE_ANDROID=1
python3 ~/android-ndk-r16b/build/tools/make_standalone_toolchain.py --stl=libc++ --arch arm --api 21 --install-dir $NDK_TOOLCHAIN_DIR
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
CPP=/home/vagrant/arm/bin/arm-linux-androideabi-cpp \
CC=/home/vagrant/arm/bin/arm-linux-androideabi-clang \
CXX=/home/vagrant/arm/bin/arm-linux-androideabi-clang++ \
LD=/home/vagrant/arm/bin/arm-linux-androideabi-ld \
AS=/home/vagrant/arm/bin/arm-linux-androideabi-as \
AR=/home/vagrant/arm/bin/arm-linux-androideabi-ar \
RANLIB=/home/vagrant/arm/bin/arm-linux-androideabi-ranlib \
CFLAGS="-I/home/vagrant/libzmq_arm/include -D__ANDROID_API__=21 -fPIC" \
CPPFLAGS="-I/home/vagrant/libzmq_arm/include -D__ANDROID_API__=21 -fPIC" \
CXXFLAGS="-I/home/vagrant/libzmq_arm/include -D__ANDROID_API__=21 -fPIC" \
LDFLAGS="-L/home/vagrant/libzmq_arm/lib -D__ANDROID_API__=21" \
LIBS="-lc -lgcc -ldl -static-libstdc++ -lc++abi -latomic" \
PKG_CONFIG_PATH=/home/vagrant/libzmq_arm/lib/pkgconfig \
--host=arm-linux-androideabi \
--prefix=/home/vagrant/libzmq_arm \
--with-libsodium=/home/vagrant/libsodium_arm \
--without-docs \
--enable-static \
--with-sysroot=/home/vagrant/arm/sysroot
make
make install
```
