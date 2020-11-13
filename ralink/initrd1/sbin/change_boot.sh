#!/bin/sh


check_ok=0
fw_swdirurl=
fw_name=
filename=
boot_loc=

check_swdirurl()
{
	status=`echo $fw_swdirurl | grep tftp`
	if [ $status ]; then
		echo "fw_swdirurl is ok"
		check_ok=1
	else
		echo "fw_swdirurl is bad"
		fw_name=`cs_client get sys/fw/$boot_loc/name`
		echo "fw_name is "$fw_name
		filename=`expr substr "$fw_name" 6 64`
		filename="tftp://192.168.157.186/"$filename
		echo "filename is "$filename
		check_ok=0
	fi
}

switch_boot_loc()
{
	fw_swdirurl=`cs_client get sys/fw/$boot_loc/swdirurl`
	echo "fw_swdirurl is "$fw_swdirurl
	check_swdirurl
	echo "check_ok is "$check_ok
	if [ $check_ok -eq 1 ]; then
		# If the sys/fw/$boot_loc/swdirurl did exist, it means the version information is good, we have to write to sys/swdirurl
		echo "cs_client set sys/swdirurl $fw_swdirurl"
		cs_client set sys/swdirurl $fw_swdirurl
	else
		# If the sys/fw/$boot_loc/swdirurl didn't exist, create it by using sys/fw/$boot_loc/name
		echo "cs_client set sys/swdirurl $filename"
		cs_client set sys/swdirurl $filename
	fi
	cfg_flash -s -n boot_loc -v $boot_loc
	cs_client set sys/boot_loc $boot_loc
}

value=`cfg_flash -r -n boot_loc`
echo "#### Current boot_loc is $value ####"
if [ $value == "0" ]; then
	boot_loc=1
else
	boot_loc=0
fi

switch_boot_loc

cs_client commit 

sleep 1

# Perry: Mark this to avoid system reboot
#killall -SIGUSR1 gpio_task

