#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AIR_HOME="${AIR_HOME:-/usr/local/bin/air_sdk}"

APP_XML="$ROOT_DIR/loader/app.xml"
LOADER_SWF="$ROOT_DIR/loader/Loader.swf"
GAME_SWF="$ROOT_DIR/assets/Game.swf"
GAME_SWF_IN_LOADER="$ROOT_DIR/loader/gamefiles/Game.swf"
ANE_PATH="$ROOT_DIR/loader/extensions/foreground-service.ane"

KEYSTORE_PATH="${KEYSTORE_PATH:-$ROOT_DIR/temp_keystore.jks}"
KEY_ALIAS="${KEY_ALIAS:-tempalias}"
KEYSTORE_PASS="${KEYSTORE_PASS:-temppass}"
KEY_PASS="${KEY_PASS:-$KEYSTORE_PASS}"

SKIP_PATCH="${SKIP_PATCH:-0}"
SKIP_ANE="${SKIP_ANE:-0}"

ARCHES=("$@")
if [[ ${#ARCHES[@]} -eq 0 ]]; then
  ARCHES=(armv7 armv8)
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1"
    exit 1
  fi
}

require_cmd cargo
require_cmd keytool

if [[ ! -x "$AIR_HOME/bin/amxmlc" || ! -x "$AIR_HOME/bin/adt" ]]; then
  echo "AIR SDK not found at: $AIR_HOME"
  echo "Set AIR_HOME to your AIR SDK path."
  exit 1
fi

cd "$ROOT_DIR"

if [[ "$SKIP_PATCH" != "1" ]]; then
  echo "[1/5] Patching latest Game.swf..."
  cargo run --release
else
  echo "[1/5] Skip patch step (SKIP_PATCH=1)"
fi

if [[ ! -f "$GAME_SWF" ]]; then
  echo "Missing file: $GAME_SWF"
  exit 1
fi

echo "[2/5] Preparing loader gamefiles..."
mkdir -p "$ROOT_DIR/loader/gamefiles"
cp "$GAME_SWF" "$GAME_SWF_IN_LOADER"

if [[ "$SKIP_ANE" != "1" ]]; then
  echo "[3/5] Building foreground-service ANE..."
  "$ROOT_DIR/scripts/build-foreground-ane.sh"
else
  echo "[3/5] Skip ANE rebuild (SKIP_ANE=1)"
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
