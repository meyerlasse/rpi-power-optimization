#!/bin/bash
# Optimize power consumption on a Raspberry Pi 3

BOOT_CFG_FILE="/boot/config.txt"

# Test if script is run with sudo
if (( "$EUID" != 0 )); then
	printf "Needs to be run as root/with sudo!\n"
	exit 1
fi

# Disable Wifi, Bluetooth, Audio, I2C, I2S, SPI
ALLOFIT_DISABLE="dtoverlay=pi3-disable-wifi,pi3-disable-bt,audio=off,i2c=off,i2s=off,spi=off"
ALLOFIT_DISABLE_CMT="# Disable Wifi, Bluetooth, Audio, I2C, I2S, SPI"

sed -i "/$ALLOFIT_DISABLE/d" "$BOOT_CFG_FILE"
sed -i "/$ALLOFIT_DISABLE_CMT/d" "$BOOT_CFG_FILE"

echo "" >> "$BOOT_CFG_FILE"
echo "$ALLOFIT_DISABLE_CMT" >> "$BOOT_CFG_FILE"
echo "$ALLOFIT_DISABLE" >> "$BOOT_CFG_FILE"

# Disable HDMI
/opt/vc/bin/tvservice -o

# Disable USB & Ethernet
#echo '1-1' | tee /sys/bus/usb/drivers/usb/unbind

# Disable Power and Activity LEDs on Raspbian Buster
if ! service rpi3-disable-leds status; then
	cp ./rpi3-disable-leds.sh /usr/local/bin
	cp ./rpi3-disable-leds.service /etc/systemd/system
	systemctl enable rpi3-disable-leds.service
	service rpi3-disable-leds start
fi

# Disable Ethernet LEDs
ETH_DIS_CMD="lan951x-led-ctl"
ETH_DIS_SRV="rpi3-disable-ethleds.service"
if ! type "$ETH_DIS_CMD"; then
	apt-get --yes install make gcc git libusb-1.0-0 libusb-1.0-0-dev && \
	git clone https://github.com/meyerlasse/lan951x-led-ctl.git && \
	cd "$ETH_DIS_CMD" && \
	make && \
	cp "$ETH_DIS_CMD" /usr/local/bin && \
	cd .. && \
	rm -rf "./$ETH_DIS_CMD"
fi

"$ETH_DIS_CMD" --fdx=0 --lnk=0 --spd=0

wget https://gist.githubusercontent.com/meyerlasse/eb40e32e7a84de1e6a6c2cb99837d069/raw/a24b6cde2677859dbd00bea78abb71f67204d0a8/rpi3-disable-ethleds.service
mv "$ETH_DIS_SRV" /etc/systemd/system
systemctl enable "$ETH_DIS_SRV"
systemctl start "$ETH_DIS_SRV"

# Set Ethernet speed to 10 Mb/s

# Underclock CPU
# No energy saving if model 3 or higher --> ARM optimizations good enough

# Disable other unnecessary services & daemons
systemctl disable alsa-utils.service
service alsa-utils stop
systemctl disable avahi-daemon.service
service avahi-daemon stop
systemctl disable bluetooth.service
service bluetooth stop
systemctl disable display-manager.service
service display-manager stop
systemctl disable gldriver-test.service
service gldriver-test stop
systemctl disable keyboard-setup.service
service keyboard-setup stop
systemctl disable lightdm.service
service lightdm stop
systemctl disable rpi-display-backlight.service
service rpi-display-backlight stop

# Boot optimization
# - Add noarp to /etc/dhcpcd.conf
# - Turn off splash screen in /boot/cmdline.txt (remove splash, add quiet)
# - Set boot-delay to 0
