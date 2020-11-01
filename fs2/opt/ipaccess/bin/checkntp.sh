#!/bin/bash
#
# checkntp.sh  Helper script to verify if provided NTP Servers
#              are valid using ntpdate command.
#
ME=`basename $0`

usage()
{
    echo "USAGE: $ME name ntpserver1 [ntpserver2] .. [ntpserver4]"
    echo " Examples:"
    echo "      $ME 212.188.128.162"
    echo "      $ME 212.188.128.163 212.188.128.16 212.188.128.164 0.ipaccess.pool.ntp.org"
    echo " return value 0 means all servers healthy and non-zero return value will"
    echo " indicate indexes of invalid servers at bitmap of respective positions;"
    echo " as in given example return value is 10. In case of script exit due to input" 
    echo " parameters errors, exit code will be 99"
    exit 99
}
                                    
if [ $# -lt 1 -o "$1" == "--help" -o "$1" == "-h" -o $# -gt 4 ]; then
    usage
fi

b=1
c=0
while [ $# -gt 0 ]
do
    STR=$STR" "$1
    ntpdate -sq $1 > /dev/null
    if [ $? -ne 0 ];then
        echo "NTP Server" $1 "validation failed"  
        let c=$c+$b
    fi
    let b=$b*2
    shift
done

echo "return code " $c
exit $c
