#!/bin/sh

export DISPLAY=:1
export DBUS_SESSION_BUS_ADDRESS=/dev/null

# Start Xvfb
XVFB_WHD=${XVFB_WHD:-1280x720x16}
Xvfb $DISPLAY -ac -screen 0 $XVFB_WHD -nolisten tcp &
echo "running: $@"
exec $@
