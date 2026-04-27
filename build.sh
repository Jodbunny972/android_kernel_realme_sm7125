#!/bin/bash
set -e

# =========================
# PATHS
# =========================
CLANG_DIR=$HOME/toolchains/clang
GCC_DIR=$HOME/toolchains/gcc
ANYKERNEL_DIR=$HOME/AnyKernel3

# =========================
# CLANG
# =========================
if [ ! -d "$CLANG_DIR" ]; then
  echo "🔽 Cloning Clang..."
  git clone --depth=1 https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r487747.git $CLANG_DIR
fi

# =========================
# GCC
# =========================
if [ ! -d "$GCC_DIR" ]; then
  echo "🔽 Cloning GCC..."
  git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git $GCC_DIR
fi

# =========================
# ANYKERNEL3 (FIXED)
# =========================
if [ ! -d "$ANYKERNEL_DIR" ]; then
  echo "🔽 Cloning AnyKernel3..."
  git clone --depth=1 https://github.com/JOD-BUNNY07/AnyKernel3.git $ANYKERNEL_DIR
fi

# =========================
# BUILD INFO
# =========================
KERNEL_NAME="BunnyX-atoll-"
VERSION="v1.1"

DATE=$(date +%Y%m%d)
TIME=$(date +%H%M)
ZIPNAME="${KERNEL_NAME}-${TIME}-${DATE}-${VERSION}.zip"

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

OUT=out

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
echo "📄 Defconfig..."
make O=$OUT ARCH=arm64 atoll_defconfig

# =========================

make O=$OUT olddefconfig

# =========================
# BUILD
# =========================
echo "🚀 Building kernel..."

make -j$(nproc) O=$OUT \
ARCH=arm64 \
CC=clang \
LLVM=1 LLVM_IAS=1 \
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
echo "📦 Creating zip..."

cp $IMG $ANYKERNEL_DIR/zImage

cd $ANYKERNEL_DIR
zip -r9 $ZIPNAME * -x "*.git*" "*.zip" README.md > /dev/null

echo "📦 Zip Created: $ZIPNAME"

# =========================
# TELEGRAM UPLOAD (OPTIONAL)
# =========================
if [ -n "$TELEGRAM_TOKEN" ]; then
  echo "📤 Uploading to Telegram..."

  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendDocument" \
    -F chat_id="$CHAT_ID" \
    -F document=@"$ANYKERNEL_DIR/$ZIPNAME" \
    -F caption="🐰 BunnyX Kernel

📦 $ZIPNAME
⚙️ Clang Build
👤 $KBUILD_BUILD_USER
🖥️ $KBUILD_BUILD_HOST"
fi

echo "🎉 DONE!"
