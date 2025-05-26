#bash
#dyno tweak

rm -rf /etc/resolv.conf
cat > /etc/resolv.conf <<-RSV
nameserver 1.1.1.1
nameserver 1.0.0.1
RSV

cat > /etc/sysctl.d/99-tweak.conf <<-SYSCT
net.core.default_qdisc=fq
SYSCT
chmod +x /etc/sysctl.d/99-tweak.conf

opkg update
opkg remove --autoremove *turboacc* *openvpn* *sqm* *wireguard* --force-depends

opkg commit

uci delete network.lan.dns
uci set network.wwan0.peerdns='0'
uci delete network.wwan0.dns
uci commit network

uci set dhcp.@dnsmasq[0].domainneeded='0'
uci set dhcp.@dnsmasq[0].nonwildcard='0'
uci set dhcp.@dnsmasq[0].boguspriv='0'
uci delete dhcp.@dnsmasq[0].local
uci delete dhcp.@dnsmasq[0].domain
uci set dhcp.@dnsmasq[0].expandhosts='0'
uci set dhcp.@dnsmasq[0].resolvfile='/etc/resolv.conf'
uci commit dhcp

rm -rf /root/*
reboot
