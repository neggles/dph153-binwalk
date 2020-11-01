#!/bin/bash
#
# Script to upload files to a server
#

ME=`basename $0`

CURLPATH=/opt/ipaccess/bin
RETVAL=0
NO_DELETE=0
SERVER_URL=
CRL_URL=
UPLOAD_PATH=
DSCP=

usage()
{
    echo "USAGE: $ME [-h|--help] [--no-delete] [--dscp=VALUE] <--server-url=URL> [--crl-url=URL] <--path=PATH>"
    echo " -h|--help              show this help text"
    echo " --no-delete            Don't delete the file after successful upload"
    echo "                        (default: false)"
    echo " --dscp=VALUE           DSCP value to be used while upload"
    echo " --server-url=URL       URL where file should be uploaded"
    echo " --crl-url=URL          CRL Base URL in case of secure upload (default: empty)"
    echo " --path=URL             Path of the file/directory to be uploded"
}

uploadFile()
{
    $CURLPATH/ipacurl -f -T $1 $DSCP $CRL_URL $2 -y 30 -Y 1
    RETVAL=$?
    if [ 0 -eq $RETVAL ] && [ $NO_DELETE == 0 ]
    then
        rm -f $1
    fi    
}

uploadDir()
{
    fileList=`ls -tr $UPLOAD_PATH`
    for file in $fileList
    do
        absPath=$UPLOAD_PATH/$file
        pathOnServer=$SERVER_URL/$file
        [ -f $absPath ] || continue
        uploadFile $absPath $pathOnServer
    done
}

# process command line arguments
for p in $*
do
    case $p in
        --no-delete)
        NO_DELETE=1
        ;;
        --server-url=*)
        SERVER_URL=`echo $p | sed 's/[-a-zA-Z0-9]*=//'`
        ;;
        --crl-url=*)
        CRL_URL=`echo $p | sed 's/[-a-zA-Z0-9]*=//'`
        CRL_URL="--crlbaseurl $CRL_URL"
        ;;
        --path=*)
        UPLOAD_PATH=`echo $p | sed 's/[-a-zA-Z0-9]*=//'`
        ;;
        --dscp=*)
        DSCP=`echo $p | sed 's/[-a-zA-Z0-9]*=//'`
        if [ $DSCP -gt 63 ]; then
            echo "ERROR: $ME: Wrong DSCP value $DSCP"
            exit 1
        fi
        DSCP="--dscp $DSCP"
        ;;
        *|--help|-h)
        usage
        exit 1
        ;;
    esac
done

#validate mandatory attributes
if [ "$SERVER_URL" == "" ] || [ "$UPLOAD_PATH" == "" ]; then
    usage
    exit 1
fi

#validate path
if [ ! -d $UPLOAD_PATH ] && [ ! -e $UPLOAD_PATH ]; then
    echo "ERROR: $ME: Path seems to be wrong"
    exit 1
fi

#validation successful
#Upload files
if [ -d $UPLOAD_PATH ]; then
    uploadDir
else
    filename=`basename $UPLOAD_PATH`
    serverUrl=$SERVER_URL/$filename
    uploadFile $UPLOAD_PATH $serverUrl
fi

exit $RETVAL        
