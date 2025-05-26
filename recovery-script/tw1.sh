#Bash
#DynoMinimTweak

rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-DS0
nameserver 1.1.1.1
nameserver 1.0.0.1
DS0

mkdir /etc/resolv.conf.d
rm -rf /etc/resolv.conf.d/cf.conf
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
DS5
sysctl -p

opkg remove --autoremove *ddns* *wireguard* *openvpn* *sqm* *turboacc* --force-depends

rm -rf /etc/ddns/*

opkg install luci-app-ddns

cd /tmp
wget https://dnbiznet.github.io/recovery-script/luci-theme-neobird_1.99-202201272020_all.ipk
opkg install luci-theme-neobird_1.99-202201272020_all.ipk
rm -rf luci-theme-neobird_1.99-202201272020_all.ipk
cd

uci set dhcp.@dnsmasq[0].noresolv='0'
uci set dhcp.@dnsmasq[0].domainneeded='0'
uci set dhcp.@dnsmasq[0].nonwildcard='0'
uci set dhcp.@dnsmasq[0].boguspriv='0'
uci set dhcp.@dnsmasq[0].expandhosts='0'
uci delete dhcp.@dnsmasq[0].local
uci delete dhcp.@dnsmasq[0].domain
uci set dhcp.@dnsmasq[0].resolvfile='/etc/resolv.conf.d/cf.conf'
uci commit dhcp

uci set network.wwan0.peerdns='0'
uci delete network.wwan0.dns
uci commit network
uci commit

uci set qmodem_ttl.main.enable='1'
uci commit qmodem_ttl

reboot
