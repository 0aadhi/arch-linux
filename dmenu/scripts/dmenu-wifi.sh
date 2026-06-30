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

# password prompt — uses st + temp file so the password is correctly
# captured back into this shell (fixes the original read-not-captured bug)
ask_pass() {
    _SSID="$1"
    _TMPFILE=$(mktemp /tmp/wifi-pass.XXXXXX)
    chmod 600 "$_TMPFILE"
    $TERM -e sh -c "  
        printf 'Password for $_SSID: '
        read pass
        echo
        printf '%s' \"\$pass\" > '$_TMPFILE'
    "
    cat "$_TMPFILE"
    rm -f "$_TMPFILE"
}

# do the actual connection (new or saved)
do_connect() {
    _SSID="$1"
    _SEC="$2"
    _SIG="$3"

    # saved network
    if nmcli -t -f NAME con show | grep -Fxq "$_SSID"; then
        nmcli con up "$_SSID" >/dev/null 2>&1 \
            && { $NOTIFY "WiFi" "Connected to $_SSID (${_SIG}%)"; ACTIVE_SSID="$_SSID"; } \
            || $NOTIFY "WiFi" "Failed to connect $_SSID"
        return
    fi

    # open network
    if [ "$_SEC" = "--" ]; then
        nmcli dev wifi connect "$_SSID" ifname "$IFACE" >/dev/null 2>&1 \
            && { $NOTIFY "WiFi" "Connected to $_SSID (${_SIG}%)"; ACTIVE_SSID="$_SSID"; } \
            || $NOTIFY "WiFi" "Connection failed"
    else
        # password protected — ask via terminal + temp file
        PASS=$(ask_pass "$_SSID")
        [ -z "$PASS" ] && return

        if nmcli dev wifi connect "$_SSID" password "$PASS" ifname "$IFACE" >/dev/null 2>&1; then
            $NOTIFY "WiFi" "Connected to $_SSID (${_SIG}%)"
            ACTIVE_SSID="$_SSID"
        else
            $NOTIFY "WiFi" "Wrong password for $_SSID"
        fi
    fi
}

# show sub-menu for a selected network
network_submenu() {
    _SSID="$1"
    _SEC="$2"
    _SIG="$3"
    _INUSE="$4"

    # check current auto-connect state for this connection
    _AUTOCON=$(nmcli -t -f connection.autoconnect con show "$_SSID" 2>/dev/null \
        | cut -d: -f2)

    if [ "$_AUTOCON" = "yes" ]; then
        _AUTOLABEL="Auto Connect: ON"
    else
        _AUTOLABEL="Auto Connect: OFF"
    fi

    # build sub-menu options
    if [ "$_INUSE" = "*" ]; then
        # already connected — no Connect option
        _OPTIONS=$(printf "Disconnect\n$_AUTOLABEL\nForget\nBack")
    else
        _OPTIONS=$(printf "Connect\n$_AUTOLABEL\nForget\nBack")
    fi

    SUBCHOICE=$(printf "%s" "$_OPTIONS" | $DMENU -p "$_SSID ($_SEC | ${_SIG}%)")
    [ -z "$SUBCHOICE" ] && return

    case "$SUBCHOICE" in
        "Connect")
            do_connect "$_SSID" "$_SEC" "$_SIG"
            ;;
        "Disconnect")
            nmcli device disconnect "$IFACE" >/dev/null 2>&1 \
                && { $NOTIFY "WiFi" "Disconnected from $_SSID"; ACTIVE_SSID=""; } \
                || $NOTIFY "WiFi" "Failed to disconnect"
            ;;
        "Auto Connect: ON")
            nmcli con mod "$_SSID" connection.autoconnect no 2>/dev/null \
                && $NOTIFY "WiFi" "Auto Connect OFF for $_SSID" \
                || $NOTIFY "WiFi" "Failed — is '$_SSID' a saved connection?"
            ;;
        "Auto Connect: OFF")
            nmcli con mod "$_SSID" connection.autoconnect yes 2>/dev/null \
                && $NOTIFY "WiFi" "Auto Connect ON for $_SSID" \
                || $NOTIFY "WiFi" "Failed — is '$_SSID' a saved connection?"
            ;;
        "Forget")
            CONFIRM=$(printf "No\nYes" | $DMENU -p "Forget $_SSID?")
            [ "$CONFIRM" = "Yes" ] && {
                nmcli con delete "$_SSID" >/dev/null 2>&1 \
                    && $NOTIFY "WiFi" "Forgot $_SSID" \
                    || $NOTIFY "WiFi" "Failed to forget $_SSID (not saved?)"
            }
            ;;
        "Back")
            return
            ;;
    esac
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
                && { $NOTIFY "WiFi" "Disconnected $ACTIVE_SSID"; ACTIVE_SSID=""; } \
                || $NOTIFY "WiFi" "Failed to disconnect"
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

            # open sub-menu for selected network
            network_submenu "$SSID" "$SEC" "$SIG" "$INUSE"
            ;;
        "Exit")
            exit 0
            ;;
    esac
done
