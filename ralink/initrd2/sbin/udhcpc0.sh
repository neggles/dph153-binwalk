#!/bin/sh

# udhcpc script edited by Tim Riker <Tim@Rikers.org>

wan_index=0
count=0

[ -z "$1" ] && echo "[DHCPC$wan_index]: Error: should be called from udhcpc" && exit 1

RESOLV_CONF="/etc/resolv.conf"
[ -n "$broadcast" ] && BROADCAST="broadcast $broadcast"
[ -n "$subnet" ] && NETMASK="netmask $subnet"

case "$1" in
    deconfig)
		echo "[DHCPC$wan_index]: execute "$1
		# since we release the IP, flash the LED
		# switch reg w b4 a
        cs_client set wan/$wan_index/ip 0.0.0.0 > /dev/null
        cs_client set wan/$wan_index/netmask 0.0.0.0 > /dev/null
        cs_client set wan/$wan_index/gateway/num 0 > /dev/null
        cs_client set wan/$wan_index/gateway/0/ip 0.0.0.0 > /dev/null
        cs_client set wan/$wan_index/dns/num 0 > /dev/null
        cs_client set wan/$wan_index/dns/0/ip 0.0.0.0 > /dev/null

		# Clear dhcpc IP address
		cs_client set dhcpc/$wan_index/opt/serverid 0.0.0.0 > /dev/null
        ;;

	renew)
		echo "[DHCPC$wan_index]: Renew IP address $ip"
		;;

    bound)
		echo "[DHCPC$wan_index]: execute "$1
		# since we got the IP, steady on the LED
		#switch reg w b4 c
		echo dhcp=1 > /proc/eth_led_settings
        cs_client set wan/$wan_index/ip $ip > /dev/null
        cs_client set wan/$wan_index/netmask $subnet > /dev/null

		if [ -n "$serverid" ] ; then 
			cs_client set dhcpc/$wan_index/opt/serverid $serverid > /dev/null
		else
			cs_client set dhcpc/$wan_index/opt/serverid "" > /dev/null
		fi

		if [ -n "$domain" ] ; then 
			cs_client set dhcpc/$wan_index/opt/domain $domain > /dev/null
		else
			cs_client set dhcpc/$wan_index/opt/domain "" > /dev/null
		fi

		if [ -n "$lease" ] ; then
			cs_client set dhcpc/$wan_index/opt/lease $lease > /dev/null
		else
			cs_client set dhcpc/$wan_index/opt/lease "" > /dev/null
		fi

		if [ -n "$mtu" ] ; then
			cs_client set dhcpc/$wan_index/opt/mtu $mtu > /dev/null
		else
			cs_client set dhcpc/$wan_index/opt/mtu "" > /dev/null
		fi
	
		if [ -n "$wins" ] ; then
			cs_client set dhcpc/$wan_index/opt/wins $wins > /dev/null
		else
			cs_client set dhcpc/$wan_index/opt/wins "" > /dev/null
		fi

		if [ -n "$all_opts" ] ; then
			cs_client set dhcpc/$wan_index/options $all_opts > /dev/null
		else
			cs_client set dhcpc/$wan_index/options "" > /dev/null
		fi

		if [ -n "$all_file" ] ; then
			cs_client set dhcpc/$wan_index/boot_file $all_file > /dev/null
		else
			cs_client set dhcpc/$wan_index/boot_file "00" > /dev/null
		fi

		if [ -n "$all_sname" ] ; then
			cs_client set dhcpc/$wan_index/sname $all_sname > /dev/null
		else
			cs_client set dhcpc/$wan_index/sname "00" > /dev/null
		fi


        if [ -n "$router" ] ; then
            echo "[DHCPC$wan_index]: deleting routers"
            metric=0
			count=0
            for i in $router ; do
                metric=`expr $metric + 1`
				cs_client set wan/$wan_index/gateway/$count/ip $i > /dev/null
				cs_client set wan/$wan_index/gateway/$count/metric $metric > /dev/null
				count=`expr $count + 1`
            done
			cs_client set wan/$wan_index/gateway/num $count > /dev/null
        fi

        echo -n > $RESOLV_CONF
        [ -n "$domain" ] && echo search $domain >> $RESOLV_CONF
		count=0
        for i in $dns ; do
            echo "[DHCPC$wan_index]: adding dns "$i
            echo nameserver $i >> $RESOLV_CONF
			cs_client set wan/$wan_index/dns/$count/ip $i > /dev/null
			count=`expr $count + 1`
        done
		cs_client set wan/$wan_index/dns/num $count > /dev/null
		cs_client reconf wan > /dev/null
		# Perry: to let pico boot
		# gpio_task -b
        ;;
esac

exit 0

