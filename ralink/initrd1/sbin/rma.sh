#!/bin/sh

echo "change the op_mode to Bridge mode"
cs_client set sys/op_mode 2

echo "Change IP and Netmask to 192.168.1.20/24"
cs_client set lan/0/ip 192.168.1.20
cs_client set lan/0/netmask 255.255.255.0

cs_client commit

