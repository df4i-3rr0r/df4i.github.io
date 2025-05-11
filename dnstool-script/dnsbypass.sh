#!/bin/bash
#Script By Dyno

systemctl disable systemd-resolved

rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-RSV
nameserver 1.1.1.1
nameserver 1.0.0.1
RSV

echo -e "Get update first"
apt-get update -y

apt-get install sudo -y

echo -e "Preparing the install file"
sudo apt-get install dnsmasq bindutils -y

echo -e "Creating dns bypass"
rm -rf /etc/dnsmasq.d/*
rm -rf /etc/dnsmasq.conf
cat > /etc/dnsmasq.conf <<-DNS1
##!/usr/bin/env bash
# General Settings
no-resolv
all-servers
interface=eth0
interface=lo
server=1.0.0.1
server=1.1.1.1
############
# > MAIN BLOCK
address=/fast.com/0.0.0.0
address=/playstation.com/0.0.0.0

# > NETFLIX/HOTSTAR/PRIME
address=/amazon.co.jp/124.217.246.148
address=/primevideo.com/124.217.246.148
address=/netflix.com/124.217.246.148
address=/netflix.net/124.217.246.148
address=/nflximg.com/124.217.246.148
address=/nflxvideo.net/124.217.246.148
address=/nflxext.com/124.217.246.148

# > XTRO
address=/astro.com.my/124.217.246.148

# > DRAMA-BYPASS
address=/viu.com/124.217.246.148
address=/iq.com/124.217.246.148
address=/iqyi.com/124.217.246.148
address=/sooka.my/124.217.246.148
DNS1
chmod +x /etc/dnsmasq.conf
systemctl enable dnsmasq

rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-RSV
nameserver 127.0.0.1
RSV

echo -e "Finishing Installer"
sleep 5

rm -rf /root/dnsbypass.sh

echo -e "Your Server Will Reboot Now"
reboot

