#!/bin/sh

# Perry: Temp write test
#sleep 2
#mtd_write lock mtd0
#sleep 1
#echo "Start continuous write test..."
#while [ 1 ]; do
#	cfg_flash -s -n test -v 1234567
#	echo "write done -- test lock"
#done

#wait config server to start
sleep 5

uboot_value=`cfg_flash -r -n boot_loc`
kernel_value=`cs_client get sys/boot_loc`

echo "[SYSTEM] Checking the boot_loc information ---- $uboot_value $kernel_value"

#if [ $uboot_value != $kernel_value ]; then
rst=`cs_client set sys/boot_loc $uboot_value; cs_client commit`
echo "[SYSTEM] Update the boot_loc information. Result: $rst"
echo $uboot_value > /tmp/boot_loc
#fi

#current_fw=`cs_client get sys/swdirurl`
#band_fw=`cs_client get sys/fw/$uboot_value/swdirurl`

#if [ $current_fw != $band_fw ]; then
#	rst=`cs_client set sys/fw/$uboot_value/swdirurl $current_fw`
#	echo "[SYSTEM] The firmware version is not correct! It's because we upgrade from version before 1.0.22"
#fi

