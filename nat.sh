#!/bin/bash
# script.sh

ifconfig h3-eth0:1 192.168.1.100 netmask 255.255.255.0 up
arp -s 192.168.1.1 00:00:00:00:00:01
route add -host 192.168.1.1 dev h3-eth0
