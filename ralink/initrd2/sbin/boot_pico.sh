#!/bin/sh

#!/bin/sh

ping_rst=0;
ping_site=192.168.157.186

ping_detect() 
{
	ping_act=`ping -c 1 $ping_site | grep "1 packets received"`

	if [ "$ping_act" ]; then
		ping_rst=1
	else
		ping_rst=0
	fi  
}

echo ""
echo ""
echo ""
echo "######### Start to boot Pico ########"
echo ""
echo ""
echo ""
gpio_task -b

#while [ $ping_rst -eq 0 ] 
#do
#	echo "Trying to ping $ping_site ..."
#	ping_detect
#	sleep 1
#done

#echo ""
#echo ""
#echo ""
#echo "######### Change GPIO6 to Tristate ########"
#echo ""
#echo ""
#echo ""
#gpio_task -p

