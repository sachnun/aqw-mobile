# AQW Pocket

Unofficial AdventureQuest Worlds client for Android.

## Download

Get the latest APK from [Releases](../../releases/latest).

## Features

- Native Android client (Adobe AIR)
- Touch controls (joystick + combat buttons)
- In-app update checker with release banner
- Background service support when app is minimized
- Built-in bot panel with simple farming/QoL modules

## Build

Requirements:

- [RABCDAsm](https://github.com/CyberShadow/RABCDAsm)
- [Adobe AIR SDK (51.1+)](https://airsdk.harman.com/download)
- [Java JDK](https://www.oracle.com/java/technologies/downloads/)
- [Android SDK Command-line Tools](https://developer.android.com/studio#command-tools)
  - Install packages: `platform-tools`, `platforms;android-34`, `build-tools;34.0.0`
  - Set `ANDROID_JAR` (for ANE build) and `ANDROID_SDK_ROOT` (for AAB build)

Quick build:

```bash
git clone https://github.com/sachnun/aqw-pocket.git
cd aqw-pocket
./scripts/build-apk.sh
```

Optional:

```bash
bash "scripts/build-apk.sh" --help
Usage: ./scripts/build-apk.sh [--skip-patch] [--skip-ane] [armv7] [armv8]
Options:
  --skip-patch  Skip Game.swf patching step
  --skip-ane    Skip background ANE rebuild step
  --target-aab  Build AAB instead of APK(s)
  -h, --help    Show this help message
```

Manual builds are also available via [GitHub Actions](../../actions).
Pull requests also upload preview APK artifacts in GitHub Actions for review.

## Contributing

PRs and issues are welcome.
