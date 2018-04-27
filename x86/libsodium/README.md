# Building on Ubuntu 16.04
These instructions are for building libsodium for an x86 android system. The Android API version can be changed to suit your needs.

## Prep work
```
sudo apt-get update
sudo apt-get install -y zip unzip autoconf cmake libtool
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
python3 ~/android-ndk-r16b/build/tools/make_standalone_toolchain.py --arch x86 --api 21 --install-dir $NDK_TOOLCHAIN_DIR
```

## Download and extract libsodium
```
wget https://github.com/jedisct1/libsodium/releases/download/1.0.16/libsodium-1.0.16.tar.gz
tar xf libsodium-1.0.16.tar.gz
```

## Configure and build libsodium
```
cd libsodium-1.0.16
./autogen.sh
./configure --prefix=$HOME/libsodium_x86 --disable-soname-versions --host=i686-linux-android
make
make install
```
