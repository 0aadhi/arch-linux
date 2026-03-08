#!/bin/sh

DMENU="dmenu -i -l 10"
NOTIFY="notify-send"

while :; do
    BT_CONNECTED=$(bluetoothctl info | grep "Name:" | cut -d' ' -f2-)
    PROMPT="Bluetooth"
    [ -n "$BT_CONNECTED" ] && PROMPT="BT: $BT_CONNECTED"

    ACTION=$(printf "Power ON\nPower OFF\nStart Scan (15s)\nStop Scan\nConnect Device\nDisconnect Device\nPair Device\nRemove Device\nExit" | $DMENU -p "$PROMPT")

    [ -z "$ACTION" ] || [ "$ACTION" = "Exit" ] && exit 0

    case "$ACTION" in
        "Power ON")
            bluetoothctl power on && $NOTIFY "Bluetooth" "Powered ON"
            ;;
        "Power OFF")
            bluetoothctl power off && $NOTIFY "Bluetooth" "Powered OFF"
            ;;
        "Start Scan (15s)")
            (bluetoothctl --timeout 15 scan on) & 
            $NOTIFY "Bluetooth" "Scanning for 15s..."
            ;;
        "Stop Scan")
            pkill -f "bluetoothctl.*scan on"
            bluetoothctl scan off
            $NOTIFY "Bluetooth" "Scan stopped"
            ;;
        "Connect Device")
            # FIX: We grep "^Device" to ignore Controllers/Agents, then format
            DEVICE_LIST=$(bluetoothctl devices | grep "^Device" | awk '{print substr($0, index($0,$3)) " | " $2}')
            
            SELECTED=$(echo "$DEVICE_LIST" | $DMENU -p "Connect")
            [ -z "$SELECTED" ] && continue
            
            # Extract MAC from the end of the line
            MAC=$(echo "$SELECTED" | awk -F ' | ' '{print $NF}')
            NAME=$(echo "$SELECTED" | awk -F ' | ' '{print $1}')

            $NOTIFY "Bluetooth" "Connecting to $NAME"
            # Trust is required on Arch for the connection to stay active
            bluetoothctl trust "$MAC" >/dev/null 2>&1
            bluetoothctl connect "$MAC"
            ;;
        "Disconnect Device")
            MAC=$(bluetoothctl info | grep "^Device" | awk '{print $2}')
            if [ -n "$MAC" ]; then
                bluetoothctl disconnect "$MAC" && $NOTIFY "Bluetooth" "Disconnected"
            else
                $NOTIFY "Bluetooth" "No device connected"
            fi
            ;;
        "Pair Device")
            # Cleanup for Pairing list as well
            DEV=$(bluetoothctl devices | grep "^Device" | sed 's/^Device //' | $DMENU -p "Pair")
            [ -z "$DEV" ] && continue
            MAC=$(echo "$DEV" | awk '{print $1}')
            $NOTIFY "Bluetooth" "Pairing..."
            echo -e "agent on\npair $MAC\ntrust $MAC\nquit" | bluetoothctl
            ;;
        "Remove Device")
            DEV=$(bluetoothctl devices | grep "^Device" | sed 's/^Device //' | $DMENU -p "Remove")
            [ -z "$DEV" ] && continue
            MAC=$(echo "$DEV" | awk '{print $1}')
            bluetoothctl remove "$MAC" && $NOTIFY "Bluetooth" "Device Removed"
            ;;
    esac
done
