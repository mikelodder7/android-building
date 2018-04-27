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
python3 ~/android-ndk-r16b/build/tools/make_standalone_toolchain.py --arch x86 --api 21 --install-dir $NDK_TOOLCHAIN_DIR
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
./configure --without-docs --enable-static --with-libsodium=$HOME/libsodium_x86 --host=i686-linux-android --prefix=$HOME/libzmq_x86 LDFLAGS="-L$HOME/libzmq_x86/lib -D__ANDROID_API__=21 -avoid-version" CPPFLAGS="-fPIC -I$HOME/libzmq_x86/include -D__ANDROID_API__=21" LIBS="-lgcc"
make
make install
```
