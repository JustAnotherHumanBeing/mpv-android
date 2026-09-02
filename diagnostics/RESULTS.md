# Shield Dolby Vision validation results

## Scope

The implementation targets Nvidia Shield TV Pro 2019, Android 11, ARM64, and
an LG 4K OLED connected through a Dolby Vision-ready HDMI mode. It keeps normal
mpv/libass subtitles and OSD available.

Validated inputs:

- single-layer Dolby Vision Profile 5 BL+RPU;
- single-layer Dolby Vision Profile 8.1 BL+RPU, HDR10-compatible;
- dual-layer Dolby Vision Profile 7 BL+EL+RPU compatibility playback;
- dual-PID Dolby Vision Profile 7 M2TS compatibility playback;
- HDR10 10-bit HEVC control;
- SDR 10-bit HEVC control;
- SDR 8-bit H.264 control;
- embedded and external SubRip subtitles.

The Profile 7 result validates compatibility playback through Nvidia's Dolby
Vision decoder. A dedicated Profile 7.6 FEL residual clip was run twice; its
literal FEL-decoded confirmation sentence never appeared. The tested Shield
path therefore does not reconstruct the FEL residual.

### Final artifact

GitHub Actions run `33580556833` built mpv-android commit
`cccae4bdb3c75209e6847ecec3a7db0e160a24ad`. The resulting ARM64 debug APK has
SHA-256
`d1babdb47c79f1fad226a406b0e89dc0f6754a62d698bf958eacdeaea19e6950`;
the APK pulled back from the Shield matched it byte-for-byte. The unstripped
ARM64 `libmpv.so` has SHA-256
`6ca3bf74e0bab52666f30bf6b4dcbb3095168c75d60f3c21ee14d789b5a558a0`.

This rebuild differs from the full-matrix predecessor only by the final
libplacebo GLSL extension-order correction. On the physical Shield it passed
Profile 5 native-Surface and MediaCodec-copy checks, Profile 8.1 native-Surface
playback, and ordinary SDR H.264 through MediaCodec's AImageReader external
texture path. These checks covered both the Dolby direct-Surface path and the
shader path changed in the rebuild.

## Results

### Profile 5 MediaCodec-copy

Configuration:

```text
vo=gpu-next
hwdec=mediacodec-copy
hwdec-software-fallback=no
sid=1
sub-font-size=27
vd-lavc-o=dovi_p5_metadata=1
```

- MediaCodec remained the pixel decoder.
- FFmpeg parsed each compressed access unit once and matched metadata to the
  decoded frame timestamp.
- `AV_FRAME_DATA_DOVI_METADATA` and `AV_FRAME_DATA_DOVI_RPU_BUFFER` reached
  mpv.
- gpu-next selected Dolby Vision reshaping for the matched frame.
- Correct colors, real-time playback, subtitles, OSD, pause/resume, seeking,
  and subtitle switching were confirmed on the physical Shield.
- The exact validated APK completed a 30-minute loop of the one-minute
  Profile 5 sample under the same PID. Every five-minute checkpoint remained
  in `PLAYING` state with `error=null`; PSS peaked during warm-up and finished
  below that peak, providing no evidence of unbounded per-loop growth.
- The LG did not enter Dolby Vision mode. This is expected for libplacebo
  rendering through the ordinary GPU output path.
- The final rebuilt APK repeated the Profile 5 copy test with correct colors,
  smooth playback, and visible subtitles/OSD. Logs confirmed MediaCodec pixel
  decoding, timestamp-matched Dolby metadata and RPU side data, and
  gpu-next's Dolby Vision reshaping path.

### Profile 5 and Profile 8.1 native Surface

Configuration:

```text
vo=gpu-next
hwdec=mediacodec
hwdec-software-fallback=no
android-dovi-overlay=yes
sid=1
sub-font-size=27
vd-lavc-o=dovi_surface_decoder=1
```

- `OMX.Nvidia.DOVI.decode` supplied the direct video Surface.
- gpu-next rendered subtitles and OSD into a transparent Surface above it.
- Correct colors, real-time playback, subtitles, OSD, and the LG Dolby Vision
  mode were confirmed for Profile 5 and Profile 8.1.
- Pause/resume, repeated seeks, audio/subtitle selection, app
  background/foreground, Surface recreation, file reopen, and transitions
  among Dolby Vision, HDR10, and SDR completed without stale video or stale
  Dolby metadata.
- A 30-minute Profile 8.1 feature playback remained active with no codec,
  application, OOM, or metadata-queue failure. PSS was not monotonic and ended
  below its warm-up peak, providing no evidence of unbounded growth.
- The final rebuilt APK passed a cold-start Profile 5 run through natural EOF
  with correct colors, smooth playback, visible subtitles/OSD, and LG Dolby
  Vision signaling.
- The same APK passed a cold-start Profile 8.1 regression with the same visual
  results. Logs confirmed `OMX.Nvidia.DOVI.decode`, MediaCodec hardware output,
  and the Android direct video Surface without a codec failure.

### Profile 7 native Surface compatibility

