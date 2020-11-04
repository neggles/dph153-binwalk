#
# Bash profile for root

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/opt/ipaccess/bin"

# Setup environment for crash logs
export CRASH_LOG_PATH=/tmp/crash_logs/applications
export CRASH_PID_PATH=/var/run

# Create the directory for the crash logs
mkdir -p $CRASH_LOG_PATH

