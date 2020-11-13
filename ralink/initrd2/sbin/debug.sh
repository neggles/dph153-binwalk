#!/bin/sh

# Perry:
#	Used to download firmware from tftp site.
#	Please make sure that you can ping to host.

tool=
tftp_site=192.168.15.200
ping_rst=0
execute=0

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
	tool=$1
fi

if [ $2 ]; then 
	tftp_site=$2
fi

if [ $3 ]; then 
	execute=$3
elif [ -e /tmp/execute ]; then
	execute=1
fi


echo "Prepare to download software";
echo "Usage: debug.sh tool_name tftp_site execute"
echo "If go given parameters, use default value"
echo "tool=$tool"
echo "tftp_site=$tftp_site"
echo "execute=$execute"

ping_detect

if [ $ping_rst -eq 0 ]; then
	cd /tmp
	echo "Trying to download tool $tool from $tftp_site"
	tftp -g -r $tool $tftp_site
	chmod +x $tool
	if [ $execute -eq 1 ]; then
		echo "Killing current running progress & restart it again"
		killall $tool
		./$tool
	fi
else
	echo "Can't ping to tftp server. Please make sure the connection setting"
fi

