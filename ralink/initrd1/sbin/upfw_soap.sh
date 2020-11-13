#!/bin/sh

# Perry:
#	Used to download firmware from tftp site.
#	Please make sure that you can ping to host.

firmware=root_uImage
tftp_site=192.1.1.33

#Perry: Default setting should be fail condition.
ping_rst=1		
tftp_rst=1

# Return:
#	1:	can't ping
#	0:	can ping
ping_detect() 
{
	ping_act=`ping -c 1 $tftp_site | grep "100% packet loss"`

	if [ "$ping_act" ]; then
		echo "$ping_act"
		cs_client set sys/fw_status ErrorServer
		ping_rst=1
	else
		ping_act=`ping -c 1 $tftp_site | grep "Destination Host Unreachable"`
		if [ "$ping_act" ]; then
	        echo "ping_act = $ping_act"
			cs_client set sys/fw_status ErrorServer
	        ping_rst=1
		else		
			ping_rst=0
		fi
	fi  
}

do_tftp()
{
	cd /tmp	
	tftp_act=`tftp -g -r $firmware $tftp_site | grep "tftp:"`
	if [ "$tftp_act" ]; then
		echo "$tftp_act"
		cs_client set sys/fw_status ErrorFileNotFound
		tftp_rst=1
	else
		tftp_rst=0
	fi
}

upfw_start()
{
	cs_client set sys/fw_status InProgress
}

do_fw()
{
	fw_act=`fw_tool -f /tmp/$firmware | grep "wrong"`
	if [ "$fw_act" ]; then
		echo "firmware write error."
		cs_client set sys/fw_status ErrorImageCorrupted
	else
		echo "firmware write successfully."
		cs_client set sys/fw_status Completed
	fi
	rm /tmp/$firmware
}

if [ $1 ]; then
	firmware=$1
fi

if [ $2 ]; then 
	tftp_site=$2
fi

echo "Prepare to download firmware";
echo "Usage: upfw_soap.sh firmware tftp_site reboot"
echo "If no given parameters, use default value"
echo "firmware=$firmware"
echo "tftp_site=$tftp_site"

upfw_start
ping_detect

if [ $ping_rst -eq 0 ]; then
	echo "Trying to download firmware $firmware from $tftp_site"
	do_tftp
	if [ $tftp_rst -eq 0 ]; then
		echo "tftp complete"
		do_fw
	else
		echo "tftp error"
	fi
else
	echo "Can't ping to tftp server. Please make sure the connection setting"
fi

