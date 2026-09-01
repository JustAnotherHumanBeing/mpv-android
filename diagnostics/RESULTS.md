# Shield Dolby Vision validation results

## Scope

The implementation targets Nvidia Shield TV Pro 2019, Android 11, ARM64, and
an LG 4K OLED connected through a Dolby Vision-ready HDMI mode. It keeps normal
mpv/libass subtitles and OSD available.

Validated inputs:

- single-layer Dolby Vision Profile 5 BL+RPU;
- single-layer Dolby Vision Profile 8.1 BL+RPU, HDR10-compatible;
- HDR10 10-bit HEVC control;
- SDR 10-bit HEVC control;
- SDR 8-bit H.264 control;
- embedded and external SubRip subtitles.

Profile 7 and enhancement-layer reconstruction are not part of this validated
result.

## Results

### Profile 5 MediaCodec-copy

Configuration:

```text
vo=gpu-next
hwdec=mediacodec-copy
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

### Profile 5 and Profile 8.1 native Surface

Configuration:

```text
vo=gpu-next
hwdec=mediacodec
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

### Controls

HDR10 HEVC, SDR 10-bit HEVC, and SDR 8-bit H.264 remained recognizable and
correct in both tested MediaCodec modes. The Dolby Surface path was not
selected for those streams. External and embedded subtitles remained visible.

## Modified code

### FFmpeg

- `libavcodec/mediacodecdec.c`: optional Profile 5 RPU parsing, bounded
  timestamp-keyed side-data ownership, flush/close cleanup, Dolby Surface
  selection for Profile 5 and 8.1, and diagnostics.
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

### mpv-android

- `BaseMPVView.kt`, `MPVActivity.kt`, `MPVLib.kt`, `main.cpp`, `render.cpp`, and
  `player.xml`: create and manage the direct video Surface plus transparent
  subtitle/OSD Surface, preserve aspect ratio, and restore output after
  Surface loss.
- Build scripts and workflow: pin all native revisions, build only ARM64 for
  this diagnostic variant, use application ID `is.xyz.mpv.dovitest`, and keep
  unstripped symbols.

### libplacebo

- `src/dispatch.c`: keeps external samplers out of raster vertex shaders so
  the Android external-texture shader links correctly.

## Safety and lifetime checks

- Compressed packets are parsed once before MediaCodec input-buffer splitting.
- Side data is reference-counted and either moved to an output frame or
  released on mismatch, error, flush, seek, close, and reinitialization.
- The pending metadata queue is capped at 512 entries.
- Direct MediaCodec frames are released exactly once.
- Surface references are retained through decoder creation and released after
  decoder teardown.
- Build warnings in modified files, `git diff --check`, shell syntax checks,
  and libplacebo's ASan/UBSan test suite passed.

No ordinary-path leak, use-after-free, out-of-bounds access, or undefined
varargs format mismatch remains in the audited changes.

## Known limitations

- Profile 5 metadata propagation is opt-in and limited to single-layer
  BL+RPU.
- Native Surface decoding is opt-in and limited to single-layer Profile 5 and
  Profile 8.1 on the tested Shield decoder.
- Profile 7 MEL/FEL, dual-track Dolby Vision, and FEL residual reconstruction
  are unsupported.
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
2. Remove `dovi_p5_metadata`, `dovi_surface_decoder`, and
   `android-dovi-overlay` from `mpv.conf`, or uninstall the `.dovitest` APK.
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
   coverage. Do not upstream Profile 7 based only on visually plausible output
   or a television Dolby Vision logo.
