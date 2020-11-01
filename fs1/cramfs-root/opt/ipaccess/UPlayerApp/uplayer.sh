#!/bin/sh
#
# uplayerapp
#


. /etc/init.d/functions

PROG="uplayerapp"
WDIR=/opt/ipaccess/UPlayerApp
DEFCFG=/opt/ipaccess/UPlayerApp/uplayerapp_default.cfg
WRKCFG=/var/ipaccess/config/uplayerapp.cfg
RETVAL=0

init()
{
    #Setup default config if working cfg is missing
    if [ -f $DEFCFG ] && [ ! -f $WRKCFG ]
    then
      cp -rf $DEFCFG $WRKCFG
    fi

    PDIR=`pwd`
    cd $WDIR
    if [ "$OP_MODE" = "OP_DEVELOPER" ]
    then
       ./$PROG >/tmp/$PROG.txt 2>&1 &
    else
        ./$PROG &
    fi
    cd $PDIR
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
    echo -n "Stopping (SIGTERM) $PROG: "
    kill -15 `pidof -o $$ -o $PPID -o %PPID $PROG` >/dev/null 2>&1
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        echo OK
    else
        echo FAILURE
    fi
    # hang about for a bit to allow UPlayerApp to die gracefully
    sleep 1
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
