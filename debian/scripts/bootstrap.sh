#!/usr/bin/env bash

#apt-get update
#takes a long time
#apt-get dist-upgrade -y

#apt-get install -y \
#	git \
#	build-essential devscripts ccache \
#	cmake qtbase5-dev libqt5webkit5-dev qtdeclarative5-dev qtscript5-dev qtmultimedia5-dev

#Install Vagrant ssh key
#mkdir /home/vagrant/.ssh
mkdir .ssh
#wget -O /home/vagrant/.ssh/authorized_keys 'https://github.com/mitchellh/vagrant/raw/master/keys/vagrant.pub'
wget -O .ssh/authorized_keys 'https://github.com/mitchellh/vagrant/raw/master/keys/vagrant.pub'
#chown -R vagrant /home/vagrant/.ssh
#chmod -R go-rwsx /home/vagrant/.ssh

# Set up sudo
#grep -q 'secure_path' /etc/sudoers || sed -i -e '/Defaults\s\+env_reset/a Defaults\tsecure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' /etc/sudoers
#sed -i -e 's/^%sudo.*/%sudo ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
echo 'vagrant ALL=NOPASSWD:ALL' > /etc/sudoers.d/vagrant

# Tweak sshd to prevent DNS resolution (speed up logins)
echo "UseDNS no" >> /etc/ssh/sshd_config
echo "GSSAPIAuthentication no" >> /etc/ssh/sshd_config

# Remove Grub timeout to speed up booting
sed -i 's/GRUB_TIMEOUT=[0-9]\{,2\}/GRUB_TIMEOUT=0/' /etc/default/grub

update-grub

# set up sbuild
mkdir /root/.gnupg # To work around #792100
rngd -r /dev/urandom #Fake entropy for the keygen; REMOVE if key security is important
sbuild-update --keygen #Requirement for sbuild
sbuild-adduser vagrant
mkdir vagrant/chroot
sbuild-createchroot --arch=i386 --make-sbuild-tarball=$HOME/chroot/stable-i386.tar.gz stable `mktemp -d` http://httpredir.debian.org/debian
