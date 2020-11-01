#!/bin/sh
#
#
# rrm
#


. /etc/init.d/functions

PROG="ipa-rrm"
WDIR=/opt/ipaccess/RRM
DEFCFG=/opt/ipaccess/RRM/rrm_default.cfg
WRKCFG=/var/ipaccess/config/rrm.cfg
DEFIMSI=/opt/ipaccess/RRM/imsi_default.cfg
WRKIMSI=/var/ipaccess/config/imsi.cfg
CDR_FLASH_PATH="/var/ipaccess/logs/cdr"
CDR_TMP_PATH="/tmp/cdr"
CDR_FILENAME="cdrlog"
HO_FLASH_PATH="/var/ipaccess/logs/ho"
HO_TMP_PATH="/tmp/ho"
HO_FILENAME="holog"
RETVAL=0
RESDEFCFG=/opt/ipaccess/RRM/rrm_resources_default.cfg
RESWRKCFG=/var/ipaccess/config/rrm_resources.cfg

copyLogFileAtShutdown()
{
    FLASHPATH=$1
    TEMPPATH=$2
    FILE=$3

    #Copy active log file from /tmp to flash
    if [ -f "$TEMPPATH/$FILE" ]; then
        cp $TEMPPATH/$FILE $FLASHPATH
    fi

    #Remove .backup file
    if [ -f "$FLASHPATH/$FILE.backup" ]; then
        rm -f $FLASHPATH/$FILE.backup
    fi
}

copyLogFileAtStartup()
{
    FLASHPATH=$1
    TEMPPATH=$2
    FILE=$3
    
    #Copy active file from flash to /tmp
    #Make sure format of timestamp matches with code
    if [ -f "$FLASHPATH/$FILE" ]; then
        echo "`date +"%a %b %d %Y %T"`, Restart detected, restoring last active logs" >> $FLASHPATH/$FILE
        cp $FLASHPATH/$FILE $TEMPPATH
        rm -f $FLASHPATH/$FILE.backup 2>/dev/null
        mv $FLASHPATH/$FILE $FLASHPATH/$FILE.backup
    elif [ -f "$FLASHPATH/$FILE.backup" ]; then
        echo "`date +"%a %b %d %Y %T"`, Restart detected after power outage, restoring last active log from backup" >> $FLASHPATH/$FILE.backup
        cp $FLASHPATH/$FILE.backup $TEMPPATH/$FILE
    else
        echo "`date +"%a %b %d %Y %T"`, Restart detected, no previous active log detected, new log started" > $TEMPPATH/$FILE
    fi
}

initLogFiles()
{
    # Ensure cdr dir exists in /tmp
    [ -d $CDR_TMP_PATH ] || mkdir $CDR_TMP_PATH

    # Ensure cdr dir exists in /var/ipaccess/logs
    [ -d $CDR_FLASH_PATH ] || mkdir -p $CDR_FLASH_PATH
    
    # Ensure ho dir exists in /tmp
    [ -d $HO_TMP_PATH ] || mkdir $HO_TMP_PATH

    # Ensure ho dir exists in /var/ipaccess/logs
    [ -d $HO_FLASH_PATH ] || mkdir -p $HO_FLASH_PATH

    #Copy active CDR file if any
    copyLogFileAtStartup $CDR_FLASH_PATH $CDR_TMP_PATH $CDR_FILENAME

    #Copy active HO file if any
    copyLogFileAtStartup $HO_FLASH_PATH $HO_TMP_PATH $HO_FILENAME
}

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

    #setup default resorces config if working resource config is missing
    if [ -f $RESDEFCFG ] && [ ! -f $RESWRKCFG ]
    then
      cp -rf $RESDEFCFG $RESWRKCFG
    fi

    
    
    #log files related initialization
    initLogFiles
    
    # Ensure the pm logs dir exists, otherwise RRM silently exits.
    [ -d /tmp/pm_logs ] || mkdir /tmp/pm_logs

    #Start RRM
    PDIR=`pwd`
    cd $WDIR
    if [ "$OP_MODE" = "OP_DEVELOPER" ]
    then
    	nice --10  ./$PROG >/tmp/$PROG.txt 2>&1 &
    else
    	nice --10  ./$PROG &
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
    #Copy CDR active file
    copyLogFileAtShutdown $CDR_FLASH_PATH $CDR_TMP_PATH $CDR_FILENAME
    
    #Copy HO active file
    copyLogFileAtShutdown $HO_FLASH_PATH $HO_TMP_PATH $HO_FILENAME

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
    rm -rf $WRKIMSI
    rm -rf $RESWRKCFG
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
