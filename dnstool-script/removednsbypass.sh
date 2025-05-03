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
apt -y autoremove --purge dnsmasq bindutils >/dev/null 2>&1

echo -e "[ ${BGreen}INFO${NC} ] Creating dns bypass"
rm -rf /etc/dnsmasq.conf  2>&1

rm -rf /etc/resolv.conf 2>&1
cat > /etc/resolv.conf <<-RSV 2>&1
nameserver 1.1.1.1
nameserver 1.0.0.1
RSV

echo -e "[ ${BGreen}INFO${NC} ] Finishing Installer"
sleep 5 2>&1
rm -rf /root/* 2>&1

echo -e "[ ${BGreen}INFO${NC} ] Your Server Will Reboot Now"
reboot 2>&1

