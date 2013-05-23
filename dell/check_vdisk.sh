#!/bin/bash
# Author: Danie van Zyl (https://github.com/pylonpower/nagios_check_scripts)
# Purpose:
# Use dell omreport to gather virtual disk statuses and present it to nagios. But be used with NRPE.
#
if [ -z "$1"  ];then
	echo -ne "\n\n${0} <controller>\n e.g. ${0} 23\n\n\n"
	exit 0
else 
	CNTRL=$1
fi
OMREPORT=/opt/dell/srvadmin/bin/omreport
CACHED_OUTPUT=/tmp/vd_controller${CNTRL}
STATUS_DATA="| "
STATUS=""
STATUS_EX="vdisk(s) "
ERROR_CODE[0]="false"
ERROR_CODE[1]="false"
ERROR_CODE[2]="false"
#ERROR_CODE[3]="false"
#
$OMREPORT storage vdisk controller=$CNTRL -fmt cdv |grep ";" > $CACHED_OUTPUT
#
#ID;Status;Name;State;Encrypted;Layout;Size;Device Name;Bus Protocol;Media;Read Policy;Write Policy;Cache Policy;Stripe Element Size;Disk Cache Policy
#version: 6.5+
#while IFS=\; read ID status name state enc layout size dev data
#version: 6.3
while IFS=\; read ID status name state hspv badblocks secured progress layout size dev data
do
if [[ $ID != "ID" ]];then
	if [[ $status == "Ok" ]];then
		exit_code=0
	elif [[ $status == "Non-Critical" ]];then
		ERROR_CODE[1]="true"
		STATUS_EX+="${dev}:${state} "
	else
		ERROR_CODE[2]="true"
		STATUS_EX+="${dev}:${state} "
	fi
	STATUS_DATA+="$dev::$state "
fi
done < $CACHED_OUTPUT

if [[ ${ERROR_CODE[2]} == "true" && ${ERROR_CODE[1]} == "true" ]];then
	exit_code=2
	STATUS="CRITICAL"
elif [[ ${ERROR_CODE[2]} == "false" && ${ERROR_CODE[1]} == "true" ]];then
	exit_code=1
	STATUS="WARNING"
else
	exit_code=0
	STATUS="OK"
	STATUS_EX="GOOD"
fi
echo "${STATUS} - ${STATUS_EX} ${STATUS_DATA}"
exit $exit_code
