#####################################################################
# $Header: mwactl.sh v.3.07
#
# Compatible with E-Biz 11i and R12
#
# Andrey Goncharov 02/13/2012
#
### The MWA server uses port n+1 to communicate with Server Manager.
### The MWA DISPATCHER uses port n+3
### If you start server on port 22212 then port 22213 will be taken up
### and you wont be able to start another server on this port

if [ x${CONTEXT_FILE} = 'x' ]; then
  S_ENVFILE="$HOME/APPS*_`hostname --short`.env"
  test -f $S_ENVFILE && . $S_ENVFILE
fi

### Define/customize your MWA script here

S_LOGIN="SYSADMIN/sysadmin5prd"
S_DISPLAY="DISPLAY=localhost:1.0; export DISPLAY"
FUSER=/sbin/fuser
BANK_A=""
BANK_B="10218 10220 10222 10224 10226 10228"
S_BANK_A_PROCESSES=0
S_BANK_B_PROCESSES=0
### end of customisation

##############################
do_check_mwa_dispatcher() {
  ps -fu $LOGNAME|grep "$MWA_TOP/bin/MWADIS"|grep -v grep 1>/dev/null
  if [ $? != 0 ];then
    printf "!! Seems to be MWA dispatcher is down, Please start dispatcher first. [`date`]\n"
    exit 1
  else
    printf "#> Dispatcher is running. [`date`]\n" ; return 0
  fi
}

do_check_mwa_jre() {
g_mwa_processes=0
g_processes=""
for i in $1
do
  FF=$MWA_LOG_TOP/"$i".system.log
  procss=$($FUSER $FF 2>/dev/null|awk '{print $0}')
  procss=$(echo $procss|sed -e "s/^[ ]*//g" -e "s/[ ]*$//g")
  for b in $(echo $procss)
  do
    g_mwa_processes=$(( g_mwa_processes + 1))
    g_processes=$(echo $g_processes $procss)
  done
done
if [[ $g_mwa_processes -gt 0 ]] ; then
  printf "#> Telnet services for BANK ($1) already started (processes: $g_mwa_processes)\n"
  printf "#> OS processes ($g_processes) running.\n"
  return 0
fi
return 1
}

##############################
stop_force_mwa_jre() {
TMP1=/tmp/procss.$$
for i in $1
do
  FF=$MWA_LOG_TOP/"$i".system.log
  #$FUSER $FF|awk '{print $0}' 1>$TMP1
  procss=$($FUSER $FF 2>/dev/null|awk '{print $0}')
  procss=$(echo $procss|sed -e "s/^[ ]*//g" -e "s/[ ]*$//g")
  if [[ -n $procss ]] ; then
    kill $procss
    printf "#> MWA telnet services on port: $i has been killed (PID: $procss), exit_code $?.\n"
  else
    printf "#> No process to kill (port: $i PID: $procss).\n"
  fi
done
#rm -f $TMP1
}

##############################
stop_soft_mwa_jre() {

cd $MWA_BIN_TOP
for i in $1
do 
  ./mwactl.sh -login $S_LOGIN stop $i 1> /dev/null 2>&1
  printf "#> Shutdown (soft) telnet service on port: $i .\n"
done
}


##############################
# MAIN
##############################
eval $S_DISPLAY

if [[ -n $1 ]]; then
  command=$1
else
  command="help"
fi

if [[ -n $2 ]]; then
  login=$2
else
  login=${S_LOGIN}
fi

if [ ! -f ${CONTEXT_FILE} ]; then
  echo " Please apply Ebiz environment file before start script"
  exit 1
fi

MWA_BIN_TOP=$MWA_TOP/bin
if [ "x${ADMIN_SCRIPTS_HOME}" != "x" ]; then MWA_BIN_TOP=${ADMIN_SCRIPTS_HOME}; fi
MWA_LOG_TOP=$MWA_TOP/log
if [ "x${INST_TOP}" != "x" ]; then MWA_LOG_TOP="${INST_TOP}/logs" ; fi

ports_list=`grep 'oa_var="s_mwaTelnetPortNo"' $CONTEXT_FILE \
      |sed 's/^.*<\([A-Z_a-z0-9]*\).*oa_var[^>]*>[ ]*\([^<]*\)<.*$/\2/g'`

S_DISPLAY=`grep 'oa_var="s_display"' $CONTEXT_FILE \
      |sed 's/^.*<\([A-Z_a-z0-9]*\).*oa_var[^>]*>[ ]*\([^<]*\)<.*$/\1=\2; export \1;/g'`

ports_list=$(echo $ports_list|sed 's/,/ /g')

if [ "x${BANK_A}" = "x" ];then 
  BANK_A="$ports_list"
fi

case $command in
help)
  printf "Usage: \n  $0 [start|stop|stop_force|start_A|start_B] USERNAME/PASSWORD\n\n" ;;

