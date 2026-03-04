#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AIR_HOME="${AIR_HOME:-/usr/local/bin/air_sdk}"
EXT_DIR="$ROOT_DIR/extensions/background"
ANE_BUILD_DIR="$EXT_DIR/build"
ANDROID_CLASSES_DIR="$ANE_BUILD_DIR/android/classes"
ANDROID_DIST_DIR="$ANE_BUILD_DIR/android-dist"
ANDROID_RES_DIR="$EXT_DIR/android/res"
COMPILER_CLASSPATH="$AIR_HOME/lib/android/FlashRuntimeExtensions.jar"
ANDROID_JAR="${ANDROID_JAR:-/root/android-sdk/platforms/android-10/android.jar}"

APP_XML="$ROOT_DIR/loader/app.xml"
LOADER_SWF="$ROOT_DIR/loader/Loader.swf"
GAME_SWF="$ROOT_DIR/assets/Game.swf"
GAME_SWF_IN_LOADER="$ROOT_DIR/loader/gamefiles/Game.swf"
ANE_PATH="$ROOT_DIR/loader/extensions/background.ane"

KEYSTORE_PATH="${KEYSTORE_PATH:-$ROOT_DIR/temp_keystore.jks}"
KEY_ALIAS="${KEY_ALIAS:-tempalias}"
KEYSTORE_PASS="${KEYSTORE_PASS:-temppass}"
KEY_PASS="${KEY_PASS:-$KEYSTORE_PASS}"

SKIP_PATCH="${SKIP_PATCH:-0}"
SKIP_ANE="${SKIP_ANE:-0}"
PACKAGE_TARGET="${PACKAGE_TARGET:-apk}"

ARCHES=()
for arg in "$@"; do
  case "$arg" in
    --skip-patch)
      SKIP_PATCH=1
      ;;
    --skip-ane)
      SKIP_ANE=1
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./scripts/build-apk.sh [--skip-patch] [--skip-ane] [armv7] [armv8]

Options:
  --skip-patch  Skip Game.swf patching step
  --skip-ane    Skip background ANE rebuild step
  --target-aab  Build AAB instead of APK(s)
  -h, --help    Show this help message
EOF
      exit 0
      ;;
    --target-aab)
      PACKAGE_TARGET="aab"
      ;;
    armv7|armv8)
      ARCHES+=("$arg")
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Use --help to see available options."
      exit 1
      ;;
  esac
done

