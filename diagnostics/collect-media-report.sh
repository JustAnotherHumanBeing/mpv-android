#!/bin/sh

set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: $0 input-file output-directory" >&2
    exit 64
fi

input=$1
output=$2
filename=${input##*/}

mkdir -p "$output"

if command -v sha256sum >/dev/null 2>&1; then
    hash=$(sha256sum "$input" | awk '{ print $1 }')
else
    hash=$(sha256 -q "$input")
fi
printf '%s  %s\n' "$hash" "$filename" >"$output/sha256.txt"

if command -v mediainfo >/dev/null 2>&1; then
    mediainfo "$input" >"$output/mediainfo.txt"
    mediainfo --Output=JSON "$input" >"$output/mediainfo.json"
else
    echo "mediainfo is not installed" >"$output/mediainfo-unavailable.txt"
fi

ffprobe -v error -show_streams -show_programs -show_chapters -show_format \
    -show_data -of json "$input" >"$output/ffprobe-streams.json"

ffprobe -v error -select_streams v:0 -show_frames -show_data -of json \
    "$input" >"$output/ffprobe-video-frames.json"
