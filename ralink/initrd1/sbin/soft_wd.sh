#!/bin/sh

restart_cs()
{
	echo "Restart config_server..."
	rm -f /var/run/cs.pid
	killall config_server
	config_server
}

trap 'restart_cs' SIGUSR1

while [ 1 ]
do
	#keep sleeping util receive signal.
	sleep 3
done