start)
  printf "## Starting MWA telnet servers on following ports: $ports_list \n"
  stop_force_mwa_jre "$ports_list"
  cd $MWA_BIN_TOP
  for i in $ports_list
  do 
    ./mwactl.sh -mwatop $MWA_TOP $command $i 1> /dev/null 2>&1
    printf "## Started MWA telnet server on port: $i . Exit_code: $? \n"
  done
  nohup ./mwactl.sh start_dispatcher 1> /dev/null 2>&1 &
  printf "## MWA dispatcher has been started at [`date`]. Exit_code: $? \n"
  ;;
  
stop)
  printf "## Stopping (soft) MWA telnet services on following ports: $ports_list \n"
  cd $MWA_BIN_TOP
  for i in $(echo $ports_list $BANK_B )
  do 
    ./mwactl.sh -mwatop $MWA_TOP -login $login $command $i
  done
  ./mwactl.sh stop_dispatcher
  printf "## MWA dispatcher has been stopped at [`date`]. Exit_code: $? \n"
  ;;
stop_force)
  printf "## Stopping (force) MWA telnet services on following ports: $ports_list \n"
  cd $MWA_BIN_TOP
  stop_force_mwa_jre "$ports_list $BANK_B"
   ./mwactl.sh stop_dispatcher
  printf "## MWA dispatcher has been stopped at [`date`]. Exit_code: $? \n"
  ;;  
start_A)
  if [ "x${BANK_B}" = "x" ];then 
    printf "!! Please define variable BANK_B Before use start_A command.\n"
    exit 1
  fi
  do_check_mwa_dispatcher
  do_check_mwa_jre   "$BANK_A"
  [ $? = 0 ] && exit 0
  printf "## Switching MWA telnet servers from BANK B to BANK A\n"
  stop_soft_mwa_jre  "$BANK_B"
  printf "\n## Starting telnet servers BANK_A: $BANK_A \n"
  stop_force_mwa_jre "$BANK_A"
  cd $MWA_BIN_TOP
  for i in $BANK_A
  do 
    ./mwactl.sh -mwatop $MWA_TOP start $i 1> /dev/null 2>&1
    printf "## Started BANK_A port: $i. Exit_code: $?\n"
  done
  ;;
start_B)
  if [ "x${BANK_B}" = "x" ];then 
    printf "!! Please define variable BANK Before use start_B command.\n"
    exit 1
  fi
  do_check_mwa_dispatcher
  do_check_mwa_jre   "$BANK_B"
  [ $? = 0 ] && exit 0
  printf "## Switching MWA telnet servers from BANK A to BANK B\n"
  stop_soft_mwa_jre  "$BANK_A"
  printf "\n## Starting telnet servers BANK_B: $BANK_B \n"
  stop_force_mwa_jre "$BANK_B"
  cd $MWA_BIN_TOP
  for i in $BANK_B
  do
    ./mwactl.sh -mwatop $MWA_TOP start $i 1> /dev/null 2>&1
    printf "## Started BANK_B port: $i. Exit_code: $?\n"
  done
  ;;

switch_bank)
  if [ "x${BANK_B}" = "x" -o "x${BANK_A}" = "x" ] ;then 
    printf "!! Please define variable BANK(s) Before use switch_bank command.\n"
    echo "#> BANK_A=$BANK_A"
    echo "#> BANK_B=$BANK_B"
    exit 1
  fi
  do_check_mwa_dispatcher
  do_check_mwa_jre   "$BANK_A"
  if [ $? = 0 ] ;then
    printf "## Switching MWA telnet servers from BANK A to BANK B\n"
    S_TARGET_BANK="$BANK_B"
    S_CURRENT_BANK="$BANK_A"
    S_BANK_A_PROCESSES="$g_mwa_processes"
  else
    printf "## Switching MWA telnet servers from BANK B to BANK A\n"
    S_TARGET_BANK="$BANK_A"
    S_CURRENT_BANK="$BANK_B"
  fi
  do_check_mwa_jre   "$S_TARGET_BANK"
  if [ $? = 0 ];then
    S_BANK_B_PROCESSES="$g_mwa_processes"
    if [[ $S_BANK_B_PROCESSES -lt $S_BANK_A_PROCESSES ]];then
    printf "## Force shutdown and restart service with less numbers of processes: BANK_B\n"
    S_TARGET_BANK="$BANK_B"
    S_CURRENT_BANK="$BANK_A"
    else
    printf "## Force shutdown and restart service with less numbers of processes: BANK_A\n"
    S_TARGET_BANK="$BANK_A"
    S_CURRENT_BANK="$BANK_B"
    fi
  fi
  printf "\n## Soft stop services: $S_CURRENT_BANK \n"
  stop_soft_mwa_jre  "$S_CURRENT_BANK"
  printf "\n## Starting telnet servers: $S_TARGET_BANK \n"
  stop_force_mwa_jre "$S_TARGET_BANK"
  cd $MWA_BIN_TOP
  for i in $S_TARGET_BANK
  do
    ./mwactl.sh -mwatop $MWA_TOP start $i 1> /dev/null 2>&1
    printf "## Started port: $i. Exit_code: $?\n"
  done ;;
status)
  do_check_mwa_dispatcher
  do_check_mwa_jre   "$BANK_A $BANK_B"
  ;;
esac
printf "\n## MWA Control script completed at [`date`] Exit_code: $? \n"

