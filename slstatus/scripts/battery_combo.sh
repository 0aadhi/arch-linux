#!/bin/sh

BAT0="/sys/class/power_supply/BAT0"
BAT1="/sys/class/power_supply/BAT1"

cap0=$(cat "$BAT0/capacity" 2>/dev/null || echo 0)
cap1=$(cat "$BAT1/capacity" 2>/dev/null || echo 0)

total=$((cap0 + cap1))

stat0=$(cat "$BAT0/status" 2>/dev/null)
stat1=$(cat "$BAT1/status" 2>/dev/null)

# determine active battery
if [ "$stat0" = "Discharging" ]; then
    active="BAT0"
elif [ "$stat1" = "Discharging" ]; then
    active="BAT1"
else
    active="AC"
fi

# charging state symbol
if [ "$stat0" = "Charging" ] || [ "$stat1" = "Charging" ]; then
    state="+"
elif [ "$stat0" = "Discharging" ] || [ "$stat1" = "Discharging" ]; then
    state="-"
else
    state="="
fi

printf "%d%%(%s)%s" "$total" "$active" "$state"
