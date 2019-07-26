#!/bin/bash

# nat source IP 10.50.0.1 -> 10.60.0.1 when going to 10.60.1.1
sudo iptables -t nat -A POSTROUTING -s 10.50.0.1 -d 10.60.1.1 -j SNAT --to-source 10.60.0.1
# nat inbound 10.60.0.1 -> 10.50.0.1
sudo iptables -t nat -A PREROUTING -d 10.60.0.1 -j DNAT --to-destination 10.50.0.1
# nat source IP 10.50.1.1 -> 10.60.1.1 when going to 10.60.0.1
sudo iptables -t nat -A POSTROUTING -s 10.50.1.1 -d 10.60.0.1 -j SNAT --to-source 10.60.1.1
# nat inbound 10.60.1.1 -> 10.50.1.1
sudo iptables -t nat -A PREROUTING -d 10.60.1.1 -j DNAT --to-destination 10.50.1.1

#
sudo ip route add 10.60.1.1 dev eth3
sudo arp -i eth3 -s 10.60.1.1 00:1B:21:13:B1:89
# eth4's mac address

sudo ip route add 10.60.0.1 dev eth4
sudo arp -i eth4 -s 10.60.0.1 00:1B:21:13:B1:8D
# eth3's mac address

