#!/bin/sh

set -eu

if [ "$#" -ne 3 ]; then
    echo "usage: $0 package-name test-id output-directory" >&2
    exit 64
fi

package=$1
test_id=$2
output=$3

mkdir -p "$output"

adb shell am force-stop "$package"
adb logcat -c
adb shell getprop >"$output/${test_id}-getprop.txt"
adb shell dumpsys display >"$output/${test_id}-display.txt"
adb shell dumpsys media.codec >"$output/${test_id}-media-codec.txt"

echo "Start playback for test ${test_id}, then press Enter here." >&2
read answer

adb logcat -d -v threadtime >"$output/${test_id}-logcat.txt"
adb shell dumpsys SurfaceFlinger >"$output/${test_id}-surfaceflinger.txt"
adb shell dumpsys media.codec >"$output/${test_id}-media-codec-after.txt"
adb shell dumpsys meminfo "$package" >"$output/${test_id}-meminfo.txt"

