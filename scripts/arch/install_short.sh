#!/bin/bash

# Format the partitions
mkfs.btrfs /dev/sda

# Mount the partitions
mount /dev/sda /mnt

# Set the mirror
echo 'Server = http://archlinux.mirror.kangaroot.net/$repo/os/$arch' > /etc/pacman.d/mirrorlist

# Install the base system
/usr/bin/pacstrap /mnt base sudo syslinux openssh virtualbox-guest-modules-arch virtualbox-guest-utils-nox puppet

# Generate the fstab
/usr/bin/genfstab -U /mnt > /mnt/etc/fstab

# Set the locale
/usr/bin/echo 'en_US.UTF-8 UTF-8' > /mnt/etc/locale.gen
/usr/bin/echo '/usr/bin/locale-gen' | /usr/bin/arch-chroot /mnt /bin/bash

# Setup time
/usr/bin/echo 'hwclock --systohc --utc' | /usr/bin/arch-chroot /mnt /bin/bash

# Setup hostname
/usr/bin/echo "arch-hostname" > /mnt/etc/hostname

# Add lvm2 hook to HOOKS in /etc/mkinitcpio.conf
/usr/bin/sed -i 's/^HOOKS=.*/HOOKS=\(base systemd autodetect modconf block filesystems keyboard\)/g' /mnt/etc/mkinitcpio.conf
/usr/bin/echo 'mkinitcpio -p linux' | arch-chroot /mnt /bin/bash

# Generate syslinux
/usr/bin/syslinux-install_update -i -a -m -c /mnt/

# Configure syslinux
uuid=$( /usr/bin/blkid -s UUID -o value /dev/sda )
/usr/bin/sed -i "s/APPEND root=.*/APPEND root=UUID=$uuid/g" /mnt/boot/syslinux/syslinux.cfg
/usr/bin/sed -i "s/TIMEOUT 50/TIMEOUT 10/g" /mnt/boot/syslinux/syslinux.cfg

# Create the vagrant user
echo 'Create the vagrant user'
echo 'useradd -U -G wheel -m -s /bin/bash vagrant' | arch-chroot /mnt /bin/bash
echo "echo 'vagrant:vagrant' | chpasswd" | arch-chroot /mnt /bin/bash

# Add the ssh key
echo 'Add the ssh key'
mkdir /mnt/home/vagrant/.ssh
echo 'vagrant  ALL=(ALL) NOPASSWD: ALL' >> /mnt/etc/sudoers
wget --no-check-certificate -O authorized_keys 'https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub' -q
mv authorized_keys /mnt/home/vagrant/.ssh/
chown -R vagrant:vagrant /mnt/home/vagrant/.ssh
chmod -R go-rwsx /mnt/home/vagrant/.ssh

# Needed for nfs
#echo 'Enable rpcbind.socket'
#systemctl --root /mnt enable rpcbind.socket

# Networking
echo 'Setup networking'
mkdir -p /mnt/etc/systemd/network
cat << EOF > /mnt/etc/systemd/network/99-dhcp.network
[Match]

[Network]
DHCP=both
LinkLocalAddressing=yes
LLDP=yes
LLMNR=yes
EOF

systemctl --root /mnt enable systemd-networkd

systemctl --root /mnt enable systemd-resolved
rm /mnt/etc/resolv.conf
ln -s /run/systemd/resolve/resolv.conf /mnt/etc/resolv.conf

# Enable the vboxservice
systemctl --root /mnt enable vboxservice

# Enable sshd
echo 'Enable sshd'
sed -i 's/#UseDNS yes/UseDNS no/' /mnt/etc/ssh/sshd_config
systemctl --root /mnt enable sshd

# Setup puppet
#echo 'Setup puppet'
#mkdir -p /etc/puppet/{hiera,manifests,modules}

## Get yaourt
#echo 'Setup yaourt'
#pacman -S git
#get_yaourt_setup='/mnt/home/vagrant/get_yaourt.sh'
#get_yaourt='/home/vagrant/get_yaourt.sh'
#
#cat << EOFyaourt > $get_yaourt_setup
#sudo pacman -S git --noconfirm
#git clone https://aur.archlinux.org/package-query.git
#cd package-query
#makepkg --noconfirm --noprogressbar -s &>/dev/null
#sudo pacman -U package-query-*.pkg.tar.xz --noconfirm
#cd ..
#rm package-query -rf
#
#git clone https://aur.archlinux.org/yaourt.git
#cd yaourt
#makepkg --noconfirm --noprogressbar -s &>/dev/null
#sudo pacman -U yaourt-*.pkg.tar.xz --noconfirm
#cd ..
#rm yaourt -rf
#EOFyaourt
#
## Add the permissions
#chmod 0755 $get_yaourt
#
## Execute as non-root user
#/usr/bin/echo "su - vagrant $get_yaourt" | arch-chroot /mnt /bin/bash
#
## Clean up the script
#rm $get_yaourt_setup

umount -R /mnt
exit 0
