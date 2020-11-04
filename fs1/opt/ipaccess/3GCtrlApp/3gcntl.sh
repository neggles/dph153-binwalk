#!/bin/sh
#
#
# 3gcntrlapp
#


. /etc/init.d/functions

export CNTRL_APP_PORT_FILE=/var/ipaccess/3gcntrl.cfg
export TRACE_FILE=/tmp/cntrl_trace
export RRC_ASN_TRACE_FILE=/tmp/asn_trace

PROG="3gcntrlapp.exe"
WDIR=/opt/ipaccess/3GCtrlApp
DEFCFG=/opt/ipaccess/3GCtrlApp/3gcntrl_default.cfg
WRKCFG=/var/ipaccess/config/3gcntrl.cfg
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
       nice --10 ./$PROG >/tmp/$PROG.txt 2>&1 &
    else
       nice --10 ./$PROG &
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
    echo -n "Stopping $PROG: "
    kill -9 `pidof -o $$ -o $PPID -o %PPID $PROG` >/dev/null 2>&1
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