Configuration:

```text
vo=gpu-next
hwdec=mediacodec
hwdec-software-fallback=no
android-dovi-overlay=yes
demuxer-dovi-split=no
sid=1
sub-font-size=27
vd-lavc-o=dovi_surface_decoder=1,dovi_p7_surface_probe=1
```

- The test input was a dual-layer Profile 7.6 FEL stream with BL, EL, and RPU
  in combined access units and `disable_residual_flag=0`.
- Disabling mpv's virtual EL split preserved those combined access units for
  `OMX.Nvidia.DOVI.decode`. The split experiment failed because the separate
  EL MediaCodec instance could not be configured and BL output waited for it.
- The combined path produced recognizable moving video with correct colors,
  visible subtitles, and LG Dolby Vision signaling on the physical Shield.
- Pause/resume, forward and backward seeks, and replacement-file transitions
  completed without stale color or decoder state.
- A seven-minute feature playback remained under one PID in `PLAYING` state
  with `error=null` at every checkpoint. PSS was non-monotonic and finished
  below its observed peak, providing no evidence of unbounded growth.
- P5 -> P7 -> P8.1 -> HDR10 -> P7 transitions selected MediaCodec for every
  stream. Both P7 observations and the P5/P8.1 observations advanced normally;
  the short HDR10 control reached normal EOF.
- A lifecycle fix resumes replacement playback only when Android itself paused
  an active file. A replacement inherited an explicit user pause as intended.
- The full-matrix predecessor APK passed a cold-start Profile 7 compatibility
  regression with correct colors, smooth playback, visible subtitles/OSD, and
  LG Dolby Vision signaling. Logs confirmed the opt-in Profile 7 probe,
  `OMX.Nvidia.DOVI.decode`, and the Android direct video Surface.

These observations establish useful Profile 7 compatibility playback on this
Shield. They are not a claim of complete Profile 7 FEL decoding.

### Profile 7 FEL residual result

- The definitive sample was Profile 7.6 BL+EL+RPU with
  `el_spatial_resampling_filter_flag=1` and `disable_residual_flag=0`.
- Its SHA-256 is
  `60d1a337a09609c639f8111685b59f89902cc79606f2bdf3a9c269cd0b508bfa`.
- It displays `This device can decode FEL` only when the enhancement-layer
  residual is reconstructed.
- Two force-stopped native-Surface runs entered LG Dolby Vision mode and
  reached normal EOF, but the sentence never appeared.

This is a negative FEL residual reconstruction result. Profile 7 support in
this work is limited to compatibility playback through Nvidia's proprietary
decoder.

### Dual-PID Profile 7 M2TS

- The Troy UHD Blu-ray transport stream stores its base and enhancement
  layers on separate PIDs.
- mpv identified and merged BL PID `0x1011` with EL PID `0x1015` into bounded
  combined access units for one Profile 7 decoder.
- The tested APK selected `OMX.Nvidia.DOVI.decode`, the Android direct video
  Surface, and embedded PGS subtitle track 1.
- A physical near-EOF run showed correct colors, smooth playback, visible PGS
  subtitles/OSD, and LG Dolby Vision signaling, then reported
  `finished playback, success` at natural EOF.
- Starting near the end briefly entered the DTS-HD stream before a core audio
  frame and logged a recoverable decoder warning. Audio recovered; this was
  not a Dolby Vision video or dual-PID merger failure.

### Controls

HDR10 HEVC, SDR 10-bit HEVC, and SDR 8-bit H.264 remained recognizable and
correct in both tested MediaCodec modes. The Dolby Surface path was not
selected for those streams. External and embedded subtitles remained visible.

The full-matrix predecessor APK repeated all three local controls successfully.
HDR10 used
`OMX.Nvidia.h265.decode`, looked correct, and activated only the television's
HDR mode. SDR 10-bit HEVC used the same ordinary HEVC decoder, looked correct,
and activated no HDR/Dolby mode. SDR 8-bit H.264 used
`OMX.Nvidia.h264.decode`, looked correct, and activated no HDR/Dolby mode. All
three reached `finished playback, success` at natural EOF.

The final rebuilt APK repeated the SDR 8-bit H.264 control with
`android-dovi-overlay=no`. It used MediaCodec hardware decoding and gpu-next's
AImageReader external-texture path, displayed correct smooth video and
subtitles/OSD, activated no HDR/Dolby mode, and reached natural EOF without a
GLSL compile or link failure.

## Modified code

### FFmpeg

- `libavcodec/mediacodecdec.c`: optional Profile 5 RPU parsing, bounded
  timestamp-keyed side-data ownership, flush/close cleanup, Dolby Surface
  selection for Profile 5 and 8.1, opt-in Profile 7 decoder probing, and
  diagnostics.
- `libavcodec/mediacodecdec_common.c` and `.h`: MediaCodec format and hardware
  frame diagnostics used to distinguish copy and Surface output.
- `configure`: enables the hashing primitive used for short diagnostic RPU
  identifiers without logging proprietary payloads.

### mpv

