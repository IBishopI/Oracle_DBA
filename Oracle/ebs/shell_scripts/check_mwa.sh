#!/usr/bin/ksh
#####################################################################
# Check WMA service script
# Version 1.3
#
# -i instance
# -n node/hostname
# -u user (SYSADMIN for telnet session)
# -P password (password for SYSADMIN)
#
# Usage: check_mwa.ksh
#####################################################################
# set -x

s_dummy=""

#####################################################################

do_check_wma() {
    l_server=$1
    l_port=$2
    l_output=$3
   (
        # select 1st option (industrial mobile)
        sleep ${TELNET_SLEEP}
        echo  "1"
        sleep 1

        # send ctrl+] to drop MWA connection
        # sleep 1
        echo -e "\035"
        echo "quit"
    ) | telnet ${l_server} ${l_port} > ${l_output} 2>&1
}


do_check_port() {
    t_server=$1
    t_port=$2
    t_start_date=`date`
    t_output_file="${MYNAME%.*}.${s_cfg_instance}.${t_port}.log"
    t_attemptNo=1

    do_check_wma ${t_server} ${t_port} ${t_output_file}

    ### ---- debug line ----
    ### cp ${t_output_file} MWA_ERROR_LOGS/"${MYNAME%.*}.${s_cfg_instance}.${l_port}.1.`date +%Y%m%d_%H%M`.log"

    # count of instance name in telnet log file
    t_logout_cnt=$( grep -ic ${s_cfg_instance} ${t_output_file} )

    # if do_check_mwa() failed... then try one more time.
    if [[ ${t_logout_cnt} -lt 1 ]]
    then
        do_check_wma ${t_server} ${t_port} ${t_output_file}

        ### ---- debug line ----
        ### cp ${t_output_file} MWA_ERROR_LOGS/"${MYNAME%.*}.${s_cfg_instance}.${l_port}.2.`date +%Y%m%d_%H%M`.log"

        # count of instance name in telnet log file
        t_logout_cnt=$( grep -ic ${s_cfg_instance} ${t_output_file} )
        t_attemptNo=2
    fi

    [[ "${s_debug}x" != "x" ]] && echo "Key word count = ${t_logout_cnt}"
    echo "--------------------------------" >> ${t_output_file}

    if [[ ${t_logout_cnt} -ge 1 ]]
    then
        MWA_port="${t_port}-OK"
    else
        MWA_port="${t_port}-ERROR"
    fi

    echo "Attempt No            = ${t_attemptNo}"       >> ${t_output_file}
    echo "MWA port              = ${MWA_port}"          >> ${t_output_file}
    echo "Key word count        = ${t_logout_cnt}"      >> ${t_output_file}
    echo "Checking started     at ${t_start_date}"      >> ${t_output_file}
    echo "Checking completed   at `date`"               >> ${t_output_file}

    # Uncomment this lines to trap errors in separate directory!
    ### ---- debug line ----
    if   [[ ${t_logout_cnt} -lt 1 ]]
    then
         [ ! -d "MWA_ERROR_LOGS" ] && mkdir MWA_ERROR_LOGS
         cp ${t_output_file} MWA_ERROR_LOGS/"${MYNAME%.*}.${s_cfg_instance}.${l_port}.`date +%Y%m%d_%H%M`.log"
    fi
}


do_print_x_vars() {
    echo "xx_key         = ${xx_key}"
    echo "x_cfg_instance = ${x_cfg_instance}"
    echo "x_env_types    = ${x_env_types}"
    echo "x_nodes        = ${x_nodes}"
    echo "x_users        = ${x_users}"
}


do_print_s_vars() {
    echo "------------------------------------------------------------"
    echo "${s_target}"
    echo "------------------------------------------------------------"
    echo "s_cfg_instance = ${s_cfg_instance}"
    echo "s_cfg_env_type = ${s_cfg_env_type}"
    echo "s_cfg_node     = ${s_cfg_node}"
    echo "s_cfg_user     = ${s_cfg_user}"
    echo "s_cfg_env_file = ${s_cfg_env_file}"
    echo "s_cfg_services = ${s_cfg_services}"
    echo "s_connect      = ${s_connect}"
    echo "s_user         = ${s_user}"
    echo "s_password     = ${s_password}"
}


