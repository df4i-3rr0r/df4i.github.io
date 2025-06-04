#Bash
#DynoLite Tweak

rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-DS0
nameserver 1.1.1.1
nameserver 1.0.0.1
DS0

opkg update

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

rm -rf /etc/sysctl.d/12-tcp-bbr.conf
cat > /etc/sysctl.d/99-bbr.conf <<-DS5
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv6.conf.all.use_tempaddr=0
net.ipv6.conf.default.use_tempaddr=0
DS5
sysctl -p

opkg update

opkg remove *ddns* *wireguard* *openvpn* *chinadns* *sqm* *turboacc* --force-depends

rm -rf /etc/init.d/ipsec
rm -rf /etc/config/ddns

opkg install luci-app-ddns openssh-sftp-server nano htop curl wget

cd /tmp
wget https://dnbiznet.github.io/recovery-script/luci-theme-neobird_1.99-202201272020_all.ipk
opkg install luci-theme-neobird_1.99-202201272020_all.ipk
rm -rf luci-theme-neobird_1.99-202201272020_all.ipk
cd

wget -q https://raw.githubusercontent.com/dvh-patcher/system/refs/heads/main/speed.sh
chmod +x speed.sh
./speed.sh

uci set dhcp.@dnsmasq[0].resolvfile='/etc/resolv.conf.d/cf.conf'
uci commit dhcp

uci set qmodem_ttl.main.enable='1'
uci commit qmodem_ttl

rm -rf /root/*
reboot