- `video/decode/vd_lavc.c`: carries the Android direct-Surface selection into
  decoder setup.
- `video/out/hwdec/hwdec_aimagereader.c`: reports Android image-import details
  and safely handles direct-Surface/non-direct transitions.
- `video/out/vo_gpu_next.c`: reports Dolby side data and recovers renderer
  state when a direct frame is followed by an ordinary frame.
- `options/options.c` and `.h`: expose the opt-in Android Dolby overlay mode.
- `demux/dovi_split.c`, `demux/demux.c`, and `demux/demux.h`: expose an opt-in
  switch that preserves combined Profile 7 access units for a vendor decoder.
- `demux/demux_lavf.c`: pairs bounded dual-PID Dolby Vision M2TS access units,
  including reordered, duplicate, absent, and malformed timestamp handling.

### mpv-android

- `BaseMPVView.kt`, `MPVActivity.kt`, `MPVLib.kt`, `main.cpp`, `render.cpp`, and
  `player.xml`: create and manage the direct video Surface plus transparent
  subtitle/OSD Surface, preserve aspect ratio, and restore output after
  Surface loss.
- `MPVActivity.kt`: distinguishes lifecycle-induced pause from an explicit
  user pause when a replacement intent arrives.
- Build scripts and workflow: pin all native revisions, build only ARM64 for
  this diagnostic variant, use application ID `is.xyz.mpv.dovitest`, and keep
  unstripped symbols.

### libplacebo

- `src/dispatch.c`: keeps external samplers and declarations fragment-only and
  emits required GLSL extension directives before declarations, so Android
  external-texture shaders satisfy GLSL ES ordering and link requirements.

## Safety and lifetime checks

- Compressed packets are parsed once before MediaCodec input-buffer splitting.
- Side data is reference-counted and either moved to an output frame or
  released on mismatch, error, flush, seek, close, and reinitialization.
- The pending metadata queue is capped at 512 entries.
- Direct MediaCodec frames are released exactly once.
- Surface references are retained through decoder creation and released after
  decoder teardown.
- mpv's normal and UBSan suites passed all 39 tests. Focused normal and UBSan
  tests covered reordered, duplicate, missing, and malformed dual-PID input.
- Clang's static analyzer reported no finding in mpv's Dolby merger or
  libplacebo's modified dispatch code.
- All 15 applicable libplacebo normal and UBSan tests passed. An unrelated
  Vulkan external-host-pointer test fails on this build host with
  `VK_ERROR_INVALID_EXTERNAL_HANDLE` in both configurations.
- `git diff --check`, shell syntax checks, and the final Android build passed.

FreeBSD-hosted ASan could not be used for the mpv tests because its allocator
aborted before test execution. No ASan result is claimed.

The audit and exercised tests found no ordinary-path leak, use-after-free,
out-of-bounds access, undefined arithmetic, or varargs format mismatch in the
modified code. This is a bounded engineering conclusion, not a claim that
unexercised device- or driver-specific behavior cannot contain defects.

## Known limitations

- Profile 5 metadata propagation is opt-in and limited to single-layer
  BL+RPU.
- Native Surface decoding is opt-in and tested only with Profile 5, Profile
  8.1, and one combined-access-unit Profile 7.6 stream on the Shield decoder.
- Profile 7 split BL/EL decoding and FEL residual reconstruction are
  unsupported. Dual-PID M2TS input is merged into bounded combined access
  units for Nvidia compatibility playback; this does not add FEL residual
  reconstruction.
- The copy path renders corrected pixels but does not provide native Dolby
  Vision HDMI signaling.
- Native Surface results depend on Nvidia's proprietary decoder and are not
  automatically portable to other Android devices.
- USB/network-server behavior is outside the decoder patch. Network tests used
  an HTTP server with byte-range support.
- The Profile 8.1 per-frame report covers the first 60 seconds; decoding every
  frame of the 2 h 49 min feature solely for a JSON report was intentionally
  avoided.

## Rollback

1. Force-stop `is.xyz.mpv.dovitest`.
2. Remove `dovi_p5_metadata`, `dovi_surface_decoder`,
   `dovi_p7_surface_probe`, `android-dovi-overlay`, and
   `demuxer-dovi-split` from `mpv.conf`, or uninstall the `.dovitest` APK.
3. Install the official mpv-android APK. Its separate application ID means it
   can coexist with the diagnostic package.
4. No media files are modified by either playback path.

## Upstreaming plan

1. Submit FFmpeg Profile 5 parsing/side-data propagation independently from
   diagnostics and from Nvidia Surface output.
2. Submit mpv Android frame diagnostics and direct/ordinary frame transition
   cleanup independently.
3. Submit the libplacebo external-sampler shader-stage correction as its own
   change.
4. Submit the mpv Android overlay contract together with the mpv-android
   Surface ownership and lifecycle implementation.
5. Keep Nvidia native Dolby profile selection opt-in until it has wider device
   coverage. Keep Profile 7 preservation experimental and explicitly limited
   to compatibility playback because the FEL residual test failed.
