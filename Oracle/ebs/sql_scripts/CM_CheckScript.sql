REM #########################################################################
REM ## Purpose: Diagnostic Script for Concurrent Manager
REM ## Filename: ccm.sql
REM ## Cert: 10.7, 11, 11.5, 12.0
REM ## Note:
REM ## Usage: sqlplus apps/<passwd> @ccm.sql
REM ## Output: reqcheck.lst
REM ## Notes:
REM ## Enter value for request ID WHEN PROMPT
REM ##
REM ## $Id: request.sql, v 1.0 4/17/2002 10:22 nalbadin Exp $
REM #########################################################################

spool ccm.lst
prompt Step 1 Checking how many rows in FND_CONCURRENT_REQUEST. 

select count(*) from fnd_concurrent_requests;
prompt
-----------------------------------------

prompt Step 2 Checking how many rows in FND_CONCURRENT_PROCESSES table. 

select count(*) from fnd_concurrent_processes;
prompt
-----------------------------------------------


prompt Step 3 Checking sys.dual table which should have one and only one row.
select count(*) from sys.dual;

prompt If you have more than one row in sys.dual, please delete it

prompt sql> delete rownum from SYS.DUAL; 
Prompt rownum= the row number to delete
prompt
prompt
prompt
---------------------------------------------


prompt Step 4 Checking fnd_dual. There must be at lest one row:

select count(*) from fnd_dual;
prompt If there are no record selected,
prompt Update fnd_dual table to have at lest one record
prompt
----------------------------------------------

prompt Step 5 Checking the Internal Manager queue name "FNDICM" which should be=1

select concurrent_queue_id from fnd_concurrent_queues
where concurrent_queue_name='FNDICM';
prompt
----------------------------------------------

prompt Step 6 Checking for Active processes under the Internal Manager queue
prompt in fnd_concurrent_proceses table:
prompt
select a.concurrent_queue_name
, substr(b.os_process_id,0,10) "OS Proc"
, b.oracle_process_id "Oracle ID"
, b.process_status_code
from fnd_concurrent_queues a
, fnd_concurrent_processes b
where a.concurrent_queue_id=b.concurrent_queue_id
and a.concurrent_queue_name='FNDICM'
and b.process_status_code='A'
order by b.process_status_code; 

prompt If any rows found with process_status_code with value = 'A' (= Active) 
prompt The internal Manager will not start up ,so to avoide this issue 
prompt update these rows to have process_status_code value ='K'(terminated)
prompt
prompt
-----------------------------------------
prompt Step 7 Checking for Active processes under the Standard Manager queue
prompt in fnd_concurrent_proceses table:
prompt
select a.concurrent_queue_name
, substr(b.os_process_id,0,10) "OS Proc"
, b.oracle_process_id "Oracle ID"
, b.process_status_code
from fnd_concurrent_queues a
, fnd_concurrent_processes b
where a.concurrent_queue_id=b.concurrent_queue_id
and a.concurrent_queue_name='STANDARD'
and b.process_status_code='A'
order by b.process_status_code; 

prompt If any rows found with process_status_code with value = 'A' (= Active) 
prompt The internal Manager will not start up ,so to avoide this issue 
prompt update these rows to have process_status_code value ='K'(terminated)
prompt
prompt
------------------------------------------
prompt Step 8 Checking for Active processes under the Conflict Manager queue
prompt in fnd_concurrent_proceses table:
prompt
select a.concurrent_queue_name
, substr(b.os_process_id,0,10) "OS Proc"
, b.oracle_process_id "Oracle ID"
, b.process_status_code
from fnd_concurrent_queues a
, fnd_concurrent_processes b
where a.concurrent_queue_id=b.concurrent_queue_id
and a.concurrent_queue_name='FNDCRM'
and b.process_status_code='A'
order by b.process_status_code; 

prompt If any rows found with process_status_code with value = 'A' (= Active) 
prompt The internal Manager will not start up ,so to avoide this issue 
prompt update these rows to have process_status_code value ='K'(terminated)
prompt
prompt
---------------------------------------------------
prompt Step 9 Checking Actual and Target Processes for Internal Manager:
select MAX_PROCESSES,RUNNING_PROCESSES
from FND_CONCURRENT_QUEUES
where CONCURRENT_QUEUE_NAME='FNDICM';

prompt If the MAX_PROCESSES=RUNNING_PROCESSES that means the manager is UP.
prompt
prompt
--------------------------------------------------------

