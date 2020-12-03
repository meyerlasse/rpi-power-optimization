#!/bin/bash
# Disable all LEDs on a Raspberry Pi 3

# Disable Ethernet LEDs
lan951x-led-ctl --fdx=0 --lnk=0 --spd=0

echo none > /sys/class/leds/led0/trigger
echo 0 > /sys/class/leds/led0/brightness

echo none > /sys/class/leds/led1/trigger
echo 0 > /sys/class/leds/led1/brightness
