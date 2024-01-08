-- Description
--    This script can be used to run the Segment Advisor in the Oracle Database.
 
SET serveroutput ON
SET pagesize 10000
SET linesize 120
SET verify OFF
 
-- Declare all the required variables.
ACCEPT t_name prompt 'Enter a unique Task Name : '
PROMPT * * * Object Type can be one of the following * * *
PROMPT - TABLESPACE
PROMPT - TABLE
PROMPT - INDEX
PROMPT - TABLE PARTITION
PROMPT - INDEX PARTITION
PROMPT - TABLE SUBPARTITION
PROMPT - INDEX SUBPARTITION
PROMPT - LOB
PROMPT - LOB PARTITION
PROMPT - LOB SUBPARTITION
 
ACCEPT obj_type PROMPT 'Enter Object Type (Tablespace, Table, Index or LOB) : '
ACCEPT obj_name PROMPT 'Enter Object Name : '
 
PROMPT - "For Tablespace leave the below User Name empty and just hit ENTER"
ACCEPT user_name DEFAULT NULL PROMPT 'Enter User Name : '
 
PROMPT - "For Tablespace/Table/Index/LOB leave the below Partition Name empty and just hit ENTER"
ACCEPT part_name DEFAULT NULL PROMPT 'Enter Partition or Sub Partiton Name : '
 
DECLARE
 
v_t_name varchar2(100) := upper('&t_name');
v_obj_type varchar2(100) := upper('&obj_type');
v_attr1 varchar2(100) := upper('&user_name');
v_attr2 varchar2(100) := upper('&obj_name');
v_attr3 varchar2(100) := upper('&part_name');
obj_id number;
 
CURSOR advisor_cur IS
SELECT f.task_name,
f.impact,
o.type AS object_type,
o.attr1 AS schema,
o.attr2 AS object_name,
o.attr3 AS partition_name,
f.message,
f.more_info
FROM dba_advisor_findings f
JOIN dba_advisor_objects o ON f.object_id = o.object_id AND f.task_name = o.task_name
WHERE f.task_name = v_t_name;
 
advisor_rec advisor_cur%ROWTYPE;
 
BEGIN
 
IF v_obj_type = 'TABLESPACE' THEN
v_attr1 := v_attr2;
v_attr2 := NULL;
v_attr3 := NULL;
ELSIF v_obj_type IN ('TABLE', 'INDEX', 'LOB') THEN
v_attr3 := NULL;
ELSE
NULL;
END IF;
 
-- Create a segment advisor task for your object (Table/Index/Tablespace)
dbms_advisor.create_task (
advisor_name => 'Segment Advisor',
task_name => v_t_name,
task_desc => 'Segment Advisor ');
 
-- Create the advisor object
dbms_advisor.create_object (
task_name => v_t_name,
object_type => v_obj_type,
attr1 => v_attr1,
attr2 => v_attr2,
attr3 => v_attr3,
attr4 => NULL,
attr5 => NULL,
object_id => obj_id
);
 
-- Set the task parameters
dbms_advisor.set_task_parameter(
task_name => v_t_name,
parameter => 'RECOMMEND_ALL',
value => 'TRUE');
 
-- Execute the task
dbms_advisor.execute_task(v_t_name);
 
-- Select form advisor views and display the output.
dbms_output.put_line('+----------------------------------------------------+');
dbms_output.put_line('| * * * * * * * Segment Advisor Output * * * * * * * |');
dbms_output.put_line('+----------------------------------------------------+');
dbms_output.put_line('- - - - - - - Task Name : ' || v_t_name ||' - - - - - - - ');
 
FOR advisor_rec IN advisor_cur
LOOP
dbms_output.put_line('+ Schema : '|| advisor_rec.schema);
dbms_output.put_line('+ Object Type : '|| advisor_rec.object_type);
dbms_output.put_line('+ Object Name : '|| advisor_rec.object_name);
dbms_output.put_line('+ Partition Name : '|| advisor_rec.partition_name);
dbms_output.put_line('+');
dbms_output.put_line('+ Advisor Message : ' || advisor_rec.message);
dbms_output.put_line('+');
dbms_output.put_line('+ More Info : ' || advisor_rec.more_info);
dbms_output.put_line('+ Impact : '|| advisor_rec.impact);
END LOOP;
 
dbms_output.put_line('+----------------------------------------------------+');
 
END;