#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root/local_ai/native"
out="$root/addons/canglan_ai/bin"
mkdir -p "$out"
TARGET="${1:-linux}"
if [[ "$TARGET" == android ]]; then
  : "${ANDROID_NDK_HOME:?Android NDK path required}"
  cmake -S "$src" -B "$src/build-android" -G Ninja -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-28 \
    -DGGML_OPENMP=OFF -DGGML_NATIVE=OFF
  cmake --build "$src/build-android" --target canglan_ai -j 3
  cp "$src/build-android/stage/libcanglan_ai.so" "$out/libcanglan_ai.android.arm64.so"
elif [[ "$TARGET" == linux ]]; then
  cmake -S "$src" -B "$src/build-linux" -G Ninja -DCMAKE_BUILD_TYPE=Release
  cmake --build "$src/build-linux" --target canglan_ai -j 3
  cp "$src/build-linux/stage/libcanglan_ai.so" "$out/libcanglan_ai.linux.x86_64.so"
else
  echo 'Expected linux or android' >&2; exit 2
fi
cat > "$root/addons/canglan_ai/canglan_ai.gdextension" <<'END'
[configuration]
entry_symbol = "canglan_ai_init"
compatibility_minimum = "4.4"

[libraries]
linux.debug.x86_64 = "res://addons/canglan_ai/bin/libcanglan_ai.linux.x86_64.so"
linux.release.x86_64 = "res://addons/canglan_ai/bin/libcanglan_ai.linux.x86_64.so"
android.debug.arm64 = "res://addons/canglan_ai/bin/libcanglan_ai.android.arm64.so"
android.release.arm64 = "res://addons/canglan_ai/bin/libcanglan_ai.android.arm64.so"
END
echo "BUILT_REAL_CANGLAN_AI_GDEXTENSION $TARGET"
