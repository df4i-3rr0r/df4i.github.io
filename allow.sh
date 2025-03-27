#Test
export DEBIAN_FRONTEND=noninteractive
MYIP1=$(wget -qO- ipv4.icanhazip.com);
NET=$(ip -o $ANU -4 route show to default | awk '{print $5}');
source /etc/os-release
ver=$VERSION_ID

iptables -F
iptables -X
ip6tables -F
ip6tables -X
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -s $MYIP1 -p tcp --dport 20203 -j ACCEPT
iptables -A INPUT -s $MYIP1 -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 20203 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -P INPUT DROP
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -p ipv6-icmp -j ACCEPT
ip6tables -P INPUT DROP
/sbin/iptables-save > /etc/iptables.up.rules
/sbin/iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

rm -rf /root/*
