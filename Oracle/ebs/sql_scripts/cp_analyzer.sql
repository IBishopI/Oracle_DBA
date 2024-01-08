REM $Id: cp_analyzer.sql 200.6 2015/08/04 mcosta & bburbage $
SET SERVEROUTPUT ON SIZE 1000000
SET ECHO OFF 
SET VERIFY OFF
SET DEFINE '~'

REM +=========================================================================+
REM |                 Copyright (c) 2001 Oracle Corporation                   |
REM |                    Redwood Shores, California, USA                      |
REM |                         All rights reserved.                            |
REM +=========================================================================+
REM | Framework 3.0.26                                                        |
REM |                                                                         |
REM | FILENAME                                                                |
REM |    cp_analyzer.sql                                                      |
REM |                                                                         |
REM | DESCRIPTION                                                             |
REM |                                                                         |
REM | HISTORY                                                                 |
REM |   Created: July 6th, 2011                                               |
REM |   Updated:  Aug 4th, 2015                                               |
REM |   bburbage   Jul 06, 2011   Created initial script                      |
REM |   bburbage   Dec 22, 2013   Added javascript code to make some tables   |
REM |                             sortable, modified the Feedback to CP       |
REM |                             Community, added buttons to display SQL     | 
REM |   mcosta     Apr 09, 2015   Updates and enhancements per guidelines     |
REM |   bburbage   Aug 04, 2015   Reformatted to new Analyzer Standards       |                                                           |
REM |                                                                         |
REM +=========================================================================+
REM
REM ANALYZER_BUNDLE_START 
REM 
REM COMPAT: 11i 12.0 12.1 12.2 
REM 
REM MENU_TITLE: Concurrent Processing Analyzer
REM
REM MENU_START
REM
REM SQL: Run Concurrent Processing Analyzer 
REM FNDLOAD: Load Concurrent Processing Analyzer as a Concurrent Program 
REM
REM MENU_END 
REM 
REM HELP_START  
REM 
REM  Concurrent Processing - CP Analyzer Help [Doc ID: 1411723.1] 
REM
REM  Explanation of available options:
REM
REM    (1)  Run CP Analyzer:  11i|12.0|12.1|12.2
REM        o Runs cp_analyzer.sql as APPS user to create an HTML report 
REM
REM    (2) Install Analyzer as a Concurrent Program: 11i|12.0|12.1|12.2 
REM        o Runs FNDLOAD as APPS 
REM        o Defines the analyzer as a concurrent executable/program 
REM        o Adds the analyzer to default request group System Administrator Reports
REM 
REM HELP_END 
REM 
REM FNDLOAD_START 
REM
REM PROD_TOP: FND_TOP
REM DEF_REQ_GROUP: System Administrator Reports
REM PROG_NAME: CP_ANALYZER_SQL 
REM PROG_TEMPLATE: cpa_prog.ldt
REM PROD_SHORT_NAME: FND 
REM
REM FNDLOAD_END 
REM
REM DEPENDENCIES_START 
REM
REM DEPENDENCIES_END
REM  
REM RUN_OPTS_START
REM
REM RUN_OPTS_END 
REM
REM OUTPUT_TYPE: UTL_FILE 
REM
REM ANALYZER_BUNDLE_END 

DECLARE
  l_debug_mode VARCHAR2(1) := 'Y';

TYPE section_rec IS RECORD(
  name           VARCHAR2(255),
  result         VARCHAR2(1), -- E,W,S
  error_count    NUMBER,
  warn_count     NUMBER,
  success_count  NUMBER,
  print_count    NUMBER);

TYPE rep_section_tbl IS TABLE OF section_rec INDEX BY BINARY_INTEGER;
TYPE hash_tbl_2k     IS TABLE OF VARCHAR2(2000) INDEX BY VARCHAR2(255);
TYPE hash_tbl_4k     IS TABLE OF VARCHAR2(4000) INDEX BY VARCHAR2(255);
TYPE hash_tbl_8k     IS TABLE OF VARCHAR2(8000) INDEX BY VARCHAR2(255);
TYPE col_list_tbl    IS TABLE OF DBMS_SQL.VARCHAR2_TABLE;
TYPE varchar_tbl     IS TABLE OF VARCHAR2(255);

TYPE signature_rec IS RECORD(
  sig_sql          VARCHAR2(32000),
  title            VARCHAR2(255),
  fail_condition   VARCHAR2(4000),
  problem_descr    VARCHAR2(4000),
  solution         VARCHAR2(4000),
  success_msg      VARCHAR2(4000),
  print_condition  VARCHAR2(8),
  fail_type        VARCHAR2(1),
  print_sql_output VARCHAR2(2),
  limit_rows       VARCHAR2(1),
  extra_info       HASH_TBL_4K,
  child_sigs       VARCHAR_TBL := VARCHAR_TBL(),
  include_in_xml   VARCHAR2(1));

TYPE signature_tbl IS TABLE OF signature_rec INDEX BY VARCHAR2(255);

----------------------------------
-- Global Variables             --
----------------------------------
g_sect_no NUMBER := 1;
g_log_file         UTL_FILE.FILE_TYPE;
g_out_file         UTL_FILE.FILE_TYPE;
g_print_to_stdout  VARCHAR2(1) := 'N';
g_is_concurrent    BOOLEAN := (to_number(nvl(FND_GLOBAL.CONC_REQUEST_ID,0)) >  0);
g_preserve_trailing_blanks BOOLEAN := false;
g_debug_mode       VARCHAR2(1);
g_max_output_rows  NUMBER := 30;
g_family_result    VARCHAR2(1);
g_errbuf           VARCHAR2(1000);
g_retcode          VARCHAR2(1);

item_cnt    	   NUMBER := 0;
sid	  			   VARCHAR2(16);
g_reqid_cnt			number;

g_query_start_time TIMESTAMP;
g_query_elapsed    INTERVAL DAY(2) TO SECOND(3);
g_analyzer_start_time TIMESTAMP;
g_analyzer_elapsed    INTERVAL DAY(2) TO SECOND(3);

g_signatures      SIGNATURE_TBL;
g_sections        REP_SECTION_TBL;
g_section_toc	  VARCHAR2(32767);
g_section_sig     NUMBER;
sig_count         NUMBER;
g_sql_tokens      HASH_TBL_2K;
g_rep_info        HASH_TBL_2K;
g_parameters      HASH_TBL_2K;
g_exec_summary      HASH_TBL_2K;
g_item_id         INTEGER := 0;
g_sig_id        INTEGER := 0;
g_parent_sig_id   		INTEGER := 0;
g_parent_sig_count		NUMBER;
analyzer_title VARCHAR2(255);
g_mos_patch_url   VARCHAR2(255) :=
  'https://support.oracle.com/epmos/faces/ui/patch/PatchDetail.jspx?patchId=';
g_mos_doc_url     VARCHAR2(255) :=
  'https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER&sourceId=1411723.1&id=';
g_hidden_xml      DBMS_XMLDOM.DOMDocument;



----------------------------------------------------------------
-- Debug, log and output procedures                          --
----------------------------------------------------------------

PROCEDURE enable_debug IS
BEGIN
  g_debug_mode := 'Y';
END enable_debug;

PROCEDURE disable_debug IS
BEGIN
  g_debug_mode := 'N';
END disable_debug;

PROCEDURE print_log(p_msg IN VARCHAR2) is
BEGIN
  IF NOT g_is_concurrent THEN
    utl_file.put_line(g_log_file, p_msg);
    utl_file.fflush(g_log_file);
  ELSE
    fnd_file.put_line(FND_FILE.LOG, p_msg);
  END IF;

  IF (g_print_to_stdout = 'Y') THEN
    dbms_output.put_line(substr(p_msg,1,254));
  END IF;
EXCEPTION WHEN OTHERS THEN
  dbms_output.put_line(substr('Error in print_log: '||sqlerrm,1,254));
  raise;
END print_log;

PROCEDURE debug(p_msg VARCHAR2) is
 l_time varchar2(25);
BEGIN
  IF (g_debug_mode = 'Y') THEN
    l_time := to_char(sysdate,'DD-MON-YY HH24:MI:SS');

    IF NOT g_is_concurrent THEN
      utl_file.put_line(g_log_file, l_time||'-'||p_msg);
    ELSE
      fnd_file.put_line(FND_FILE.LOG, l_time||'-'||p_msg);
    END IF;

    IF g_print_to_stdout = 'Y' THEN
      dbms_output.put_line(substr(l_time||'-'||p_msg,1,254));
    END IF;

  END IF;
EXCEPTION WHEN OTHERS THEN
  print_log('Error in debug');
  raise;
END debug;


PROCEDURE print_out(p_msg IN VARCHAR2
                   ,p_newline IN VARCHAR  DEFAULT 'Y' ) is
BEGIN
  IF NOT g_is_concurrent THEN
    IF (p_newline = 'N') THEN
       utl_file.put(g_out_file, p_msg);
    ELSE
       utl_file.put_line(g_out_file, p_msg);
    END IF;
    utl_file.fflush(g_out_file);
  ELSE
     IF (p_newline = 'N') THEN
        fnd_file.put(FND_FILE.OUTPUT, p_msg);
     ELSE
        fnd_file.put_line(FND_FILE.OUTPUT, p_msg);
     END IF;
  END IF;
EXCEPTION WHEN OTHERS THEN
  print_log('Error in print_out');
  raise;
END print_out;


PROCEDURE print_error (p_msg VARCHAR2) is
BEGIN
  print_out('<div class="diverr">'||p_msg);
  print_out('</div>');
END print_error;



----------------------------------------------------------------
--- Time Management                                          ---
----------------------------------------------------------------

PROCEDURE get_current_time (p_time IN OUT TIMESTAMP) IS
BEGIN
  SELECT localtimestamp(3) INTO p_time
  FROM   dual;
END get_current_time;

FUNCTION stop_timer(p_start_time IN TIMESTAMP) RETURN INTERVAL DAY TO SECOND IS
  l_elapsed INTERVAL DAY(2) TO SECOND(3);
BEGIN
  SELECT localtimestamp - p_start_time  INTO l_elapsed
  FROM   dual;
  RETURN l_elapsed;
END stop_timer;

FUNCTION format_elapsed (p_elapsed IN INTERVAL DAY TO SECOND) RETURN VARCHAR2 IS
  l_days         VARCHAR2(3);
  l_hours        VARCHAR2(2);
  l_minutes      VARCHAR2(2);
  l_seconds      VARCHAR2(6);
  l_fmt_elapsed  VARCHAR2(80);
BEGIN
  l_days := EXTRACT(DAY FROM p_elapsed);
  IF to_number(l_days) > 0 THEN
    l_fmt_elapsed := l_days||' days';
  END IF;
  l_hours := EXTRACT(HOUR FROM p_elapsed);
  IF to_number(l_hours) > 0 THEN
    IF length(l_fmt_elapsed) > 0 THEN
      l_fmt_elapsed := l_fmt_elapsed||', ';
    END IF;
    l_fmt_elapsed := l_fmt_elapsed || l_hours||' Hrs';
  END IF;
  l_minutes := EXTRACT(MINUTE FROM p_elapsed);
  IF to_number(l_minutes) > 0 THEN
    IF length(l_fmt_elapsed) > 0 THEN
      l_fmt_elapsed := l_fmt_elapsed||', ';
    END IF;
    l_fmt_elapsed := l_fmt_elapsed || l_minutes||' Min';
  END IF;
  l_seconds := EXTRACT(SECOND FROM p_elapsed);
  IF length(l_fmt_elapsed) > 0 THEN
    l_fmt_elapsed := l_fmt_elapsed||', ';
  END IF;
  l_fmt_elapsed := l_fmt_elapsed || l_seconds||' Sec';
  RETURN(l_fmt_elapsed);
END format_elapsed;


----------------------------------------------------------------
--- File Management                                          ---
----------------------------------------------------------------

PROCEDURE initialize_files is
  l_date_char        VARCHAR2(20);
  l_log_file         VARCHAR2(200);
  l_out_file         VARCHAR2(200);
  l_file_location    V$PARAMETER.VALUE%TYPE;
  l_instance         VARCHAR2(16);
  l_host         	 VARCHAR2(64);
  NO_UTL_DIR         EXCEPTION;
  
BEGIN
get_current_time(g_analyzer_start_time);

  IF NOT g_is_concurrent THEN

    SELECT to_char(sysdate,'YYYY-MM-DD-HH24MISS') INTO l_date_char from dual;

	SELECT instance_name, host_name
    INTO l_instance, l_host
    FROM v$instance;
	
-- PSD #4
    l_log_file := 'CP_Analyzer_'||l_host||'_'||l_instance||'_'||l_date_char||'.log';
    l_out_file := 'CP_Analyzer_'||l_host||'_'||l_instance||'_'||l_date_char||'.html';       


    SELECT decode(instr(value,','),0,value,
           SUBSTR (value,1,instr(value,',') - 1))
    INTO   l_file_location
    FROM   v$parameter
    WHERE  name = 'utl_file_dir';

	
	-- Set maximum line size to 10000 for encoding of base64 icon
    IF l_file_location IS NULL THEN
      RAISE NO_UTL_DIR;
    ELSE
      g_out_file := utl_file.fopen(l_file_location, l_out_file, 'w',10000);
      g_log_file := utl_file.fopen(l_file_location, l_log_file, 'w',10000);
    END IF;

	dbms_output.put_line('Output Files are located on Host : '||l_host);
    dbms_output.put_line('Output file : '||l_file_location||'/'||l_out_file);
    dbms_output.put_line('Log file:     '||l_file_location||'/'||l_log_file);
  END IF;
EXCEPTION
  WHEN NO_UTL_DIR THEN
    dbms_output.put_line('Exception: Unable to identify a valid output '||
      'directory for UTL_FILE in initialize_files');
    raise;
  WHEN OTHERS THEN
    dbms_output.put_line('Exception: '||sqlerrm||' in initialize_files');
    raise;
END initialize_files;


PROCEDURE close_files IS
BEGIN
  debug('Entered close_files');
  print_out('</BODY></HTML>');
  IF NOT g_is_concurrent THEN
    debug('Closing files');
    utl_file.fclose(g_log_file);
    utl_file.fclose(g_out_file);
  END IF;
END close_files;


----------------------------------------------------------------
-- REPORTING PROCEDURES                                       --
----------------------------------------------------------------

----------------------------------------------------------------
-- Prints HTML page header and auxiliary Javascript functions --
-- Notes:                                                     --
-- Looknfeel styles for the o/p must be changed here          --
----------------------------------------------------------------

