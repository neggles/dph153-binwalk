#!/bin/sh

# Perry:
#	Used to download firmware from tftp site.
#	Please make sure that you can ping to host.

firmware=image_1.0.20
tftp_site=192.168.110.199
ping_rst=0
reboot=1

# Return:
#	1:	can't ping
#	0:	can ping
ping_detect() 
{
	ping_act=`ping -c 1 $tftp_site | grep "Destination Host Unreachable"`

	if [ "$ping_act" ]; then
		ping_rst=1
	else
		ping_rst=0
	fi  
}

if [ $1 ]; then
	firmware=$1
fi

if [ $2 ]; then 
	tftp_site=$2
fi

if [ $3 ]; then 
	reboot=$3
fi

echo "Prepare to download firmware";
echo "Usage: upgrade_fw.sh firmware tftp_site reboot"
echo "If go given parameters, use default value"
echo "firmware=$firmware"
echo "tftp_site=$tftp_site"
echo "reboot=$reboot"

ping_detect

if [ $ping_rst -eq 0 ]; then
	cd /tmp
	echo "Trying to download firmware $firmware from $tftp_site"
#	tftp -g -r $firmware $tftp_site
#	echo "Trying to write firmware into mtd"
#	if [ $reboot -eq 1 ]; then
#		fw_tool -r -f $firmware 
#	else
#		fw_tool -f $firmware
#	fi
	rmm_client 192.168.157.185 do_software_download tftp://$tftp_site/$firmware
	echo "Download firmware complete"
#	rm $firmware
else
	echo "Can't ping to tftp server. Please make sure the connection setting"
fi

