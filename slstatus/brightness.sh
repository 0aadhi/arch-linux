#!/bin/sh
BL=$(ls /sys/class/backlight | head -n1)
cur=$(cat /sys/class/backlight/$BL/brightness)
max=$(cat /sys/class/backlight/$BL/max_brightness)
echo $((cur * 100 / max))%