PROCEDURE print_page_header is
BEGIN
  -- HTML header
  print_out('
<HTML><HEAD>
  <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1">
  <meta http-equiv="X-UA-Compatible" content="IE=9">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">');

  -- Page Title
  print_out('<TITLE>CP Analyzer Report</TITLE>');

  -- Styles
  print_out('
<STYLE type="text/css">
body {
  background-color:#ffffff;
  font-family:Arial;
  font-size:12pt;
  margin-left: 30px;
  margin-right: 30px;
  margin-top: 25px;
  margin-bottom: 25px;
}
tr {
  font-family: Tahoma, Helvetica, Geneva, sans-serif;
  font-size: small;
  color: #3D3D3D;
  background-color: white;
  padding: 5px;
}
tr.top {
  vertical-align:top;
}
tr.master {
  padding-bottom: 20px;
  background-color: white;
}
th {
  font-family: inherit;
  font-size: inherit;
  font-weight: bold;
  text-align: left;
  background-color: #BED3E9;
  color: #3E3E3E;
  padding: 5px;
}
th.master {
  font-family: Arial, Helvetica, sans-serif;
  padding-top: 10px;
  font-size: inherit;
  background-color: #BED3E9;
  color: #35301A;
}
th.rep {
  white-space: nowrap;
  width: 5%;
}
td {
  padding: inherit;
  font-family: inherit;
  font-size: inherit;
  font-weight: inherit;
  color: inherit;
  background-color: inherit;
  text-indent: 0px;
}
td.hlt {
  padding: inherit;
  font-family: inherit;
  font-size: inherit;
  font-weight: bold;
  color: #333333;
  background-color: #FFE864;
  text-indent: 0px;
}

a {color: #0066CC;}
a:visited { color: #808080;}
a:hover { color: #0099CC;}
a:active { color: #0066CC;}

.detail {
  text-decoration:none;
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
}
.detailsmall {
  text-decoration:none;
  font-size: xx-small;
}
.table1 {
   border: 1px solid #EAEAEA;
  vertical-align: middle;
  text-align: left;
  padding: 3px;
  margin: 1px;
  width: 100%;
  font-family: Arial, Helvetica, sans-serif;
  border-spacing: 1px;
  background-color: #F5F5F5;
}
.toctable {
  background-color: #F4F4F4;
}
.TitleBar, .TitleImg{
display:table-cell;
width:95%;
vertical-align: middle;
--border-radius: 6px;
font-family: Calibri;
background-color: #152B40;
padding: 9px;
margin: 0px;
box-shadow: 3px 3px 3px #AAAAAA;
color: #F4F4F4;
font-size: xx-large;
font-weight: bold;
overflow:hidden;
}
.TitleImg{}
.TitleBar > div{
    height:25px;
}
.TitleBar .Title2{
font-family: Calibri;
background-color: #152B40;
padding: 9px;
margin: 0px;
color: #F4F4F4;
font-size: medium;
}
.divSection {
  -moz-border-radius: 6px;
  -webkit-border-radius: 6px;
  border-radius: 6px;
  font-family: Arial, Helvetica, sans-serif;
  background-color: #CCCCCC;
  border: 1px solid #DADADA;
  padding: 9px;
  margin: 0px;
  box-shadow: 3px 3px 3px #AAAAAA;
  overflow:hidden;
}
.divSectionTitle {
width: 98.5%;
font-family: Calibri;
font-weight: bold;
background-color: #152B40;
color: #FFFFFF;
padding: 9px;
margin: 0px;
box-shadow: 3px 3px 3px #AAAAAA;
-moz-border-radius: 6px;
-webkit-border-radius: 6px;
border-radius: 6px;
height: 30px;
overflow:hidden;
}
.columns       { 
width: 98.5%; 
font-family: Calibri;
font-weight: bold;
background-color: #254B72;
color: #FFFFFF;
padding: 9px;
margin: 0px;
box-shadow: 3px 3px 3px #AAAAAA;
-moz-border-radius: 6px;
-webkit-border-radius: 6px;
border-radius: 6px;
height: 30px;
}
div.divSectionTitle div   { height: 30px; float: left; }
div.left          { width: 70%; background-color: #152B40; font-size: x-large; border-radius: 6px; }
div.right         { width: 30%; background-color: #152B40; font-size: medium; border-radius: 6px;}
div.clear         { clear: both; }
<!--End BBURBAGE code for adding the logo into the header -->
.sectHideShow {
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  font-weight: bold;
  background-color: #254B72;
  color: #1D70AD;
}

.sectHideShowLnk {
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  font-weight: bold;
  background-color: #254B72;
  color: #1D70AD;
}
.divSubSection {
  -moz-border-radius: 6px;
  -webkit-border-radius: 6px;
  border-radius: 6px;
  font-family: Arial, Helvetica, sans-serif;
  background-color: #E4E4E4;
  border: 1px solid #DADADA;
  padding: 9px;
  margin: 0px;
  box-shadow: 3px 3px 3px #AAAAAA;
}
.divSubSectionTitle {
  font-family: Arial, Helvetica, sans-serif;
  font-size: large;
  font-weight: bold;
  background-color: #888888;
  color: #FFFFFF;
  padding: 9px;
  margin: 0px;
  box-shadow: 3px 3px 3px #AAAAAA;
  -moz-border-radius: 6px;
  -webkit-border-radius: 6px;
  border-radius: 6px;
}
.divItem {
  -moz-border-radius: 6px;
  -webkit-border-radius: 6px;
  border-radius: 6px;
  font-family: Arial, Helvetica, sans-serif;
  background-color: #F4F4F4;
  border: 1px solid #EAEAEA;
  padding: 9px;
  margin: 0px;
  box-shadow: 3px 3px 3px #AAAAAA;
}
.divItemTitle {
  font-family: Arial, Helvetica, sans-serif;
  font-size: medium;
  font-weight: bold;
  color: #336699;
  border-bottom-style: solid;
  border-bottom-width: medium;
  border-bottom-color: #3973AC;
  margin-bottom: 9px;
  padding-bottom: 2px;
  margin-left: 3px;
  margin-right: 3px;
}
.divwarn {
  -moz-border-radius: 6px;
  -webkit-border-radius: 6px;
  border-radius: 6px;
  font-family: Arial, Helvetica, sans-serif;
  color: #333333;
  background-color: #FFEF95;
  border: 0px solid #FDC400;
  padding: 9px;
  margin: 0px;
  box-shadow: 3px 3px 3px #AAAAAA;
  font-size: small;
}
.divwarn1 {
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  font-weight: bold;
  color: #9B7500;
  margin-bottom: 9px;
  padding-bottom: 2px;
  margin-left: 3px;
  margin-right: 3px;
}
.diverr {
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  font-weight: bold;
  color: white;
  background-color: #F04141;
  box-shadow: 3px 3px 3px #AAAAAA;
   -moz-border-radius: 6px;
   -webkit-border-radius: 6px;
  border-radius: 6px;
  margin: 3px;
}
.divuar {
  border: 0px solid #CC0000;
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  font-weight: normal;
  background-color: #FFD8D8;
  color: #333333;
  padding: 9px;
  margin: 3px;
  box-shadow: 3px 3px 3px #AAAAAA;
  -moz-border-radius: 6px;
  -webkit-border-radius: 6px;
  border-radius: 6px;
}
.divuar1 {
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  font-weight: bold;
  color: #CC0000;
  margin-bottom: 9px;
  padding-bottom: 2px;
  margin-left: 3px;
  margin-right: 3px;
}
.divok {
  border: 1px none #00CC99;
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  font-weight: normal;
  background-color: #ECFFFF;
  color: #333333;
  padding: 9px;
  margin: 3px;
  box-shadow: 3px 3px 3px #AAAAAA;
  -moz-border-radius: 6px;
  -webkit-border-radius: 6px;
  border-radius: 6px;
}
.divok1 {
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  font-weight: bold;
  color: #006600;
  margin-bottom: 9px;
  padding-bottom: 2px;
  margin-left: 3px;
  margin-right: 3px;
}
.divsol {
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  background-color: #D9E6F2;
  color: #333333;
  padding: 9px;
  margin: 0px;
  box-shadow: 3px 3px 3px #AAAAAA;
  -moz-border-radius: 6px;
  -webkit-border-radius: 6px;
  border-radius: 6px;
}
.divtable {
  font-family: Arial, Helvetica, sans-serif;
  box-shadow: 3px 3px 3px #AAAAAA;
  overflow: auto;
}
.graph {
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
}
.graph tr {
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  background-color: transparent;
}
.baruar {
  border-style: none;
  background-color: white;
  text-align: right;
  padding-right: 0.5em;
  width: 300px;
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  font-weight: bold;
  color: #CC0000;
  background-color: transparent;
}
.barwarn {
  border-style: none;
  background-color: white;
  text-align: right;
  padding-right: 0.5em;
  width: 300px;
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  font-weight: bold;
  color: #B38E00;
  background-color: transparent;
}
.barok {
  border-style: none;
  background-color: white;
  text-align: right;
  padding-right: 0.5em;
  width: 300px;
  font-family: Arial, Helvetica, sans-serif;
  font-size: small;
  color: #25704A;
  font-weight: bold;
  background-color: transparent;
}
.baruar div {
  border-top: solid 2px #0077DD;
  background-color: #FF0000;
  border-bottom: solid 2px #002266;
  text-align: right;
  color: white;
  float: left;
  padding-top: 0;
  height: 1em;
  font-family: Arial, Helvetica, sans-serif;
  font-size: x-small;
  border-top-color: #FF9999;
  border-bottom-color: #CC0000;
}
.barwarn div {
  border-top: solid 2px #0077DD;
  background-color: #FFCC00;
  border-bottom: solid 2px #002266;
  text-align: right;
  color: white;
  float: left;
  padding-top: 0;
  height: 1em;
  font-family: Arial, Helvetica, sans-serif;
  font-size: x-small;
  border-top-color: #FFFF66;
  border-bottom-color: #ECBD00;
}
.barok div {
  border-top: solid 2px #0077DD;
  background-color: #339966;
  border-bottom: solid 2px #002266;
  text-align: right;
  color: white;
  float: left;
  padding-top: 0;
  height: 1em;
  font-family: Arial, Helvetica, sans-serif;
  font-size: x-small;
  border-top-color: #00CC66;
  border-bottom-color: #006600;
}
span.errbul {
  color: #EE0000;
  font-size: large;
  font-weight: bold;
  text-shadow: 1px 1px #AAAAAA;
}
span.warbul {
  color: #FFAA00;
  font-size: large;
  font-weight: bold;
  text-shadow: 1px 1px #AAAAAA;
}
.legend {
  font-weight: normal; 
  color: #0000FF; 
  font-size: 9pt; 
  font-weight: bold
}
.solution {
  font-weight: normal; 
  color: #0000FF; 
 font-size: small; 
  font-weight: bold
}
.regtext {
  font-weight: normal; 
 font-size: small; 
}
.btn {
	display: inline-block;
	border: #000000;
	border-style: solid; 
	border-width: 2px;
	width:190px;
	height:54px;
	border-radius: 6px;	
	background: linear-gradient(#FFFFFF, #B0B0B0);
	font-weight: bold;
	color: blue; 
	margin-top: 5px;
    margin-bottom: 5px;
    margin-right: 5px;
    margin-left: 5px;
	vertical-align: middle;
}  

</STYLE>');
  -- JS and end of header
  print_out('
<script type="text/javascript">

   function activateTab(pageId) {
	     var tabCtrl = document.getElementById(''tabCtrl'');
	       var pageToActivate = document.getElementById(pageId);
	       for (var i = 0; i < tabCtrl.childNodes.length; i++) {
	           var node = tabCtrl.childNodes[i];
	           if (node.nodeType == 1) { /* Element */
	               node.style.display = (node == pageToActivate) ? ''block'' : ''none'';
	           }
	        }
	   }

	   
   function displayItem(e, itm_id) {
     var tbl = document.getElementById(itm_id);
	 if (tbl == null) {
       if (e.innerHTML == e.innerHTML.replace(
             String.fromCharCode(9660),
             String.fromCharCode(9654))) {
       e.innerHTML =
         e.innerHTML.replace(String.fromCharCode(9654),String.fromCharCode(9660));
       }
       else {
         e.innerHTML =
           e.innerHTML.replace(String.fromCharCode(9660),String.fromCharCode(9654))
       }
     }
     else {
       if (tbl.style.display == ""){
          e.innerHTML =
             e.innerHTML.replace(String.fromCharCode(9660),String.fromCharCode(9654));
          e.innerHTML = e.innerHTML.replace("Hide SQL","Show SQL &amp; info");
          tbl.style.display = "none"; }
       else {
          e.innerHTML =
            e.innerHTML.replace(String.fromCharCode(9654),String.fromCharCode(9660));
          e.innerHTML = e.innerHTML.replace("Show SQL &amp; info","Hide SQL");
          tbl.style.display = ""; }
     }
   }
   
   
   //Pier: changed function to support automatic display if comming from TOC
   function displaySection(ee,itm_id) { 
 
     var tbl = document.getElementById(itm_id + ''contents'');
     var e = document.getElementById(''showhide'' + itm_id + ''contents'');

     if (tbl.style.display == ""){
        // do not hide if coming from TOC link
        if (ee != ''TOC'') {
          e.innerHTML =
          e.innerHTML.replace(String.fromCharCode(9660),String.fromCharCode(9654));
          e.innerHTML = e.innerHTML.replace("Hide SQL","Show SQL &amp; info");
          tbl.style.display = "none";
        } 
     } else {
         e.innerHTML =
           e.innerHTML.replace(String.fromCharCode(9654),String.fromCharCode(9660));
         e.innerHTML = e.innerHTML.replace("Show SQL &amp; info","Hide SQL");
         tbl.style.display = ""; }
     //Go to section if comming from TOC
     if (ee == ''TOC'') {
       window.location.hash=''sect'' + itm_id;
     }
   }
</script>');
-- JQuery for icons
print_out('
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
<script>
$(document).ready(function(){

var src = $(''img#error_ico'').attr(''src'');
$(''img.error_ico'').attr(''src'', src);

var src = $(''img#warn_ico'').attr(''src'');
$(''img.warn_ico'').attr(''src'', src);

var src = $(''img#check_ico'').attr(''src'');
$(''img.check_ico'').attr(''src'', src);
	});
</script>'); 

-- Tablesorter
print_out('
<script>
        $(function(){
          $("#ProfileOpts").tablesorter({sortList: [[2,1],[1,0]] }); // sorts 3rd column in descending order, then 2nd column asc
        });
</script>');

     print_out('</HEAD><BODY>');
	 
 
-- base64 icons definition	 
 --error icon
  print_out('<div style="display: none;">');
    print_out('<img id="error_ico" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABAAAAAPCAYAAADtc08vAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyppVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMi1jMDAxIDYzLjEzOTQzOSwgMjAxMC8xMC8xMi0wODo0NTozMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIEVsZW1lbnRzIDExLjAgV2luZG93cyIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpDNEY2MDBGRjlDRjMxMUU0OUM5M0EyMkI2RkNEMkQyMiIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDpDNEY2MDEwMDlDRjMxMUU0OUM5M0EyMkI2RkNEMkQyMiI+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOkM0RjYwMEZEOUNGMzExRTQ5QzkzQTIyQjZGQ0QyRDIyIiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOkM0RjYwMEZFOUNGMzExRTQ5QzkzQTIyQjZGQ0QyRDIyIi8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+X+gwwwAAAspJREFUeNpUk11Ik1EYx/9nbrNJfi6dCm1aF0poF4UaNNgs6YtIigiC6EJCAonsJgiKriOwi7qrSCOCCCWlG015Z4o6XasuJOdHtPArTbN0m9v7nvf0nNdpeeDh7OP9/Z///znnZUIIbK5GxnI5cEYHajSggspFFaYaoepWgY42IRbx32KbAgQfJfDaqfMna8s8buwqKYU1IxORqRC+B4MYHAygdeBzFwk1vROic5vADYILnYUPzjXUle9xOgB/D/iXIPjcDIQ9D8LhhO7Yjb6JWTzv+zg+vhq7FRCizRBoBKTtx9fv3a7dG5uD3t4MwTk4GdPJkty5sTMKVILu3wL3/aH+H8CVsBAhk8wsbcvOekczWP0dsCfKNjitRUFqw13EKc7hNAGvI8NtAy4xxqwmylQjM0vbukZyBz0wVXhheaYYAhI2V3qpPCQmoC8uoDzdAhPgoQT5qAcmY12tQj3uFPFyiFgZhDasCLlU/8YeH1LEdDFE2AXxtdgi+kvtYh8wRwIHpAOXNTMbYn4GetJy9HI1tGGf0Tnh92HxYvXGHKi0hIosroIezSWBLCkQjk6NQc/JMwRk2ZK2JWyt8sL+UoFGsCqLzM9GErRD3oc0KTASDn6AyHcaHWzN/+Cf1Dk+5MOOQ14UvFKM/3VhwmhUkwITJBCVAt1DAwHjrOVRqf7eLVgjN7MXqhEb9CEy0GsIqPRbIMaxDnwigRV2lrLQlxeNp93HKrUlJCbHwGn8EpaHoiWPU37mLAXtEeDpKvcvAI+Ie2+Sd5vsNLXQDev5QxaLSqBn5tDDFmhg0AjizAw1xWLAbyJ8ag14S3CIHMxvvQsVjJ2gu1Z3pCDLvT/durPIClsO18zTkThG1xLaSJSv9q3rPQR3LgNBQr4Ru8z+fxtdjKVWATcL7dlXV5Z+ZafQTGlGCwmKHqeYZur4GngIOcsk+FeAAQAH74+14hNYkgAAAABJRU5ErkJggg==" alt="error_ico">');
 --warning icon
    print_out('<img title="warning" id="warn_ico" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAAACXBIWXMAAAsTAAALEwEAmpwYAAAKT2lDQ1BQaG90b3Nob3AgSUNDIHByb2ZpbGUAAHjanVNnVFPpFj333vRCS4iAlEtvUhUIIFJCi4AUkSYqIQkQSoghodkVUcERRUUEG8igiAOOjoCMFVEsDIoK2AfkIaKOg6OIisr74Xuja9a89+bN/rXXPues852zzwfACAyWSDNRNYAMqUIeEeCDx8TG4eQuQIEKJHAAEAizZCFz/SMBAPh+PDwrIsAHvgABeNMLCADATZvAMByH/w/qQplcAYCEAcB0kThLCIAUAEB6jkKmAEBGAYCdmCZTAKAEAGDLY2LjAFAtAGAnf+bTAICd+Jl7AQBblCEVAaCRACATZYhEAGg7AKzPVopFAFgwABRmS8Q5ANgtADBJV2ZIALC3AMDOEAuyAAgMADBRiIUpAAR7AGDIIyN4AISZABRG8lc88SuuEOcqAAB4mbI8uSQ5RYFbCC1xB1dXLh4ozkkXKxQ2YQJhmkAuwnmZGTKBNA/g88wAAKCRFRHgg/P9eM4Ors7ONo62Dl8t6r8G/yJiYuP+5c+rcEAAAOF0ftH+LC+zGoA7BoBt/qIl7gRoXgugdfeLZrIPQLUAoOnaV/Nw+H48PEWhkLnZ2eXk5NhKxEJbYcpXff5nwl/AV/1s+X48/Pf14L7iJIEyXYFHBPjgwsz0TKUcz5IJhGLc5o9H/LcL//wd0yLESWK5WCoU41EScY5EmozzMqUiiUKSKcUl0v9k4t8s+wM+3zUAsGo+AXuRLahdYwP2SycQWHTA4vcAAPK7b8HUKAgDgGiD4c93/+8//UegJQCAZkmScQAAXkQkLlTKsz/HCAAARKCBKrBBG/TBGCzABhzBBdzBC/xgNoRCJMTCQhBCCmSAHHJgKayCQiiGzbAdKmAv1EAdNMBRaIaTcA4uwlW4Dj1wD/phCJ7BKLyBCQRByAgTYSHaiAFiilgjjggXmYX4IcFIBBKLJCDJiBRRIkuRNUgxUopUIFVIHfI9cgI5h1xGupE7yAAygvyGvEcxlIGyUT3UDLVDuag3GoRGogvQZHQxmo8WoJvQcrQaPYw2oefQq2gP2o8+Q8cwwOgYBzPEbDAuxsNCsTgsCZNjy7EirAyrxhqwVqwDu4n1Y8+xdwQSgUXACTYEd0IgYR5BSFhMWE7YSKggHCQ0EdoJNwkDhFHCJyKTqEu0JroR+cQYYjIxh1hILCPWEo8TLxB7iEPENyQSiUMyJ7mQAkmxpFTSEtJG0m5SI+ksqZs0SBojk8naZGuyBzmULCAryIXkneTD5DPkG+Qh8lsKnWJAcaT4U+IoUspqShnlEOU05QZlmDJBVaOaUt2ooVQRNY9aQq2htlKvUYeoEzR1mjnNgxZJS6WtopXTGmgXaPdpr+h0uhHdlR5Ol9BX0svpR+iX6AP0dwwNhhWDx4hnKBmbGAcYZxl3GK+YTKYZ04sZx1QwNzHrmOeZD5lvVVgqtip8FZHKCpVKlSaVGyovVKmqpqreqgtV81XLVI+pXlN9rkZVM1PjqQnUlqtVqp1Q61MbU2epO6iHqmeob1Q/pH5Z/YkGWcNMw09DpFGgsV/jvMYgC2MZs3gsIWsNq4Z1gTXEJrHN2Xx2KruY/R27iz2qqaE5QzNKM1ezUvOUZj8H45hx+Jx0TgnnKKeX836K3hTvKeIpG6Y0TLkxZVxrqpaXllirSKtRq0frvTau7aedpr1Fu1n7gQ5Bx0onXCdHZ4/OBZ3nU9lT3acKpxZNPTr1ri6qa6UbobtEd79up+6Ynr5egJ5Mb6feeb3n+hx9L/1U/W36p/VHDFgGswwkBtsMzhg8xTVxbzwdL8fb8VFDXcNAQ6VhlWGX4YSRudE8o9VGjUYPjGnGXOMk423GbcajJgYmISZLTepN7ppSTbmmKaY7TDtMx83MzaLN1pk1mz0x1zLnm+eb15vft2BaeFostqi2uGVJsuRaplnutrxuhVo5WaVYVVpds0atna0l1rutu6cRp7lOk06rntZnw7Dxtsm2qbcZsOXYBtuutm22fWFnYhdnt8Wuw+6TvZN9un2N/T0HDYfZDqsdWh1+c7RyFDpWOt6azpzuP33F9JbpL2dYzxDP2DPjthPLKcRpnVOb00dnF2e5c4PziIuJS4LLLpc+Lpsbxt3IveRKdPVxXeF60vWdm7Obwu2o26/uNu5p7ofcn8w0nymeWTNz0MPIQ+BR5dE/C5+VMGvfrH5PQ0+BZ7XnIy9jL5FXrdewt6V3qvdh7xc+9j5yn+M+4zw33'||
              'jLeWV/MN8C3yLfLT8Nvnl+F30N/I/9k/3r/0QCngCUBZwOJgUGBWwL7+Hp8Ib+OPzrbZfay2e1BjKC5QRVBj4KtguXBrSFoyOyQrSH355jOkc5pDoVQfujW0Adh5mGLw34MJ4WHhVeGP45wiFga0TGXNXfR3ENz30T6RJZE3ptnMU85ry1KNSo+qi5qPNo3ujS6P8YuZlnM1VidWElsSxw5LiquNm5svt/87fOH4p3iC+N7F5gvyF1weaHOwvSFpxapLhIsOpZATIhOOJTwQRAqqBaMJfITdyWOCnnCHcJnIi/RNtGI2ENcKh5O8kgqTXqS7JG8NXkkxTOlLOW5hCepkLxMDUzdmzqeFpp2IG0yPTq9MYOSkZBxQqohTZO2Z+pn5mZ2y6xlhbL+xW6Lty8elQfJa7OQrAVZLQq2QqboVFoo1yoHsmdlV2a/zYnKOZarnivN7cyzytuQN5zvn//tEsIS4ZK2pYZLVy0dWOa9rGo5sjxxedsK4xUFK4ZWBqw8uIq2Km3VT6vtV5eufr0mek1rgV7ByoLBtQFr6wtVCuWFfevc1+1dT1gvWd+1YfqGnRs+FYmKrhTbF5cVf9go3HjlG4dvyr+Z3JS0qavEuWTPZtJm6ebeLZ5bDpaql+aXDm4N2dq0Dd9WtO319kXbL5fNKNu7g7ZDuaO/PLi8ZafJzs07P1SkVPRU+lQ27tLdtWHX+G7R7ht7vPY07NXbW7z3/T7JvttVAVVN1WbVZftJ+7P3P66Jqun4lvttXa1ObXHtxwPSA/0HIw6217nU1R3SPVRSj9Yr60cOxx++/p3vdy0NNg1VjZzG4iNwRHnk6fcJ3/ceDTradox7rOEH0x92HWcdL2pCmvKaRptTmvtbYlu6T8w+0dbq3nr8R9sfD5w0PFl5SvNUyWna6YLTk2fyz4ydlZ19fi753GDborZ752PO32oPb++6EHTh0kX/i+c7vDvOXPK4dPKy2+UTV7hXmq86X23qdOo8/pPTT8e7nLuarrlca7nuer21e2b36RueN87d9L158Rb/1tWeOT3dvfN6b/fF9/XfFt1+cif9zsu72Xcn7q28T7xf9EDtQdlD3YfVP1v+3Njv3H9qwHeg89HcR/cGhYPP/pH1jw9DBY+Zj8uGDYbrnjg+OTniP3L96fynQ89kzyaeF/6i/suuFxYvfvjV69fO0ZjRoZfyl5O/bXyl/erA6xmv28bCxh6+yXgzMV70VvvtwXfcdx3vo98PT+R8IH8o/2j5sfVT0Kf7kxmTk/8EA5jz/GMzLdsAAAAgY0hSTQAAeiUAAICDAAD5/wAAgOkAAHUwAADqYAAAOpgAABdvkl/FRgAAAfBJREFUeNp8kd1L02EUxz/nt5EjlZY25ksktQWhZZEaKtoqUEYLzcLCNCQ3gq4y8QX0WvItrD8gyG6CoCzIKy8rDEQIoasoCqxFhBBERWzndDHcKtcOfHngPM/3jUfMjGxz86I8VKVDlfnBe3aG/42ZbcJsD5GluxEzM3t2J2Ld9fRne2dmOFmcXYh74nDbdVgWSvIW2OOj37tVyrIF2CSgSrS1q2//ll9LAAQCUF9LRfshBkREcla4cYGCW5cKPyR/rNlkLN9ix8Um+8Tij7Gxk3wJ+qjMWUGVgbbotTJn/TYrL7/z5j2srEKJD442UNwcZERE3FkrzHRJef72ncMVtZchPo3fl9r7dwAKjTXgL+RcXQUNWQVUGeu4Mpovn8ZBvxEOpb433GyQhAIPtDbhqS5lREQ8GzwxM6bOS2VRedVqbPy+i1fVoElIppxJZqAJGJlCX7zj7NO39iidQJWpzquTLtaG0+S5B9AzKMzNZwQchfZjOPt8jIpIIYAz0SmhmlAosq2oANYX0s6Lz4WPn2FxSTIpEtB0AA7upu5EgG4AR5WhhtNDEJ8Gy8RuqTfKfNByxNLkDaHGKtjlJSoixW5VauX1KfD80VmhNwK94X/IidTd3lLIcwgCAbcqT2ZmiapCLpj9fX79yTLg/T0AA6H+hDXGjwAAAAAASUVORK5CYII=" alt="warn_ico">');
  --check icon
    print_out('<img id="check_ico" src="data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABAAAAANCAYAAACgu+4kAAAACXBIWXMAAAsTAAALEwEAmpwYAAAKT2lDQ1BQaG90b3Nob3AgSUNDIHByb2ZpbGUAAHjanVNnVFPpFj333vRCS4iAlEtvUhUIIFJCi4AUkSYqIQkQSoghodkVUcERRUUEG8igiAOOjoCMFVEsDIoK2AfkIaKOg6OIisr74Xuja9a89+bN/rXXPues852zzwfACAyWSDNRNYAMqUIeEeCDx8TG4eQuQIEKJHAAEAizZCFz/SMBAPh+PDwrIsAHvgABeNMLCADATZvAMByH/w/qQplcAYCEAcB0kThLCIAUAEB6jkKmAEBGAYCdmCZTAKAEAGDLY2LjAFAtAGAnf+bTAICd+Jl7AQBblCEVAaCRACATZYhEAGg7AKzPVopFAFgwABRmS8Q5ANgtADBJV2ZIALC3AMDOEAuyAAgMADBRiIUpAAR7AGDIIyN4AISZABRG8lc88SuuEOcqAAB4mbI8uSQ5RYFbCC1xB1dXLh4ozkkXKxQ2YQJhmkAuwnmZGTKBNA/g88wAAKCRFRHgg/P9eM4Ors7ONo62Dl8t6r8G/yJiYuP+5c+rcEAAAOF0ftH+LC+zGoA7BoBt/qIl7gRoXgugdfeLZrIPQLUAoOnaV/Nw+H48PEWhkLnZ2eXk5NhKxEJbYcpXff5nwl/AV/1s+X48/Pf14L7iJIEyXYFHBPjgwsz0TKUcz5IJhGLc5o9H/LcL//wd0yLESWK5WCoU41EScY5EmozzMqUiiUKSKcUl0v9k4t8s+wM+3zUAsGo+AXuRLahdYwP2SycQWHTA4vcAAPK7b8HUKAgDgGiD4c93/+8//UegJQCAZkmScQAAXkQkLlTKsz/HCAAARKCBKrBBG/TBGCzABhzBBdzBC/xgNoRCJMTCQhBCCmSAHHJgKayCQiiGzbAdKmAv1EAdNMBRaIaTcA4uwlW4Dj1wD/phCJ7BKLyBCQRByAgTYSHaiAFiilgjjggXmYX4IcFIBBKLJCDJiBRRIkuRNUgxUopUIFVIHfI9cgI5h1xGupE7yAAygvyGvEcxlIGyUT3UDLVDuag3GoRGogvQZHQxmo8WoJvQcrQaPYw2oefQq2gP2o8+Q8cwwOgYBzPEbDAuxsNCsTgsCZNjy7EirAyrxhqwVqwDu4n1Y8+xdwQSgUXACTYEd0IgYR5BSFhMWE7YSKggHCQ0EdoJNwkDhFHCJyKTqEu0JroR+cQYYjIxh1hILCPWEo8TLxB7iEPENyQSiUMyJ7mQAkmxpFTSEtJG0m5SI+ksqZs0SBojk8naZGuyBzmULCAryIXkneTD5DPkG+Qh8lsKnWJAcaT4U+IoUspqShnlEOU05QZlmDJBVaOaUt2ooVQRNY9aQq2htlKvUYeoEzR1mjnNgxZJS6WtopXTGmgXaPdpr+h0uhHdlR5Ol9BX0svpR+iX6AP0dwwNhhWDx4hnKBmbGAcYZxl3GK+YTKYZ04sZx1QwNzHrmOeZD5lvVVgqtip8FZHKCpVKlSaVGyovVKmqpqreqgtV81XLVI+pXlN9rkZVM1PjqQnUlqtVqp1Q61MbU2epO6iHqmeob1Q/pH5Z/YkGWcNMw09DpFGgsV/jvMYgC2MZs3gsIWsNq4Z1gTXEJrHN2Xx2KruY/R27iz2qqaE5QzNKM1ezUvOUZj8H45hx+Jx0TgnnKKeX836K3hTvKeIpG6Y0TLkxZVxrqpaXllirSKtRq0frvTau7aedpr1Fu1n7gQ5Bx0onXCdHZ4/OBZ3nU9lT3acKpxZNPTr1ri6qa6UbobtEd79up+6Ynr5egJ5Mb6feeb3n+hx9L/1U/W36p/VHDFgGswwkBtsMzhg8xTVxbzwdL8fb8VFDXcNAQ6VhlWGX4YSRudE8o9VGjUYPjGnGXOMk423GbcajJgYmISZLTepN7ppSTbmmKaY7TDtMx83MzaLN1pk1mz0x1zLnm+eb15vft2BaeFostqi2uGVJsuRaplnutrxuhVo5WaVYVVpds0atna0l1rutu6cRp7lOk06rntZnw7Dxtsm2qbcZsOXYBtuutm22fWFnYhdnt8Wuw+6TvZN9un2N/T0HDYfZDqsdWh1+c7RyFDpWOt6azpzuP33F9JbpL2dYzxDP2DPjthPLKcRpnVOb00dnF2e5c4PziIuJS4LLLpc+Lpsbxt3IveRKdPVxXeF60vWdm7Obwu2o26/uNu5p7ofcn8w0nymeWTNz0MPIQ+BR5dE/C5+VMGvfrH5PQ0+BZ7XnIy9jL5FXrdewt6V3qvdh7xc+9j5yn+M+4zw33jLeWV/MN8C3yLfL'||
              'T8Nvnl+F30N/I/9k/3r/0QCngCUBZwOJgUGBWwL7+Hp8Ib+OPzrbZfay2e1BjKC5QRVBj4KtguXBrSFoyOyQrSH355jOkc5pDoVQfujW0Adh5mGLw34MJ4WHhVeGP45wiFga0TGXNXfR3ENz30T6RJZE3ptnMU85ry1KNSo+qi5qPNo3ujS6P8YuZlnM1VidWElsSxw5LiquNm5svt/87fOH4p3iC+N7F5gvyF1weaHOwvSFpxapLhIsOpZATIhOOJTwQRAqqBaMJfITdyWOCnnCHcJnIi/RNtGI2ENcKh5O8kgqTXqS7JG8NXkkxTOlLOW5hCepkLxMDUzdmzqeFpp2IG0yPTq9MYOSkZBxQqohTZO2Z+pn5mZ2y6xlhbL+xW6Lty8elQfJa7OQrAVZLQq2QqboVFoo1yoHsmdlV2a/zYnKOZarnivN7cyzytuQN5zvn//tEsIS4ZK2pYZLVy0dWOa9rGo5sjxxedsK4xUFK4ZWBqw8uIq2Km3VT6vtV5eufr0mek1rgV7ByoLBtQFr6wtVCuWFfevc1+1dT1gvWd+1YfqGnRs+FYmKrhTbF5cVf9go3HjlG4dvyr+Z3JS0qavEuWTPZtJm6ebeLZ5bDpaql+aXDm4N2dq0Dd9WtO319kXbL5fNKNu7g7ZDuaO/PLi8ZafJzs07P1SkVPRU+lQ27tLdtWHX+G7R7ht7vPY07NXbW7z3/T7JvttVAVVN1WbVZftJ+7P3P66Jqun4lvttXa1ObXHtxwPSA/0HIw6217nU1R3SPVRSj9Yr60cOxx++/p3vdy0NNg1VjZzG4iNwRHnk6fcJ3/ceDTradox7rOEH0x92HWcdL2pCmvKaRptTmvtbYlu6T8w+0dbq3nr8R9sfD5w0PFl5SvNUyWna6YLTk2fyz4ydlZ19fi753GDborZ752PO32oPb++6EHTh0kX/i+c7vDvOXPK4dPKy2+UTV7hXmq86X23qdOo8/pPTT8e7nLuarrlca7nuer21e2b36RueN87d9L158Rb/1tWeOT3dvfN6b/fF9/XfFt1+cif9zsu72Xcn7q28T7xf9EDtQdlD3YfVP1v+3Njv3H9qwHeg89HcR/cGhYPP/pH1jw9DBY+Zj8uGDYbrnjg+OTniP3L96fynQ89kzyaeF/6i/suuFxYvfvjV69fO0ZjRoZfyl5O/bXyl/erA6xmv28bCxh6+yXgzMV70VvvtwXfcdx3vo98PT+R8IH8o/2j5sfVT0Kf7kxmTk/8EA5jz/GMzLdsAAAAgY0hSTQAAeiUAAICDAAD5/wAAgOkAAHUwAADqYAAAOpgAABdvkl/FRgAAAMRJREFUeNqkkjEOgkAQRd96GY7gAajEWBALEzXRhHAJqr0Dd/AqJFZa2dnZSGVjY/EtkEUC0UU3mWYz7/3J7hhJ/HNGQ5rN1lizNjILY92lJK9ig2WFinshYkRILonh8J6qIgQEv8NjdsCsakqxpIgU24GXH2AIHFw8Cr1LWsmHfrj6wRouUXbLRIKYk7vk4wuedOFaUI1f0kg8kp3AvUGCuCDOKLtmX5NbAknUY3OigaPPcGcPmJIT+8O9i0RI7gtL4jkALy1qUf+xbKAAAAAASUVORK5CYII=" alt="check_ico">');
   print_out('</div>');

END print_page_header;
	 
----------------------------------------------------------------
-- Prints report title section                                --
-- ===========================                                --
-- To change look & feel:                                     --
-- Change css class divtitle which is the container box and   --
-- defines the backgrownd color and first line font           --
-- Change css class divtitle1 which defines the font on the   --
-- testname (second line)                                     --
----------------------------------------------------------------

PROCEDURE print_rep_title(p_analyzer_title varchar2) is
BEGIN

-- Print title
-- PSD #5  
  print_page_header;
  print_out('<!----------------- Title ----------------->
<div class="TitleBar">
    <div class="Title1">'|| p_analyzer_title || ' Analyzer Report' ||'</div>
    <div class="Title2">Compiled using version ' ||  g_rep_info('File Version') || ' / Latest version: ' || '<a href="https://support.oracle.com/oip/faces/secure/km/DownloadAttachment.jspx?attachid=1411723.1:CP_ANALYZER">
<img border="0" src="https://blogs.oracle.com/ebs/resource/Proactive/cpa_latest_version.gif" title="Click here to download the latest version of analyzer" alt="Latest Version Icon"></a>
   </div>
</div>
<div class="TitleImg"><a href="https://support.oracle.com/rs?type=doc%5C&amp;id=432.1" target="_blank"><img src="https://blogs.oracle.com/ebs/resource/Proactive/PSC_Logo.jpg" title="Click here to see other helpful Oracle Proactive Tools" alt="Proactive Services Banner" border="0" height="60" width="180"></a></div>
<br>');
END print_rep_title;


----------------------------------------------------------------
-- Prints Report Information placeholder                      --
----------------------------------------------------------------

PROCEDURE print_toc(
  ptoctitle varchar2 DEFAULT 'Report Information') IS
  l_key  VARCHAR2(255);
  l_html VARCHAR2(4000);
BEGIN
  g_sections.delete;
    print_out('<!------------------ TOC ------------------>
    <div class="divSection">');
  -- Print Run details and Parameters Section
  print_out('<div class="divItem" id="runinfo"><div class="divItemTitle">' ||
    'Report Information</div>');
	print_out('<span class="legend">Legend: &nbsp;&nbsp;<img class="error_ico"> Error &nbsp;&nbsp;<img class="warn_ico"> Warning &nbsp;&nbsp;<img class="check_ico"> Passed Check</span>');
	-- print_out('<p>');  
  print_out(
   '<table width="100%" class="graph"><tbody> 
      <tr class="top"><td width="30%"><p>
      <a class="detail" href="javascript:;" onclick="displayItem(this,''RunDetails'');"><font color="#0066CC">
      &#9654; Execution Details</font></a></p>
      <table class="table1" id="RunDetails" style="display:none">
      <tbody>');
  -- Loop and print values
  l_key := g_rep_info.first;
  WHILE l_key IS NOT NULL LOOP
    print_out('<tr><th class="rep">'||l_key||'</th><td>'||
      g_rep_info(l_key)||'</td></tr>');
    l_key := g_rep_info.next(l_key);
  END LOOP;
  print_out('</tbody></table></td>');
  print_out('<td width="30%"><p>
    <a class="detail" href="javascript:;" onclick="displayItem(this,''Parameters'');"><font color="#0066CC">
       &#9654; Parameters</font></a></p>
       <table class="table1" id="Parameters" style="display:none">
       <tbody>');
  l_key := g_parameters.first;
  WHILE l_key IS NOT NULL LOOP
    print_out('<tr><th class="rep">'||l_key||'</th><td>'||
      g_parameters(l_key)||'</td></tr>');
    l_key := g_parameters.next(l_key);
  END LOOP;
    print_out('</tbody></table></td>');  
    print_out('<td width="30%"><p>
    <div id="ExecutionSummary1"><a class="detail" href="javascript:;" onclick="displayItem(this,''ExecutionSummary2'');"><font color="#0066CC">&#9654; Execution Summary</font></a> </div>
    <div id="ExecutionSummary2" style="display:none">   </div>');   
 
  print_out('</td></tr></table>
    </div><br/>');

  -- Print out the Table of Contents holder
  print_out('<div class="divItem" id="toccontent"><div class="divItemTitle">' ||
    ptoctitle || '</div></div>
	<div align="center">
<a class="detail" onclick="opentabs();" href="javascript:;"><font color="#0066CC"><br>Show All Sections</font></a> &nbsp;&nbsp;/ &nbsp;&nbsp;
<a class="detail" onclick="closetabs();" href="javascript:;"><font color="#0066CC">Hide All Sections</font></a>
</div>
	</div></div><br><br>');
END print_toc;

----------------------------------------------------------------
-- Prints report TOC contents at end of script                --
----------------------------------------------------------------

PROCEDURE print_toc_contents(
     p_err_label  VARCHAR2 DEFAULT 'Checks Failed - Critical',
     p_warn_label VARCHAR2 DEFAULT 'Checks Failed - Warning',
     p_pass_label VARCHAR2 DEFAULT 'Checks Passed') IS

  l_action_req BOOLEAN := false;
  l_cnt_err  NUMBER := 0;
  l_cnt_warn NUMBER := 0;
  l_cnt_succ NUMBER := 0;
  l_tot_cnt  NUMBER;
  l_loop_count NUMBER;
     
BEGIN
 
  -- Script tag, assign old content to var, reassign old content and new stuff
  print_out('
<script type="text/javascript">
  var auxs;
  auxs = document.getElementById("toccontent").innerHTML;
  document.getElementById("toccontent").innerHTML = auxs + ');

  l_loop_count := g_sections.count;
	
  -- Loop through sections and generate HTML
  FOR i in 1 .. l_loop_count LOOP
      -- Add to counts
      l_cnt_err := l_cnt_err + g_sections(i).error_count;
      l_cnt_warn := l_cnt_warn + g_sections(i).warn_count;
      l_cnt_succ := l_cnt_succ + g_sections(i).success_count;
      -- Print Section name
		print_out('"<button class=''btn'' OnClick=activateTab(''page' || to_char(i) || ''')>' ||     
        g_sections(i).name || '" +');
      -- Print if section in error, warning or successful
      IF g_sections(i).result ='E' THEN 
	  print_out('" <img class=''error_ico''>" +');
        l_action_req := true;
      ELSIF g_sections(i).result ='W' THEN
        print_out('" <img class=''warn_ico''>" +');
        l_action_req := true;
	  ELSIF g_sections(i).result ='S' THEN
        print_out('" <img class=''check_ico''>" +');
        l_action_req := true;
      -- Print end of button
       
    END IF;
	print_out('"</button>" +');
  END LOOP;
  -- End the div
  print_out('"</div>";');
  -- End
  print_out('activateTab(''page1'');');
  
  -- Loop through sections and generate HTML for start sections
    FOR i in 1 .. l_loop_count LOOP
		print_out('auxs = document.getElementById("sect_title'||i||'").innerHTML;
				document.getElementById("sect_title'||i||'").innerHTML = auxs + ');
		if g_sections(i).error_count>0 and g_sections(i).warn_count>0 then
				print_out(' "'||g_sections(i).error_count||' <img class=''error_ico''>  '||g_sections(i).warn_count||' <img class=''warn_ico''> ";');
			elsif g_sections(i).error_count>0 then
				print_out(' "'||g_sections(i).error_count||' <img class=''error_ico''> ";');
			elsif g_sections(i).warn_count>0 then
				print_out(' "'||g_sections(i).warn_count||' <img class=''warn_ico''> ";');
			elsif g_sections(i).result ='S' then
				print_out(' " <img class=''check_ico''> ";');
			else
				print_out(' " ";');
			end if;						
	END LOOP;

	-- Loop through sections and generate HTML for execution summary
	print_out('auxs = document.getElementById("ExecutionSummary1").innerHTML;
				document.getElementById("ExecutionSummary1").innerHTML = auxs + ');
	if l_cnt_err>0 and l_cnt_warn>0 then
		print_out(' "('||l_cnt_err||' <img class=''error_ico''> '||l_cnt_warn||' <img class=''warn_ico''>)</A>";');
	elsif l_cnt_err>0 and l_cnt_warn=0 then
		print_out(' "(<img class=''error_ico''>'||l_cnt_err||')</A>";');
	elsif l_cnt_err=0 and l_cnt_warn>0 then
		print_out(' "(<img class=''warn_ico''>'||l_cnt_warn||')</A>";');
	elsif l_cnt_err=0 and l_cnt_warn=0 then
		print_out(' "(<img class=''check_ico''> No issues reported)</A>";');
	end if;
		
	print_out('auxs = document.getElementById("ExecutionSummary2").innerHTML;
				document.getElementById("ExecutionSummary2").innerHTML = auxs + ');
	print_out('" <table width=''100%'' class=''table1''><TR><TH class=''rep''><B>Section</B></TH><TH class=''rep''><B>Errors</B></TH><TH class=''rep''><B>Warnings</B></TH></TR>"+');
	  
    FOR i in 1 .. l_loop_count LOOP
			print_out('"<TR><TH class=''rep''><A class=detail onclick=activateTab(''page' || to_char(i) || '''); href=''javascript:;''>'||g_sections(i).name||'</A> "+');
			if g_sections(i).error_count>0 then
				print_out(' "<img class=''error_ico''>"+');
			elsif g_sections(i).warn_count>0 then
				print_out(' "<img class=''warn_ico''>"+');	
			elsif g_sections(i).result ='S' then
				print_out(' "<img class=''check_ico''>"+');
			end if;	
			print_out('"</TH><TD>'||g_sections(i).error_count||'</TD><TD>'||g_sections(i).warn_count||'</TD> </TR>"+'); 
	END LOOP;
	print_out('" </TABLE></div>";'); 
		
	print_out('function openall()
	{var txt = "restable";
	 var i;
	 var x=document.getElementById(''restable1'');
	 for (i=0;i<='||g_sig_id||';i++)  
	  {
	  x = document.getElementById(txt.concat(i.toString(),''b''));  
	       if (!(x == null ))
		    {x.innerHTML = x.innerHTML.replace(String.fromCharCode(9654),String.fromCharCode(9660));
	         x.innerHTML = x.innerHTML.replace("Show SQL &amp; info","Hide SQL"); 
			 }
	  x=document.getElementById(txt.concat(i.toString())); 
	    if (!(x == null ))
		  {document.getElementById(txt.concat(i.toString())).style.display = ''''; }
	  }
	}
	 
	function closeall()
	{var txt = "restable";
	var txt2 = "tbitm";
	var i;
	var x=document.getElementById(''restable1'');
	for (i=0;i<='||g_sig_id||';i++)  
	{	
			x=document.getElementById(txt2.concat(i.toString()));   
	       if (!(x == null ))
		    {document.getElementById(txt2.concat(i.toString())).style.display = ''none'';}
		   x = document.getElementById(txt2.concat(i.toString(),''b''));  
			   if (!(x == null ))
				{x.innerHTML = x.innerHTML.replace("Hide SQL","Show SQL &amp; info");}
				 
			x = document.getElementById(txt.concat(i.toString(),''b''));  
	       if (!(x == null )){x.innerHTML = x.innerHTML.replace(String.fromCharCode(9660),String.fromCharCode(9654)); }
			
			x=document.getElementById(txt.concat(i.toString())); 
	       if (!(x == null )){document.getElementById(txt.concat(i.toString())).style.display = ''none'';}  	
		   }}
		 
	 function opentabs() {
     var tabCtrl = document.getElementById(''tabCtrl'');       
       for (var i = 0; i < tabCtrl.childNodes.length; i++) {
           var node = tabCtrl.childNodes[i];
           if (node.nodeType == 1 && node.toString() != ''[object HTMLScriptElement]'') { /* Element */
               node.style.display =  ''block'' ;
           }
        }
   }
   
    function closetabs() {
     var tabCtrl = document.getElementById(''tabCtrl'');       
       for (var i = 0; i < tabCtrl.childNodes.length; i++) {
           var node = tabCtrl.childNodes[i];
           if (node.nodeType == 1) { /* Element */
               node.style.display =  ''none'' ;
           }
        }
   }
		</script> ');	
	
EXCEPTION WHEN OTHERS THEN
  print_log('Error in print_toc_contents: '||sqlerrm);
  raise;
END print_toc_contents;

----------------------------------------------------------------
-- Evaluates if a rowcol meets desired criteria               --
----------------------------------------------------------------

FUNCTION evaluate_rowcol(p_oper varchar2, p_val varchar2, p_colv varchar2) return boolean is
  x   NUMBER;
  y   NUMBER;
  n   boolean := true;
BEGIN
  -- Attempt to convert to number the column value, otherwise proceed as string
  BEGIN
    x := to_number(p_colv);
    y := to_number(p_val);
  EXCEPTION WHEN OTHERS THEN
    n := false;
  END;
  -- Compare
  IF p_oper = '=' THEN
    IF n THEN
      return x = y;
    ELSE
      return p_val = p_colv;
    END IF;
  ELSIF p_oper = '>' THEN
    IF n THEN
      return x > y;
    ELSE
      return p_colv > p_val;
    END IF;
  ELSIF p_oper = '<' THEN
    IF n THEN
      return x < y;
    ELSE
      return p_colv < p_val;
    END IF;
  ELSIF p_oper = '<=' THEN
    IF n THEN
      return x <= y;
    ELSE
      return p_colv <= p_val;
    END IF;
  ELSIF p_oper = '>=' THEN
    IF n THEN
      return x >= y;
    ELSE
      return p_colv >= p_val;
    END IF;
  ELSIF p_oper = '!=' OR p_oper = '<>' THEN
    IF n THEN
      return x != y;
    ELSE
      return p_colv != p_val;
    END IF;
  END IF;
EXCEPTION WHEN OTHERS THEN
  print_log('Error in evaluate_rowcol');
  raise;
END evaluate_rowcol;

---------------------------------------------
-- Expand [note] or {patch} tokens         --
---------------------------------------------

FUNCTION expand_links(p_str VARCHAR2) return VARCHAR2 IS
  l_str VARCHAR2(32000);
  l_s VARCHAR2(20);
Begin
  -- Assign to working variable
  l_str := p_str;
  -- First deal with patches
  l_str := regexp_replace(l_str,'({)([0-9]*)(})',
    '<a target="_blank" href="'||g_mos_patch_url||'\2">Patch \2</a>',1,0);
  -- Same for notes
  l_str := regexp_replace(l_str,'(\[)([0-9]*\.[0-9])(\])',
    '<a target="_blank" href="'||g_mos_doc_url||'\2">Doc ID \2</a>',1,0);
  return l_str;
END expand_links;

--------------------------------------------
-- Prepare the SQL with the substitution values
--------------------------------------------

FUNCTION prepare_sql(
  p_signature_sql IN VARCHAR2
  ) RETURN VARCHAR2 IS
  l_sql VARCHAR2(32767);
  l_key VARCHAR2(255);
BEGIN
  -- Assign signature to working variable
  l_sql := p_signature_sql;
  --  Build the appropriate SQL replacing all applicable values
  --  with the appropriate parameters
  l_key := g_sql_tokens.first;
  WHILE l_key is not null LOOP
    l_sql := replace(l_sql, l_key, g_sql_tokens(l_key));
    l_key := g_sql_tokens.next(l_key);
  END LOOP;
  RETURN l_sql;
EXCEPTION WHEN OTHERS THEN
  print_log('Error in prepare_sql');
  raise;
END prepare_sql;

----------------------------------------------------------------
-- Set partial section result                                 --
----------------------------------------------------------------
PROCEDURE set_item_result(result varchar2) is
BEGIN
      IF g_sections(g_sections.last).result in ('U','I') THEN
          g_sections(g_sections.last).result := result;
      ELSIF g_sections(g_sections.last).result = 'S' THEN
        IF result in ('E','W') THEN
          g_sections(g_sections.last).result := result;
        END IF;   
      ELSIF g_sections(g_sections.last).result = 'W' THEN
        IF result = 'E' THEN
          g_sections(g_sections.last).result := result;
        END IF;
      END IF;
  -- Set counts
  IF result = 'S' THEN
    g_sections(g_sections.last).success_count :=
       g_sections(g_sections.last).success_count + 1;
  ELSIF result = 'W' THEN
    g_sections(g_sections.last).warn_count :=
       g_sections(g_sections.last).warn_count + 1;
  ELSIF result = 'E' THEN
    g_sections(g_sections.last).error_count :=
       g_sections(g_sections.last).error_count + 1;
  END IF;
EXCEPTION WHEN OTHERS THEN
  print_log('Error in set_item_result: '||sqlerrm);
  raise;
END set_item_result;

----------------------------------------------------------------------
-- Runs a single SQL using DBMS_SQL returns filled tables
-- Precursor to future run_signature which will call this and
-- the print api. For now calls are manual.
----------------------------------------------------------------------

PROCEDURE run_sig_sql(
   p_raw_sql      IN  VARCHAR2,     -- SQL in the signature may require substitution
   p_col_rows     OUT COL_LIST_TBL, -- signature SQL column names
   p_col_headings OUT VARCHAR_TBL, -- signature SQL row values
   p_limit_rows   IN  VARCHAR2 DEFAULT 'Y') IS

  l_sql            VARCHAR2(32767);
  c                INTEGER;
  l_rows_fetched   NUMBER;
  l_step           VARCHAR2(20);
  l_col_rows       COL_LIST_TBL := col_list_tbl();
  l_col_headings   VARCHAR_TBL := varchar_tbl();
  l_col_cnt        INTEGER;
  l_desc_rec_tbl   DBMS_SQL.DESC_TAB2;

BEGIN
  -- Prepare the Signature SQL
  l_step := '10';
  l_sql := prepare_sql(p_raw_sql);
  -- Add SQL with substitution to attributes table
  l_step := '20';
  c := dbms_sql.open_cursor;
  l_step := '30';
  DBMS_SQL.PARSE(c, l_sql, DBMS_SQL.NATIVE);
  -- Get column count and descriptions
  l_step := '40';
  DBMS_SQL.DESCRIBE_COLUMNS2(c, l_col_cnt, l_desc_rec_tbl);
  -- Register arrays to bulk collect results and set headings
  l_step := '50';
  FOR i IN 1..l_col_cnt LOOP
    l_step := '50.1.'||to_char(i);
    l_col_headings.extend();
    l_col_headings(i) := initcap(replace(l_desc_rec_tbl(i).col_name,'|','<br>'));
    l_col_rows.extend();
    dbms_sql.define_array(c, i, l_col_rows(i), g_max_output_rows, 1);
  END LOOP;
  -- Execute and Fetch
  l_step := '60';
  get_current_time(g_query_start_time);
  l_rows_fetched := DBMS_SQL.EXECUTE(c);
  l_rows_fetched := DBMS_SQL.FETCH_ROWS(c);
  debug(' Rows fetched: '||to_char(l_rows_fetched));
  l_step := '70';
  IF l_rows_fetched > 0 THEN
    FOR i in 1..l_col_cnt LOOP
      l_step := '70.1.'||to_char(i);
      DBMS_SQL.COLUMN_VALUE(c, i, l_col_rows(i));
    END LOOP;
  END IF;
  IF nvl(p_limit_rows,'Y') = 'N' THEN
    WHILE l_rows_fetched = g_max_output_rows LOOP
      l_rows_fetched := DBMS_SQL.FETCH_ROWS(c);
      debug(' Rows fetched: '||to_char(l_rows_fetched));
      FOR i in 1..l_col_cnt LOOP
        l_step := '70.2.'||to_char(i);
        DBMS_SQL.COLUMN_VALUE(c, i, l_col_rows(i));
      END LOOP;
    END LOOP;
  END IF;
  g_query_elapsed := stop_timer(g_query_start_time);
--  g_query_total := g_query_total + g_query_elapsed;

  -- Close cursor
  l_step := '80';
  IF dbms_sql.is_open(c) THEN
    dbms_sql.close_cursor(c);
  END IF;
  -- Set out parameters
  p_col_headings := l_col_headings;
  p_col_rows := l_col_rows;
EXCEPTION
  WHEN OTHERS THEN
    print_error('PROGRAM ERROR<br />
      Error in run_sig_sql at step '||
      l_step||': '||sqlerrm||'<br/>
      See the log file for additional details<br/>');
    print_log('Error at step '||l_step||' in run_sig_sql running: '||l_sql);
    print_log('Error: '||sqlerrm);
    l_col_cnt := -1;
    IF dbms_sql.is_open(c) THEN
      dbms_sql.close_cursor(c);
    END IF;
    g_errbuf := 'toto '||l_step;
END run_sig_sql;

PROCEDURE generate_hidden_xml(
  p_sig_id          VARCHAR2,
  p_sig             SIGNATURE_REC, -- Name of signature item
  p_col_rows        COL_LIST_TBL,  -- signature SQL row values
  p_col_headings    VARCHAR_TBL)    -- signature SQL column names       
IS

l_hidden_xml_doc       DBMS_XMLDOM.DOMDocument;
l_hidden_xml_node      DBMS_XMLDOM.DOMNode;
l_diagnostic_element   DBMS_XMLDOM.DOMElement;
l_diagnostic_node      DBMS_XMLDOM.DOMNode;
l_issues_node          DBMS_XMLDOM.DOMNode;
l_signature_node       DBMS_XMLDOM.DOMNode;
l_signature_element    DBMS_XMLDOM.DOMElement;
l_node                 DBMS_XMLDOM.DOMNode;
l_row_node             DBMS_XMLDOM.DOMNode;
l_failure_node         DBMS_XMLDOM.DOMNode;
l_run_details_node     DBMS_XMLDOM.DOMNode;
l_run_detail_data_node DBMS_XMLDOM.DOMNode;
l_detail_element       DBMS_XMLDOM.DOMElement;
l_detail_node          DBMS_XMLDOM.DOMNode;
l_detail_name_attribute DBMS_XMLDOM.DOMAttr;
l_parameters_node      DBMS_XMLDOM.DOMNode;
l_parameter_node       DBMS_XMLDOM.DOMNode;
l_col_node             DBMS_XMLDOM.DOMNode;
l_parameter_element    DBMS_XMLDOM.DOMElement;
l_col_element          DBMS_XMLDOM.DOMElement;
l_param_name_attribute DBMS_XMLDOM.DOMAttr;
l_failure_element      DBMS_XMLDOM.DOMElement;
l_sig_id_attribute     DBMS_XMLDOM.DOMAttr;
l_col_name_attribute   DBMS_XMLDOM.DOMAttr;
l_row_attribute        DBMS_XMLDOM.DOMAttr;
l_key                  VARCHAR2(255);
l_match                VARCHAR2(1);
l_rows                 NUMBER;
l_value                VARCHAR2(2000);


BEGIN

l_hidden_xml_doc := g_hidden_xml;

IF (DBMS_XMLDOM.isNULL(l_hidden_xml_doc)) THEN
   l_hidden_xml_doc := DBMS_XMLDOM.newDOMDocument;
   l_hidden_xml_node := DBMS_XMLDOM.makeNode(l_hidden_xml_doc);
   l_diagnostic_node := DBMS_XMLDOM.appendChild(l_hidden_xml_node,DBMS_XMLDOM.makeNode(DBMS_XMLDOM.createElement(l_hidden_xml_doc,'diagnostic')));

   l_run_details_node := DBMS_XMLDOM.appendChild(l_diagnostic_node,DBMS_XMLDOM.makeNode(DBMS_XMLDOM.createElement(l_hidden_xml_doc,'run_details')));   
   l_key := g_rep_info.first;
   WHILE l_key IS NOT NULL LOOP
   
     l_detail_element := DBMS_XMLDOM.createElement(l_hidden_xml_doc,'detail');
     l_detail_node := DBMS_XMLDOM.appendChild(l_run_details_node,DBMS_XMLDOM.makeNode(l_detail_element));
     l_detail_name_attribute:=DBMS_XMLDOM.setAttributeNode(l_detail_element,DBMS_XMLDOM.createAttribute(l_hidden_xml_doc,'name'));
     DBMS_XMLDOM.setAttribute(l_detail_element, 'name', l_key);
     l_node := DBMS_XMLDOM.appendChild(l_detail_node,DBMS_XMLDOM.makeNode(DBMS_XMLDOM.createTextNode(l_hidden_xml_doc,g_rep_info(l_key))));

     l_key := g_rep_info.next(l_key);

   END LOOP;

   l_parameters_node := DBMS_XMLDOM.appendChild(l_diagnostic_node,DBMS_XMLDOM.makeNode(DBMS_XMLDOM.createElement(l_hidden_xml_doc,'parameters')));
   l_key := g_parameters.first;
   WHILE l_key IS NOT NULL LOOP

     l_parameter_element := DBMS_XMLDOM.createElement(l_hidden_xml_doc,'parameter');
     l_parameter_node := DBMS_XMLDOM.appendChild(l_parameters_node,DBMS_XMLDOM.makeNode(l_parameter_element));
     l_param_name_attribute:=DBMS_XMLDOM.setAttributeNode(l_parameter_element,DBMS_XMLDOM.createAttribute(l_hidden_xml_doc,'name'));
     DBMS_XMLDOM.setAttribute(l_parameter_element, 'name', l_key);
     l_node := DBMS_XMLDOM.appendChild(l_parameter_node,DBMS_XMLDOM.makeNode(DBMS_XMLDOM.createTextNode(l_hidden_xml_doc,g_parameters(l_key))));

     l_key := g_parameters.next(l_key);


   END LOOP;
   
   l_issues_node := DBMS_XMLDOM.appendChild(l_diagnostic_node,DBMS_XMLDOM.makeNode(DBMS_XMLDOM.createElement(l_hidden_xml_doc,'issues')));   

END IF;


 IF p_sig_id IS NOT NULL THEN

   l_issues_node := DBMS_XMLDOM.getLastChild(DBMS_XMLDOM.getFirstChild(DBMS_XMLDOM.makeNode(l_hidden_xml_doc)));

   l_signature_element := DBMS_XMLDOM.createElement(l_hidden_xml_doc,'signature');
   l_sig_id_attribute := DBMS_XMLDOM.setAttributeNode(l_signature_element,DBMS_XMLDOM.createAttribute(l_hidden_xml_doc,'id'));
   l_signature_node := DBMS_XMLDOM.appendChild(l_issues_node,DBMS_XMLDOM.makeNode(l_signature_element));
   DBMS_XMLDOM.setAttribute(l_signature_element, 'id',p_sig_id);

   IF p_sig.limit_rows='Y' THEN
      l_rows := least(g_max_output_rows,p_col_rows(1).COUNT,50);
   ELSE
      l_rows := least(p_col_rows(1).COUNT,50);
   END IF;
   
   FOR i IN 1..l_rows LOOP

      l_failure_element := DBMS_XMLDOM.createElement(l_hidden_xml_doc,'failure');
      l_row_attribute := DBMS_XMLDOM.setAttributeNode(l_failure_element,DBMS_XMLDOM.createAttribute(l_hidden_xml_doc,'row'));     
      l_failure_node := DBMS_XMLDOM.appendChild(l_signature_node,DBMS_XMLDOM.makeNode(l_failure_element));
      DBMS_XMLDOM.setAttribute(l_failure_element, 'row', i);   
    
      FOR j IN 1..p_col_headings.count LOOP
 
         l_col_element := DBMS_XMLDOM.createElement(l_hidden_xml_doc,'column');
         l_col_name_attribute := DBMS_XMLDOM.setAttributeNode(l_col_element,DBMS_XMLDOM.createAttribute(l_hidden_xml_doc,'name'));
         l_col_node := DBMS_XMLDOM.appendChild(l_failure_node,DBMS_XMLDOM.makeNode(l_col_element));
         DBMS_XMLDOM.setAttribute(l_col_element, 'name',p_col_headings(j));
 
         l_value := p_col_rows(j)(i);

         IF p_sig_id = 'REC_PATCH_CHECK' THEN
            IF p_col_headings(j) = 'Patch' THEN
               l_value := replace(replace(p_col_rows(j)(i),'{'),'}');
            ELSIF p_col_headings(j) = 'Note' THEN
               l_value := replace(replace(p_col_rows(j)(i),'['),']');
            END IF;
         END IF;

		  -- Rtrim the column value if blanks are not to be preserved
          IF NOT g_preserve_trailing_blanks THEN
            l_value := RTRIM(l_value, ' ');
          END IF;
		  
         l_node := DBMS_XMLDOM.appendChild(l_col_node,DBMS_XMLDOM.makeNode(DBMS_XMLDOM.createTextNode(l_hidden_xml_doc,l_value)));

      END LOOP;
    END LOOP;
    
  END IF;  

  g_hidden_xml := l_hidden_xml_doc;


END generate_hidden_xml;


PROCEDURE print_hidden_xml
IS

l_hidden_xml_clob      clob;
l_offset               NUMBER := 1;
l_length               NUMBER;

l_node_list            DBMS_XMLDOM.DOMNodeList;
l_node_length          NUMBER;

BEGIN

IF DBMS_XMLDOM.isNULL(g_hidden_xml) THEN

   generate_hidden_xml(p_sig_id => null,
                       p_sig => null,
                       p_col_headings => null,
                       p_col_rows => null);
                       
END IF;                      

dbms_lob.createtemporary(l_hidden_xml_clob, true);

--print CLOB
DBMS_XMLDOM.WRITETOCLOB(g_hidden_xml, l_hidden_xml_clob); 

print_out('<!-- ######BEGIN DX SUMMARY######','Y');

LOOP
   EXIT WHEN (l_offset > dbms_lob.getlength(l_hidden_xml_clob) OR dbms_lob.getlength(l_hidden_xml_clob)=0);
   
      print_out(dbms_lob.substr(l_hidden_xml_clob,2000, l_offset),'N');

      l_offset := l_offset + 2000;
      
   END LOOP;
   
print_out('######END DX SUMMARY######-->','Y');  --should be a newline here

dbms_lob.freeTemporary(l_hidden_xml_clob);      
DBMS_XMLDOM.FREEDOCUMENT(g_hidden_xml);

END print_hidden_xml;

----------------------------------------------------------------
-- Once a signature has been run, evaluates and prints it     --
----------------------------------------------------------------
FUNCTION process_signature_results(
  p_sig_id          VARCHAR2,      -- signature id
  p_sig             SIGNATURE_REC, -- Name of signature item
  p_col_rows        COL_LIST_TBL,  -- signature SQL row values
  p_col_headings    VARCHAR_TBL,    -- signature SQL column names
  p_is_child        BOOLEAN    DEFAULT FALSE
  ) RETURN VARCHAR2 IS             -- returns 'E','W','S','I'

  l_sig_fail      BOOLEAN := false;
  l_row_fail      BOOLEAN := false;
  l_fail_flag     BOOLEAN := false;
  l_html          VARCHAR2(32767) := null;
  l_column        VARCHAR2(255) := null;
  l_operand       VARCHAR2(3);
  l_value         VARCHAR2(4000);
  l_step          VARCHAR2(255);
  l_i             VARCHAR2(255);
  l_curr_col      VARCHAR2(255) := NULL;
  l_curr_val      VARCHAR2(4000) := NULL;
  l_print_sql_out BOOLEAN := true;
  l_inv_param     EXCEPTION;
  l_rows_fetched  NUMBER := p_col_rows(1).count;
  l_printing_cols NUMBER := 0;
  l_is_child      BOOLEAN;
  l_error_type    VARCHAR2(1);  

BEGIN
  -- Validate parameters which have fixed values against errors when
  -- defining or loading signatures
  l_is_child := p_is_child;
    IF (NOT l_is_child) THEN
       g_family_result := '';
    END IF;
  l_step := 'Validate parameters';
  IF (p_sig.fail_condition NOT IN ('RSGT1','RS','NRS')) AND
     ((instr(p_sig.fail_condition,'[') = 0) OR
      (instr(p_sig.fail_condition,'[',1,2) = 0) OR
      (instr(p_sig.fail_condition,']') = 0) OR
      (instr(p_sig.fail_condition,']',1,2) = 0))  THEN
    print_log('Invalid value or format for failure condition: '||
      p_sig.fail_condition);
    raise l_inv_param;
  ELSIF p_sig.print_condition NOT IN ('SUCCESS','FAILURE','ALWAYS','NEVER') THEN
    print_log('Invalid value for print_condition: '||p_sig.print_condition);
    raise l_inv_param;
  ELSIF p_sig.fail_type NOT IN ('E','W','I') THEN
    print_log('Invalid value for fail_type: '||p_sig.fail_type);
    raise l_inv_param;
  ELSIF p_sig.print_sql_output NOT IN ('Y','N','RS') THEN
    print_log('Invalid value for print_sql_output: '||p_sig.print_sql_output);
    raise l_inv_param;
  ELSIF p_sig.limit_rows NOT IN ('Y','N') THEN
    print_log('Invalid value for limit_rows: '||p_sig.limit_rows);
    raise l_inv_param;
  ELSIF p_sig.print_condition in ('ALWAYS','SUCCESS') AND
        p_sig.success_msg is null AND p_sig.print_sql_output = 'N' THEN
    print_log('Invalid parameter combination.');
    print_log('print_condition/success_msg/print_sql_output: '||
      p_sig.print_condition||'/'||nvl(p_sig.success_msg,'null')||
      '/'||p_sig.print_sql_output);
    print_log('When printing on success either success msg or SQL output '||
        'printing should be enabled.');
    raise l_inv_param;
  END IF;
  -- For performance sake: first make trivial evaluations of success
  -- and if no need to print just return
  l_step := '10';
  IF (p_sig.print_condition IN ('NEVER','FAILURE') AND
	 ((p_sig.fail_condition = 'RSGT1' AND l_rows_fetched = 0) OR
      (p_sig.fail_condition = 'RS' AND l_rows_fetched = 0) OR
      (p_sig.fail_condition = 'NRS' AND l_rows_fetched > 0))) THEN
    IF p_sig.fail_type = 'I' THEN
      return 'I';
    ELSE
      return 'S';
    END IF;
  ELSIF (p_sig.print_condition IN ('NEVER','SUCCESS') AND
		((p_sig.fail_condition = 'RSGT1' AND l_rows_fetched > 1) OR
        (p_sig.fail_condition = 'RS' AND l_rows_fetched > 0) OR
         (p_sig.fail_condition = 'NRS' AND l_rows_fetched = 0))) THEN
    return p_sig.fail_type;
  END IF;

  l_print_sql_out := (nvl(p_sig.print_sql_output,'Y') = 'Y' OR
					 (p_sig.print_sql_output = 'RSGT1' AND l_rows_fetched > 1) OR
                     (p_sig.print_sql_output = 'RS' AND l_rows_fetched > 0) OR
                      p_sig.child_sigs.count > 0 AND l_rows_fetched > 0);

  -- Determine signature failure status
  IF p_sig.fail_condition NOT IN ('RSGT1','RS','NRS') THEN
    -- Get the column to evaluate, if any
    l_step := '20';
    l_column := upper(substr(ltrim(p_sig.fail_condition),2,instr(p_sig.fail_condition,']') - 2));
    l_operand := rtrim(ltrim(substr(p_sig.fail_condition, instr(p_sig.fail_condition,']')+1,
      (instr(p_sig.fail_condition,'[',1,2)-instr(p_sig.fail_condition,']') - 1))));
    l_value := substr(p_sig.fail_condition, instr(p_sig.fail_condition,'[',2)+1,
      (instr(p_sig.fail_condition,']',1,2)-instr(p_sig.fail_condition,'[',1,2)-1));

    l_step := '30';
    FOR i IN 1..least(l_rows_fetched, g_max_output_rows) LOOP
      l_step := '40';
      FOR j IN 1..p_col_headings.count LOOP
        l_step := '40.1.'||to_char(j);
        l_row_fail := false;
        l_curr_col := upper(p_col_headings(j));
        l_curr_val := p_col_rows(j)(i);
        IF nvl(l_column,'&&&') = l_curr_col THEN
          l_step := '40.2.'||to_char(j);
          l_row_fail := evaluate_rowcol(l_operand, l_value, l_curr_val);
          IF l_row_fail THEN
            l_fail_flag := true;
          END IF;
        END IF;
      END LOOP;
    END LOOP;
  END IF;

  -- Evaluate this signature
  l_step := '50';
  l_sig_fail := l_fail_flag OR
				(p_sig.fail_condition = 'RSGT1' AND l_rows_fetched > 1) OR
                (p_sig.fail_condition = 'RS' AND l_rows_fetched > 0) OR
                (p_sig.fail_condition = 'NRS' and l_rows_fetched = 0);

  l_step := '55';
  IF (l_sig_fail AND p_sig.include_in_xml='Y') THEN
     generate_hidden_xml(p_sig_id => p_sig_id,
                         p_sig => p_sig,
                         p_col_headings => p_col_headings,
                         p_col_rows => p_col_rows);
  END IF;

  -- If success and no print just return
  l_step := '60';
  IF ((NOT l_sig_fail) AND p_sig.print_condition IN ('FAILURE','NEVER')) THEN
    IF p_sig.fail_type = 'I' THEN
      return 'I';
    ELSE
      return 'S';
    END IF;
  ELSIF (l_sig_fail AND (p_sig.print_condition IN ('SUCCESS','NEVER'))) THEN
    return p_sig.fail_type;
  END IF;

  -- Print container div
  l_html := '<div class="divItem" id="sig'||p_sig_id||'">';

  -- Print title div
  l_step := '70';
   	g_sig_id := g_sig_id + 1;
	l_html := l_html || ' <div class="divItemTitle">' || '<a name="restable'||p_sig.title||'b"></a> <a id="restable'||to_char(g_sig_id)||'b'||'" class="detail" href="javascript:;" onclick="displayItem(this, ''restable' ||
      to_char(g_sig_id) ||''');">&#9654; '||p_sig.title||'</a>';
	
  -- Print collapsable/expandable extra info table if there are contents
  l_step := '80';
  IF p_sig.extra_info.count > 0 OR p_sig.sig_sql is not null THEN
    g_item_id := g_item_id + 1;
    l_step := '90';
    -- Print the triangle and javascript
    l_html := l_html || '
      <a class="detailsmall" id="tbitm' || to_char(g_item_id) || 'b" href="javascript:;" onclick="displayItem(this, ''tbitm' ||
      to_char(g_item_id) ||''');"><font color="#0066CC">(Show SQL &amp; info)</font></a></div>';
    -- Print the table with extra information in hidden state
    l_step := '100';
    l_html := l_html || '
      <table class="table1" id="tbitm' || to_char(g_item_id) ||
      '" style="display:none">
      <tbody><tr><th>Item Name</th><th>Item Value</th></tr>';
    -- Loop and print values
    l_step := '110';
    l_i := p_sig.extra_info.FIRST;
    WHILE l_i IS NOT NULL LOOP
      l_step := '110.1.'||l_i;
      l_html := l_html || '<tr><td>' || l_i || '</td><td>'||
        p_sig.extra_info(l_i) || '</td></tr>';
      l_step := '110.2.'||l_i;
      l_i := p_sig.extra_info.next(l_i);
    END LOOP;
    IF p_sig.sig_sql is not null THEN
      l_step := '120';
      l_html := l_html || '
         <tr><td>SQL</td><td><pre>'|| prepare_sql(p_sig.sig_sql) ||
         '</pre></td></tr>';
    END IF;
  ELSE -- no extra info or SQL to print
    l_step := '130';
    l_html := l_html || '</div>';
  END IF;

  l_step := '140';
  l_html := l_html || '</tbody></table>';

  -- Print the header SQL info table
  print_out(expand_links(l_html));
  l_html := null;

  IF l_print_sql_out THEN
    IF p_sig.child_sigs.count = 0 THEN
      -- Print the actual results table
      -- Table header
      l_step := '150';
      l_html := '<div class="divtable"><table class="table1" id="restable' || to_char(g_sig_id) ||
      '" style="display:none"><tbody>';
      -- Column headings
      l_html := l_html || '<tr>';
      l_step := '160';
      FOR i IN 1..p_col_headings.count LOOP
        l_html := l_html || '
          <th>'||nvl(p_col_headings(i),'&nbsp;')||'</th>';
      END LOOP;
      l_html := l_html || '</tr>';
      -- Print headers
      print_out(expand_links(l_html));
      -- Row values
      l_step := '170';
      FOR i IN 1..l_rows_fetched LOOP
        l_html := '<tr>';
        l_step := '170.1.'||to_char(i);
        FOR j IN 1..p_col_headings.count LOOP
          -- Evaluate if necessary
          l_step := '170.2.'||to_char(j);
          l_row_fail := false;
          l_step := '170.3.'||to_char(j);
          l_curr_col := upper(p_col_headings(j));
          l_step := '170.4.'||to_char(j);
          l_curr_val := p_col_rows(j)(i);
          l_step := '170.5.'||to_char(j);
          IF nvl(l_column,'&&&') = l_curr_col THEN
            l_step := '170.6.'||
              substr('['||l_operand||']['||l_value||']['||l_curr_val||']',1,96);
            l_row_fail := evaluate_rowcol(l_operand, l_value, l_curr_val);
          END IF;
		  
		   -- Encode blanks as HTML space if this analyzer is set so by g_preserve_trailing_blanks
		   -- this ensures trailing blanks added for padding are honored by browsers
		   -- affects only printing, DX summary handled separately
		   IF g_preserve_trailing_blanks THEN
			 l_curr_Val := RPAD(RTRIM(l_curr_Val,' '),
			  -- pad length is the number of spaces existing times the length of &nbsp; => 6
			 (length(l_curr_Val) - length(RTRIM(l_curr_Val,' '))) * 6 + length(RTRIM(l_curr_Val,' ')),
			 '&nbsp;');
		   ELSE
			 l_curr_Val := RTRIM(l_curr_Val, ' ');
		   END IF;
	   		  
          -- Print
          l_step := '170.7.'||to_char(j);
          IF l_row_fail THEN
            l_html := l_html || '
              <td class="hlt">' || l_curr_Val || '</td>';
          ELSE
            l_html := l_html || '
              <td>' || l_curr_val || '</td>';
          END IF;
        END LOOP;
        l_html := l_html || '</tr>';
        print_out(expand_links(l_html));
      END LOOP;
	  
	l_html := '<tr><th colspan="100%"><b><i><font style="font-size:x-small; color:#333333">';
      IF p_sig.limit_rows = 'N' OR l_rows_fetched < g_max_output_rows THEN
        l_html := l_html || l_rows_fetched || ' rows selected';
      ELSE
        l_html := l_html ||'Displaying first '||to_char(g_max_output_rows);
      END IF;
      l_html := l_html ||' - Elapsed time: ' || format_elapsed(g_query_elapsed) || '
        </font></i></b><br>';
	  l_html := l_html || '</th></tr>';
      print_out(l_html);

      -- End of results and footer
      l_step := '180';
      l_html :=  '</tbody></table></div>';
      l_step := '190';
      print_out(l_html);
--
    ELSE -- there are children signatures
      -- Print master rows and call appropriate processes for the children
      -- Table header
      l_html := '<div class="divtable"><table class="table1" id="restable' || to_char(g_sig_id) ||
      '" style="display:none"><tbody>';
      -- Row values
      l_step := '200';
      FOR i IN 1..l_rows_fetched LOOP
        l_step := '200.1.'||to_char(i);
        -- Column headings printed for each row
        l_html := l_html || '<tr>';
        FOR j IN 1..p_col_headings.count LOOP
          l_step := '200.2.'||to_char(j);
          IF upper(nvl(p_col_headings(j),'XXX')) not like '##$$FK_$$##' THEN
            l_html := l_html || '
              <th class="master">'||nvl(p_col_headings(j),'&nbsp;')||'</th>';
          END IF;
        END LOOP;
        l_step := '200.3';
        l_html := l_html || '</tr>';
        -- Print headers
        print_out(expand_links(l_html));
        -- Print a row
        l_html := '<tr class="master">';

        l_printing_cols := 0;
        FOR j IN 1..p_col_headings.count LOOP
          l_step := '200.4.'||to_char(j);

          l_curr_col := upper(p_col_headings(j));
          l_curr_val := p_col_rows(j)(i);

          -- If the col is a FK set the global replacement vals
          IF l_curr_col like '##$$FK_$$##' THEN
            l_step := '200.5';
            g_sql_tokens(l_curr_col) := l_curr_val;
          ELSE -- printable column
            l_printing_cols := l_printing_cols + 1;
            -- Evaluate if necessary
            l_row_fail := false;
            IF nvl(l_column,'&&&') = l_curr_col THEN
              l_step := '200.6'||
                substr('['||l_operand||']['||l_value||']['||l_curr_val||']',1,96);
              l_row_fail := evaluate_rowcol(l_operand, l_value, l_curr_val);
            END IF;
		  
		   -- Encode blanks as HTML space if this analyzer is set so by g_preserve_trailing_blanks
		   -- this ensures trailing blanks added for padding are honored by browsers
		   -- affects only printing, DX summary handled separately
		   IF g_preserve_trailing_blanks THEN
			 l_curr_Val := RPAD(RTRIM(l_curr_Val,' '),
			  -- pad length is the number of spaces existing times the length of &nbsp; => 6
			 (length(l_curr_Val) - length(RTRIM(l_curr_Val,' '))) * 6 + length(RTRIM(l_curr_Val,' ')),
			 '&nbsp;');
		   ELSE
			 l_curr_Val := RTRIM(l_curr_Val, ' ');
		   END IF;
	   			
            -- Print
            IF l_row_fail THEN
              l_html := l_html || '
                <td class="hlt">' || l_curr_Val || '</td>';
            ELSE
              l_html := l_html || '
                <td>' || l_curr_val || '</td>';
            END IF;
          END IF;
        END LOOP;
        l_html := l_html || '</tr>';
        print_out(expand_links(l_html));
        l_html := null;
        FOR i IN p_sig.child_sigs.first..p_sig.child_sigs.last LOOP
          print_out('<tr><td colspan="'||to_char(l_printing_cols)||
            '"><blockquote>');
          DECLARE
            l_col_rows  COL_LIST_TBL := col_list_tbl();
            l_col_hea   VARCHAR_TBL := varchar_tbl();
            l_child_sig SIGNATURE_REC;
            l_result    VARCHAR2(1);
          BEGIN
           l_child_sig := g_signatures(p_sig.child_sigs(i));
           print_log('Processing child signature: '||p_sig.child_sigs(i));
           run_sig_sql(l_child_sig.sig_sql, l_col_rows, l_col_hea,
             l_child_sig.limit_rows);
           l_result := process_signature_results(p_sig.child_sigs(i),
             l_child_sig, l_col_rows, l_col_hea, TRUE);
           set_item_result(l_result);

		 -- show parent signature failure based on result from child signature(s)
         IF l_result in ('W','E') THEN
             l_fail_flag := true;
           IF l_result = 'E' THEN
             l_error_type := 'E';
           ELSIF (l_result = 'W') AND ((l_error_type is NULL) OR (l_error_type != 'E')) THEN
             l_error_type := 'W';
           END IF;
           g_family_result := l_error_type;
         END IF;

          EXCEPTION WHEN OTHERS THEN
            print_log('Error processing child signature: '||p_sig.child_sigs(i));
            print_log('Error: '||sqlerrm);
            raise;
          END;

          print_out('</blockquote></td></tr>');
        END LOOP;
      END LOOP;
      --l_sig_fail := (l_sig_fail OR l_fail_flag);

      -- End of results and footer
      l_step := '210';
      l_html :=  '</tbody></table></div>
        <font style="font-size:x-small; color:#333333">';
      l_step := '220';
      IF p_sig.limit_rows = 'N' OR l_rows_fetched < g_max_output_rows THEN
        l_html := l_html || l_rows_fetched || ' rows selected';
      ELSE
        l_html := l_html ||'Displaying first '||to_char(g_max_output_rows);
      END IF;
      l_html := l_html ||' - Elapsed time: ' || format_elapsed(g_query_elapsed) || '
        </font><br>';
      print_out(l_html);
    END IF; -- master or child
  END IF; -- print output is true

  -- Print actions
  IF l_sig_fail THEN
    l_step := '230';
    IF p_sig.fail_type = 'E' THEN
      l_html := '<div class="divuar"><span class="divuar1"><img class="error_ico"> Error:</span>' ||
        p_sig.problem_descr;
    ELSIF p_sig.fail_type = 'W' THEN
      l_html := '<div class="divwarn"><span class="divwarn1"><img class="warn_ico"> Warning:</span>' ||
        p_sig.problem_descr;
    ELSE
      l_html := '<div class="divok"><span class="divok1">Information:</span>' ||
        p_sig.problem_descr;
    END IF;

    -- Print solution only if passed
    l_step := '240';
    IF p_sig.solution is not null THEN
      l_html := l_html || '
        <br><br><span class="solution">Findings and Recommendations:</span><br>
        ' || p_sig.solution;
    END IF;

    -- Close div here cause success div is conditional
    l_html := l_html || '</div>';
  ELSE
    l_step := '250';
    IF p_sig.success_msg is not null THEN
      IF p_sig.fail_type = 'I' THEN
        l_html := '
          <br><div class="divok"><div class="divok1">Information:</div>'||
          nvl(p_sig.success_msg, 'No instances of this problem found') ||
          '</div>';
      ELSE
        l_html := '
          <br><div class="divok"><div class="divok1"><img class="check_ico"> All checks passed.</div>'||
          nvl(p_sig.success_msg,
          'No instances of this problem found') ||
          '</div>';
      END IF;
    ELSE
      l_html := null;
    END IF;
  END IF;

    -- DIV for parent
 IF p_sig.child_sigs.count > 0 and NOT (l_is_child) THEN
        IF g_family_result = 'E' THEN 
           l_html := l_html || '
             <div class="divuar"><div class="divuar1"><img class="error_ico"> There was an error reported in one of the child checks. Please expand the section for more information.</div></div>';	
        ELSIF g_family_result = 'W' THEN
           l_html := l_html || '
             <div class="divwarn"><div class="divwarn1"><img class="warn_ico"> There was an issue reported in one of the child checks. Please expand the section for more information.</div></div>';	
        END IF;     
      END IF;
	  
  -- Add final tags
  l_html := l_html || '
    </div>' || '<br><font style="font-size:x-small;">
    <a href="#top"><font color="#0066CC">Back to top</font></a></font><br>' || '<br>';
	 
   --Code for Table of Contents of each section  
   g_section_sig := g_section_sig + 1;
   sig_count := g_section_sig;  
   
   IF NOT (l_is_child) THEN
     -- for even # signatures
   g_parent_sig_count := g_parent_sig_count + 1;
   IF MOD(g_parent_sig_count, 2) = 0 THEN

   g_section_toc := g_section_toc || '<td>' || '<a href="#restable'||to_char(g_sig_id)||'b">'||p_sig.title||'</a> ';
   
       IF ((l_sig_fail) AND (p_sig.fail_type ='E' OR l_error_type = 'E')) OR (g_family_result = 'E') THEN
         g_section_toc := g_section_toc || '<img class="error_ico">';      
       ELSIF ((l_sig_fail) AND (p_sig.fail_type ='W' OR l_error_type = 'W')) OR (g_family_result = 'W') THEN
         g_section_toc := g_section_toc ||'<img class="warn_ico">';        
       END IF; 
	   
   g_section_toc := g_section_toc || '</td></tr>';
   
   ELSE
     -- for odd # signatures start the row
   g_section_toc := g_section_toc || '<tr class="toctable"><td>' || '<a href="#restable'||to_char(g_sig_id)||'b">'||p_sig.title||'</a> ';
   
       IF ((l_sig_fail) AND (p_sig.fail_type ='E' OR l_error_type = 'E')) OR (g_family_result = 'E') THEN
         g_section_toc := g_section_toc || '<img class="error_ico">';      
       ELSIF ((l_sig_fail) AND (p_sig.fail_type ='W' OR l_error_type = 'W')) OR (g_family_result = 'W') THEN
         g_section_toc := g_section_toc ||'<img class="warn_ico">';        
       END IF;
	   
   g_section_toc := g_section_toc || '</td>';   
    
	END IF;
	
  END IF;	
   
	 
  -- Increment the print count for the section	   
  l_step := '260';
  g_sections(g_sections.last).print_count :=
       g_sections(g_sections.last).print_count + 1;

  -- Print
  l_step := '270';
  print_out(expand_links(l_html));
   
	 
  IF l_sig_fail THEN
    l_step := '280';
    return p_sig.fail_type;
  ELSE
    l_step := '290';
    IF p_sig.fail_type = 'I' THEN
      return 'I';
    ELSE
      return 'S';
    END IF;
  END IF;
  

  
EXCEPTION
  WHEN L_INV_PARAM THEN
    print_log('Invalid parameter error in process_signature_results at step '
      ||l_step);
    raise;
  WHEN OTHERS THEN
    print_log('Error in process_signature_results at step '||l_step);
    g_errbuf := l_step;
    raise;
END process_signature_results;

------------------------------------------------------------------------------
-- Once a signature has been run, evaluates and prints a sortable table     --
------------------------------------------------------------------------------
FUNCTION sortable_table_results(
  p_sig_id          VARCHAR2,      -- signature id
  p_sig             SIGNATURE_REC, -- Name of signature item
  p_col_rows        COL_LIST_TBL,  -- signature SQL row values
  p_col_headings    VARCHAR_TBL,    -- signature SQL column names
  p_is_child        BOOLEAN    DEFAULT FALSE
  ) RETURN VARCHAR2 IS             -- returns 'E','W','S','I'

  l_sig_fail      BOOLEAN := false;
  l_row_fail      BOOLEAN := false;
  l_fail_flag     BOOLEAN := false;
  l_html          VARCHAR2(32767) := null;
  l_column        VARCHAR2(255) := null;
  l_operand       VARCHAR2(3);
  l_value         VARCHAR2(4000);
  l_step          VARCHAR2(255);
  l_i             VARCHAR2(255);
  l_curr_col      VARCHAR2(255) := NULL;
  l_curr_val      VARCHAR2(4000) := NULL;
  l_print_sql_out BOOLEAN := true;
  l_inv_param     EXCEPTION;
  l_rows_fetched  NUMBER := p_col_rows(1).count;
  l_printing_cols NUMBER := 0;
  l_is_child      BOOLEAN;
  l_error_type    VARCHAR2(1);
  
BEGIN
  -- Validate parameters which have fixed values against errors when
  -- defining or loading signatures
  l_is_child := p_is_child;
    IF (NOT l_is_child) THEN
       g_family_result := '';
    END IF;
  l_step := 'Validate parameters';
  IF (p_sig.fail_condition NOT IN ('RSGT1','RS','NRS')) AND
     ((instr(p_sig.fail_condition,'[') = 0) OR
      (instr(p_sig.fail_condition,'[',1,2) = 0) OR
      (instr(p_sig.fail_condition,']') = 0) OR
      (instr(p_sig.fail_condition,']',1,2) = 0))  THEN
    print_log('Invalid value or format for failure condition: '||
      p_sig.fail_condition);
    raise l_inv_param;
  ELSIF p_sig.print_condition NOT IN ('SUCCESS','FAILURE','ALWAYS','NEVER') THEN
    print_log('Invalid value for print_condition: '||p_sig.print_condition);
    raise l_inv_param;
  ELSIF p_sig.fail_type NOT IN ('E','W','I') THEN
    print_log('Invalid value for fail_type: '||p_sig.fail_type);
    raise l_inv_param;
  ELSIF p_sig.print_sql_output NOT IN ('Y','N','RS') THEN
    print_log('Invalid value for print_sql_output: '||p_sig.print_sql_output);
    raise l_inv_param;
  ELSIF p_sig.limit_rows NOT IN ('Y','N') THEN
    print_log('Invalid value for limit_rows: '||p_sig.limit_rows);
    raise l_inv_param;
  ELSIF p_sig.print_condition in ('ALWAYS','SUCCESS') AND
        p_sig.success_msg is null AND p_sig.print_sql_output = 'N' THEN
    print_log('Invalid parameter combination.');
    print_log('print_condition/success_msg/print_sql_output: '||
      p_sig.print_condition||'/'||nvl(p_sig.success_msg,'null')||
      '/'||p_sig.print_sql_output);
    print_log('When printing on success either success msg or SQL output '||
        'printing should be enabled.');
    raise l_inv_param;
  END IF;
  -- For performance sake: first make trivial evaluations of success
  -- and if no need to print just return
  l_step := '10';
  IF (p_sig.print_condition IN ('NEVER','FAILURE') AND
	 ((p_sig.fail_condition = 'RSGT1' AND l_rows_fetched = 0) OR
      (p_sig.fail_condition = 'RS' AND l_rows_fetched = 0) OR
      (p_sig.fail_condition = 'NRS' AND l_rows_fetched > 0))) THEN
    IF p_sig.fail_type = 'I' THEN
      return 'I';
    ELSE
      return 'S';
    END IF;
  ELSIF (p_sig.print_condition IN ('NEVER','SUCCESS') AND
		((p_sig.fail_condition = 'RSGT1' AND l_rows_fetched > 1) OR
        (p_sig.fail_condition = 'RS' AND l_rows_fetched > 0) OR
         (p_sig.fail_condition = 'NRS' AND l_rows_fetched = 0))) THEN
    return p_sig.fail_type;
  END IF;

  l_print_sql_out := (nvl(p_sig.print_sql_output,'Y') = 'Y' OR
					 (p_sig.print_sql_output = 'RSGT1' AND l_rows_fetched > 1) OR
                     (p_sig.print_sql_output = 'RS' AND l_rows_fetched > 0) OR
                      p_sig.child_sigs.count > 0 AND l_rows_fetched > 0);

  -- Determine signature failure status
  IF p_sig.fail_condition NOT IN ('RSGT1','RS','NRS') THEN
    -- Get the column to evaluate, if any
    l_step := '20';
    l_column := upper(substr(ltrim(p_sig.fail_condition),2,instr(p_sig.fail_condition,']') - 2));
    l_operand := rtrim(ltrim(substr(p_sig.fail_condition, instr(p_sig.fail_condition,']')+1,
      (instr(p_sig.fail_condition,'[',1,2)-instr(p_sig.fail_condition,']') - 1))));
    l_value := substr(p_sig.fail_condition, instr(p_sig.fail_condition,'[',2)+1,
      (instr(p_sig.fail_condition,']',1,2)-instr(p_sig.fail_condition,'[',1,2)-1));

    l_step := '30';
    FOR i IN 1..least(l_rows_fetched, g_max_output_rows) LOOP
      l_step := '40';
      FOR j IN 1..p_col_headings.count LOOP
        l_step := '40.1.'||to_char(j);
        l_row_fail := false;
        l_curr_col := upper(p_col_headings(j));
        l_curr_val := p_col_rows(j)(i);
        IF nvl(l_column,'&&&') = l_curr_col THEN
          l_step := '40.2.'||to_char(j);
          l_row_fail := evaluate_rowcol(l_operand, l_value, l_curr_val);
          IF l_row_fail THEN
            l_fail_flag := true;
          END IF;
        END IF;
      END LOOP;
    END LOOP;
  END IF;

  -- Evaluate this signature
  l_step := '50';
  l_sig_fail := l_fail_flag OR
				(p_sig.fail_condition = 'RSGT1' AND l_rows_fetched > 1) OR
                (p_sig.fail_condition = 'RS' AND l_rows_fetched > 0) OR
                (p_sig.fail_condition = 'NRS' and l_rows_fetched = 0);

  l_step := '55';
  IF (l_sig_fail AND p_sig.include_in_xml='Y') THEN
     generate_hidden_xml(p_sig_id => p_sig_id,
                         p_sig => p_sig,
                         p_col_headings => p_col_headings,
                         p_col_rows => p_col_rows);
  END IF;

  -- If success and no print just return
  l_step := '60';
  IF ((NOT l_sig_fail) AND p_sig.print_condition IN ('FAILURE','NEVER')) THEN
    IF p_sig.fail_type = 'I' THEN
      return 'I';
    ELSE
      return 'S';
    END IF;
  ELSIF (l_sig_fail AND (p_sig.print_condition IN ('SUCCESS','NEVER'))) THEN
    return p_sig.fail_type;
  END IF;

  -- Print container div
  l_html := '<div class="divItem" id="sig'||p_sig_id||'">';

  -- Print title div
  l_step := '70';
   	g_sig_id := g_sig_id + 1;
	l_html := l_html || ' <div class="divItemTitle">' || '<a name="restable'||p_sig.title||'b"></a> <a id="restable'||to_char(g_sig_id)||'b'||'" class="detail" href="javascript:;" onclick="displayItem(this, ''restable' ||
      to_char(g_sig_id) ||''');">&#9654; '||p_sig.title||'</a>';
	
  -- Print collapsable/expandable extra info table if there are contents
  l_step := '80';
  IF p_sig.extra_info.count > 0 OR p_sig.sig_sql is not null THEN
    g_item_id := g_item_id + 1;
    l_step := '90';
    -- Print the triangle and javascript
    l_html := l_html || '
      <a class="detailsmall" id="tbitm' || to_char(g_item_id) || 'b" href="javascript:;" onclick="displayItem(this, ''tbitm' ||
      to_char(g_item_id) ||''');"><font color="#0066CC">(Show SQL &amp; info)</font></a></div>';
    -- Print the table with extra information in hidden state
    l_step := '100';
    l_html := l_html || '
    <table class="tablesorter" id="ProfileOpts" style="display:none">
      <THEAD><tbody><tr><th>Item Name</th><th>Item Value</th></tr>';
    -- Loop and print values
    l_step := '110';
    l_i := p_sig.extra_info.FIRST;
    WHILE l_i IS NOT NULL LOOP
      l_step := '110.1.'||l_i;
      l_html := l_html || '<tr><td>' || l_i || '</td><td>'||
        p_sig.extra_info(l_i) || '</td></tr>';
      l_step := '110.2.'||l_i;
      l_i := p_sig.extra_info.next(l_i);
    END LOOP;
    IF p_sig.sig_sql is not null THEN
      l_step := '120';
      l_html := l_html || '
         <tr><td>SQL</td><td><pre>'|| prepare_sql(p_sig.sig_sql) ||
         '</pre></td></tr>';
    END IF;
  ELSE -- no extra info or SQL to print
    l_step := '130';
    l_html := l_html || '</div>';
  END IF;

  l_step := '140';
  l_html := l_html || '</tbody></table>';

  -- Print the header SQL info table
  print_out(expand_links(l_html));
  l_html := null;

  IF l_print_sql_out THEN
    IF p_sig.child_sigs.count = 0 THEN
      -- Print the actual results table
      -- Table header
      l_step := '150';
      l_html := '<div class="divtable"><table class="table1" id="restable' || to_char(g_sig_id) ||
      '" style="display:none"><tbody>';
      -- Column headings
      l_html := l_html || '<tr>';
      l_step := '160';
      FOR i IN 1..p_col_headings.count LOOP
        l_html := l_html || '
          <th>'||nvl(p_col_headings(i),'&nbsp;')||'</th>';
      END LOOP;
      l_html := l_html || '</tr>';
      -- Print headers
      print_out(expand_links(l_html));
      -- Row values
      l_step := '170';
      FOR i IN 1..l_rows_fetched LOOP
        l_html := '<tr>';
        l_step := '170.1.'||to_char(i);
        FOR j IN 1..p_col_headings.count LOOP
          -- Evaluate if necessary
          l_step := '170.2.'||to_char(j);
          l_row_fail := false;
          l_step := '170.3.'||to_char(j);
          l_curr_col := upper(p_col_headings(j));
          l_step := '170.4.'||to_char(j);
          l_curr_val := p_col_rows(j)(i);
          l_step := '170.5.'||to_char(j);
          IF nvl(l_column,'&&&') = l_curr_col THEN
            l_step := '170.6.'||
              substr('['||l_operand||']['||l_value||']['||l_curr_val||']',1,96);
            l_row_fail := evaluate_rowcol(l_operand, l_value, l_curr_val);
          END IF;
		  
		   -- Encode blanks as HTML space if this analyzer is set so by g_preserve_trailing_blanks
		   -- this ensures trailing blanks added for padding are honored by browsers
		   -- affects only printing, DX summary handled separately
		   IF g_preserve_trailing_blanks THEN
			 l_curr_Val := RPAD(RTRIM(l_curr_Val,' '),
			  -- pad length is the number of spaces existing times the length of &nbsp; => 6
			 (length(l_curr_Val) - length(RTRIM(l_curr_Val,' '))) * 6 + length(RTRIM(l_curr_Val,' ')),
			 '&nbsp;');
		   ELSE
			 l_curr_Val := RTRIM(l_curr_Val, ' ');
		   END IF;
	   			
          -- Print
          l_step := '170.7.'||to_char(j);
          IF l_row_fail THEN
            l_html := l_html || '
              <td class="hlt">' || l_curr_Val || '</td>';
          ELSE
            l_html := l_html || '
              <td>' || l_curr_val || '</td>';
          END IF;
        END LOOP;
        l_html := l_html || '</tr>';
        print_out(expand_links(l_html));
      END LOOP;
	  
	l_html := '<tr><th colspan="100%"><b><i><font style="font-size:x-small; color:#333333">';
      IF p_sig.limit_rows = 'N' OR l_rows_fetched < g_max_output_rows THEN
        l_html := l_html || l_rows_fetched || ' rows selected';
      ELSE
        l_html := l_html ||'Displaying first '||to_char(g_max_output_rows);
      END IF;
      l_html := l_html ||' - Elapsed time: ' || format_elapsed(g_query_elapsed) || '
        </font></i></b><br>';
	  l_html := l_html || '</th></tr>';
      print_out(l_html);

      -- End of results and footer
      l_step := '180';
      l_html :=  '</tbody></table></div>';
      l_step := '190';
      print_out(l_html);
--
    ELSE -- there are children signatures
      -- Print master rows and call appropriate processes for the children
      -- Table header
      l_html := '<div class="divtable"><table class="table1" id="restable' || to_char(g_sig_id) ||
      '" style="display:none"><tbody>';
      -- Row values
      l_step := '200';
      FOR i IN 1..l_rows_fetched LOOP
        l_step := '200.1.'||to_char(i);
        -- Column headings printed for each row
        l_html := l_html || '<tr>';
        FOR j IN 1..p_col_headings.count LOOP
          l_step := '200.2.'||to_char(j);
          IF upper(nvl(p_col_headings(j),'XXX')) not like '##$$FK_$$##' THEN
            l_html := l_html || '
              <th class="master">'||nvl(p_col_headings(j),'&nbsp;')||'</th>';
          END IF;
        END LOOP;
        l_step := '200.3';
        l_html := l_html || '</tr>';
        -- Print headers
        print_out(expand_links(l_html));
        -- Print a row
        l_html := '<tr class="master">';

        l_printing_cols := 0;
        FOR j IN 1..p_col_headings.count LOOP
          l_step := '200.4.'||to_char(j);

          l_curr_col := upper(p_col_headings(j));
          l_curr_val := p_col_rows(j)(i);

          -- If the col is a FK set the global replacement vals
          IF l_curr_col like '##$$FK_$$##' THEN
            l_step := '200.5';
            g_sql_tokens(l_curr_col) := l_curr_val;
          ELSE -- printable column
            l_printing_cols := l_printing_cols + 1;
            -- Evaluate if necessary
            l_row_fail := false;
            IF nvl(l_column,'&&&') = l_curr_col THEN
              l_step := '200.6'||
                substr('['||l_operand||']['||l_value||']['||l_curr_val||']',1,96);
              l_row_fail := evaluate_rowcol(l_operand, l_value, l_curr_val);
            END IF;
		  
		   -- Encode blanks as HTML space if this analyzer is set so by g_preserve_trailing_blanks
		   -- this ensures trailing blanks added for padding are honored by browsers
		   -- affects only printing, DX summary handled separately
		   IF g_preserve_trailing_blanks THEN
			 l_curr_Val := RPAD(RTRIM(l_curr_Val,' '),
			  -- pad length is the number of spaces existing times the length of &nbsp; => 6
			 (length(l_curr_Val) - length(RTRIM(l_curr_Val,' '))) * 6 + length(RTRIM(l_curr_Val,' ')),
			 '&nbsp;');
		   ELSE
			 l_curr_Val := RTRIM(l_curr_Val, ' ');
		   END IF;
	   						
            -- Print
            IF l_row_fail THEN
              l_html := l_html || '
                <td class="hlt">' || l_curr_Val || '</td>';
            ELSE
              l_html := l_html || '
                <td>' || l_curr_val || '</td>';
            END IF;
          END IF;
        END LOOP;
        l_html := l_html || '</tr>';
        print_out(expand_links(l_html));
        l_html := null;
        FOR i IN p_sig.child_sigs.first..p_sig.child_sigs.last LOOP
          print_out('<tr><td colspan="'||to_char(l_printing_cols)||
            '"><blockquote>');
          DECLARE
            l_col_rows  COL_LIST_TBL := col_list_tbl();
            l_col_hea   VARCHAR_TBL := varchar_tbl();
            l_child_sig SIGNATURE_REC;
            l_result    VARCHAR2(1);
          BEGIN
           l_child_sig := g_signatures(p_sig.child_sigs(i));
           print_log('Processing child signature: '||p_sig.child_sigs(i));
           run_sig_sql(l_child_sig.sig_sql, l_col_rows, l_col_hea,
             l_child_sig.limit_rows);
           l_result := sortable_table_results(p_sig.child_sigs(i),
             l_child_sig, l_col_rows, l_col_hea, TRUE);
           set_item_result(l_result);

		 -- show parent signature failure based on result from child signature(s)
         IF l_result in ('W','E') THEN
             l_fail_flag := true;
           IF l_result = 'E' THEN
             l_error_type := 'E';
           ELSIF (l_result = 'W') AND ((l_error_type is NULL) OR (l_error_type != 'E')) THEN
             l_error_type := 'W';
           END IF;
           g_family_result := l_error_type;
         END IF;

          EXCEPTION WHEN OTHERS THEN
            print_log('Error processing child signature: '||p_sig.child_sigs(i));
            print_log('Error: '||sqlerrm);
            raise;
          END;

          print_out('</blockquote></td></tr>');
        END LOOP;
      END LOOP;
      --l_sig_fail := (l_sig_fail OR l_fail_flag);

      -- End of results and footer
      l_step := '210';
      l_html :=  '</tbody></table></div>
        <font style="font-size:x-small; color:#333333">';
      l_step := '220';
      IF p_sig.limit_rows = 'N' OR l_rows_fetched < g_max_output_rows THEN
        l_html := l_html || l_rows_fetched || ' rows selected';
      ELSE
        l_html := l_html ||'Displaying first '||to_char(g_max_output_rows);
      END IF;
      l_html := l_html ||' - Elapsed time: ' || format_elapsed(g_query_elapsed) || '
        </font><br>';
      print_out(l_html);
    END IF; -- master or child
  END IF; -- print output is true

  -- Print actions
  IF l_sig_fail THEN
    l_step := '230';
    IF p_sig.fail_type = 'E' THEN
      l_html := '<div class="divuar"><span class="divuar1"><img class="error_ico"> Error:</span>' ||
        p_sig.problem_descr;
    ELSIF p_sig.fail_type = 'W' THEN
      l_html := '<div class="divwarn"><span class="divwarn1"><img class="warn_ico"> Warning:</span>' ||
        p_sig.problem_descr;
    ELSE
      l_html := '<div class="divok"><span class="divok1">Information:</span>' ||
        p_sig.problem_descr;
    END IF;

    -- Print solution only if passed
    l_step := '240';
    IF p_sig.solution is not null THEN
      l_html := l_html || '
        <br><br><span class="solution">Findings and Recommendations:</span><br>
        ' || p_sig.solution;
    END IF;

    -- Close div here cause success div is conditional
    l_html := l_html || '</div>';
  ELSE
    l_step := '250';
    IF p_sig.success_msg is not null THEN
      IF p_sig.fail_type = 'I' THEN
        l_html := '
          <br><div class="divok"><div class="divok1">Information:</div>'||
          nvl(p_sig.success_msg, 'No instances of this problem found') ||
          '</div>';
      ELSE
        l_html := '
          <br><div class="divok"><div class="divok1"><img class="check_ico"> All checks passed.</div>'||
          nvl(p_sig.success_msg,
          'No instances of this problem found') ||
          '</div>';
      END IF;
    ELSE
      l_html := null;
    END IF;
  END IF;

  -- Add final tags
  l_html := l_html || '
    </div>' || '<br><font style="font-size:x-small;">
    <a href="#top"><font color="#0066CC">Back to top</font></a></font><br>' || '<br>';
	 
   --Code for Table of Contents of each section  
   g_section_sig := g_section_sig + 1;
   sig_count := g_section_sig;  
   
   IF NOT (l_is_child) THEN
     -- for even # signatures
   IF MOD(g_section_sig, 2) = 0 THEN

   g_section_toc := g_section_toc || '<td>' || '<a href="#restable'||to_char(g_sig_id)||'b">'||p_sig.title||'</a> ';
   
       IF ((l_sig_fail) AND (p_sig.fail_type ='E' OR l_error_type = 'E')) OR (g_family_result = 'E') THEN
         g_section_toc := g_section_toc || '<img class="error_ico">';      
       ELSIF ((l_sig_fail) AND (p_sig.fail_type ='W' OR l_error_type = 'W')) OR (g_family_result = 'W') THEN
         g_section_toc := g_section_toc ||'<img class="warn_ico">';        
       END IF;
	   
   g_section_toc := g_section_toc || '</td></tr>';
   
   ELSE
     -- for odd # signatures start the row
   g_section_toc := g_section_toc || '<tr class="toctable"><td>' || '<a href="#restable'||to_char(g_sig_id)||'b">'||p_sig.title||'</a> ';
   
       IF ((l_sig_fail) AND (p_sig.fail_type ='E' OR l_error_type = 'E')) OR (g_family_result = 'E') THEN
         g_section_toc := g_section_toc || '<img class="error_ico">';      
       ELSIF ((l_sig_fail) AND (p_sig.fail_type ='W' OR l_error_type = 'W')) OR (g_family_result = 'W') THEN
         g_section_toc := g_section_toc ||'<img class="warn_ico">';        
       END IF;
	   
   g_section_toc := g_section_toc || '</td>';   
    
	END IF;
	
  END IF;	
   
	 
  -- Increment the print count for the section	   
  l_step := '260';
  g_sections(g_sections.last).print_count :=
       g_sections(g_sections.last).print_count + 1;

  -- Print
  l_step := '270';
  print_out(expand_links(l_html));
   
	 
  IF l_sig_fail THEN
    l_step := '280';
    return p_sig.fail_type;
  ELSE
    l_step := '290';
    IF p_sig.fail_type = 'I' THEN
      return 'I';
    ELSE
      return 'S';
    END IF;
  END IF;
  

  
EXCEPTION
  WHEN L_INV_PARAM THEN
    print_log('Invalid parameter error in sortable_table_results at step '
      ||l_step);
    raise;
  WHEN OTHERS THEN
    print_log('Error in sortable_table_results at step '||l_step);
    g_errbuf := l_step;
    raise;
END sortable_table_results;

----------------------------------------------------------------
-- Creates a report section                                   --
-- For now it just prints html, in future it could be         --
-- smarter by having the definition of the section logic,     --
-- signatures etc....                                         --
----------------------------------------------------------------

PROCEDURE start_section(p_sect_title varchar2) is
  lsect section_rec;
  
BEGIN
  lsect.name := p_sect_title;
  lsect.result := 'U'; -- 'U' stands for undefined which is a temporary status
  lsect.error_count := 0;
  lsect.warn_count := 0;
  lsect.success_count := 0;
  lsect.print_count := 0;
  g_sections(g_sections.count + 1) := lsect;
  g_section_toc := null;
  g_section_sig := 0;
  sig_count := null;
  g_parent_sig_count := 0;
  
  -- Print section header
  print_out('
  <div id="page'||g_sect_no|| '" style="display: none;">');
  print_out('
<div class="divSection">
<div class="divSectionTitle" id="sect' || g_sections.last || '">
<div class="left"  id="sect_title' || g_sections.last || '" font style="font-weight: bold; font-size: x-large;" align="left" color="#FFFFFF">' || p_sect_title || ': 
</font> 
</div>
       <div class="right" font style="font-weight: normal; font-size: small;" align="right" color="#FFFFFF"> 
          <a class="detail" onclick="openall();" href="javascript:;">
          <font color="#FFFFFF">&#9654; Expand All Checks</font></a> 
          <font color="#FFFFFF">&nbsp;/ &nbsp; </font><a class="detail" onclick="closeall();" href="javascript:;">
          <font color="#FFFFFF">&#9660; Collapse All Checks</font></a> 
       </div>
  <div class="clear"></div>
</div><br>');	

  -- Table of Content DIV
  -- Making DIV invisible by default as later has logic to show TOC only if have 2+ signatures
   print_out('<div class="divItem" style="display: none" id="toccontent'|| g_sections.last||'"></div><br>');
  -- end of TOC DIV		
    		
    print_out('<div id="' || g_sections.last ||'contents">');

-- increment section #
  g_sect_no:=g_sect_no+1;

END start_section;


----------------------------------------------------------------
-- Finalizes a report section                                 --
-- Finalizes the html                                         --
----------------------------------------------------------------

PROCEDURE end_section (
  p_success_msg IN VARCHAR2 DEFAULT 'All checks passed.') IS
  
  l_loop_count NUMBER;
  
BEGIN
  IF g_sections(g_sections.last).result = 'S' AND
     g_sections(g_sections.last).print_count = 0 THEN
    print_out('<div class="divok">'||p_success_msg||'</div>');
  END IF;
  print_out('</div></div><br><font style="font-size:x-small;">
    <a href="#top"><font color="#0066CC">Back to top</font></a></font><br><br>');
   print_out('</div>');
   
 -- Printing table for Table of Content and contents
 -- IF is to print end tag of table row for odd number of sigs
	 
	 IF SUBSTR (g_section_toc, length(g_section_toc)-5, 5) != '</tr>'
		THEN g_section_toc := g_section_toc || '</tr>';
		
	 end if;	
	 
	 g_section_toc := '<table class="toctable" border="0" width="90%" align="center" cellspacing="0" cellpadding="0">' || g_section_toc || '</table>';
	 
 -- Printing 'In This Section' only have 2 or more signatures
	 IF sig_count > 1
	    THEN
	   print_out('
		<script type="text/javascript">
		var a=document.getElementById("toccontent'|| g_sections.last||'");
		a.style.display = "block";
		  a.innerHTML = ''' || '<div class="divItemTitle">In This Section</div>' || g_section_toc ||'''; </script> ');
	end if;	  
 
END end_section;

----------------------------------------------------------------
-- Creates a report sub section                               --
-- workaround for now in future normal sections should        --
-- support nesting                                            --
----------------------------------------------------------------

PROCEDURE print_rep_subsection(p_sect_title varchar2) is
BEGIN
  print_out('<div class="divSubSection"><div class="divSubSectionTitle">' ||
    p_sect_title || '</div><br>');
END print_rep_subsection;

PROCEDURE print_rep_subsection_end is
BEGIN
  print_out('</div<br>');
END print_rep_subsection_end;

----------------------------------------------------------------
-- Creates a Temperature Gauge Graph                          --
-- Used to show how healthy the current data is               --
----------------------------------------------------------------
PROCEDURE show_data_gauge IS

begin
print_out('<div class="divItem" id="CP_ENV">');
	print_out('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
	print_out('<tbody><tr><td>');      

	if (g_reqid_cnt > 5000) THEN  -- This is the critical setting which customers can adjust here

	print_out('<b>Concurrent Processing Runtime Data Gauge</b><BR>');
	print_out('<img src="http://chart.apis.google.com/chart?chxl=0:|critical|bad|good&chxt=y&chs=300x150&cht=gm&chd=t:10&chl=Excessive" width="300" height="150" alt="" />');
	print_out('</td>');

  else   if (g_reqid_cnt > 3500) THEN   -- This is the bad setting which customers can adjust here.

  print_out('<b>Concurrent Processing Runtime Data Gauge</b><BR>');
  print_out('<img src="http://chart.apis.google.com/chart?chxl=0:|critical|bad|good&chxt=y&chs=300x150&cht=gm&chd=t:50&chl=Poor" width="300" height="150" alt="" />');
  print_out('</td>');
  
  else

  print_out('<b>Concurrent Processing Runtime Data Gauge</b><BR>');
  print_out('<img src="http://chart.apis.google.com/chart?chxl=0:|critical|bad|good&chxt=y&chs=300x150&cht=gm&chd=t:90&chl=Healthy" width="300" height="150" alt="" />');
  print_out('</td>');
     
  end if;
end if;
	
	print_out('<td>');
	print_out(' This Runtime Data Gauge is adjustable for your site by entering your own settings for the item_cnt variable in cp_analyzer.sql:<BR>');
	print_out(' 1. Change the following for the immediate review setting (critical): ''(item_cnt > 5000)''.<br>');
	print_out(' 2. Change the following for the review required setting (bad): ''(item_cnt > 3500)''.');
	print_out('</td></tr></tbody> ');
	print_out('</table>');
	
	print_out('</div><br>');

END show_data_gauge;

-------------------------
-- Recommended patches 
-------------------------
-- PSD #6  
    --------------------------------
    /* Query for patches 
	   July 2015: 
	    Function is now calling 'is_patch_applied' API which is required to properly check for R12.2 patches.
		 API exist also in 11i and previous R12 releases.
		IMPORTANT NOTE - Make sure to define l_rel parameter in each condition:
		 l_rel parameter is used when calling cursor. If do not have proper l_rel value, query will return null so not applied.
		    - For 11i: 11i
			- For all R12.x releases: R12
	*/
    --------------------------------	

FUNCTION check_txk_patches RETURN VARCHAR2 IS 

      l_col_rows   COL_LIST_TBL := col_list_tbl(); -- Row values
      l_hdr        VARCHAR_TBL := varchar_tbl(); -- Column headings
      l_app_date   DATE;         -- Patch applied date
      l_extra_info HASH_TBL_4K;   -- Extra information
      l_step       VARCHAR2(10);
      l_sig        SIGNATURE_REC;
	  l_rel       VARCHAR2(3); -- amar

	  -- amar
      CURSOR get_app_date(p_ptch VARCHAR2, p_rel VARCHAR2) IS			  
      SELECT Max(Last_Update_Date) as date_applied
      FROM Ad_Bugs Adb 
      WHERE Adb.Bug_Number like p_ptch
      AND ad_patch.is_patch_applied(p_rel, -1, adb.bug_number)!='NOT_APPLIED';
	  
    BEGIN
	
      -- Column headings
      l_step := '10';
      l_hdr.extend(5);
      l_hdr(1) := 'Patch';
      l_hdr(2) := 'Applied';
      l_hdr(3) := 'Date';
      l_hdr(4) := 'Name';
      l_hdr(5) := 'Note';

    IF substr(g_rep_info('Apps Version'),1,4) = '12.0' THEN
	    l_rel := 'R12'; -- amar
	l_col_rows.extend(5);
	l_col_rows(1)(1) := '4440000';
	l_col_rows(2)(1) := 'No';
	l_col_rows(3)(1) := NULL;
	l_col_rows(4)(1) := 'Oracle Applications Release 12 Maintenance Pack';
	l_col_rows(5)(1) := '[]';

	l_col_rows(1)(2) := '5082400';
	l_col_rows(2)(2) := 'No';
	l_col_rows(3)(2) := NULL;
	l_col_rows(4)(2) := '12.0.1 Release Update Pack (RUP1)';
	l_col_rows(5)(2) := '[]';

	l_col_rows(1)(3) := '5484000';
	l_col_rows(2)(3) := 'No';
	l_col_rows(3)(3) := NULL;
	l_col_rows(4)(3) := '12.0.2 Release Update Pack (RUP2)';
	l_col_rows(5)(3) := '[]';

	l_col_rows(1)(4) := '6141000';
	l_col_rows(2)(4) := 'No';
	l_col_rows(3)(4) := NULL;
	l_col_rows(4)(4) := '12.0.3 Release Update Pack (RUP3)';
	l_col_rows(5)(4) := '[]';

	l_col_rows(1)(5) := '6435000';
	l_col_rows(2)(5) := 'No';
	l_col_rows(3)(5) := NULL;
	l_col_rows(4)(5) := '12.0.4 RELEASE UPDATE PACK (RUP4)';
	l_col_rows(5)(5) := '[]';

	l_col_rows(1)(6) := '5907545';
	l_col_rows(2)(6) := 'No';
	l_col_rows(3)(6) := NULL;
	l_col_rows(4)(6) := 'R12.ATG_PF.A.DELTA.1';
	l_col_rows(5)(6) := '[]';

	l_col_rows(1)(7) := '5917344';
	l_col_rows(2)(7) := 'No';
	l_col_rows(3)(7) := NULL;
	l_col_rows(4)(7) := 'R12.ATG_PF.A.DELTA.2';
	l_col_rows(5)(7) := '[]';

	l_col_rows(1)(8) := '6077669';
	l_col_rows(2)(8) := 'No';
	l_col_rows(3)(8) := NULL;
	l_col_rows(4)(8) := 'R12.ATG_PF.A.DELTA.3';
	l_col_rows(5)(8) := '[]';

	l_col_rows(1)(9) := '6272680';
	l_col_rows(2)(9) := 'No';
	l_col_rows(3)(9) := NULL;
	l_col_rows(4)(9) := 'R12.ATG_PF.A.DELTA.4';
	l_col_rows(5)(9) := '[]';

	l_col_rows(1)(10) := '7237006';
	l_col_rows(2)(10) := 'No';
	l_col_rows(3)(10) := NULL;
	l_col_rows(4)(10) := 'R12.ATG_PF.A.DELTA.6';
	l_col_rows(5)(10) := '[]';

	l_col_rows(1)(11) := '6728000';
	l_col_rows(2)(11) := 'No';
	l_col_rows(3)(11) := NULL;
	l_col_rows(4)(11) := '12.0.6 RELEASE UPDATE PACK (RUP6)';
	l_col_rows(5)(11) := '[]'; 

     ELSIF substr(g_rep_info('Apps Version'),1,4) = '12.1' THEN	
	    l_rel := 'R12'; -- amar
	l_col_rows.extend(5);
	l_col_rows(1)(1) := '6430106';
	l_col_rows(2)(1) := 'No';
	l_col_rows(3)(1) := NULL;
	l_col_rows(4)(1) := 'R12 ORACLE E-BUSINESS SUITE 12.1';
	l_col_rows(5)(1) := '[]'; 

	l_col_rows(1)(2) := '7303030';
	l_col_rows(2)(2) := 'No';
	l_col_rows(3)(2) := NULL;
	l_col_rows(4)(2) := '12.1.1 Maintenance Pack';
	l_col_rows(5)(2) := '[]';

	l_col_rows(1)(3) := '7307198';
	l_col_rows(2)(3) := 'No';
	l_col_rows(3)(3) := NULL;
	l_col_rows(4)(3) := 'R12.ATG_PF.B.DELTA.1';
	l_col_rows(5)(3) := '[]';

	l_col_rows(1)(4) := '7651091';
	l_col_rows(2)(4) := 'No';
	l_col_rows(3)(4) := NULL;
	l_col_rows(4)(4) := 'R12.ATG_PF.B.DELTA.2';
	l_col_rows(5)(4) := '[]';

	l_col_rows(1)(5) := '7303033';
	l_col_rows(2)(5) := 'No';
	l_col_rows(3)(5) := NULL;
	l_col_rows(4)(5) := 'Oracle E-Business Suite 12.1.2 Release Update Pack (RUP2)';
	l_col_rows(5)(5) := '[]';

	l_col_rows(1)(6) := '8919491';
	l_col_rows(2)(6) := 'No';
	l_col_rows(3)(6) := NULL;
	l_col_rows(4)(6) := 'R12.ATG_PF.B.DELTA.3';
	l_col_rows(5)(6) := '[]';

	l_col_rows(1)(7) := '9239090';
	l_col_rows(2)(7) := 'No';
	l_col_rows(3)(7) := NULL;
	l_col_rows(4)(7) := 'ORACLE E-BUSINESS SUITE 12.1.3 RELEASE UPDATE PACK';
	l_col_rows(5)(7) := '[]';
	
     ELSIF substr(g_rep_info('Apps Version'),1,4) = '12.2' THEN		
		l_rel := 'R12'; -- amar
        l_col_rows.extend(5);
	l_col_rows.extend(5);
	l_col_rows(1)(1) := '16207672';
	l_col_rows(2)(1) := 'No';
	l_col_rows(3)(1) := NULL;
	l_col_rows(4)(1) := 'R12.2.2 - ORACLE E-BUSINESS SUITE 12.2.2 RELEASE UPDATE PACK';
	l_col_rows(5)(1) := '[]';

	l_col_rows(1)(2) := '17020683';
	l_col_rows(2)(2) := 'No';
	l_col_rows(3)(2) := NULL;
	l_col_rows(4)(2) := 'R12.2.3 - ORACLE E-BUSINESS SUITE 12.2.3 RELEASE UPDATE PACK';
	l_col_rows(5)(2) := '[]';

	l_col_rows(1)(3) := '17919161';
	l_col_rows(2)(3) := 'No';
	l_col_rows(3)(3) := NULL;
	l_col_rows(4)(3) := 'R12.2.4 - ORACLE E-BUSINESS SUITE 12.2.4 RELEASE UPDATE PACK';
	l_col_rows(5)(3) := '[]';
	
     ELSE -- 11i
        l_rel := '11i'; -- amar
	l_col_rows.extend(5);
	l_col_rows(1)(1) := '3262919';
	l_col_rows(2)(1) := 'No';
	l_col_rows(3)(1) := NULL;
	l_col_rows(4)(1) := 'FMWK.H';
	l_col_rows(5)(1) := '[]';

	l_col_rows(1)(2) := '3262159';
	l_col_rows(2)(2) := 'No';
	l_col_rows(3)(2) := NULL;
	l_col_rows(4)(2) := 'FND.H INCLUDE OWF.H';
	l_col_rows(5)(2) := '[]';

	l_col_rows(1)(3) := '3258819';
	l_col_rows(2)(3) := 'No';
	l_col_rows(3)(3) := NULL;
	l_col_rows(4)(3) := 'OWF.H INCLUDED IN 11.5.10';
	l_col_rows(5)(3) := '[]';

	l_col_rows(1)(4) := '3438354';
	l_col_rows(2)(4) := 'No';
	l_col_rows(3)(4) := NULL;
	l_col_rows(4)(4) := '11i.ATG_PF.H INCLUDE OWF.H';
	l_col_rows(5)(4) := '[]';

	l_col_rows(1)(5) := '3140000';
	l_col_rows(2)(5) := 'No';
	l_col_rows(3)(5) := NULL;
	l_col_rows(4)(5) := 'ORACLE APPLICATIONS RELEASE 11.5.10 MAINTENANCE PACK';
	l_col_rows(5)(5) := '[]';

	l_col_rows(1)(6) := '3240000';
	l_col_rows(2)(6) := 'No';
	l_col_rows(3)(6) := NULL;
	l_col_rows(4)(6) := '11.5.10 ORACLE E-BUSINESS SUITE CONSOLIDATED UPDATE 1';
	l_col_rows(5)(6) := '[]';

	l_col_rows(1)(7) := '3460000';
	l_col_rows(2)(7) := 'No';
	l_col_rows(3)(7) := NULL;
	l_col_rows(4)(7) := '11.5.10 ORACLE E-BUSINESS SUITE CONSOLIDATED UPDATE 2';
	l_col_rows(5)(7) := '[]';

	l_col_rows(1)(8) := '3480000';
	l_col_rows(2)(8) := 'No';
	l_col_rows(3)(8) := NULL;
	l_col_rows(4)(8) := 'ORACLE APPLICATIONS RELEASE 11.5.10.2 MAINTENANCE PACK';
	l_col_rows(5)(8) := '[]';

	l_col_rows(1)(9) := '4017300';
	l_col_rows(2)(9) := 'No';
	l_col_rows(3)(9) := NULL;
	l_col_rows(4)(9) := 'ATG_PF:11.5.10 Consolidated Update (CU1) for ATG Product Family';
	l_col_rows(5)(9) := '[]';

	l_col_rows(1)(10) := '4125550';
	l_col_rows(2)(10) := 'No';
	l_col_rows(3)(10) := NULL;
	l_col_rows(4)(10) := 'ATG_PF:11.5.10 Consolidated Update (CU2) for ATG Product Family';
	l_col_rows(5)(10) := '[]';

	l_col_rows(1)(11) := '5121512';
	l_col_rows(2)(11) := 'No';
	l_col_rows(3)(11) := NULL;
	l_col_rows(4)(11) := 'AOL USER RESPONSIBILITY SECURITY FIXES VERSION 1';
	l_col_rows(5)(11) := '[]';

	l_col_rows(1)(12) := '6008417';
	l_col_rows(2)(12) := 'No';
	l_col_rows(3)(12) := NULL;
	l_col_rows(4)(12) := 'AOL USER RESPONSIBILITY SECURITY FIXES 2b';
	l_col_rows(5)(12) := '[]';

	l_col_rows(1)(13) := '6047864';
	l_col_rows(2)(13) := 'No';
	l_col_rows(3)(13) := NULL;
	l_col_rows(4)(13) := 'REHOST JOC FIXES (BASED ON JOC 10.1.2.2) FOR APPS 11i';
	l_col_rows(5)(13) := '[]';

	l_col_rows(1)(14) := '4334965';
	l_col_rows(2)(14) := 'No';
	l_col_rows(3)(14) := NULL;
	l_col_rows(4)(14) := '11i.ATG_PF.H RUP3';
	l_col_rows(5)(14) := '[]';

	l_col_rows(1)(15) := '4676589';
	l_col_rows(2)(15) := 'No';
	l_col_rows(3)(15) := NULL;
	l_col_rows(4)(15) := '11i.ATG_PF.H.RUP4';
	l_col_rows(5)(15) := '[]';

	l_col_rows(1)(16) := '5473858';
	l_col_rows(2)(16) := 'No';
	l_col_rows(3)(16) := NULL;
	l_col_rows(4)(16) := '11i.ATG_PF.H.RUP5';
	l_col_rows(5)(16) := '[]';

	l_col_rows(1)(17) := '5903765';
	l_col_rows(2)(17) := 'No';
	l_col_rows(3)(17) := NULL;
	l_col_rows(4)(17) := '11i.ATG_PF.H.RUP6';
	l_col_rows(5)(17) := '[]';

	l_col_rows(1)(18) := '6241631';
	l_col_rows(2)(18) := 'No';
	l_col_rows(3)(18) := NULL;
	l_col_rows(4)(18) := '11i.ATG_PF.H.RUP7';
	l_col_rows(5)(18) := '[]';

		
	END IF;

      -- Check if applied
	  IF l_col_rows.exists(1) THEN
	  FOR i in 1..l_col_rows(1).count loop
		l_step := '40';
		OPEN get_app_date(l_col_rows(1)(i),l_rel);
		FETCH get_app_date INTO l_app_date;
		CLOSE get_app_date;
		IF l_app_date is not null THEN
		  l_step := '50';
		  l_col_rows(2)(i) := 'Yes';
		  l_col_rows(3)(i) := to_char(l_app_date);
		END IF;
	  END LOOP;
	  END IF;


      --Render
      l_step := '60';

      l_sig.title := 'Applied E-Business Suite Technology Stack Patches';
      l_sig.fail_condition := '[Applied] = [No]';
      l_sig.problem_descr := 'Please check the recommended Reports patches that are not applied on this instance';
      l_sig.solution := '<b>To get a current accurate list of recommended EBS product patches that are applied/not applied to your instance, please run Patch Wizard.</b><br>
		See [976188.1] - Patch Wizard Utility, [976688.2] FAQ, or [1077813.1] Videos for more information.<br>
		<ul>Above is a short list of recommended product patches as of the date this script was written to show you what may or may not be applied on this '||g_rep_info('Instance')||' instance.
		<li>Please review the list above and schedule to apply any unappplied patches as soon as possible</li>
        <li>Refer to the note indicated for more information about each patch</li></ul><br>';
      l_sig.success_msg := '<b>All known recommended EBS product patches, at the time this script was written, for release '||g_rep_info('Apps Version')||' have been applied.<br>
	  To get the most current list of recommended EBS product patches that are applied/not applied to your instance, please run Patch Wizard.</b><br>
	  See [976188.1] - Patch Wizard Utility, [976688.2] FAQ, or [1077813.1] Videos for more information.<br>';
      l_sig.print_condition := 'ALWAYS';
      l_sig.fail_type := 'W';
      l_sig.print_sql_output := 'Y';
      l_sig.limit_rows := 'N';
      l_sig.include_in_xml :='N';

      l_step := '70';
      RETURN process_signature_results(
        'CHECK_TXK_PATCHES',   -- sig ID
        l_sig,                 -- signature information
        l_col_rows,            -- data
        l_hdr);                -- headers
    EXCEPTION WHEN OTHERS THEN
      print_log('Error in check_txk_patches at step '||l_step);
      raise;
END check_txk_patches;
	
   --------------------------------
    /* Query for patches 
	   July 2015: 
	    Function is now calling 'is_patch_applied' API which is required to properly check for R12.2 patches.
		 API exist also in 11i and previous R12 releases.
		IMPORTANT NOTE - Make sure to define l_rel parameter in each condition:
		 l_rel parameter is used when calling cursor. If do not have proper l_rel value, query will return null so not applied.
		    - For 11i: 11i
			- For all R12.x releases: R12
	*/
    --------------------------------	

FUNCTION check_cprec_patches RETURN VARCHAR2 IS 

      l_col_rows   COL_LIST_TBL := col_list_tbl(); -- Row values
      l_hdr        VARCHAR_TBL := varchar_tbl(); -- Column headings
      l_app_date   DATE;         -- Patch applied date
      l_extra_info HASH_TBL_4K;   -- Extra information
      l_step       VARCHAR2(10);
      l_sig        SIGNATURE_REC;
	  l_rel       VARCHAR2(3); -- amar

	  -- amar
      CURSOR get_app_date(p_ptch VARCHAR2, p_rel VARCHAR2) IS			  
      SELECT Max(Last_Update_Date) as date_applied
      FROM Ad_Bugs Adb 
      WHERE Adb.Bug_Number like p_ptch
      AND ad_patch.is_patch_applied(p_rel, -1, adb.bug_number)!='NOT_APPLIED';
	  
    BEGIN
	print_log('Processing signature: check_cprec_patches');
      -- Column headings
      l_step := '10';
      l_hdr.extend(5);
      l_hdr(1) := 'Patch';
      l_hdr(2) := 'Applied';
      l_hdr(3) := 'Date';
      l_hdr(4) := 'Name';
      l_hdr(5) := 'Note';

IF substr(g_rep_info('Apps Version'),1,4) = '12.0' THEN	
	    l_rel := 'R12'; -- amar
		l_col_rows.extend(5);
        l_col_rows(1)(1) := '4440000'; 
        l_col_rows(2)(1) := 'No';
        l_col_rows(3)(1) := NULL;
        l_col_rows(4)(1) := 'Oracle Applications Release 12 Maintenance Pack';
        l_col_rows(5)(1) := '';
        
	l_col_rows(1)(2) := '5082400'; 
        l_col_rows(2)(2) := 'No';
        l_col_rows(3)(2) := NULL;
        l_col_rows(4)(2) := '12.0.1 Release Update Pack (RUP1)';
        l_col_rows(5)(2) := '';
        
	l_col_rows(1)(3) := '5484000'; 
        l_col_rows(2)(3) := 'No';
        l_col_rows(3)(3) := NULL;
        l_col_rows(4)(3) := '12.0.2 Release Update Pack (RUP2)';
        l_col_rows(5)(3) := '';
        
	l_col_rows(1)(4) := '6141000'; 
        l_col_rows(2)(4) := 'No';
        l_col_rows(3)(4) := NULL;
        l_col_rows(4)(4) := '12.0.3 Release Update Pack (RUP3)';
        l_col_rows(5)(4) := '';
        
	l_col_rows(1)(5) := '6435000'; 
        l_col_rows(2)(5) := 'No';
        l_col_rows(3)(5) := NULL;
        l_col_rows(4)(5) := '12.0.4 Release Update Pack (RUP4)';
        l_col_rows(5)(5) := '';
        
	l_col_rows(1)(6) := '5907545'; 
        l_col_rows(2)(6) := 'No';
        l_col_rows(3)(6) := NULL;
        l_col_rows(4)(6) := 'R12.ATG_PF.A.DELTA.1';
        l_col_rows(5)(6) := '';
        
	l_col_rows(1)(7) := '5917344'; 
        l_col_rows(2)(7) := 'No';
        l_col_rows(3)(7) := NULL;
        l_col_rows(4)(7) := 'R12.ATG_PF.A.DELTA.2';
        l_col_rows(5)(7) := '';
        
	l_col_rows(1)(8) := '6077669'; 
        l_col_rows(2)(8) := 'No';
        l_col_rows(3)(8) := NULL;
        l_col_rows(4)(8) := 'R12.ATG_PF.A.DELTA.3';
        l_col_rows(5)(8) := '';
        
	l_col_rows(1)(9) := '6272680'; 
        l_col_rows(2)(9) := 'No';
        l_col_rows(3)(9) := NULL;
        l_col_rows(4)(9) := 'R12.ATG_PF.A.DELTA.4';
        l_col_rows(5)(9) := '';
        
	l_col_rows(1)(10) := '7237006'; 
        l_col_rows(2)(10) := 'No';
        l_col_rows(3)(10) := NULL;
        l_col_rows(4)(10) := 'R12.ATG_PF.A.DELTA.6';
        l_col_rows(5)(10) := '';
        
	l_col_rows(1)(11) := '6728000'; 
        l_col_rows(2)(11) := 'No';
        l_col_rows(3)(11) := NULL;
        l_col_rows(4)(11) := 'R12 12.0.6 (RUP6)';
        l_col_rows(5)(11) := '';
        
ELSIF substr(g_rep_info('Apps Version'),1,6) = '12.1.1' THEN	
	    l_rel := 'R12'; -- amar
		l_col_rows.extend(5);
        l_col_rows(1)(1) := '6430106'; 
        l_col_rows(2)(1) := 'No';
        l_col_rows(3)(1) := NULL;
        l_col_rows(4)(1) := 'R12 Oracle E-Business Suite 12.1';
        l_col_rows(5)(1) := '';
        
	l_col_rows(1)(2) := '7303030'; 
        l_col_rows(2)(2) := 'No';
        l_col_rows(3)(2) := NULL;
        l_col_rows(4)(2) := '12.1.1 Maintenance Pack';
        l_col_rows(5)(2) := '';
        
	l_col_rows(1)(3) := '7307198'; 
        l_col_rows(2)(3) := 'No';
        l_col_rows(3)(3) := NULL;
        l_col_rows(4)(3) := 'R12.ATG_PF.B.DELTA.1';
        l_col_rows(5)(3) := '';
        
ELSIF substr(g_rep_info('Apps Version'),1,6) = '12.1.2' THEN	
	    l_rel := 'R12'; -- amar
		l_col_rows.extend(5);
        l_col_rows(1)(1) := '7651091'; 
        l_col_rows(2)(1) := 'No';
        l_col_rows(3)(1) := NULL;
        l_col_rows(4)(1) := 'R12.ATG_PF.B.DELTA.2';
        l_col_rows(5)(1) := '';
        
	l_col_rows(1)(2) := '7303033'; 
        l_col_rows(2)(2) := 'No';
        l_col_rows(3)(2) := NULL;
        l_col_rows(4)(2) := 'R12 Oracle E-Business Suite 12.1.2 (RUP2)';
        l_col_rows(5)(2) := '';
        
ELSIF substr(g_rep_info('Apps Version'),1,6) = '12.1.3' THEN	
	    l_rel := 'R12'; -- amar
		l_col_rows.extend(5);
        l_col_rows(1)(1) := '8919491'; 
        l_col_rows(2)(1) := 'No';
        l_col_rows(3)(1) := NULL;
        l_col_rows(4)(1) := 'R12.ATG_PF.B.DELTA.3';
        l_col_rows(5)(1) := '';
        
	l_col_rows(1)(2) := '9239090'; 
        l_col_rows(2)(2) := 'No';
        l_col_rows(3)(2) := NULL;
        l_col_rows(4)(2) := 'R12 Oracle E-Business Suite 12.1.3 (RUP3)';
        l_col_rows(5)(2) := '';
        
	l_col_rows(1)(3) := '17774755'; 
        l_col_rows(2)(3) := 'No';
        l_col_rows(3)(3) := NULL;
        l_col_rows(4)(3) := 'Oracle 12.1.3+ E-Business Suite Recommended Patch Collection 1 [RPC1]';
        l_col_rows(5)(3) := '[1638535.1]';
        
	l_col_rows(1)(4) := '19030202'; 
        l_col_rows(2)(4) := 'No';
        l_col_rows(3)(4) := NULL;
        l_col_rows(4)(4) := 'Oracle 12.1.3+ E-Business Suite Recommended Patch Collection 2 [RPC2]';
        l_col_rows(5)(4) := '[1920628.1]';
        
	l_col_rows(1)(5) := '20203366'; 
        l_col_rows(2)(5) := 'No';
        l_col_rows(3)(5) := NULL;
        l_col_rows(4)(5) := 'Oracle 12.1.3+ E-Business Suite Recommended Patch Collection 3 [RPC3]';
        l_col_rows(5)(5) := '[1986065.1]';

ELSIF substr(g_rep_info('Apps Version'),1,6) = '12.2.2' THEN	
	    l_rel := 'R12'; -- amar
		l_col_rows.extend(5);
        l_col_rows(1)(1) := '16207672'; 
        l_col_rows(2)(1) := 'No';
        l_col_rows(3)(1) := NULL;
        l_col_rows(4)(1) := 'ORACLE E-BUSINESS SUITE 12.2.2 RELEASE UPDATE PACK';
        l_col_rows(5)(1) := '';

ELSIF substr(g_rep_info('Apps Version'),1,6) = '12.2.3' THEN	
	    l_rel := 'R12'; -- amar
		l_col_rows.extend(5);
        l_col_rows(1)(1) := '17020683'; 
        l_col_rows(2)(1) := 'No';
        l_col_rows(3)(1) := NULL;
        l_col_rows(4)(1) := 'ORACLE E-BUSINESS SUITE 12.2.3 RELEASE UPDATE PACK';
        l_col_rows(5)(1) := '';
        
ELSIF substr(g_rep_info('Apps Version'),1,6) = '12.2.4' THEN	
	    l_rel := 'R12'; -- amar
		l_col_rows.extend(5);
        l_col_rows(1)(1) := '17919161'; 
        l_col_rows(2)(1) := 'No';
        l_col_rows(3)(1) := NULL;
        l_col_rows(4)(1) := 'ORACLE E-BUSINESS SUITE 12.2.4 RELEASE UPDATE PACK';
        l_col_rows(5)(1) := '';
        
ELSE -- 11i
        l_rel := '11i'; -- amar
		l_col_rows.extend(5);
		l_col_rows(1)(1) := '3240000'; 
        l_col_rows(2)(1) := 'No';
        l_col_rows(3)(1) := NULL;
        l_col_rows(4)(1) := '11.5.10 Oracle E-Business Suite Consolidated Update (CU1)';
        l_col_rows(5)(1) := '';
        
	l_col_rows(1)(2) := '3460000'; 
        l_col_rows(2)(2) := 'No';
        l_col_rows(3)(2) := NULL;
        l_col_rows(4)(2) := '11.5.10 Oracle E-Business Suite Consolidated Update (CU2)';
        l_col_rows(5)(2) := '';
        
	l_col_rows(1)(3) := '3480000'; 
        l_col_rows(2)(3) := 'No';
        l_col_rows(3)(3) := NULL;
        l_col_rows(4)(3) := 'Oracle Applications Release 11.5.10.2 Maintenance Pack';
        l_col_rows(5)(3) := '';
        
	l_col_rows(1)(4) := '4017300'; 
        l_col_rows(2)(4) := 'No';
        l_col_rows(3)(4) := NULL;
        l_col_rows(4)(4) := 'ATG_PF:11.5.10 Consolidated Update (CU1) for ATG Product Family';
        l_col_rows(5)(4) := '';
        
	l_col_rows(1)(5) := '4125550'; 
        l_col_rows(2)(5) := 'No';
        l_col_rows(3)(5) := NULL;
        l_col_rows(4)(5) := 'ATG_PF:11.5.10 Consolidated Update (CU2) for ATG Product Family';
        l_col_rows(5)(5) := '';
        
	l_col_rows(1)(6) := '4334965'; 
        l_col_rows(2)(6) := 'No';
        l_col_rows(3)(6) := NULL;
        l_col_rows(4)(6) := '11i.ATG_PF.H RUP3';
        l_col_rows(5)(6) := '';
        
	l_col_rows(1)(7) := '4676589'; 
        l_col_rows(2)(7) := 'No';
        l_col_rows(3)(7) := NULL;
        l_col_rows(4)(7) := '11i.ATG_PF.H.RUP4';
        l_col_rows(5)(7) := '';
        
	l_col_rows(1)(8) := '5473858'; 
        l_col_rows(2)(8) := 'No';
        l_col_rows(3)(8) := NULL;
        l_col_rows(4)(8) := '11i.ATG_PF.H.RUP5';
        l_col_rows(5)(8) := '';
        
	l_col_rows(1)(9) := '5903765'; 
        l_col_rows(2)(9) := 'No';
        l_col_rows(3)(9) := NULL;
        l_col_rows(4)(9) := '11i.ATG_PF.H.RUP6';
        l_col_rows(5)(9) := '';
        
	l_col_rows(1)(10) := '6241631'; 
        l_col_rows(2)(10) := 'No';
        l_col_rows(3)(10) := NULL;
        l_col_rows(4)(10) := '11i.ATG_PF.H.RUP7';
        l_col_rows(5)(10) := '';
        
	END IF;

      -- Check if applied
	  IF l_col_rows.exists(1) THEN
	  FOR i in 1..l_col_rows(1).count loop
		l_step := '40';
		OPEN get_app_date(l_col_rows(1)(i),l_rel);
		FETCH get_app_date INTO l_app_date;
		CLOSE get_app_date;
		IF l_app_date is not null THEN
		  l_step := '50';
		  l_col_rows(2)(i) := 'Yes';
		  l_col_rows(3)(i) := to_char(l_app_date);
		END IF;
	  END LOOP;
	  END IF;


      --Render
      l_step := '60';

      l_sig.title := 'Recommended Concurrent Processing Patches for '||g_rep_info('Apps Version')||'';
      l_sig.fail_condition := '[Applied] = [No]';
      l_sig.problem_descr := '<b>There are recommended '||g_rep_info('Apps Version')||' Concurrent Processing patches that are not applied '||
        'on this instance</b>';
      l_sig.solution := '<ul><li>Please review list above and schedule
        to apply any unappplied recommended Concurrent Processing patches as soon as possible</li>
        <li>Refer to the note indicated for more information about each patch</li></ul>';
      l_sig.success_msg := 'All recommended Concurrent Processing patches (if any) have been applied.';
      l_sig.print_condition := 'ALWAYS';
      l_sig.fail_type := 'W';
      l_sig.print_sql_output := 'Y';
      l_sig.limit_rows := 'N';
      l_sig.include_in_xml :='N';

      l_step := '70';
      RETURN process_signature_results(
        'CHECK_CPREC_PATCHES',     -- sig ID
        l_sig,                 -- signature information
        l_col_rows,            -- data
        l_hdr);                -- headers
    EXCEPTION WHEN OTHERS THEN
      print_log('Error in check_cprec_patches at step '||l_step);
      raise;
END check_cprec_patches;	


PROCEDURE add_signature(
  p_sig_id           VARCHAR2,     -- Unique Signature identifier
  p_sig_sql          VARCHAR2,     -- The text of the signature query
  p_title            VARCHAR2,     -- Signature title
  p_fail_condition   VARCHAR2,     -- RSGT1 (RS greater than 1), RS (row selected), NRS (no row selected)
  p_problem_descr    VARCHAR2,     -- Problem description
  p_solution         VARCHAR2,     -- Problem solution
  p_success_msg      VARCHAR2    DEFAULT null,      -- Message on success
  p_print_condition  VARCHAR2    DEFAULT 'ALWAYS',  -- ALWAYS, SUCCESS, FAILURE, NEVER
  p_fail_type        VARCHAR2    DEFAULT 'W',       -- Warning(W), Error(E), Informational(I) is for use of data dump so no validation
  p_print_sql_output VARCHAR2    DEFAULT 'RS',      -- Y/N/RS - when to print data
  p_limit_rows       VARCHAR2    DEFAULT 'Y',       -- Y/N
  p_extra_info       HASH_TBL_4K DEFAULT CAST(null AS HASH_TBL_4K), -- Additional info
  p_child_sigs       VARCHAR_TBL DEFAULT VARCHAR_TBL(),
  p_include_in_xml   VARCHAR2    DEFAULT 'N') --should signature be included in DX Summary
 IS

  l_rec signature_rec;
BEGIN
  l_rec.sig_sql          := p_sig_sql;
  l_rec.title            := p_title;
  l_rec.fail_condition   := p_fail_condition;
  l_rec.problem_descr    := p_problem_descr;
  l_rec.solution         := p_solution;
  l_rec.success_msg      := p_success_msg;
  l_rec.print_condition  := p_print_condition;
  l_rec.fail_type        := p_fail_type;
  l_rec.print_sql_output := p_print_sql_output;
  l_rec.limit_rows       := p_limit_rows;
  l_rec.extra_info       := p_extra_info;
  l_rec.child_sigs       := p_child_sigs;
  l_rec.include_in_xml   := p_include_in_xml;
  g_signatures(p_sig_id) := l_rec;
EXCEPTION WHEN OTHERS THEN
  print_log('Error in add_signature procedure: '||p_sig_id);
  raise;
END add_signature;


FUNCTION run_stored_sig(p_sig_id varchar2) RETURN VARCHAR2 IS

  l_col_rows COL_LIST_TBL := col_list_tbl();
  l_col_hea  VARCHAR_TBL := varchar_tbl();
  l_sig      signature_rec;

BEGIN
  print_log('Processing signature: '||p_sig_id);
  -- Get the signature record from the signature table
  BEGIN
    l_sig := g_signatures(p_sig_id);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    print_log('No such signature '||p_sig_id||' error in run_stored_sig');

    raise;
  END;

  -- Run SQL
  run_sig_sql(l_sig.sig_sql, l_col_rows, l_col_hea,
              l_sig.limit_rows);

  -- Evaluate and print
  RETURN process_signature_results(
       p_sig_id,               -- signature id
       l_sig,                  -- Name/title of signature item
       l_col_rows,             -- signature SQL row values
       l_col_hea);             -- signature SQL column names
 
	   
EXCEPTION WHEN OTHERS THEN
  print_log('Error in run_stored_sig procedure for sig_id: '||p_sig_id);
  print_log('Error: '||sqlerrm);
  print_error('PROGRAM ERROR<br/>
    Error for sig '||p_sig_id||' '||sqlerrm||'<br/>
    See the log file for additional details');
  return null;
END run_stored_sig;


FUNCTION run_sortable_table(p_sig_id varchar2) RETURN VARCHAR2 IS

  l_col_rows COL_LIST_TBL := col_list_tbl();
  l_col_hea  VARCHAR_TBL := varchar_tbl();
  l_sig      signature_rec;

BEGIN
  print_log('Processing signature: '||p_sig_id);
  -- Get the signature record from the signature table
  BEGIN
    l_sig := g_signatures(p_sig_id);
  EXCEPTION WHEN NO_DATA_FOUND THEN
    print_log('No such signature '||p_sig_id||' error in run_sortable_table');

    raise;
  END;

  -- Run SQL
  run_sig_sql(l_sig.sig_sql, l_col_rows, l_col_hea,
              l_sig.limit_rows);

  -- Evaluate and print
  RETURN sortable_table_results(
       p_sig_id,               -- signature id
       l_sig,                  -- Name/title of signature item
       l_col_rows,             -- signature SQL row values
       l_col_hea);             -- signature SQL column names
 
	   
EXCEPTION WHEN OTHERS THEN
  print_log('Error in run_sortable_table procedure for sig_id: '||p_sig_id);
  print_log('Error: '||sqlerrm);
  print_error('PROGRAM ERROR<br/>
    Error for sig '||p_sig_id||' '||sqlerrm||'<br/>
    See the log file for additional details');
  return null;
END run_sortable_table;


--########################################################################################
--     Beginning of specific code of this ANALYZER 
--########################################################################################

----------------------------------------------------------------
--- Validate Parameters                                      ---
----------------------------------------------------------------
-- PSD #7
PROCEDURE validate_parameters IS

  l_from_date    VARCHAR2(25);
  l_to_date      VARCHAR2(25);
  l_revision     VARCHAR2(25);
  l_date_char    VARCHAR2(30);
  l_item_cnt     number;
  l_sid			 varchar2(16);
  l_instance     V$INSTANCE.INSTANCE_NAME%TYPE;
  l_apps_version FND_PRODUCT_GROUPS.RELEASE_NAME%TYPE;
  l_host         V$INSTANCE.HOST_NAME%TYPE;
 
  invalid_parameters EXCEPTION;
     
BEGIN
 
  -- Determine instance info
  BEGIN

    SELECT max(release_name) INTO l_apps_version
    FROM fnd_product_groups;

    SELECT instance_name, host_name
    INTO l_instance, l_host
    FROM v$instance;

	select upper(instance_name) into l_sid from v$instance;

	select count(request_id) into l_item_cnt from fnd_concurrent_requests where phase_code='C';
	
  EXCEPTION WHEN OTHERS THEN
    print_log('Error in validate_parameters gathering instance information: '
      ||sqlerrm);
    raise;
  END;
  
-- Revision and date values can be populated by RCS
-- PSD #8  
  l_revision := rtrim(replace('$Revision: 200.6 $','$',''));  
  l_revision := ltrim(replace(l_revision,'Revision:',''));
  l_date_char := rtrim(replace('$Date: 2014/05/01 22:05:55 $','$',''));
  l_date_char := ltrim(replace(l_date_char,'Date:',''));
  l_date_char := to_char(to_date(l_date_char,'YYYY/MM/DD HH24:MI:SS'),'DD-MON-YYYY');
 
-- Create global hash for report information
  g_rep_info('Host') := l_host;
  g_rep_info('Instance') := l_instance;
  g_rep_info('Apps Version') := l_apps_version;

-- PSD #9  
  g_rep_info('File Name') := 'cp_analyzer.sql';
  g_rep_info('File Version') := l_revision;   
  g_rep_info('Execution Date') := to_char(sysdate,'DD-MON-YYYY HH24:MI:SS');
  g_rep_info('Description') := ('The ' || analyzer_title ||' Analyzer ' || '(<a href="https://support.oracle.com/rs?type=doc\&id=1411723.1" target="_blank">Doc ID  1411723.1</a>)' || ' is a self-service proactive health-check script that reviews the overall footprint, analyzes current configurations and settings for the environment and provides feedback and recommendations on best practices. Your application data is not altered in any way when you run this analyzer.');

  ------------------------------------------------------------------------------
  -- NOTE: Add code here for validation to the parameters of your diagnostic
  ------------------------------------------------------------------------------

  g_reqid_cnt := l_item_cnt;
  
EXCEPTION
  WHEN INVALID_PARAMETERS THEN
    print_log('Invalid parameters provided. Process cannot continue.');
    raise;
  WHEN OTHERS THEN
    print_log('Error validating parameters: '||sqlerrm);
    raise;
END validate_parameters;


---------------------------------------------
-- Load signatures for this ANALYZER       --
---------------------------------------------
PROCEDURE load_signatures IS
  l_info  HASH_TBL_4K;
BEGIN
-- PSD #11
   -----------------------------------------
  -- Add definition of signatures here ....
  ------------------------------------------
 add_signature(
	'CONC_REQ1',
	'select to_char(actual_completion_date,''YYYY'') "COMPLETED", count(request_id) "COUNT" 
	 from fnd_concurrent_requests where phase_code=''C''
	 group by to_char(actual_completion_date,''YYYY'')
	 order by to_char(actual_completion_date,''YYYY'') desc',
	'Your overall Concurrent Processing HealthCheck Status is in need of Immediate Review!',
	'RS',   
    'The '||to_char(g_reqid_cnt,'999,999,999,999')||' rows in the FND_CONCURRENT_REQUESTS Table suggests request purging is never performed on a regular basis.<BR><BR>
    This Gauge is merely a simple indicator about volume of Concurrent Request data on '||g_rep_info('Instance')||'.
    It displays GREEN if less than 3,500 rows are found, ORANGE if less than 5,000, and RED if over 5,000 rows are found.',
    'Clean up Concurrent Request Data and move the needle to green.<BR>
    For more information please review:<br>
    [1057802.1] - Concurrent Processing - Best Practices for Performance for Concurrent Managers in E-Business Suite',
	null,
	'ALWAYS',
    'W',
    'RS',
    'Y'); 
	
  add_signature(
	'CONC_REQ2',
	'select to_char(actual_completion_date,''YYYY'') "COMPLETED", count(request_id) "COUNT" 
	 from fnd_concurrent_requests where phase_code=''C''
	 group by to_char(actual_completion_date,''YYYY'')
	 order by to_char(actual_completion_date,''YYYY'') desc',
	'Your overall Concurrent Processing HealthCheck Status is in need of Review!',
	'RS',   
    'The '||to_char(g_reqid_cnt,'999,999,999,999')||' rows in the FND_CONCURRENT_REQUESTS Table suggests request purging is not performed as often as required.<BR><BR>
    This Gauge is merely a simple indicator about volume of Concurrent Request data on '||g_rep_info('Instance')||'. <br>
    It displays GREEN if less than 3,500 rows are found, ORANGE if less than 5,000, and RED if over 5,000 rows are found.',
    'Clean up Concurrent Request Data and move the needle to green.<BR>
    For more information please review:<br>
    [1057802.1] - Concurrent Processing - Best Practices for Performance for Concurrent Managers in E-Business Suite.',
	null,
	'ALWAYS',
    'W',
    'RS',
    'Y');	

  add_signature(
	'CONC_REQ3',
	'select to_char(actual_completion_date,''YYYY'') "COMPLETED", count(request_id) "COUNT" 
	 from fnd_concurrent_requests where phase_code=''C''
	 group by to_char(actual_completion_date,''YYYY'')
	 order by to_char(actual_completion_date,''YYYY'') desc',
	'Your overall Concurrent Processing HealthCheck Status is Healthy!',
	'RS',   
    'The '||to_char(g_reqid_cnt,'999,999,999,999')||' rows in the FND_CONCURRENT_REQUESTS Table suggests purging is performed on a regular basis.<BR><BR>
    This Gauge is merely a simple indicator about volume of Concurrent Request data on '||g_rep_info('Instance')||'. <br>
    It displays GREEN if less than 3,500 rows are found, ORANGE if less than 5,000, and RED if over 5,000 rows are found.',
    'Clean up Concurrent Request Data and move the needle to green.<BR>
    For more information please review:<br>
    [1057802.1] - Concurrent Processing - Best Practices for Performance for Concurrent Managers in E-Business Suite.',
	null,
	'ALWAYS',
    'I',
    'RS',
    'Y');
	
  add_signature(
   'PURGEREQS',
   'SELECT r.REQUEST_ID, u.user_name, r.PHASE_CODE, r.ACTUAL_START_DATE,
          c.CONCURRENT_PROGRAM_NAME, p.USER_CONCURRENT_PROGRAM_NAME, r.ARGUMENT_TEXT,
          r.RESUBMIT_INTERVAL, r.RESUBMIT_INTERVAL_UNIT_CODE, r.RESUBMIT_END_DATE
          FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u
          WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id
          and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID
          and c.CONCURRENT_PROGRAM_NAME = ''FNDCPPUR''
          AND p.language = ''US''
          and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in (''P'',''R'')
          order by c.CONCURRENT_PROGRAM_NAME, r.ARGUMENT_TEXT',
   'Verify Purge and/or Manager Data Programs Scheduled to Run',
   'NRS',
   '<b>There are a total of '||to_char(g_reqid_cnt,'999,999,999,999')||' records in FND_CONCURRENT_REQUESTS that are completed, but no "Purge Concurrent Request and/or Manager Data" program (FNDCPPUR) scheduled or running</b>',
   '<b>Please Review Concurrent Processing purging status with your team.</b><br>
    Run the concurrrent program "Purge Concurrent Request and/or Manager Data" (FNDCPPUR) for all requests, or for specific requests that have large volumes of purge eligible data as seen above. The last purge of Concurrent Request data completed on No Date info available for VISION.
	FNDCPPUR should be scheduled and run on a regular basis to avoid performance issues. Run the query behind the SQL SCRIPT button to get the complete list of purge eligible concurrent request data, and for more information please review:<br>
	[1057802.1] - Concurrent Processing - Best Practices for Performance for Concurrent Managers in E-Business Suite
	[1095625.1] - Health Check Alert: Purge the eligible records from the FND_CONCURRENT_REQUESTS table<br><br>
	<b>Note:</b> This section is only looking at the scheduled jobs in FND_CONCURRENT_REQUESTS table. Jobs scheduled using other tools (DBMS_JOBS, CONSUB, or PL/SQL, etc) are not reflected here, so keep this in mind. ',
   '<b>There is a "Purge Concurrent Request and/or Manager Data" program (FNDCPPUR) scheduled or running on '||g_rep_info('Instance')||'.</b><br>
    There are a total of '||to_char(g_reqid_cnt,'999,999,999,999')||' records in FND_CONCURRENT_REQUESTS that are completed, and eligible for purging.', 
   'ALWAYS',
   'W',
   'RS');

 add_signature(
   'PURGELIGIBLE',
   'select p.USER_CONCURRENT_PROGRAM_NAME, decode(r.phase_code,''C'',''Complete'') STATUS, count(r.request_id) COUNT
	FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p
	WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID
	and r.phase_code=''C''
	group by p.USER_CONCURRENT_PROGRAM_NAME, r.phase_code
	order by count(r.request_id) desc',
   'Total Purge Eligible Records in FND_CONCURRENT_REQUESTS',
   'RS',
   'There are a total of '||to_char(g_reqid_cnt,'999,999,999,999')||' records in FND_CONCURRENT_REQUESTS that are completed, and eligible for purging.',
   '<b>Review Concurrent Processing purging status with your team.</b><br>
    Run the concurrrent program "Purge Concurrent Request and/or Manager Data" (FNDCPPUR) for all requests, or for specific requests that have large volumes of purge eligible data as seen above. The last purge of Concurrent Request data completed on No Date info available for VISION.
	FNDCPPUR should be scheduled and run on a regular basis to avoid performance issues. Run the query behind the SQL SCRIPT button to get the complete list of purge eligible concurrent request data, and for more information please review:<br>
	[1057802.1] - Concurrent Processing - Best Practices for Performance for Concurrent Managers in E-Business Suite
	[1095625.1] - Health Check Alert: Purge the eligible records from the FND_CONCURRENT_REQUESTS table<br><br>
	<b>Note:</b> This section is only looking at the scheduled jobs in FND_CONCURRENT_REQUESTS table. Jobs scheduled using other tools (DBMS_JOBS, CONSUB, or PL/SQL, etc) are not reflected here, so keep this in mind. ',
   'There are a total of '||to_char(g_reqid_cnt,'999,999,999,999')||' records in FND_CONCURRENT_REQUESTS that are completed, and eligible for purging.', 
   'ALWAYS',
   'W',
   'RS');
   
   add_signature(
   'EBS_VERSION',
   'SELECT instance_name, release_name, host_name,
          startup_time, version
          from fnd_product_groups, v$instance',
   'E-Business Suite Version',
   'NRS',
   'There is a problem identifying the EBS Instance Information',
   null,
   null,
   'ALWAYS',
   'I',
   'RS',
   'Y');

/*    add_signature(
      'TEST_RUN',
      'select * from fnd_concurrent_requests where request_id = ''##$$REQID$$##''',          
      'Testing signature substitution',
      'NRS',
      'Problem Msg: There is a problem identifying the signature substition values',
	 'Problem Solution Msg: <ul> 
       <li>Ensure the Reports Profile Options are properly set for this instance.</li>
       <li>If they are not, please contact the operating system administrator to set it as required.</li>
       <li>Refer to [356501.1] for How to Setup Pasta Quickly and Effectively</li> 
     </ul>',
 	 'Success Msg: You can substitute global hash variables that you set up.<br>
	  Using g_sql_token format, the request id entered is : '||g_sql_tokens('##$$REQID$$##')||'.<br>
	  The release of the Apps is: '||g_rep_info('Apps Version')||'.<BR>
	  You can also use g_rep_info to show the Apps Release is : '||g_rep_info('Apps Version')||'.<br>
	  <BR><b>Action:</b><BR> Please review the values for the profile options above to ensure they are 
	  properly set for this instance.',
     'ALWAYS',
     'W',
     'RS',
	 'Y');
*/
	 
  add_signature(
   'NODE_INFO',
   'SELECT substr(node_name, 1, 20) node_name, node_mode, server_address, substr(host, 1, 15) host,
       substr(domain, 1, 20) domain, substr(support_cp, 1, 3) cp, substr(support_web, 1, 3) web,
       substr(support_admin, 1, 3) ADMIN, substr(support_forms, 1, 3) FORMS,
       substr(SUPPORT_DB, 1, 3) db, substr(VIRTUAL_IP, 1, 30) virtual_ip 
       from fnd_nodes',
   'Instance Node Details',
   'NRS',
   'There is a problem identifying the EBS Instance Information',
  null,
   null,
  'ALWAYS',
    'I',
    'RS',
    'Y');
   
  add_signature(
   'CP_PARAMETERS',
   'SELECT name, value
          from v$parameter
          where upper(name) in (''AQ_TM_PROCESSES'',''JOB_QUEUE_PROCESSES'',''JOB_QUEUE_INTERVAL'',
                                ''UTL_FILE_DIR'',''NLS_LANGUAGE'', ''NLS_TERRITORY'', ''CPU_COUNT'',
                                ''PARALLEL_THREADS_PER_CPU'')',
   'Concurrent Processing Database Parameter Settings',
   'NRS',
   'There is a problem identifying the Concurrent Processing Database Parameter Settings',
   'Verify the Concurrent Processing Database Parameter Settings are set',
   'For more information refer to [396009.1] - Database Initialization Parameters for Oracle E-Business Suite Release 12',
   'SUCCESS',
   'I');
   
  add_signature(
   'CP_ENV',
   'SELECT unique variable_name, value
          from FND_ENV_CONTEXT
          where CONCURRENT_PROCESS_ID in
          (select max(CONCURRENT_PROCESS_ID) from FND_CONCURRENT_PROCESSES
           where QUEUE_APPLICATION_ID in (select APPLICATION_ID from FND_APPLICATION where APPLICATION_SHORT_NAME = ''FND''))
           and VARIABLE_NAME in (''APPLTMP'',''APPLPTMP'',''REPORTS60_TMP'',''APPLCSF'',''APPLLOG'',''APPLOUT'')',
   'Concurrent Processing Environment Variables',
   'NRS',
   'There is a problem identifying the Concurrent Processing Environment Variables',
   'Verify the Concurrent Processing Environment Variables',
   'Refer to [1355735.1] - Difference between APPLPTMP and APPLTMP Directories in EBS',
   'SUCCESS',
   'I');

  add_signature(
   'CP_PROFILES',
   'SELECT t.PROFILE_OPTION_ID, t.PROFILE_OPTION_NAME, z.language, z.USER_PROFILE_OPTION_NAME,
          v.PROFILE_OPTION_VALUE, z.DESCRIPTION
          from fnd_profile_options t, fnd_profile_option_values v, fnd_profile_options_tl z
          where (v.PROFILE_OPTION_ID (+) = t.PROFILE_OPTION_ID)
          and (v.level_id = 10001)
          and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)
          and (t.PROFILE_OPTION_NAME in (''CONC_GSM_ENABLED'',''CONC_PP_RESPONSE_TIMEOUT'',''CONC_TM_TRANSPORT_TYPE'',''GUEST_USER_PWD'',
          ''AFLOG_ENABLED'',''AFLOG_FILENAME'',''AFLOG_LEVEL'',''AFLOG_BUFFER_MODE'',''AFLOG_MODULE'',''FND_FWK_COMPATIBILITY_MODE'',
          ''FND_VALIDATION_LEVEL'',''FND_MIGRATED_TO_JRAD'',''AMPOOL_ENABLED'',''CONC_PP_PROCESS_TIMEOUT'',''CONC_DEBUG'',''CONC_COPIES'',
		  ''CONC_FORCE_LOCAL_OUTPUT_MODE'',''CONC_HOLD'',''CONC_CD_ID'',''CONC_PMON_METHOD'',''CONC_PP_INIT_DELAY'',''CONC_PRINT_WARNING'',
		  ''CONC_REPORT_ACCESS_LEVEL'',''CONC_REQUEST_LIMIT'',''CONC_SINGLE_THREAD'',''CONC_TOKEN_TIMEOUT'',''CONC_VALIDATE_SUBMISSION'',
		  ''FND_CONC_ALLOW_DEBUG'',''CP_INSTANCE_CHECK''))
          order by z.USER_PROFILE_OPTION_NAME',
   'E-Business Suite Profile Settings',
   'NRS',
   'There is a problem identifying the E-Business Suite Profile Settings',
   'Verify the E-Business Suite Profile Settings',
   'E-Business Suite Profile Settings',
   'SUCCESS',
   'I');
   
   
  add_signature(
   'GSM_ENABLED',
   'SELECT p.PROFILE_OPTION_NAME, v.PROFILE_OPTION_VALUE
   from fnd_profile_option_values v, fnd_profile_options p
  where v.PROFILE_OPTION_ID = p.PROFILE_OPTION_ID
    and p.PROFILE_OPTION_NAME = ''CONC_GSM_ENABLED''
    and sysdate BETWEEN p.start_date_active
    and NVL(p.end_date_active, sysdate)
    and v.PROFILE_OPTION_VALUE = ''Y''',
   'Verify Profile "Concurrent:GSM Enabled" is enabled',
   'NRS',
   'The EBS profile "Concurrent:GSM Enabled" is not enabled.',
   'Please review [210062.1] - Concurrent Processing - Generic Service Management (GSM) in Oracle Applications, for more information.<BR>',
   'Profile "Concurrent:GSM Enabled" is enabled as expected<br><br>
    The profile "Concurrent:GSM Enabled" is currently set to Y to allow GSM to manage processes on multiple host machines.<BR>
    Please review [210062.1] - Concurrent Processing - Generic Service Management (GSM) in Oracle Applications, for more information.<BR>',
   'ALWAYS',
   'E');
   
  add_signature(
   'FND_FILE',
   'SELECT name, value 
          FROM  v$parameter
          WHERE name = ''utl_file_dir''',
   'Check FND_FILE Setup',
   'NRS',
   'The FND_FILE Setup is not enabled.',
   'Need to correct this<br>Please review [210062.1] - Concurrent Processing - Generic Service Management (GSM) in Oracle Applications, for more information.<BR>',
   '<b>FND_FILE Setup is enabled as expected.</b><br>
    For more information, please review [261693.1] - Concurrent Processing - Troubleshooting Concurrent Request ORA-20100 errors in the request logs.',
   'ALWAYS',
   'E');
   
   
  add_signature(
   'APPLTMP',
   'SELECT VARIABLE_NAME, VALUE 
          from FND_ENV_CONTEXT 
          where CONCURRENT_PROCESS_ID in 
          (select max(CONCURRENT_PROCESS_ID) from FND_CONCURRENT_PROCESSES
          where CONCURRENT_QUEUE_ID in (select CONCURRENT_QUEUE_ID from FND_CONCURRENT_QUEUES where CONCURRENT_QUEUE_NAME = ''WFMLRSVC'')
          and QUEUE_APPLICATION_ID in (select APPLICATION_ID from FND_APPLICATION
          where APPLICATION_SHORT_NAME = ''FND''))
          and VARIABLE_NAME in (''APPLTMP'')
          order by VARIABLE_NAME',
   'Display $APPLTMP Evironment Variable',
   'NRS',
   'Display $APPLTMP Environment Variable',
   'Need to correct this<br>Display $APPLTMP Environment Variable',
   '<b>$APPLTMP Environment Variable is enabled as expected.</b><br>
    For more information, please review Display $APPLTMP Environment Variable',
   'ALWAYS',
   'E');

  add_signature(
   'LONGRPTS',
   'SELECT p.user_concurrent_program_name program_name, count(r.request_id),
          avg((nvl(r.actual_completion_date,sysdate) - r.actual_start_date) * 1440) avg_run_time,
          min((nvl(r.actual_completion_date,sysdate) - r.actual_start_date) * 1440) min_run_time,
          max((nvl(r.actual_completion_date,sysdate) - r.actual_start_date) * 1440) max_run_time
          from apps.fnd_concurrent_requests r, apps.fnd_concurrent_processes c, apps.fnd_concurrent_queues q,
          apps.fnd_concurrent_programs_vl p
          where p.concurrent_program_id = r.concurrent_program_id and p.application_id = r.program_application_id
          and c.concurrent_process_id = r.controlling_manager and q.concurrent_queue_id = c.concurrent_queue_id
          and q.concurrent_queue_name <> ''HIGH_IMPACT''and p.application_id >= 20000 and r.actual_start_date >= sysdate-31
          and r.status_code = ''C'' and r.phase_code in (''C'',''G'')
          and (nvl(r.actual_completion_date,r.actual_start_date) - r.actual_start_date) * 24 * 60 > 30
          and p.user_concurrent_program_name not like ''Gather%Statistics%''
          and ((nvl(r.actual_completion_date,r.actual_start_date) - r.actual_start_date) * 24 > 16
          or (r.actual_start_date-trunc(r.actual_start_date)) * 24 between 9 and 17
          or (r.actual_completion_date-trunc(r.actual_completion_date)) * 24 between 9 and 17)
          group by p.user_concurrent_program_name
          order by avg((nvl(r.actual_completion_date,sysdate) - r.actual_start_date) * 1440) desc', 
   'Long Running Reports During Business Hours',
   'RS',
   'You have Long Running Reports During Business Hours',
   'Review the requests listed and confirm if they are intended to run for longer amounts of time.<br> 
	If the wrong date range is used or a large volume of data exists for the request, a longer run time can be expected.<br> 
	Monthly, Quarterly, and Yearly requests would typically run longer. ',
   'There does not appear to be any long running requests during business hours.<br> 
	The intent is to proactively identify requests which could represent potential performance problems. ',
   'ALWAYS',
   'I');
   
  
  add_signature(
   'ELAPSEDHIST',
   'SELECT f.application_short_name "APPLICATION", substr(p.user_concurrent_program_name,1,55) "DESCRIPTION",
        substr(p.concurrent_program_name,1,20) "PROGRAM", r.priority "PRIORITY", 
		to_char(count(*),''999,999,999,999'') "#TIMESRUN",
        to_char(round(sum(actual_completion_date - actual_start_date) * 1440, 2),''999,999,999,999.99'') "TOTAL|MINS",
       to_char(round(avg(actual_completion_date - actual_start_date) * 1440, 2),''999,999,999,999.99'') "AVG|MINS",
       to_char(round(max(actual_completion_date - actual_start_date) * 1440, 2),''999,999,999,999.99'') "MAX|MINS",
       to_char(round(min(actual_completion_date - actual_start_date) * 1440, 2),''999,999,999,999.99'') "MIN|MINS",
       to_char(round(stddev(actual_completion_date - actual_start_date) * 1440, 2),''999,999,999,999.99'') "RUN|STHDEV MINS",
       to_char(round(stddev(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440, 2),''999,999,999,999.99'') "WAIT|STHDEV MINS",
       to_char(round(sum(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440, 2),''999,999,999,999.99'') "#WAITED|MINS",
       to_char(round(avg(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 1440, 2),''999,999,999,999.99'') "AVG|WAIT MINS",
       c.request_class_name "TYPE"
      from apps.fnd_concurrent_request_class c, apps.fnd_application f, apps.fnd_concurrent_programs_vl p,
      apps.fnd_concurrent_requests r 
      where r.program_application_id = p.application_id and r.concurrent_program_id = p.concurrent_program_id
      and r.status_code in (''C'',''G'') and r.phase_code = ''C'' and p.application_id = f.application_id
      and r.program_application_id = f.application_id and r.request_class_application_id = c.application_id(+)
      and r.concurrent_request_class_id = c.request_class_id(+)
      group by c.request_class_name, f.application_short_name, p.concurrent_program_name, p.user_concurrent_program_name, r.priority
      order by count(*)',
   'Elapsed Time History of Concurrent Requests',
   'RS',
   'This section identifies the total time duration for recently completed requests.',
   'The output produced can be cross referenced with the enabled managers and defined workshifts outputs,
	for better allocation of requests across the existing managers/workshifts. <br>
	For example you can consider assigning quick requests to one manager and/or workshift, and assigning slow requests to another manager and/or workshift. <br>
	Requests with varying runtimes can also be moved to their own manager, or remain with the standard manager queue.',
	null,
   'ALWAYS',
   'I',
   'RS',
   'N');

   
  add_signature(
   'CURRENTREQS',
   'SELECT w.seconds_in_wait "Secondswait", w.event "waitEvent", w.p1||chr(10)||w.p2||chr(10)||w.p3 "Session Wait",
          p.spid||chr(10)||s.process "ServerClient", s.sid||chr(10)||s.serial#||chr(10)||s.sql_hash_value "SidSerialSQLHash",
          u.user_name||chr(10)||PHASE_CODE||'' ''||STATUS_CODE||chr(10)||s.status "DBPhaseStatusCODEUser",
          Request_id||chr(10)||priority_request_id||chr(10)||Parent_request_id "Request_id",
          concurrent_program_name, user_concurrent_program_name,
          requested_start_Date||chr(10)||round((sysdate- requested_start_date)*1440, 2)||''M'' "RequestStartDate",
          ARGUMENT_TEXT, CONCURRENT_QUEUE_ID, QUEUE_DESCRIPTION
          FROM FND_CONCURRENT_WORKER_REQUESTS, fnd_user u, v$session s, v$process p, v$session_wait w 
          WHERE (Phase_Code=''R'')and hold_flag != ''Y''and Requested_Start_Date <= SYSDATE 
          AND ('''' IS NULL OR ('''' = ''B'' AND PHASE_CODE = ''R'' AND STATUS_CODE IN (''I'', ''Q'')))and ''1'' in (0,1,4)
          and requested_by=u.user_id and s.paddr=p.addr and s.sid=w.sid and oracle_process_id = p.spid
          and oracle_session_id = s.audsid 
          order by requested_start_date',
   'Requests Currently Running on a System',
   'NRS',
   'There are no Concurrent Requests currently Running on this '||g_rep_info('Instance')||' instance',
   'This table reflects a summary for all concurrent requests running on the instance with thier current state.',
   'This reflects a summary for all concurrent requests running on the instance with thier current state.',
   'ALWAYS',
   'I',
   'Y');

   
  add_signature(
   'CONCREQTOTALS',
   'SELECT decode(phase_code, ''P'', ''Pending requests'',''R'', ''Running requests'',''C'', ''Completed requests'') PHASE,
          count(request_id) "# of Requests"
          FROM fnd_concurrent_requests
          GROUP BY phase_code',
   'FND_CONCURRENT_REQUESTS Totals',
   'RS',
   'Provides a count of concurrent requests in a state of: Pending, Running, or Completed.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of how often you are purging Concurrent Request tables. <br>
    If the total records are too large performance issues can result and FNDCPPUR should be run, otherwise there is no immediate action required. ',
   'There are no concurrent requests in a state of: Pending, Running, or Completed.',
   'ALWAYS',
   'I');


  add_signature(
   'CONCREQS',
   'SELECT request_id id, nvl(meaning, ''UNKNOWN'') status, user_concurrent_program_name rpname,
       to_char(actual_start_date, ''DD-MON-RR HH24:MI:SS'') sd, decode(run_alone_flag, ''Y'', ''Yes'', ''No'') ra
       FROM   fnd_concurrent_requests fcr, fnd_lookups fl, fnd_concurrent_programs_vl fcpv
       WHERE  phase_code = ''R'' AND LOOKUP_TYPE = ''CP_STATUS_CODE'' AND lookup_code = status_code
       AND fcr.concurrent_program_id = fcpv.concurrent_program_id AND fcr.program_application_id = fcpv.application_id
       ORDER BY actual_start_date, request_id',
   'Running Requests',
   'NRS',
   'There are no concurrent requests currently running on this '||g_rep_info('Instance')||' instance.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently running on the system.<br>
    Otherwise there is no immediate action required.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently running on the system.<br>
    Otherwise there is no immediate action required. ',
   'ALWAYS',
   'I');


  add_signature(
   'PENDREQ',
   'SELECT ''Pending'' "Phase", meaning "Status", count(*) "# Reqs"
       FROM   fnd_concurrent_requests, fnd_lookups
       WHERE  LOOKUP_TYPE = ''CP_STATUS_CODE'' AND lookup_code = status_code AND phase_code = ''P''
       GROUP BY meaning',
   'Total Pending Requests by Status Code',
   'NRS',
   'There are no Pending Requests currently found on this '||g_rep_info('Instance')||' instance.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently pending on the system. <br>
    Otherwise there is no immediate action required.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently pending on the system. <br>
    Otherwise there is no immediate action required.',
   'ALWAYS',
   'I');


  add_signature(
   'PENDREGSCHDREQ',
   'SELECT ''Pending Regularly Scheduled requests:'' schedt, count(*) schedcnt
          from   fnd_concurrent_requests
          WHERE  (requested_start_date > sysdate OR status_code = ''P'') AND phase_code = ''P''',
   'Count of Pending Regularly Scheduled Requests',
   'NRS',
   'There are no Pending Regularly Scheduled Requests',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system. <br>
    Otherwise there is no immediate action required.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system. <br>
    Otherwise there is no immediate action required.',
   'ALWAYS',
   'I');


  add_signature(
   'PENDNONREGSCHDREQ',
   'SELECT ''Pending Non Regularly Scheduled requests:'' schedt, count(*) schedcnt
          from   fnd_concurrent_requests
          WHERE  requested_start_date <= sysdate AND status_code != ''P'' AND phase_code = ''P''',
   'Count of Pending Non Regularly Scheduled Requests',
   'NRS',
   'There are no Pending Non Regularly Scheduled Requests',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system. <br>
    Otherwise there is no immediate action required.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system. <br>
    Otherwise there is no immediate action required.',
   'ALWAYS',
   'I');      



  add_signature(
   'CNTPENDREQ_OH',
   'SELECT ''Pending Requests on hold:'' schedt, count(*) schedcnt
          from   fnd_concurrent_requests
          WHERE  hold_flag = ''Y'' AND phase_code = ''P''',
   'Count of Pending Requests on Hold',
   'NRS',
   'There are no Pending Requests on Hold',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently on hold in the system. <br>
    Otherwise there is no immediate action required.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently on hold in the system. <br>
    Otherwise there is no immediate action required.',
   'ALWAYS',
   'I');



  add_signature(
   'CNTPENDREQ_NOH',
   'SELECT ''Pending Requests Not on hold:'' schedt, count(*) schedcnt
          from   fnd_concurrent_requests
          WHERE  hold_flag != ''Y'' AND phase_code = ''P''',
   'Count of Pending Requests Not on Hold',
   'NRS',
   'There are no Pending Requests Not on Hold',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently on hold in the system. <br>
    Otherwise there is no immediate action required.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently on hold in the system. <br>
    Otherwise there is no immediate action required.',
   'ALWAYS',
   'I');


  add_signature(
   'SCHEDULEDREQ',
   'SELECT request_id REQ_ID, fu.user_name REQUESTED_BY, nvl(meaning, ''UNKNOWN'') status, user_concurrent_program_name PROGRAM_NAME,
          to_char(request_date, ''DD-MON-RR HH24:MI:SS'') SUBMITTED, to_char(requested_start_date, ''DD-MON-RR HH24:MI:SS'') START_DATE
          FROM fnd_concurrent_requests fcr, fnd_lookups fl, fnd_concurrent_programs_vl fcpv, fnd_user fu
          WHERE fcr.requested_by = fu.user_id 
          and phase_code = ''P'' AND (fcr.requested_start_date >= sysdate OR status_code = ''P'')
          AND LOOKUP_TYPE = ''CP_STATUS_CODE'' AND lookup_code = status_code AND fcr.concurrent_program_id = fcpv.concurrent_program_id
          AND fcr.program_application_id = fcpv.application_id
          ORDER BY requested_start_date',
   'Listing of Scheduled Requests',
   'NRS',
   'There are no Scheduled Requests',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system.<br>
    Otherwise there is no immediate action required.<br><br>
	For more information refer to [213021.1] - Concurrent Processing (CP) / APPS Reporting Scripts',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system.<br>
    Otherwise there is no immediate action required.<br><br>
	For more information refer to [213021.1] - Concurrent Processing (CP) / APPS Reporting Scripts',
   'ALWAYS',
   'I');      


  add_signature(
   'PENDREQHOLD',
   'SELECT request_id id, nvl(meaning, ''UNKNOWN'') status, user_concurrent_program_name pname,
           to_char(request_date, ''DD-MON-RR HH24:MI:SS'') submitd
           FROM fnd_concurrent_requests fcr, fnd_lookups fl, fnd_concurrent_programs_vl fcpv
           WHERE phase_code = ''P'' AND hold_flag = ''Y'' AND fcr.requested_start_date <= sysdate
           AND status_code != ''P'' AND LOOKUP_TYPE = ''CP_STATUS_CODE'' AND lookup_code = status_code
           AND fcr.concurrent_program_id = fcpv.concurrent_program_id AND fcr.program_application_id = fcpv.application_id
           ORDER BY request_date, request_id',
   'Listing of Pending Requests on Hold',
   'NRS',
   'There are no Pending Requests on Hold and wating to be run',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system. <br>
    Otherwise there is no immediate action required.<br>
    To get a complete list of Pending Requests on Hold including the Request ID, run the query behind the SQL SCRIPT button.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of Pending Requests on Hold and wating to be run. <br>
    Otherwise there is no immediate action required.<br>
    To get a complete list of Pending Requests on Hold including the Request ID, run the query behind the SQL SCRIPT button.',
   'ALWAYS',
   'I');      



  add_signature(
   'SCHEDULEDREQ2',
   'SELECT request_id id, nvl(meaning, ''UNKNOWN'') status, user_concurrent_program_name pname,
          to_char(request_date, ''DD-MON-RR HH24:MI:SS'') submitd, to_char(requested_start_date, ''DD-MON-RR HH24:MI:SS'') requestd
          FROM   fnd_concurrent_requests fcr, fnd_lookups fl, fnd_concurrent_programs_vl fcpv
          WHERE  phase_code = ''P'' AND hold_flag = ''N'' AND fcr.requested_start_date <= sysdate
          AND status_code != ''P'' AND LOOKUP_TYPE = ''CP_STATUS_CODE'' AND lookup_code = status_code
          AND fcr.concurrent_program_id = fcpv.concurrent_program_id AND fcr.program_application_id = fcpv.application_id
          ORDER BY request_date, request_id',
   'Listing of Scheduled Requests',
   'NRS',
   'There are not scheduled requests waiting to run that are currently not on hold.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of whats currently scheduled on the system. <br>
    Otherwise there is no immediate action required.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of Pending Requests waiting to run that are currently not on hold.. <br>
    Otherwise there is no immediate action required.',
   'ALWAYS',
   'I');


  add_signature(
   'LASTMONDAILY',
   'SELECT trunc(REQUESTED_START_DATE), count(*)
          FROM FND_CONCURRENT_REQUESTS
          WHERE REQUESTED_START_DATE BETWEEN sysdate-30 AND sysdate
          group by rollup(trunc(REQUESTED_START_DATE))',
   'Volume of Daily Concurrent Requests for Last Month',
   'NRS',
   'There are no rows showing Volume of Daily Concurrent Requests for Last Month',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of your average monthly throughput, and identify any spikes or drops. <br>
    Otherwise there is no immediate action required.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline of your average monthly throughput, and identify any spikes or drops. <br>
    Otherwise there is no immediate action required. ',
   'ALWAYS',
   'I');


  add_signature(
   'RUNALONE',
   'SELECT USER_CONCURRENT_PROGRAM_NAME, ENABLED_FLAG, CONCURRENT_PROGRAM_NAME, DESCRIPTION, RUN_ALONE_FLAG
          FROM FND_CONCURRENT_PROGRAMS_VL
          WHERE (RUN_ALONE_FLAG=''Y'')',
   'Identify/Resolve the "Pending/Standby" Issue, if Caused by Run Alone Flag',
   'NRS',
   'There are no Requests that Identify/Resolve the "Pending/Standby" Issue, if Caused by Run Alone Flag',
   'The output provided is for review and confirmation by your teams, and is intended to identify any concurrent program definitions causing Pending/Standby Requests which may require review.',
   'The output provided is for review and confirmation by your teams, and is intended to identify any concurrent program definitions causing Pending/Standby Requests which may require review.',
   'ALWAYS',
   'I');


  add_signature(
   'TABLESPACES',
   'SELECT SEGMENT_NAME "Table Name",sum(BLOCKS)  "Total blocks" , sum(bytes/1024/1024) "Size in MB" 
          from dba_segments
          where segment_name in (''FND_CONCURRENT_REQUESTS'',''FND_CONCURRENT_PROCESSES'',''FND_CONCURRENT_QUEUES'',
          ''FND_ENV_CONTEXT'',''FND_EVENTS'',''FND_EVENT_TOKENS'')
          group by segment_name
          order by 2',
   'Tablespace Statistics for the FND_CONCURRENT Tables',
   'NRS',
   'There are no rows found for Tablespace Statistics for the FND_CONCURRENT Tables',
   'The output provided is for review and confirmation by your teams, and serves as a baseline regarding your tablespace disk overhead. <br>
    You can cross reference the collected information with exisiting notes on tablespace sizing and defragmentation best practices',
   'The output provided is for review and confirmation by your teams, and serves as a baseline regarding your tablespace disk overhead. <br>
    You can cross reference the collected information with exisiting notes on tablespace sizing and defragmentation best practices',
   'ALWAYS',
   'I');


  add_signature(
   'TABLESPACES2',
   'SELECT table_name,blocks, empty_blocks, num_rows,last_analyzed,sample_size
          FROM   all_tables
          WHERE table_name in (''FND_CONCURRENT_REQUESTS'',''FND_CONCURRENT_PROCESSES'',
          ''FND_CONCURRENT_QUEUES'',''FND_ENV_CONTEXT'',''FND_EVENTS'',''FND_EVENT_TOKENS'')',
   'Additional Tablespace Statistics for the FND_CONCURRENT Tables',
   'NRS',
   'There are no rows found for Additional Tablespace Statistics for the FND_CONCURRENT Tables',
   'The output provided is for review and confirmation by your teams, and serves as a baseline regarding your tablespace disk overhead. <br>
    You can cross reference the collected information with exisiting notes on tablespace sizing and defragmentation best practices',
   'The output provided is for review and confirmation by your teams, and serves as a baseline regarding your tablespace disk overhead. <br>
    You can cross reference the collected information with exisiting notes on tablespace sizing and defragmentation best practices',
   'ALWAYS',
   'I');      

  add_signature(
   'CPADV1',
   'SELECT q.CONCURRENT_QUEUE_NAME "Queue Name", q.USER_CONCURRENT_QUEUE_NAME "User Queue Name",  
          a.application_short_name module,q.cache_size cache, p.concurrent_time_period_name, 
          qs.min_processes, qs.max_processes, qs.sleep_seconds
          from apps.fnd_concurrent_queues_vl q, apps.fnd_product_installations i, apps.fnd_application_vl a,
          apps.fnd_concurrent_time_periods p, apps.fnd_concurrent_queue_size qs
          where i.application_id = q.application_id 
          and a.application_id = q.application_id 
          and qs.queue_application_id = q.application_id
          and qs.concurrent_queue_id = q.concurrent_queue_id 
          and qs.period_application_id = p.application_id
          and qs.concurrent_time_period_id = p.concurrent_time_period_id 
          and q.enabled_flag = ''Y'' 
          and nvl(q.control_code,''X'') <> ''E''
          order by q.concurrent_queue_name, p.concurrent_time_period_id',
   'Concurrent Managers Active/Enabled and Workshifts',
   'NRS',
   'There are no Concurrent Managers Active/Enabled and Workshifts',
   'This section collects the Concurrent Managers that are currently Active and Enabled to process data, and associated with a specific Workshift, and establishes a baseline list of managers defined on your system. 
	The Workshifts are created to define specific times when a Manager can run requests.<br>
	The resulting data is for review and confirmation by your teams, and serves as a baseline for comparison with later outputs above. <br>
    Otherwise there is no immediate action required.<br><br>
	For more information refer to [1373727.1] - FAQ: EBS Concurrent processing Performance and Best Practices.',
   'This section collects the Concurrent Managers that are currently Active and Enabled to process data, and associated with a specific Workshift, and establishes a baseline list of managers defined on your system. 
	The Workshifts are created to define specific times when a Manager can run requests.<br>
	The resulting data is for review and confirmation by your teams, and serves as a baseline for comparison with later outputs above. <br>
    Otherwise there is no immediate action required.<br><br>
	For more information refer to [1373727.1] - FAQ: EBS Concurrent processing Performance and Best Practices.',
   'ALWAYS',
   'I');


  add_signature(
   'CPADV3',
   'SELECT q.CONCURRENT_QUEUE_NAME, p.concurrent_time_period_name, qs.min_processes
          from apps.fnd_concurrent_queues_vl q, apps.fnd_product_installations i, apps.fnd_application_vl a,
          apps.fnd_concurrent_time_periods p, apps.fnd_concurrent_queue_size qs
          where i.application_id = q.application_id and a.application_id = q.application_id
          and qs.queue_application_id = q.application_id and qs.concurrent_queue_id = q.concurrent_queue_id
          and qs.period_application_id = p.application_id and qs.concurrent_time_period_id = p.concurrent_time_period_id
          and q.enabled_flag = ''Y'' and nvl(q.control_code,''X'') <> ''E'' and qs.min_processes >0 and i.status <> ''I''
          order by q.concurrent_queue_name, p.concurrent_time_period_id',
   'Active Managers for Applications not Installed/Used',
   'RS',
   'There are Concurrent Managers that are active for Application modules not Installed or Used.',
   'These unused managers can impact performance, and deactivating them can reduce current application overhead on the instance.',
   'There are no Concurrent Managers that are active for Application modules not Installed or Used. ',
   'ALWAYS',
   'W');


  add_signature(
   'CPADV4',
   'SELECT q.CONCURRENT_QUEUE_NAME, q.max_processes, q.running_processes, q.node_name, q.node_name2,
          p.concurrent_time_period_name, qs.min_processes
          from apps.fnd_concurrent_queues_vl q, apps.fnd_product_installations i, apps.fnd_application_vl a,
          apps.fnd_concurrent_time_periods p, apps.fnd_concurrent_queue_size qs
          where i.application_id = q.application_id and a.application_id = q.application_id
          and qs.queue_application_id = q.application_id and qs.concurrent_queue_id = q.concurrent_queue_id
          and qs.period_application_id = p.application_id and qs.concurrent_time_period_id = p.concurrent_time_period_id
          and q.enabled_flag = ''Y'' and nvl(q.control_code,''X'') <> ''E'' and qs.min_processes >0 and q.manager_type = 1
          and p.concurrent_time_period_name not in (''Weekend'',''Off-Peak AM'',''Off-Peak PM'')
          order by qs.min_processes desc,q.concurrent_queue_name',
   'Total Target Processes for Request Managers Excluding Off-Hours',
   'RS',
   'Total Target Processes for Request Managers Excluding Off-Hours<br>
    This identifies the total number of processes that can be run for a given concurrent manager. <br>
    The greater the number of processes defined can impact increased Concurrent Processing loads. ',
   'The resulting data is for review and confirmation by your teams, and serves as a baseline for comparison with later outputs above. <br>
	Otherwise there is no immediate action required.',	
   'There are no rows found for Total Target Processes for Request Managers Excluding Off-Hours',
   'ALWAYS',
   'I');


  add_signature(
   'CPADV5',
   'SELECT q.CONCURRENT_QUEUE_NAME, q.cache_size, max(qs.min_processes) max_proc
          from apps.fnd_concurrent_queues_vl q, apps.fnd_product_installations i, apps.fnd_application_vl a,
          apps.fnd_concurrent_time_periods p, apps.fnd_concurrent_queue_size qs
          where i.application_id = q.application_id and a.application_id = q.application_id
          and qs.queue_application_id = q.application_id and qs.concurrent_queue_id = q.concurrent_queue_id
          and qs.period_application_id = p.application_id and qs.concurrent_time_period_id = p.concurrent_time_period_id
          and q.enabled_flag = ''Y'' and nvl(q.control_code,''X'') <> ''E'' and qs.min_processes >0 and q.manager_type = 1
          group by q.CONCURRENT_QUEUE_NAME, q.cache_size
          having decode(max(qs.min_processes),1,2,max(qs.min_processes)) > nvl(q.cache_size,1)
          order by  q.concurrent_queue_name',
   'Request Managers with Incorrect Cache Size',
   'RS',
   'There are Request Managers with Incorrect Cache Size',
   'A Managers cache size reflects the number of requests a manager adds to its queue, each time it reads available requests to run. <br>
	For example, if a manager has 1 target process and a cache value of 3, it will read 3 requests and run those requests before returning to cache additional requests. 
	<br><br>
	Tip: Enter a value of 1 when defining a manager that runs long, time-consuming jobs, and a value of 3 or 4 for managers that run small, quick jobs. <BR><br>
	For more information refer to [1373727.1] - FAQ: EBS Concurrent processing Performance and Best Practices',
   'There are no Request Managers with Incorrect Cache Size',
   'ALWAYS',
   'E');

  add_signature(
   'CPADV11',
   'SELECT  q.concurrent_queue_name, count(*) cnt, 
		  to_char(round(sum(r.actual_completion_date - r.actual_start_date) * 24, 2),''999,999,999,999.99'') elapsed,
		  to_char(round(avg(r.actual_completion_date - r.actual_start_date) * 24, 2),''999,999,999,999.99'') average,
          to_char(round(stddev(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 24, 2),''999,999,999,999.99'') wstddev,
          to_char(round(sum(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 24, 2),''999,999,999,999.99'') waited,
          to_char(round(avg(actual_start_date - greatest(r.requested_start_date,r.request_date)) * 24, 2),''999,999,999,999.99'') avewait
          from apps.fnd_concurrent_programs p, apps.fnd_concurrent_requests r, apps.fnd_concurrent_queues q,
          apps.fnd_concurrent_processes p 
          where r.program_application_id = p.application_id and r.concurrent_program_id = p.concurrent_program_id 
          and r.phase_code=''C'' -- completed and r.status_code in (''C'',''G'')  -- completed normal or with warning
          and r.controlling_manager=p.concurrent_process_id and q.concurrent_queue_id=p.concurrent_queue_id 
          and r.concurrent_program_id=p.concurrent_program_id 
          group by  q.concurrent_queue_name',
   'Concurrent Manager Request Summary by Manager',
   'RS',
   'These are the concurrent managers being used, and can be compared with the actual concurrent managers allocated at startup. <br>
    This only considers requests with completion status of normal/warning.',
   'Please consider deactivation of any managers which are consistently not being used, and are listed as Active/Enabled above. ',
   'There are no concurrent managers are being used, and can be compared with the actual concurrent managers allocated at startup. ',
   'ALWAYS',
   'I');


  add_signature(
   'CPADV12',
   'SELECT a.CONCURRENT_QUEUE_ID "Queue ID", a.QUEUE_APPLICATION_ID "Apps ID",
          b.user_CONCURRENT_QUEUE_NAME "Concurrent Manager", decode(a.PHASE_CODE, ''P'',''PENDING'',''R'',''Running'') Phase,count(1)
          FROM FND_CONCURRENT_WORKER_REQUESTS a, fnd_concurrent_queues_vl b
          WHERE (a.Phase_Code = ''P'' or a.Phase_Code = ''R'') and a.hold_flag != ''Y'' and a.Requested_Start_Date <= SYSDATE
          AND ('''' IS NULL OR ('''' = ''B'' AND a.PHASE_CODE = ''R'' AND a.STATUS_CODE IN (''I'', ''Q''))) and ''1'' in (0,1,4)
          And a.concurrent_queue_id=b.concurrent_queue_id
          group by a.CONCURRENT_QUEUE_ID, a.QUEUE_APPLICATION_ID, b.user_CONCURRENT_QUEUE_NAME, a.PHASE_CODE
          order by 1',
   'Check Manager Queues for Pending Requests',
   'RS',
   'There are concurrent requests that are in a Pending state. ',
   'The output above is for review and confirmation by your team. Typically when there are requests pending, the number should be the same as the number of actual processes. <br>
    However if there are no pending requests or requests were just submitted, the number of requests running may be less than the number of actual processes. <br>
	Also note if a concurrent program is incompatible with another program currently running, it does not start until the incompatible program has completed. In this case, the number of requests running may be less than number of actual processes even when there are requests pending. ',
   'There are no concurrent requests that are in a Pending state.',
   'ALWAYS',
   'I');


  add_signature(
   'CPADV17',
   'SELECT service_id, service_handle, developer_parameters
         FROM fnd_cp_services
         WHERE service_id = (SELECT manager_type
                             FROM fnd_concurrent_queues
                             WHERE concurrent_queue_name = ''FNDCPOPP'')',
   'Check the Configuration of OPP',
   'RS',
   'OPP is currently configured, identifying the: Service ID, Service Handle, and Parameters used.',
   'The output provided is for review and confirmation by your teams, and serves as a baseline regarding your current OPP configuration. <br>
	You can cross reference the collected information with existing notes on OPP best practices :<br>
	[1399454.1] - Tuning Output Post Processor (OPP) to Improve Performance<br>
	[1057802.1] -	Concurrent Processing - Best Practices for Performance for Concurrent Managers in E-Business Suite',
   'OPP is currently not configured.<br><br>
    Please check existing notes on OPP best practices :<br>
	[1399454.1] - Tuning Output Post Processor (OPP) to Improve Performance<br>
	[1057802.1] -	Concurrent Processing - Best Practices for Performance for Concurrent Managers in E-Business Suite',
   'ALWAYS',
   'I');  

 
   
  -- PSD #11a
  add_signature(
   'INVALIDS',
   'SELECT a.object_name,
           decode(a.object_type,
             ''PACKAGE'', ''Package Spec'',
             ''PACKAGE BODY'', ''Package Body'',
             a.object_type) type,
           (
             SELECT ltrim(rtrim(substr(substr(c.text, instr(c.text,''Header: '')),
               instr(substr(c.text, instr(c.text,''Header: '')), '' '', 1, 1),
               instr(substr(c.text, instr(c.text,''Header: '')), '' '', 1, 2) -
               instr(substr(c.text, instr(c.text,''Header: '')), '' '', 1, 1)
               ))) || '' - '' ||
               ltrim(rtrim(substr(substr(c.text, instr(c.text,''Header: '')),
               instr(substr(c.text, instr(c.text,''Header: '')), '' '', 1, 2),
               instr(substr(c.text, instr(c.text,''Header: '')), '' '', 1, 3) -
               instr(substr(c.text, instr(c.text,''Header: '')), '' '', 1, 2)
               )))
             FROM dba_source c
             WHERE c.owner = a.owner
             AND   c.name = a.object_name
             AND   c.type = a.object_type
             AND   c.line = 2
             AND   c.text like ''%$Header%''
           ) "File Version",
           b.text "Error Text"
    FROM dba_objects a,
         dba_errors b
    WHERE a.object_name = b.name(+)
    AND a.object_type = b.type(+)
    AND a.owner = ''APPS''
    AND (a.object_name like ''IBY%'' OR
         a.object_name like ''AP_%'' )
    AND a.status = ''INVALID''',
   'Payments Related Invalid Objects',
   'RS',
   'There exist invalid Payments/Payables related objects',
   '<ul>
      <li>Recompile the individual objects manually or recompile the
          entire APPS schema with adadmin utility</li>
      <li>Review any error messages provided</li>
   </ul>',
   'No Payments related invalid objects exists in the database',
   'ALWAYS',
   'E');

   
  -------------------------------------------
  -- Example signatures
  -- PSD #11b
  -------------------------------------------

  l_info.delete;
  l_info('Doc ID') := '390023.1'; -- example using l_info
  l_info('Bug Number') := '9707155'; -- example using l_info

  add_signature(
   'Note390023.1_case_GEN1',
   'SELECT count(*)
    FROM (
         SELECT bug_number FROM ad_bugs
         UNION
         SELECT patch_name FROM ad_applied_patches
       ) bugs
    WHERE bugs.bug_number like ''9707155''',
    'Reset Patch Not Applied',
    '[count(*)] = [0]',
    'The patch for resetting a document has not been applied',
    'In order to reset stuck documents you will need to apply {9707155} '||
      'which contains the requires data fix scripts',
    null,
    'FAILURE',
    'W',
    'N',
    'Y',
    l_info);


  l_info.delete;
  add_signature(
   'Note390023.1_case_GEN4',
   'SELECT ''PO/PA'' "Doc Type",
           h.segment1 "Doc Number",
           h.po_header_id "Doc ID",
           h.org_id,
           null "Release Num",
           null "PO Release ID",
           h.type_lookup_code "Type Code",
           h.authorization_status "Athorization Status",
           nvl(h.cancel_flag,''N'') canceled,
           nvl(h.closed_code,''OPEN'') "Closed Code",
           h.change_requested_by "Change Requested By",
           h.revision_num,
           h.wf_item_type, h.wf_item_type "##$$FK1$$##",
           h.wf_item_key, h.wf_item_key "##$$FK2$$##",
           h.approved_date "Approved Date"
    FROM po_headers_all h
    WHERE to_date(''##$$FDATE$$##'') <= (
            SELECT max(ah.action_date) FROM po_action_history ah
            WHERE ah.object_id = h.po_header_id
            AND   ah.object_type_code IN (''PO'',''PA'')
            AND   ah.action_code = ''SUBMIT''
            AND   ah.object_sub_type_code = h.type_lookup_code)
    AND   h.org_id = ##$$ORGID$$##
    AND   h.authorization_status IN (''IN PROCESS'', ''PRE-APPROVED'')
    AND   nvl(h.cancel_flag,''N'') <> ''Y''
    AND   nvl(h.closed_code,''OPEN'') <> ''FINALLY CLOSED''
    AND   nvl(h.change_requested_by,''NONE'') NOT IN (''REQUESTER'',''SUPPLIER'')
    AND   (nvl(h.ENCUMBRANCE_REQUIRED_FLAG, ''N'') <> ''Y'' OR
           h.type_lookup_code <> ''BLANKET'')
    AND   NOT EXISTS (
            SELECT null
            FROM wf_item_activity_statuses ias,
                 wf_notifications n
            WHERE ias.notification_id is not null
            AND   ias.notification_id = n.group_id
            AND   n.status = ''OPEN''
            AND   ias.item_type = ''POAPPRV''
            AND   ias.item_key IN (
                    SELECT i.item_key FROM wf_items i
                    START WITH i.item_type = ''POAPPRV''
                    AND        i.item_key = h.wf_item_key
                    CONNECT BY PRIOR i.item_type = i.parent_item_type
                    AND        PRIOR i.item_key = i.parent_item_key
                    AND     nvl(i.end_date,sysdate+1) >= sysdate))
    ORDER BY 1,2',
   'Recent Documents - Candidates for Reset',
   'RS',
   'Recent documents exist which are candidates for reset.  The documents
    listed are all IN PROCESS or PRE-APPROVED approval status
    and do not have an open workflow notification.',
   '<ul><li>Review the results in the Workflow Activity section
         for the documents.</li>
      <li>If multiple documents are stuck with errors in the same
         workflow activity then try the Mass Retry in [458216.1].</li>
      <li>For all other document see [390023.1] for details on
         how to reset these documents if needed.</li>
      <li>To obtain a summary count for all such documents in your 
         system by document type, refer to [1584264.1]</li></ul>',
   null,
   'FAILURE',
   'W',
   'RS',
   'Y',
   l_info,
   VARCHAR_TBL('Note390023.1_case_GEN4_CHILD1',
     'Note390023.1_case_GEN4_CHILD2'));

    l_info.delete;
    add_signature(
     'Note390023.1_case_GEN4_CHILD1',
     'SELECT DISTINCT
             ac.name Activity,
             ias.activity_result_code Result,
             ias.error_name ERROR_NAME,
             ias.error_message ERROR_MESSAGE,
             ias.error_stack ERROR_STACK
      FROM wf_item_activity_statuses ias,
           wf_process_activities pa,
           wf_activities ac,
           wf_activities ap,
           wf_items i
      WHERE ias.item_type = ''##$$FK1$$##''
      AND   ias.item_key  = ''##$$FK2$$##''
      AND   ias.activity_status     = ''ERROR''
      AND   ias.process_activity    = pa.instance_id
      AND   pa.activity_name        = ac.name
      AND   pa.activity_item_type   = ac.item_type
      AND   i.item_type             = ias.item_type
      AND   i.item_key              = ias.item_key
      AND   i.begin_date            >= ac.begin_date
      AND   i.begin_date            < nvl(ac.end_date, i.begin_date+1)
      AND   (ias.error_name is not null OR
             ias.error_message is not null OR
             ias.error_stack is not null)
      ORDER BY 1,2',
     'WF Activity Errors for This Document',
     'NRS',
     'No errored WF activities found for the document',
     null,
     null,
     'SUCCESS',
     'I',
     'RS');
	 
    -------------------------------------------
    -- End of example signatures
    -------------------------------------------	 
    -- PSD #11b-end


EXCEPTION WHEN OTHERS THEN
  print_log('Error in load_signatures');
  raise;
END load_signatures;





---------------------------------
-- MAIN ENTRY POINT
---------------------------------
-- PSD #12
PROCEDURE main IS

  l_sql_result VARCHAR2(1);
  l_step       VARCHAR2(5);
  l_analyzer_end_time   TIMESTAMP;
  L_COMPLETION_STATUS 	BOOLEAN;

BEGIN

  -- re-initialize values 
  g_sect_no := 1;
  g_sig_id := 0;
  g_item_id := 0;
  
  l_step := '10';
  initialize_files;
 
-- PSD #13
-- Title of analyzer!! - do not add word 'analyzer' at the end as it is appended in code where title is called   
  analyzer_title := 'Concurrent Processing';

  l_step := '20';
  validate_parameters;

  l_step := '30';
  print_rep_title(analyzer_title);

  l_step := '40';
  load_signatures;

  l_step := '50';
  print_toc('Sections In This Report');

  -- Start of Sections and signatures
  l_step := '60';
  print_out('<div id="tabCtrl">');
  -- PSD #14
  -- Start of Sections and signatures
  start_section('E-Business Applications Concurrent Processing Overview');
     show_data_gauge;
		
		if (g_reqid_cnt > 5000) THEN
			set_item_result(run_stored_sig('CONC_REQ1'));
	
		  elsif (g_reqid_cnt > 3500) THEN
			set_item_result(run_stored_sig('CONC_REQ2'));
			
		  else
			set_item_result(run_stored_sig('CONC_REQ3'));
			
		end if;

--	 set_item_result(run_stored_sig('PURGEREQS'));
	 set_item_result(run_stored_sig('PURGELIGIBLE'));
	 set_item_result(run_stored_sig('EBS_VERSION'));
--	 set_item_result(run_stored_sig('TEST_RUN'));
	 
	 set_item_result(run_stored_sig('NODE_INFO'));
	 set_item_result(run_stored_sig('CP_PARAMETERS'));
	 set_item_result(run_stored_sig('CP_ENV'));
	 set_item_result(run_sortable_table('CP_PROFILES'));
	 set_item_result(run_stored_sig('FND_FILE'));
	 set_item_result(check_txk_patches);
	 set_item_result(check_cprec_patches);
	 --set_item_result(run_stored_sig('GSM_ENABLED'));
	 --set_item_result(run_stored_sig('Note390023.1_case_GEN4'));
	 --set_item_result(run_stored_sig('APPLTMP'));
  end_section;
  start_section('E-Business Applications Concurrent Request Analysis');
	 set_item_result(run_stored_sig('LONGRPTS'));
 	 set_item_result(run_stored_sig('ELAPSEDHIST'));
	 set_item_result(run_stored_sig('CURRENTREQS'));
	 set_item_result(run_stored_sig('CONCREQTOTALS'));
	 set_item_result(run_stored_sig('CONCREQS'));
 	 set_item_result(run_stored_sig('PENDREQ'));
	 set_item_result(run_stored_sig('PENDREGSCHDREQ'));
	 set_item_result(run_stored_sig('PENDNONREGSCHDREQ'));
	 set_item_result(run_stored_sig('CNTPENDREQ_OH'));
	 set_item_result(run_stored_sig('CNTPENDREQ_NOH'));
	 set_item_result(run_stored_sig('SCHEDULEDREQ'));
	 set_item_result(run_stored_sig('PENDREQHOLD'));
	 set_item_result(run_stored_sig('SCHEDULEDREQ2'));
	 set_item_result(run_stored_sig('LASTMONDAILY'));
	 set_item_result(run_stored_sig('RUNALONE'));
	 set_item_result(run_stored_sig('TABLESPACES'));
	 set_item_result(run_stored_sig('TABLESPACES2')); 
  end_section;
  start_section('E-Business Applications Concurrent Manager Analysis');
	 set_item_result(run_stored_sig('CPADV1'));
	 set_item_result(run_stored_sig('CPADV3'));
	 set_item_result(run_stored_sig('CPADV4'));
	 set_item_result(run_stored_sig('CPADV5'));
	 set_item_result(run_stored_sig('CPADV11'));
	 set_item_result(run_stored_sig('CPADV12'));
	 set_item_result(run_stored_sig('CPADV17'));
  end_section;
 
  print_out('</div>');

  -- End of report, print TOC
  l_step := '140';
  print_toc_contents;
  
  g_analyzer_elapsed := stop_timer(g_analyzer_start_time);
  get_current_time(l_analyzer_end_time);
  
  print_out('<hr><br><table width="40%"><thead><strong>Performance Data</strong></thead>');
  print_out('<tbody><tr><th>Started at:</th><td>'||to_char(g_analyzer_start_time,'hh24:mi:ss.ff3')||'</td></tr>');
  print_out('<tr><th>Complete at:</th><td>'||to_char(l_analyzer_end_time,'hh24:mi:ss.ff3')||'</td></tr>');
  print_out('<tr><th>Total time:</th><td>'||format_elapsed(g_analyzer_elapsed)||'</td></tr>');
  print_out('</tbody></table>');
  
  print_out('<br><hr>');
  print_out('<strong>Still have questions or suggestions?</strong><br>');
  -- PSD #15
  print_out('<a href="https://community.oracle.com/message/11891559" target="_blank">');
  print_out('<img border="0" src="https://blogs.oracle.com/ebs/resource/Proactive/Feedback_75.gif" title="Click here to provide feedback for this Analyzer">');
  print_out('</a><br><span class="regtext">');
  print_out('Click the button above to ask questions about and/or provide feedback on the ' || analyzer_title ||  ' Analyzer. Share your recommendations for enhancements and help us make this Analyzer even more useful!');  
  print_out('</span>');

  print_hidden_xml;
  
  close_files; 
  
  IF g_is_concurrent THEN
     l_completion_status:=FND_CONCURRENT.SET_COMPLETION_STATUS('NORMAL','');
  END IF;
  
EXCEPTION WHEN others THEN
  g_retcode := 2;
  g_errbuf := 'Error in main at step '||l_step||': '||sqlerrm;
  print_log(g_errbuf);
  
  IF g_is_concurrent THEN
     l_completion_status:=FND_CONCURRENT.SET_COMPLETION_STATUS('ERROR',g_errbuf);
  END IF; 
      
END main;

---------------------------------
-- MAIN ENTRY POINT FOR CONC PROC
-- only needed in the package template
---------------------------------
/*PROCEDURE main_cp IS

l_trx_num VARCHAR2(25);

BEGIN
  g_retcode := 0;
  g_errbuf := null;
  l_trx_num := nvl(p_po_num, p_req_num);
  main;

  retcode := g_retcode;
  errbuf  := g_errbuf;
EXCEPTION WHEN OTHERS THEN
  retcode := '2';
  errbuf := 'Error in main_cp: '||sqlerrm||' : '||g_errbuf;
END main_cp;*/


BEGIN

-- PSD #16
   main;

EXCEPTION WHEN OTHERS THEN
  dbms_output.put_line('Error encountered: '||sqlerrm);
END;
/
exit;