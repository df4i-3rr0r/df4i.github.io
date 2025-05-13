#!/bin/bash

red='\e[1;31m'
green='\e[0;32m'
yell='\e[1;33m'
tyblue='\e[1;36m'
BRed='\e[1;31m'
BGreen='\e[1;32m'
BYellow='\e[1;33m'
BBlue='\e[1;34m'
NC='\e[0m'
purple() { echo -e "\\033[35;1m${*}\\033[0m"; }
tyblue() { echo -e "\\033[36;1m${*}\\033[0m"; }
yellow() { echo -e "\\033[33;1m${*}\\033[0m"; }
green() { echo -e "\\033[32;1m${*}\\033[0m"; }
red() { echo -e "\\033[31;1m${*}\\033[0m"; }

echo -e "[ ${BGreen}INFO${NC} ] Get update first"
apt update -y > /dev/null 2>&1
apt install sudo -y > /dev/null 2>&1

echo -e "[ ${BGreen}INFO${NC} ] Preparing the install file"
systemctl disable systemd-resolved > /dev/null 2>&1

rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-RSV
nameserver 1.1.1.1
nameserver 1.0.0.1
RSV

sudo apt install dnsmasq dnsutils -y > /dev/null 2>&1

echo -e "[ ${BGreen}INFO${NC} ] Creating dns bypass"
rm -rf /etc/dnsmasq.d/*
rm -rf /etc/dnsmasq.conf > /dev/null 2>&1
cat > /etc/dnsmasq.conf <<-DNS1
##!/usr/bin/env bash
# General Settings
no-hosts
no-resolv
all-servers
interface=eth0
local-ttl=60
server=1.0.0.1
server=1.1.1.1
############
# > MAIN BLOCK
address=/fast.com/0.0.0.0
address=/playstation.com/0.0.0.0

# > NETFLIX/HOTSTAR/PRIME
address=/hotstar.com/124.217.246.148
address=/amazon.co.jp/124.217.246.148
address=/primevideo.com/124.217.246.148
address=/netflix.com/124.217.246.148
address=/netflix.net/124.217.246.148
address=/nflximg.com/124.217.246.148
address=/nflxvideo.net/124.217.246.148
address=/nflxext.com/124.217.246.148

# > XTRO/YOUTUBE
address=/astro.com.my/124.217.246.148
address=/youtube.com/124.217.246.148

# > DRAMA-BYPASS
address=/viu.com/124.217.246.148
address=/iq.com/124.217.246.148
address=/iqyi.com/124.217.246.148
address=/sooka.my/124.217.246.148

# > BANK/GOV-SITE
address=/affinalways.com/124.217.246.148
address=/affinagroup.com/124.217.246.148
address=/rhbgroup.com/124.217.246.148
address=/bankislam.com/124.217.246.148
address=/bankislam.biz/124.217.246.14
address=/hongleongconnect.my/124.217.246.148
address=/pbebank.com/124.217.246.148
address=/maybank2e.com/124.217.246.148
address=/aeonbank.com.my/124.217.246.148
address=/cimbocto.com.my/124.217.246.148
address=/mae.com.my/124.217.246.148
address=/maybank2u.com.my/124.217.246.148
address=/cimbclicks.com.my/124.217.246.148
address=/bankrakyat.com.my/124.217.246.148
address=/irakyat.com.my/124.217.246.148
DNS1
chmod +x /etc/dnsmasq.conf
systemctl enable dnsmasq > /dev/null 2>&1
systemctl start dnsmasq > /dev/null 2>&1

rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-RSV
nameserver 127.0.0.1
RSV

echo -e "[ ${BGreen}INFO${NC} ] Finishing Installer"
sleep 5 > /dev/null 2>&1
rm -f /root/dnsbypass.sh > /dev/null 2>&1

echo -e "[ ${BGreen}INFO${NC} ] Your Server Will Reboot Now"
reboot > /dev/null 2>&1

