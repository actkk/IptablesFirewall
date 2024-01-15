#!/bin/bash
clear
# For editing the website you can change host_output
host_output=$(host www.google.com)
ip_address=$(echo "$host_output" | awk '/has address/ {print $4}')
pingtimes=5

echo "Client2 ping to firewall via 192.0.2.66 ip"
# Execute the ping command and capture the output
sudo ip netns exec client2 ping 192.0.2.66 -c $pingtimes


echo -e "\nClient1 ping to Server via 192.0.2.129"
sudo ip netns exec client1 ping 192.0.2.129 -c $pingtimes

echo -e "\nClient1 ping to $host_output via $ip_address"
sudo ip netns exec client1 ping $ip_address -c $pingtimes


echo -e "\nClient2 ping to $host_output via $ip_address"
sudo ip netns exec client2 ping $ip_address -c $pingtimes


echo -e "\nServer ping to $host_output via $ip_address"
sudo ip netns exec server ping $ip_address -c $pingtimes

echo -e "\nClient1 ping to firewall via 192.0.2.2"
sudo ip netns exec client1 ping 192.0.2.2 -c $pingtimes

#echo -e "\n Testing https service on port 4000"
#sudo ip netns exec server curl localhost:4000

