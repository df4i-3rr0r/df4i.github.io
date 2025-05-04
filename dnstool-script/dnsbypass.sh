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
apt -y update >/dev/null 2>&1

echo -e "[ ${BGreen}INFO${NC} ] Preparing the install file"
apt -y install dnsmasq bindutils >/dev/null 2>&1

echo -e "[ ${BGreen}INFO${NC} ] Creating dns bypass"
rm -rf /etc/dnsmasq.conf <<-DNS1 >/dev/null 2>&1
rm -rf /etc/dnsmasq.d/* <<-DNS1 >/dev/null 2>&1
cat > /etc/dnsmasq.conf <<-DNS1 >/dev/null 2>&1
##!/usr/bin/env bash
# General Settings
no-resolv
interface=eth0
interface=lo
server=1.1.1.1
############
# > Netflix
address=/netflix.com/124.217.246.148
address=/netflix.net/124.217.246.148
address=/nflximg.com/124.217.246.148
address=/nflxvideo.net/124.217.246.148
address=/nflxext.com/124.217.246.148

# > MEDIA-STREAM
address=/astro.com.my/124.217.246.148
address=/viu.com/124.217.246.148
address=/iq.com/124.217.246.148
address=/iqyi.com/124.217.246.148
address=/amazon.co.jp/124.217.246.148
address=/primevideo.com/124.217.246.148
address=/sooka.my/124.217.246.148
DNS1
chmod +x /etc/dnsmasq.conf >/dev/null 2>&1
systemctl enable dnsmasq >/dev/null 2>&1
systemctl start dnsmasq >/dev/null 2>&1



rm -rf /etc/resolv.conf >/dev/null 2>&1
cat > /etc/resolv.conf <<-RSV >/dev/null 2>&1
nameserver 127.0.0.1
RSV

echo -e "[ ${BGreen}INFO${NC} ] Finishing Installer"
sleep 5 >/dev/null 2>&1
rm -rf /root/dnsbypass.sh >/dev/null 2>&1

echo -e "[ ${BGreen}INFO${NC} ] Your Server Will Reboot Now"
reboot >/dev/null 2>&1

