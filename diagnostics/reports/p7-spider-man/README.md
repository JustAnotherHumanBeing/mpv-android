# Dolby Vision Profile 7 FEL sample

This directory records the characteristics of the local Profile 7 validation
sample. The copyrighted media file is not included.

- Container: Matroska
- Video: HEVC Main 10, 3840x2160, 24000/1001 fps
- Dolby Vision: Profile 7.6, level 6, BL+EL+RPU
- Base-layer compatibility: HDR10 (compatibility ID 6)
- First decoded frame: `disable_residual_flag=0`
- File size: 66,033,395,661 bytes
- SHA-256: `5b368ef5ef31d77652fecb80876b6663e5568344ec29896fd82796bf97924ac4`

The stream is a dual-layer Profile 7 FEL sample, not a Profile 7 MEL sample.
Its enabled enhancement-layer residual makes it unsuitable for claiming full
Profile 7 support based only on correct-looking colors or the television's
Dolby Vision indicator. A successful validation must also establish whether
the enhancement-layer residual is reconstructed.

The Shield codec registry exposes Nvidia's Dolby Vision decoder, but does not
advertise Android's Profile 7 value. The corresponding decoder experiment is
therefore explicitly opt-in and exploratory.

## Failed split-decoder probe

The first opt-in ARM64 probe used `vo=gpu-next`, `hwdec=mediacodec`, direct
Nvidia Dolby Vision surface output, and disabled software fallback. The
physical test failed: the television remained black and no video was visible.

The diagnostic log proves that `OMX.Nvidia.DOVI.decode` received the original
combined access units, including BL VCL, RPU NAL units, and EL NAL units. It
also records `DVProfile 64`, followed by Nvidia's `Profile 64 not supported`
message. mpv's separate 1920x1080 enhancement-layer MediaCodec instance failed
to configure, while the primary 3840x2160 Nvidia Dolby Vision instance
continued successfully.

The primary decoder accepted input and returned an initial MediaCodec frame,
but mpv's frame-pairing path held that frame while waiting for output from the
failed EL decoder. This explains the black screen without treating it as proof
that the primary Nvidia decoder had failed.

Probe APK:

- mpv-android commit: `783086b333f6f7ebe7441af6159ee27dd97270ce`
- FFmpeg commit: `a38ca389b1a6ca6a672591fda5b9f9d129b01d00`
- SHA-256: `e128331a42b1d954d4c6808c9e6bec5b1fbd2803e278acd28fce8f1cbdf3c29d`

## Combined-access-unit result

The follow-up build set `demuxer-dovi-split=no`, leaving the original combined
BL+EL+RPU access units intact for `OMX.Nvidia.DOVI.decode`. Software fallback
remained disabled.

The physical Shield test then passed the compatibility-playback checks:

- recognizable moving video was displayed;
- colors appeared correct;
- subtitles remained visible;
- the LG television entered Dolby Vision mode;
- pause/resume and forward/backward seeking remained stable;
- replacement-file transitions did not retain stale color or decoder state.

A seven-minute run remained `PLAYING` with `error=null` at every minute. PSS in
KiB was `327052, 358323, 358956, 368316, 366106, 362687, 389474, 376084`; it was
non-monotonic and ended below the peak. No codec crash, application crash, OOM,
or growing metadata queue was observed.

Validated APKs:

- direct/soak build: mpv-android `0fdacf12cb6224468480607b196ab4a0fb387d79`,
  SHA-256 `835c3a5fd9722ae2516eaa8d2be1665c8d7d1f0fb10fa47b3460929c1b2a8af5`;
- lifecycle/file-transition build: mpv-android
  `005f7e9db953d05d632562d0004c8a61362fb870`, SHA-256
  `b5dc489cc4217046804026d526abcf61df27b89cbcbae5e08181693608119e16`.

Both use FFmpeg `a38ca389b1a6ca6a672591fda5b9f9d129b01d00`, mpv
`a0f7fbc84bcfd9f03a5d06da52494d5cc5a892b6`, and libplacebo
`b3ff1dbe73de8e75bda36836f7b1b5a2e00068f1`.

This result does not reveal whether Nvidia applies the FEL enhancement-layer
residual. Correct-looking output and Dolby Vision signaling establish
compatibility playback, not complete FEL reconstruction.

Files:

- `ffprobe-streams.json`: complete stream and side-data inventory
- `ffprobe-video-first-frame.json`: decoded first-frame side data
- `mediainfo.json`: machine-readable MediaInfo report
- `mediainfo.txt`: human-readable MediaInfo report
- `sha256.txt`: full-file checksum
