#!/bin/bash
##########################################################################
# fsvalidator.sh
# Script to generate Filesystem Checksums and compare the result
# (C) ip.access 2009
##########################################################################


function usage()
{
	echo "fsvalidator.sh <root path> [reference_fs_chk_file]"
	echo "			it cd's to <root path> and    returns a list of files and their MD5SUMs"
	echo "			if [reference_fs_chk_file] is specified it diff's the output against the "
	echo "			reference file to determine if it is identical."
	echo "			returns 0 if matches, -1 if fails"
}


generate_check_output()
{
	cd $1
	for i in `find . -xdev -type f`
	do
		md5sum $i
	done
}

verify_output()
{
	cd $1
	md5sum -c $2
}


case $# in
    0)
	usage;
	;;
	1)
	generate_check_output $1;
	;;
	2)
	verify_output $1 $2
	;;
	*)
	usage;
	;;
esac