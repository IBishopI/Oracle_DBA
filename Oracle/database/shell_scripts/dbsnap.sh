#!/bin/ksh
#Add to scrlst
#==============================================================================
# Script name: dbsnap
# Abstract   : Creates a database snapshot for use with clones and backups
#
# Created    : 12/08/10   Last Modified: 06/17/15   Author: Michael Jenkins
#==============================================================================
# Description:
#    Creates a volume snapshot which includes the current redo log and a
#  'create control file' script.  The database is not actually taken down for
#  this exercise since the clone script doesn't care.  This script was adapted
#  from the 'mstr_reboot' script.
#------------------------------------------------------------------------------
# Usage: dbsnap [database_sid] [snap_type]
#
#    [?]             Gives the syntax for the script.
#    [-?]            Provides help by listing the script's documentation.
#    [database_sid]  Database SID.  Assumed to match the lower-case of the
#                    volume name.  All SIDs supplied will be automatically
#                    converted to upper-case.
#    [snap_type]     Optional snap prefix: 'backup', 'cold', 'hot'; the
#                    default is 'hot'.  A standard date/time suffix will be
#                    added to non-custom types.  If a custom type is supplied,
#                    the snapshot name will match the custom name.
#
# end_usage_flag
#------------------------------------------------------------------------------
# Examples: dbsnap BAPRDTX cold
#           dbsnap BAPRDOK backup
#           dbsnap BAPRDOK
#           dbsnap BAPRDKS baprdks_before_rate_chg
#
# Notes:    1) ERRORLEVELS set on exit include:
#              0  The script ran successfully
#              1  Syntax error
#           2) If the snapshot already exists, it will be deleted and
#              recreated.
#           3) This script is designed to work with Oracle 10g and above.
#==============================================================================
# end_documentation_flag

CURRENT_SCRIPT="$(echo "$_" | awk -F \/ '{print $NF}') $*"

# Include the storage libary
. /usr/local/sys/bin/svc.lib

DEBUG=false

if $DEBUG
then
  set -x
fi

#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------
# Determine where to look for dependent scripts
if [[ "`dirname $0`" = "." ]]
then
  BINDIR=`pwd`
else
  BINDIR=`dirname $0`
fi

DBA_ETC="/usr/local/dba/etc"

#------------------------------------------------------------------------------
# Local Variables
#------------------------------------------------------------------------------

DASH_LINE="-----------------------------------------------------------------------------"
DATE_TIME="$(date +"%m%d%y_%H%M%S")"
MAIL_FILE="${BINDIR}/dbsnap.mail"
EQUL_LINE="============================================================================="
HOST="$(hostname | awk -F '.' '{print $1}')"
RETRY_MAX=4
SLEEP=15
SCRIPT="$0"
SVC_CMD_FILE="/usr/local/dba/log/dbsnap.svc"
SVC_CALLING_SCRIPT="dbsnap"

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------

function show_usage {
  if $DEBUG
  then
    set -x
  fi

  cd $BINDIR

  echo ""
  awk '{print substr($0,2)}' $SCRIPT |  awk '{if ($1 == "Usage:") p=1; if ($1 == "end_usage_flag") p=0; if (p == 1) print $0}'


  echo ""
  awk '{print substr($0,2)}' $SCRIPT |  awk '{if ($1 == "Usage:") p=1; if ($1 == "end_usage_flag") p=0; if (p == 1) print $0}'
  echo ""
}

function show_documentation {
  if $DEBUG
  then
    set -x
  fi

  cd $BINDIR

  grep -v "end_usage_flag" $SCRIPT | awk '{print substr($0,3)}' | awk '{if ($1 == "Script") p=1; if ($1 == "Modification" && $2 == "History") p=0; if (p == 1) print $0}' | more
}

function mail_results {
  if $DEBUG
  then
    set -x
  fi

  typeset SUBJECT="$1"
  typeset REPLY="$(id -n -u)@$(hostname)"
  typeset MAIL_RESULTS=${ACTIVITY_LOG}.tmp

  # Go back if no mail file is found
  if [[ ! -f $MAIL_FILE ]]
  then
    return
  fi

  # Convert the contents to a list
  NAMES="$(grep -v "^#" $MAIL_FILE | awk '{if (o == "") o=$0; else o=o " " $0} END {printf o}')"

  mhmail -subject "$SUBJECT" -from "$REPLY" $NAMES < $ACTIVITY_LOG

  if [[ $? -eq 0 ]]
  then
    echo "Mail to '$NAMES' succeeded." > $MAIL_RESULTS
  else
    echo "Mail to '$NAMES' failed." > $MAIL_RESULTS
  fi

  # Add the mail results to the main log
  cat $MAIL_RESULTS >> $ACTIVITY_LOG

  rm $MAIL_RESULTS 1>/dev/null 2>&1
}

function clean_logs {
  if $DEBUG
  then
    set -x
  fi

  find /usr/local/dba/log -name "dbsnap*log*" -mtime +30 -exec rm {} \;
}


}

