#!/bin/sh
#
#
# mgr_app 
#


. /etc/init.d/functions

PROG="ipa-mgr_app"
WDIR=/opt/ipaccess/MgrApp
DEFCFG=/opt/ipaccess/MgrApp/mgr_app_default.cfg
WRKCFGDIR=/var/ipaccess/config
CFGFILE=mgr_app.cfg
BKUPCFGFILE=mgr_app_bkup.cfg
WRKCFG=$WRKCFGDIR/$CFGFILE
WRKBKUPCFG=$WRKCFGDIR/$BKUPCFGFILE
BBMGRDEFCFG=/opt/ipaccess/MgrApp/baseband_mgr.cfg
BBMGRWRKCFG=/var/ipaccess/config/baseband_mgr.cfg
SECCTRLDEFCFG=/opt/ipaccess/MgrApp/security_ctrl_default.cfg
SECCTRLWRKCFG=/var/ipaccess/config/security_ctrl.cfg
NWLDEFCFG=/opt/ipaccess/MgrApp/nwl.cfg
NWLWRKCFG=/var/ipaccess/config/nwl.cfg
HWDESDEF=/var/ipaccess/factory_config/hw_description.dat
HWDESWRK=/var/ipaccess/hw_description.dat
DEFAPDIAGCFG=/opt/ipaccess/MgrApp/apdiag.cfg
WRKAPDIAGCFG=/var/ipaccess/config/apdiag.cfg
NTP_WDIR=/tmp/ntp
RETVAL=0
CMD_LINE_PARAMS=
GETVARVAL=/opt/ipaccess/Utils/scripts/getVarVal
SW_DESC=/etc/sw_description.dat
SWDBDAT=/var/ipaccess/sw_db.dat
SWDLCLIENT=/opt/ipaccess/bin/swdl_client

init()
{
    #Setup default config if working cfg is missing

    if [ ! -f $WRKCFG ]; then
        # The config dir is erased when a new s/w version is downloaded.
        # Try looking in the alternate bank for an old cfg file first.
        BANK=`fw_printenv -n bank`
        ALTCFGDIR=
        case $BANK in
            1) ALTCFGDIR=/var/ipaccess/config_bank_2 ;;
            2) ALTCFGDIR=/var/ipaccess/config_bank_1 ;;
        esac
        if [ -f "$ALTCFGDIR/$CFGFILE" ]; then
            cp  $ALTCFGDIR/$CFGFILE $WRKCFG
        fi
        if [ -f "$ALTCFGDIR/$BKUPCFGFILE" ]; then
            cp  $ALTCFGDIR/$BKUPCFGFILE $WRKBKUPCFG
        fi
        if [ -f $DEFCFG ] && [ ! -f $WRKCFG ]
        then
            cp  $DEFCFG $WRKCFG
        fi
    fi
    
    #Setup default apdiag config file 
    if [ -f $DEFAPDIAGCFG ] && [ ! -f $WRKAPDIAGCFG ]
    then
      cp -rf $DEFAPDIAGCFG $WRKAPDIAGCFG
    fi
  
    #Setup default IMSI list if working list is missing
    if [ -f $DEFIMSI ] && [ ! -f $WRKIMSI ]
    then
      cp -rf $DEFIMSI $WRKIMSI
    fi

    #Setup default baseband manager if working cfg is missing
    if [ -f $BBMGRDEFCFG ] && [ ! -f $BBMGRWRKCFG ]
    then
      cp -rf $BBMGRDEFCFG $BBMGRWRKCFG
    fi

    #Setup default security_ctrl if working cfg is missing
    if [ -f $SECCTRLDEFCFG ] && [ ! -f $SECCTRLWRKCFG ]
    then
      cp -rf $SECCTRLDEFCFG $SECCTRLWRKCFG
    fi

    if [ -f $NWLDEFCFG ] && [ ! -f $NWLWRKCFG ]
    then
      cp -rf $NWLDEFCFG $NWLWRKCFG
    fi

    if [ -e $HWDESWRK ]
    then
        if [ -h $HWDESWRK ]
        then
            rm $HWDESWRK;
            cp $HWDESDEF $HWDESWRK;
        fi
    else
        if [ -e $HWDESDEF ] 
        then
            cp $HWDESDEF $HWDESWRK;    
        fi
    fi

    # Ensure a copy of sw_sb.dat exists before it's accessed from mgr_app
    if [ ! -f $SWDBDAT ]
    then
      $SWDLCLIENT -recoverdb
    fi


    # Check /tmp/ntp/ directory exists before runningg MgrApp since NTPCtrl gets unhappy if not
    if [ ! -d $NTP_WDIR ]
    then
       mkdir $NTP_WDIR
    fi
    
    # See if IUH is to be enabled
    if [ -x /opt/ipaccess/Iapc/iapc.sh ]
    then
       CMD_LINE_PARAMS=" -i"
    fi
    
    # If it is a Factory Restore case
    if [ "$COMMISSIONING_MODE" = "1" ]
    then 
       CMD_LINE_PARAMS="$CMD_LINE_PARAMS -w"
    fi   
    #Start MgrApp
    PDIR=`pwd`
    cd $WDIR
    if [ "$OP_MODE" == "OP_DEVELOPER" ]
    then
       ./$PROG $CMD_LINE_PARAMS > /tmp/$PROG.txt 2>&1 &
    else
       ./$PROG $CMD_LINE_PARAMS &
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
    rm -rf $BBMGRWRKCFG
    rm -rf $SECCTRLWRKCFG
    rm -rf $WRKIMSI
    rm -rf $NWLWRKCFG
    rm -rf $WRKAPDIAGCFG
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
