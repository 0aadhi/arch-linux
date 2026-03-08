#!/bin/sh

# check if networking is enabled
NETSTATE=$(nmcli -t -f WIFI general status | cut -d: -f1)

# OFF (exact width)
[ "$NETSTATE" = "disabled" ] && printf " N:OFF" && exit 0

# connected device
INFO=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$3=="connected"{print $1 ":" $2; exit}')

# ON but not connected
[ -z "$INFO" ] && printf " N:ON " && exit 0

DEV=${INFO%%:*}
TYPE=${INFO##*:}

[ "$TYPE" = "wifi" ] && LABEL=" W:" || LABEL=" E:"

RX1=$(cat /sys/class/net/$DEV/statistics/rx_bytes)
sleep 1
RX2=$(cat /sys/class/net/$DEV/statistics/rx_bytes)

RX=$((RX2 - RX1))

fmt() {
    b=$1
    if [ "$b" -ge 1073741824 ]; then
        printf "%3dG" $((b / 1073741824))
    elif [ "$b" -ge 1048576 ]; then
        printf "%3dM" $((b / 1048576))
    else
        printf "%3dK" $((b / 1024))
    fi
}

printf "%s%s" "$LABEL" "$(fmt "$RX")"
