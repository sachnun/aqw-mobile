#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXT_DIR="$ROOT_DIR/extensions/foreground-service"
BUILD_DIR="$EXT_DIR/build"
ANDROID_CLASSES_DIR="$BUILD_DIR/android/classes"
ANDROID_DIST_DIR="$BUILD_DIR/android-dist"
ANDROID_RES_DIR="$EXT_DIR/android/res"
AIR_HOME="${AIR_HOME:-/usr/local/bin/air_sdk}"
COMPILER_CLASSPATH="$AIR_HOME/lib/android/FlashRuntimeExtensions.jar"
ANDROID_JAR="${ANDROID_JAR:-/root/android-sdk/platforms/android-10/android.jar}"

if [[ ! -f "$ANDROID_JAR" ]]; then
  echo "Missing android.jar: $ANDROID_JAR"
  echo "Set ANDROID_JAR=/path/to/android.jar and run again."
  exit 1
fi

mkdir -p "$BUILD_DIR/as3/ext" "$ANDROID_CLASSES_DIR" "$ANDROID_DIST_DIR" "$ROOT_DIR/loader/extensions"

rm -rf "$ANDROID_DIST_DIR/res"
if [[ -d "$ANDROID_RES_DIR" ]]; then
  cp -R "$ANDROID_RES_DIR" "$ANDROID_DIST_DIR/res"
fi

cp "$ROOT_DIR/loader/src/ext/ForegroundService.as" "$BUILD_DIR/as3/ext/ForegroundService.as"

"$AIR_HOME/bin/compc" \
  -source-path "$BUILD_DIR/as3" \
  -include-classes ext.ForegroundService \
  -swf-version=23 \
  -output "$BUILD_DIR/foreground-service.swc"

javac --release 8 \
  -cp "$ANDROID_JAR:$COMPILER_CLASSPATH" \
  -d "$ANDROID_CLASSES_DIR" \
  "$EXT_DIR/android/src/com/aqw/foreground/"*.java

jar cf "$BUILD_DIR/foreground-ext.jar" -C "$ANDROID_CLASSES_DIR" .

python - <<'PY'
import zipfile, zlib
swc = '/root/aqw-mobile/extensions/foreground-service/build/foreground-service.swc'
out = '/root/aqw-mobile/extensions/foreground-service/build/android-dist/library.swf'
with zipfile.ZipFile(swc) as z:
    data = z.read('library.swf')
if data[:3] == b'CWS':
    body = zlib.decompress(data[8:])
    data = b'FWS' + bytes([data[3]]) + data[4:8] + body
with open(out, 'wb') as f:
    f.write(data)
PY

cp "$BUILD_DIR/foreground-ext.jar" "$ANDROID_DIST_DIR/foreground-ext.jar"
cp "$EXT_DIR/extension.xml" "$BUILD_DIR/extension.xml"
cp "$EXT_DIR/platform-android.xml" "$ANDROID_DIST_DIR/platform.xml"

"$AIR_HOME/bin/adt" -package -target ane \
  "$BUILD_DIR/foreground-service.ane" \
  "$BUILD_DIR/extension.xml" \
  -swc "$BUILD_DIR/foreground-service.swc" \
  -platform Android-ARM \
  -platformoptions "$ANDROID_DIST_DIR/platform.xml" \
  -C "$ANDROID_DIST_DIR" foreground-ext.jar library.swf res \
  -platform Android-ARM64 \
  -platformoptions "$ANDROID_DIST_DIR/platform.xml" \
  -C "$ANDROID_DIST_DIR" foreground-ext.jar library.swf res

cp "$BUILD_DIR/foreground-service.ane" "$ROOT_DIR/loader/extensions/foreground-service.ane"
echo "Built: loader/extensions/foreground-service.ane"
