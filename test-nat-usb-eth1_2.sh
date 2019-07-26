# testing traffic between two USB ether adapters: eth1 and eth2 
#

ifconfig $1 10.50.0.1 netmask 255.255.255.0 up
ifconfig $2 10.50.1.1 netmask 255.255.255.0 up

if1_mac_addr=`ifconfig $1 | grep HWaddr | awk '{print $5}'` 
if2_mac_addr=`ifconfig $2 | grep HWaddr | awk '{print $5}'`

# nat source IP 10.50.0.1 -> 10.60.0.1 when going to 10.60.1.1
iptables -t nat -A POSTROUTING -s 10.50.0.1 -d 10.60.1.1 -j SNAT --to-source 10.60.0.1
# nat inbound 10.60.0.1 -> 10.50.0.1
iptables -t nat -A PREROUTING -d 10.60.0.1 -j DNAT --to-destination 10.50.0.1
# nat source IP 10.50.1.1 -> 10.60.1.1 when going to 10.60.0.1
iptables -t nat -A POSTROUTING -s 10.50.1.1 -d 10.60.0.1 -j SNAT --to-source 10.60.1.1
# nat inbound 10.60.1.1 -> 10.50.1.1
iptables -t nat -A PREROUTING -d 10.60.1.1 -j DNAT --to-destination 10.50.1.1

#
ip route add 10.60.1.1 dev $1
arp -i $1 -s 10.60.1.1 $if2_mac_addr
# $2 mac address

ip route add 10.60.0.1 dev $2
arp -i $2 -s 10.60.0.1 $if1_mac_addr
# $1 mac address

