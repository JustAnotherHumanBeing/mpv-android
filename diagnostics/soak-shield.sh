#!/bin/sh

set -eu

if [ "$#" -lt 4 ] || [ "$#" -gt 6 ]; then
    echo "usage: $0 package-name config media-uri output-directory [duration-minutes [interval-minutes]]" >&2
    exit 64
fi

package=$1
config=$2
media_uri=$3
output=$4
duration_minutes=${5:-30}
interval_minutes=${6:-5}
remote_config="/data/local/tmp/mpv-dovi-soak-${package}.conf"
logcat_pid=

case "$package" in
    ''|*[!A-Za-z0-9._]*)
        echo "invalid Android package name: $package" >&2
        exit 64
        ;;
esac

case "$duration_minutes:$interval_minutes" in
    *[!0-9:]*|0:*|*:0)
        echo "duration and interval must be positive whole minutes" >&2
        exit 64
        ;;
esac

if [ ! -f "$config" ]; then
    echo "config does not exist: $config" >&2
    exit 66
fi

adb_run()
{
    if [ -n "${ADB_SERIAL:-}" ]; then
        command adb -s "$ADB_SERIAL" "$@"
    else
        command adb "$@"
    fi
}

stop_logcat()
{
    if [ -n "$logcat_pid" ]; then
        kill "$logcat_pid" 2>/dev/null || true
        wait "$logcat_pid" 2>/dev/null || true
        logcat_pid=
    fi
}

cleanup()
{
    stop_logcat
    adb_run shell am force-stop "$package" >/dev/null 2>&1 || true
}

snapshot()
{
    label=$(printf '%02d' "$1")
    date '+%Y-%m-%dT%H:%M:%S%z' >"$output/minute-${label}-time.txt"
    adb_run shell pidof "$package" >"$output/minute-${label}-pid.txt"
    adb_run shell dumpsys media_session \
        >"$output/minute-${label}-media-session.txt"
    adb_run shell dumpsys meminfo "$package" \
        >"$output/minute-${label}-meminfo.txt"
    echo "captured minute $label" >&2
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p "$output"
cp "$config" "$output/mpv.conf"

adb_run shell input keyevent 224 >/dev/null
sleep 2
adb_run shell am force-stop "$package"
adb_run push "$config" "$remote_config" >/dev/null
adb_run shell run-as "$package" mkdir -p files
adb_run shell run-as "$package" cp "$remote_config" files/mpv.conf
adb_run exec-out run-as "$package" cat files/mpv.conf | cmp - "$config"
adb_run logcat -c
adb_run logcat -v threadtime >"$output/logcat.txt" \
    2>"$output/logcat-stderr.txt" &
logcat_pid=$!

adb_run shell am start -W -a android.intent.action.VIEW \
    -d "$media_uri" -t video/x-matroska \
    -n "$package/is.xyz.mpv.MPVActivity" \
    >"$output/activity-start.txt"

sleep 10
snapshot 0

elapsed=0
while [ "$elapsed" -lt "$duration_minutes" ]; do
    remaining=$((duration_minutes - elapsed))
    step=$interval_minutes
    if [ "$step" -gt "$remaining" ]; then
        step=$remaining
    fi
    sleep $((step * 60))
    elapsed=$((elapsed + step))
    snapshot "$elapsed"
done

adb_run shell dumpsys activity activities >"$output/activity-final.txt"
adb_run shell dumpsys SurfaceFlinger >"$output/surfaceflinger-final.txt"
adb_run shell dumpsys media.codec >"$output/media-codec-final.txt" 2>&1 || true
stop_logcat

if [ -s "$output/logcat-stderr.txt" ]; then
    cat "$output/logcat-stderr.txt" >&2
    exit 1
fi
