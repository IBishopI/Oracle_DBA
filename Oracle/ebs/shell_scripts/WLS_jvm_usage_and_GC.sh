#!/bin/bash
#################################################################
## Weblogic JVM heap usage and Garbage collection script
##
## Created by: Boris Holovko
##
## Date: 12/28/2016 07:20
#################################################################
v_java_bin=$(dirname `ps -fu $LOGNAME | grep '/bin/java'| grep -v grep | head -1| awk '{print $8}'`)
$v_java_bin/jcmd | grep 'weblogic.'| awk '{print $1}'| while read -r line ; do
echo "------------------------------"
echo "$($v_java_bin/jcmd | grep 'weblogic.' |grep $line |awk '{print $2}') JVM PID: $line"
echo "------------------------------"
# Calculate current heap size
gc=$($v_java_bin/jstat -gc $line | tail -1 | sed -e 's/[ ][ ]*/ /g')
set -- $gc
eu=$(expr "${6}" : '\([0-9]\+\)')
ou=$(expr "${8}" : '\([0-9]\+\)')
heap=$(($eu + $ou))
echo "Current Heap Size: $heap KB"
# Calculate maximum heap size
gccapacity=$($v_java_bin/jstat -gccapacity $line | tail -1 | sed -e 's/[ ][ ]*/ /g')
set -- $gccapacity
ygcmx=$(expr "${2}" : '\([0-9]\+\)')
ogcmx=$(expr "${8}" : '\([0-9]\+\)')
heapmax=$(($ygcmx + $ogcmx))
echo "Max Heap Size: $heapmax KB"
# Calculate usage ratio
echo "Usage ratio:  $((($heap*100) / $heapmax)) %"
echo -e "\nPerforming GC...."
$v_java_bin/jcmd $line GC.run
v_date=`date +%H":"%M":"%S`
echo -e "DONE: $v_date\n\nRe-checking usage ..."
gc=$($v_java_bin/jstat -gc $line | tail -1 | sed -e 's/[ ][ ]*/ /g')
set -- $gc
eu=$(expr "${6}" : '\([0-9]\+\)')
ou=$(expr "${8}" : '\([0-9]\+\)')
heap=$(($eu + $ou))
gccapacity=$($v_java_bin/jstat -gccapacity $line | tail -1 | sed -e 's/[ ][ ]*/ /g')
set -- $gccapacity
ygcmx=$(expr "${2}" : '\([0-9]\+\)')
ogcmx=$(expr "${8}" : '\([0-9]\+\)')
heapmax=$(($ygcmx + $ogcmx))
echo "Usage ratio:  $((($heap*100) / $heapmax)) %"
echo -e "------------------------------\n\n"
done