#!/usr/bin/ksh 
#########################################################################################
# Filename      runaway_process.sh
# Usage         runaway_process.sh <cmdname> <cpu threshold> <time threshold>
# Return        good condition: null
#               bad condition: process_id CMDNAME cpu_threshold time_treshold
#########################################################################################
normal_exit()
{
        echo "Return Code: Normal"
        rm $TMPLIST $TMP $OUTF 2>/dev/null
        exit 0
}

WD=`dirname $0`
MYNAME=`basename $0`

TMPLIST=/tmp/topsession.$$
OUTF=/tmp/topsession.$$.out
CMDNAME=$1
CPU_THRESHOLD=$2
TIME_THRESHOLD=$3


LOGFILE=$WD/../log/${MYNAME%.*}.log

TMP=/tmp/top.$$


case `uname` in
    HP-UX)
        s_awk="awk"
        s_platform="HP-UX"
        s_mail="mailx"
       s_top_command="top -d 2 -s 1 -h -f $TMP"
        s_title_str='/^CPU/ &&  /TTY/ && /PID/ && /COMMAND$/'
        s_top_start=10
        s_pid_col=3
        s_user_col=4
        s_time_col=10
        s_cpu_col=12
        s_ps_col=13
        ;;
    SunOS)
        s_platform="SOLARIS"
        s_awk="nawk"
        s_mail="mailx"
        s_top_command="top -d 3 -s 1 >$TMP"
        s_title_str='PID USERNAME LWP PRI NICE  SIZE   RES STATE    TIME    CPU COMMAND'
        s_top_start=51
        s_pid_col=1
        s_user_col=2
        s_time_col=9
        s_cpu_col=10
        ;;
    AIX)
        ### not AIX available yet
        s_platform="SOLARIS"
        s_awk="nawk"
        s_mail="mailx"
        s_top_command="top -d 3 -s 1 >$TMP"
        s_top_start=51
        s_pid_col=1
        s_user_col=2
        s_time_col=9
        s_cpu_col=10
        ;;
    Linux)
        s_platform="LINUX"
        s_awk="awk"
        s_mail="mail"
        s_top_command="top -b -d 1 -n 2 > $TMP"
        s_title_str='PID USER      PR  NI  VIRT  RES  SHR S \%CPU \%MEM    TIME\+  COMMAND'
        s_top_start=8
        s_pid_col=1
        s_user_col=2
        s_time_col=11
        s_cpu_col=9
        s_ps_col=12
        ;;

esac

## run top command
eval $s_top_command

## print the last line number of title string
CMD="$s_awk '/"$s_title_str"/ {n=NR} END {print n}' $TMP"
s_top_start=`eval "${CMD}"`


## find the string
$s_awk 'NR>'"$s_top_start"' && $'"$s_ps_col"' == "'"$CMDNAME"'" {print $0}' $TMP|head -10> $TMPLIST

## process the top session list
if [[ ! -s $TMPLIST ]] then
        normal_exit
else
        cat $TMPLIST | $s_awk 'BEGIN {
        CPU_THRESHOLD='"$CPU_THRESHOLD"'
        TIME_THRESHOLD='"$TIME_THRESHOLD"'}
        $'"$s_cpu_col"' > CPU_THRESHOLD {tm=substr($'"$s_time_col"',1,index($'"$s_time_col"',":")-1);
                if ( int(tm)> TIME_THRESHOLD) {print $'"$s_pid_col"'" "$'"$s_user_col"' " " $'"$s_time_col"' " " $'"$s_cpu_col"' " " $'"$s_ps_col"'}
                }' > $OUTF
        ### if OUTF is not null: find high CPU processes
        if [[ -s $OUTF ]]
        then
                date >> $LOGFILE
                echo 'Return Code: Error'
                cat $OUTF
                cat $TMPLIST >> $LOGFILE
                cat $OUTF >> $LOGFILE
                echo "=======================" >> $LOGFILE
                rm $TMPLIST $TMP $OUTF
               exit 1
        else
                normal_exit
        fi
fi

