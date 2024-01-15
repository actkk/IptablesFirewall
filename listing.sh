#!/bin/bash
clear
echo "listing namespaces"
ip netns list

echo -e "\nlisting veths"
ip link show
echo -e "\nfirewall ip link"
sudo ip netns exec firewall ip link show
