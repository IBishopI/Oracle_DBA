----------------------------------------------------------------------------------------
--
-- analyzepending.sql
-- Analyze all pending requests
--
--
-- $Id: analyzepending.sql,v 1.1 2000/03/16 01:10:50 pferguso Exp $
--
-- $Log: analyzepending.sql,v $
-- Revision 1.1 2000/03/16 01:10:50 pferguso
-- Initial import into CVS
-- 
--
----------------------------------------------------------------------------------------


set serveroutput on
set feedback off
set verify off
set heading off
set timing off


DECLARE

FUNCTION chkwaiting(rid number) return varchar2 AS

parent_id number(15);

BEGIN

SELECT nvl(parent_request_id, -1)
INTO parent_id
FROM fnd_conc_req_summary_v
WHERE request_id = rid;
IF parent_id = -1 THEN
return('Waiting, but unable to find a parent request for this request');
ELSE
return('Waiting on parent request: ' || to_char(parent_id));
END IF;

END chkwaiting;


PROCEDURE manager_check (req_id in number,
mgr_defined out boolean,
mgr_active out boolean,
mgr_workshift out boolean,
mgr_running out boolean) is

cursor mgr_cursor (rid number) is
select running_processes, max_processes,
decode(control_code,
'T','N', -- Abort
'X','N', -- Aborted
'D','N', -- Deactivate
'E','N', -- Deactivated
'Y') active
from fnd_concurrent_worker_requests
where request_id = rid
and not((queue_application_id = 0)
and (concurrent_queue_id in (1,4)));


begin
mgr_defined := FALSE;
mgr_active := FALSE;
mgr_workshift := FALSE;
mgr_running := FALSE;

for mgr_rec in mgr_cursor(req_id) loop
mgr_defined := TRUE;
if (mgr_rec.active = 'Y') then
mgr_active := TRUE;
if (mgr_rec.max_processes > 0) then
mgr_workshift := TRUE;
end if;
if (mgr_rec.running_processes > 0) then
mgr_running := TRUE;
end if;
end if;
end loop;

END manager_check;

FUNCTION chknormal(rid number) return varchar2 AS

mgr_defined boolean;
mgr_active boolean;
mgr_workshift boolean;
mgr_running boolean;

BEGIN

manager_check(rid, mgr_defined, mgr_active, mgr_workshift, mgr_running);

IF mgr_defined = FALSE OR mgr_active = FALSE OR mgr_workshift = FALSE OR mgr_running = FALSE THEN
return('No managers are running that can run this request');
END IF;

return('Pending Normal');

END chknormal;

FUNCTION analyzereq(rid number) return varchar2 AS

reqinfo fnd_concurrent_requests%ROWTYPE;
qcf fnd_concurrent_programs.queue_control_flag%TYPE;
v_enabled_flag fnd_concurrent_programs.enabled_flag%TYPE;
conc_app_id fnd_concurrent_requests.program_application_id%TYPE;
conc_id fnd_concurrent_requests.concurrent_program_id%TYPE;
conc_cd_id fnd_concurrent_requests.cd_id%TYPE;
traid fnd_concurrent_requests.program_application_id%TYPE;
trcpid fnd_concurrent_requests.concurrent_program_id%TYPE;
ireqid fnd_concurrent_requests.request_id%TYPE;
pcode fnd_concurrent_requests.phase_code%TYPE;
scode fnd_concurrent_requests.status_code%TYPE;
run_alone_flag varchar2(1);
r varchar2(100);

CURSOR c_inc IS
SELECT to_run_application_id, to_run_concurrent_program_id
FROM fnd_concurrent_program_serial
WHERE running_application_id = conc_app_id
AND running_concurrent_program_id = conc_id;

CURSOR c_ireqs IS
SELECT request_id, phase_code, status_code
FROM fnd_concurrent_requests
WHERE phase_code = 'R'
AND program_application_id = traid
AND concurrent_program_id = trcpid
AND cd_id = conc_cd_id;

BEGIN

SELECT * 
INTO reqinfo
FROM fnd_concurrent_requests
WHERE request_id = rid;

-- could be a queue control request
SELECT queue_control_flag
INTO qcf
FROM fnd_concurrent_programs
WHERE concurrent_program_id = reqinfo.concurrent_program_id
AND application_id = reqinfo.program_application_id;

