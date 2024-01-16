#!/bin/bash

# Namespaces
sudo ip netns add client1
sudo ip netns add client2
sudo ip netns add server
sudo ip netns add firewall

# Setting veth
sudo ip link add vfc1 type veth peer name vc1f
sudo ip link add vfc2 type veth peer name vc2f
sudo ip link add vfs type veth peer name vsf
sudo ip link add vfh type veth peer name vhf

# Connection
sudo ip link set vfc1 netns firewall
sudo ip link set vfc2 netns firewall
sudo ip link set vfs netns firewall
sudo ip link set vfh netns firewall
sudo ip link set vc1f netns client1
sudo ip link set vc2f netns client2
sudo ip link set vsf netns server

# interface activation
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

# 192.0.2.0/26 subnet  =>  [192.0.2.0 , 192.0.2.63]
# IP
sudo ip netns exec firewall ip addr add 192.0.2.1/26 dev vfc1
sudo ip netns exec client1 ip addr add 192.0.2.2/26 dev vc1f
sudo ip netns exec firewall ip addr add 192.0.2.65/26 dev vfc2
sudo ip netns exec client2 ip addr add 192.0.2.66/26 dev vc2f
sudo ip netns exec firewall ip addr add 192.0.2.129/26 dev vfs
sudo ip netns exec server ip addr add 192.0.2.130/26 dev vsf
sudo ip netns exec firewall ip addr add 192.0.2.193/26 dev vfh
sudo ip addr add 192.0.2.194/26 dev vhf


sudo ip netns exec client1 ip route add default via 192.0.2.1
sudo ip netns exec client2 ip route add default via 192.0.2.65
sudo ip netns exec server ip route add default via 192.0.2.129

#ip forward
sudo ip netns exec firewall sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv4.ip_forward=1

sudo route add -net 192.0.2.0 netmask 255.255.255.0 gw 192.0.2.193
sudo iptables -t nat -A POSTROUTING -s 192.0.2.0/24  -j MASQUERADE
sudo ip netns exec firewall ip route add default via 192.0.2.194 dev vfh


#iptable rules
#drop
sudo iptables --policy FORWARD ACCEPT  # Docker rule

sudo ip netns exec firewall iptables --policy INPUT DROP
sudo ip netns exec firewall iptables --policy OUTPUT DROP
sudo ip netns exec firewall iptables --policy FORWARD DROP

# Allow ping from client2
sudo ip netns exec firewall iptables -A INPUT -p icmp -s 192.0.2.66/32 -i vfc2 -j ACCEPT

#tcp
#sudo ip netns exec firewall iptables -I FORWARD -p tcp --dport 80 -s 192.0.2.0/26 -d 192.0.2.192/26 -j ACCEPT
#sudo ip netns exec firewall iptables -I FORWARD -p tcp --dport 80 -s 192.0.2.64/26 -d 192.0.2.192/26 -j ACCEPT
#sudo ip netns exec firewall iptables -I FORWARD -p tcp --dport 80 -s 192.0.2.128/26 -d 192.0.2.192/26 -j ACCEPT
sudo ip netns exec firewall iptables -I FORWARD -p tcp --dport 80 -s 192.0.2.0/24 -d 192.0.2.192/26 -j ACCEPT


# Block ping from client1,
sudo ip netns exec firewall iptables -A INPUT -p icmp -s 192.0.2.2/32 -i vfc1 -j DROP


# Allow ICMP forwarding for client1 and client2:
sudo ip netns exec firewall iptables -A FORWARD -p icmp -s 192.0.2.2/32 -i vfc1 -j ACCEPT
sudo ip netns exec firewall iptables -A FORWARD -p icmp -s 192.0.2.66/32 -i vfc2 -j ACCEPT

# Allow forwarding for internet access:
sudo ip netns exec firewall iptables -A FORWARD -s 192.0.2.0/26 -i vfc1 -j ACCEPT
sudo ip netns exec firewall iptables -A FORWARD -s 192.0.2.64/26 -i vfc2 -j ACCEPT
sudo ip netns exec firewall iptables -A FORWARD -s 192.0.2.128/26 -i vfs -j ACCEPT

sudo ip netns exec firewall iptables -A FORWARD -o vfc1 -d 192.0.2.0/26 -j ACCEPT
sudo ip netns exec firewall iptables -A FORWARD -o vfc2 -d 192.0.2.64/26 -j ACCEPT
sudo ip netns exec firewall iptables -A FORWARD -o vfs -d 192.0.2.128/26 -j ACCEPT


# Allow established/related connections:
sudo ip netns exec firewall iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow ping to firewall
sudo ip netns exec firewall iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#http service
sudo ip netns exec server python3 -m http.server 80
