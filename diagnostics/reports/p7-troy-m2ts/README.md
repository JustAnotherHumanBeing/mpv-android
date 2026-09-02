# Dolby Vision Profile 7 dual-PID M2TS sample

This directory records the characteristics of the local Troy UHD Blu-ray
transport stream. The copyrighted media file is not included.

- SHA-256: `1cb579f58ffa9c85c47dde40e614fbee9257787c905f8bc702b5aa6b206cf847`
- Container: BDAV/MPEG transport stream, 97,664,624,640 bytes
- Duration: 3 h 16 min 3.795 s
- Base layer: PID `0x1011`, 3840x2160, 24000/1001 fps, 10-bit HEVC,
  HDR10 compatible
- Enhancement layer: PID `0x1015`, 1920x1080, 24000/1001 fps, 10-bit HEVC
- Dolby Vision: dual-layer Profile 7 BL+EL+RPU
- Frame metadata: `el_spatial_resampling_filter_flag=1` and
  `disable_residual_flag=0`
- Audio: DTS-HD Master Audio 5.1 and 16-bit stereo Blu-ray PCM
- Subtitles: PGS, PID `0x12a0`

mpv's M2TS merger paired the independently packetized base- and
enhancement-layer access units before passing them to Nvidia's Dolby Vision
decoder. On the physical Shield, the LG television entered Dolby Vision mode,
colors appeared correct, PGS subtitles were visible, playback was smooth, and
the near-EOF test reached normal end of file. A transient DTS-HD warning was
observed after starting near EOF in the middle of an audio stream; audio then
recovered.

This is a successful Profile 7 compatibility and dual-PID demuxing result. It
does not establish FEL residual reconstruction. The dedicated residual test in
`../p7-fel-residual/` produced a negative result.

Files:

- `ffprobe-streams.json`: complete stream inventory
- `ffprobe-video-frames-first-60s.json.xz`: decoded frame side data for the
  first 60 seconds
- `mediainfo.json`: machine-readable complete MediaInfo report
- `mediainfo.txt`: human-readable complete MediaInfo report
- `sha256.txt`: full-file checksum
