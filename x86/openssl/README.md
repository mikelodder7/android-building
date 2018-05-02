# Building on Ubuntu 16.04
These instructions are for building openssl for an x86 android system. The Android API version can be changed to suit your needs.
Be sure to update the *setenv-android.sh* script to reflect your changes and environment.

## Prep work
```
sudo apt-get update
sudo apt-get install -y zip unzip autoconf cmake
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
python3 ~/android-ndk-r16b/build/tools/make_standalone_toolchain.py --arch x86 --api 21 --install-dir $NDK_TOOLCHAIN_DIR
```

## Download and extract openssl
```
wget https://www.openssl.org/source/openssl-1.1.0h.tar.gz
tar xf openssl-1.1.0h.tar.gz
```

## Setup environment variables for building openssl
```
wget https://github.com/mikelodder7/android-building/blob/master/x86/openssl/setenv-android.sh
chmod a+x setenv-android.sh
. ./setenv-android.sh
```

## Configure and build openssl
```
cd openssl-1.1.0.h
./config -D__ANDROID_API__=21 --openssldir=$HOME/openssl_x86 --prefix=$HOME/openssl_x86 -lc -lgcc -ldl
make
make install
```
