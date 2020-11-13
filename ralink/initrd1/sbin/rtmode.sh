#!/bin/sh

echo "change the op_mode to router mode"
cs_client set sys/op_mode 0

echo "cange IP and Netmask"
cs_client set lan/0/ip 192.168.157.185
cs_client set lan/0/netmask 255.255.255.252

cs_client commit


