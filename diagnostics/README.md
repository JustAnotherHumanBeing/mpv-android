# Shield Dolby Vision diagnostics

This directory records the reproducible baseline for the Nvidia Shield TV Pro
(2019) Dolby Vision investigation. Copyrighted media and APKs are deliberately
excluded from Git.

## Frozen source baseline

| Component | Revision |
| --- | --- |
| mpv-android | `474111adc4abe5b67f3f8082c8a307e80d45c174` |
| mpv | `49418246f30a9c24af31ac184aa24f39755db89a` |
| FFmpeg | tag `n9.0`, commit `d32b387f2b0a484599d4587d651891f0c63c4238` |
| libplacebo | `22ee762e8e0890fc54068beb670310f0edce7263` (7.371.0) |
| Android command-line tools | `11076708_latest` |
| Android platform / compile SDK | 36 |
| Android build tools | 36.0.0 |
| Android NDK | r29 (`29.0.14206865`) |
| Java | 17 (matching upstream CI) |

Current mpv-android does not pin mpv or libplacebo in its download scripts.
The mpv revision above is the head fetched by the successful upstream CI run
for the listed mpv-android commit on 2026-08-22. The libplacebo revision is the
head fetched when that run's native dependency cache was created on
2026-08-17. Freezing both here avoids substituting later master revisions.

## Target

- Nvidia Shield TV Pro 2019
- Android 11 (exact firmware build to be recorded from `getprop`)
- ARM64 debug APK with application ID suffix `.dovitest`
- HDMI to LG 4K OLED television
- Shield mode: 4K 59.940 Hz, Dolby Vision and HDR10 ready

## Test matrix

Each run must begin with a force-stop and use an explicit `hwdec` value.

| ID | `vo` | `hwdec` | Baseline observation |
| --- | --- | --- | --- |
| A | `gpu-next` | `no` | Correct-looking recognizable image; too slow at 4K |
| B | `gpu-next` | `mediacodec-copy` | Real-time recognizable image with pink/green hue |
| C | `gpu-next` | `mediacodec` | Solid or near-solid magenta field |
| D | `mediacodec_embed` | `mediacodec` | Black; subtitles/OSD requirement not met |

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
```

For each run, put the sample at a Shield-accessible URI and invoke the capture
script with one of the lowercase IDs `a`, `b`, `c`, or `d`. The script
force-stops the app, replaces its private `mpv.conf` through Android's
debug-only `run-as` facility, clears logcat, and launches the media URI.

```sh
./diagnostics/capture-shield.sh is.xyz.mpv.dovitest b \
    file:///sdcard/Movies/p5-smoke-s01e01-60s.mkv diagnostics/logs/b
```
