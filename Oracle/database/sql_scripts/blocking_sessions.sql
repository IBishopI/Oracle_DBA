REM######################################################################
REM
REM  SQL name:  blocking_sessions.sql
REM
REM  Purpose:   This SQL checks for locking sessions without applications
REM
REM
REM######################################################################

set serveroutput on size 1000000
set linesize 80 pages 999
set feed off
set head off
define outfile=&1

col " " for A25
spool &outfile
declare
cursor block_session is
select --+ ORDERED
HH.session_id hsid,
Ww.session_id wsid
from
-----------------------------------------------------
(
select /*+ RULE */ *
from dba_locks
where blocking_others = 'Blocking' and
mode_held != 'None' and
mode_held != 'Null'
) HH,
-----------------------------------------------------
(
select /*+ RULE */ *
from dba_locks
where mode_requested != 'None'
) WW
-----------------------------------------------------
where WW.lock_type = HH.lock_type and
WW.lock_id1 = HH.lock_id1 and
WW.lock_id2 = HH.lock_id2
order by 1,2
;
last_hold_sid number:=0;
wait_indent varchar2(5):=chr(9)||chr(9);
hold_indent varchar2(5):=chr(9);
print_session_type char(1);
ident varchar2(10);

procedure print_sql(psid number,pindent varchar2) is
sqlstr varchar2(2000);
begin
        select substr(sql_text,1,500) into sqlstr from v$session s, v$sqlarea a
        where sid=psid and s.sql_address=a.address
        and s.sql_hash_value=a.hash_value;
        dbms_output.put_line(pindent||'--------- SQL-text Details: ---------');
        dbms_output.put_line(pindent||sqlstr);
        dbms_output.put_line(pindent||'-------------------------------------');
exception
        when no_data_found then
        null;
        when too_many_rows then
        null;
end;


procedure get_ora8i_session_detail(psid number,flag char)
is
cnt number:=0;
session_type varchar2(15);
session_type_printed boolean:=false;
cursor d2 is
        select  /*+ ORDERED */
        s.username username,
        OSUSER,
        to_char(s.logon_time,'mm/dd/yyyy HH24:MI:SS') logon_time,
        floor(last_call_et/3600)||':'||
        floor(mod(last_call_et,3600)/60)||':'||
        mod(mod(last_call_et,3600),60) idle,
        action,
        module,
        s.status,
        s.sid||','||s.sErial# sid_serial,
	s.CLIENT_IDENTIFIER CLIENT_IDENTIFIER
        from      gv$session  s
        ,         v$process  p
        where  s.paddr      = p.addr
        and     s.sid=psid;
begin
        if flag='h' then
                ident:=hold_indent;
                session_type:='Holding session';
        else
                ident:=wait_indent;
                session_type:='Waiting session';
        end if;

        for cd2 in d2
        loop
                if print_session_type='Y' and not session_type_printed then
                        dbms_output.put_line(session_type);
                end if;
                dbms_output.put_line(chr(13));
                dbms_output.put_line(ident||'UserName: '||cd2.username);
                dbms_output.put_line(ident||'OSUser: '||cd2.osuser);
                dbms_output.put_line(ident||'LogonTime: '||cd2.logon_time);
                dbms_output.put_line(ident||'Idle: '||cd2.idle);
                dbms_output.put_line(ident||'Action: '||cd2.action);
                dbms_output.put_line(ident||'Module: '||cd2.module);
                dbms_output.put_line(ident||'Status: '||cd2.status);
                dbms_output.put_line(ident||'Sid Serial#: '||cd2.sid_serial);
                dbms_output.put_line(ident||'Client: '||cd2.client_identifier);
                print_sql(psid,ident);
                session_type_printed:=true;
        end loop;
end;

begin
        for c in block_session
        loop
                if last_hold_sid!=c.hsid then
                        print_session_type:='Y';
                        get_ora8i_session_detail(c.hsid,'h');
                else
                        print_session_type:='N';
                end if;
                get_ora8i_session_detail(c.wsid,'w');

                last_hold_sid:=c.hsid;
        end loop;


end;
/

spool off
set feed on
exit

