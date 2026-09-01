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

## Final artifact soak

The exact APK with SHA-256
`f3ecfc0d3e8c2e5b33e7446377af51fd1e8788ca5d1ad2a21bc5bb7a81fa4ec5`
looped this sample for 30 minutes with `hwdec=mediacodec-copy` and Profile 5
metadata propagation enabled.

| Minute | PID | State | Error | PSS (KiB) | RSS (KiB) |
| ---: | ---: | ---: | --- | ---: | ---: |
| 0 | 23573 | 3 (`PLAYING`) | `null` | 374030 | 488036 |
| 5 | 23573 | 3 (`PLAYING`) | `null` | 400515 | 486532 |
| 10 | 23573 | 3 (`PLAYING`) | `null` | 401470 | 485668 |
| 15 | 23573 | 3 (`PLAYING`) | `null` | 396915 | 483288 |
| 20 | 23573 | 3 (`PLAYING`) | `null` | 390051 | 475732 |
| 25 | 23573 | 3 (`PLAYING`) | `null` | 401736 | 486496 |
| 30 | 23573 | 3 (`PLAYING`) | `null` | 396607 | 482696 |

Memory remained within a bounded warm range and was nonmonotonic. No codec,
application, out-of-memory, or metadata-queue failure occurred.
