# AQW Pocket

Unofficial AdventureQuest Worlds client for Android.

## Download

Get the latest APK from [Releases](../../releases/latest).

## Features

- Native Android client (Adobe AIR)
- On-screen joystick and combat buttons
- Auto update check from GitHub releases

## Build

Requirements:

- [DMD](https://dlang.org/download.html)
- [RABCDAsm](https://github.com/CyberShadow/RABCDAsm)
- [Adobe AIR SDK (51.1+)](https://airsdk.harman.com/download)
- [Java](https://adoptium.net/temurin/releases/)

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

## Contributing

PRs and issues are welcome.
