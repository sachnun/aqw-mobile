# AQW Pocket

Unofficial AdventureQuest Worlds client for Android.

> Unofficial community project. Not affiliated with Artix Entertainment.

## Download

- Get the latest APK from [Releases](../../releases/latest)
- Use `armv7` for older devices, `armv8` for most modern devices

## Features

- Native Android client (Adobe AIR)
- On-screen joystick and combat buttons
- Auto update check from GitHub releases

## Build

Requirements:

- Rust
- DMD
- RABCDAsm
- Adobe AIR SDK (51.1+)
- Java

Quick build:

```bash
git clone https://github.com/sachnun/aqw-mobile.git
cd aqw-mobile
./scripts/build-apk.sh
```

Optional:

```bash
./scripts/build-apk.sh armv8
SKIP_PATCH=1 ./scripts/build-apk.sh armv8
SKIP_ANE=1 ./scripts/build-apk.sh armv8
```

Manual builds are also available via [GitHub Actions](../../actions).

## Contributing

PRs and issues are welcome.
