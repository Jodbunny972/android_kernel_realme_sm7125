#!/bin/bash
set -e

# =========================
# PATHS
# =========================
CLANG_DIR=$PWD/toolchains/clang
GCC_DIR=$PWD/toolchains/gcc
ANYKERNEL_DIR=$PWD/AnyKernel3
OUT=out

# =========================
# ENV
# =========================
export ARCH=arm64
export SUBARCH=arm64

export KBUILD_BUILD_USER="JOD-BUNNY"
export KBUILD_BUILD_HOST="BunnyX"

export PATH=$CLANG_DIR/bin:$GCC_DIR/bin:$PATH

export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export CLANG_TRIPLE=aarch64-linux-gnu-

export USE_CCACHE=1
export CCACHE_EXEC=$(which ccache)

# =========================
# CLANG
# =========================
if [ ! -d "$CLANG_DIR" ]; then
  echo "🔽 Cloning Proton Clang..."
  git clone --depth=1 https://github.com/kdrag0n/proton-clang $CLANG_DIR
fi

# =========================
# GCC
# =========================
if [ ! -d "$GCC_DIR" ]; then
  echo "🔽 Cloning GCC..."
  git clone --depth=1 https://github.com/mvaisakh/gcc-arm64 $GCC_DIR
fi

# =========================
# ANYKERNEL3
# =========================
if [ ! -d "$ANYKERNEL_DIR" ]; then
  echo "🔽 Cloning AnyKernel3..."
  git clone --depth=1 https://github.com/JOD-BUNNY07/AnyKernel3 $ANYKERNEL_DIR
fi

# =========================
# CLEAN
# =========================
echo "🧹 Cleaning..."
rm -rf $OUT
mkdir -p $OUT
rm -f $ANYKERNEL_DIR/zImage

# =========================
# DEFCONFIG
# =========================
echo "⚙️ Generating defconfig..."
make O=$OUT ARCH=arm64 atoll_defconfig

# =========================
# BUILD
# =========================
echo "🚀 Building kernel..."

make -j$(nproc) O=$OUT \
  ARCH=arm64 \
  CC=clang \
  LLVM=1 \
  LLVM_IAS=1 \
  LD=ld.lld \
  AR=llvm-ar \
  NM=llvm-nm \
  OBJCOPY=llvm-objcopy \
  OBJDUMP=llvm-objdump \
  STRIP=llvm-strip \
  CROSS_COMPILE=$CROSS_COMPILE \
  CROSS_COMPILE_ARM32=$CROSS_COMPILE_ARM32 \
  2>&1 | tee build.log

# =========================
# CHECK
# =========================
IMG=$OUT/arch/arm64/boot/Image.gz-dtb

if [ ! -f "$IMG" ]; then
  echo "❌ Build Failed!"
  exit 1
fi

echo "✅ Build Success"

# =========================
# ZIP
# =========================
echo "📦 Creating ZIP..."

cp $IMG $ANYKERNEL_DIR/zImage

cd $ANYKERNEL_DIR
ZIPNAME="BunnyX-Kernel-$(date +%Y%m%d-%H%M).zip
