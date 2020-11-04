#!/bin/sh
#
#
# iapc.sh
#


. /etc/init.d/functions

PROG="iapc"
WDIR=/opt/ipaccess/Iapc
LOGDIR=/tmp/iapclogs
RETVAL=0

init()
{
    # Check /tmp/iapclog/ directory exists before running the app
    if [ ! -d $LOGDIR ]
    then
        mkdir $LOGDIR
    fi

    #Start the app
    cd $WDIR
    nice -n -10 ./$PROG &
}

start() {
    echo -n "Starting $PROG: "
    is_app_running $PROG
    if [ $? != $TRUE ]; then
        init
        RETVAL=$?
        if [ $RETVAL -eq 0 ]; then
            echo OK
        else
            echo FAILURE
        fi
    else
        echo "FAILURE (already running)"
    fi
}

stop() {
    echo -n "Stopping $PROG: "
    kill -SIGTERM `pidof -o $$ -o $PPID -o %PPID $PROG` >/dev/null 2>&1
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        echo OK
    else
        echo FAILURE
    fi
}

restart() {
    stop
    start
    RETVAL=$?
}

reset()
{
    #delete configuration from /var/ipacces so on next start, init will copy it over
    rm -rf $WRKCFG
    rm -rf $WRKBKUPCFG
}

# processing of command line
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    reset)
        reset
        ;;
    restart|reload)
        restart
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac

exit $RETVAL
