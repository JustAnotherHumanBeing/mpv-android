# Shield Profile 5 baseline - 2026-08-30

## Frozen environment

- Device: Nvidia Shield TV Pro 2019 (`mdarcy`), Android 11
- Firmware build: `RQ1A.210105.003.7825230_4387.0822`
- Display mode: 3840x2160 at 59.94006 Hz; HDMI reports HDR10 and Dolby Vision support
- APK: ARM64 debug, package `is.xyz.mpv.dovitest`
- APK SHA-256: `018cfba04674c47a1a7cbf4ac8cb749bae630f78969861ffec8a2bc31caa2410`
- mpv-android upstream baseline: `474111adc4abe5b67f3f8082c8a307e80d45c174`
- APK integration commit: `b389effde3bb43f39cbac72f42ca0c40a0859f08`
- Host capture harness: `982500fe1db6898f1c4b0d15e890f41ccfb07158`
- mpv diagnostics: `b34d890f311968165b9b7c8de862b54932c7ec87`
- FFmpeg diagnostics: `1e2198971fdab6885e8cca9b7467834e75f5bfbf`
- libplacebo: `22ee762e8e0890fc54068beb670310f0edce7263`
- Android SDK/API and build tools: 36 / 36.0.0
- Android NDK: r29 (`29.0.14206865`)

The sample is a 60-second, single-layer Profile 5 BL+RPU Matroska file. Its
SHA-256 is `17dd982abae2e4100176524916b05f7040e9ee599a3c39102ea0252e84e93dba`.
The media itself is not stored in Git. Its MediaInfo and ffprobe reports are in
`diagnostics/reports/p5-smoke-s01e01-60s/`.

The LG picture-mode indicator was not re-observed during this instrumented
run, so it is recorded as unknown rather than inferred from Android state.

## Test A - software decoding

Configuration:

```ini
vo=gpu-next
hwdec=no
```

Observed result:

- The recognizable Dolby Vision program image is displayed.
- Colors appear correct.
- No pink/green or solid-magenta problem is present.
- 4K playback is too slow to be practically usable on the Shield.

Instrumentation captured 1,468 decoded AVFrames. Every captured AVFrame had
`AV_FRAME_DATA_DOVI_METADATA` and `AV_FRAME_DATA_DOVI_RPU_BUFFER`; gpu-next
selected `dolby-vision-reshaping` for all 945 frames that reached its logged
render-input point. Four audio underruns were recorded.

## Test B - MediaCodec copy decoding

Configuration:

```ini
vo=gpu-next
hwdec=mediacodec-copy
```

Observed result:

- The recognizable actual video image is displayed.
- Playback is hardware accelerated and substantially faster.
- The entire image has an incorrect pink/green hue.
- This resembles an unprocessed Dolby Vision Profile 5 base layer.
- mpv subtitles and OSD are available.

The Nvidia decoder processed the complete sample at 23.976 fps. Instrumentation
found an RPU in 1,451 compressed packets, but all 1,437 decoded AVFrames had no
Dolby Vision metadata and no raw RPU side data. gpu-next selected `path=sdr` for
1,436 frames. MediaCodec reported `OMX.Nvidia.h265.decode`, copied NV12 output,
BT.601/BT.1886 frame tags, and no reported 10-bit output format.

## Test C - non-copy MediaCodec decoding

Configuration:

```ini
vo=gpu-next
hwdec=mediacodec
```

Observed result:

- The recognizable video image is not displayed.
- Instead, the output is a solid or near-solid magenta field.
- This is visibly different from Test B's recognizable but pink/green image.
- Test B and Test C are not assumed to have precisely the same root cause.

Instrumentation found RPUs in 1,176 compressed packets, but all 1,172 decoded
AVFrames lacked Dolby Vision side data. AImageReader returned private images
with unknown dataspace, no readable planes, AHardwareBuffer format `0x10b`, and
an identity transform. EGLImage creation and external-OES binding reported
success, but libplacebo logged one `GL_INVALID_OPERATION` while creating the
render pass. gpu-next treated 1,170 imported RGB frames as SDR.

## Test D - direct MediaCodec output

Configuration:

```ini
vo=mediacodec_embed
hwdec=mediacodec
```

Observed result:

- Video output is black on this Shield.
- This path is not an acceptable solution regardless, because normal
  mpv/libass subtitle and OSD composition is required.

The direct Surface path decoded 1,090 captured frames. All lacked Dolby Vision
side data and carried BT.709/BT.1886 tags.

## Files

`logs/*.xz` contains complete filtered logcat streams. `state/` contains the
exact per-test configuration, activity-launch result, display state,
SurfaceFlinger state, memory report, and log-buffer state. Android 11 on this
Shield does not expose a `media.codec` dumpsys service; decoder details are
therefore captured through FFmpeg instrumentation and relevant Android log
tags instead.
