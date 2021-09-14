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
apt-get install -y docker.io openjdk-11-jre-headless

ln -sf /bin/bash /bin/sh

groups=docker,sudo
if [ -e /dev/kvm ]; then
  groups+=,kvm
fi
useradd -s /bin/bash -G $groups -m jenkins

systemctl daemon-reload
systemctl enable --now azure-tmpdirs
