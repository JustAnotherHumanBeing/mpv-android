# Shield Dolby Vision diagnostics

This directory records the reproducible baseline for the Nvidia Shield TV Pro
(2019) Dolby Vision investigation. Copyrighted media and APKs are deliberately
excluded from Git.

## Frozen source baseline and validated build

| Component | Revision |
| --- | --- |
| mpv-android | `49e46645047511b481c806094738262a3914d7d8` |
| mpv | `83d5ddbc1c6fb5b5a998b1a636a5b273497535fd` |
| FFmpeg | `fcd628b64dcd64b3325294866c4edd2990637c9c` |
| libplacebo | `b3ff1dbe73de8e75bda36836f7b1b5a2e00068f1` (7.371.0 base) |
| Android command-line tools | `11076708_latest` |
| Android platform / compile SDK | 36 |
| Android build tools | 36.0.0 |
| Android NDK | r29 (`29.0.14206865`) |
| Java | 17 (matching upstream CI) |

The dependency download scripts pin all three native repositories. The
validated ARM64 debug APK was produced by GitHub Actions run `33447804998`:

```text
app-default-arm64-v8a-debug.apk
SHA-256 f3ecfc0d3e8c2e5b33e7446377af51fd1e8788ca5d1ad2a21bc5bb7a81fa4ec5
```

The installed APK was pulled back from the Shield and matched this digest.

## Target

- Nvidia Shield TV Pro 2019
- Android 11 (exact firmware build to be recorded from `getprop`)
- ARM64 debug APK with application ID suffix `.dovitest`
- HDMI to LG 4K OLED television
- Shield mode: 4K 59.940 Hz, Dolby Vision and HDR10 ready

## Test matrix

Each run must begin with a force-stop and use an explicit `hwdec` value.

| ID | `vo` | `hwdec` | Unmodified-path observation | Patched result |
| --- | --- | --- | --- |
| A | `gpu-next` | `no` | Correct-looking recognizable image; too slow at 4K | Reference only |
| B | `gpu-next` | `mediacodec-copy` | Real-time recognizable image with pink/green hue | Profile 5 metadata reaches gpu-next; colors, subtitles, OSD, and real-time playback pass |
| C | `gpu-next` | `mediacodec` | Solid or near-solid magenta field | Shield Dolby Surface supplies video while transparent gpu-next overlay supplies subtitles and OSD; Profile 5 and 8.1 pass |
| D | `mediacodec_embed` | `mediacodec` | Black; subtitles/OSD requirement not met | Not used |

Path B performs Dolby Vision reshaping in libplacebo and does not make the LG
television enter Dolby Vision mode. Path C uses the Shield's native Dolby
decoder and does make the television enter Dolby Vision mode. A television
logo alone is not evidence that enhancement-layer data was reconstructed.

The validated surface-decoder gate accepts only single-layer Profile 5 and
Profile 8.1. Profile 7 MEL/FEL and Profile 7 enhancement-layer reconstruction
remain unsupported and are not silently converted to Profile 8.1.

The reports and logs generated during testing belong in `reports/` and
`logs/`. Test media belongs in `media/` and must never be committed.

## Build and install

The diagnostic branch builds only ARM64 and gives its debug APK the application
ID `is.xyz.mpv.dovitest`, allowing it to coexist with the official app.

```sh
git clone --branch dovi-shield-integration \
    https://github.com/JustAnotherHumanBeing/mpv-android.git
cd mpv-android
buildscripts/include/ci.sh install
DONT_BUILD_RELEASE=1 buildscripts/include/ci.sh build
adb install -r app/build/outputs/apk/default/debug/app-default-arm64-v8a-debug.apk
adb shell pm grant is.xyz.mpv.dovitest android.permission.READ_EXTERNAL_STORAGE
adb shell mkdir -p /sdcard/Movies
adb push /path/to/p5-smoke-s01e01-60s.mkv /sdcard/Movies/
```

For each run, put the sample at a Shield-accessible URI and invoke the capture
script with one of the lowercase IDs `a`, `b`, `c`, or `d`. The script
force-stops the app, replaces its private `mpv.conf` through Android's
debug-only `run-as` facility, clears logcat, and launches the media URI.

```sh
./diagnostics/capture-shield.sh is.xyz.mpv.dovitest b \
    file:///sdcard/Movies/p5-smoke-s01e01-60s.mkv diagnostics/logs/b
```

If Android reports `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, the old debug APK was
signed with a different ephemeral CI key. Back up its private `mpv.conf`,
uninstall only `is.xyz.mpv.dovitest`, install the new APK, and restore the
configuration. The official mpv-android package has a different application
ID and is unaffected.

For a reproducible sustained run:

```sh
ADB_SERIAL=shield-address:5555 ./diagnostics/soak-shield.sh \
    is.xyz.mpv.dovitest diagnostics/configs/test-b-soak.conf \
    file:///sdcard/Movies/p5-smoke-s01e01-60s.mkv \
    diagnostics/logs/p5-copy-soak 30 5
```

See `RESULTS.md` for the validation record, modified-file explanation,
limitations, rollback procedure, and upstreaming plan.
