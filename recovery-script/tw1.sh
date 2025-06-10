#Bash
#DynoLite Tweak

rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-DS0
nameserver 1.1.1.1
nameserver 1.0.0.1
DS0

opkg update

opkg install wget curl nano htop sudo

opkg remove *ddns* *wireguard* *openvpn* *sqm* *turboacc* --force-depends

rm -rf /etc/config/ddns

opkg update

opkg install luci-app-ddns openssh-sftp-server

cd /tmp
wget https://dnbiznet.github.io/recovery-script/luci-theme-neobird_1.99-202201272020_all.ipk
opkg install luci-theme-neobird_1.99-202201272020_all.ipk
rm -rf luci-theme-neobird_1.99-202201272020_all.ipk
cd

opkg update

wget -q https://raw.githubusercontent.com/dvh-patcher/system/refs/heads/main/passwall.sh
chmod +x passwall.sh
./passwall.sh

opkg update

wget -q https://raw.githubusercontent.com/dvh-patcher/system/refs/heads/main/speed.sh
chmod +x speed.sh
./speed.sh

rm -rf /tmp/resolv.conf*
rm -rf /tmp/resolv.conf.d
rm -rf /etc/resolv.conf.d
mkdir /etc/resolv.conf.d
rm -f /etc/resolv.conf.d/cf.conf
cat > /etc/resolv.conf.d/cf.conf <<-DS1
nameserver 1.1.1.1
nameserver 1.0.0.1
DS1
chmod +x /etc/resolv.conf.d/cf.conf

rm -rf /etc/sysctl.d/10-default.conf
cat > /etc/sysctl.d/10-default.conf <<-DF11
#Default By Dyno
kernel.panic=3
kernel.core_pattern=/tmp/%e.%t.%p.%s.core
fs.suid_dumpable=2

fs.protected_hardlinks = 1
fs.protected_symlinks = 1

net.core.bpf_jit_enable=1

net.ipv4.conf.default.arp_ignore=1
net.ipv4.conf.all.arp_ignore=1
net.ipv4.ip_forward=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.igmp_max_memberships=100
net.ipv4.tcp_fin_timeout=30
net.ipv4.tcp_keepalive_time=120
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_timestamps=1
net.ipv4.tcp_sack=1
net.ipv4.tcp_dsack=1

net.ipv6.conf.default.forwarding=1
net.ipv6.conf.all.forwarding=1

# disable bridge firewalling by default
net.bridge.bridge-nf-call-arptables=0
net.bridge.bridge-nf-call-ip6tables=0
net.bridge.bridge-nf-call-iptables=0

vm.overcommit_memory=0
vm.min_free_kbytes=16384
vm.vfs_cache_pressure=500
vm.swappiness=100
vm.dirty_background_ratio=1
vm.dirty_ratio=50
DF11

rm -rf /etc/sysctl.d/12-tcp-bbr.conf
cat > /etc/sysctl.d/99-bbr.conf <<-DS5
#Bbr Tweak By Dyno
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv6.conf.all.use_tempaddr=0
net.ipv6.conf.default.use_tempaddr=0
DS5

sysctl -p

uci set dhcp.@dnsmasq[0].resolvfile='/etc/resolv.conf.d/cf.conf'
uci commit dhcp

uci set qmodem_ttl.main.enable='1'
uci commit qmodem_ttl

rm -rf /root/*

reboot
