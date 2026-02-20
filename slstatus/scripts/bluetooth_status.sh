#!/bin/sh

power=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [ "$power" != "yes" ]; then
    echo "Off"
    exit
fi

device=$(bluetoothctl info | grep "Name:" | cut -d' ' -f2-)

if [ -n "$device" ]; then
    echo "$device"
else
    echo "On"
fi

