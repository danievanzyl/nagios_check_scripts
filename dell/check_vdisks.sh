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
OMREPORT=/opt/dell/srvadmin/bin/omreport
TMP=$(mktemp /tmp/check_vdisk.XXXXX)

function clean_up {
  rm -f $TMP
}

#enable traps
trap clean_up EXIT

STATUS_DATA="| "
STATUS=""
STATUS_EX="vdisk(s)"
$OMREPORT storage vdisk controller=$CNTRL -fmt cdv |grep ';' > $TMP
#version 7.2
#ID;Status;Name;State;Hot Spare Policy violated;Encrypted;Layout;Size;Device Name;Bus Protocol;Media;Read Policy;Write Policy;Cache Policy;Stripe Element Size;Disk Cache Policy

while IFS=\; read ID status name state hspv enc layout size dev data
do
  if [[ $ID != "ID" ]];then
    if [[ $status == "Ok" ]];then
      exit_code=0
      STATUS="GOOD"
    else
      exit_code=2
      STATUS="CRITICAL"
    fi
  STATUS_EX+=" ${dev}[${layout}:${state}]"
  fi
done < $TMP

echo "${STATUS} - ${STATUS_EX} ${STATUS_DATA}"
exit $exit_code
