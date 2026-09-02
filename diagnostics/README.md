# Shield Dolby Vision diagnostics

This directory records the reproducible baseline for the Nvidia Shield TV Pro
(2019) Dolby Vision investigation. Copyrighted media and APKs are deliberately
excluded from Git.

## Frozen source baseline and validated build

| Component | Revision |
| --- | --- |
| mpv-android | `cccae4bdb3c75209e6847ecec3a7db0e160a24ad` |
| mpv | `4bd5caacd8a7d6f05832615913b7b3af73f6966f` |
| FFmpeg | `fe5154cc777f0d0a5286e2cb8a8c46ba3dbce719` |
| libplacebo | `f6f5f8eff599b78dcac28e1dc989b78c4c59b834` (7.371.0 base) |
| Android command-line tools | `11076708_latest` |
| Android platform / compile SDK | 36 |
| Android build tools | 36.0.0 |
| Android NDK | r29 (`29.0.14206865`) |
| Java | 17 (matching upstream CI) |

The dependency download scripts pin all three native repositories. The
validated ARM64 debug APK was produced by GitHub Actions run `33580556833`:

```text
app-default-arm64-v8a-debug.apk
SHA-256 d1babdb47c79f1fad226a406b0e89dc0f6754a62d698bf958eacdeaea19e6950
```

The installed APK was pulled back from the Shield and matched this digest. Its
unstripped ARM64 `libmpv.so` has SHA-256
`6ca3bf74e0bab52666f30bf6b4dcbb3095168c75d60f3c21ee14d789b5a558a0`.

## Target

- Nvidia Shield TV Pro 2019
- Android 11, build `RQ1A.210105.003.7825230_4387.0822`
- Device `mdarcy`; release fingerprint
  `NVIDIA/mdarcy/mdarcy:11/RQ1A.210105.003/7825230_4387.0822:user/release-keys`
- ARM64 debug APK with application ID suffix `.dovitest`
- HDMI to LG 4K OLED television
- Shield mode: 4K 59.940 Hz, Dolby Vision and HDR10 ready

## Test matrix

Each run must begin with a force-stop and use an explicit `hwdec` value.

| ID | `vo` | `hwdec` | Unmodified-path observation | Patched result |
| --- | --- | --- | --- |
| A | `gpu-next` | `no` | Correct-looking recognizable image; too slow at 4K | Reference only |
| B | `gpu-next` | `mediacodec-copy` | Real-time recognizable image with pink/green hue | Profile 5 metadata reaches gpu-next; colors, subtitles, OSD, and real-time playback pass |
| C | `gpu-next` | `mediacodec` | Solid or near-solid magenta field | Shield Dolby Surface supplies video while transparent gpu-next overlay supplies subtitles and OSD; Profiles 5 and 8.1 pass, as does Profile 7 compatibility playback with combined access units |
| D | `mediacodec_embed` | `mediacodec` | Black; subtitles/OSD requirement not met | Not used |

Path B performs Dolby Vision reshaping in libplacebo and does not make the LG
television enter Dolby Vision mode. Path C uses the Shield's native Dolby
decoder and does make the television enter Dolby Vision mode. A television
logo alone is not evidence that enhancement-layer data was reconstructed.

The normal surface-decoder gate accepts only single-layer Profile 5 and
Profile 8.1. An additional opt-in Profile 7 probe preserves combined BL+EL+RPU
access units for Nvidia's proprietary decoder. Profile 7.6 FEL compatibility
playback passed visible playback, subtitle/OSD, seeking, transition, and
seven-minute soak checks, and the stream is not silently converted to Profile
8.1. A dedicated residual test was run twice and did not display its
FEL-decoded confirmation sentence. This is a definitive negative result for
FEL residual reconstruction on the tested path, not complete FEL support.

The reports and logs generated during testing belong in `reports/` and
`logs/`. Test media belongs in `media/` and must never be committed.

## Build and install

The diagnostic branch builds only ARM64 and gives its debug APK the application
ID `is.xyz.mpv.dovitest`, allowing it to coexist with the official app.

```sh
git clone --branch dovi-shield-m2ts \
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

Profile 7 compatibility playback requires its separate opt-in configuration:

```sh
ADB_SERIAL=shield-address:5555 ./diagnostics/soak-shield.sh \
    is.xyz.mpv.dovitest diagnostics/configs/test-p7-soak.conf \
    http://media-server/profile7-sample.mkv \
    diagnostics/logs/p7-soak 7 1
```

This path deliberately sets `demuxer-dovi-split=no`; the tested Nvidia decoder
receives the original combined BL+EL+RPU access units. It must not be described
as complete FEL support unless enhancement-layer residual reconstruction is
independently demonstrated.

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

`test-b-final.conf` is the quiet, non-looping Profile 5 copy configuration
used for final visual checks. `test-external-sampler.conf` disables the direct
video overlay so an ordinary MediaCodec file exercises AImageReader and the
external-texture shader path. `test-m2ts-eof.conf` starts the dual-PID M2TS
sample near EOF to validate pairing, PGS subtitles, teardown, and natural
completion without replaying the entire feature.

See `RESULTS.md` for the validation record, modified-file explanation,
limitations, rollback procedure, and upstreaming plan.
