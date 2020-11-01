#!/bin/bash
#
# setnv_env.sh - helper script to allow applications to set 
#                non-volatile environment variables.
#
NVENV=/var/ipaccess/nv_env.sh
ME=`basename $0`

usage()
{
    echo "USAGE: $ME [-c] name [value]"
    echo " Examples:"
    echo "  Give variable named TESTENV a value of 123"
    echo "      $ME TESTENV 123"
    echo "  Update variable TESTENV with new value of 456"
    echo "      $ME TESTENV 456"
    echo "  Clear variable TESTENV by setting it to an empty string"
    echo "      $ME TESTENV"
    echo "  Clear variable TESTENV by removing in from the file (will not update running consoles)"
    echo "      $ME -c TESTENV"

    exit 1
}

if [ $# -lt 1 -o "$1" == "--help" -o "$1" == "-h" ]; then
    usage
fi

REMOVE=0
VARNAME=$1
if [ $1 = "-c" ]; then
    REMOVE=1
    VARNAME=$2
fi

# $VARNAME isn't checked to allow environment variables to be cleared
# rather than just not set (to unset a previously set value)
if [ -f $NVENV ]; then
    if [ "`grep $VARNAME $NVENV`" != "" ]; then
        sed -ie "s/export $VARNAME=.*//g" $NVENV
        sed -ie "/^$/d" $NVENV
    fi
fi

if [ $1 != "-c" ]; then
    echo "export $1=\"$2\"" >> $NVENV
fi
echo "WARNING:"$1 "will be updated on OMCR( if already exist in diagnosticTunning list) on next AP reboot"