#####################################################################
do_parse_apps_ctl() {
    xx_key='^# +x_config'
    x_cfg_instance=$(echo ${s_cfg_instance} | sed -e 's:,:\|:g')
    x_env_types='mwa'
    x_nodes='.+'
    x_users='.+'

    s_list_of_targets=$(egrep "${xx_key} +(${x_cfg_instance}):(${x_env_types}):(${x_nodes}):(${x_users}):.*$" \
        ${s_apps_ctl} | ${s_awk} '{printf "%s ", $3}')
    if [ "${s_list_of_targets}x" = "x" ]
    then
        echo "Can't parse ${s_apps_ctl} file for given parameters:";
        echo "-----"; do_print_x_vars; echo "-----"
        echo ${ERROR}
        exit
    fi
    
    for s_target in ${s_list_of_targets}
    do
        # save shell 'delimiter'
        OLDIFS="$IFS"; 
        # parse all string
        IFS=":"
        read s_cfg_instance s_cfg_env_type s_cfg_node s_cfg_user s_cfg_env_file s_cfg_services s_connect <<EOF
${s_target}
EOF
        # parse user and password
        IFS="/"
        read s_user s_password <<EOF
${s_connect}
EOF
        # restore shell 'delimiter'
        IFS="$OLDIFS"
        
        [[ "${s_debug}x" != "x" ]] && do_print_s_vars
    done    
}


#####################################################################
do_sleep_or_suicide() {
    # $1 secs to sleep
    [[ "${s_debug}x" != "x" ]] && echo "Starting timer."
    sleep $1
    [[ "${s_debug}x" != "x" ]] && echo "Commit a suicide."
    echo ${ERROR}
    kill -9 ${MYPID}
}


#####################################################################
do_print_help() {
    echo "#####################################################################"
    echo "Usage: $0 parameters ..."
    echo
    echo "    parameter      required example"
    echo "    -------------- -------- -----------"
    echo "    1. instance    yes      PRD"
    echo "    2. port        yes      102000"
    echo "    3. port        yes      102002"
    echo "    4. port        yes      102004"
    echo "    5. port        yes      102006"
#    echo "    -n host        no       server_db01"
#    echo "    -u user        no       SYSADMIN (user for telnet session)"
#    echo "    -P password    no       *****    (password for telnet sesion)"
    echo
    echo "     apps_ctl.sh script is mandatory for this script."
#    echo "    * User and Password parameters will be used"
#    echo "      if script can not access to apps_ctl.sh."
    echo
    echo "Example: $0 PRD 10200 10202 10204 10206"
    echo
    echo "Porpuse: Check WMA service, by producing following actinos:"
    echo "    1) start telnet session"
    echo "    2) loging to WMA"
    echo "    3) logout form WMA"
    echo
    echo "NOTICE:"
    echo "    1) Script will generate following telnet session logfile in work directory:"
    echo "         ${TELNET_LOG}"
    echo "    2) This script is using Ctrl+Z combination to drop telnet session."
    echo "       But WMA service can be configured to use other keystroke."
    echo
    echo "       Issue following command:"
    echo "         $ grep MWA_DROP_CONNECTION $MWA_TOP/secure/default_key.ini"
    echo "       Results should be like this:"
    echo "         MWA_DROP_CONNECTION=CONTROLZ"
    echo "#####################################################################"
}


####################################################################
#   MAIN
####################################################################

# General configuration
# ------------------------------------------------------------------
WD=`dirname $0`
MYNAME=`basename $0`
MYPID=$$
TELNET_SLEEP=2         # 3 secs wait before perform next step inside telnet session
TIMEOUT=300            # 5 mins to check mwa
MWA_port=""
MWA_port1=""
MWA_port2=""
MWA_port3=""
MWA_port4=""
ERROR="Return code: ERROR"
SUCCESS="Return code: OK"

# TELNET_LOG=${MYNAME%.*}.telnet.log

# apps_ctl parsing related configuration
# ------------------------------------------------------------------
s_apps_ctl='/home/topaz/scripts/apps_ctl.sh'

if [[ `uname` = "SunOS" ]]; then
    s_awk="nawk"
else
    s_awk="awk"
fi


