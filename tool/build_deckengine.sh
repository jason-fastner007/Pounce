#!/usr/bin/env bash
# Builds deckengine (Rust) for all platforms and puts the binaries into this repo.
#   DECKENGINE=~/src/deckengine tool/build_deckengine.sh
set -euo pipefail
DE=${DECKENGINE:-$HOME/Downloads/deckengine}
KF=$(cd "$(dirname "$0")/.." && pwd)
NDK=${ANDROID_NDK:-$(ls -d "$HOME"/Android/Sdk/ndk/* | sort -V | tail -1)}/toolchains/llvm/prebuilt/linux-x86_64/bin

cd "$DE"
# Linux (with playback engine and all decoders)
cargo build --release --lib
strip -o "$KF/linux/deckengine/libdeckengine.so" target/release/libdeckengine.so
cp include/deckengine.h "$KF/linux/deckengine/"

# Android arm64: only analysis + MP3 excerpts (ExoPlayer does the playback)
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$NDK/aarch64-linux-android26-clang"
export CC_aarch64_linux_android="$NDK/aarch64-linux-android26-clang"
export AR_aarch64_linux_android="$NDK/llvm-ar"
cargo build --release --lib --target aarch64-linux-android --no-default-features --features clip
"$NDK/llvm-strip" -o "$KF/packages/native_player/android/src/main/jniLibs/arm64-v8a/libdeckengine.so" \
  target/aarch64-linux-android/release/libdeckengine.so

# Web: WebAssembly for the analysis worker
cargo build --release --lib --target wasm32-unknown-unknown --no-default-features --features clip
cp target/wasm32-unknown-unknown/release/deckengine.wasm "$KF/web/deckengine.wasm"
python3 "$KF/tool/strip_wasm.py" "$KF/web/deckengine.wasm"
echo "deckengine: Linux, Android arm64 und Web aktualisiert."
