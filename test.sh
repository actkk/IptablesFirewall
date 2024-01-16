#!/bin/bash
clear
# For editing the website, you can change host_output
host_output=$(host www.google.com)
ip_address=$(echo "$host_output" | awk '/has address/ {print $4}')
pingtimes=5


echo  "Client1 ping to Server via 192.0.2.130"
sudo ip netns exec client1 ping 192.0.2.130 -c $pingtimes
echo -e "\nTraceroute"
sudo ip netns exec client1 traceroute 192.0.2.130

echo -e "\n\n\nClient2 accessing server for HTTP"
sudo ip netns exec client2 curl http://192.0.2.130


echo -e "\n\n\nClient2 ping to firewall via 192.0.2.65 ip"
sudo ip netns exec client2 ping 192.0.2.65 -c $pingtimes

echo -e "\n\n\nClient1 ping to firewall via 192.0.2.1"
sudo ip netns exec client1 ping 192.0.2.1 -c $pingtimes



echo -e "\n\n\nClient1 ping to $host_output via $ip_address"
sudo ip netns exec client1 ping $ip_address -c $pingtimes

echo -e "\n\n\nClient2 ping to $host_output via $ip_address"
sudo ip netns exec client2 ping $ip_address -c $pingtimes

echo -e "\n\n\nServer ping to $host_output via $ip_address"
sudo ip netns exec server ping $ip_address -c $pingtimes



echo -e "\n firwall iptables rules"
sudo ip netns exec  firewall iptables -L