function remove_files {
  if $DEBUG
  then
    set -x
  fi

  typeset FILE="$1"
  typeset CNT=0
  typeset MAX=10

  while true
  do
    ((CNT+=1))

    if $DEBUG
    then
      rm $FILE
    else
      rm -f $FILE
    fi

    if [[ ! -f $FILE ]] || [[ $CNT -gt $MAX ]]
    then
      return
    fi

    sleep ${SLEEP}
  done
}

function set_ora_env {
  if $DEBUG
  then
    set -x
  fi

  export ORACLE_HOME="$(awk -F ':' '{if ($1 == "'$ORACLE_SID'") print $2}' /etc/oratab)"
  export PATH="$PATH:${ORACLE_HOME}/bin"
  export ORAENV_ASK=NO
  . ${ORACLE_HOME}/bin/oraenv -s
  export TNS_ADMIN=${ORACLE_HOME}/network/admin
  export LOCALBIN=/usr/lbin
  export LPATH=/lib:/usr/lib:${ORACLE_HOME}/lib
  export LD_LIBRARY_PATH=${ORACLE_HOME}/lib:/usr/lpp/cobol/coblib
  export LLDPATH=${ORACLE_HOME}/lib
}

function create_snap {
  if $DEBUG
  then
    set -x
  fi

  set_ora_env

  typeset CNT=0
  while true

  typeset CNT=0
  while true
  do
    ((CNT+=1))
    echo "Getting current redo log, attempt #${CNT}." | tee -a ${ACTIVITY_LOG}
    $ORACLE_HOME/bin/sqlplus -s '/ as sysdba' <<***EOF***
      set hea off ver off feed off termout off
      alter system checkpoint;
      spool ${CURGRP}
      select to_char(current_group#) from v\$Instance_log_group;
      exit;
***EOF***
    REDO_FILE="redo0`cat ${CURGRP} 2>/dev/null | sed /SQL/d | sed '/^$/d' | sed 's/[ \t]*$//'`.log"
    echo $REDO_FILE > ${DBF_DIR}/${REDO_NAME}_redo.txt
    chown oracle:dba ${DBF_DIR}/${REDO_NAME}_redo.txt

    if [[ "$(cat ${DBF_DIR}/${REDO_NAME}_redo.txt 2>/dev/null)" != "" ]]
    then
      echo "Current redo log number saved." | tee -a ${ACTIVITY_LOG}
      break
    elif [[ $CNT -gt ${RETRY_MAX} ]]
    then
      echo "Current redo log number not saved." | tee -a ${ACTIVITY_LOG}
      break
    fi

    sleep ${SLEEP}
  done

  CNT=0
  while true
  do
    ((CNT+=1))
    echo "Generating controlfile for ${ORACLE_SID}, attempt #${CNT}." | tee -a ${ACTIVITY_LOG}
    $ORACLE_HOME/bin/sqlplus -s '/ as sysdba' <<***EOF***
      set hea off ver off feed on termout off
      spool ${ACTIVITY_LOG} append
      alter database backup controlfile to trace as '${DBF_DIR}/${CTRL_NAME}_ctrl.sql';
      exit;
***EOF***

    if [[ "$(cat ${DBF_DIR}/${CTRL_NAME}_ctrl.sql 2>/dev/null)" != "" ]]
    then
      echo "Controlfile SQL saved." | tee -a ${ACTIVITY_LOG}
      break
    elif [[ $CNT -gt ${RETRY_MAX} ]]
    then
      echo "Controlfile SQL not saved." | tee -a ${ACTIVITY_LOG}
      break
    fi

    sleep ${SLEEP}
  done

  echo "Running 'sync'." | tee -a ${ACTIVITY_LOG}
  sync

  if ss_found $SNAP_NAME
  then

  if ss_found $SNAP_NAME
  then
    if ss_delete $SNAP_NAME
    then
      echo "Delete of existing snapshot '$SNAP_NAME' successful." | tee -a ${ACTIVITY_LOG}
    else
      echo "Delete of existing snapshot '$SNAP_NAME' failed." | tee -a ${ACTIVITY_LOG}
    fi
  fi


  CNT=0
  while true
  do
    ((CNT+=1))
    echo "Creating snapshot '$SNAP_NAME', attempt #${CNT}." | tee -a ${ACTIVITY_LOG}

    if ss_create $VOLUME $SNAP_NAME
    then
      echo "Create of snapshot '${SNAP_NAME}' successful." | tee -a ${ACTIVITY_LOG}
      break
    else
      echo "Create of snapshot '${SNAP_NAME}' failed." | tee -a ${ACTIVITY_LOG}
    fi

    if [[ $CNT -gt ${RETRY_MAX} ]]
    then
      echo "Creation of snapshot ${SNAP_NAME} abandoned." | tee -a ${ACTIVITY_LOG}
      EXIT_CODE=1
      break
    fi

    sleep ${SLEEP}
  done
}

#------------------------------------------------------------------------------
# Main Program
#------------------------------------------------------------------------------

# Verify the user running this script.
if [ "$(id -n -u)" != "oracle" ]
then
  clear
  echo ""
  echo "Error: Only the 'oracle' user can run this script." >&2
  echo ""
  show_usage
fi

if ! ss_host_found
then
  clear
  echo "Error: Connection to SVC '$SVC' failed."
  show_usage
  exit 1
fi

case "$1"


case "$1"
in
 '-?')
    clear
    show_documentation
    exit
  ;;

  '?')
    clear
    show_usage
    exit
  ;;

  *)
    # Convert to upper-case
    ORACLE_SID="$(echo "$1" | tr 'a-z' 'A-Z')"
    # Convert to lower-case
    SNAP_TYPE="$(echo "$2" | tr 'A-Z' 'a-z')"
    VOLUME="$(echo "$ORACLE_SID" | tr 'A-Z' 'a-z')"

  ;;
