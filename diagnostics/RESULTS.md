# Shield Dolby Vision validation results

## Scope

The implementation targets Nvidia Shield TV Pro 2019, Android 11, ARM64, and
an LG 4K OLED connected through a Dolby Vision-ready HDMI mode. It keeps normal
mpv/libass subtitles and OSD available.

Validated inputs:

- single-layer Dolby Vision Profile 5 BL+RPU;
- single-layer Dolby Vision Profile 8.1 BL+RPU, HDR10-compatible;
- dual-layer Dolby Vision Profile 7 BL+EL+RPU compatibility playback;
- HDR10 10-bit HEVC control;
- SDR 10-bit HEVC control;
- SDR 8-bit H.264 control;
- embedded and external SubRip subtitles.

The Profile 7 result validates compatibility playback through Nvidia's Dolby
Vision decoder. It does not prove enhancement-layer residual reconstruction.

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

These observations establish useful Profile 7 compatibility playback on this
Shield. They do not establish whether Nvidia reconstructs the FEL residual, so
this is not a claim of complete Profile 7 FEL decoding.

### Controls

HDR10 HEVC, SDR 10-bit HEVC, and SDR 8-bit H.264 remained recognizable and
correct in both tested MediaCodec modes. The Dolby Surface path was not
selected for those streams. External and embedded subtitles remained visible.

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
- Native Surface decoding is opt-in and tested only with Profile 5, Profile
  8.1, and one combined-access-unit Profile 7.6 stream on the Shield decoder.
- Profile 7 split BL/EL decoding, dual-track Dolby Vision, and verified FEL
  residual reconstruction are unsupported.
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
   coverage. Keep Profile 7 preservation experimental until FEL reconstruction
   can be verified independently of plausible output and television signaling.
