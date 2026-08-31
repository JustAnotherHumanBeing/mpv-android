# Profile 5 baseline sample

This report describes a local, user-supplied one-minute Dolby Vision Profile 5
sample. The copyrighted media file is intentionally excluded from Git.

The sample contains:

- one 3840x1606 HEVC Main 10 video stream;
- Dolby Vision Profile 5 BL+RPU signaling, with no enhancement layer;
- one E-AC-3 audio stream; and
- one SubRip subtitle stream for subtitle-composition testing.

It was produced without transcoding, inherited stream statistics, global
metadata, or chapters:

```sh
ffmpeg -ss 300 -i "$SOURCE" -t 60 \
    -map 0:v:0 -map 0:a:0 -map '0:s:0?' -c copy \
    -map_metadata -1 -map_metadata:s -1 -map_chapters -1 \
    -avoid_negative_ts make_zero p5-smoke-s01e01-60s.mkv
```