# Get parameters
# ------------------------------------------------------------------
# while getopts hdi:n:p:o:r:t:u:P: s_parameter
while getopts hdn:u:P: s_parameter
do
   case ${s_parameter} in
        h)    do_print_help; exit 0;;
        d)    s_debug="debug";;
#        i)    s_cfg_instance="$OPTARG";;
#        p)    s_port1="$OPTARG";;
#        o)    s_port2="$OPTARG";;
#        r)    s_port3="$OPTARG";;
#        t)    s_port4="$OPTARG";;
        n)    s_cfg_node="$OPTARG";;
        u)    s_user="$OPTARG";;
        P)    s_password="$OPTARG";;
        \?)   do_print_help; exit 1;;
    esac
done

s_cfg_instance=$1
s_port1=$2
s_port2=$3
s_port3=$4
s_port4=$5
# s_debug="debug"

TELNET_LOG=${MYNAME%.*}.$1.telnet.log

[[ "${s_debug}x" != "x" ]] && do_print_s_vars

# Checking parameters
# ------------------------------------------------------------------
if [[ $# -eq 0 ]]; then
    do_print_help
    exit 0
fi
[[ ${s_port1} -lt 1 ]] && [[ "${s_debug}x" != "x" ]] && echo "Port1 number is incorrect!!! Skipped"
[[ ${s_port2} -lt 1 ]] && [[ "${s_debug}x" != "x" ]] && echo "Port2 number is incorrect!!! Skipped"
[[ ${s_port3} -lt 1 ]] && [[ "${s_debug}x" != "x" ]] && echo "Port3 number is incorrect!!! Skipped"
[[ ${s_port4} -lt 1 ]] && [[ "${s_debug}x" != "x" ]] && echo "Port4 number is incorrect!!! Skipped"

if [[ ! -r ${s_apps_ctl} ]]; then
    s_apps_ctl='/home/topaz/scripts/apps_ctl.sh'
    if [[ ! -r ${s_apps_ctl} ]]; then
        echo "Not able to access to apps_ctl.sh file (${s_apps_ctl})"
        echo "Will try to use values from -n, -u and -P parameters."
        if [[ "${s_user}x" = "x" ]] || \
           [[ "${s_password}x" = "x" ]] || \
           [[ "${s_cfg_node}x" = "x" ]]; then
            echo "Please use -n , -u and -P parameter."
            echo ${ERROR}
            exit 1;
        fi
    fi
fi

# Check WMA
# ------------------------------------------------------------------
[[ "${s_debug}x" != "x" ]] && echo "${MYNAME} started at `date`."

# start postponed suicide
do_sleep_or_suicide ${TIMEOUT} &
s_suicide_pid=$!

if [[ "${s_debug}x" != "x" ]]; then
    echo "My    PID: $$"
    echo "Timer PID: ${s_suicide_pid}"
fi

if [[ -r ${s_apps_ctl} ]]; then
    # this function will initialize s_user and s_password vars
    do_parse_apps_ctl
fi

# start telnet port1 check
if [[ ${s_port1} -gt 1 ]]; then
    do_check_port ${s_cfg_node} ${s_port1}
    MWA_port1="${MWA_port}"
fi

# start telnet port2 check
if [[ ${s_port2} -gt 1 ]]; then
    do_check_port ${s_cfg_node} ${s_port2} 
    MWA_port2="${MWA_port}"
fi

# start telnet port3 check
if [[ ${s_port3} -gt 1 ]]; then
    do_check_port ${s_cfg_node} ${s_port3} 
    MWA_port3="${MWA_port}"
fi

# start telnet port4 check
if [[ ${s_port4} -gt 1 ]]; then
    do_check_port ${s_cfg_node} ${s_port4} 
    MWA_port4="${MWA_port}"
fi

# candel suicide
[[ "${s_debug}x" != "x" ]] && echo "Stoping timer."
kill -9 ${s_suicide_pid} 

echo "${MWA_port1}" "${MWA_port2}" "${MWA_port3}" "${MWA_port4}"

[[ "${s_debug}x" != "x" ]] && echo "See `pwd`/${TELNET_LOG} for details of telnet session"
[[ "${s_debug}x" != "x" ]] && echo "${MYNAME} completed at `date`."

exit 0

