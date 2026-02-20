#!/bin/sh

DMENU="dmenu -i -l 8"
NOTIFY="notify-send"

while :; do
    ACTION=$(printf \
"Connect VPN
Disconnect VPN
VPN Status
Add VPN
Exit" | $DMENU -p "VPN")

    [ -z "$ACTION" ] && exit 0

    case "$ACTION" in
        "Connect VPN")
            VPN=$(nmcli -t -f NAME,TYPE con show | grep vpn | cut -d: -f1 \
                | $DMENU -p "Select VPN")
            [ -z "$VPN" ] && continue
            nmcli con up "$VPN" >/dev/null 2>&1 \
                && $NOTIFY "VPN" "Connected $VPN"
            ;;
        "Disconnect VPN")
            VPN=$(nmcli -t -f NAME,TYPE con show --active | grep vpn | cut -d: -f1)
            [ -z "$VPN" ] && {
                $NOTIFY "VPN" "No VPN active"
                continue
            }
            nmcli con down "$VPN" >/dev/null 2>&1 \
                && $NOTIFY "VPN" "Disconnected $VPN"
            ;;
        "VPN Status")
            INFO=$(nmcli -f NAME,TYPE,DEVICE,STATE con show --active | grep vpn)
            [ -z "$INFO" ] && $NOTIFY "VPN" "No VPN active" || $NOTIFY "VPN" "$INFO"
            ;;
        "Add VPN")
            nm-connection-editor &
            ;;
        "Exit")
            exit 0
            ;;
    esac
done
