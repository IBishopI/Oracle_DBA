-- This script checks 4 situations for current running concurrent requests
-- 1. Current running concurrent requests
-- 2. Normal running concurrent request with database sessions
-- 3. Running concurrent requests with NO database sessions (status need to be reset)
-- 4. Concurrent requests has been cancelled but database session is still running, session need to be cancelled.



define outfile=&1
column request_id format 9999999
column start_time format a20
column end_time format a20
column requestor format a10
column program format a40

set pagesize 100 
set linesize 150
set verify off
set feedback on
set heading off
spool &outfile
Prompt Current running concurrent request
Prompt ==============================================

select request_id||' '||substr(program,1,50)||': '||to_char(actual_start_date,'mm/dd/yyyy hh24:mi:ss')||
' '||
  round((sysdate - actual_start_date)*60*24)||' Minues '||
  requestor||' '|| status_code             
  from  apps.fnd_conc_requests_form_v
  where 
  phase_code = 'R'
  order by  sysdate - actual_start_date desc;

column action format a20
column module format a20
column sid_serial format a15
column duration format a10
column requestor format a15
column req format a40

Prompt Normal running concurrent request with database sessions
Prompt ==============================================
select Request_id||': '||substr(cr.program,1,30) req, Requestor,v.sid||','||v.serial# sid_serial,
floor(last_call_et/3600)||':'||
        floor(mod(last_call_et,3600)/60)||':'||
        mod(mod(last_call_et,3600),60) duration
from v$session v, v$process p, apps.fnd_conc_requests_form_v cr
where v.type!='BACKGROUND' 
--and v.status='ACTIVE'
and v.action='Concurrent Request'
and v.paddr=p.addr
and p.spid=cr.ORACLE_PROCESS_ID
and cr.phase_code='R'
order by last_call_et
/

Prompt Running concurrent requests with NO database sessions
Prompt You May need to kill these sessions
Prompt Verify the status code first, if it is 'W', and duration is short, do not kill the session
Prompt ==============================================
select request_id||': '||substr(cr.program,1,30) req, Requestor,
trunc((sysdate-actual_start_date)*24)||':'||round(mod((sysdate-actual_start_date)*24*60,60))||
':'||round(mod((sysdate-actual_start_date)*24*60*60,60)) duration,cr.status_code
from apps.fnd_conc_requests_form_v cr
where phase_code='R'
and oracle_process_id not in
(select spid from v$process p, v$session s
where s.paddr=p.addr and s.action='Concurrent Request')
/

Prompt Runaway database sessions
Prompt The requests have been cancelled but the database session is still running
Prompt Verify the status code first, if it is 'X', then the request already cancelled
Prompt ==============================================
select request_id||': '||substr(cr.program,1,30) req,requestor,
v.sid||','||v.serial# sid_serial,
floor(last_call_et/3600)||':'||
        floor(mod(last_call_et,3600)/60)||':'||
        mod(mod(last_call_et,3600),60) duration,
cr.status_code
from v$session v, v$process p, apps.fnd_conc_requests_form_v cr
where v.type!='BACKGROUND' and v.status='ACTIVE'
and v.action='Concurrent Request'
and v.paddr=p.addr
and p.spid=cr.ORACLE_PROCESS_ID
and cr.phase_code='C'
and cr.status_code in ('X','D','E')
/
spool off
--exit


