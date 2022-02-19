#!/bin/bash

mkdir -p /etc/docker
mkdir -p /etc/systemd/system
mkdir -p /etc/tmpfiles.d
mkdir -p /etc/sudoers.d

cp etc/docker/daemon.json /etc/docker/
cp etc/systemd/system/azure-tmpdirs.service /etc/systemd/system/
cp etc/tmpfiles.d/local-storage.conf /etc/tmpfiles.d/
cp etc/sudoers.d/91-jenkins /etc/sudoers.d

apt-get update
apt-get install -y docker.io openjdk-11-jre-headless lbzip2 gnupg2

ln -sf /bin/bash /bin/sh

groups=docker,sudo
if [ -e /dev/kvm ]; then
  groups+=,kvm
fi
useradd -s /bin/bash -G $groups -m jenkins

systemctl daemon-reload
systemctl enable --now azure-tmpdirs

grep -q ^ClientAliveInterval /etc/ssh/sshd_config || echo "ClientAliveInterval 15" >>/etc/ssh/sshd_config
systemctl restart ssh

(
umask 0077
mkdir /home/jenkins/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM01lDv4oYESG5ObKybpmcje1B3aC2hqW1Ie4jKrT2Mf jenkins' >/home/jenkins/.ssh/authorized_keys
chown jenkins:jenkins -R /home/jenkins/.ssh
)

echo "SSH HOST KEY:"
cat /etc/ssh/ssh_host_rsa_key.pub
