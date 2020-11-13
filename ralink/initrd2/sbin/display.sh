#!/bin/sh

#!/bin/sh

file=/proc/qos/settings
if [ $1 ]; then
	file=$1
fi

while [ 1 ] 
do
	clear;
	cat $file
	sleep 1
done

