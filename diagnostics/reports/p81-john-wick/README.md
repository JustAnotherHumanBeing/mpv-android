# Profile 8.1 feature report

The tested Matroska feature is 3840x1608, 23.976 fps, 10-bit HEVC, Dolby Vision
Profile 8.1 BL+RPU, compatibility ID 1, and HDR10-compatible. Its SHA-256 is in
`sha256.txt`.

`ffprobe-video-frames-first-60s.json.xz` records complete ffprobe frame-side
data for the first 60 seconds. It confirms recurring Dolby Vision RPU data and
parsed Dolby Vision metadata. The full 2 h 49 min feature was used for physical
playback and the 30-minute soak, but was not decoded end-to-end merely to
produce a very large JSON report.