IF qcf = 'Y' THEN
return('Queue control request. Will be run by the ICM on its next sleep cycle');
END IF;


-- could be scheduled
IF reqinfo.requested_start_date > sysdate THEN
return('Scheduled to run on ' || to_char(reqinfo.requested_start_date, 'DD-MON-RR HH24:MI:SS'));
END IF;

-- could be on hold
IF reqinfo.hold_flag = 'Y' THEN
return('On hold');
END IF;

-- could be disabled
select enabled_flag into v_enabled_flag
from fnd_concurrent_programs
where concurrent_program_id = reqinfo.concurrent_program_id
and application_id = reqinfo.program_application_id;
IF v_enabled_flag = 'N' THEN
return('Concurrent program is disabled');
END IF;

-- advanced schedule
IF reqinfo.status_code = 'P' THEN
return('Scheduled to be run by the Advanced Scheduler');
END IF;

-- check queue_method_code
IF reqinfo.queue_method_code NOT IN ('I','B') THEN
return('Bad queue_method_code of: ' || reqinfo.queue_method_code);
END IF;

-- waiting status
IF reqinfo.status_code IN ('A', 'Z') THEN
return chkwaiting(reqinfo.request_id);
END IF;

-- check for runalones
SELECT runalone_flag
into run_alone_flag
from fnd_conflicts_domain d
where d.cd_id = reqinfo.cd_id;

IF (run_alone_flag = 'Y') THEN
return('Waiting on a run-alone request');
END IF;

-- Normal status
IF reqinfo.status_code = 'I' THEN
return chknormal(reqinfo.request_id);
END IF;

-- unconstrained requests
IF reqinfo.queue_method_code = 'I' THEN
-- bad status
IF reqinfo.status_code = 'Q' THEN
return('Unconstrained Standby request. Will not be run');
END IF;

return('Odd status of: ' || reqinfo.status_code);

END IF;

-- constrained requests
IF reqinfo.queue_method_code = 'B' THEN

-- standby, check reasons for waiting
IF reqinfo.status_code = 'Q' THEN

-- incompatible programs
SELECT program_application_id, concurrent_program_id, cd_id
INTO conc_app_id, conc_id, conc_cd_id
FROM fnd_concurrent_requests
WHERE request_id = reqinfo.request_id;

FOR progs in c_inc LOOP

traid := progs.to_run_application_id;
trcpid := progs.to_run_concurrent_program_id;

OPEN c_ireqs;
LOOP

FETCH c_ireqs INTO ireqid, pcode, scode;
EXIT WHEN c_ireqs%NOTFOUND;
return('Waiting on incompatible request ' || ireqid || ' phase=' || pcode || ' status=' || scode);

END LOOP;
CLOSE c_ireqs;


END LOOP;



-- single threaded
IF reqinfo.single_thread_flag = 'Y' THEN
return('Single-threaded request. Waiting on other requests for this user.');
END IF;

-- request limit
IF reqinfo.request_limit = 'Y' THEN
return('Concurrent: Active Request Limit is set. Waiting on other requests for this user.');
END IF;


END IF;

-- well, could be released, but waiting on a manager
r := chknormal(reqinfo.request_id);
IF substr(r, 1) = 'N' THEN
return r;
END IF;

-- could be just waiting on the CRM
return('Pending Standby, probably waiting on the CRM');

END IF;

-- give up
return('No idea');

END analyzereq;

PROCEDURE analyzeall AS

cnt number := 1;

CURSOR c_reqs IS
SELECT request_id FROM fnd_concurrent_requests
WHERE phase_code = 'P'
ORDER BY request_id;

BEGIN
FOR rid in c_reqs LOOP
DBMS_OUTPUT.PUT_LINE('Request' || ': ' || rid.request_id || ': ' || analyzereq(rid.request_id));
cnt := cnt + 1;
END LOOP;

END analyzeall;





BEGIN
dbms_output.enable(2000000);

DBMS_OUTPUT.PUT_LINE('Analyzing all Pending requests');
DBMS_OUTPUT.PUT_LINE('-----------------------------------------');
analyzeall;

END;
/

prompt

exit
/