if [[ ${#ARCHES[@]} -eq 0 ]]; then
  ARCHES=(armv7 armv8)
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1"
    exit 1
  fi
}

resolve_android_sdk_root() {
  if [[ -n "${ANDROID_SDK_ROOT:-}" && -d "${ANDROID_SDK_ROOT}" ]]; then
    printf '%s\n' "${ANDROID_SDK_ROOT}"
    return
  fi

  if [[ -n "${ANDROID_JAR:-}" ]]; then
    local jar_dir
    local platform_dir
    local sdk_root
    jar_dir="$(dirname "${ANDROID_JAR}")"
    platform_dir="$(dirname "${jar_dir}")"
    sdk_root="$(dirname "${platform_dir}")"
    if [[ -d "${sdk_root}" ]]; then
      printf '%s\n' "${sdk_root}"
      return
    fi
  fi

  if [[ -d "/usr/local/lib/android/sdk" ]]; then
    printf '%s\n' "/usr/local/lib/android/sdk"
    return
  fi

  if [[ -d "/root/android-sdk" ]]; then
    printf '%s\n' "/root/android-sdk"
    return
  fi

  return 1
}

build_foreground_ane() {
  mkdir -p "$ANE_BUILD_DIR/as3/ext" "$ANDROID_CLASSES_DIR" "$ANDROID_DIST_DIR" "$ROOT_DIR/loader/extensions"

  rm -rf "$ANDROID_DIST_DIR/res"
  if [[ -d "$ANDROID_RES_DIR" ]]; then
    cp -R "$ANDROID_RES_DIR" "$ANDROID_DIST_DIR/res"
  fi

  cp "$ROOT_DIR/loader/src/ext/ForegroundService.as" "$ANE_BUILD_DIR/as3/ext/ForegroundService.as"

  "$AIR_HOME/bin/compc" \
    -source-path "$ANE_BUILD_DIR/as3" \
    -include-classes ext.ForegroundService \
    -swf-version=23 \
    -output "$ANE_BUILD_DIR/background.swc"

  javac --release 8 \
    -cp "$ANDROID_JAR:$COMPILER_CLASSPATH" \
    -d "$ANDROID_CLASSES_DIR" \
    "$EXT_DIR/android/src/com/aqw/foreground/"*.java

  jar cf "$ANE_BUILD_DIR/foreground-ext.jar" -C "$ANDROID_CLASSES_DIR" .

  PY_SWC="$ANE_BUILD_DIR/background.swc" \
  PY_LIB_SWF="$ANDROID_DIST_DIR/library.swf" \
  python - <<'PY'
import os
import zipfile
import zlib

swc = os.environ["PY_SWC"]
out = os.environ["PY_LIB_SWF"]
with zipfile.ZipFile(swc) as z:
    data = z.read("library.swf")
if data[:3] == b"CWS":
    body = zlib.decompress(data[8:])
    data = b"FWS" + bytes([data[3]]) + data[4:8] + body
with open(out, "wb") as f:
    f.write(data)
PY

  cp "$ANE_BUILD_DIR/foreground-ext.jar" "$ANDROID_DIST_DIR/foreground-ext.jar"
  cp "$EXT_DIR/extension.xml" "$ANE_BUILD_DIR/extension.xml"
  cp "$EXT_DIR/platform-android.xml" "$ANDROID_DIST_DIR/platform.xml"

  "$AIR_HOME/bin/adt" -package -target ane \
    "$ANE_BUILD_DIR/background.ane" \
    "$ANE_BUILD_DIR/extension.xml" \
    -swc "$ANE_BUILD_DIR/background.swc" \
    -platform Android-ARM \
    -platformoptions "$ANDROID_DIST_DIR/platform.xml" \
    -C "$ANDROID_DIST_DIR" foreground-ext.jar library.swf res \
    -platform Android-ARM64 \
    -platformoptions "$ANDROID_DIST_DIR/platform.xml" \
    -C "$ANDROID_DIST_DIR" foreground-ext.jar library.swf res

  cp "$ANE_BUILD_DIR/background.ane" "$ROOT_DIR/loader/extensions/background.ane"
}

require_cmd java
require_cmd keytool
require_cmd javac
require_cmd jar
require_cmd python

if [[ ! -x "$AIR_HOME/bin/amxmlc" || ! -x "$AIR_HOME/bin/adt" ]]; then
  echo "AIR SDK not found at: $AIR_HOME"
  echo "Set AIR_HOME to your AIR SDK path."
  exit 1
fi

if [[ ! -x "$AIR_HOME/bin/compc" ]]; then
  echo "Missing compc in AIR SDK at: $AIR_HOME/bin/compc"
  exit 1
fi

if [[ "$SKIP_ANE" != "1" && ! -f "$ANDROID_JAR" ]]; then
  echo "Missing android.jar: $ANDROID_JAR"
  echo "Set ANDROID_JAR=/path/to/android.jar and run again."
  exit 1
fi

cd "$ROOT_DIR"

if [[ "$SKIP_PATCH" != "1" ]]; then
  echo "[1/5] Patching latest Game.swf..."
  java scripts/PatchGame.java
else
  echo "[1/5] Skip patch step (--skip-patch / SKIP_PATCH=1)"
fi

if [[ ! -f "$GAME_SWF" ]]; then
  echo "Missing file: $GAME_SWF"
  exit 1
fi

echo "[2/5] Preparing loader gamefiles..."
mkdir -p "$ROOT_DIR/loader/gamefiles"
cp "$GAME_SWF" "$GAME_SWF_IN_LOADER"

if [[ "$SKIP_ANE" != "1" ]]; then
  echo "[3/5] Building background ANE..."
  build_foreground_ane
else
  echo "[3/5] Skip ANE rebuild (--skip-ane / SKIP_ANE=1)"
fi

if [[ ! -f "$ANE_PATH" ]]; then
  echo "Missing ANE: $ANE_PATH"
  exit 1
fi

echo "[4/5] Compiling Loader.swf..."
"$AIR_HOME/bin/amxmlc" \
  -external-library-path+="$ANE_PATH" \
  -output "$LOADER_SWF" \
  "$ROOT_DIR/loader/src/Main.as"

if [[ ! -f "$KEYSTORE_PATH" ]]; then
  echo "[keystore] Creating temporary keystore: $KEYSTORE_PATH"
  keytool -genkeypair \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -keystore "$KEYSTORE_PATH" \
    -storepass "$KEYSTORE_PASS" \
    -keypass "$KEY_PASS" \
    -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, S=Unknown, C=US"
fi

if [[ "$PACKAGE_TARGET" == "aab" ]]; then
  echo "[5/5] Building AAB..."
  out_aab="$ROOT_DIR/AQWPocket.aab"
  PLATFORM_SDK="$(resolve_android_sdk_root || true)"
  if [[ -z "$PLATFORM_SDK" ]]; then
    echo "Unable to detect Android SDK root for AAB build."
    echo "Set ANDROID_SDK_ROOT=/path/to/android/sdk and run again."
    exit 1
  fi
  "$AIR_HOME/bin/adt" -package \
    -target aab \
    -storetype JKS \
    -keystore "$KEYSTORE_PATH" \
    -storepass "$KEYSTORE_PASS" \
    -keypass "$KEY_PASS" \
    "$out_aab" \
    "$APP_XML" \
    -extdir "$ROOT_DIR/loader/extensions" \
    -C "$ROOT_DIR/loader" \
      Loader.swf \
      icons/android-icon-36x36.png \
      icons/android-icon-48x48.png \
      icons/android-icon-72x72.png \
      icons/android-icon-96x96.png \
      icons/android-icon-144x144.png \
      icons/android-icon-192x192.png \
      gamefiles/Game.swf \
    -platformsdk "$PLATFORM_SDK"
  echo "Done. AAB output:"
  echo "- AQWPocket.aab"
else
  echo "[5/5] Building APK(s)..."
  for arch in "${ARCHES[@]}"; do
    out_apk="$ROOT_DIR/AQWPocket-${arch}.apk"
    echo "  - $out_apk"

    "$AIR_HOME/bin/adt" -package \
      -target apk-captive-runtime \
      -arch "$arch" \
      -storetype JKS \
      -keystore "$KEYSTORE_PATH" \
      -storepass "$KEYSTORE_PASS" \
      -keypass "$KEY_PASS" \
      "$out_apk" \
      "$APP_XML" \
      -extdir "$ROOT_DIR/loader/extensions" \
      -C "$ROOT_DIR/loader" \
        Loader.swf \
        icons/android-icon-36x36.png \
        icons/android-icon-48x48.png \
        icons/android-icon-72x72.png \
        icons/android-icon-96x96.png \
        icons/android-icon-144x144.png \
        icons/android-icon-192x192.png \
        gamefiles/Game.swf
  done

  echo "Done. APK output:"
  for arch in "${ARCHES[@]}"; do
    echo "- AQWPocket-${arch}.apk"
  done
fi
