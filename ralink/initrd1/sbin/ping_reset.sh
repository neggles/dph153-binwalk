#!/bin/sh

# Perry:
#	Used to download firmware from tftp site.
#	Please make sure that you can ping to host.

ping_site=192.168.157.186
ping_rst=0

# Return:
#	1:	can't ping
#	0:	can ping
ping_detect() 
{
	ping_act=`ping -c 1 $ping_site | grep "1 packets received"`

	if [ "$ping_act" ]; then
		ping_rst=1
	else
		ping_rst=0
	fi  
}

if [ $1 ]; then 
	ping_site=$1
fi

#echo "Usage: ping_reset.sh ping_site"
#echo "ping_site=$ping_site"

while [ $ping_rst -eq 0 ]
do
	echo "[GPIO_TASK] Trying to ping $ping_site"
	ping_detect
	sleep 2
done

echo "[GPIO_TASK] clear restore_default bit and commit"
cs_client set sys/restore_default 0 
cs_client commit