esac

# Parse command line options, setting variables when flags are found
if [ $# -lt 1 ];
then
   echo ""
   echo "Error: Incorrect number of arguments specified."
   echo ""
   show_usage
   echo ""
   exit 1;
fi

# Provide a default
if [[ "$SNAP_TYPE" = "" ]]
then
  SNAP_TYPE="hot"
fi

if [[ "$SNAP_TYPE" = "hot" || "$SNAP_TYPE" = "cold" || "$SNAP_TYPE" = "backup" ]]
then
  # Change to proper case
  PREFIX="$(echo "$SNAP_TYPE" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')"
fi

if [[ $(ps -ef | grep -c pmon_${ORACLE_SID}) -lt 2 ]]
then
   echo ""
   echo "Warning: Database '$ORACLE_SID' is not up."
   echo ""
   show_documentation
   echo ""
   exit 1;
fi

# Recognize a custom snap name


# Recognize a custom snap name
if [[ "${SNAP_TYPE}" != "hot" ]] && \
   [[ "${SNAP_TYPE}" != "cold" ]] && \
   [[ "${SNAP_TYPE}" != "backup" ]]
then
  SNAP_NAME="$SNAP_TYPE"
  SNAP_TYPE="custom"
fi

if [[ "$SNAP_TYPE" = "custom" ]]
then
  echo "Custom name '$SNAP_NAME' will be used." | tee -a ${ACTIVITY_LOG}

  CTRL_NAME="${VOLUME}"
  REDO_NAME="${VOLUME}"
else
  CTRL_NAME="${PREFIX}_${VOLUME}_${DATE_TIME}"
  SNAP_NAME="${PREFIX}_${VOLUME}_${DATE_TIME}"
  REDO_NAME="${PREFIX}_${VOLUME}_${DATE_TIME}"
fi

CURGRP="/var/tmp/${SNAP_NAME}.txt"

if [[ "$PREFIX" != "" ]]
then
  ACTIVITY_LOG="/usr/local/dba/log/dbsnap_${PREFIX}_${VOLUME}.log.${DATE_TIME}"
else
  ACTIVITY_LOG="/usr/local/dba/log/dbsnap_${VOLUME}.log.${DATE_TIME}"
fi

DBF_DIR="/${VOLUME}/oradata"
TEMPFILE="/var/tmp/dbsnap_${PREFIX}_${VOLUME}.tmp"

echo ${EQUL_LINE} | tee ${ACTIVITY_LOG}
echo "Execution of '$CURRENT_SCRIPT' started on $(date '+%D %T')" | tee -a ${ACTIVITY_LOG}
echo ${DASH_LINE} | tee -a ${ACTIVITY_LOG}
echo "" | tee -a ${ACTIVITY_LOG}

# Delete old files
if [[ "${SNAP_TYPE}" = "hot" ]] || \
   [[ "${SNAP_TYPE}" = "cold" ]] || \
   [[ "${SNAP_TYPE}" = "backup" ]]
then
  SN_BARE="$(echo "$SNAP_NAME" | awk -F \_ '{print $1 FS $2 FS}')"
  rm /var/tmp/${SN_BARE}*.txt 1>/dev/null 2>&1
  rm ${DBF_DIR}/${SN_BARE}*.txt 1>/dev/null 2>&1
  rm ${DBF_DIR}/${SN_BARE}*.sql 1>/dev/null 2>&1
else
  rm -f /var/tmp/${REDO_NAME}_redo.txt ${DBF_DIR}/${CTRL_NAME}_ctrl.sql ${DBF_DIR}/${REDO_NAME}_redo.txt 1>/dev/null 2>&1
fi

create_snap

echo "" | tee -a ${ACTIVITY_LOG}
echo ${DASH_LINE} | tee -a ${ACTIVITY_LOG}
echo "Execution of '$CURRENT_SCRIPT' finished on $(date '+%D %T')" | tee -a ${ACTIVITY_LOG}
echo ${EQUL_LINE} | tee -a ${ACTIVITY_LOG}

echo ${EQUL_LINE} | tee -a ${ACTIVITY_LOG}

if [[ "$PREFIX" != "None" ]]
then
  mail_results "Alert: $PREFIX Database Snap of $ORACLE_SID on ${HOST}"
else
  mail_results "Alert: Database Snap of $ORACLE_SID on ${HOST}"
fi

clean_logs

#------------------------------------------------------------------------------
# Exit code.
#------------------------------------------------------------------------------
exit ${EXIT_CODE}
~

