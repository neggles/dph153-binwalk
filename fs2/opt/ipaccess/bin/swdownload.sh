#!/bin/bash
#
# Usage swdownload.sh <host IP> <kernel image> <filesystem image>
#
#  Host IP defaults to 10.255.250.175
#  Filesystem image name defaults to fs.bin
#  Kernel image name defaults to kernel.bin
#

GETVARVAL=/opt/ipaccess/Utils/scripts/getVarVal
SETVARVAL=/opt/ipaccess/Utils/scripts/setVarVal
SETNV_ENV=/opt/ipaccess/bin/setnv_env.sh
MNT_HW_DESC=/mnt/var/ipaccess/factory_config/hw_description.dat
TMP_HW_DESC=hw_description.dat.tmp
TMP_HW_DESC2=hw_description.dat.tmp2
TMP_MODULES=modules.tmp
MNT_MODULES=/mnt/etc/modules
MNT_FACTORY_CONFIG=/mnt/var/ipaccess/factory_config

echo
echo "Flashing 267 board:"
echo
if [ -z "$1" ]; then
    host_ip=10.255.250.175
else
    host_ip=$1
fi

if [ -z "$2" ]; then
    kernel_file=kernel.bin
else
    kernel_file=$2
fi

# Check if the Kernel file exists
status=`wget -s -q http://$host_ip/$kernel_file 2>&1`
if [ "$status" != "" ]; then
    echo "Kernel file does not exist. Aborting !!!"
    exit
fi

if [ -z "$3" ]; then
    image_file=fs.bin
else
    image_file=$3
fi

# Check if the Image file exists
status=`wget -s -q http://$host_ip/$image_file 2>&1`
if [ "$status" != "" ]; then
    echo "Image file does not exist. Aborting !!!"
    exit
fi
        
echo "Using          host IP $host_ip"
echo "          kernel image $kernel_file"
echo "      filesystem image $image_file"
echo

# determine which FS partition we're booting from
boot_dev=

for p in $(cat /proc/cmdline); do
    case $p in
        root=*)
            boot_dev=`echo $p | awk -F= '{print $2}'`
            ;;
    esac
done

boot_bank=1
flash_bank=2
kernel_mtd=mtd7
fs_mtd=8
fs_ubi=1
bank_letter=B
if [ "$boot_dev" = ubi1:rootfs ]; then
    boot_bank=2
    flash_bank=1
    kernel_mtd=mtd4
    fs_mtd=5
    fs_ubi=0
    bank_letter=A
fi

echo "     Running from bank $boot_bank  (boot device is $boot_dev)"
echo "Updating image in bank $flash_bank"
echo

echo -n "Erasing kernel $bank_letter partition.......... "
flash_erase /dev/$kernel_mtd 0 0 > /dev/null
if [ $? -ne 0 ]; then
    echo "Failed"
    exit 1
else
    echo "Done"
fi

echo -n "Programming kernel $bank_letter partition...... "
wget -q -O - http://$host_ip/$kernel_file | nandwrite -a -p /dev/$kernel_mtd - > /dev/null
if [ $? -ne 0 ]; then
    echo "Failed"
    exit 1
else
    echo "Done"
fi

echo -n "Detaching mtd$fs_mtd from ubi............. "
ubidetach /dev/ubi_ctrl -m $fs_mtd 2> /dev/null
if [ $? -ne 0 ]; then
    echo "Failed (ignored)"
else
    echo "Done"
fi

echo -n "Counting bytes in filesystem image.. "
image_len=`wget -q -O - http://$host_ip/$image_file | wc -c`
echo $image_len

echo -n "Programming filesystem $bank_letter partition.. "
wget -q -O - http://$host_ip/$image_file | ubiformat -y -s 2048 -O 2048 /dev/mtd$fs_mtd -f - -S $image_len > /dev/null
if [ $? -ne 0 ]; then
    echo "Failed"
    exit 1
else
    echo "Done"
fi

echo -n "Switching to bank $flash_bank................. "
fw_setenv bank $flash_bank > /dev/null
fw_setenv bank $flash_bank > /dev/null
if [ $? -ne 0 ]; then
    echo "Failed"
    exit 1
else
    echo "Done"
fi

sync
echo "Board flashed successfully."