prompt Step 10 Checking Actual and Target Processes for the Standard Manager:
select MAX_PROCESSES,RUNNING_PROCESSES
from FND_CONCURRENT_QUEUES
where CONCURRENT_QUEUE_NAME='STANDARD';

prompt If the MAX_PROCESSES=RUNNING_PROCESSES that means the manager is UP.
prompt
prompt
---------------------------------------------------------
prompt Step 11 Checking Actual and Target Processes for Conflict Resolution Manager:
select MAX_PROCESSES,RUNNING_PROCESSES
from FND_CONCURRENT_QUEUES
where CONCURRENT_QUEUE_NAME='FNDCRM';

prompt If the MAX_PROCESSES=RUNNING_PROCESSES that means the manager is UP.
prompt
prompt
---------------------------------------------------------

Prompt Step 12 Checking if the control_code set to 'N':

select control_code from fnd_concurrent_queues
where control_code='N';
prompt
prompt If any rows selected, please update the table fnd_concurrent_queues:
prompt Update fnd_concurrent_queues set control_code = null 
prompt where control_code ='N';
PROMPT Update fnd_concurrent_queues set target_node = null;
PROMPT commit;
prompt
prompt
--------------------------------

PROMPT Step 13 Checking terminated processes:
PROMPT 
select count (*) from fnd_concurrent_requests
where status_code='T'; 
prompt
prompt If you have terminated processes run the following sql statement:
prompt
prompt SQL> Update fnd_concurrent_requests 
prompt set status_code = 'E', phase_code = 'C'
prompt where status_code = 'T';
prompt
------------------------------------------


prompt Step 14 Checking pending requests:

select count(*) from fnd_concurrent_requests
where status_code='P';
prompt If any rows selected please run the following sql statement:

prompt SQL> Update fnd_concurrent_requests 
prompt set status_code = 'E', phase_code = 'C'
prompt where status_code = 'P';
prompt
------------------------------------------------------
prompt Step 15 Checking Running processes:
prompt
select count (*) from fnd_concurrent_requests
where status_code='R'; 
prompt
prompt If you have Running processes run the following sql statement
prompt SQL> Update fnd_concurrent_requests 
prompt set status_code = 'E', phase_code = 'C'
prompt where status_code = 'R';
prompt
------------------------------------------

prompt Step 16 Checking the PMON method, which should be set to LOCK:
prompt
select profile_option_id , profile_option_value
from FND_PROFILE_OPTION_VALUES
where profile_option_id= (select profile_option_id
from FND_PROFILE_OPTIONS
where profile_option_name='CONC_PMON_METHOD');
prompt
prompt If the PROFILE_OPTION_VALUE was't LOCK please
prompt Reset PMON to LOCK by running afimpmon.sql script(The manager should be down) 

prompt 1-At UNIX command prompt: 

prompt 2-cd $FND_TOP/sql 

prompt 3-Log into SQLPLUS as apps/ 

prompt SQL> @afimpmon.sql
prompt prompt1:dual
prompt prompt2:LOCK (LOCK MUST BE ALL UPPERCASE) 

prompt For Oracle Applications Release 11.5 and 12.0, when you check the PMON
prompt Method you may get no rows selected which is normal,
prompt because in apps 11.5 and 12.0 the PMON Method is hard coded to Lock at
prompt the Operating System level.
prompt
prompt
-------------------------------------------------------

prompt Step-17 Checking how many FNDLIBR processes are running:
prompt -For Unix :From unix command prompt $ ps -ef |grep -i fndlibr
prompt If you have any FNDLIBR processes running,please kill them before
prompt starting or shuting down the internal manager
prompt
prompt
prompt -For NT, through Task Manager, check the entries under the Processes tab
for FNDLIBR.exe processes.
prompt If there are any, Highlight and click [End Process] button to kill processes

prompt
----------------------------------------------------------

prompt Step-18 Checking how many "FND_%"invalid objects:

select substr(owner,1, 12) owner, substr(object_type,1,12) type,
substr(status,1,8) status, substr(object_name, 1, 25) name
from dba_objects
where object_name like 'FND_%'
and status='INVALID';

prompt If you have any invalied objects please see Note 113947.1

prompt
--------------------------------------------------------------

prompt Step-19-How to find the PID in the O/S for request_id:
prompt If you do not like to check this enter any number then click Enter to Exit

select r.request_id, p.os_process_id
from FND_CONCURRENT_REQUESTS r,FND_CONCURRENT_PROCESSES p
where r.controlling_manager = p.concurrent_process_id
and request_id=&request_id;

prompt
prompt Please upload the "ccm.lst" output to Support, Thanks.
prompt
spool off