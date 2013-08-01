#!/bin/bash
#
# author: danievanzyl (https://github.com/danievanzyl)
# version: 1.0
# license: http://www.apache.org/licenses/LICENSE-2.0.html
# read changelog for most up-to-date changes
##########################
if [ -z "$1"  ];then
  echo -ne "\n\n${0} <controller>\n e.g. ${0} 23\n\n\n"
  exit 0
else 
  CNTRL=$1
fi

TMP=$(mktemp /tmp/check_pdisk.XXXXX)
function clean_up {
rm -f $TMP 
}
OMREPORT=/opt/dell/srvadmin/sbin/omreport
STATUS=""
STATUS_EX="pdisk(s)"
exit_status=0
$OMREPORT storage pdisk controller=$CNTRL -fmt cdv |grep ";" > $TMP
#add traps
trap clean_up EXIT
#version 7.2
#ID;Status;Name;State;Power Status;Bus Protocol;Media;Device Life Remaining;Failure Predicted;Revision;Driver Version;Model Number;Certified;Encryption Capable;Encrypted;Progress;Mirror Set ID;Capacity;Used RAID Disk Space;Available RAID Disk Space;Hot Spare;Vendor ID;Product ID;Serial No.;Part Number;Negotiated Speed;Capable Speed;Device Write Cache;Manufacture Day;Manufacture Week;Manufacture Year;SAS Address
while IFS=\; read ID Status Name State PowerStatus busp media dlr FailurePredicted rev drvver modelnum Certified EncryptionCapable Encrypted Progress MirrorSetID Capacity UsedRAIDDiskSpace AvailableRAIDDiskSpace HotSpare data
do
  if [[ $ID != "ID" ]];then
    STATUS=$Status
    if [[ $Status != "Ok" ]];then
      exit_status=2
    elif [[ $Status == "Ok" ]]; then
      exit_status=0
      STATUS_OK+=" ${ID}[$State::$HotSpare]"
    fi
    if [[ $State != "Online" && $State != "Ready" ]];then
      STATUS_FL+=" ${ID}[$State::$HotSpare]"
    fi
  fi
done < $TMP

echo $STATUS - $STATUS_FL $STATUS_OK
exit $exit_status
