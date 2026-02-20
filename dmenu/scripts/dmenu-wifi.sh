#!/bin/sh

NOTIFY="notify-send"
DMENU="dmenu -i -l 10"
TERM="st"

# detect wifi interface
IFACE=$(nmcli -g DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1}')
[ -z "$IFACE" ] && $NOTIFY "WiFi" "No WiFi device found" && exit 1

# get active SSID (if any)
ACTIVE_SSID=$(nmcli -t -f ACTIVE,SSID dev wifi list ifname "$IFACE" \
    | awk -F: '$1=="yes"{print $2}')

# password prompt
ask_pass() {
    $TERM -e sh -c '
        stty -echo
        printf "Password: "
        read pass
        stty echo
        echo
        printf "%s" "$pass"
    '
}

while :; do
    PROMPT="WiFi"
    [ -n "$ACTIVE_SSID" ] && PROMPT="WiFi (Connected: $ACTIVE_SSID)"

    ACTION=$(printf "WiFi ON\nWiFi OFF\nConnect\nDisconnect\nExit" \
        | $DMENU -p "$PROMPT")

    [ -z "$ACTION" ] && exit 0

    case "$ACTION" in
        "WiFi ON")
            nmcli radio wifi on && $NOTIFY "WiFi" "Enabled"
            ;;
        "WiFi OFF")
            nmcli radio wifi off && $NOTIFY "WiFi" "Disabled"
            ;;
        "Disconnect")
            nmcli device disconnect "$IFACE" \
              && $NOTIFY "WiFi" "Disconnected $ACTIVE_SSID"
            ;;
        "Connect")
            NET=$(nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL dev wifi list ifname "$IFACE" \
                | sed 's/^*/*:/' \
                | $DMENU -p "Select Network")

            [ -z "$NET" ] && continue

            INUSE=$(echo "$NET" | cut -d: -f1)
            SSID=$(echo "$NET" | cut -d: -f2)
            SEC=$(echo "$NET" | cut -d: -f3)
            SIG=$(echo "$NET" | cut -d: -f4)

            [ "$INUSE" = "*" ] && {
                $NOTIFY "WiFi" "Already connected to $SSID"
                continue
            }

            # saved network
            if nmcli -t -f NAME con show | grep -Fxq "$SSID"; then
                nmcli con up "$SSID" >/dev/null 2>&1 \
                    && $NOTIFY "WiFi" "Connected to $SSID (${SIG}%)" \
                    || $NOTIFY "WiFi" "Failed to connect $SSID"
                continue
            fi

            # new network
            if [ "$SEC" = "--" ]; then
                nmcli dev wifi connect "$SSID" ifname "$IFACE" >/dev/null 2>&1 \
                    && $NOTIFY "WiFi" "Connected to $SSID (${SIG}%)" \
                    || $NOTIFY "WiFi" "Connection failed"
            else
                PASS=$(ask_pass)
                [ -z "$PASS" ] && continue

                if nmcli dev wifi connect "$SSID" password "$PASS" ifname "$IFACE" >/dev/null 2>&1; then
                    $NOTIFY "WiFi" "Connected to $SSID (${SIG}%)"
                else
                    $NOTIFY "WiFi" "Wrong password for $SSID"
                fi
            fi
            ;;
        "Exit")
            exit 0
            ;;
    esac
done
