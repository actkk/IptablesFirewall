#!/bin/bash

# Namespace'leri oluştur
sudo ip netns add client1
sudo ip netns add client2
sudo ip netns add server
sudo ip netns add firewall

# veth arayüzlerini oluştur ve bağla
sudo ip link add vfc1 type veth peer name vc1f
sudo ip link add vfc2 type veth peer name vc2f
sudo ip link add vfs type veth peer name vsf
sudo ip link add vfh type veth peer name vhf

# bağlantılar
sudo ip link set vfc1 netns firewall
sudo ip link set vfc2 netns firewall
sudo ip link set vfs netns firewall
sudo ip link set vfh netns firewall
sudo ip link set vc1f netns client1
sudo ip link set vc2f netns client2
sudo ip link set vsf netns server

# up
sudo ip netns exec firewall ip link set dev vfc1 up
sudo ip netns exec firewall ip link set dev vfc2 up
sudo ip netns exec firewall ip link set dev vfs up
sudo ip netns exec firewall ip link set dev vfh up
sudo ip netns exec client1 ip link set dev vc1f up
sudo ip netns exec client2 ip link set dev vc2f up
sudo ip netns exec server ip link set dev vsf up
sudo ip link set dev vhf up

#loopback
sudo ip netns exec  firewall ip link set dev lo up
sudo ip netns exec client1 ip link set dev lo up
sudo ip netns exec client2 ip link set dev lo up
sudo ip netns exec server ip link set dev lo up

# 192.0.2.0/26 subnet  => aralık [192.0.2.0 , 192.0.2.63]
# IP adreslerini ata
sudo ip netns exec firewall ip addr add 192.0.2.2/26 dev vfc1
sudo ip netns exec client1 ip addr add 192.0.2.1/26 dev vc1f
sudo ip netns exec firewall ip addr add 192.0.2.66/26 dev vfc2
sudo ip netns exec client2 ip addr add 192.0.2.65/26 dev vc2f
sudo ip netns exec firewall ip addr add 192.0.2.130/26 dev vfs
sudo ip netns exec server ip addr add 192.0.2.129/26 dev vsf
sudo ip netns exec firewall ip addr add 192.0.2.194/26 dev vfh
sudo ip addr add 192.0.2.193/26 dev vhf


sudo ip netns exec client1 ip route add default via 192.0.2.2
sudo ip netns exec client2 ip route add default via 192.0.2.66
sudo ip netns exec server ip route add default via 192.0.2.130

#ip yönlendirmesi
sudo ip netns exec firewall sysctl -w net.ipv4.ip_forward=1

sudo route add -net 192.0.2.0 netmask 255.255.255.0 gw 192.0.2.194
sudo iptables -t nat -A POSTROUTING -s 192.0.2.0/24  -j MASQUERADE
sudo ip netns exec firewall ip route add default via 192.0.2.193 dev vfh

#http service
#sudo ip netns exec server python3 -m http.server 80

#iptable rules
#drop
sudo iptables --policy FORWARD ACCEPT # docker automatically drops that if installed

sudo ip netns exec firewall iptables --policy INPUT DROP
sudo ip netns exec firewall iptables --policy OUTPUT DROP
sudo ip netns exec firewall iptables --policy FORWARD DROP

sudo ip netns exec firewall iptables -A OUTPUT -p icmp -j ACCEPT
sudo ip netns exec firewall iptables -A OUTPUT -p tcp -j ACCEPT

sudo ip netns exec firewall iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo ip netns exec firewall iptables -I INPUT -p icmp -s 192.0.2.64/26 -d 192.0.2.64/26 -j ACCEPT

sudo ip netns exec firewall iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo ip netns exec firewall iptables -I FORWARD -p icmp -s 192.0.2.0/26 -d 192.0.2.128/26 -j ACCEPT
sudo ip netns exec firewall iptables -I FORWARD -p icmp -s 192.0.2.0/26 -d 192.0.2.192/26 -j ACCEPT
sudo ip netns exec firewall iptables -I FORWARD -p icmp -s 192.0.2.64/26 -d 192.0.2.192/26 -j ACCEPT
sudo ip netns exec firewall iptables -I FORWARD -p icmp -s 192.0.2.128/26 -d 192.0.2.192/26 -j ACCEPT

sudo ip netns exec firewall iptables -I FORWARD -p tcp --dport 80 -s 192.0.2.64/26 -d 192.0.2.128/26 -j ACCEPT
sudo ip netns exec firewall iptables -I FORWARD -p tcp --dport 80 -s 192.0.2.0/26 -d 192.0.2.192/26 -j ACCEPT
sudo ip netns exec firewall iptables -I FORWARD -p tcp --dport 80 -s 192.0.2.64/26 -d 192.0.2.192/26 -j ACCEPT
sudo ip netns exec firewall iptables -I FORWARD -p tcp --dport 80 -s 192.0.2.128/26 -d 192.0.2.192/26 -j ACCEPT

sudo ip netns exec firewall iptables -I FORWARD -p icmp ! -d 192.0.0.0/8 -j ACCEPT
sudo ip netns exec firewall iptables -I FORWARD -p tcp ! -d 192.0.0.0/8  --dport 80 -j ACCEPT

