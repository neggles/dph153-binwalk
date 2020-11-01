#!/bin/bash
# VLAN setup script.
# Copyright (c) 2010 ip.access Ltd.
#
# Creates necessary VLAN devices and configuration to operate as a VLAN
# on the WAN port.
# Note: on Nano-8 the VLAN id must be used for the internal VLAN for the WAN port
#
# Usage:
#       setup_vlan.sh vlan_id
#

vlan_id="$1"

primary_if=eth0
RETVAL=1

#
# If an external VLAN is configured, set it up
#
if [ ${vlan_id:-"-1"} != "-1" ] && [ $vlan_id -ge 0 ] && [ $vlan_id -lt 4096 ]
then
    # Create vlan interface
    vconfig add eth0 $vlan_id

    # IP Forwarding is needed for VLANs
    echo 1 > /proc/sys/net/ipv4/ip_forward

    # Report back the network interface that udhcpc should use
    primary_if=eth0.$vlan_id

    RETVAL=0
fi

echo $primary_if

exit $RETVAL
