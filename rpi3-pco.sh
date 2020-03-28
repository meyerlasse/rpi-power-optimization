#!/bin/bash
# Optimize power consumption on a Raspberry Pi 3

BOOT_CFG_FILE="/boot/config.txt"

# Test if script is run with sudo
if (( "$EUID" != 0 )); then
	printf "Needs to be run as root/with sudo!\n"
	exit 1
fi

# Disable HDMI
/opt/vc/bin/tvservice -o

# Disable Wi-Fi
WIFI_DISABLE="dtoverlay=pi3-disable-wifi"
WIFI_DISABLE_CMT="# Disable Wifi"

systemctl disable raspberrypi-net-mods.service
systemctl disable wifi-country.service
systemctl disable wpa_supplicant.service

sed -i "/$WIFI_DISABLE/d" "$BOOT_CFG_FILE"
sed -i "/$WIFI_DISABLE_CMT/d" "$BOOT_CFG_FILE"

echo "" >> "$BOOT_CFG_FILE"
echo "$WIFI_DISABLE_CMT" >> "$BOOT_CFG_FILE"
echo "$WIFI_DISABLE" >> "$BOOT_CFG_FILE"

# Disable Bluetooth
BT_DISABLE="dtoverlay=pi3-disable-bt"
BT_DISABLE_CMT="# Disable Bluetooth"

systemctl disable bluetooth.service
systemctl disable hciuart.service

sed -i "/$BT_DISABLE/d" "$BOOT_CFG_FILE"
sed -i "/$BT_DISABLE_CMT/d" "$BOOT_CFG_FILE"

echo "" >> "$BOOT_CFG_FILE"
echo "$BT_DISABLE_CMT" >> "$BOOT_CFG_FILE"
echo "$BT_DISABLE" >> "$BOOT_CFG_FILE"

# Disable USB & Ethernet
#echo '1-1' | tee /sys/bus/usb/drivers/usb/unbind

# Disable Activity LED
LEDACT_DISABLE_1="dtparam=act_led_trigger"
LEDACT_DISABLE_2="dtparam=act_led_activelow"
LEDACT_DISABLE_CMT="# Disable Activity LED"

sed -i "/$LEDACT_DISABLE_1/d" "$BOOT_CFG_FILE"
sed -i "/$LEDACT_DISABLE_2/d" "$BOOT_CFG_FILE"
sed -i "/$LEDACT_DISABLE_CMT/d" "$BOOT_CFG_FILE"

echo "" >> "$BOOT_CFG_FILE"
echo "$LEDACT_DISABLE_CMT" >> "$BOOT_CFG_FILE"
echo "$LEDACT_DISABLE_1=none" >> "$BOOT_CFG_FILE"
echo "$LEDACT_DISABLE_2=off" >> "$BOOT_CFG_FILE"

# Disable Power LED
LEDPWR_DISABLE_1="dtparam=pwr_led_trigger"
LEDPWR_DISABLE_2="dtparam=pwr_led_activelow"
LEDPWR_DISABLE_CMT="# Disable Power LED"

sed -i "/$LEDPWR_DISABLE_1/d" "$BOOT_CFG_FILE"
sed -i "/$LEDPWR_DISABLE_2/d" "$BOOT_CFG_FILE"
sed -i "/$LEDPWR_DISABLE_CMT/d" "$BOOT_CFG_FILE"

echo "" >> "$BOOT_CFG_FILE"
echo "$LEDPWR_DISABLE_CMT" >> "$BOOT_CFG_FILE"
echo "$LEDPWR_DISABLE_1=none" >> "$BOOT_CFG_FILE"
echo "$LEDPWR_DISABLE_2=off" >> "$BOOT_CFG_FILE"

# Disable Ethernet LEDs
ETH_DIS_CMD="lan951x-led-ctl"
ETH_DIS_SRV="pi3-disable-ethleds.service"
if ! type "$ETH_DIS_CMD"; then
	apt-get install make gcc git libusb-1.0-0 libusb-1.0-0-dev && \
	git clone https://github.com/meyerlasse/lan951x-led-ctl.git && \
	cd "$ETH_DIS_CMD" && \
	make && \
	cp "$ETH_DIS_CMD" /usr/local/bin && \
	cd .. && \
	rm -rf "./$ETH_DIS_CMD"
fi

"$ETH_DIS_CMD" --fdx=0 --lnk=0 --spd=0

wget https://gist.githubusercontent.com/meyerlasse/a1ef2258ac2567c8ddb0670bc3d4f62c/raw/59e98ac3feab8a62deb45aea3fae11470c4191a0/pi3-disable-ethleds.service
mv "$ETH_DIS_SRV" /etc/systemd/system
systemctl enable "$ETH_DIS_SRV"
systemctl start "$ETH_DIS_SRV"

# Disable audio
AUDIO_DISABLE="dtparam=audio"
AUDIO_DISABLE_CMT="# Disable audio (snd_bcm2835)"

sed -i "/$AUDIO_DISABLE/d" "$BOOT_CFG_FILE"
sed -i "/$AUDIO_DISABLE_CMT/d" "$BOOT_CFG_FILE"

echo "" >> "$BOOT_CFG_FILE"
echo "$AUDIO_DISABLE_CMT" >> "$BOOT_CFG_FILE"
echo "$AUDIO_DISABLE=off" >> "$BOOT_CFG_FILE"

# Underclock CPU

# Disable other unnecessary services & daemons
systemctl disable avahi-daemon.service
systemctl disable display-manager.service
systemctl disable gldriver-test.service
systemctl disable keyboard-setup.service
systemctl disable lightdm.service
systemctl disable rpi-display-backlight.service
systemctl disable triggerhappy.service
systemctl disable triggerhappy.socket

# Boot optimization
# - Add noarp to /etc/dhcpcd.conf
# - Turn off splash screen in /boot/cmdline.txt (quiet splash)