# Profile 7 FEL residual reconstruction test

The report describes `FEL_TEST_ST_DL_P7_CMV4_4000nits_V4.mkv`; the media file
itself is not stored in this repository.

- SHA-256: `60d1a337a09609c639f8111685b59f89902cc79606f2bdf3a9c269cd0b508bfa`
- Container: Matroska
- Duration: 2 min 1 s
- Video: 3840x2160, 23.976 fps, 10-bit HEVC
- Dolby Vision: Profile 7.6, BL+EL+RPU, compatibility ID 6
- Frame metadata: `el_spatial_resampling_filter_flag=1` and
  `disable_residual_flag=0`

The clip displays the literal sentence `This device can decode FEL` only when
the enhancement-layer residual is reconstructed. It was run twice from a
force-stopped application with the native Nvidia Dolby Surface path. The LG
television entered Dolby Vision mode and both runs reached normal end of file,
but the sentence never appeared.

This is a negative result for FEL residual reconstruction. The Shield path can
provide useful Profile 7 compatibility playback and Dolby Vision signaling,
but it must not be described as complete FEL decoding.
