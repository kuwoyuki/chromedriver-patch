#!/bin/bash

check_or_install() {
    local name="$1"

    if [ ! $(command -v $name) ]; then
        echo "[X] no $name found on the system. we'll install it now.."
        sleep 1
        DEBIAN_FRONTEND=noninteractive apt-get install -yqq $name
    fi
    command -v $name >/dev/null
    return $?
}

startDesktop() {
    check_or_install x11vnc || return 1
    check_or_install Xvfb || return 1
    check_or_install xvfb-run || return 1
    check_or_install fluxbox || return 1

    x11vnc -create -env FD_PROG=/usr/bin/fluxbox \
        -env X11VNC_FINDDISPLAY_ALWAYS_FAILS=1 \
        -env X11VNC_CREATE_GEOM=${1:-1280x720x16} \
        -gone 'killall Xvfb' \
        -forever \
        -nopw \
        -quiet &

    localip="$(hostname -I)"
    remoteip=$(curl -s "https://httpbin.org/ip" |
        grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)")

    echo "----------------------------------------------------------"
    echo "to conect to your desktop using vnc:"
    echo "depending on your setup"
    echo ""
    echo "${localip}:5900   (local)"
    echo "or"
    echo "${remoteip}:5900  (remote)"
    echo "----------------------------------------------------------"
    echo "in both cases, the container should have exposed port 5900"
    echo "like 'docker run ...  -P 5900:5900 .... '"
    echo "----------------------------------------------------------"
    xrdp &
}

trap _kill_procs SIGTERM

export DISPLAY=:1
XVFB_WHD=${XVFB_WHD:-1280x720x16}
# Start Xvfb
Xvfb $DISPLAY -ac -screen 0 $XVFB_WHD -nolisten tcp &
startDesktop &
echo "running: $@"
exec $@
