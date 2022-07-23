#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	# install-to-emmc node_number
	if [[ $BUILD_DESKTOP == yes ]]; then
		echo "sed -i 's/node_number=/node_number=4096/g' $SDCARD/root/install-to-emmc.sh"
		sed -i 's/node_number=/node_number=4096/g' $SDCARD/root/install-to-emmc.sh
	else
		echo "sed -i 's/node_number=/node_number=1024/g' $SDCARD/root/install-to-emmc.sh"
		sed -i 's/node_number=/node_number=1024/g' $SDCARD/root/install-to-emmc.sh
	fi
	# timezone
	timedatectl set-timezone "Asia/Shanghai"
	timedatectl
	# fonts-noto-cjk
	apt install -y fonts-noto-cjk
	# docker
	curl -fsSL https://get.docker.com | sh -

} # Main

Main "$@"
