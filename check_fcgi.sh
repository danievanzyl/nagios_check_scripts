#!/bin/bash
#
#	Author: Danie van Zyl (https://github.com/anythinglinux/nagios_check_scripts)
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
function display_usage {
	echo -ne "\tUsage: \n"
	echo -ne "\t\t$0 <ip> <port>\n"
	echo -ne "\t\te.g. $0 127.0.0.1 9000\n"
}

function clean_up {
	rm -f $TMP
}

function check_fcgi {
	local _host=$1
	local _port=$2
	local _tmp=$3

	#execute command
	SCRIPT_NAME=/status \
	SCRIPT_FILENAME=/status \
	REQUEST_METHOD=GET \
	QUERY_STRING= \
	$fcgi -bind -connect $_host:$_port > $_tmp 2>/dev/null 
	return $?
}

function main {
	local _host=$1
	local _port=$2
	local perf=""
	#trap on exit cleanup function
	trap clean_up EXIT

	#run fcgi command		
	check_fcgi $_host $_port $TMP

	if [[ "$?" -ge "1" ]]; then
		echo "General Error - fcgi command not found, please install"
		exit 255
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
	echo ${STATUS[$exit_status]} $msg "|" $perf
	exit $exit_status
}
#
#EOFunctions

# check arguments
if [[ "$#" -lt "2" ]];then
	display_usage
	exit 1
else
	#then run main function
	main $1 $2
fi
