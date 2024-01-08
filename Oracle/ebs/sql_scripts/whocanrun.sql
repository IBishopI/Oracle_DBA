REM     
REM     whocanrun.sql
REM     Paul Ferguson
REM     1/21/99
REM
REM     List the responsibilities that can run a given concurrent program
REM
REM     Usage:  sqlplus apps/apps @whocanrun <concurrent program name>
REM     or:     sqlplus apps/apps @whocanrun <concurrent program short name>
REM
REM     Implemented remark 64545.1 to modify script for use with 11i
REM     changed to use fnd_concurrent_programs_vl, and fnd_responsibility_vl
REM     in place of fnd_concurrent_programs, and fnd_responsibility.
REM


set verify off
set pagesize 1000

column RN               format A40 heading "Responsibility Name"

prompt
prompt &1 can be run by:

SELECT          responsibility_name RN
FROM            fnd_request_groups frg,
                fnd_request_group_units frgu,
                fnd_concurrent_programs_vl fcpv,
                fnd_responsibility_vl frv
WHERE           frgu.request_unit_type = 'P'
AND             (UPPER(fcpv.concurrent_program_name) = UPPER('&1')
                OR
                UPPER(fcpv.user_concurrent_program_name) = UPPER('&1'))
AND             frgu.request_group_id = frg.request_group_id
AND             frgu.request_unit_id = fcpv.concurrent_program_id
AND             frv.request_group_id = frg.request_group_id
ORDER BY        responsibility_name 
/