#!/bin/sh

DMENU="dmenu -i -l 8"
NOTIFY="notify-send"

# get connected bluetooth device name
BT_CONNECTED=$(bluetoothctl info 2>/dev/null \
    | awk -F': ' '/Name:/{print $2}')

while :; do
    PROMPT="Bluetooth"
    [ -n "$BT_CONNECTED" ] && PROMPT="Bluetooth (Connected: $BT_CONNECTED)"

    ACTION=$(printf \
"Power ON
Power OFF
Scan ON
Scan OFF
Pair Device
Connect Device
Disconnect Device
Remove Device
Exit" | $DMENU -p "$PROMPT")

    [ -z "$ACTION" ] && exit 0

    case "$ACTION" in
        "Power ON")
            bluetoothctl power on && $NOTIFY "Bluetooth" "Powered ON"
            ;;
        "Power OFF")
            bluetoothctl power off && $NOTIFY "Bluetooth" "Powered OFF"
            ;;
        "Scan ON")
            bluetoothctl --timeout 0 scan on &
            echo $! > /tmp/bt-scan.pid
            $NOTIFY "Bluetooth" "Scanning..."
            ;;
        "Scan OFF")
            [ -f /tmp/bt-scan.pid ] && kill "$(cat /tmp/bt-scan.pid)" 2>/dev/null
            bluetoothctl scan off
            rm -f /tmp/bt-scan.pid
            $NOTIFY "Bluetooth" "Scan stopped"
            ;;
        "Pair Device")
            DEV=$(bluetoothctl devices | sed 's/^Device //' | $DMENU -p "Pair")
            [ -z "$DEV" ] && continue
            MAC=$(echo "$DEV" | awk '{print $1}')
            NAME=$(echo "$DEV" | cut -d' ' -f2-)
            bluetoothctl pair "$MAC" && $NOTIFY "Bluetooth" "Paired $NAME"
            ;;
        "Connect Device")
            DEV=$(bluetoothctl devices | sed 's/^Device //' | $DMENU -p "Connect")
            [ -z "$DEV" ] && continue
            MAC=$(echo "$DEV" | awk '{print $1}')
            NAME=$(echo "$DEV" | cut -d' ' -f2-)
            bluetoothctl connect "$MAC" && $NOTIFY "Bluetooth" "Connected $NAME"
            ;;
        "Disconnect Device")
            bluetoothctl disconnect && $NOTIFY "Bluetooth" "Disconnected"
            ;;
        "Remove Device")
            DEV=$(bluetoothctl devices | sed 's/^Device //' | $DMENU -p "Remove")
            [ -z "$DEV" ] && continue
            MAC=$(echo "$DEV" | awk '{print $1}')
            bluetoothctl remove "$MAC" && $NOTIFY "Bluetooth" "Removed device"
            ;;
        "Exit")
            exit 0
            ;;
    esac
done
