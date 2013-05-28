#!/bin/bash
#
#	Author: Danie van Zyl (https://github.com/pylonpower/nagios_check_scripts)
# 	Requires: fcgi (yum install fcgi)
# 	Purpose: Display /status and gather stats for a specified pool
#
#	More status can be gathered, this will change as warning / criticals 
#	will be set on worker utilization in the future
##############

#Global Variables
exit_status=-1
msg=""
fcgi=$(which cgi-fcgi)
TMP=$(mktemp /tmp/check_phpfpm.XXXXX)

STATUS[0]="OK - "
STATUS[1]="WARNING - "
STATUS[2]="CRITICAL - "
STATUS[3]="UNKNOWN - "

#Functions
#
function check_lock {
	fuser -s $LOCK &> /dev/null
	return $?
}

function check_proc {
	local _proc
	_proc=$(ps hU ${activemq_user} |awk '{print $1}')
	if [ -z "$_proc" ];then
		return 1	
	else
		echo $_proc
		return 0
	fi
}

function clean_up {
	rm -f $TMP
}

function check_fcgi {
#execute command
	local _host=$1
	local _port=$2
	local _tmp=$3

SCRIPT_NAME=/status \
	SCRIPT_FILENAME=/status \
	REQUEST_METHOD=GET \
	QUERY_STRING= \
	$fcgi -bind -connect $_host:$_port > $_tmp 2>/dev/null 
	return $?
}

function main {
	#trap on exit cleanup function
	local _host=$1
	local _port=$2
	trap clean_up EXIT
	#run fcgi command		
	check_fcgi $_host $_port $TMP
	if [[ "$?" -ge "1" ]]; then
		echo "General Error - fcgi command not found, please install"
	fi

	#check if file is empty
	if [[ -s $TMP ]];then
		pool_name=$(awk '/pool:/ {print $2}' $TMP)
		p_active=$(awk -F : '/^active processes:/ {print $2}' $TMP)
		p_total=$(awk -F : '/total processes:/ {print $2} ' $TMP)
		perf="procs=$p_active;$p_total;"
		msg="Pool $pool_name listening on $_host:$_port"
		exit_status=0
	else
		msg="Could not connect to $host:$port"
		exit_status=2
	fi
	echo ${STATUS[$exit_status]} $msg
	exit $exit_status
}
#
#EOFunctions

#run main function
#

main $1 $2
