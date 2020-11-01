#!/bin/sh
#
#
# dmi
#


. /etc/init.d/functions

PROG="ipa-dmi"
WDIR=/opt/ipaccess/DMI
DEFCFG=
WRKCFG=
DEFIMSI=
WRKIMSI=
RETVAL=0

init()
{
    #Setup default config if working cfg is missing
    if [ -f $DEFCFG ] && [ ! -f $WRKCFG ]
    then
      cp -rf $DEFCFG $WRKCFG
    fi

    #Setup default IMSI list if working list is missing
    if [ -f $DEFIMSI ] && [ ! -f $WRKIMSI ]
    then
      cp -rf $DEFIMSI $WRKIMSI
    fi

    #Start DMI
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
    #restore default configuration
    if [ -f $DEFCFG ]
    then
      cp -rf $DEFCFG $WRKCFG
    fi

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
