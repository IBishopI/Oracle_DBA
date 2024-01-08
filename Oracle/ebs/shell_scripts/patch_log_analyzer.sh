#!/bin/sh
#######################################################
# Ver: 20140505
#######################################################
# 20130423 Added backup/local version comparison (for post_patch.csv)
# 20140505 remove _BALANCE
#######################################################

# generate csv file with local and backup versions side by side
#######################################################
do_post_patch_scv(){
    s_scv_name=${s_patch_num}_${TWO_TASK}_post_patch.csv
    echo 'Patch Number,File Name,Backup Version,Local version' > ${s_scv_name}

    for s_backup_file in $( find ${s_patch_num}/backup/$TWO_TASK -type f )
    do
      s_output=$( echo "${s_backup_file}" | \
      perl -ne '
      m#^(\d+)/([^/]+/){3}([^/]+)(\S*?)([^/]+\.\S+)$# and
      print "
        s_server=$2
        s_top=$3
        s_path=$4
        s_file_name=$5
        "
      ')
      eval ${s_output}

      # check values
      [ "x${s_top}"       = "x" ] || \
      [ "x${s_path}"      = "x" ] || \
      [ "x${s_file_name}" = "x" ] && continue

      s_top=$( echo "${s_top}_top" | tr 'a-z' 'A-Z' )
      s_file=$( echo "${s_top}/${s_path}/${s_file_name}" | perl -pe 's#//#/#g' )

      s_top=$( eval "echo \$${s_top}" )
      s_local_file="${s_top}/${s_path}/${s_file_name}"

      s_backup_version=$(
      adident Header  ${s_backup_file} | grep "${s_file_name%.*}" | \
      perl -ne 'm/\$Header:?\s+(\S+\.\S+)\s+([\d\.]+)/ and print "$2\n"' | head -1
      )

      s_local_version=$(
      adident Header  ${s_local_file%.*}* | grep "${s_file_name%.*}" | \
      perl -ne 'm/\$Header:?\s+(\S+\.\S+)\s+([\d\.]+)/ and print "$2\n"' | head -1
      )

      echo "${s_patch_num},${s_file},${s_backup_version},${s_local_version}" >> ${s_scv_name}
    done
}


# Main
#######################################################
if [ "x$1" == "x" ]; then echo "Error: provide patch number"; exit 1; fi

s_patch_num=$1
s_log="$APPL_TOP/admin/$TWO_TASK/log/adpatch_${s_patch_num}${2}.log"
s_lgi="$APPL_TOP/admin/$TWO_TASK/log/adpatch_${s_patch_num}${2}.lgi"
# remove _BALANCE (shared appl_top)
TWO_TASK=${TWO_TASK%_BALANCE}

perl -ne 'm/Copying.+\/(\w+\.\w+)/ and print "$1\n"' ${s_lgi} >${s_patch_num}_${TWO_TASK}_files_copied.txt
perl -ne 'm/(\w+\.pll)/ and print "$1\n"'            ${s_log} >${s_patch_num}_${TWO_TASK}_pll_compiled.txt
perl -ne 'm/(\w+\.fmx)/ and print "$1\n"'            ${s_log} >${s_patch_num}_${TWO_TASK}_fmb_compiled.txt
perl -ne 'm#(\S+\s+\[(\d+\.?)+ -> (\d+\.?)+\])# and print "$1\n"' ${s_log} >${s_patch_num}_${TWO_TASK}_jcopy_copied.txt

do_post_patch_scv

zip -r ${s_patch_num}_${TWO_TASK}_patch_impact.zip \
  ${s_patch_num}/backup/${TWO_TASK} \
  ${s_patch_num}_${TWO_TASK}_*ed.txt \
  ${s_patch_num}_${TWO_TASK}_post_patch.csv \
  ${s_log} ${s_lgi}


echo "#"
echo "# Following files have been generated:"
ls -1 ${s_patch_num}_${TWO_TASK}_*.*
