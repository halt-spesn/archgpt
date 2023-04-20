#!/bin/bash

# Set keyboard layout
loadkeys us

# Partition the disk with MBR
parted -a optimal /dev/sda mklabel msdos mkpart primary 1MiB 100% set 1 boot on

# Format the partition as ext4 and mount it
mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt/gentoo

# Download and extract the stage3 tarball
wget http://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64/stage3-amd64-$(date +%Y%m%dT%H%M%S).tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

# Set the Gentoo mirror and download the latest portage snapshot
mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
mkdir /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
emerge-webrsync

# Copy DNS information to the new system
cp -L /etc/resolv.conf /mnt/gentoo/etc/

# Mount necessary filesystems for the chroot environment
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

# Enter the chroot environment
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"

# Set the timezone
echo "Europe/London" > /etc/timezone
emerge --config sys-libs/timezone-data

# Set the system locale
echo "en_US ISO-8859-1" > /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set 5

# Update the system and install necessary packages
emerge --update --deep --newuse @world
emerge sys-kernel/gentoo-sources
emerge net-misc/networkmanager mate-base/mate-desktop pulseaudio


# Add necessary services to the default runlevel
rc-update add dbus default
rc-update add NetworkManager default
rc-update add pulseaudio default

# Install the bootloader (GRUB)
emerge sys-boot/grub:2
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Exit the chroot environment and unmount the filesystems
exit
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo

# Reboot the system
reboot
