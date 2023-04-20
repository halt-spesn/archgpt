#!/bin/bash

# Set keyboard layout
loadkeys us

# Update system clock
timedatectl set-ntp true

# Partition the disk (assumes one disk at /dev/sda)
echo -e "n\np\n1\n\n+50M\nn\np\n2\n\n\nw" | fdisk /dev/sda

# Format the partitions
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda2

# Mount the partitions
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Install Arch Linux base packages
pacstrap /mnt base base-devel linux linux-firmware

# Generate fstab file
genfstab -U /mnt >> /mnt/etc/fstab

# Change root into the new system
arch-chroot /mnt

# Set the time zone
ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
hwclock --systohc

# Uncomment en_US.UTF-8 UTF-8 in /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# Set the hostname
echo "archlinux" > /etc/hostname

# Set up network connection using NetworkManager
pacman -S networkmanager
systemctl enable NetworkManager

# Set up PulseAudio
pacman -S pulseaudio pulseaudio-alsa
systemctl --user enable pulseaudio

# Install and configure KDE desktop environment
pacman -S xorg-server plasma-meta kde-applications sddm
systemctl enable sddm

# Install bootloader
pacman -S grub
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Exit chroot and reboot
exit
umount -R /mnt
reboot
