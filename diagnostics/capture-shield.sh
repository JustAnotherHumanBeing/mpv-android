#!/bin/sh

set -eu

if [ "$#" -ne 4 ]; then
    echo "usage: $0 package-name test-id media-uri output-directory" >&2
    exit 64
fi

package=$1
test_id=$2
media_uri=$3
output=$4
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config="$script_dir/configs/test-${test_id}.conf"
remote_config="/data/local/tmp/mpv-dovi-${package}-${test_id}.conf"

case "$package" in
    ''|*[!A-Za-z0-9._]*)
        echo "invalid Android package name: $package" >&2
        exit 64
        ;;
esac

case "$test_id" in
    a|b|c|d) ;;
    *)
        echo "unknown test ID: $test_id" >&2
        exit 64
        ;;
esac

if [ ! -f "$config" ]; then
    echo "unknown test ID: $test_id" >&2
    exit 64
fi

mkdir -p "$output"
cp "$config" "$output/${test_id}-mpv.conf"

adb shell am force-stop "$package"
adb push "$config" "$remote_config" >/dev/null
adb shell run-as "$package" mkdir -p files
adb shell run-as "$package" cp "$remote_config" files/mpv.conf
adb shell rm -f "$remote_config"
adb exec-out run-as "$package" cat files/mpv.conf | cmp - "$config"
adb logcat -c
adb shell getprop >"$output/${test_id}-getprop.txt"
adb shell dumpsys display >"$output/${test_id}-display.txt"
adb shell dumpsys media.codec >"$output/${test_id}-media-codec.txt"

adb shell am start -W -a android.intent.action.VIEW \
    -d "$media_uri" -t video/x-matroska \
    -n "$package/is.xyz.mpv.MPVActivity" \
    >"$output/${test_id}-activity-start.txt"

echo "Observe test ${test_id}; record the television mode, then press Enter." >&2
read -r answer

adb logcat -d -v threadtime >"$output/${test_id}-logcat.txt"
adb shell dumpsys SurfaceFlinger >"$output/${test_id}-surfaceflinger.txt"
adb shell dumpsys media.codec >"$output/${test_id}-media-codec-after.txt"
adb shell dumpsys meminfo "$package" >"$output/${test_id}-meminfo.txt"
