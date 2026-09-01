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

## Shield probe result

The opt-in ARM64 probe used `vo=gpu-next`, `hwdec=mediacodec`, direct Nvidia
Dolby Vision surface output, and disabled software fallback. During the
physical test, the following all passed:

- recognizable video with correct-looking colors and smooth motion;
- visible mpv subtitles and OSD; and
- activation of the LG television's Dolby Vision picture mode.

The diagnostic log proves that `OMX.Nvidia.DOVI.decode` received the original
combined access units, including BL VCL, RPU NAL units, and EL NAL units. It
also records `DVProfile 64`, followed by Nvidia's `Profile 64 not supported`
message. mpv's separate 1920x1080 enhancement-layer MediaCodec instance failed
to configure, while the primary 3840x2160 Nvidia Dolby Vision instance
continued successfully.

Consequently, this is a successful Profile 7 compatibility-playback result,
but it is not proof of full FEL reconstruction. The most defensible current
interpretation is native Dolby Vision BL+RPU playback with the FEL residual
possibly ignored. Correct-looking colors and the television's Dolby Vision
indicator are insufficient to distinguish that result from full FEL output.

Probe APK:

- mpv-android commit: `783086b333f6f7ebe7441af6159ee27dd97270ce`
- FFmpeg commit: `a38ca389b1a6ca6a672591fda5b9f9d129b01d00`
- SHA-256: `e128331a42b1d954d4c6808c9e6bec5b1fbd2803e278acd28fce8f1cbdf3c29d`

Files:

- `ffprobe-streams.json`: complete stream and side-data inventory
- `ffprobe-video-first-frame.json`: decoded first-frame side data
- `mediainfo.json`: machine-readable MediaInfo report
- `mediainfo.txt`: human-readable MediaInfo report
- `sha256.txt`: full-file checksum
