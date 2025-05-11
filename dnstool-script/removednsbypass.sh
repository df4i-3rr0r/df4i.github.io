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
apt update -y
apt install sudo -y

echo -e "[ ${BGreen}INFO${NC} ] Preparing the remove package dns"
sudo apt autoremove --purge dnsmasq dnsmasq-* bindutils -y > /dev/null 2>&1

echo -e "[ ${BGreen}INFO${NC} ] Setting Back Public Dns"
rm -rf /etc/dnsmasq.d/*
rm -rf /etc/dnsmasq.conf > /dev/null 2>&1

rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-RSV
nameserver 1.1.1.1
nameserver 1.0.0.1
RSV

echo -e "[ ${BGreen}INFO${NC} ] Finishing Removing"
sleep 5 > /dev/null 2>&1
rm -rf /root/removednsbypass.sh > /dev/null 2>&1

echo -e "[ ${BGreen}INFO${NC} ] Your Server Will Reboot Now"
reboot > /dev/null 2>&1

