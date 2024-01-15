## Iptables With Firewall
This project is a Intern project you can find more information at :
https://github.com/fatihusta/intern-projects/tree/main/create-an-iptables-firewall


* Create 4 network namespaces.
* Namespaces are client1, client2, server, firewall
* Create veth for all namespaces and your host-to-firewall for network communication.
* Serve sample http service inside the server namespace
* Create Iptables rules inside the firewall namespace and control traffic between the namespaces.
   
### Rules

        Client1 can ping to server
        Client2 can access to server for http
        Client2 can ping to firewall
        Client1 doesn't have ping permission to firewall
        Client and server networks are can be access to the internet from firewall namespace via your host machine.

### Notes

    Client1 subnetwork is 192.0.2.0/26
    Client2 subnetwork is 192.0.2.64/26
    Server subnetwork is 192.0.2.128/26
    Host-To-Firewall Subnetwork is 192.0.2.192/26
    Firewall should be a stateful.
### Topology
```
                   ┌─────────────┐
                   │             │
                   │   Internet  │
                   │             │
                   └──────┬──────┘
                          │
                          │
                          │
               ┌──────────┴──────────┐
               │                     │
               │        HOST         │
               │                     │
               └──────────┬──────────┘
                          │
                          │
                          │
                 ┌────────┴────────┐
                 │                 │
                 │    Firewall     ├───────┐
      ┌──────────┤                 │       │
      │          └───┬─────────────┘       │
      │              │                     │
      │              │                     │
      │              │                  ┌──┴───┐
      │              │                  │      │
      │              │                  │      │
┌─────┴────┐   ┌─────┴────┐             │Server│
│          │   │          │             │      │
│  Client1 │   │ Client2  │             │      │
│          │   │          │             │      │
└──────────┘   └──────────┘             └──────┘
```

## Explaning app.sh
### Creating namespaces and connecting 
#### Set up the namespcaes

    sudo ip netns add client1
    sudo ip netns add client2
    sudo ip netns add server
    sudo ip netns add firewall
#### Set up the veth and connect them
Creating veths

    sudo ip link add vfc1 type veth peer name vc1f
    sudo ip link add vfc2 type veth peer name vc2f
    sudo ip link add vfs type veth peer name vsf
    sudo ip link add vfh type veth peer name vhf
Connecting 

    sudo ip link set vfc1 netns firewall
    sudo ip link set vfc2 netns firewall
    sudo ip link set vfs netns firewall
    sudo ip link set vfh netns firewall
    sudo ip link set vc1f netns client1
    sudo ip link set vc2f netns client2
    sudo ip link set vsf netns server

Now all the veths are connected client1 client2 and server is connected to firewall.

#### Setting veth up

    sudo ip netns exec firewall ip link set dev vfc1 up
    sudo ip netns exec firewall ip link set dev vfc2 up
    sudo ip netns exec firewall ip link set dev vfs up
    sudo ip netns exec firewall ip link set dev vfh up
    sudo ip netns exec client1 ip link set dev vc1f up
    sudo ip netns exec client2 ip link set dev vc2f up
    sudo ip netns exec server ip link set dev vsf up
    sudo ip link set dev vhf up

#### Loopback connections
    
    sudo ip netns exec  firewall ip link set dev lo up
    sudo ip netns exec client1 ip link set dev lo up
    sudo ip netns exec client2 ip link set dev lo up
    sudo ip netns exec server ip link set dev lo up


#### Ip adrress

In notes there are subnets for ip we can calculate range like this :

192.0.2.0/26 subnet  =>  [192.0.2.0 , 192.0.2.63]

    sudo ip netns exec firewall ip addr add 192.0.2.2/26 dev vfc1
    sudo ip netns exec client1 ip addr add 192.0.2.1/26 dev vc1f
    sudo ip netns exec firewall ip addr add 192.0.2.66/26 dev vfc2
    sudo ip netns exec client2 ip addr add 192.0.2.65/26 dev vc2f
    sudo ip netns exec firewall ip addr add 192.0.2.130/26 dev vfs
    sudo ip netns exec server ip addr add 192.0.2.129/26 dev vsf
    sudo ip netns exec firewall ip addr add 192.0.2.194/26 dev vfh
    sudo ip addr add 192.0.2.193/26 dev vhf

#### Setting default routes
    
    sudo ip netns exec client1 ip route add default via 192.0.2.2
    sudo ip netns exec client2 ip route add default via 192.0.2.66
    sudo ip netns exec server ip route add default via 192.0.2.130

#### Host connections and connecting to Internet
    
    sudo ip netns exec firewall sysctl -w net.ipv4.ip_forward=1
    
    
    sudo route add -net 192.0.2.0 netmask 255.255.255.0 gw 192.0.2.194
    sudo iptables -t nat -A POSTROUTING -s 192.0.2.0/24  -j MASQUERADE
    sudo ip netns exec firewall ip route add default via 192.0.2.193 dev vfh

#### Serving https services in server

    sudo ip netns exec server python3 -m http.server 4000


#### Iptable rules

Before setting Iptable rules with need the drop all the rules
        
    sudo ip netns exec firewall iptables --policy INPUT DROP
    sudo ip netns exec firewall iptables --policy OUTPUT DROP
    sudo ip netns exec firewall iptables --policy FORWARD DROP
    
Rules

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
## Contents
app.sh is the main file for run this :

    ./app.sh

test.sh file for testing your connections you can edit the link for testing. For run this file you can type :

    ./test.sh

remove.sh removes all the namespcaes and Iptable rules. Before running app.sh second time you must remove all the rules for running you can type :

    ./remove.sh

listing.sh lists all namepspaces and veths connected to firewall. For run this file you can type :

    ./listing.sh

### For more information to understand namespaces and Iptables you can check this links
* https://itnext.io/create-your-own-network-namespace-90aaebc745d
* https://medium.com/techlog/diving-into-linux-networking-and-docker-bridge-veth-and-iptables-a05eb27b1e72
* https://wiki.archlinux.org/title/simple_stateful_firewall

It's always good to read man pages

* https://man7.org/linux/man-pages/man7/network_namespaces.7.html
* https://man7.org/linux/man-pages/man8/iptables.8.html