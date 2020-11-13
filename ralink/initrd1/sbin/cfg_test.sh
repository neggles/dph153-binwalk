#!/bin/sh

cnt=0
sector=0
mtu=1400
rst=

while [ 1 ]; do

	echo "#######################"
	echo "Start Config Test ....."
	echo "#######################"

	if [ $mtu -eq "1000" ]; then
		mtu=1300
	elif [ $mtu -eq "1300" ]; then
		mtu=1400
	else
		mtu=1000
	fi

	echo "#######################"
	echo "cs_client set wan/0/mtu $mtu"
	echo "cs_client commit"
	echo "#######################"
	cs_client set wan/0/mtu $mtu
	cs_client commit
	sleep 5

	if [ $sector -eq "0" ]; then
		sector=1
	else
		sector=0
	fi

	rst=`nvram show -c $sector | grep mtu | grep $mtu`
	if [ -z $rst ]; then
		echo "#####################"
		echo "The data in flash $sector is not match .. $rst $mtu ... Fail"
		echo "#####################"
		exit 0;
	fi
	echo "#####################"
	echo "The data in flash $sector is match $rst mtu=$mtu ... Pass"
	echo "#####################"

	echo "#######################"
	echo "killall config_server"
	echo "config_server"
	echo "#######################"
	killall config_server
	config_server
	sleep 5

	rst=`cs_client get wan/0/mtu`
	if [ $rst -ne $mtu ]; then
		echo "#####################"
		echo "value error in save/restore. rst=$rst mtu=$mtu ... Fail"
		echo "#####################"
		exit 0
	fi
	echo "#####################"
	echo "value in save/restore. rst=$rst mtu=$mtu  PASS "
	echo "#####################"

	echo "#####################"
	echo "cs_client restore all"
	echo "#####################"
	cs_client restore all
	sleep 5

	if [ $sector -eq "0" ]; then
		sector=1
	else
		sector=0
	fi

	rst=`nvram show -c $sector | grep mtu | grep 1500`
	if [ -z $rst ]; then
		echo "#####################"
		echo "After restore MTU not 1500 in flash.. break. sector:$sector FAIL"
		echo "#####################"
		exit 0;
	fi
	echo "#####################"
	echo "After restore MTU is 1500.... $rst $sector ... PASS "
	echo "#####################"

	echo "#######################"
	echo "killall config_server"
	echo "config_server"
	echo "#######################"
	killall config_server
	config_server
	sleep 5

	rst=`cs_client get wan/0/mtu`
	if [ $rst -ne "1500" ]; then
		echo "#####################"
		echo "After restore value error in save/restore. rst=$rst 1500 Fail"
		echo "#####################"
		exit 0
	fi
	echo "#####################"
	echo "After restore value in save/restore.. $rst ... PASS"
	echo "#####################"

	if [ $mtu -eq "1400" ]; then
		killall config_server
		flash -f 20000 -l 3ffff
		config_server
		sector=1
		sleep 5

	fi

done
