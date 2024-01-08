#!/bin/bash


 source_user=$1
 source_host=$2
 source_dir=$3
 target_dir=$4

 rsync_bin="/usr/bin/rsync"

 # Version for remsh
 # rsync_cmd="${rsync_bin} -rlptzv --delete --rsh=remsh --rsync-path=${rsync_bin}"
 # Version for ssh
 rsync_cmd="${rsync_bin} -rlptzv --delete --rsh=ssh --rsync-path=${rsync_bin}"
 ### rsync_cmd="${rsync_bin} -rlptzv"


 mkdir -p ${target_dir}
 cd ${target_dir}

 if [ ! -d ${target_dir} ]
 then
         echo "[`date`]: ERROR: target directory does not exist: ${target_dir}"
         exit 1
 fi

 if cd ${target_dir}
 then
         echo "[`date`]: BEGIN: sync ${source_user}@${source_host}:${source_dir} to ${target_dir}"
         ${rsync_cmd} ${source_user}@${source_host}:${source_dir}/ ${target_dir}
         echo "[`date`]: DONE: sync ${source_user}@${source_host}:${source_dir} to ${target_dir}"
 else
         echo "[`date`]: ERROR: cannot change to: ${target_dir}"
         exit 1
fi
