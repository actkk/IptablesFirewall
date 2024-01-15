#!/bin/bash
sudo ip netns delete client1
sudo ip netns delete client2
sudo ip netns delete server
sudo ip netns delete firewall
rule_numbers=$(sudo iptables -t nat --line-numbers -L POSTROUTING | awk '/MASQUERADE/ {print $1}')
for rule_number in $rule_numbers; do
  sudo iptables -t nat -D POSTROUTING $rule_number
done