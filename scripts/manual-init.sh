# location of compressed log file containing startup output of
# everything within /etc/rcS.d
CONSOLE_LOG=/var/log/rcS.d_consolelog.gz
# console output
TMP_LOG=/tmp/consolelog
# location of nv_env.sh file and its helper script
NVENV=/var/ipaccess/nv_env.sh
SETNVENV=/opt/ipaccess/bin/setnv_env.sh

# Mount the default file systems mentioned in /etc/fstab.
mount -a

# setup /dev as a tmpfs and populate using mdev
if ! mountpoint -q /dev; then
    mount -t tmpfs -o size=64k,mode=0755 tmpfs /dev
fi
# Enable automated reboot on oops and oom
# Depends on kernel.panic=1 which is set through kernel command line "panic=1"
sysctl -w kernel.panic_on_oops=1
sysctl -w vm.panic_on_oom=1

if ! mountpoint -q /dev/pts; then
    mkdir -p /dev/pts
    mount -t devpts devpts /dev/pts
fi

echo /sbin/mdev > /proc/sys/kernel/hotplug
/sbin/mdev -s

# Create ttyS00 and ttyS01 sym links for backward compatibility with older platforms
ln -sf /dev/ttyS0 /dev/ttyS00
ln -sf /dev/ttyS1 /dev/ttyS01

if [ -x /opt/ipaccess/bin/setup_mtd_links ]; then
    /opt/ipaccess/bin/setup_mtd_links
fi

# workaround, it seems hotplug isn't working too well
for d in 0 1; do
    LEDF=/dev/leddriver$d
    if [ ! -c $LEDF ]; then
        rm -f $LEDF
        mknod $LEDF c 241 $d
    fi
done
ln -sf leddriver0 /dev/leddriver

# Source the PATH from /etc/profile
source /etc/profile


### overrides
export IS_NANO=1
export COMMISSIONING_MODE=1

export FS_VARIANT="224A"
export FS_LETTER=${FS:3:1}


# done after sourcing /etc/profile so FS_VARIANT is set
TMP_LOG_MAX=64

echo "Running rc.sysinit" > /dev/console
/etc/init.d/rc.sysinit

# Run in a sub-shell so we can pipe output via ipalog to a log file
(

# Create root's home directory, if not already there
if [ ! -f /var/ipaccess/root_home/.bash_profile ]
then
  mkdir -p /var/ipaccess/root_home
  tar -xzf /opt/ipaccess/RootDir/root_home.tgz -C /var/ipaccess
  sync
fi


# Pick out the code letter for the filesystem name
# Assumes it is the fourth character of the string
FS_LETTER="A"
DEFAULT_UNHARDENED="TRUE"

ENV_UPDATED=0
# if value is unset, default it
if [ "$ENV_VERBOSE_CONSOLE_ENABLED" = "" ]; then
    echo "Defaulting ENV_VERBOSE_CONSOLE_ENABLED to filesystem default ($DEFAULT_UNHARDENED)"
    $SETNVENV ENV_VERBOSE_CONSOLE_ENABLED $DEFAULT_UNHARDENED
    # ensure getty is in the correct state
    killall startgetty
    ENV_UPDATED=1
fi
if [ "$ENV_FIREWALL_DISABLED" = "" ]; then
    echo "Defaulting ENV_FIREWALL_DISABLED to filesystem default ($DEFAULT_UNHARDENED)"
    $SETNVENV ENV_FIREWALL_DISABLED $DEFAULT_UNHARDENED
    ENV_UPDATED=1
fi

# this is here in case something went wrong creating/modifying nv_env
export ENV_VERBOSE_CONSOLE_ENABLED=$DEFAULT_UNHARDENED
export ENV_FIREWALL_DISABLED=$DEFAULT_UNHARDENED

ENV_UPDATED=1

# allow additional nv_env variable to override default/configured state
# of serial console (but not ssh console)
export SERIAL_CONSOLE_ENABLED=$ENV_VERBOSE_CONSOLE_ENABLED

if [ $ENV_UPDATED = 1 ]; then
    source $NVENV
fi

rcdir=/etc/rcS.d

#for i in ${rcdir}/S*
#do
#    [ ! -f  "$i" ]  && continue;
#    echo -n "Starting `basename $i`: " > /dev/console
#    $i start
#    RETVAL=$?
#    if [ $RETVAL -eq 0 ]; then
#        echo "OK" > /dev/console
#    else
#        echo "FAILED ($RETVAL)" > /dev/console
#    fi
#done

pushd /etc/rcS.d
./S00start start
./S01cpu_alignment start
./S02mountoemparts start
./S03lastreboot start
./S03ubootenvcheck start
./S06iptables start
./S07dhcp start
./S08random start
./S10sshd start
./S11fallbackdate start
#./S13crond start
./S99end start

echo "Running rc.local" > /dev/console
/etc/init.d/rc.local


# Save and compress the startup log
# This must be just after the last init script is run
mv $TMP_LOG /tmp/console.tmp
# ipalog will create a new log file when it writes out the next log entry
gzip -c /tmp/console.tmp > $CONSOLE_LOG
rm /tmp/console.tmp
