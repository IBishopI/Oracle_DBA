REM
REM   $Header: workflow_analyzer.sql 5.08 2015/04/01 16:47:23 bburbage $
REM   
REM MODIFICATION LOG:
REM	
REM	BBURBAGE 
REM	
REM	Consolidated script to diagnose the current status and footprint of workflow on an environment.
REM     This script can be run on 11.5.x or higher.
REM
REM   workflow_analyzer.sql
REM     
REM   	This script was created to collect all the required information to understand what impact workflow
REM   	embedded in Oracle Applications has on an EBS instance.
REM
REM
REM   How to run it? Follow the directions found in the Master Note 1369938.1
REM   
REM   	sqlplus apps/<password>	@workflow_analyzer.sql
REM
REM   
REM   Output file format found in the same directory if run manually
REM   
REM	wf_analyzer_<HOST_NAME>_<SID>_<DATE>.html
REM
REM
REM     Created: May 16th, 2011
REM     Last Updated: April 1st, 2015
REM
REM
REM  CHANGE HISTORY:
REM   1.00    16-MAY-2011 bburbage 	Creation from design
REM   1.01    04-JUN-2011 bburbage 	Adjustments to include more queries
REM   3.00    11-JUN-2011 bburbage 	Change output to html
REM   3.01    16-JUN-2011 bburbage 	Adding patches, adding more recommendations
REM   3.02    08-JUL-2011 bburbage 	Adding WF_ADMIN_ROLE search and enhancements
REM   3.03    21-JUL-2011 bburbage 	Added Profiles check, and database parameter settings
REM                                	aq_tm_processes and job_queue_processes
REM   3.06    07-JUL-2011 bburbage 	Enhanced Java Mailer to loop thru custom mailer if exist
REM                                	Modified the Concurrent Requests test to include scheduled requests
REM                                	as well as requests that have run.
REM   4.00    19-SEP-2011 bburbage 	Prepare script for initial external release
REM   4.01    06-DEC-2011 bburbage 	Adding Feedback Section
REM                                	Adding Change History
REM   4.02    07-DEC-2011 bburbage 	Corrected some miscellaneous verbage and color coding
REM   4.03    28-DEC-2011 bburbage 	Created table for TOC.
REM                                	Added SQL Script buttons to display queries
REM                                	Added exception logic for no rows found in large historical activities
REM   4.04    12-JAN-2012 bburbage 	Added logic to stabilize Footprint graph code
REM	  			   	Added SYSADMIN User Setup Analysis	
REM   4.05    28-FEB-2012 bburbage 	Miscellaneous syntax corrections
REM   				   	Added Note 1425053.1 on How To schedule WF_Analyzer as Concurrent Request
REM                                	to the script output and to the Note 1369938.1
REM				   	Modified the WF Footprint graph and Runtime Tables
REM				   	Added graph for WF Error Notifications
REM				   	Removed the spool naming format to allow for Concurrent Request Functionality
REM				   	Added spool naming instructions in Note 1369938.1 for running script manually
REM   4.06    21-APR-2012 bburbage 	Miscellaneous syntax corrections
REM           18-JUN-2012 bburbage 	Fine tuned the compile date and time to run calculations
REM   4.07    07-AUG-2012 bburbage 	Added Proactive Services banner and links
REM                                	Fixed EBS version test to handle RAC environments
REM				   	Added elapsed timing calculations to each table output for DBAs peace of mind.
REM				   	Added Concurrent Tier Environment settings for the Java Mailer Section
REM				   	Added feedback and Best Practice for DISABLED notification preferences.
REM				   	Added Order Management specific Section to review setups and known issues
REM				  	Updated the list of 1-Off Workflow Patches
REM		 		   	Added Warning messages on #STUCK activities when found
REM   4.08    20-NOV-2012 bburbage 	Fixed v4.07 logic issue causing ORA-01476: divisor is equal to zero in new OM Section
REM   4.08.1  31-JAN-2013 bburbage 	One-Off to fix OM SQL Performance issue (not mass distributed)
REM   4.08.2  31-JAN-2013 bburbage 	One-Off to fix divide by zero issue in Error Notifications Section (not mass distributed)
REM   4.09    01-FEB-2013 bburbage 	Added HCM Specific workflow section
REM				   	Added miscellaneous verbage for clarification and documentation
REM				   	Added additional Mailer configuration checks and validations
REM				   	Amended recommendations for AQ_TM_PROCESSES and versions affected
REM				   	Updated the list of 1-Off Workflow Patches
REM   4.09.1  25-MAR-2013 bburbage 	Corrected Concurrent Requests that have run to analyze completed requests.
REM   4.09.2  28-MAR-2013 bburbage 	Added reference to Load Balanced instances note 339718.1 when profile WF_MAIL_WEB_AGENT is not set.
REM   4.09.3  24-APR-2013 bburbage 	Fixed the Footprint color legend to match correct columns
REM				   	Modified the WF_ADMIN_ROLE query to only display Valid users with active responsibilities, and added SQL query	
REM				   	Moved the Stuck Activities Anchor up to include the common misconceptions
REM   5.01    30-APR-2013 bburbage 	Added PO Specific workflow section
REM                                	Increased SYSADMIN email address (:admin_email) 40 char limitation to 320 characters
REM                                	Added a hyperlink to the WF Analyzer note 1369938.1 at the top.
REM				   	Fixed a divide by zero scenario in the Large Activity History Table queries 
REM				   	Added Notification Patches for review
REM                                	Added modifications to OM Section as suggested by the OM Team
REM   5.02    01-JUL-2013 bburbage 	Modifications to some table layouts
REM					Updated OM content by OM Dev team.
REM					Updated the General & Recommended 1-Off patches to be validated by component and release
REM					Added a check for R12.2.2 (16207672)
REM					Included feedback checks for Concurrent Requests used by Workflow
REM   5.03    14-OCT-2013 bburbage	Added 30 rows output filter to OM queries that can returned many rows
REM					Updated the Header info so it does not fail during snapshot update
REM					Updated OM query with a HINT to improve performance for OEOL pending workflows for closed order lines
REM   5.04    08-NOV-2013 bburbage  	Fixed a formatting error in the WF Footprint code
REM					Added some validation for DEFAULT_EVENT_ERROR notifications
REM					Added some explanation to the initial WF Runtime Data Age Gauge and added a WF_ITEMS volume chart
REM   5.05    12-DEC-2013 bburbage  	Modified the references to WF Community to use the new MOSC URLs.
REM   5.05.1  10-FEB-2014 bburbage	Removed iframe code for the link to WF Analyzer Feedback Thread and change to open a new window, 
REM                                     as new MOSC uses JIVE platform and does not like iFrames. 
REM					Added multi-column sortable tables to enhance usefulness of detailed data displayed
REM					Added references to Java Mailer Technical Troubleshooting doc and Mailer Setup Test script
REM   5.05.2  25-FEB-2014 bburbage      Modified OM query OEOL pending workflows for closed order lines to use to_number not to_char
REM   5.06    28-FEB-2014 bburbage	Added latest version update link in the title of the output report
REM					Modified the total script elapsed time calculation.  Thank you Simona Stanciu for your collaboration.
REM					Added check for the concurrent program Workflow Work Items Statistics (FNDWFWITSTATCC) last run to avoid confusion
REM					Added link at end of report for all other Proactice Support Analyzers found on Note 1545562.1
REM   5.07    07-APR-2014 bburbage	Redesigned the graph to use javascript to avoid a dbms_output limitation for big data customers
REM					Edited some sections for performance for a customer
REM 					Corrected WF_DEFERRED_TABLE_M_N1 index check (v5.04+). Removing bind variable wfdtmindx=0 used for testing. Thanks Don.
REM    					Updated references to wf_roles view to base table wf_local_roles
REM				 	Modified sort order for Concurrent Request to show most recent completed. Thanks Norman.
REM					Corrected dbms.output syntax for several queries to allow single quotes so queries can be cut-n-pasted. Thanks Norman.
REM					Updated STUCK table output to show only Open items that are #STUCK and when they started
REM					Modified Mailer Loop Check to handle multiple mailers
REM					Updated Warning boxes to be orange like Attention boxes, to match other Analyzer styles.
REM					Corrected syntax error to fix the physical vs logical-space calculated rate.  Thanks Karen
REM					Modified the WF Admin cursor to allow for duplicate role names that have different ORIG_SYSTEMS.  Thanks Ravin.
REM					Updated Recommended and Suggested One-Off patches with latest, and modified R12.2 to use ad_patch.is_patch_applied() method					
REM					Updated all KM Doc links to use a trackable ...DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1... code 
REM                                     for statistics and KM analytics.
REM   5.08    01-APR-2015 bburbage	Fixed a spacing issue causing ERROR: ORA-06502: PL/SQL: numeric or value error: host bind array too small ORA-06512
REM

set arraysize 1
set heading off
set feedback off  
set echo off
set verify off
SET CONCAT ON
SET CONCAT .
SET ESCAPE OFF
SET ESCAPE '\'

set lines 175
set pages 9999
set serveroutput on size 100000

variable st_time 	varchar2(100);
variable et_time 	varchar2(100);

REM Uncomment the SPOOL line below by removing the REM tag at the beginning of that line
REM to automatically spool the output report to a meaningful name.

COLUMN host_name NOPRINT NEW_VALUE hostname
SELECT host_name from v$instance;
COLUMN instance_name NOPRINT NEW_VALUE instancename
SELECT instance_name from v$instance;
COLUMN sysdate NOPRINT NEW_VALUE when
select to_char(sysdate, 'YYYY-Mon-DD') "sysdate" from dual;
REM SPOOL wf_analyzer_&&hostname._&&instancename._&&when..html

VARIABLE TEST			VARCHAR2(240);
VARIABLE WFCMTPHY		NUMBER;
VARIABLE WFDIGPHY		NUMBER;
VARIABLE WFITMPHY		NUMBER;
VARIABLE WIASPHY		NUMBER;
VARIABLE WIASHPHY		NUMBER;
VARIABLE WFATTRPHY		NUMBER;
VARIABLE WFNTFPHY		NUMBER;
VARIABLE WFCMTPHY2		NUMBER;
VARIABLE WFDIGPHY2		NUMBER;
VARIABLE WFITMPHY2		NUMBER;
VARIABLE WIASPHY2		NUMBER;
VARIABLE WIASHPHY2		NUMBER;
VARIABLE WFATTRPHY2		NUMBER;
VARIABLE WFNTFPHY2		NUMBER;
VARIABLE ERRORNTFCNT    	NUMBER;
VARIABLE NTFERR_CNT		NUMBER;
VARIABLE ECXERR_CNT		NUMBER;
VARIABLE OMERR_CNT		NUMBER;
VARIABLE POERR_CNT		NUMBER;
VARIABLE WFERR_CNT		NUMBER;
VARIABLE ECXRATE		NUMBER;
VARIABLE OMRATE			NUMBER;
VARIABLE PORATE			NUMBER;
VARIABLE WFRATE			NUMBER;
VARIABLE ADMIN_EMAIL    	VARCHAR2(320);
VARIABLE NTF_PREF       	VARCHAR2(10);
VARIABLE GSM			VARCHAR2(240);
VARIABLE WF_ADMIN_ROLE		VARCHAR2(2000);
VARIABLE ITEM_CNT    		NUMBER;
VARIABLE ITEM_OPEN   		NUMBER;
VARIABLE OLDEST_ITEM 		NUMBER;
VARIABLE SID         		VARCHAR2(16);
VARIABLE HOST        		VARCHAR2(64);
VARIABLE APPS_REL    		VARCHAR2(50);
VARIABLE WF_ADMIN_DISPLAY 	VARCHAR2(360);
VARIABLE EMAIL       		VARCHAR2(320);
VARIABLE EMAIL_OVERRIDE		VARCHAR2(1996);
VARIABLE NTF_PREF    		VARCHAR2(8);
VARIABLE MAILER_ENABLED		VARCHAR2(8);
VARIABLE MAILER_STATUS		VARCHAR2(30);
VARIABLE CORRID    		VARCHAR2(240);
VARIABLE COMPONENT_NAME 	VARCHAR2(80);
VARIABLE CONTAINER_NAME 	VARCHAR2(240);
VARIABLE STARTUP_MODE   	VARCHAR2(30);
VARIABLE TOTAL_ERROR  		NUMBER;
VARIABLE OPEN_ERROR   		NUMBER;
VARIABLE CLOSED_ERROR 		NUMBER;
VARIABLE LOGICAL_TOTALS 	VARCHAR2(22);
VARIABLE PHYSICAL_TOTALS 	VARCHAR2(22);
VARIABLE DIFF_TOTALS    	VARCHAR2(22);
VARIABLE NINETY_TOTALS		VARCHAR2(22);
VARIABLE RATE			NUMBER;
VARIABLE NINETY_CNT		NUMBER;
VARIABLE HIST_CNT		NUMBER;
VARIABLE HIST_DAYS		NUMBER;
VARIABLE HIST_DAILY		NUMBER;
VARIABLE MAILER_CNT		NUMBER;
VARIABLE HIST_END		VARCHAR2(22);
VARIABLE HIST_BEGIN		VARCHAR2(22);
VARIABLE SYSDATE		VARCHAR2(22);
VARIABLE HIST_RECENT		VARCHAR2(22);
VARIABLE HASROWS		NUMBER;
VARIABLE HIST_ITEM		VARCHAR2(8);
VARIABLE HIST_KEY		VARCHAR2(240);
VARIABLE WFADMIN_NAME		VARCHAR2(320);
VARIABLE WFADMIN_DISPLAY_NAME	VARCHAR2(360);
VARIABLE WFADMIN_ORIG_SYSTEM	VARCHAR2(30);
VARIABLE WFADMIN_STATUS 	VARCHAR2(8);
VARIABLE WF_ADMINS_CNT  	NUMBER; 
VARIABLE QMON			VARCHAR2(512);
VARIABLE DB_VER    		VARCHAR2(17);
VARIABLE OMCNT			NUMBER;
VARIABLE OLCNT			NUMBER;
VARIABLE OPENOMCNT		NUMBER;
VARIABLE CLOSEDOMCNT		NUMBER;
VARIABLE OMPRGCNT		NUMBER;
VARIABLE ORPHHDR		NUMBER;	
VARIABLE ORPHLINE		NUMBER;	
VARIABLE RUN_OM_QRY     	VARCHAR2(2);
VARIABLE n			NUMBER;
VARIABLE g			NUMBER;
VARIABLE user_cnt_disabled 	NUMBER;
VARIABLE CHART_OM_CNT		NUMBER;
VARIABLE OEOH_CNT		NUMBER;
VARIABLE OEOL_CNT		NUMBER;
VARIABLE OMERROR_CNT		NUMBER;
VARIABLE OEOI_CNT		NUMBER;
VARIABLE OECOGS_CNT		NUMBER;
VARIABLE OEOA_CNT		NUMBER;
VARIABLE OECHG_CNT		NUMBER;
VARIABLE OEWFERR_CNT		NUMBER;
VARIABLE OEON_CNT		NUMBER;
VARIABLE OEBH_CNT		NUMBER;
VARIABLE OEOHRATE		NUMBER;
VARIABLE OEOLRATE		NUMBER;
VARIABLE OMERRORRATE		NUMBER;
VARIABLE OEOIRATE		NUMBER;
VARIABLE OECOGSRATE		NUMBER;
VARIABLE OEOARATE		NUMBER;
VARIABLE OECHGRATE		NUMBER;
VARIABLE OEWFERRRATE		NUMBER;
VARIABLE OEONRATE		NUMBER;
VARIABLE OEBHRATE		NUMBER;
VARIABLE STUCK_CNT		NUMBER;
VARIABLE RUN_HCM_QRY		VARCHAR2(2);
VARIABLE hrcnt			NUMBER;
VARIABLE c14			NUMBER;
VARIABLE chart_hr		NUMBER;
VARIABLE ohrcnt 		NUMBER;
VARIABLE chrcnt 		NUMBER;
VARIABLE c1			NUMBER;
VARIABLE c2			NUMBER;
VARIABLE c3			NUMBER;
VARIABLE c4			NUMBER;
VARIABLE c5			NUMBER;
VARIABLE c6			NUMBER;
VARIABLE c7			NUMBER;
VARIABLE c8			NUMBER;
VARIABLE c9			NUMBER;
VARIABLE c10			NUMBER;
VARIABLE hr_cnt			NUMBER;
VARIABLE c11			NUMBER;
VARIABLE c12			NUMBER;
VARIABLE c13			NUMBER;
VARIABLE c14			NUMBER;
VARIABLE c15			NUMBER;
VARIABLE c16			NUMBER;
VARIABLE c17			NUMBER;
VARIABLE c18			NUMBER;
VARIABLE c19			NUMBER;
VARIABLE c20			NUMBER;
VARIABLE po_cnt			NUMBER;
VARIABLE c21			NUMBER;
VARIABLE c22			NUMBER;
VARIABLE c23			NUMBER;
VARIABLE r1			NUMBER;
VARIABLE r2			NUMBER;
VARIABLE r3			NUMBER;
VARIABLE r4			NUMBER;
VARIABLE r5			NUMBER;
VARIABLE r6			NUMBER;
VARIABLE r7			NUMBER;
VARIABLE r8			NUMBER;
VARIABLE r9			NUMBER;
VARIABLE r10			NUMBER;
VARIABLE hrsrate		NUMBER;
VARIABLE r11			NUMBER;
VARIABLE r12			NUMBER;
VARIABLE r13			NUMBER;
VARIABLE r14			NUMBER;
VARIABLE r15			NUMBER;
VARIABLE r16			NUMBER;
VARIABLE r17			NUMBER;
VARIABLE r18			NUMBER;
VARIABLE r19			NUMBER;
VARIABLE r20			NUMBER;
VARIABLE poerrate		NUMBER;
VARIABLE r21			NUMBER;
VARIABLE r22			NUMBER;
VARIABLE r23			NUMBER;
VARIABLE RUN_PO_QRY		VARCHAR2(2);
VARIABLE chart_po		NUMBER;
VARIABLE opocnt 		NUMBER;
VARIABLE cpocnt 		NUMBER;
VARIABLE incomplreq     	NUMBER;
VARIABLE incomplpo		NUMBER;
VARIABLE expunge		varchar2(1996);
VARIABLE rup			varchar2(320);
VARIABLE ptch1			varchar2(52);
VARIABLE ptch2			varchar2(52);
VARIABLE ptch3			varchar2(52);
VARIABLE ptch4			varchar2(52);
VARIABLE ptch5			varchar2(52);
VARIABLE ptch6			varchar2(52);
VARIABLE ptch7			varchar2(52);
VARIABLE ptch8			varchar2(52);
VARIABLE ptch9			varchar2(52);
VARIABLE ptch10			varchar2(52);
VARIABLE ptch11			varchar2(52);
VARIABLE ptch12			varchar2(52);
VARIABLE ptch13			varchar2(52);
VARIABLE ptch14			varchar2(52);
VARIABLE ptch15			varchar2(52);
VARIABLE ptch16			varchar2(52);
VARIABLE ptch17			varchar2(52);
VARIABLE ptch18			varchar2(52);
VARIABLE ptch19			varchar2(52);
VARIABLE ptch20			varchar2(52);
VARIABLE ptch21			varchar2(52);
VARIABLE ptch22			varchar2(52);
VARIABLE ptch23			varchar2(52);
VARIABLE ptch24			varchar2(52);
VARIABLE ptch25			varchar2(52);
VARIABLE ptchcnt		varchar2(52);
VARIABLE ATGRUP4		number;
VARIABLE mlr_runs		number;
VARIABLE alldefrd		number;
VARIABLE stuckfreq		number;
VARIABLE prgall			number;
VARIABLE prgcore		number;
VARIABLE dee_clsd_cnt		number;
VARIABLE dee_open_cnt		number;
VARIABLE dee_open30_cnt		number;
VARIABLE beginmin		number;
VARIABLE beginmax 		number;
VARIABLE maxitems		number;
VARIABLE cls_cnt		number;
VARIABLE wfdtmIndx		number;
VARIABLE LAST_RAN		VARCHAR2(22);

declare

	test			varchar2(240);
	wfcmtphy		number;
	wfdigphy		number;
	wfitmphy		number;
	wiasphy			number;
	wiashphy		number;
	wfattrphy		number;
	wfntfphy		number;
	wfcmtphy2		number;
	wfdigphy2		number;
	wfitmphy2		number;
	wiasphy2		number;
	wiashphy2		number;
	wfattrphy2		number;
	wfntfphy2		number;
	errorntfcnt		number;
	ntferr_cnt		number;
	ecxerr_cnt		number;	
	omerr_cnt		number;	
	poerr_cnt		number;	
	wferr_cnt		number;	
	ecxrate			number;	
	omrate			number;	
	porate			number;	
	wfrate			number;
	admin_email         	varchar2(320);
        ntf_pref        	varchar2(10);
	gsm         		varchar2(240);
	item_cnt    		number;
	item_open   		number;
	oldest_item 		number;
	sid         		varchar2(16);
	host        		varchar2(64);
	apps_rel    		varchar2(50);
	wf_admin_display 	varchar2(360);
	email       		varchar2(320);
	email_override 		varchar2(1996);	
	ntf_pref    		varchar2(8);
	mailer_enabled 		varchar2(8);
	mailer_status 		varchar2(30);
	corrid	 		varchar2(240);
	component_name  	varchar2(80);
	container_name  	varchar2(240);
	startup_mode    	varchar2(30);
	total_error  		number;
	open_error   		number;
	closed_error 		number;
	wf_admin_role 		varchar2(2000);
    logical_totals		varchar2(22);
    physical_totals 		varchar2(22);
    diff_totals 		varchar2(22);
    ninety_totals 		varchar2(22);
	rate			number;
	ninety_cnt		number;
	hist_cnt   		number;
	hist_days 		number;
	hist_daily		number;
	mailer_cnt		number;
	hist_end		varchar2(22);
	hist_begin		varchar2(22);
	hist_recent		varchar2(22);
	sysdate			varchar2(22);
	hasrows			number;
	hist_item      		varchar2(8);
	hist_key       		varchar2(240);
	wf_admins_cnt		number;
	wfadmin_name		varchar2(320);                                                                                                     
	wfadmin_display_name	varchar2(360);                                                                                           
	wfadmin_orig_system	varchar2(30);
	wfadmin_status		varchar2(8);
	qmon			varchar2(512);
	mycheck			number;
	db_ver			varchar2(17); 
	omcnt 			number;
	olcnt 			number;	
	omprgcnt 		number;
	orphhdr			number;
	orphline		number;
	n 			number;	
	g			number;
	openomcnt 		number;
	closedomcnt 		number;
	user_cnt_disabled	number;
	chart_om_cnt		number;
	oeoh_cnt		number;
	oeol_cnt		number;
	omerror_cnt		number;
	oeoi_cnt		number;
	oecogs_cnt		number;
	oeoa_cnt		number;
	oechg_cnt		number;
	oewferr_cnt		number;
	oeon_cnt		number;
	oebh_cnt		number;	
	oeohrate		number;
	oeolrate		number;
	omerrorrate		number;
	oeoirate		number;
	oecogsrate		number;
	oeoarate		number;
	oechgrate		number;
	oewferrrate		number;
	oeonrate		number;
	oebhrate		number;		
	stuck_cnt		number;
	user_cnt_disabled	number;
	chart_hr		number;
	c14			number;
	ohrcnt 			number;
	chrcnt 			number;
	c1			number;
	c2			number;
	c3			number;
	c4			number;
	c5			number;
	c6			number;
	c7			number;
	c8			number;
	c9			number;
	c10			number;
	hr_cnt			number;
	c11			number;
	c12			number;
	c13			number;
	c14			number;
	c15			number;
	c16			number;
	c17			number;
	c18			number;
	c19			number;
	c20			number;
	po_cnt			number;
	c21			number;
	c22			number;
	c23			number;
	r1			number;
	r2			number;
	r3			number;
	r4			number;
	r5			number;
	r6			number;
	r7			number;
	r8			number;
	r9			number;
	r10			number;
	hrsrate			number;
	r11			number;
	r12			number;
	r13			number;
	r14			number;
	r15			number;
	r16			number;
	r17			number;
	r18			number;
	r19			number;
	r20			number;
	poerrate		number;
	r21			number;	
	r22			number;
	r23			number;
	incomplreq  		number;
	incomplpo   		number;
	expunge			varchar2(1996);
	rup			varchar2(320);
	ptch1			varchar2(52);
	ptch2			varchar2(52);
	ptch3			varchar2(52);
	ptch4			varchar2(52);
	ptch5			varchar2(52);
	ptch6			varchar2(52);	
	ptch7			varchar2(52);
	ptch8			varchar2(52);
	ptch9			varchar2(52);
	ptch10			varchar2(52);
	ptch11			varchar2(52);
	ptch12			varchar2(52);
 	ptch13			varchar2(52);
	ptch14			varchar2(52);
 	ptch15			varchar2(52); 
 	ptch16			varchar2(52);
 	ptch17			varchar2(52);
 	ptch18			varchar2(52);
 	ptch19			varchar2(52);
 	ptch20			varchar2(52);
 	ptch21			varchar2(52);
 	ptch22			varchar2(52);
 	ptch23			varchar2(52);
 	ptch24			varchar2(52);
 	ptch25			varchar2(52); 	
	ptchcnt			varchar2(52);
	ATGRUP4			number;	
	mlr_runs		number;
	alldefrd		number;
	stuckfreq		number;
	prgall			number;
	prgcore			number;	
	dee_clsd_cnt		number;
	dee_open_cnt		number;
	dee_open30_cnt		number;
	beginmin		number;
	beginmax 		number;
	maxitems		number;
	cls_cnt			number;
	wfdtmIndx		number;
	last_ran		varchar2(22);
	
begin
  select wf_core.translate('WF_ADMIN_ROLE') into :wf_admin_role from dual; 
end;
/

alter session set NLS_DATE_FORMAT = 'DD-MON-YYYY HH24:MI:SS';

begin
  select to_char(sysdate,'hh24:mi:ss') into :st_time from dual;
end;
/

exec :g := dbms_utility.get_time;

prompt <!DOCTYPE html>
prompt <html>
prompt <head>
prompt     <style>html { font-size: 12px; font-family: Arial, Helvetica, sans-serif; }</style>
prompt     <title>Workflow Analyzer</title>
prompt    <link rel="stylesheet" href="http://cdn.kendostatic.com/2014.3.1316/styles/kendo.common.min.css" />
prompt     <link rel="stylesheet" href="http://cdn.kendostatic.com/2014.3.1316/styles/kendo.default.min.css" />
prompt     <link rel="stylesheet" href="http://cdn.kendostatic.com/2014.3.1316/styles/kendo.dataviz.min.css" />
prompt     <link rel="stylesheet" href="http://cdn.kendostatic.com/2014.3.1316/styles/kendo.dataviz.default.min.css" />
prompt 
prompt     <script src="http://cdn.kendostatic.com/2014.3.1316/js/jquery.min.js"></script>
prompt     <script src="http://cdn.kendostatic.com/2014.3.1316/js/kendo.all.min.js"></script>
prompt 	<script type="text/javascript" src="http://cdnjs.cloudflare.com/ajax/libs/jquery.tablesorter/2.9.1/jquery.tablesorter.min.js"></script>
prompt 
prompt     <style>
prompt       body { font-size: 14px; font-family: Arial, Helvetica, sans-serif; }
prompt       #container {
prompt         width: 990px;
prompt       }
prompt 
prompt       span.doc { color: green; font-weight: bold; }
REM prompt       a { color: black; }
REM prompt       a:visited { color: gray; }
prompt       .example { float: left; }
prompt       h2 { clear: both; }
prompt 
prompt       .guage    .graph-header { width: 400px; }
prompt       .runtime  .graph-header { width: 500px; }
prompt
prompt       .runtime { margin-left: 20px; }
prompt       li { margin-bottom: 3px; }
prompt     </style>
prompt </HEAD>
prompt <BODY>

prompt <TABLE border="1" cellspacing="0" cellpadding="10">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF"><TD bordercolor="#DEE6EF"><font face="Calibri">
prompt <B><font size="+2">Workflow Analyzer for 
select UPPER(instance_name) from v$instance;
prompt <B><font size="+2"> on 
select UPPER(host_name) from v$instance;
prompt </font></B></TD></TR>
prompt </TABLE><BR>

prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=432.1" target="_blank">
prompt <img src="https://blogs.oracle.com/ebs/resource/Proactive/banner4.jpg" title="Click here to see other helpful Oracle Proactive Tools" width="758" height="81" border="0" alt="Proactive Services Banner" /></a>
prompt <br>

prompt <font size="-1"><i><b>Workflow_Analyzer.sql v5.08 compiled on : 
select to_char(sysdate, 'Dy Month DD, YYYY') from dual;
prompt at 
select to_char(sysdate, ' hh24:mi:ss') from dual;
prompt </b></i></font>. <BR> The latest version is 
prompt <a href="https://support.oracle.com/oip/faces/secure/km/DownloadAttachment.jspx?attachid=1369938.1:SCRIPT">
prompt <img src="https://blogs.oracle.com/ebs/resource/Proactive/wfa_latest_version.gif" title="Click here to download the latest version of Workflow Analyzer" alt="Latest Version Icon" /></a>
prompt <BR><BR>

prompt This Workflow Analyzer script (<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1369938.1" target="_blank">Note 1369938.1
prompt </a>) reviews the current Workflow Footprint, analyzes runtime tables, profiles, settings, 
prompt and configurations for the overall workflow environment, providing helpful feedback and recommendations on Workflow Best Practices for any areas for concern on this instance (
select UPPER(instance_name) from v$instance;
prompt ).<BR>

prompt ________________________________________________________________________________________________<BR>

prompt <table width="95%" border="0">
prompt   <tr> 
prompt     <td colspan="2" height="46"> 
prompt       <p><a name="top"><b><font size="+2">Table of Contents</font></b></a> </p>
prompt     </td>
prompt   </tr>
prompt   <tr> 
prompt     <td width="50%"> 
prompt       <p><a href="#section1"><b><font size="+1">Workflow Analyzer Overview</font></b></a> 
prompt         <br>
prompt       <blockquote> <a href="#wfadv111"> - E-Business Suite Version</a><br>
prompt         <a href="#fndnodes"> - Instance Node Details</a><br>
prompt         <a href="#wfadv112"> - Workflow Database Parameter Settings</a></blockquote>
prompt       <a href="#section2"><b><font size="+1">Workflow Administration</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#wfadv121"> - Verify the Workflow Administrator Role</a><br>
prompt         <a href="#sysadmin"> - SYSADMIN User Setup for Error Notifications</a><br>
prompt         <a href="#wferror"> - Workflow Error Notifications Summary Status</a><br>
prompt         <a href="#wfadv124"> - Workflow Error Notification Messages Summary Status</a><br>
prompt         <a href="#wfadv122"> - SYSADMIN WorkList Access</a><br>
prompt         <a href="#wfrouting"> - SYSADMIN Notification Routing Rules</a><br>
prompt         <a href="#ebsprofile"> - E-Business Suite Profile Settings</a><br>
prompt         <a href="#wfprofile"> - Workflow Profile Settings</a><br>
prompt         <a href="#wfstuck"> - Verify #STUCK Activities</a><br>
prompt         <a href="#wfadv125"> - Totals for Notification Preferences</a><br>
prompt         <a href="#wfadv126"> - Check the Status of Workflow Services</a><br>
prompt       </blockquote>
prompt       <a href="#section3"><b><font size="+1">Workflow Footprint</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#section3"> - Volume of Workflow Runtime Data Tables</a><br>
prompt         <a href="#wfadv132"> - Verify Closed and Purgeable TEMP Items</a><br>
prompt         <a href="#wfsummry"> - Summary Of Workflow Processes By Item Type</a><br>
prompt         <a href="#wfadv133"> - Check the Volume of Open and Closed Items Annually</a><br>
prompt         <a href="#wfadv134"> - Average Volume of Opened Items in the past 6 Months, 
prompt         Monthly, and Daily</a><br>
prompt         <a href="#wfadv135"> - Total OPEN Items Started Over 90 Days Ago</a><br>
prompt         <a href="#wfadv136"> - Check Top 30 Large Item Activity Status History 
prompt         Items</a></blockquote>
prompt     </td>
prompt     <td width="50%"><a href="#section4"><b><font size="+1">Workflow Concurrent 
prompt       Programs</font></b></a> <br>
prompt       <blockquote> <a href="#wfadv141"> - Verify Concurrent Programs Scheduled 
prompt         to Run</a><br>
prompt         <a href="#wfadv142"> - Verify Workflow Background Processes that ran</a><br>
prompt         <a href="#wfadv143"> - Verify Status of the Workflow Background Engine 
prompt         Deferred Queue Table</a><br>
prompt         <a href="#wfadv144"> - Verify Workflow Purge Concurrent Programs</a><br>
prompt         <a href="#wfadv145"> - Verify Workflow Control Queue Cleanup Programs</a></blockquote>
prompt       <a href="#section5"><b><font size="+1">Workflow Notification Mailer</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#wfmlrptch"> - Known 1-OFF Java Mailer Patches on top of ATG Rollups</a><br>
prompt         <a href="#wfadv150"> - Check the status of the Workflow Services</a><br>
prompt         <a href="#wfadv151"> - Check the Concurrent Tier Environment Settings for the Java Mailer</a><br>
prompt         <a href="#wfadv123"> - Verify AutoClose_FYI Setting</a><br>
prompt         <a href="#wfadv152"> - Check the status of the Workflow Notification Mailer(s)</a><br>
prompt         <a href="#wfadv153"> - Check Status of WF_NOTIFICATIONS Table</a><br>
prompt         <a href="#wfadv154"> - Check Status of WF_NOTIFICATION_OUT Table</a><br>
prompt         <a href="#wfadv155"> - Check for Orphaned Notifications</a></blockquote>
prompt       <a href="#section6"><b><font size="+1">Workflow Patch Levels</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#section6"> - Applied ATG Patches</a><br>
prompt         <a href="#atgrups"> - Known 1-Off Patches on top of ATG Rollups</a><br>
prompt         <a href="#wfadv162"> - Verify Status of Workflow Log Levels</a><br>
prompt         <a href="#wfadv163"> - Verify Workflow Services Log Locations</a><br>
prompt       </blockquote>
prompt       <a href="#section7"><b><font size="+1">Product Specific Workflows</font></b></a> 
prompt       <br>
prompt       <blockquote> <a href="#wfprdont"> - ONT - Order Management</a><br>
prompt         <a href="#wfprdhcm"> - HCM - HRMS Human Resources</a><br>
prompt         <a href="#wfprdpo"> - PO - Purchasing</a><br>
prompt         <a href="#wfprdinv"> - INV - Inventory</a><i>(coming soon)</i><br>
prompt         <a href="#wfprdpa"> - PA - Payables</a><i>(coming soon)</i><br>
prompt       </blockquote>
prompt       <a href="#section8"><b><font size="+1">References</font></b></a><br><br> 
prompt       <a href="#section9"><b><font size="+1">Feedback</font></b></a> 
prompt       <blockquote></blockquote>
prompt     </td>
prompt   </tr>
prompt </table>

prompt ________________________________________________________________________________________________<BR><BR>


REM **************************************************************************************** 
REM *******                   Section 1 : Workflow Analyzer Overview                 *******
REM ****************************************************************************************

prompt <a name="section1"></a><B><font size="+2">Workflow Analyzer Overview</font></B><BR><BR>
prompt <blockquote>

declare 

	clsd_index	number;
	open_index	number;
	year_index	number;
	emesg           VARCHAR2(250);
	
begin

select upper(instance_name) into :sid from v$instance;

select host_name into :host from v$instance;

select release_name into :apps_rel from fnd_product_groups;

select min(to_char(begin_date, 'YYYY')) into :beginmin
from wf_items;

select max(to_char(sysdate, 'YYYY')) into :beginmax
from wf_items;

clsd_index := :beginmin;

Select max(nvl(Count(Item_Key),0)) into :maxitems
From Wf_Items
Group By To_Char(Begin_Date, 'YYYY')
order by To_Char(Begin_Date, 'YYYY');

select e.status into :mailer_enabled
from wf_events e, WF_EVENT_SUBSCRIPTIONS s
where  e.GUID=s.EVENT_FILTER_GUID
and s.DESCRIPTION like '%WF_NOTIFICATION_OUT%'
and e.name = 'oracle.apps.wf.notification.send.group';

select count(notification_id) into :total_error
from WF_NOTIFICATIONS
where message_type like '%ERROR%';

select count(notification_id) into :open_error
from WF_NOTIFICATIONS
where message_type like '%ERROR%'
and end_date is null;

select count(notification_id) into :closed_error
from WF_NOTIFICATIONS
where message_type like '%ERROR%'
and end_date is not null;

select count(item_key) into :item_cnt from wf_items;

select count(item_key) into :item_open from wf_items where end_date is null;

select round(sysdate-(min(begin_date)),0) into :oldest_item from wf_items;

dbms_output.put_line('<script>');
dbms_output.put_line('function createChart() {$("#chart").kendoChart({');
dbms_output.put_line('legend: {position: "top",visible: true},');
dbms_output.put_line('seriesDefaults: {type: "column",stack: true},');
dbms_output.put_line('series: [{name: "Closed",');
dbms_output.put_line('data: [');

WHILE clsd_index <= :beginmax
LOOP
   BEGIN
      /* Loop thru the CLOSED items by year */

	select nvl(count(item_key),0) into :cls_cnt
	from wf_items
	where to_char(begin_date,'YYYY')=clsd_index
	and end_date is not null;

      dbms_output.put(:cls_cnt);
      
      if (clsd_index = :beginmax) then
      	dbms_output.put('],');
      else 
      	dbms_output.put(',');
      end if;
      
      clsd_index:=clsd_index+ 1;
      
   EXCEPTION
      WHEN OTHERS
      THEN
         clsd_index:=clsd_index+ 1;
   END;
END LOOP;

dbms_output.put_line('color: "#4D89F9"}, {name: "Open",data: [');

open_index := :beginmin;

WHILE open_index <= :beginmax
LOOP
   BEGIN
      /* Loop thru the OPEN items by year */

	select nvl(count(item_key),0) into :cls_cnt
	from wf_items
	where to_char(begin_date,'YYYY')=open_index
	and end_date is null;

      dbms_output.put(:cls_cnt);
      
      if (open_index=:beginmax) then
      	exit;
      else 
      	dbms_output.put(',');
      end if;
      
      open_index:=open_index+ 1;
      
   EXCEPTION
      WHEN OTHERS
      THEN
         open_index:=open_index+ 1;
   END;
END LOOP;



dbms_output.put_line('],color: "#C6D9FD"}],valueAxis: {max: '||:maxitems||',');
dbms_output.put_line('labels: {format: "{0}"},');
dbms_output.put_line('line: {visible: false},');
dbms_output.put_line('minorGridLines: {visible: true}},');
dbms_output.put_line('categoryAxis: {categories: [');

year_index := :beginmin;

WHILE year_index <= :beginmax
LOOP
   BEGIN
      /* Build the labels by year */

      dbms_output.put(year_index);
      
      if (year_index=:beginmax) then
      	exit;
      else 
      	dbms_output.put(',');
      end if;
      
      year_index:=year_index+ 1;
      
   EXCEPTION
      WHEN OTHERS
      THEN
         year_index:=year_index+ 1;
   END;
END LOOP;

dbms_output.put_line('],majorGridLines: {visible: false}},');
dbms_output.put_line('tooltip: {visible: true,template: "#= series.name #: #= value #"}});}');
dbms_output.put_line('$(document).ready(createChart);$(document).bind("kendo:skinChange", createChart);');
dbms_output.put_line('</script>');


dbms_output.put_line('<div id="container">');
dbms_output.put_line('<div class="example runtime">');
dbms_output.put_line('<div class="graph-header" align="center">');
dbms_output.put_line('<h3>Workflow Runtime Data Volume</h3>');
dbms_output.put_line('<div id="chart" style="width: 500px; height: 250px;"></div></div></div>');

dbms_output.put_line('<div class="example guage">');
dbms_output.put_line('<div class="graph-header" align="center">');
dbms_output.put_line('<h3>Workflow Runtime Data Age Guage</h3>');
dbms_output.put_line('<div id="guage-graph" class="graph" style="width: 400px; height: 240px;">');

if (:oldest_item > 1095) THEN

  dbms_output.put_line('<img src="');
  dbms_output.put('https://chart.googleapis.com/chart?chxl=0:|critical|bad|good');
  dbms_output.put_line('\&chts=000000,20,c\&chxt=y\&chs=400x200\&cht=gm\&chd=t:10\&chl=Excessive">');
  dbms_output.put_line('</div></div></div></div>');
  dbms_output.put_line('<br>_____________________________________________________________________________________________________________________<br><br>');
  
    dbms_output.put_line('<table border="1" name="RedBox" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('      <p><font size="+2">The overall Volume of Workflow Runtime Data is in need of Immediate Review!</font><BR> ');
    dbms_output.put_line('        The WF_ITEMS Table has obsolete workflow runtime data that is older than 3 years.<BR>');
    dbms_output.put_line('        This Gauge is merely a simple indicator about age and volume of Workflow runtime data on '||:sid||'. <br>');
    dbms_output.put_line('It checks the oldest workflow on this instance, and displays GREEN if less than 1 year old, ORANGE if less than 3, and RED if older than 3 years.<br>');
    dbms_output.put_line('Clean up your old Workflow Runtime Data and move the needle to green.   See below for more details.<BR></p>');
    dbms_output.put_line('      </td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');
    
  else   if (:oldest_item > 365) THEN

  dbms_output.put_line('<img src="');
  dbms_output.put('https://chart.googleapis.com/chart?chxl=0:|critical|bad|good');
  dbms_output.put_line('\&chts=000000,20,c\&chxt=y\&chs=400x200\&cht=gm\&chd=t:50\&chl=Poor">');
  dbms_output.put_line('</div></div></div>');
  dbms_output.put_line('<br>_____________________________________________________________________________________________________________________<br><br>');
 
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('      <p><font size="+2">The overall Volume of Workflow Runtime Data is in need of Review!</font><BR> ');
    dbms_output.put_line('        The WF_ITEMS Table has obsolete workflow runtime data that is older than 1 year but less than 3 years.<BR>');
    dbms_output.put_line('        This Gauge is merely a simple indicator about age and volume of Workflow runtime data on '||:sid||'. <br>');
    dbms_output.put_line('It checks the oldest workflow on this instance, and displays GREEN if less than 1 year old, ORANGE if less than 3, and RED if older than 3 years.<br>');
    dbms_output.put_line('Clean up your old Workflow Runtime Data and move the needle to green.   See below for more details.<BR></p>');
    dbms_output.put_line('      </td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');
    
  else

  dbms_output.put_line('<img src="');
  dbms_output.put('https://chart.googleapis.com/chart?chxl=0:|critical|bad|good');
  dbms_output.put_line('\&chts=000000,20,c\&chxt=y\&chs=400x200\&cht=gm\&chd=t:90\&chl=Healthy">');
  dbms_output.put_line('</div></div></div>');
  dbms_output.put_line('<br>_____________________________________________________________________________________________________________________<br><br>');

    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('      <p><font size="+2">The overall Volume of Workflow Runtime Data is Healthy!</font><BR> ');
    dbms_output.put_line('        The WF_ITEMS Table has workflow runtime data that is less than 1 year old.<BR><BR></p>');
    dbms_output.put_line('        This Gauge is merely a simple indicator about age and volume of Workflow runtime data on '||:sid||'.  Good Work!<BR>');  
    dbms_output.put_line('It checks the oldest workflow on this instance, and displays GREEN if less than 1 year old, ORANGE if less than 3, and RED if older than 3 years.<br>');
    dbms_output.put_line('Clean up your old Workflow Runtime Data and move the needle to green.   See below for more details.<BR></p>');
    dbms_output.put_line('      </td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');
    
  end if;
end if;


    
  if (:item_cnt > 100) THEN
   
    dbms_output.put_line('We reviewed all ' || to_char(:item_cnt,'999,999,999,999') || ' rows in WF_ITEMS Table for Oracle Applications Release ' || :apps_rel || ' instance called ' || :sid || ' on ' || :host || '<BR>');
    dbms_output.put_line('Currently ' || (round(:item_open/:item_cnt, 2)*100) || '% (' || to_char(:item_open,'999,999,999,999') || ') of WF_ITEMS ');
    dbms_output.put_line('are OPEN, while ' || (round((:item_cnt-:item_open)/:item_cnt, 2)*100) || '% (' || to_char((:item_cnt-:item_open),'999,999,999,999') || ') are CLOSED items but still exist in the runtime tables.<BR><BR>');

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note:</B> Once a Workflow is closed, all the transactional or runtime data that is stored in Workflow Runtime Tables (WF_*) becomes obsolete.<BR>');
    dbms_output.put_line('All the pertinent data is stored in the functional tables (FND_*, PO_*, AP_*, HR_*, OE_*, etc), like who approved what, for how much, for who, etc...)<br>');
    dbms_output.put_line('Remember that each row in WF_ITEMS is associated to 100s or 1,000s of rows in the other WF runtime tables, ');
    dbms_output.put_line('so it is important to purge this obsolete runtime data regularly.<br>');
    dbms_output.put_line('Once a workflow item is closed then all the runtime data associated to completing this workflow process is now obsolete and should be purged to make room for new workflows.<BR><br>');
    dbms_output.put_line('<b>Purging Workflow regularly is recommended to maintain good system performance.</b><br>');  
    dbms_output.put_line('All workflow child processes must be completed in order for the whole workflow to be eligible for purging.  A common problem for workflows not getting purged as expected, can be as simple as an open notification that was never acknowledged or closed.');
    dbms_output.put_line('Not responding to SYSADMIN error notifications (WFERROR) can cause many workflow process and all of the child processes to not become eligible for purge.<br>It is important to review and manage any workflow items that remain open or closed for a long ');
    dbms_output.put_line('period of time, especially if your functional team considers them to be closed.  There can be many reasons for this, not purging all workflows, or workflows closed incorrectly, or errors that do not get addressed, and repeat over and over.');
    dbms_output.put_line('There are many scripts and notes provided in this WF Analyzer output that can help you identify any problems and provide solutions to help you <b><i>take control of workflow</b></i>.<br><br>');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=144806.1" target="_blank">Note 144806.1</a> - A Detailed Approach To Purging Oracle Workflow Runtime Data ');
    dbms_output.put_line('for details on how to drill down and identify any OLD items are still open, and ways to close them so they can be purged.</p>');    
    dbms_output.put_line('</td></tr></tbody></table><BR>');

  else

    dbms_output.put_line('There are less than 100 items in the WF_ITEMS table.<BR><BR>');

  end if;

  exception
	when others then 
	emesg := SQLERRM;
        dbms_output.put_line(emesg);
    
end;
/



REM
REM ******* Ebusiness Suite Version *******
REM

prompt <script type="text/javascript">    function displayRows1sql1(){var row = document.getElementById("s1sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv111"></a>
prompt     <B>E-Business Suite Version</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="60">
prompt       <blockquote><p align="left">
prompt          select vi.instance_name, fpg.release_name, vi.host_name, vi.startup_time, vi.version <br>
prompt          from fnd_product_groups fpg, v$instance vi<br>
prompt          where upper(substr(fpg.APPLICATIONS_SYSTEM_NAME,1,4)) = upper(substr(vi.INSTANCE_NAME,1,4));</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RELEASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>HOSTNAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DATABASE</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||vi.instance_name||'</TD>'||chr(10)|| 
'<TD>'||fpg.release_name||'</TD>'||chr(10)|| 
'<TD>'||vi.host_name||'</TD>'||chr(10)|| 
'<TD>'||vi.startup_time||'</TD>'||chr(10)|| 
'<TD>'||vi.version||'</TD></TR>'
from fnd_product_groups fpg, v$instance vi
where upper(substr(fpg.APPLICATIONS_SYSTEM_NAME,1,4)) = upper(substr(vi.INSTANCE_NAME,1,4));
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

REM
REM ******* Instance Node Details *******
REM

prompt <script type="text/javascript">    function displayRows1sql3(){var row = document.getElementById("s1sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=7 bordercolor="#DEE6EF"><font face="Calibri"><a name="fndnodes"></a>
prompt     <B>Instance Node Details</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="8" height="60">
prompt       <blockquote><p align="left">
prompt       select substr(node_name, 1, 20) node_name, server_address, substr(host, 1, 15) host,<br>
prompt           substr(domain, 1, 20) domain, substr(support_cp, 1, 3) cp, substr(support_web, 1, 3) web,<br>
prompt           substr(SUPPORT_DB, 1, 3) db, substr(VIRTUAL_IP, 1, 30) virtual_ip from fnd_nodes;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NODE_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SERVER ADDRESS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>HOST</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DOMAIN</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CP</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WEB</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DB</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VIRTUAL_IP</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||substr(node_name, 1, 20)||'</TD>'||chr(10)|| 
'<TD>'||server_address||'</TD>'||chr(10)|| 
'<TD>'||substr(host, 1, 15)||'</TD>'||chr(10)|| 
'<TD>'||substr(domain, 1, 20)||'</TD>'||chr(10)|| 
'<TD>'||substr(support_cp, 1, 3)||'</TD>'||chr(10)|| 
'<TD>'||substr(support_web, 1, 3)||'</TD>'||chr(10)||
'<TD>'||substr(SUPPORT_DB, 1, 3)||'</TD>'||chr(10)|| 
'<TD>'||substr(VIRTUAL_IP, 1, 30)||'</TD></TR>'
from fnd_nodes;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Workflow Database Parameter Settings *******
REM

prompt <script type="text/javascript">    function displayRows1sql2(){var row = document.getElementById("s1sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv112"></a>
prompt     <B>Workflow Database Parameter Settings</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows1sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s1sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="45">
prompt       <blockquote><p align="left">
prompt          select name, value<br>
prompt          from v$parameter<br>
prompt          where upper(name) in ('AQ_TM_PROCESSES','JOB_QUEUE_PROCESSES','JOB_QUEUE_INTERVAL',<br>
prompt                                'UTL_FILE_DIR','NLS_LANGUAGE', 'NLS_TERRITORY', 'CPU_COUNT',<br>
prompt                                'PARALLEL_THREADS_PER_CPU');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||name||'</TD>'||chr(10)|| 
'<TD>'||value||'</TD></TR>'
from v$parameter
where upper(name) in ('AQ_TM_PROCESSES','JOB_QUEUE_PROCESSES','JOB_QUEUE_INTERVAL','UTL_FILE_DIR','NLS_LANGUAGE', 'NLS_TERRITORY', 'CPU_COUNT','PARALLEL_THREADS_PER_CPU');
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

begin

select version into :db_ver from v$instance;

if (:db_ver like '8.%') or (:db_ver like '9.%') then 

    :db_ver := '0'||:db_ver;

end if;

if (:db_ver < '11.1') then

    select value into :qmon from v$parameter where upper(name) = 'AQ_TM_PROCESSES';

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note: JOB_QUEUE_PROCESSES for pre-11gR1 ('||:db_ver||') databases:</B><BR>');
    dbms_output.put_line('Oracle Workflow requires job queue processes to handle propagation of Business Event System event messages by AQs.<BR>');
    dbms_output.put_line('<B>The recommended minimum number of JOB_QUEUE_PROCESSES for Oracle Workflow is 10.<BR> ');
    dbms_output.put_line('The maximum number of JOB_QUEUE_PROCESSES is :<BR> -    36 in Oracle8i<BR> - 1,000 in Oracle9i Database and higher, so set the value of JOB_QUEUE_PROCESSES accordingly.</B><BR>');
    dbms_output.put_line('The ideal setting for JOB_QUEUE_PROCESSES should be set to the maximum number of jobs that would ever be run concurrently on a system PLUS a few more.</B><BR><BR>');

    dbms_output.put_line('To determine the proper amount of JOB_QUEUE_PROCESSES for Oracle Workflow, follow the queries outlined in<BR> ');
    dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=578831.1" target="_blank">Note 578831.1</a>');
    dbms_output.put_line('- How to determine the correct setting for JOB_QUEUE_PROCESSES.<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');
	
  elsif (:db_ver >= '11.1') then

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note: Significance of the JOB_QUEUE_PROCESSES for 11gR1+ ('||:db_ver||') databases:</B><BR><BR>');
    dbms_output.put_line('Starting from 11gR1, The init.ora parameter job_queue_processes does NOT need to be set for AQ propagations.');
    dbms_output.put_line('AQ propagation is now likewise handled by DBMS_SCHEDULER jobs rather than DBMS_JOBS. ');
    dbms_output.put_line('Reason: propagation takes advantage of the event based scheduling features of DBMS_SCHEDULER for better scalability. ');
    dbms_output.put_line('If the value of the JOB_QUEUE_PROCESSES database initialization parameter is zero, then that parameter does not influence ');
    dbms_output.put_line('the number of Oracle Scheduler jobs that can run concurrently. ');
    dbms_output.put_line('However, if the value is non-zero, it effectively becomes the maximum number of Scheduler jobs and job queue jobs than can run concurrently. ');
    dbms_output.put_line('If a non-zero value is set, it should be large enough to accommodate a Scheduler job for each Messaging Gateway agent to be started.<BR><BR>');    
    
    dbms_output.put_line('<B>Oracle Workflow recommends to UNSET the JOB_QUEUE_PROCESSES parameter as per DB recommendations to enable the scheduling features of DBMS_SCHEDULER for better scalability.</B><BR><BR>');      
    
    dbms_output.put_line('To update the JOB_QUEUE_PROCESSES database parameter file (init.ora) file:');
    dbms_output.put_line('<blockquote><i>job_queue_processes=10</i></blockquote>');
    dbms_output.put_line('or set dynamically via');
    dbms_output.put_line('<blockquote><i>connect / as sysdba<br><br>alter system set job_queue_processes=10;</i></blockquote>Remember that after bouncing the DB, dynamic changes are lost, and the DB parameter file settings are used.<BR>');    
    dbms_output.put_line('To determine the proper setting of JOB_QUEUE_PROCESSES for Oracle Workflow, follow the queries outlined in <BR>');
    dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=578831.1" target="_blank">Note 578831.1</a>');
    dbms_output.put_line('- How to determine the correct setting for JOB_QUEUE_PROCESSES.<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');
  
  else 

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note: To determine the proper amount of JOB_QUEUE_PROCESSES for Oracle Workflow</B><BR>');
    dbms_output.put_line('Follow the queries outlined in ');
    dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=578831.1" target="_blank">Note 578831.1</a>');
    dbms_output.put_line('- How to determine the correct setting for JOB_QUEUE_PROCESSES.<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

end if;

  
end;
/

declare
mycheck number;
begin
select 1 into mycheck from v$parameter where name = 'aq_tm_processes' and value = '0'
and (ismodified <> 'FALSE' OR isdefault='FALSE');
if (mycheck = 1) then
    	dbms_output.put_line('<table border="1" name="RedBox" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
    	dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    	dbms_output.put_line('<p><B>Error:<BR>');
	dbms_output.put_line('The parameter AQ_TM_PROCESSES is explicitly set to Zero (0)!</B><br>');
	dbms_output.put_line('This means the time monitor process (QMN) is disabled!!!, and no workflows will be progressed.');
	dbms_output.put_line('This can also disrupt the operation of the database due to several system queue tables used when the standard database features are used.!');	
	dbms_output.put_line('If it is set to zero, it is recommended to unset the parameter. However, this requires bouncing the database. ');
	dbms_output.put_line('In the meantime, if the database cannot be immediately bounced, the recommended value to set it to is "1", and this can be done dynamically:');
	dbms_output.put_line('<blockquote><i>conn / as sysdba<br>');
	dbms_output.put_line('alter system set aq_tm_processes = 1;</i></blockquote><br>');
	dbms_output.put_line('<B>Action:</B><BR>');	
	dbms_output.put_line('Follow the comments below, and refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=746313.1" target="_blank">Note 746313.1</a>');
	dbms_output.put_line('- What should be the Correct Setting for Parameter AQ_TM_PROCESSES in E-Business Suite Instance?<br>');
	dbms_output.put_line('</p></td></tr></tbody></table><BR>');
end if;
exception when no_data_found then
       	dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       	dbms_output.put_line('<tbody><tr><td> ');
	dbms_output.put_line('The parameter AQ_TM_PROCESSES is not explicitly set to Zero (0), which is fine.');
       	dbms_output.put_line('</td></tr></tbody></table><BR>');
end;
/

begin

select version into :db_ver from v$instance;

if (:db_ver like '8.%') or (:db_ver like '9.%') then 

    :db_ver := '0'||:db_ver;

end if;

if (:db_ver < '11.2') then

    select value into :qmon from v$parameter where upper(name) = 'AQ_TM_PROCESSES';

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note: AQ_TM_PROCESSES for pre-11gR2 ('||:db_ver||') databases:</B><BR><BR>');
    dbms_output.put_line('The Oracle Streams AQ time manager process is called the Queue MONitor (QMON), a background process controlled by parameter AQ_TM_PROCESSES.<BR>');
    dbms_output.put_line('QMON processes are associated with the mechanisms for message expiration, retry, delay, maintaining queue statistics, removing PROCESSED messages ');
    dbms_output.put_line('from a queue table and updating the dequeue IOT as necessary.  QMON plays a part in both permanent and buffered message processing.<BR>');
    dbms_output.put_line('If a qmon process should fail, this should not cause the instance to fail. This is also the case with job queue processes.<BR>');
    dbms_output.put_line('QMON itself operates on queues but does not use a database queue for its own processing of tasks and time based operations, so it can ');
    dbms_output.put_line('be envisaged as a number of discrete tasks which are run by Queue Monitor processes or servers.');

    dbms_output.put_line('The AQ_TM_PROCESSES parameter is set in the (init.ora) database parameter file, and by default is set to 1.<br>');
    dbms_output.put_line('This value allows Advanced Queuing to start 1 AQ background process for Queue Monitoring, which is  ');
    dbms_output.put_line('usually sufficient for simple E-Business Suite instances.  <BR><B>However, this setting can be increased (dynamically) to improve queue maintenance performance.</B></p>');
    
    dbms_output.put_line('<B>Oracle highly recommends manually setting the aq_tm_processes parameter to a reasonable value (no greater than 5) which will leave some qmon slave processes to deal with buffered message operations.</B><BR><BR>');
      
    dbms_output.put_line('If this parameter is set to a non-zero value X, Oracle creates that number of QMNX processes starting from ora_qmn0_SID (where SID is the identifier of the database) ');
    dbms_output.put_line('up to ora_qmnX_SID ; if the parameter is not specified or is set to 0, then the QMON processes are not created. ');
    dbms_output.put_line('There can be a maximum of 10 QMON processes running on a single instance. <BR>For example the parameter can be set in the init.ora as follows :');
    dbms_output.put_line('<blockquote><i>aq_tm_processes=5</i></blockquote>');
    dbms_output.put_line('or set dynamically via');
    dbms_output.put_line('<blockquote><i>connect / as sysdba<br><br>alter system set aq_tm_processes=5;</i></blockquote>Remember that after bouncing the DB, dynamic changes are lost, and the DB parameter file settings are used.<BR>'); 
    
    dbms_output.put_line('It is recommended to NOT DISABLE the Queue Monitor processes by setting aq_tm_processes=0 on a permanent basis. As can be seen above, ');
    dbms_output.put_line('disabling will stop all related processing in relation to tasks outlined. This will likely have a significant affect on operation of queues - PROCESSED ');
    dbms_output.put_line('messages will not be removed and any time related, TM actions will not succeed, AQ objects will grow in size.<BR><BR>');
    dbms_output.put_line('To update the AQ_TM_PROCESSES database parameter, follow the steps outlined in <BR>');
    dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=305662.1#aref1" target="_blank">Note 305662.1</a>');
    dbms_output.put_line('- Master Note for AQ Queue Monitor Process (QMON).<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

  elsif (:db_ver >= '11.2') then

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note: Significance of the AQ_TM_PROCESSES for 11gR2+ ('||:db_ver||') databases:</B><BR><BR>');
    dbms_output.put_line('Starting from 11gR2, Queue Monitoring can utilize a feature called "auto-tune".<br>');
    dbms_output.put_line('By default, AQ_TM_PROCESSES parameter is unspecified so it is able to adapt the number of AQ background processes to the system load.<br>');
    dbms_output.put_line('However, if you do specify a value, then that value is taken into account but the number of processes can still be auto-tuned and so the number of ');
    dbms_output.put_line('running qXXX processes can be different from what was specified by AQ_TM_PROCESSES.<BR><BR>');    
    
    dbms_output.put_line('<B>Oracle highly recommends that you leave the AQ_TM_PROCESSES parameter unspecified and let the system autotune.</B><BR><BR>');
    
    dbms_output.put_line('Note: For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=746313.1" target="_blank">Note 746313.1</a>');
    dbms_output.put_line('- What should be the Correct Setting for Parameter AQ_TM_PROCESSES in E-Business Suite Instance?<br></p>');

    dbms_output.put_line('It should be noted that if AQ_TM_PROCESSES is explicitly specified then the process(es) started will only maintain persistent messages. ');
    dbms_output.put_line('For example if aq_tm_processes=1 then at least one queue monitor slave process will be dedicated to maintaining persistent messages. ');
    dbms_output.put_line('Other process can still be automatically started to maintain buffered messages. Up to and including version 11.1 if you explicitly set aq_tm_processes = 10 ');
    dbms_output.put_line('then there will be no processes available to maintain buffered messages. This should be borne in mind in environments which use Streams replication ');
    dbms_output.put_line('and from 10.2 onwards user enqueued buffered messages.<BR><BR>');

    dbms_output.put_line('It is also recommended to NOT DISABLE the Queue Monitor processes by setting aq_tm_processes=0 on a permanent basis. As can be seen above, ');
    dbms_output.put_line('disabling will stop all related processing in relation to tasks outlined. This will likely have a significant affect on operation of queues - PROCESSED ');
    dbms_output.put_line('messages will not be removed and any time related, TM actions will not succeed, AQ objects will grow in size.<BR>');

    dbms_output.put_line('<p><B>Note: There is a known issue viewing the true value of AQ_TM_PROCESSES for 10gR2+ (10.2) from the v$parameters table.</B><BR>');
    dbms_output.put_line('Review the details in <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=428441.1" target="_blank">Note 428441.1</a>');
    dbms_output.put_line('- "Warning: Aq_tm_processes Is Set To 0" Message in Alert Log After Upgrade to 10.2.0.3 or Higher.<br>');
    dbms_output.put_line('Also of interest <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=809383.1" target="_blank">Note 809383.1</a>');
    dbms_output.put_line('- Queue Monitor Auto-Tuning only uses 1 Qmon Slave Process for Persistent Queues.</p>');
    
    dbms_output.put_line('To check whether AQ_TM_PROCESSES Auto-Tuning is enabled, follow the steps outlined in<BR> ');
    dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=305662.1#aref7" target="_blank">Note 305662.1</a>');
    dbms_output.put_line('- Master Note for AQ Queue Monitor Process (QMON) under Section : Significance of the AQ_TM_PROCESSES Parameter in 10.1 onwards<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');
  
  else 

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note:</B> For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=746313.1" target="_blank">Note 746313.1</a>');
    dbms_output.put_line('- What should be the Correct Setting for Parameter AQ_TM_PROCESSES in E-Business Suite Instance?<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

end if;

  
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* This is just a Note *******
REM

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody> 
prompt   <tr>     
prompt     <td> 
prompt       <p>For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1" target="_blank">
prompt Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br>
prompt       </td>
prompt    </tr>
prompt    </tbody> 
prompt </table><BR><BR>

prompt </blockquote>

REM **************************************************************************************** 
REM *******                   Section 2 : Workflow Administration                    *******
REM ****************************************************************************************

prompt <a name="section2"></a><B><font size="+2">Workflow Administration</font></B><BR><BR>
prompt <blockquote>

REM
REM ******* Verify the Workflow Administrator Role *******
REM

prompt <a name="wfadv121"></a><B><U>Workflow Administrator Role</B></U><BR>
prompt <blockquote>
       
declare

	wfadminUsers          varchar2(320);

cursor wf_adminIDs IS
	select r.name,r.display_name,r.orig_system,r.status
	from WF_USER_ROLE_ASSIGNMENTS_V wura, wf_roles r, fnd_user f
	where r.name = f.user_name
	and wura.user_name = r.name
	and wura.role_name = (select wf_core.translate('WF_ADMIN_ROLE') from dual)
	and ((wura.start_date < sysdate) and ((wura.end_date is null) or (wura.end_date > sysdate)))
	and ((f.start_date < sysdate) and ((f.end_date is null) or (f.end_date > sysdate)))
	order by r.name;

begin

	select wf_core.translate('WF_ADMIN_ROLE') into :wf_admin_role from dual;

	select nvl(max(rownum), 0) into :wf_admins_cnt
	from wf_roles 
	where name in (select user_name from WF_USER_ROLE_ASSIGNMENTS where role_name = (select wf_core.translate('WF_ADMIN_ROLE') from dual));

if ((:wf_admin_role like 'FND_RESP%') and (:wf_admins_cnt = 0)) then

       dbms_output.put_line('There are no Users assigned to this Responsibility, so noone has Workflow Administrator Role permissions on this instance.<BR>');
       dbms_output.put_line('Please assign someone this responsibility.<BR><BR> ');
       

  elsif ((:wf_admin_role like 'FND_RESP%') and (:wf_admins_cnt = 1)) then
 
       dbms_output.put_line('There is only one User assigned to this Responsibility, so they alone have Workflow Administrator Role permissions on this instance.<BR>');
       dbms_output.put_line('Please assign more people to this responsibility.<BR><BR> ');
  
  elsif ((:wf_admin_role like 'FND_RESP%') and (:wf_admins_cnt > 1)) then

	select r.display_name into :wf_admin_display 
	from wf_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ;

	select notification_preference into :ntf_pref 
	from wf_local_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ; 

	select decode(email_address, '','No Email Specified', email_address) into :email 
	from wf_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ;  

       dbms_output.put_line('The Workflow Administrator role (WF_ADMIN_ROLE) for ' || :sid || ' is set to a Responsibility (' || :wf_admin_role || ') also known as ' || :wf_admin_display || '.<BR>' );
       dbms_output.put_line('This role ' || :wf_admin_role || ' has a Notification Preference of ' || :ntf_pref || ', and email address is set to ' || :email || '.<BR>');
       dbms_output.put_line('There are mutiple Users assigned to this Responsibility, all having Workflow Administrator Role permissions on this instance.<BR>');
       dbms_output.put_line('<b>Remember that the Workflow Administrator Role has permissions to full access of ALL workflows and notifications.</b><BR><BR>');
       dbms_output.put_line('Please verify this list of ACTIVE users assigned this ACTIVE responsibility is accurate.<BR><BR>');
       
       dbms_output.put_line('<script type="text/javascript">    function displayRows2sql2c(){var row = document.getElementById("s2sql2c");if (row.style.display == "")  row.style.display = "none";	else row.style.display = "";    }</script>');
       dbms_output.put_line('<TABLE border="1" cellspacing="0" cellpadding="2">');
       dbms_output.put_line('<TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">');
       dbms_output.put_line('  <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri">');
       dbms_output.put_line('    <B>Roles with Workflow Administrator Role Permissions</B></font></TD>');
       dbms_output.put_line('    <TD bordercolor="#DEE6EF">');
       dbms_output.put_line('      <div align="right"><button onclick="displayRows2sql2c()" >SQL Script</button></div>');
       dbms_output.put_line('  </TD>');
       dbms_output.put_line('</TR>');
       dbms_output.put_line('<TR id="s2sql2c" style="display:none">');
       dbms_output.put_line('   <TD BGCOLOR=#DEE6EF colspan="4" height="85">');
       dbms_output.put_line('      <blockquote><p align="left">');
       dbms_output.put_line(' This query lists all the users that have EVER had this responsibility assigned and shows thier current FND_USER status.<br>');
       dbms_output.put_line(' Remove the comment lines in the query to list only current ACTIVE users (ie table output below) AND that have this responsibility currently assigned.<br><br>');
       dbms_output.put_line(' select r.name, r.display_name, r.description, r.status, wura.start_date RESP_START_DATE,<br>');
       dbms_output.put_line('        wura.end_date RESP_END_DATE, f.start_date FND_USER_START, f.end_date FND_USER_END_DATE <br>');
       dbms_output.put_line(' from WF_USER_ROLE_ASSIGNMENTS wura, wf_local_roles r, fnd_user f<br>');
       dbms_output.put_line(' where r.name = f.user_name<br>');
       dbms_output.put_line(' and wura.user_name = r.name<br>');
       dbms_output.put_line(' and wura.role_name = (select wf_core.translate("WF_ADMIN_ROLE") from dual)<br>');
       dbms_output.put_line(' --and ((wura.start_date < sysdate) and ((wura.end_date is null) or (wura.end_date > sysdate))) --uncomment these two lines to<br>');
       dbms_output.put_line(' --and ((f.start_date < sysdate) and ((f.end_date is null) or (f.end_date > sysdate)))          --show only current active users<br>');  
       dbms_output.put_line(' order by wura.creation_date desc;</p>');
       dbms_output.put_line('      </blockquote>');
       dbms_output.put_line('    </TD>');
       dbms_output.put_line('  </TR>');
       dbms_output.put_line('<TR>');
       dbms_output.put_line('<TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NAME</B></font></TD>');
       dbms_output.put_line('<TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></font></TD>');
       dbms_output.put_line('<TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ORIG_SYSTEM</B></font></TD>');
       dbms_output.put_line('<TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></font></TD>');


	FOR recwf_adminIDs IN wf_adminIDs
	LOOP
		dbms_output.put_line('<TR><TD>'||recwf_adminIDs.name||'</TD>');                                                                                                     
		dbms_output.put_line('<TD>'||recwf_adminIDs.display_name||'</TD>');                                                                                              
		dbms_output.put_line('<TD>'||recwf_adminIDs.orig_system||'</TD>');                                                                                                             
		dbms_output.put_line('<TD>'||recwf_adminIDs.status||'</TD></TR>');                                                                                                      
	END LOOP;

        dbms_output.put_line('</TABLE><P><P>');

  elsif (:wf_admin_role = '*') then

	:wf_admin_display := 'Asterisk';
	:ntf_pref := 'not set';
	:email := 'not set when Asterisk';

    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Warning:</B>The Workflow Administrator role (WF_ADMIN_ROLE) for ' || :sid || ' is set to an Asterisk which allows EVERYONE access to Workflow Administrator Role permissions.<BR>');
    dbms_output.put_line('This is not recommended for Production instances, but may be ok for Testing.  <BR>');
    dbms_output.put_line('<b>Remember that the Workflow Administrator Role has permissions to full access of all workflows and notifications.</b><BR><BR>');
    dbms_output.put_line('      <p><B>Note:</B> For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1" target="_blank">Note 453137.1</a>');
    dbms_output.put_line('- Oracle Workflow Best Practices Release 12 and Release 11i<br></p>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

  else 

	select r.display_name into :wf_admin_display 
	from wf_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ;

	select notification_preference into :ntf_pref 
	from wf_local_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ; 

	select decode(email_address, '','No Email Specified', email_address) into :email 
	from wf_roles r, wf_resources res 
	where res.name = 'WF_ADMIN_ROLE'
	and res.language = 'US'
	and res.text = r.NAME ; 
	
    dbms_output.put_line('The Workflow Administrator role (WF_ADMIN_ROLE) for ' || :sid || ' is set to a single Applications Username or role (' || :wf_admin_role || ') also known as ' || :wf_admin_display || '.<BR>' );
    dbms_output.put_line('This role ' || :wf_admin_role || ' has a Notification Preference of ' || :ntf_pref || ', and email address is set to ' || :email || '.<BR>' );
    dbms_output.put_line('On this instance, you must log into Oracle Applications as ' || :wf_admin_role || ' to utilize the Workflow Administrator Role permissions and control any and all workflows.<BR><BR>');
    dbms_output.put_line('<B>Note:</B> For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1" target="_blank">Note 453137.1</a>');
    dbms_output.put_line('- Oracle Workflow Best Practices Release 12 and Release 11i<br><br>');



  end if;
 
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* SYSADMIN User Setup for Error Notifications *******
REM

prompt <a name="sysadmin"></a><B><U>SYSADMIN User Setup for Error Notifications</B></U><BR>
prompt <blockquote>

begin

 select notification_preference into :ntf_pref 
   from wf_local_roles
  where name = 'SYSADMIN';

 select nvl(email_address,'NOTSET') into :admin_email 
   from wf_local_roles
  where name = 'SYSADMIN';

 select count(notification_id) into :errorntfcnt
   from wf_notifications
  where recipient_role = 'SYSADMIN'
    and message_type like '%ERROR%';

end;
/

begin

if (:ntf_pref = 'DISABLED') then

    dbms_output.put_line('<table border="1" name="RedBox" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Error:<BR>');
    dbms_output.put_line('The SYSADMIN User e-mail is DISABLED!</B><BR>');
    dbms_output.put_line('The SYSADMIN User is the default recipient for several types of notifications such as Workflow error notifications.<br>  ');
    dbms_output.put_line('Currently there are '||to_char((:errorntfcnt),'999,999,999,999')||' Error Notifications assigned to the SYSADMIN user. <br><br>');
    dbms_output.put_line('<B>Action:</B><BR>');
    dbms_output.put_line('Please specify how you want to receive these notifications by defining the notification preference and e-mail address for the SYSADMIN User.<BR>');
    dbms_output.put_line('First correct the SYSADMIN User e-mail_address and change the notification_preference from DISABLED to a valid setting.<BR><BR>');
    dbms_output.put_line('Please review System Administration Setup Tasks in the <a href="http://docs.oracle.com/cd/B25516_18/current/acrobat/115sacg.zip"');
    dbms_output.put_line('target="_blank">Oracle Applications System Administrators Guide</a>, for information on how to change these settings.<BR>');
    dbms_output.put_line('For additional solutions for distributing the workload of responding to SYSADMIN Error Notifications to other groups or individuals using WorkList Access or Notification Routing Rules, please review :<br>'); 
    dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1448095.1" target="_blank">');
    dbms_output.put_line('Note 1448095.1</a> - How to handle or reassign System : Error (WFERROR) Notifications that default to SYSADMIN.<br>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	   
  elsif (:ntf_pref = 'QUERY') then

    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Warning:</B><BR>');
    dbms_output.put_line('The SYSADMIN User appears to be setup to <b>not receive</b> email notifications!<br>');
    dbms_output.put_line('<br>This is fine.<br>');
    dbms_output.put_line('<B>However</b>, this means SYSADMIN can only access notifications through the Oracle Workflow Worklist Web page. <br>');
    dbms_output.put_line('Please verify that the SYSADMIN User is actively processing the '||to_char((:errorntfcnt),'999,999,999,999')||' Error Notifications that are currently assigned to this user. <br><br>');
    dbms_output.put_line('Please review System Administration Setup Tasks in the <a href="http://docs.oracle.com/cd/B25516_18/current/acrobat/115sacg.zip"');
    dbms_output.put_line('target="_blank">Oracle Applications System Administrators Guide</a>, for information on how to change these settings if needed.<BR>');
    dbms_output.put_line('For additional solutions for distributing the workload of responding to SYSADMIN Error Notifications to other groups or individuals using WorkList Access or Notification Routing Rules, please review :<br>'); 
    dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1448095.1" target="_blank">');
    dbms_output.put_line('Note 1448095.1</a> - How to handle or reassign System : Error (WFERROR) Notifications that default to SYSADMIN.<br>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>'); 

    
  elsif ((:admin_email = 'NOTSET') and (:ntf_pref <> 'QUERY')) then

    dbms_output.put_line('<table border="1" name="RedBox" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Error:<BR>');
    dbms_output.put_line('The SYSADMIN User has not been setup correctly.  SYSADMIN e-mail address is not set, but the notification preference is set to send emails.</B><BR>');
    dbms_output.put_line('Currently there are '||to_char((:errorntfcnt),'999,999,999,999')||' Error Notifications assigned to the SYSADMIN user. <br><br>');
    dbms_output.put_line('<B>Action:</B><BR>');
    dbms_output.put_line('In Oracle Applications, you must particularly check the notification preference and e-mail address for the SYSADMIN User. <BR>');
    dbms_output.put_line('The SYSADMIN User is the default recipient for several types of notifications such as Workflow error notifications.  ');
    dbms_output.put_line('You need to specify how you want to receive these notifications by defining the notification preference and e-mail address for the User: SYSADMIN.<BR>');
    dbms_output.put_line('By default, the SYSADMIN User has a notification preference to receive e-mail notifications. <BR>To enable Oracle Workflow to send e-mail to the SYSADMIN user, ');
    dbms_output.put_line('Login to Oracle Applications as SYSADMIN and navigate to the User Preferences window in top right corner and assign SYSADMIN an e-mail address that is fully qualified with a valid domain.<br> ');
    dbms_output.put_line('However, if you want to access notifications only through the Oracle Workflow Worklist Web page, ');
    dbms_output.put_line('then you should change the notification preference for SYSADMIN to "Do not send me mail" in the Preferences page. In this case you do not need to define an e-mail address. <br><br>');
    dbms_output.put_line('Please review System Administration Setup Tasks in the <a href="http://docs.oracle.com/cd/B25516_18/current/acrobat/115sacg.zip"');
    dbms_output.put_line('target="_blank">Oracle Applications System Administrators Guide</a>, for more information.<BR>');
    dbms_output.put_line('For additional solutions for distributing the workload of responding to SYSADMIN Error Notifications to other groups or individuals using WorkList Access or Notification Routing Rules, please review :<br>'); 
    dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1448095.1" target="_blank">');
    dbms_output.put_line('Note 1448095.1</a> - How to handle or reassign System : Error (WFERROR) Notifications that default to SYSADMIN.<br>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

  elsif ((:admin_email <> 'NOTSET') and (:ntf_pref <> 'QUERY')) then 

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note:</B> The SYSADMIN User appears to be setup to receive email notifications.<br>');
    dbms_output.put_line('Please verify that the email_address ('||:admin_email||') is a valid email address and can recieve emails successully.<br>');
    dbms_output.put_line('Also, please verify that the SYSADMIN User is actively processing the '||to_char((:errorntfcnt),'999,999,999,999')||' Error Notifications that are currently assigned to this user. <br><br>');
    dbms_output.put_line('Please review System Administration Setup Tasks in the <a href="http://docs.oracle.com/cd/B25516_18/current/acrobat/115sacg.zip"');
    dbms_output.put_line('target="_blank">Oracle Applications System Administrators Guide</a>, for more information.<BR>');
    dbms_output.put_line('For additional solutions for distributing the workload of responding to SYSADMIN Error Notifications to other groups or individuals using WorkList Access or Notification Routing Rules, please review :<br>'); 
    dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1448095.1" target="_blank">');
    dbms_output.put_line('Note 1448095.1</a> - How to handle or reassign System : Error (WFERROR) Notifications that default to SYSADMIN.<br>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');  
    
  else 

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note:</B> It is unclear what the SYSADMIN User e-mail address is set to.<br>');
    dbms_output.put_line('Please verify that the SYSADMIN User is actively processing the '||to_char((:errorntfcnt),'999,999,999,999')||' Error Notifications that are currently assigned to this user. <br><br>');
    dbms_output.put_line('Please review System Administration Setup Tasks in the <a href="http://docs.oracle.com/cd/B25516_18/current/acrobat/115sacg.zip"');
    dbms_output.put_line('target="_blank">Oracle Applications System Administrators Guide</a>, for information on how to setup these tasks.<BR>');
    dbms_output.put_line('For additional solutions for distributing the workload of responding to SYSADMIN Error Notifications to other groups or individuals using WorkList Access or Notification Routing Rules, please review :<br>'); 
    dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1448095.1" target="_blank">');
    dbms_output.put_line('Note 1448095.1</a> - How to handle or reassign System : Error (WFERROR) Notifications that default to SYSADMIN.<br>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');  
    
end if;
 
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Workflow Error Notifications Summary Status *******
REM

prompt <a name="wferror"></a><BR><B><U>Workflow Error Notifications Summary Status</B></U><BR>
prompt <blockquote>

begin

	select nvl(max(rownum), 0) into :ntferr_cnt
	from wf_notifications n
	where n.message_type like '%ERROR%';

	select nvl(max(rownum), 0) into :ecxerr_cnt
	from wf_notifications n
	where n.message_type = 'ECXERROR';

	select nvl(max(rownum), 0) into :omerr_cnt
	from wf_notifications n
	where n.message_type = 'OMERROR';

	select nvl(max(rownum), 0) into :poerr_cnt
	from wf_notifications n
	where n.message_type = 'POERROR';

	select nvl(max(rownum), 0) into :wferr_cnt
	from wf_notifications n
	where n.message_type = 'WFERROR';	


  if (:ntferr_cnt = 0) then

       	dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       	dbms_output.put_line('<tbody><tr><td> ');
       	dbms_output.put_line('<p><B>Well Done !!<BR><BR>');
       	dbms_output.put_line('There are no Notification Error Messages for this instance.</B><BR>');
       	dbms_output.put_line('You deserve a whole cake!!!<BR>');
       	dbms_output.put_line('</p></td></tr></tbody></table><BR>');
       
    elsif (:ntferr_cnt < 100) then
 
 	dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');	
   	dbms_output.put_line('<tbody><tr><td> ');
  	dbms_output.put_line('<p><B>Attention:<BR>');
       	dbms_output.put_line('There are less that 100 Error Notifications found on this instance.</B><BR>');
       	dbms_output.put_line('Keep up the good work.... You deserve a piece of pie.<BR>');
       	dbms_output.put_line('</p></td></tr></tbody></table><BR>');  
  
    else 

	select round(:ecxerr_cnt/:ntferr_cnt,2)*100 into :ecxrate from dual;	
	select round(:omerr_cnt/:ntferr_cnt,2)*100 into :omrate from dual;
	select round(:poerr_cnt/:ntferr_cnt,2)*100 into :porate from dual;
	select round(:wferr_cnt/:ntferr_cnt,2)*100 into :wfrate from dual;
	
	dbms_output.put('<blockquote><img src="https://chart.googleapis.com/chart?');
	dbms_output.put('chs=500x200');
	dbms_output.put('\&chd=t:'||:wfrate||','||:porate||','||:omrate||','||:ecxrate||'\&cht=p3');
	dbms_output.put('\&chtt=Workflow+Error+Notifications+by+Type');
	dbms_output.put('\&chl=WFERROR|POERROR|OMERROR|ECXERROR');
	dbms_output.put('\&chdl='||:wferr_cnt||'|'||:poerr_cnt||'|'||:omerr_cnt||'|'||:ecxerr_cnt||'"><BR>');
	dbms_output.put_line('Item Types</blockquote><br>');

    	dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');	
  	dbms_output.put_line('<tbody><tr><td> ');
  	dbms_output.put_line('<B>Warning:</B><BR>');
  	dbms_output.put_line('There are '||to_char(:ntferr_cnt,'999,999,999,999')||' Error Notifications of type (ECXERROR,OMERROR,POERROR,WFERROR) found on this instance.<BR>');
  	dbms_output.put_line('Please review the following table to better understand the volume and status for these Error Notifications. <BR><BR>');
  	dbms_output.put_line('Also review : <br><a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1448095.1" target="_blank">');
  	dbms_output.put_line('Note 1448095.1</a> - How to handle or reassign System : Error (WFERROR) Notifications that default to SYSADMIN.<br>');
  	dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=760386.1" target="_blank">');
  	dbms_output.put_line('Note 760386.1</a> - How to enable Bulk Notification Response Processing for Workflow in 11i and R12, for more details on ways to do this.');
  	dbms_output.put_line('</p></td></tr></tbody></table><BR>');       
       
  end if;
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Workflow Error Notification Messages Summary Status *******
REM

prompt <a name="wfadv124"></a><B><U>Workflow Error Notification Messages Summary Status</B></U><BR>
prompt <blockquote>

prompt <script>
prompt         $(function(){
prompt           $("#ErrorNtfs").tablesorter({sortList: [[3,0],[9,1],[4,0]] }); // sorts 4th column asc, 10th column desc, 5th column asc order
prompt         });
prompt </script>

prompt <script type="text/javascript">    function displayRows2sql6(){var row = document.getElementById("s2sql6");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2" width="100%">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Workflow Error Notification Messages Summary Status <i>(Default SORT is by NTF_STATUS asc, COUNT desc, RECIPIENT)</i></B></font><br>
prompt     <font color="#FF0000"><i><b>TIP! </b></font>Sort multiple columns simultaneously by holding down the shift key and clicking a second, third or even fourth column header!</i></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql6()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql6" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="165">
prompt       <blockquote><p align="left">
prompt          select n.message_type, n.MESSAGE_NAME, nvl(to_char(n.end_date, 'YYYY'),'OPEN') CLOSED,<br>
prompt          -- nvl(to_char(n.end_date, 'YYYY-MM'),'OPEN') CLOSED, <br>
prompt          n.STATUS, n.recipient_role, r.STATUS, r.ORIG_SYSTEM, r.notification_preference NTF_PREF,<br>
prompt          r.email_address, count(n.notification_id) COUNT<br>
prompt          from wf_notifications n, wf_local_roles r<br>
prompt          where n.recipient_role = r.name<br>
prompt          and n.message_type like '%ERROR%'<br>
prompt          group by n.message_type, n.MESSAGE_NAME, nvl(to_char(n.end_date, 'YYYY'),'OPEN'), n.STATUS,<br> 
prompt          n.recipient_role, r.STATUS, r.ORIG_SYSTEM, r.notification_preference, r.email_address<br>
prompt          order by nvl(to_char(n.end_date, 'YYYY'),'OPEN'), count(n.notification_id) desc, n.recipient_role;</p>
prompt       </blockquote>
prompt </TD></TR></TABLE>
prompt <TABLE id="ErrorNtfs" class="tablesorter" border="1" cellspacing="0" cellpadding="2">
prompt <THEAD>
prompt   <TR>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM TYPE</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE_NAME</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>CLOSED</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>NTF_STATUS</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>RECIPIENT</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>ORIG_SYSTEM</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>EMAIL PREF</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>EMAIL ADDRESS</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TH>
prompt   </TR>
prompt </THEAD>
prompt <TBODY>
exec :n := dbms_utility.get_time;
select 
'<TR><TD>'||n.message_type||'</TD>'||chr(10)|| 
'<TD>'||n.MESSAGE_NAME||'</TD>'||chr(10)||
'<TD>'||nvl(to_char(n.end_date, 'YYYY'),'OPEN')||'</TD>'||chr(10)|| 
'<TD>'||n.STATUS||'</TD>'||chr(10)||
'<TD>'||n.recipient_role||'</TD>'||chr(10)|| 
'<TD>'||r.STATUS||'</TD>'||chr(10)||
'<TD>'||r.ORIG_SYSTEM||'</TD>'||chr(10)||
'<TD>'||r.notification_preference||'</TD>'||chr(10)|| 
'<TD>'||r.email_address||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(n.notification_id),'999,999,999,999')||'</div></TD></TR>'
from wf_notifications n, wf_local_roles r
where n.recipient_role = r.name
and n.message_type like '%ERROR%'
group by n.message_type, n.MESSAGE_NAME, nvl(to_char(n.end_date, 'YYYY'),'OPEN'), n.STATUS, 
n.recipient_role, r.STATUS, r.ORIG_SYSTEM, r.notification_preference, r.email_address
order by nvl(to_char(n.end_date, 'YYYY'),'OPEN'), count(n.notification_id) desc, n.recipient_role;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

   :dee_open_cnt := 0;
   :dee_clsd_cnt := 0;
   :dee_open30_cnt := 0;
   
select count(n.notification_id) into :dee_open_cnt
from wf_notifications n, wf_local_roles r
where n.recipient_role = r.name
and n.message_type like '%ERROR%'
and n.message_name like 'DEFAULT_EVENT%'
and n.status = 'OPEN';

select count(n.notification_id) into :dee_open30_cnt
from wf_notifications n, wf_local_roles r
where n.recipient_role = r.name
and n.message_type = 'WFERROR'
and n.message_name like 'DEFAULT_EVENT%'
and n.begin_date > sysdate-30
and n.status = 'OPEN';

select count(n.notification_id) into :dee_clsd_cnt
from wf_notifications n, wf_local_roles r
where n.recipient_role = r.name
and n.message_type = 'WFERROR'
and n.message_name like 'DEFAULT_EVENT%'
and n.status ! = 'OPEN';

if (:dee_open_cnt>0)  then

	if (:dee_open30_cnt = 0) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are ' || to_char(:total_error,'999,999,999,999') || ' Error Notifications, ');
       dbms_output.put_line('where ' || to_char(:open_error,'999,999,999,999') || ' (' || (round(:open_error/:total_error,2)*100) || '%) are still OPEN, ');
       dbms_output.put_line('and '|| to_char(:closed_error,'999,999,999,999') || ' are closed.<BR><BR>');	   
       dbms_output.put_line('Additionally, ALL '|| to_char(:dee_open_cnt,'999,999,999,999') || ' of the system generated Workflow Error Notifications (DEFAULT_EVENT_%_ERROR) that are assigned to SYSADMIN and remain OPEN were generated over 30 days ago and therefore are likely candidates to be closed and purged.<br> ');
       dbms_output.put_line('These system generated WFERROR messages do not belong to a parent workflow process and account for ('|| (round(:dee_open_cnt/:ntferr_cnt,2)*100) || '%) of the all Error notifications');
       dbms_output.put_line(' of which ' || to_char(:open_error,'999,999,999,999') || ' (' || (round(:open_error/:total_error,2)*100) || '%) are still OPEN,');
       dbms_output.put_line(' and '|| to_char(:dee_clsd_cnt,'999,999,999,999') || ' (' || (round(:closed_error/:total_error,2)*100) || '%)  are closed.<BR><BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Since these errors have not occured recently, it is recommended to remove these space consuming system generated Error notifications.<br>');
       dbms_output.put_line('Follow the note below for steps to clean up SYSADMIN queue and easily remove these system generated error notifications.<br><br> ');	   
       dbms_output.put_line('<B>Note:</B> For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1587923.1" target="_blank">Note 1587923.1</a>');
       dbms_output.put_line('- How to Close and Purge excessive WFERROR workflows and DEFAULT_EVENT_ERROR notifications from Workflow.<br><br>');	   
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	   
	elsif (:dee_open_cnt = :dee_open30_cnt) then
	
       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are ' || to_char(:total_error,'999,999,999,999') || ' Error Notifications, ');
       dbms_output.put_line('where ' || to_char(:open_error,'999,999,999,999') || ' (' || (round(:open_error/:total_error,2)*100) || '%) are still OPEN, ');
       dbms_output.put_line('and '|| to_char(:closed_error,'999,999,999,999') || ' are closed.<BR><BR>');		   
       dbms_output.put_line('Additionally, ALL ' || to_char(:dee_open_cnt,'999,999,999,999') || ' of the system generated Workflow Error Notifications (DEFAULT_EVENT_%_ERROR) ');dbms_output.put_line('that are assigned to SYSADMIN and remain OPEN were generated within the past 30 days.  ');
       dbms_output.put_line('These system generated WFERROR messages do not belong to a parent workflow process and account for ' || to_char(:dee_open_cnt/:ntferr_cnt) ||'('|| (round(:dee_open_cnt/:ntferr_cnt,2)*100) || '%) of the Error notifications');
       dbms_output.put_line(' of which (' || (round(:open_error/:total_error,2)*100) || '%) are still OPEN,');
       dbms_output.put_line(' and (' || (round(:closed_error/:total_error,2)*100) || '%)  are closed.<BR><BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Since these errors have occured recently, it is recommended to first ensure that the issue is resolved and no longer raising system generated ');
       dbms_output.put_line('Error notifications.<br> Next, follow the note below for steps to remove these system generated error notifications.<br><br> ');   
       dbms_output.put_line('Follow the note below for steps to clean up SYSADMIN queue and easily remove these system generated error notifications.<br><br> ');	     
       dbms_output.put_line('<B>Note:</B> For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1587923.1" target="_blank">Note 1587923.1</a>');
       dbms_output.put_line('- How to Close and Purge excessive WFERROR workflows and DEFAULT_EVENT_ERROR notifications from Workflow.<br>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

	else 
	
       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are ' || to_char(:total_error,'999,999,999,999') || ' Error Notifications, ');
       dbms_output.put_line('where ' || to_char(:open_error,'999,999,999,999') || ' (' || (round(:open_error/:total_error,2)*100) || '%) are still OPEN, ');
       dbms_output.put_line('and '|| to_char(:closed_error,'999,999,999,999') || ' are closed.<BR><BR>');		   
       dbms_output.put_line('Additionally, some of the ' || to_char(:dee_open_cnt,'999,999,999,999') || ' system generated Workflow Error Notifications (DEFAULT_EVENT_%_ERROR) that'); dbms_output.put_line('are assigned to SYSADMIN and remain OPEN were generated within the past 30 days.<br> ');
       dbms_output.put_line('These system generated WFERROR messages do not belong to a parent workflow process and account ');
       dbms_output.put_line('for ('|| (round(:dee_open_cnt/:ntferr_cnt,2)*100) || '%) of all the Error notifications where (' || (round(:open_error/:total_error,2)*100) || '%) are still OPEN,');
       dbms_output.put_line(' and (' || (round(:closed_error/:total_error,2)*100) || '%)  are closed.<BR><BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Since some of these errors have occured recently, it is recommended to first ensure that the issue is resolved and is no longer raising ');
       dbms_output.put_line('system generated Error notifications.<br> Next, follow the note below for steps to easily remove these system generated error notifications.<br><br> ');
       dbms_output.put_line('<B>Note:</B> For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1587923.1" target="_blank">Note 1587923.1</a>');
       dbms_output.put_line('- How to Close and Purge excessive WFERROR workflows and DEFAULT_EVENT_ERROR notifications from Workflow.<br><br>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');
		
	end if;
	
else 
       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Well Done !!</B><BR><BR>');
       dbms_output.put_line('There are ZERO OPEN system generated Workflow Error Notifications (DEFAULT_EVENT_%_ERROR) !<br> ');
       dbms_output.put_line('You deserve a whole cake!!!<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

       
end if;      
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
   
   
prompt <script type="text/javascript">    function displayRows2sql3(){var row = document.getElementById("s2sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=7 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Summary of Error Message Recipients (WFERROR, POERROR, OMERROR, ECXERROR)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="8" height="85">
prompt       <blockquote><p align="left">
prompt          select r.name, r.display_name, r.status, r.notification_preference, r.email_address, n.message_type,<br>
prompt          count(n.notification_id) COUNT, decode(to_char(n.end_date), null, 'OPEN', 'CLOSED') OPEN<br>
prompt          from wf_local_roles r, wf_notifications n<br>
prompt          where r.name in (select distinct n.recipient_role from wf_notifications where n.message_type like '%ERROR')<br>
prompt          and r.name = n.recipient_role<br>
prompt          group by r.name, r.display_name, r.status, r.notification_preference, r.email_address, n.message_type, decode(to_char(n.end_date), null, 'OPEN', 'CLOSED')<br>
prompt          order by count(n.notification_id) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PREFERENCE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EMAIL</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OPEN</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||r.name||'</TD>'||chr(10)|| 
'<TD>'||r.display_name||'</TD>'||chr(10)||
'<TD>'||r.status||'</TD>'||chr(10)||
'<TD>'||r.notification_preference||'</TD>'||chr(10)||
'<TD>'||r.email_address||'</TD>'||chr(10)||
'<TD>'||n.message_type||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(n.notification_id),'999,999,999,999')||'</div></TD>'||chr(10)|| 
'<TD><div align="center">'||decode(to_char(n.end_date), null, 'OPEN', 'CLOSED')||'</div></TD></TR>'
from wf_local_roles r, wf_notifications n
where r.name in (select distinct n.recipient_role from wf_notifications where n.message_type like '%ERROR')
and r.name = n.recipient_role
group by r.name, r.display_name, r.status, r.notification_preference, r.email_address, n.message_type, decode(to_char(n.end_date), null, 'OPEN', 'CLOSED')
order by count(n.notification_id) desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* WorkList Access for SYSADMIN *******
REM

prompt <a name="wfadv122"></a><B><U>SYSADMIN Worklist Access</B></U><BR>
prompt <blockquote>

prompt The Oracle Workflow Advanced Worklist allows you to grant access to your worklist to another user. <BR>
prompt That user can then act as your proxy to handle the notifications in your list on your behalf. 
prompt You can either grant a user access for a specific period or allow the user’s access to continue indefinitely.
prompt The worklist access feature lets you allow another user to handle your notifications 
prompt without giving that user access to any other privileges or responsibilities that you have in Oracle Applications.<BR>
prompt <BR>
prompt To access other worklists granted to you, simply switch the Advanced Worklist to display the user’s notifications instead of your own.<BR> 
prompt When viewing another user’s worklist, you can perform the following actions:<BR>
prompt - View the details of the user’s notifications.<BR>
prompt - Respond to notifications that require a response.<BR>
prompt - Close notifications that do not require a response.<BR>
prompt - Reassign notifications to a different user.<BR><BR>
prompt Below we verify who has been granted WorkList Access to the SYSADMIN Role in order to respond to error notifications.
prompt <BR><BR>


prompt <script type="text/javascript">    function displayRows2sql2(){var row = document.getElementById("s2sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=5 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>SYSADMIN WorkList Access</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="6" height="85">
prompt       <blockquote><p align="left">
prompt          select parameter1, grantee_key, start_date,<br>
prompt          end_date, parameter2, instance_pk1_value<br>
prompt          FROM fnd_grants<br>
prompt          WHERE program_name = 'WORKFLOW_UI'<br>
prompt          AND parameter1 = 'SYSADMIN';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>GRANTOR</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>GRANTEE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>START DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>END DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACCESSIBLE ITEMS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||parameter1||'</TD>'||chr(10)|| 
'<TD>'||grantee_key||'</TD>'||chr(10)|| 
'<TD>'||start_date||'</TD>'||chr(10)|| 
'<TD>'||end_date||'</TD>'||chr(10)|| 
'<TD>'||parameter2||'</TD>'||chr(10)|| 
'<TD>'||instance_pk1_value||'</TD></TR>'
FROM fnd_grants
WHERE program_name = 'WORKFLOW_UI'
AND parameter1 = 'SYSADMIN';
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Routing Rules for SYSADMIN *******
REM

prompt <a name="wfrouting"></a><B><U>SYSADMIN Notification Routing Rules</B></U><BR>
prompt <blockquote>

prompt The Oracle Workflow Advanced Worklist provides an overview of all SYSADMIN notifications, from which one can drill down to :<BR>
prompt - View individual notifications<BR>
prompt - Reassign notifications to another user, <BR>
prompt - Request more information about a notification from another user, <BR>
prompt - Respond to requests for information, and <BR>
prompt - Define (Vacation) Routing Rules to handle notifications automatically in your absence.<BR>
prompt <BR>
prompt For companies that restrict access to the SYSADMIN user role, or do not assign a valid email address that multiple people can access, 
prompt then assigning routing rules to manage SYSADMIN notifications automatically  is a good idea.
prompt Oracle Workflow Vacation Routing Rules allows a user or administrator to define rules to perform the following actions automatically when a notification arrives:<BR>
prompt - Reassign the notification to another user<BR>
prompt - Respond to the notification with a predefined response, <BR>
prompt - Close a notification that does not require a response<BR>
prompt - Deliver the notification to SYSADMIN worklist as usual, with no further action<BR>
prompt <BR>
prompt The Vacation Rules page can be used to define rules for automatic notification processing, or the Workflow Administrator can also define rules for other users.<BR>
prompt Below we verify any Routing Rules defined for the SYSADMIN Role in order to respond to error notifications.
prompt <BR><BR>


prompt <script type="text/javascript">    function displayRows2sql2a(){var row = document.getElementById("s2sql2a");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>SYSADMIN Notification Routing Rules</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql2a()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql2a" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="85">
prompt       <blockquote><p align="left">
prompt          SELECT wrr.RULE_ID, wrr.ROLE, r.DESCRIPTION, wrr.ACTION, <br>
prompt          wrr.ACTION_ARGUMENT "TO", wrr.MESSAGE_TYPE, wrr.MESSAGE_NAME, <br>
prompt          wrr.BEGIN_DATE, wrr.END_DATE, wrr.RULE_COMMENT<br>
prompt          FROM WF_ROUTING_RULES wrr, wf_local_roles r<br>
prompt          WHERE wrr.ROLE = r.NAME<br>
prompt          and wrr.role = 'SYSADMIN';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RULE_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ROLE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DESCRIPTION</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTION</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TO</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE_TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BEGIN_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>END_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RULE_COMMENT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||wrr.RULE_ID||'</TD>'||chr(10)|| 
'<TD>'||wrr.ROLE||'</TD>'||chr(10)|| 
'<TD>'||r.DESCRIPTION||'</TD>'||chr(10)|| 
'<TD>'||wrr.ACTION||'</TD>'||chr(10)|| 
'<TD>'||wrr.ACTION_ARGUMENT||'</TD>'||chr(10)|| 
'<TD>'||wrr.MESSAGE_TYPE||'</TD>'||chr(10)|| 
'<TD>'||wrr.MESSAGE_NAME||'</TD>'||chr(10)|| 
'<TD>'||wrr.BEGIN_DATE||'</TD>'||chr(10)|| 
'<TD>'||wrr.END_DATE||'</TD>'||chr(10)||
'<TD>'||wrr.RULE_COMMENT||'</TD></TR>'
FROM WF_ROUTING_RULES wrr, wf_local_roles r
WHERE wrr.ROLE = r.NAME
and wrr.role = 'SYSADMIN';
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* E-Business Suite Profile Settings *******
REM

prompt <a name="ebsprofile"></a><B><U>E-Business Suite Profile Settings</B></U><BR>
prompt <blockquote>

prompt <script>
prompt         $(function(){
prompt           $("#ProfileOpts").tablesorter({sortList: [[3,0]] }); // sorts 3rd column in descending order, then 2nd column asc
prompt         });
prompt </script>

prompt <script type="text/javascript">    function displayRows2sql4(){var row = document.getElementById("s2sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2" width="100%">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=5 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>E-Business Suite Profile Settings <i>(Default SORT is by NTF_STATUS asc)</i></B></font><br>
prompt     <font color="#FF0000"><i><b>TIP! </b></font>Sort multiple columns simultaneously by holding down the shift key and clicking a second, third or even fourth column header!</i></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="6" height="125">
prompt       <blockquote><p align="left">
prompt          select t.PROFILE_OPTION_ID, t.PROFILE_OPTION_NAME, z.language, z.USER_PROFILE_OPTION_NAME,<br>
prompt          v.PROFILE_OPTION_VALUE, z.DESCRIPTION<br>
prompt          from fnd_profile_options t, fnd_profile_option_values v, fnd_profile_options_tl z<br>
prompt          where (v.PROFILE_OPTION_ID (+) = t.PROFILE_OPTION_ID)<br>
prompt          and (v.level_id = 10001)<br>
prompt          and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)<br>
prompt          and (t.PROFILE_OPTION_NAME in ('CONC_GSM_ENABLED','WF_VALIDATE_NTF_ACCESS','GUEST_USER_PWD',<br>
prompt          'AFLOG_ENABLED','AFLOG_FILENAME','AFLOG_LEVEL','AFLOG_BUFFER_MODE','AFLOG_MODULE','FND_FWK_COMPATIBILITY_MODE',<br>
prompt          'FND_VALIDATION_LEVEL','FND_MIGRATED_TO_JRAD','AMPOOL_ENABLED',<br>
prompt          'FND_NTF_REASSIGN_MODE','WF_ROUTE_RULE_ALLOW_ALL'))<br>
prompt          order by z.USER_PROFILE_OPTION_NAME;</p>
prompt       </blockquote>
prompt </TD></TR></TABLE>
prompt <TABLE id="ProfileOpts" class="tablesorter" border="1" cellspacing="0" cellpadding="2">
prompt <THEAD>
prompt   <TR>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>ID</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>PROFILE_OPTION_NAME</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>LANGUAGE</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>PROFILE</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TH>
prompt <TH BGCOLOR=#DEE6EF><font face="Calibri"><B>DESCRIPTION</B></TH>
prompt   </TR>
prompt </THEAD>
prompt <TBODY>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||t.PROFILE_OPTION_ID||'</TD>'||chr(10)|| 
'<TD>'||t.PROFILE_OPTION_NAME||'</TD>'||chr(10)|| 
'<TD>'||z.language||'</TD>'||chr(10)|| 
'<TD>'||z.USER_PROFILE_OPTION_NAME||'</TD>'||chr(10)|| 
'<TD>'||v.PROFILE_OPTION_VALUE||'</TD>'||chr(10)|| 
'<TD>'||z.DESCRIPTION||'</TD></TR>'
from fnd_profile_options t, fnd_profile_option_values v, fnd_profile_options_tl z
where (v.PROFILE_OPTION_ID (+) = t.PROFILE_OPTION_ID)
and (v.level_id = 10001)
and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)
and (t.PROFILE_OPTION_NAME in ('CONC_GSM_ENABLED','WF_VALIDATE_NTF_ACCESS','GUEST_USER_PWD','AFLOG_ENABLED','AFLOG_FILENAME','AFLOG_LEVEL','AFLOG_BUFFER_MODE','AFLOG_MODULE','FND_FWK_COMPATIBILITY_MODE',
'FND_VALIDATION_LEVEL','FND_MIGRATED_TO_JRAD','AMPOOL_ENABLED',
'FND_NTF_REASSIGN_MODE','WF_ROUTE_RULE_ALLOW_ALL'));
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


begin

 select v.PROFILE_OPTION_VALUE into :gsm 
   from fnd_profile_option_values v, fnd_profile_options p
  where v.PROFILE_OPTION_ID = p.PROFILE_OPTION_ID
    and p.PROFILE_OPTION_NAME = 'CONC_GSM_ENABLED'
    and sysdate BETWEEN p.start_date_active 
    and NVL(p.end_date_active, sysdate);

if (:gsm = 'Y') then

    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>The Profile "Concurrent:GSM Enabled" is enabled as expected.</B><BR>');
    dbms_output.put_line('This profile is currently set to Y, allows the GSM (Generic Services Manager) to enable running workflows.<BR>'); 
    dbms_output.put_line('This is expected as GSM must be enabled in order to process workflow.<BR>');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1191125.1#mozTocId991385"');
    dbms_output.put_line('target="_blank">Note 1191125.1</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	
  elsif (:gsm = 'N') then

    dbms_output.put_line('<table border="1" name="RedBox" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Error:<BR>');
    dbms_output.put_line('The EBS profile "Concurrent:GSM Enabled" is not enabled.</B><BR><BR>');
    dbms_output.put_line('<B>Action:</B><BR>');
    dbms_output.put_line('Please enable profile "Concurrent:GSM Enabled" to Y to allow GSM to enable running workflows.<BR>'); 
    dbms_output.put_line('GSM must be enabled to process workflow.<BR>');
    dbms_output.put_line('Once GSM has started, verify Workflow Services started via OAM.<BR>');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1191125.1#mozTocId991385"');
    dbms_output.put_line('target="_blank">Note 1191125.1</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

  else 

    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('      <p><B>Note:</B> It is unclear what EBS profile "Concurrent:GSM Enabled" is set to.');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1191125.1#mozTocId991385"');
    dbms_output.put_line('target="_blank">Note 1191125.1</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');

end if;
 
end;
/

REM
REM ******* Workflow Profile Settings *******
REM

prompt <script type="text/javascript">    function displayRows2sql5(){var row = document.getElementById("s2sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfprofile"></a>
prompt     <B>Workflow Profile Settings</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="85">
prompt       <blockquote><p align="left">
prompt          select t.PROFILE_OPTION_ID, t.PROFILE_OPTION_NAME, z.USER_PROFILE_OPTION_NAME,<br>
prompt          nvl(v.PROFILE_OPTION_VALUE,'NOT SET - Replace with specific Web Server URL (non-virtual) if using load balancers')<br>
prompt          from fnd_profile_options t, fnd_profile_option_values v, fnd_profile_options_tl z<br>
prompt          where (v.PROFILE_OPTION_ID (+) = t.PROFILE_OPTION_ID)<br>
prompt          and ((v.level_id = 10001) or (v.level_id is null))<br>
prompt          and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)<br>                
prompt          and (t.PROFILE_OPTION_NAME in ('APPS_FRAMEWORK_AGENT','WF_MAIL_WEB_AGENT'));</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROFILE_OPTION_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROFILE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||t.PROFILE_OPTION_ID||'</TD>'||chr(10)|| 
'<TD>'||t.PROFILE_OPTION_NAME||'</TD>'||chr(10)|| 
'<TD>'||z.USER_PROFILE_OPTION_NAME||'</TD>'||chr(10)|| 
'<TD>'||nvl(v.PROFILE_OPTION_VALUE,'NOT SET - Replace with specific Web Server URL (non-virtual) if using load balancers and reference <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=339718.1#loadbalanced" target="_blank">Note 339718.1</a>, Section 4.C')||'</TD></TR>'
from fnd_profile_options t, fnd_profile_option_values v, fnd_profile_options_tl z
where (v.PROFILE_OPTION_ID (+) = t.PROFILE_OPTION_ID)
and ((v.level_id = 10001) or (v.level_id is null))
and (z.PROFILE_OPTION_NAME = t.PROFILE_OPTION_NAME)
and (t.PROFILE_OPTION_NAME in ('APPS_FRAMEWORK_AGENT','WF_MAIL_WEB_AGENT'));
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Verify #STUCK Activities *******
REM

prompt <a name="wfstuck"></a><B><U>STUCK Activities</B></U><BR>
prompt <blockquote>

prompt A process is identified as stuck when it has a status of ACTIVE, but cannot progress any further. 
prompt Stuck activities do not have a clear pattern as cause but mainly they are caused by flaws in the WF definition like improper transition definitions.
prompt For example, a process could become stuck in the following situations:<BR>
prompt - A thread within a process leads to an activity that is not defined as an End activity
prompt but has no other activity modeled after it, and no other activity is active.<BR>
prompt - A process with only one thread loops back, but the pivot activity of the loop has
prompt the On Revisit property set to Ignore.<BR>
prompt - An activity returns a result for which no eligible transition exists. <BR>
prompt For instance, if the function for a function activity returns an unexpected result value, and no default transition is modeled after that activity, the process cannot continue.  
prompt <BR><BR>
prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td><font size="+1">
prompt <B>STUCK Activities:</B></font><BR><BR>
prompt <B>COMMON MISCONCEPTION for STUCK Activities: Running the Worklfow Background Process for STUCK activities fixes STUCK workflows.</B><BR>
prompt Not true.<BR>
prompt Running the concurrent request "Workflow Background Process" with Stuck=Yes only identifies these activities that cannot progress.
prompt The workflow engine changes the status of a stuck process to ERROR:#STUCK and executes the error process defined for it.
prompt This error process sends a notification to SYSADMIN to alert them of this issue, which they need to resolve.
prompt <b>The query to determine these activities is very expensive</b> as it joins 3 WF runtime tables and one WF design table. 
prompt This is why the Workflow Background Engine should run seperately when load is not high and only once a week or month.<BR> 
prompt <p>For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1" 
prompt target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br>
prompt </td></tr></tbody></table><BR>

prompt <script type="text/javascript">    function displayRows2sql7(){var row = document.getElementById("s2sql7");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=6 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Verify #STUCK Activities</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql7" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="7" height="85">
prompt       <blockquote><p align="left">
prompt          Select P.Process_Item_Type, P.Activity_Name, S.Activity_Status, S.Activity_Result_Code, <br>
prompt                 Nvl(To_Char(Wi.End_Date,'YYYY'),'OPEN') Wf_Status, To_Char(S.Begin_Date, 'YYYY') Began, Count(S.Item_Key)<br>
prompt            FROM wf_item_activity_statuses s,wf_process_activities p, wf_items wi<br>
prompt           WHERE P.Instance_Id = S.Process_Activity<br>
prompt             AND Wi.Item_Type = S.Item_Type<br>
prompt             AND wi.item_key = s.item_key<br>
prompt             AND activity_status = 'ERROR'<br>
prompt             AND activity_result_code = '#STUCK'<br>
prompt             AND S.End_Date Is Null<br>
prompt        GROUP BY P.Process_Item_Type, P.Activity_Name, S.Activity_Status, S.Activity_Result_Code, <br>
prompt                 to_char(wi.end_date,'YYYY'), To_Char(S.Begin_Date, 'YYYY')<br>
prompt        ORDER BY to_char(wi.end_date,'YYYY') desc, To_Char(S.Begin_Date, 'YYYY');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVITY</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVITY_RESULT_CODE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>WF STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BEGAN</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||p.PROCESS_ITEM_TYPE||'</TD>'||chr(10)|| 
'<TD>'||p.ACTIVITY_NAME||'</TD>'||chr(10)|| 
'<TD>'||s.ACTIVITY_STATUS||'</TD>'||chr(10)|| 
'<TD>'||s.ACTIVITY_RESULT_CODE||'</TD>'||chr(10)||
'<TD>'||Nvl(To_Char(Wi.End_Date,'YYYY'),'OPEN')||'</TD>'||chr(10)||
'<TD>'||To_Char(S.Begin_Date, 'YYYY')||'</TD>'||chr(10)||
'<TD><div align="right">'||to_char(count(s.ITEM_KEY),'999,999,999,999')||'</div></TD></TR>'
FROM wf_item_activity_statuses s,wf_process_activities p, wf_items wi
Where P.Instance_Id = S.Process_Activity
And Wi.Item_Type = S.Item_Type
and wi.item_key = s.item_key
AND activity_status = 'ERROR'
AND activity_result_code = '#STUCK'
And S.End_Date Is Null
Group By P.Process_Item_Type, P.Activity_Name, S.Activity_Status, S.Activity_Result_Code, 
to_char(wi.end_date,'YYYY'), To_Char(S.Begin_Date, 'YYYY')
ORDER BY to_char(wi.end_date,'YYYY') desc, To_Char(S.Begin_Date, 'YYYY');
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');



begin

select count(s.item_key) into :stuck_cnt
  FROM wf_item_activity_statuses s,wf_process_activities p
WHERE p.instance_id = s.process_activity
   and s.activity_status = 'ERROR'
   AND s.activity_result_code = '#STUCK'
   and s.end_date is null;


if (:stuck_cnt = 0) then

    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Nice work!!<BR>');
    dbms_output.put_line('There are ZERO #STUCK Activities found.</B><BR><BR>');
    dbms_output.put_line('For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1" ');
    dbms_output.put_line('target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');
   
  elsif (:stuck_cnt < 50) then

    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Warning:<BR>');
    dbms_output.put_line('There are '||:stuck_cnt||' #STUCK activities found that are still open!</B><br><br>');
    dbms_output.put_line('These workflows will not progress or complete on their own. It is recommended that these are looked into....<br>');
    dbms_output.put_line('Look for patterns in the same item_type, looking for the same wf_process_activities, date ranges, and check the root_activity_version for any patterns.<br>');
    dbms_output.put_line('Run the following query for more details about these ERROR #STUCK processes<br>');
    dbms_output.put_line('<blockquote><i>select p.PROCESS_ITEM_TYPE, wi.ITEM_KEY, p.ACTIVITY_NAME, s.ACTIVITY_STATUS, <br>');
    dbms_output.put_line('s.ACTIVITY_RESULT_CODE, wi.root_activity, wi.root_activity_version, wi.begin_date<br>');
    dbms_output.put_line('FROM wf_item_activity_statuses s,wf_process_activities p, wf_items wi<br>');
    dbms_output.put_line('WHERE p.instance_id = s.process_activity<br>');
    dbms_output.put_line('and wi.item_type = s.item_type<br>');
    dbms_output.put_line('and wi.item_key = s.item_key<br>');
    dbms_output.put_line('and activity_status = \''ERROR\''<br>');
    dbms_output.put_line('and activity_result_code = \''#STUCK\''<br>');
    dbms_output.put_line('order by wi.begin_date;</i></blockquote>');
    dbms_output.put_line('For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1#wfsysad" ');
    dbms_output.put_line('target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>'); 

  else 

    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Attention:<br>');
    dbms_output.put_line('There are '||to_char((:stuck_cnt),'999,999,999,999')||' #STUCK activities found that are still open!</B><br><br>');
    dbms_output.put_line('These workflows will not progress or complete on their own. It is recommended that these are looked into....<br>');
    dbms_output.put_line('Look for patterns in the same item_type, looking for the same wf_process_activities, date ranges, and check the root_activity_version for any patterns.<br>');
    dbms_output.put_line('Run the following query for more details about these ERROR #STUCK processes<br>');
    dbms_output.put_line('<blockquote><i>select p.PROCESS_ITEM_TYPE, wi.ITEM_KEY, p.ACTIVITY_NAME, s.ACTIVITY_STATUS, <br>');
    dbms_output.put_line('s.ACTIVITY_RESULT_CODE, wi.root_activity, wi.root_activity_version, wi.begin_date<br>');
    dbms_output.put_line('FROM wf_item_activity_statuses s,wf_process_activities p, wf_items wi<br>');
    dbms_output.put_line('WHERE p.instance_id = s.process_activity<br>');
    dbms_output.put_line('and wi.item_type = s.item_type<br>');
    dbms_output.put_line('and wi.item_key = s.item_key<br>');
    dbms_output.put_line('and activity_status = \''ERROR\''<br>');
    dbms_output.put_line('and activity_result_code = \''#STUCK\''<br>');
    dbms_output.put_line('order by wi.begin_date;</i></blockquote>');
    dbms_output.put_line('For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1#wfsysad" ');
    dbms_output.put_line('target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>'); 

    
end if;
 
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* DISABLED Notification Preferences *******
REM

prompt <a name="wfadv125"></a><B><U>Check for DISABLED Notification Preferences</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows2sql8b(){var row = document.getElementById("s2sql8b");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Totals for User Notification Preferences</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql8b()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql8b" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="50">
prompt       <blockquote><p align="left">
prompt          select notification_preference, count(name)<br>
prompt          from wf_local_roles<br>
prompt          where name not like 'FND_RESP%'<br>
prompt          and user_flag = 'Y'<br>
prompt          group by notification_preference;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>NOTIFICATION PREFERENCE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||notification_preference||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(name),'999,999,999,999')||'</div></TD></TR>'
from wf_local_roles
where name not like 'FND_RESP%'
and user_flag = 'Y'
group by notification_preference;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

 select count(name) into :user_cnt_disabled 
   from wf_local_roles
  where notification_preference = 'DISABLED'
  and user_flag = 'Y';
	
  if (:apps_rel < '12.2') then
  
  
	if (:user_cnt_disabled = 0) then

		dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Nice work!!<BR>');
		dbms_output.put_line('There are ZERO Users with DISABLED notification preferences.</B><BR><BR>');
		dbms_output.put_line('Please review : Workflow Notification Email Preference is Disabled: How to Troubleshoot and Repair <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1326359.1"');
		dbms_output.put_line('target="_blank">Note 1326359.1</a>, for more information on how to troubleshoot Workflow email notification preferences.<BR>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	   
	  elsif (:user_cnt_disabled > 50) then

    		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Warning:<BR>');
		dbms_output.put_line('There are a large number of Users with DISABLED notification preferences!</B><br>');
		dbms_output.put_line('<br>It is recommended that these are looked into....<br>');
		dbms_output.put_line('Please verify the email addresses for the '||to_char((:user_cnt_disabled),'999,999,999,999')||' Users that have DISABLED notification preference using : ');
		dbms_output.put_line('   <blockquote><i>select name, display_name, description, status, <br>');
		dbms_output.put_line('   orig_system, email_address, notification_preference<br>');
		dbms_output.put_line('   from wf_local_roles<br>');
		dbms_output.put_line('   where notification_preference = \''DISABLED\''<br>');
		dbms_output.put_line('   and user_flag = \''Y\'';</i></blockquote>');
		dbms_output.put_line('Please review : Workflow Notification Email Preference is Disabled: How to Troubleshoot and Repair <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1326359.1"');
		dbms_output.put_line('target="_blank">Note 1326359.1</a>, for information on how to correct and reset these settings if needed.<BR>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>'); 
		
	  else 

		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Attention:<br>');
		dbms_output.put_line('There are '||to_char((:user_cnt_disabled),'999,999,999,999')||' Users that have thier email notification preference set to DISABLED.</B><br>');
		dbms_output.put_line('This may be done by the users on purpose, or by the system because of a problem with a bad email address.<br>');
		dbms_output.put_line('<br>It is recommended to verify all the email addresses for these '||to_char((:user_cnt_disabled),'999,999,999,999')||' Users that have DISABLED notification preference using : <br>');
		dbms_output.put_line('   <blockquote><i>select name, display_name, description, status, <br>');
		dbms_output.put_line('   orig_system, email_address, notification_preference<br>');
		dbms_output.put_line('   from wf_local_roles<br>');
		dbms_output.put_line('   where notification_preference = \''DISABLED\''<br>');
		dbms_output.put_line('   and user_flag = \''Y\'';</i></blockquote>');    
		dbms_output.put_line('Please review : Workflow Notification Email Preference is Disabled: How to Troubleshoot and Repair <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1326359.1"');
		dbms_output.put_line('target="_blank">Note 1326359.1</a>, for information on how to correct and reset these settings if needed.<BR>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>');  
    
	end if;
	
	elsif  (:apps_rel >= '12.2')  then
		
		if (:user_cnt_disabled = 0) then

		dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Nice work!!<BR>');
		dbms_output.put_line('There are ZERO Users with DISABLED notification preferences.</B><BR><BR>');
		dbms_output.put_line('Please review : Workflow Notification Email Preference is Disabled: How to Troubleshoot and Repair <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1326359.1"');
		dbms_output.put_line('target="_blank">Note 1326359.1</a>, for more information on how to troubleshoot Workflow email notification preferences.<BR>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	   
	    elsif (:user_cnt_disabled > 50) then

    		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');		
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Warning:<BR>');
		dbms_output.put_line('There are a large number of Users with DISABLED notification preferences!</B><br>');
		dbms_output.put_line('<br>It is recommended that these are looked into....<br>');
		dbms_output.put_line('Please verify the email addresses for the '||to_char((:user_cnt_disabled),'999,999,999,999')||' Users that have DISABLED notification preference using : ');
		dbms_output.put_line('   <blockquote><i>select name, display_name, description, status, <br>');
		dbms_output.put_line('   orig_system, email_address, notification_preference<br>');
		dbms_output.put_line('   from wf_local_roles<br>');
		dbms_output.put_line('   where notification_preference = "DISABLED"<br>');
		dbms_output.put_line('   and user_flag = "Y";</i></blockquote>');
		dbms_output.put_line('For R12.2+ there is a new Concurrent program "Workflow Directory Services Bulk Reset DISABLED Notification Preference" (FNDWFBULKRESETNTFPREF).<br>');
		dbms_output.put_line('This program lets you reset the notification preference from DISABLED back to the original value for multiple users at once.<br>');
		dbms_output.put_line('Please review : Workflow Notification Email Preference is Disabled: How to Troubleshoot and Repair <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1326359.1"');
		dbms_output.put_line('target="_blank">Note 1326359.1</a>, for information on how to correct and reset these settings if needed.<BR>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>'); 
		
	    else 

		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Attention:<br>');
		dbms_output.put_line('There are '||to_char((:user_cnt_disabled),'999,999,999,999')||' Users that have thier email notification preference set to DISABLED.</B><br>');
		dbms_output.put_line('This may be done by the users on purpose, or by the system because of a problem with a bad email address.<br>');
		dbms_output.put_line('<br>It is recommended to verify all the email addresses for these '||to_char((:user_cnt_disabled),'999,999,999,999')||' Users that have DISABLED notification preference using : <br>');
		dbms_output.put_line('   <blockquote><i>select name, display_name, description, status, <br>');
		dbms_output.put_line('   orig_system, email_address, notification_preference<br>');
		dbms_output.put_line('   from wf_local_roles<br>');
		dbms_output.put_line('   where notification_preference = "DISABLED"<br>');
		dbms_output.put_line('   and user_flag = "Y";</i></blockquote>');    
		dbms_output.put_line('For R12.2+ there is a new Concurrent program "Workflow Directory Services Bulk Reset DISABLED Notification Preference" (FNDWFBULKRESETNTFPREF).<br>');
		dbms_output.put_line('This program lets you reset the notification preference from DISABLED back to the original value for multiple users at once.<br>');
		dbms_output.put_line('Please review : Workflow Notification Email Preference is Disabled: How to Troubleshoot and Repair <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1326359.1"');
		dbms_output.put_line('target="_blank">Note 1326359.1</a>, for information on how to correct and reset these settings if needed.<BR>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>');  
		
		end if;
end if; 
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Check the Status of Workflow Services *******
REM

prompt <a name="wfadv126"></a><B><U>Workflow Services Status</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows2sql9(){var row = document.getElementById("s2sql9");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Check the Status of Workflow Services</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql9()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s2sql9" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="11" height="130">
prompt       <blockquote><p align="left">
prompt          select fcq.USER_CONCURRENT_QUEUE_NAME, fsc.COMPONENT_NAME,<br>
prompt          DECODE(fcp.OS_PROCESS_ID,NULL,'Not Running',fcp.OS_PROCESS_ID), fcq.MAX_PROCESSES,<br>
prompt          fcq.RUNNING_PROCESSES, v.PARAMETER_VALUE, fcq.ENABLED_FLAG, fsc.COMPONENT_ID,<br>
prompt          fsc.CORRELATION_ID, fsc.STARTUP_MODE, fsc.COMPONENT_STATUS<br>
prompt          from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, <br>
prompt          APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v<br>
prompt          where v.COMPONENT_ID=fsc.COMPONENT_ID<br>
prompt          and fcq.MANAGER_TYPE = fcs.SERVICE_ID <br>
prompt          and fcs.SERVICE_HANDLE = 'FNDCPGSC' <br>
prompt          and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)<br>
prompt          and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+)<br> 
prompt          and fcq.application_id = fcp.queue_application_id(+) <br>
prompt          and fcp.process_status_code(+) = 'A'<br>
prompt          and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'<br>
prompt          order by fcp.OS_PROCESS_ID, fsc.STARTUP_MODE;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONTAINER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROCID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TARGET</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTUAL</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>#THREADS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ENABLED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CORRELATION_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTUP_MODE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||fcq.USER_CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_NAME||'</TD>'||chr(10)|| 
'<TD><div align="center">'||DECODE(fcp.OS_PROCESS_ID,NULL,'Not Running',fcp.OS_PROCESS_ID)||'</TD>'||chr(10)|| 
'<TD><div align="center">'||fcq.MAX_PROCESSES||'</div></TD>'||chr(10)|| 
'<TD><div align="center">'||fcq.RUNNING_PROCESSES||'</div></TD>'||chr(10)|| 
'<TD><div align="center">'||v.PARAMETER_VALUE||'</div></TD>'||chr(10)|| 
'<TD><div align="center">'||fcq.ENABLED_FLAG||'</div></TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_ID||'</TD>'||chr(10)|| 
'<TD>'||fsc.CORRELATION_ID||'</TD>'||chr(10)|| 
'<TD>'||fsc.STARTUP_MODE||'</TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_STATUS||'</TD></TR>'
from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
where v.COMPONENT_ID=fsc.COMPONENT_ID
and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
and fcq.application_id = fcp.queue_application_id(+) 
and fcp.process_status_code(+) = 'A'
and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
order by fcp.OS_PROCESS_ID, fsc.STARTUP_MODE;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>
prompt </blockquote>


REM **************************************************************************************** 
REM *******                   Section 3 : Workflow Footprint                         *******
REM ****************************************************************************************

prompt <a name="section3"></a><B><font size="+2">Workflow Footprint</font></B><BR><BR>
prompt <blockquote>


REM
REM ******* Check the Actual Table Size for Workflow  *******
REM

begin

	select round((blocks*8192/1024/1024),2) into :wfcmtphy
	from dba_tables 
	where table_name = 'WF_COMMENTS'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wfdigphy
	from dba_tables 
	where table_name = 'WF_DIG_SIGS'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wfitmphy
	from dba_tables 
	where table_name = 'WF_ITEMS'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wiasphy
	from dba_tables 
	where table_name = 'WF_ITEM_ACTIVITY_STATUSES'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wiashphy
	from dba_tables 
	where table_name = 'WF_ITEM_ACTIVITY_STATUSES_H'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wfattrphy
	from dba_tables 
	where table_name = 'WF_ITEM_ATTRIBUTE_VALUES'
	and owner = 'APPLSYS';

	select round((blocks*8192/1024/1024),2) into :wfntfphy
	from dba_tables 
	where table_name = 'WF_NOTIFICATIONS'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wfcmtphy2
	from dba_tables 
	where table_name = 'WF_COMMENTS'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wfdigphy2
	from dba_tables 
	where table_name = 'WF_DIG_SIGS'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wfitmphy2
	from dba_tables 
	where table_name = 'WF_ITEMS'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wiasphy2
	from dba_tables 
	where table_name = 'WF_ITEM_ACTIVITY_STATUSES'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wiashphy2
	from dba_tables 
	where table_name = 'WF_ITEM_ACTIVITY_STATUSES_H'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wfattrphy2
	from dba_tables 
	where table_name = 'WF_ITEM_ATTRIBUTE_VALUES'
	and owner = 'APPLSYS';

	select round((num_rows*AVG_ROW_LEN)/1024/1024,2) into :wfntfphy2
	from dba_tables 
	where table_name = 'WF_NOTIFICATIONS'
	and owner = 'APPLSYS';

end;
/

prompt <img src="https://chart.googleapis.com/chart?chxl=0:|WF_NOTIFICATIONS|WF_ITEM_ATTRIBUTE_VALUES|WF_ITEM_ACTIVITY_STATUSES_H|WF_ITEM_ACTIVITY_STATUSES|WF_ITEMS|WF_DIG_SIGS|WF_COMMENTS\&chdl=Logical_Data|Physical_Data\&chxs=0,676767,11.5,0,lt,676767\&chxtc=0,5\&chxt=y,x\&chds=a\&chs=600x425\&chma=0,0,0,5\&chbh=20,5,10\&cht=bhg
begin
  select '\&chd=t:'||:wfcmtphy||','||:wfdigphy||','||:wfitmphy||','||:wiasphy||','||:wiashphy||','||:wfattrphy||','||:wfntfphy||'\|'||:wfdigphy2||','||:wfitmphy2||','||:wiasphy2||','||:wiashphy2||','||:wfattrphy2||','||:wfntfphy2 into :test from dual;
  dbms_output.put('\&chco=A2C180,3D7930');
  dbms_output.put(''||:test||'');
  dbms_output.put('\&chtt=Workflow+Runtime+Data+Tables" />');
  dbms_output.put_line('<br><br>');
end;
/

begin

select to_char(sum(LOGICAL_TOTAL),'999,999,999,999') into :logical_totals  from (
select   round(blocks*8192/1024/1024) as "LOGICAL_TOTAL"
		from dba_tables 
                where table_name in ('WF_ITEMS','WF_ITEM_ACTIVITY_STATUSES','WF_ITEM_ACTIVITY_STATUSES_H',
                'WF_ITEM_ATTRIBUTE_VALUES','WF_NOTIFICATIONS','WF_COMMENTS','WF_DIG_SIGS')
                and owner = 'APPLSYS' );

select to_char(sum(PHYSICAL_TOTAL),'999,999,999,999') into :physical_totals  from ( 
select round((num_rows*AVG_ROW_LEN)/1024/1024) as "PHYSICAL_TOTAL"
		from dba_tables 
                where table_name in ('WF_ITEMS','WF_ITEM_ACTIVITY_STATUSES','WF_ITEM_ACTIVITY_STATUSES_H',
                'WF_ITEM_ATTRIBUTE_VALUES','WF_NOTIFICATIONS','WF_COMMENTS','WF_DIG_SIGS')
                and owner = 'APPLSYS' );

select to_char(sum(TOTAL_DIFF),'999,999,999,999') into :diff_totals  from ( 
select round((blocks*8192/1024/1024)-(num_rows*AVG_ROW_LEN)/1024/1024) as "TOTAL_DIFF" 
		from dba_tables 
                where table_name in ('WF_ITEMS','WF_ITEM_ACTIVITY_STATUSES','WF_ITEM_ACTIVITY_STATUSES_H',
                'WF_ITEM_ATTRIBUTE_VALUES','WF_NOTIFICATIONS','WF_COMMENTS','WF_DIG_SIGS')
                and owner = 'APPLSYS' ); 

if (:logical_totals>'0') then
	select ROUND(:diff_totals/:logical_totals,2)*100 into :rate from dual;
else
        :rate:=0;
end if;


select to_char(sum(COUNT),'999,999,999,999') into :ninety_totals from ( 
select  
to_char(wi.begin_date, 'YYYY') BEGAN,
to_char(count(wi.item_key)) COUNT
from wf_items wi, wf_item_types wit, wf_item_types_tl witt  
where wi.ITEM_TYPE=wit.NAME and wi.end_date is null  
and wit.NAME=witt.NAME and witt.language = 'US' and wi.begin_date < sysdate-90  
group by to_char(wi.begin_date, 'YYYY') 
order by to_char(wi.begin_date, 'YYYY'));

    if (:rate>29) then

        dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	dbms_output.put_line('<tbody><tr><td> ');
	dbms_output.put_line('<p><B>Attention:<BR>');
        dbms_output.put_line('The Workflow Runtime Tables logical space which is used for all full-table scans is ' || :rate || '% greater than the physical or actual tablespace being used.</B><BR>');
        dbms_output.put_line('It is recommended to have a DBA resize these tables to reset the HighWater Mark.<BR>');
        dbms_output.put_line('There are several ways to coalesce, drop, recreate these workflow runtime tables.<BR><BR> ');
	dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=388672.1" target="_blank">Note 388672.1');
	dbms_output.put_line('</a> - How to Reorganize Workflow Tables, for more details on ways to do this.');
	dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    else

	dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
	dbms_output.put_line('<tbody><tr><td> ');
	dbms_output.put_line('<p><B>Note:<BR>');
	dbms_output.put_line('The Workflow Runtime Tables logical space which is used for all full-table scans is only at ' || :rate || '% greater than the physical or actual tablespace being used.</B><BR>');
        dbms_output.put_line('It is recommended at levels above 30% to resize these tables to maintain or reset the table HighWater Mark for optimum performance.<br>');
        dbms_output.put_line('Please have a DBA monitor these tables going forward to ensure they are being maintained at optimal levels.<BR><BR>');
        dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=388672.1" target="_blank">Note 388672.1');
        dbms_output.put_line('</a> - How to Reorganize Workflow Tables, on how to manage workflow runtime tablespaces for optimal performance.<BR>');
	dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	
    end if;
    
end;
/


prompt <script type="text/javascript">    function displayRows3sql1(){var row = document.getElementById("s3sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv131"></a>
prompt     <B>Volume of Workflow Runtime Data Tables (in MegaBytes)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="130">
prompt       <blockquote><p align="left">
prompt          select table_name, <br>
prompt                   round(blocks*8192/1024/1024) "MB Logical", <br>
prompt                   round((num_rows*AVG_ROW_LEN)/1024/1024) "MB Physical", <br>
prompt                   round((blocks*8192/1024/1024)  - <br>
prompt                  (num_rows*AVG_ROW_LEN)/1024/1024) "MB Difference"<br>
prompt          from dba_tables <br>
prompt          where table_name in ('WF_ITEMS','WF_ITEM_ACTIVITY_STATUSES',<br>
prompt               'WF_ITEM_ACTIVITY_STATUSES_H','WF_ITEM_ATTRIBUTE_VALUES',<br>
prompt               'WF_NOTIFICATIONS','WF_COMMENTS','WF_DIG_SIGS')<br>
prompt          and owner = 'APPLSYS'<br>
prompt          order by table_name;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Workflow Table Name</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Logical Table Size</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Physical Table Data</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>Difference</B></TD></TR>
exec :n := dbms_utility.get_time;
select
'<TR><TD>'||table_name||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(round(blocks*8192/1024/1024),'999,999,999,999')||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(round((num_rows*AVG_ROW_LEN)/1024/1024),'999,999,999,999')||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(round((blocks*8192/1024/1024)-(num_rows*AVG_ROW_LEN)/1024/1024),'999,999,999,999')||'</div></TD></TR>'
from dba_tables
where table_name in ('WF_ITEMS','WF_ITEM_ACTIVITY_STATUSES','WF_ITEM_ACTIVITY_STATUSES_H',
                     'WF_ITEM_ATTRIBUTE_VALUES','WF_NOTIFICATIONS','WF_COMMENTS','WF_DIG_SIGS')
and owner='APPLSYS'
order by table_name;
prompt <TR><TD BGCOLOR=#DEE6EF align="right"><font face="Calibri"><B>TOTALS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF align="right"><font face="Calibri">
print :logical_totals
prompt </TD> 
prompt <TD BGCOLOR=#DEE6EF align="right"><font face="Calibri">
print :physical_totals
prompt </TD> 
prompt <TD BGCOLOR=#DEE6EF align="right"><font face="Calibri">
print :diff_totals
prompt </TD></TD></TR>
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

REM
REM ******* Verify Closed and Purgeable TEMP Items *******
REM

prompt <a name="wfadv132"></a><B><U>Verify Closed and Purgeable TEMP Items</B></U><BR>
prompt <blockquote>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td> 
prompt This table displays counts for ALL TEMPORARY persistence workflow item types that are closed... ie end_date is not null.<br>
prompt It also shows how many of these closed workflows are eligible for purging, meaning if you ran the Purge Obsolete Workflow Runtime Data (FNDWFPR) now REM for TEMP items, they will be purged.<br><br>
prompt If there are closed items that are not purgeable, (ie CLOSED ITEMS>PURGEABLE) then it may be because an associated child process is still open.<BR>
prompt To verify the end-dates of all workflows (item_keys) that are associated to a single workflow process, run the bde_wf_process_tree.sql<BR>
prompt script found in <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1378954.1" target="_blank">Document 1378954.1
prompt </a> - bde_wf_process_tree.sql - For REM analyzing the Root Parent, Children, Grandchildren Associations of a Single Workflow Process<BR>
prompt </p></td></tr></tbody></table><BR>

prompt <script type="text/javascript">    function displayRows3sql2(){var row = document.getElementById("s3sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Verify Closed and Purgeable TEMP Items</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="130">
prompt       <blockquote><p align="left">
prompt          select COUNT(A.ITEM_KEY), WF_PURGE.GETPURGEABLECOUNT(A.ITEM_TYPE),<br>
prompt          A.ITEM_TYPE, b.DISPLAY_NAME, b.PERSISTENCE_DAYS<br>
prompt          FROM  WF_ITEMS A, WF_ITEM_TYPES_VL B<br>
prompt          WHERE  A.ITEM_TYPE = B.NAME<br>
prompt          and b.PERSISTENCE_TYPE = 'TEMP'<br>
prompt          and a.END_DATE is not null<br>
prompt          GROUP BY A.ITEM_TYPE, b.DISPLAY_NAME, b.PERSISTENCE_DAYS<br>
prompt          order by 1 desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CLOSED ITEMS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PURGEABLE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE DAYS</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD><div align="right">'||to_char(COUNT(A.ITEM_KEY),'999,999,999,999')||'</div></TD>'||chr(10)|| 
'<TD><div align="left">'||to_char(WF_PURGE.GETPURGEABLECOUNT(A.ITEM_TYPE),'999,999,999,999')||'</div></TD>'||chr(10)|| 
'<TD>'||A.ITEM_TYPE||'</TD>'||chr(10)|| 
'<TD>'||b.DISPLAY_NAME||'</TD>'||chr(10)|| 
'<TD>'||b.PERSISTENCE_DAYS||'</TD></TR>'
FROM  WF_ITEMS A, WF_ITEM_TYPES_VL B       
WHERE  A.ITEM_TYPE = B.NAME       
and b.PERSISTENCE_TYPE = 'TEMP' 
and a.END_DATE is not null       
GROUP BY A.ITEM_TYPE, b.DISPLAY_NAME, b.PERSISTENCE_DAYS     
order by 1 desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


begin

select count(*) into :ATGRUP4
from AD_BUGS b 
where b.BUG_NUMBER = '4676589';

SELECT max(r.ACTUAL_COMPLETION_DATE) into :last_ran
FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u 
WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id 
and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
and c.CONCURRENT_PROGRAM_NAME in ('FNDWFWITSTATCC') 
AND p.language = 'US' 
And R.Actual_Completion_Date Is Not Null
Order By R.Actual_Completion_Date Desc;


if ((:apps_rel > '12.0') or (:ATGRUP4 > 0)) then 
	:ATGRUP4 := 1;
else
	:ATGRUP4 := 0; 
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><b>Attention:<br>');    
    dbms_output.put_line('11i.ATG_PF.H.RUP4 (Patch 4676589) is NOT applied, so the following table will fail as expected.</b><br>');
    dbms_output.put_line('This table queries WF_ITEM_TYPES for columns that are added after 11i.ATG_PF.H.RUP4 (Patch 4676589).<BR>');
    dbms_output.put_line('Please ignore this table and error.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table>');	
end if;

if (:last_ran is null) then 

    dbms_output.put_line('<table border="1" name="Notebox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('Post 11i.ATG.rup4+, there are 3 new Concurrent Programs designed to gather Workflow Statistics that is displayed in OAM Workflow Manager - Workflow Metrics screens.<BR>');
    dbms_output.put_line('These Concurrent Programs are set to run automatically every 24 hrs by default to refresh these workflow runtime table statistics.<BR>');
    dbms_output.put_line('<B> - Workflow Agent Activity Statistics (FNDWFAASTATCC)</B> - Gathers statistics for the Agent Activity graph in the Workflow System status page and for the agent activity list in the Agent Activity page.<BR>');
    dbms_output.put_line('<B> - Workflow Mailer Statistics (FNDWFMLRSTATCC)</B> - Gathers statistics for the throughput graph in the Notification Mailer Throughput page.<BR>');
    dbms_output.put_line('<B> - Workflow Work Items Statistics (FNDWFWITSTATCC)</B> - Gathers statistics for the Work Items graph in the Workflow System status page, for ');
    dbms_output.put_line('the Completed Work Items list in the Workflow Purge page, and for the work item lists in the Active Work Items, Deferred Work Items, Suspended Work Items, and Errored Work Items pages.<BR>');
    dbms_output.put_line('If the list above does not match the list below, then please run these Workflow Statistics requests again.<BR><br>');
    dbms_output.put_line('<b>Note: <br>There is not enough data to determine the last time FNDWFWITSTATCC was successfully run.</b><BR>');
    dbms_output.put_line('Perhaps the request has not been run in a long time or all recent data has been purged.<BR>');
    dbms_output.put_line('To refresh this data, please run the concurrent program Workflow Work Items Statistics (FNDWFWITSTATCC).<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

elsif (:last_ran < sysdate) then 

    dbms_output.put_line('<table border="1" name="Notebox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('Post 11i.ATG.rup4+, there are 3 new Concurrent Programs designed to gather Workflow Statistics that is displayed in OAM Workflow Manager - Workflow Metrics screens.<BR>');
    dbms_output.put_line('These Concurrent Programs are set to run automatically every 24 hrs by default to refresh these workflow runtime table statistics.<BR>');
    dbms_output.put_line('<B> - Workflow Agent Activity Statistics (FNDWFAASTATCC)</B> - Gathers statistics for the Agent Activity graph in the Workflow System status page and for the agent activity list in the Agent Activity page.<BR>');
    dbms_output.put_line('<B> - Workflow Mailer Statistics (FNDWFMLRSTATCC)</B> - Gathers statistics for the throughput graph in the Notification Mailer Throughput page.<BR>');
    dbms_output.put_line('<B> - Workflow Work Items Statistics (FNDWFWITSTATCC)</B> - Gathers statistics for the Work Items graph in the Workflow System status page, for ');
    dbms_output.put_line('the Completed Work Items list in the Workflow Purge page, and for the work item lists in the Active Work Items, Deferred Work Items, Suspended Work Items, and Errored Work Items pages.<BR><br>');
    dbms_output.put_line('<b>Note: <br>The concurrent program FNDWFWITSTATCC last ran on '||:last_ran||', which is how current the data is in this table as well as OAM Workflow Manager.<BR>');
    dbms_output.put_line('To refresh this data, please run the concurrent program Workflow Work Items Statistics (FNDWFWITSTATCC).</b><BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

else 

    dbms_output.put_line('There seems to be a problem determining the last time the concurrent program Workflow Work Items Statistics (FNDWFWITSTATCC) was ran.<BR>');

end if;

end;
/

REM
REM ******* WF_ITEM_TYPES *******
REM

prompt <script type="text/javascript">    function displayRows3sql3(){var row = document.getElementById("s3sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfsummry"></a>
prompt     <B>Summary of Workflow Processes By Item Type</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="150">
prompt       <blockquote><p align="left">
prompt          select NUM_ACTIVE, NUM_COMPLETE, NUM_PURGEABLE, WIT.NAME, DISPLAY_NAME, <br>
prompt          PERSISTENCE_TYPE, PERSISTENCE_DAYS, NUM_ERROR, NUM_DEFER, NUM_SUSPEND<br>
prompt          from wf_item_types wit, wf_item_types_tl wtl<br>
prompt          where wit.name like ('%')<br>
prompt          AND wtl.name = wit.name<br>
prompt          AND wtl.language = userenv('LANG')<br>
prompt          AND wit.NUM_ACTIVE is not NULL<br>
prompt          AND wit.NUM_ACTIVE <>0 <br>
prompt          order by PERSISTENCE_TYPE, NUM_COMPLETE desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPLETED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PURGEABLE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE_TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE_DAYS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ERRORED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DEFERRED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SUSPENDED</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD><div align="right">'||to_char(NUM_ACTIVE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_COMPLETE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="left">'||to_char(NUM_PURGEABLE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="left">'||WIT.NAME||'</div></TD>'||chr(10)||
'<TD><div align="left">'||DISPLAY_NAME||'</div></TD>'||chr(10)||
'<TD><div align="center">'||PERSISTENCE_TYPE||'</div></TD>'||chr(10)||
'<TD><div align="center">'||PERSISTENCE_DAYS||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_ERROR,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_DEFER,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_SUSPEND,'999,999,999,999')||'</div></TD></TR>'
from wf_item_types wit, wf_item_types_tl wtl
where wit.name like ('%')
AND wtl.name = wit.name
AND wtl.language = userenv('LANG')
AND wit.NUM_ACTIVE is not NULL
AND wit.NUM_ACTIVE <>0 
order by PERSISTENCE_TYPE, NUM_COMPLETE desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Check the Volume of Open and Closed Items Annually *******
REM

prompt <a name="wfadv133"></a><B><U>Check the Volume of Open and Closed Items Annually</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows3sql4(){var row = document.getElementById("s3sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=5 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Check the Volume of Open and Closed Items Annually</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="6" height="135">
prompt       <blockquote><p align="left">
prompt          select wi.item_type, witt.DISPLAY_NAME, wit.PERSISTENCE_TYPE,<br>
prompt          nvl(wit.PERSISTENCE_DAYS,0), nvl(to_char(wi.end_date, 'YYYY'),'OPEN'), count(wi.item_key)<br>
prompt          from wf_items wi, wf_item_types wit, wf_item_types_tl witt where wi.ITEM_TYPE=wit.NAME <br>
prompt          and wit.NAME=witt.NAME and witt.language = 'US'<br>
prompt          group by wi.item_type, witt.DISPLAY_NAME, wit.PERSISTENCE_TYPE, <br>
prompt          wit.PERSISTENCE_DAYS, to_char(wi.end_date, 'YYYY')<br>
prompt          order by wit.PERSISTENCE_TYPE asc, nvl(to_char(wi.end_date, 'YYYY'),'OPEN') asc, count(wi.item_key) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>P_DAYS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CLOSED</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD> 
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||wi.item_type||'</TD>'||chr(10)|| 
'<TD>'||witt.DISPLAY_NAME||'</TD>'||chr(10)|| 
'<TD>'||wit.PERSISTENCE_TYPE||'</TD>'||chr(10)|| 
'<TD>'||nvl(wit.PERSISTENCE_DAYS,0)||'</TD>'||chr(10)||
'<TD>'||nvl(to_char(wi.end_date, 'YYYY'),'OPEN')||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(wi.item_key),'999,999,999,999')||'</div></TD></TR>'
from wf_items wi, wf_item_types wit, wf_item_types_tl witt where wi.ITEM_TYPE=wit.NAME and wit.NAME=witt.NAME and witt.language = 'US'
group by wi.item_type, witt.DISPLAY_NAME, wit.PERSISTENCE_TYPE, 
wit.PERSISTENCE_DAYS, to_char(wi.end_date, 'YYYY')
order by wit.PERSISTENCE_TYPE asc, nvl(to_char(wi.end_date, 'YYYY'),'OPEN') asc, count(wi.item_key) desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');


prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Average Volume of Opened Items in the past 6 Months, Monthly, & Daily *******
REM

prompt <a name="wfadv134"></a><B><U>Average Volume of Opened Items in the past 6 Months, Monthly, and Daily</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows3sql5(){var row = document.getElementById("s3sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv134"></a>
prompt     <B>Average Volume of Opened Items in the past 6 Months, Monthly, and Daily</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="85">
prompt       <blockquote><p align="left">
prompt          select item_type, count(item_key), <br>
prompt          to_char(round(count(item_key)/6,0),'999,999,999,999'), to_char(round(count(item_key)/180,0),'999,999,999,999')<br>
prompt          from wf_items<br>
prompt          where begin_date > sysdate-180<br>
prompt          group by item_type<br>
prompt          order by count(item_key) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>6_MONTHS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MONTHLY</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DAILY</B></TD> 
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||item_type||'</TD>'||chr(10)|| 
'<TD>'||to_char(count(item_key),'999,999,999,999')||'</TD>'||chr(10)|| 
'<TD>'||to_char(round(count(item_key)/6,0),'999,999,999,999')||'</TD>'||chr(10)|| 
'<TD>'||to_char(round(count(item_key)/180,0),'999,999,999,999')||'</TD></TR>'
from wf_items
where begin_date > sysdate-180
group by item_type
order by count(item_key) desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>

REM
REM ******* Opened Over 90 Days Ago *******
REM

prompt <a name="wfadv135"></a><B><U>Total OPEN Items Started Over 90 Days Ago</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows3sql6(){var row = document.getElementById("s3sql6");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Total OPEN Items Started Over 90 Days Ago</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql6()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql6" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="55">
prompt       <blockquote><p align="left">
prompt          select to_char(wi.begin_date, 'YYYY'), count(wi.item_key)<br>
prompt          from wf_items wi, wf_item_types wit, wf_item_types_tl witt<br>  
prompt          where wi.ITEM_TYPE=wit.NAME and wi.end_date is null  <br>
prompt          and wit.NAME=witt.NAME and witt.language = 'US' and wi.begin_date < sysdate-90  <br>
prompt          group by to_char(wi.begin_date, 'YYYY') <br>
prompt          order by to_char(wi.begin_date, 'YYYY');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>OPENED</B></font></TD> 
prompt <TD BGCOLOR=#DEE6EF><div align="right"><font face="Calibri"><B>COUNT</B></font></div></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||to_char(wi.begin_date, 'YYYY')||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(wi.item_key),'999,999,999,999')||'</div></TD></TR>'
from wf_items wi, wf_item_types wit, wf_item_types_tl witt  
where wi.ITEM_TYPE=wit.NAME and wi.end_date is null  
and wit.NAME=witt.NAME and witt.language = 'US' and wi.begin_date < sysdate-90  
group by to_char(wi.begin_date, 'YYYY') 
order by to_char(wi.begin_date, 'YYYY');
prompt <TR><TD BGCOLOR=#DEE6EF align="right"><font face="Calibri"><B>TOTALS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF align="right"><font face="Calibri">
print :ninety_totals
prompt </TD></TR>
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

select sum(COUNT) into :ninety_cnt from (  
select to_char(wi.begin_date, 'YYYY') TOTAL_OPENED, count(wi.item_key) COUNT  
from wf_items wi, wf_item_types wit, wf_item_types_tl witt  
where wi.ITEM_TYPE=wit.NAME and wi.end_date is null  
and wit.NAME=witt.NAME and witt.language = 'US' and wi.begin_date < (sysdate-90)
group by to_char(wi.begin_date, 'YYYY') );

    if (:ninety_cnt = 0) then

       dbms_output.put_line('There are no OPEN items that were started over 90 days ago.<BR>');
      
      else if (:ninety_cnt > 0) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:<BR>');
       dbms_output.put_line('There are ' || to_char(:ninety_cnt,'999,999,999,999') || ' OPEN item_types in WF_ITEMS table that were started over 90 days ago.</B><BR>');
       dbms_output.put_line('Remember that once a Workflow is closed, its runtime data which is stored in Workflow Runtime Tables (WF_*) becomes obsolete.<BR>');
       dbms_output.put_line('All pertinent information is stored in the functional tables (FND_*, PO_*, AP_*, HR_*, OE_*, etc), like who approved what, for how much, for whom, etc...)');
       dbms_output.put_line('and that each single row in WF_ITEMS can represent 100s or 1000s of rows in the subsequent Workflow Runtime tables, ');
       dbms_output.put_line('so it is important to close these open workflows once completed so they can be purged.<BR>');
       dbms_output.put_line('<B>Action:<BR>');
       dbms_output.put_line('Ask the Question: How long should these workflows take to complete?</B><BR>');
       dbms_output.put_line('30 Days... 60 Days... 6 months... 1 Year?<BR>');
       dbms_output.put_line('There may be valid business reasons why these OPEN items still exist after 90 days so that should be taken into consideration.<BR>');
       dbms_output.put_line('However, if this is not the case, then once a workflow item is closed then all the runtime data associated to completing this workflow is now obsolete and should be purged to make room for new workflows.<BR>');
       dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=144806.1" target="_blank">Note 144806.1');
       dbms_output.put_line('</a> - A Detailed Approach To Purging Oracle Workflow Runtime Data ');
       dbms_output.put_line('for details on how to drill down to discover the reason why these OLD items are still open, and ways to close them so they can be purged.');
       dbms_output.put_line('</p></td></tr></tbody></table><BR><BR>');
 
      end if;   
    end if;  
end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Check Top 30 Large Item Activity Status History Items *******
REM

prompt <a name="wfadv136"></a><B><U>Workflow Looping Activities</B></U><BR>
prompt <blockquote>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td><font size="+1">
prompt <B>Workflow Looping Activities:</B></font><BR><BR>
prompt It is normal for Workflow to use WAITS and other looping acitivities to process delayed responses and other criteria.<BR>
prompt Each revisit of a node replaces the previous data with the current activities status and stores the old activity information into a activities history table.<BR>
prompt Looking at this history table (WF_ITEM_ACTIVITY_STATUSES_H) can help to identify possible long running workflows that appear to be stuck in a loop over a long time, or a poorly designed workflow that is looping excessively and can cause performance issues.<BR>
prompt </p></td></tr></tbody></table><BR>


prompt <script type="text/javascript">    function displayRows3sql7(){var row = document.getElementById("s3sql7");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=5 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Check Top 30 Large Item Activity Status History Items</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows3sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s3sql7" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="6" height="125">
prompt       <blockquote><p align="left">
prompt          SELECT sta.item_type ITEM_TYPE, sta.item_key ITEM_KEY, COUNT(*) COUNT,<br>
prompt          TO_CHAR(wfi.begin_date, 'YYYY-MM-DD') OPENED, TO_CHAR(wfi.end_date, 'YYYY-MM-DD') CLOSED, wfi.user_key DESCRIPTION<br>
prompt          FROM wf_item_activity_statuses_h sta, <br>
prompt          wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' <br>
prompt          GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), <br>
prompt          TO_CHAR(wfi.end_date, 'YYYY-MM-DD') <br>
prompt          HAVING COUNT(*) > 500 <br>
prompt          ORDER BY COUNT(*) DESC;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">ITEM_KEY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">COUNT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">BEGIN_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">END_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">DESCRIPTION</B></TD>
exec :n := dbms_utility.get_time;
SELECT * FROM (SELECT  
'<TR><TD>'||sta.item_type||'</TD>'||chr(10)|| 
'<TD>'||sta.item_key||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(COUNT(*),'999,999,999,999')||'</div></TD>'||chr(10)|| 
'<TD>'||TO_CHAR(wfi.begin_date, 'YYYY-MM-DD')||'</TD>'||chr(10)|| 
'<TD>'||TO_CHAR(wfi.end_date, 'YYYY-MM-DD')||'</TD>'||chr(10)|| 
'<TD>'||wfi.user_key||'</TD></TR>'
FROM wf_item_activity_statuses_h sta, 
wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
HAVING COUNT(*) > 500 
ORDER BY COUNT(*) DESC) 
WHERE ROWNUM < 31;
prompt</TABLE><P><P>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

SELECT count(*) into :hasrows FROM (SELECT sta.item_type 
FROM wf_item_activity_statuses_h sta, 
wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
HAVING COUNT(*) > 500 
ORDER BY COUNT(*) DESC);

if (:hasrows>0) then

	SELECT * into :hist_item FROM (SELECT sta.item_type 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	select * into :hist_key from (SELECT sta.item_key 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	SELECT * into :hist_end  
	FROM (SELECT end_date from wf_items where item_type = :hist_item and item_key = :hist_key);

	SELECT * into :hist_cnt FROM (SELECT count(sta.item_key) 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	SELECT * into :hist_begin
	FROM (SELECT to_char(begin_date, 'Mon DD, YYYY') from  wf_items where item_type = :hist_item and item_key = :hist_key);

	select * into :hist_days
	from (select round(sysdate-begin_date,0) from wf_items where item_type = :hist_item and item_key = :hist_key);
	
	select * into :hist_recent 
	FROM (SELECT to_char(max(begin_date),'Mon DD, YYYY') from wf_item_activity_statuses_h
	where item_type = :hist_item and item_key = :hist_key);

	select sysdate into :sysdate from dual;

	    if ((:hist_end is null) and (:hist_days=0)) then 
		
		:hist_daily := :hist_cnt;
		
    	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> ');
	       dbms_output.put_line('Currently, the largest single activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This workflow process is still open, so this may be a problem. It was started on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>');       

	   elsif ((:hist_end is null) and (:hist_days > 0)) then 

		select ROUND((:hist_cnt/:hist_days),0) into :hist_daily from dual;
		
    	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This workflow process is still open, so this may be a problem. It was started back on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>'); 

	   elsif ((:hist_end is not null) and (:hist_days = 0)) then 

		select ROUND((:hist_cnt/:hist_days),0) into :hist_daily from dual;
		
    	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This process has been closed since ' || :hist_end || ', it was started on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>');
	       
	   else 

		select ROUND((:hist_cnt/:hist_days),2) into :hist_daily from dual;
		
    		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This process has been closed since ' || :hist_end || '.<BR>');
	       
	    end if;       

	       dbms_output.put_line('So far this one activity for item_type ' || :hist_item || ' and item_key ' || :hist_key || ' has looped ' || to_char(:hist_cnt,'999,999,999,999') || ' times since it started in ' || :hist_begin || '.<BR>');
	       dbms_output.put_line('<B>Action:</B><BR>');
	       dbms_output.put_line('This is a good place to start, as this single activity has been looping for ' || to_char(:hist_days,'999,999') || ' days, which is about ' || to_char(:hist_daily,'999,999.99') || ' times a day.<BR>');
	       dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=144806.1" target="_blank">');
	       dbms_output.put_line('Note 144806.1</a> - A Detailed Approach To Purging Oracle Workflow Runtime Data on how to drill down and discover how to purge this workflow data.<br>');
	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');


elsif (:hasrows=0) then 

       dbms_output.put_line('<table border="1" name="GoodJob" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Well Done !!</B><BR><BR>');
       dbms_output.put_line('There are NO ROWS found in the HISTORY table (wf_item_activity_statuses_h) that have over 500 rows associated to the same item_key.<BR>');
       dbms_output.put_line('This is a good result, which means there is no major looping issues at this time.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

end if;
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>
prompt </blockquote>


REM **************************************************************************************** 
REM *******                   Section 4 : Workflow Concurrent Programs               *******
REM ****************************************************************************************

prompt <a name="section4"></a><B><font size="+2">Workflow Concurrent Programs</font></B><BR><BR>
prompt <blockquote>

REM
REM ******* Verify Concurrent Programs Scheduled to Run *******
REM

prompt <p>Oracle Workflow requires several Concurrent Programs to be run to process, progress, cleanup, and purge workflow related information.<BR>
prompt    This section verifies these required Workflow Concurrent Programs are scheduled as recommended.  <BR>
prompt    Note: This section is only looking at the scheduled jobs in FND_CONCURRENT_REQUESTS table.<br>
prompt    Jobs scheduled using other tools (DBMS_JOBS, CONSUB, or PL/SQL, etc) are not reflected here, so keep this in mind.</p>


prompt <a name="wfadv141"></a><B><U>Verify Workflow Concurrent Programs Scheduled to Run</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows4sql1(){var row = document.getElementById("s4sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Verify Workflow Concurrent Programs Scheduled to Run</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="185">
prompt       <blockquote><p align="left">
prompt          select r.REQUEST_ID, u.user_name, r.PHASE_CODE, r.ACTUAL_START_DATE,<br>
prompt          c.CONCURRENT_PROGRAM_NAME, p.USER_CONCURRENT_PROGRAM_NAME, r.ARGUMENT_TEXT, <br>
prompt          r.RESUBMIT_INTERVAL, r.RESUBMIT_INTERVAL_UNIT_CODE, r.RESUBMIT_END_DATE<br>
prompt          FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u <br>
prompt          WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id <br>
prompt          and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID <br>
prompt          and c.CONCURRENT_PROGRAM_NAME in ('FNDWFBG','FNDWFPR','FNDWFRET','JTFRSWSN','FNDWFSYNCUR','FNDWFLSC', <br>
prompt          'FNDWFLIC','FNDWFDSURV','FNDCPPUR','FNDWFBES_CONTROL_QUEUE_CLEANUP','FNDWFAASTATCC','FNDWFMLRSTATCC','FNDWFWITSTATCC','FNDWFBULKRESETNTFPREF') <br>
prompt          AND p.language = 'US' <br>
prompt          and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')<br>
prompt          order by c.CONCURRENT_PROGRAM_NAME, r.ARGUMENT_TEXT;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUESTED_BY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PHASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>INTERNAL NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ARGUMENTS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EVERY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SO_OFTEN</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RESUBMIT_END_DATE</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||r.REQUEST_ID||'</TD>'||chr(10)|| 
'<TD>'||u.user_name||'</TD>'||chr(10)|| 
'<TD>'||r.PHASE_CODE||'</TD>'||chr(10)|| 
'<TD>'||r.ACTUAL_START_DATE||'</TD>'||chr(10)||
'<TD>'||c.CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)|| 
'<TD>'||p.USER_CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)||
'<TD>'||r.ARGUMENT_TEXT||'</TD>'||chr(10)|| 
'<TD>'||r.RESUBMIT_INTERVAL||'</TD>'||chr(10)||  
'<TD>'||r.RESUBMIT_INTERVAL_UNIT_CODE||'</TD>'||chr(10)||
'<TD>'||r.RESUBMIT_END_DATE||'</TD></TR>'
FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u 
WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id 
and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
and c.CONCURRENT_PROGRAM_NAME in ('FNDWFBG','FNDWFPR','FNDWFRET','JTFRSWSN','FNDWFSYNCUR','FNDWFLSC', 
'FNDWFLIC','FNDWFDSURV','FNDCPPUR','FNDWFBES_CONTROL_QUEUE_CLEANUP','FNDWFAASTATCC','FNDWFMLRSTATCC','FNDWFWITSTATCC','FNDWFBULKRESETNTFPREF') 
AND p.language = 'US' 
and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')
order by c.CONCURRENT_PROGRAM_NAME, r.ARGUMENT_TEXT;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

REM
REM ******* Verify Workflow Background Processes Scheduled to Run *******
REM

begin

	select count(rownum) into :alldefrd
	FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c 
	WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID
	and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
	and c.CONCURRENT_PROGRAM_NAME = 'FNDWFBG' 
	AND p.language = 'US' 
	and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')
	and substr(r.ARGUMENT_TEXT,0,instr(r.ARGUMENT_TEXT,',')-1) is NULL
	and TRIM(substr(r.ARGUMENT_TEXT,instr(r.ARGUMENT_TEXT,',',1,3)+1,(instr(r.ARGUMENT_TEXT,',',1,4)-1)-(instr(r.ARGUMENT_TEXT,',',1,3)))) = 'Y';

	select count(rownum) into :stuckfreq
	FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c 
	WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID
	and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
	and c.CONCURRENT_PROGRAM_NAME = 'FNDWFBG' 
	AND p.language = 'US' 
	and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P')
	and TRIM(substr(r.ARGUMENT_TEXT,instr(r.ARGUMENT_TEXT,',',1,5)+1)) = 'Y'
    and r.RESUBMIT_INTERVAL_UNIT_CODE in ('HOURS','MINUTES');
  		
	if (:alldefrd = 0) then

	    dbms_output.put_line('<table border="1" name="RedBox" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Error:<BR>');
		dbms_output.put_line('There are No Workflow Background Processes scheduled to run for ALL Item_Types.</B><BR><BR>');
		dbms_output.put_line('<B>Action:<br>');
		dbms_output.put_line('Please schedule the concurrent request "Workflow Background Process" to process deferred, timed-out, and identify stuck activities for ALL item_types using the guidelines listed above.</B><br>');
		dbms_output.put_line('At a minimum, there needs to be at least one background process that can handle both deferred and timed-out activities in order to progress workflows.<BR><BR>');
		dbms_output.put_line('For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=466535.1#aref_section23" target="_blank">');
		dbms_output.put_line('Note 466535.1</a> - How to run the Workflow Background Engine per developments recommendations.<br>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	   
	    elsif (:alldefrd > 0) then

		
		dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Nice work!!<BR>');		
		dbms_output.put_line('There are '||to_char((:alldefrd),'999,999,999,999')||' Workflow Background Processes scheduled to run for deferred activities for ALL Item_Types!</B><br>');
		dbms_output.put_line('<br>Development recommends scheduling a Background Process to handle DEFERRED activities periodically every 5 to 60 minutes.<br>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>'); 

		end if;
			
	if (:stuckfreq = 1) then

	    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Attention:<BR>');
		dbms_output.put_line('There is a Workflow Background Process to identify STUCK activites scheduled periodically to run in hours or mintues, which may be scheduled to recur too frequently.<BR><BR>');
		dbms_output.put_line('Suggestion:<br>');
		dbms_output.put_line('Workflow Development recommends scheduling a Background Process to identify STUCK Activities once a week to once a month, when the load on the system is low.</b><BR>');
		dbms_output.put_line('Stuck activities do not have a clear pattern as cause but mainly they are caused by flaws in the WF definition like improper transition definitions.<br> ');
		dbms_output.put_line('<b>The query to determine activities that are STUCK is very expensive</b> as it joins 3 WF runtime tables and one WF design table. <br>');
		dbms_output.put_line('This is why the Workflow Background Engine should run for STUCK Activities SEPERATELY and ONLY when load is low and maybe once a week or as your business requires.<br><br>');
		dbms_output.put_line('Please see <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=186361.1" target="_blank">Note 186361.1</a>');
		dbms_output.put_line(' - Workflow Background Process Performance Troubleshooting Guide for more information<br>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>');

		elsif (:stuckfreq > 1) then

	    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Attention:<BR>');
		dbms_output.put_line('There are '||to_char((:stuckfreq),'999,999,999,999')||' Workflow Background Processes which identify STUCK activites scheduled periodically to run in hours or mintues, which may be scheduled to recur too frequently.<BR><BR>');
		dbms_output.put_line('Suggestion:<br>');
		dbms_output.put_line('Workflow Development recommends scheduling a Background Process to identify STUCK Activities once a week to once a month, when the load on the system is low.</b><BR>');
		dbms_output.put_line('Stuck activities do not have a clear pattern as cause but mainly they are caused by flaws in the WF definition like improper transition definitions.<br> ');
		dbms_output.put_line('<b>The query to determine activities that are STUCK is very expensive</b> as it joins 3 WF runtime tables and one WF design table. <br>');
		dbms_output.put_line('This is why the Workflow Background Engine should run for STUCK Activities SEPERATELY and ONLY when load is low and maybe once a week or as your business requires.<br><br>');
		dbms_output.put_line('Please see <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=186361.1" target="_blank">Note 186361.1</a>');
		dbms_output.put_line(' - Workflow Background Process Performance Troubleshooting Guide for more information<br>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>');
		
		end if;
	
end;
/

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt   <tbody><tr><td><p>
prompt   The Workflow Administrator's Guide requires that there is at least one background engine that can process deferred activities, check for timed-out activities, and identify stuck processes.<BR> 
prompt   At a minimum, there needs to be at least one background process that can handle both deferred and timed-out activities in order to progress workflows.<BR>
prompt   <B>However, for performance reasons Oracle recommends running three (3) separate background engines at different intervals.<BR>
prompt   1) Run a Background Process to handle only DEFERRED activities every 5 to 60 minutes.<BR>
prompt   2) Run a Background Process to handle only TIMED-OUT activities every 1 to 24 hours as needed.</B><BR>
prompt   - Timed-out and stuck activities are not processed from the queue but from the table directly, so Timed-out and stuck activities do not have a representing message in queue WF_DEFERRED_TABLE_M.<br> 
prompt   - For this reason they need to be queried up from the runtime tables and progressed as needed. When those records are found the internal Engine APIs are called to progress those workflows further.<br> 
prompt   - Timed-out activities are checked in table WF_ITEM_ACTIVITY_STATUSES when their status is ACTIVE, WAITING , NOTIFIED, SUSPEND, or DEFERRED.<br> 
prompt   - This query on the table is strightforward and no performance issues are expected here. <br>
prompt   <B>3) Run a Background Process to identify STUCK Activities once a week to once a month, when the load on the system is low.</B><BR>
prompt   - Stuck activities do not have a clear pattern as cause but mainly they are caused by flaws in the WF definition like improper transition definitions.<br> 
prompt   - The query to determine activities that are STUCK is very expensive as it joins 3 WF runtime tables and one WF design table. <br>
prompt   - This is why the Workflow Background Engine should run for STUCK Activities SEPERATELY and ONLY when load is not high and maybe once a week or so.<br><br>
prompt   Please see <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=186361.1" target="_blank">Note 186361.1</a> - Workflow Background Process Performance Troubleshooting Guide for more information</p>
prompt   </td></tr></tbody></table><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>

REM
REM ******* Verify (last 30) Workflow Background Processes that ran *******
REM

prompt <a name="wfadv142"></a><B><U>Verify (last 30) Workflow Background Processes that have completed</B></U><BR>
prompt <blockquote>

prompt <p>The following table displays Concurrent requests that HAVE run and completed, regardless of how they were scheduled (DBMS_JOBS, CONSUB, or PL/SQL, etc)<BR>
prompt    Keep in mind how often the Concurrent Requests Data is being purged.</p>     

prompt <script type="text/javascript">    function displayRows4sql2(){var row = document.getElementById("s4sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Verify (last 30) Workflow Background Processes that have completed</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="350">
prompt       <blockquote><p align="left">
prompt          SELECT r.REQUEST_ID, u.user_name, p.USER_CONCURRENT_PROGRAM_NAME PROGRAM,<br>
prompt          DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',<br>
prompt          'D','D=Cancelled','E','E=Error','G','G=Warning',<br>
prompt          'H','H=On Hold','I','I=Normal','M','M=No Manager',<br>
prompt          'P','P=Scheduled','Q','Q=Standby','R','R=Normal',<br>
prompt          'S','S=Suspended','T','T=Terminating','U','U=Disabled',<br>
prompt          'W','W=Paused','X','X=Terminated','Z','Z=Waiting') STATUS,<br>
prompt          DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running') PHASE,<br>
prompt          r.ACTUAL_START_DATE STARTED, r.ACTUAL_COMPLETION_DATE COMPLETED,<br>
prompt          ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2) TOTAL_MINS,<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||<br>
prompt          FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||<br>
prompt          ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-<br>
prompt          (FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs' TIME_TO_RUN,<br> 
prompt          r.ARGUMENT_TEXT ARGUMENTS<br>
prompt          FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u <br>
prompt          WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id <br>
prompt          and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID <br>
prompt          and c.CONCURRENT_PROGRAM_NAME = 'FNDWFBG'<br>
prompt          AND p.language = 'US' <br>
prompt          and r.ACTUAL_COMPLETION_DATE is not null<br>
prompt          order by r.ACTUAL_START_DATE desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PHASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPLETED</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL_MINS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TIME_TO_RUN</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ARGUMENTS</B></TD> 
exec :n := dbms_utility.get_time;
SELECT * FROM (SELECT
'<TR><TD>'||r.REQUEST_ID||'</TD>'||chr(10)|| 
'<TD>'||u.user_name||'</TD>'||chr(10)|| 
'<TD>'||p.USER_CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',
'D','D=Cancelled','E','E=Error','G','G=Warning',
'H','H=On Hold','I','I=Normal','M','M=No Manager',
'P','P=Scheduled','Q','Q=Standby','R','R=Normal',
'S','S=Suspended','T','T=Terminating','U','U=Disabled',
'W','W=Paused','X','X=Terminated','Z','Z=Waiting')||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running')||'</TD>'||chr(10)|| 
'<TD>'||r.ACTUAL_START_DATE||'</TD>'||chr(10)||
'<TD>'||r.ACTUAL_COMPLETION_DATE||'</TD>'||chr(10)|| 
'<TD>'||ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2)||'</TD>'||chr(10)||
'<TD>'||FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||
FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||
ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-(FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs'||'</TD>'||chr(10)|| 
'<TD>'||r.ARGUMENT_TEXT||'</TD></TR>'
FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u 
WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id 
and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
and c.CONCURRENT_PROGRAM_NAME = 'FNDWFBG'
AND p.language = 'US' 
and r.ACTUAL_COMPLETION_DATE is not null
order by r.ACTUAL_START_DATE desc)
WHERE ROWNUM < 31;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Verify Status of the Workflow Background Engine Deferred Queue Table *******
REM

prompt <a name="wfadv143"></a><B><U>Display Activity Status of the Workflow Background Process Deferred Table</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows4sql3(){var row = document.getElementById("s4sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Display Activity Status of the Workflow Background Process Deferred Table (WF_DEFERRED_TABLE_M)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="60">
prompt       <blockquote><p align="left">
prompt          select corr_id, msg_state, count(*)<br>
prompt          from applsys.aq$wf_deferred_table_m<br> 
prompt          group by corr_id, msg_state<br>
prompt          order by msg_state, count(*) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CORR_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||corr_id||'</TD>'||chr(10)|| 
'<TD>'||msg_state||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(*),'999,999,999,999')||'</div></TD></TR>'
from applsys.aq$wf_deferred_table_m 
group by corr_id, msg_state
order by msg_state, count(*) desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

REM
REM ******* WF_DEFERRED_TABLE_M Index Check *******
REM


begin

:wfdtmIndx := 0;

select count(index_name) into :wfdtmIndx
from dba_ind_columns
where table_name like '%WF_DEFERRED_TABLE_M%'
and index_name = 'WF_DEFERRED_TABLE_M_N1'
and index_owner = 'APPLSYS';


if (:wfdtmIndx > 0) then

    dbms_output.put_line('');
    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('The Background Process Index: WF_DEFERRED_TABLE_M_N1 on WF_DEFERRED_TABLE_M(CORRID) exists as expected.<br>');
    dbms_output.put_line('</td></tr></tbody></table><BR>');
    
else 

    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><tr><td> ');
    dbms_output.put_line('<p><B>Attention:<br>');
    dbms_output.put_line('The Index: WF_DEFERRED_TABLE_M_N1 for Workflow Background Processing on table WF_DEFERRED_TABLE_M does not exist.</B><br><br>');
    dbms_output.put_line('It can be created as follows:<br><br>');
    dbms_output.put_line('<i>');
    dbms_output.put_line('CREATE INDEX WF_DEFERRED_TABLE_M_N1 ON WF_DEFERRED_TABLE_M(CORRID)<br>');
    dbms_output.put_line('STORAGE (INITIAL 1M NEXT 1M MINEXTENTS 1 MAXEXTENTS 2147483645 PCTINCREASE 0) TABLESPACE <tablespacename>;</i><br><br>');
    dbms_output.put_line('For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=466535.1" ');
    dbms_output.put_line('target="_blank">Note 466535.1</a> - How to Resolve the Most Common Workflow Background Engine Problems<br>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>'); 


end if;
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>



REM
REM ******* Verify Workflow Purge Concurrent Programs *******
REM

prompt <a name="wfadv144"></a><B><U>Verify (last 30) Workflow Purge Concurrent Programs that have completed</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows4sql4(){var row = document.getElementById("s4sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Verify (last 30) Workflow Purge Concurrent Programs that have completed</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="250">
prompt       <blockquote><p align="left">
prompt          select r.REQUEST_ID, u.user_name, p.USER_CONCURRENT_PROGRAM_NAME,<br>
prompt          DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',<br>
prompt          'D','D=Cancelled','E','E=Error','G','G=Warning',<br>
prompt          'H','H=On Hold','I','I=Normal','M','M=No Manager',<br>
prompt          'P','P=Scheduled','Q','Q=Standby','R','R=Normal',<br>
prompt          'S','S=Suspended','T','T=Terminating','U','U=Disabled',<br>
prompt          'W','W=Paused','X','X=Terminated','Z','Z=Waiting'),<br>
prompt          DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running'),<br>
prompt          r.ACTUAL_START_DATE,r.ACTUAL_COMPLETION_DATE,<br>
prompt          ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2),<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||<br>
prompt          FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||<br>
prompt          ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-(FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs', <br>
prompt          r.ARGUMENT_TEXT<br>
prompt          FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u <br>
prompt          WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id <br>
prompt          and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID <br>
prompt          and c.CONCURRENT_PROGRAM_NAME = ('FNDWFPR') <br>
prompt          AND p.language = 'US' <br>
prompt          and r.ACTUAL_COMPLETION_DATE is not null<br>
prompt          order by r.ACTUAL_START_DATE desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PHASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPLETED</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL_MINS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TIME_TO_RUN</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ARGUMENTS</B></TD> 
exec :n := dbms_utility.get_time;
SELECT * FROM (SELECT  
'<TR><TD>'||r.REQUEST_ID||'</TD>'||chr(10)|| 
'<TD>'||u.user_name||'</TD>'||chr(10)||
'<TD>'||p.USER_CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',
'D','D=Cancelled','E','E=Error','G','G=Warning',
'H','H=On Hold','I','I=Normal','M','M=No Manager',
'P','P=Scheduled','Q','Q=Standby','R','R=Normal',
'S','S=Suspended','T','T=Terminating','U','U=Disabled',
'W','W=Paused','X','X=Terminated','Z','Z=Waiting')||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running')||'</TD>'||chr(10)|| 
'<TD>'||r.ACTUAL_START_DATE||'</TD>'||chr(10)||
'<TD>'||r.ACTUAL_COMPLETION_DATE||'</TD>'||chr(10)|| 
'<TD>'||ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2)||'</TD>'||chr(10)||
'<TD>'||FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||
FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||
ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-(FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs'||'</TD>'||chr(10)|| 
'<TD>'||r.ARGUMENT_TEXT||'</TD></TR>'
FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u 
WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id 
and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
and c.CONCURRENT_PROGRAM_NAME = ('FNDWFPR') 
AND p.language = 'US' 
and r.ACTUAL_COMPLETION_DATE is not null
order by r.ACTUAL_START_DATE desc) 
WHERE ROWNUM < 31;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

	select count(rownum) into :prgall
	FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c 
	WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID
	and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
	and c.CONCURRENT_PROGRAM_NAME = 'FNDWFPR' 
	AND p.language = 'US' 
	and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')
	and substr(r.ARGUMENT_TEXT,0,instr(r.ARGUMENT_TEXT,',')-1) is null
	and TRIM(substr(r.ARGUMENT_TEXT,instr(r.ARGUMENT_TEXT,',',1,3)+1,(instr(r.ARGUMENT_TEXT,',',1,4)-1)-(instr(r.ARGUMENT_TEXT,',',1,3)))) = 'TEMP';

	select count(distinct item_type) into :n from wf_items;
	
	select count(rownum) into :prgcore
	FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c 
	WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID
	and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
	and c.CONCURRENT_PROGRAM_NAME = 'FNDWFPR' 
	AND p.language = 'US' 
	and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')
	and TRIM(substr(r.ARGUMENT_TEXT,instr(r.ARGUMENT_TEXT,',',1,3)+1,(instr(r.ARGUMENT_TEXT,',',1,4)-1)-(instr(r.ARGUMENT_TEXT,',',1,3)))) = 'TEMP'
	and TRIM(substr(r.ARGUMENT_TEXT,instr(r.ARGUMENT_TEXT,',',1,4)+1,(instr(r.ARGUMENT_TEXT,',',1,5)-1)-(instr(r.ARGUMENT_TEXT,',',1,4)))) = 'N';
	
	if (:prgall = 0) then

	    dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Error:<BR>');
		dbms_output.put_line('There are No Purge Obsolete Workflow Runtime Data Concurrent Requests scheduled to run for ALL workflow Item_Types with TEMP persistence.</B><BR><BR>');
		dbms_output.put_line('<B>Action:<br>');
		dbms_output.put_line('Currently there are '||to_char((:n),'999,999,999,999')||' distinct workflow items_types actively being used on '||:sid||'.<br>');
		dbms_output.put_line('Workflow Development recommends scheduling the concurrent request "Purge Obsolete Workflow Runtime Data" to purge workflow runtime data for ALL item_types using the following guidelines.</B><br>');
		dbms_output.put_line('Oracle Workflow and Oracle XML Gateway access several tables that can grow quite large with obsolete workflow ');
		dbms_output.put_line('information that is stored for all completed workflow processes, as well as obsolete information for XML transactions.');
		dbms_output.put_line('The size of these tables and indexes can adversely affect performance.<br>');
		dbms_output.put_line('These tables should be purged on a regular basis, using the Purge Obsolete Workflow Runtime Data concurrent program.<BR><BR>');
		dbms_output.put_line('For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=144806.1" target="_blank">');
		dbms_output.put_line('Note 144806.1</a> - A Detailed Approach To Purging Oracle Workflow Runtime Data.<br>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	   
	    elsif (:prgall > 0) then

		
		dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Nice work!!<BR>');		
		dbms_output.put_line('There are '||to_char((:prgall),'999,999,999,999')||' Purge Obsolete Workflow Runtime Data Concurrent requests scheduled to purge workflow for ALL Item_Types!</B><br>');
		dbms_output.put_line('<br>Development recommends scheduling the Workflow Purge program periodically based on your business volumes.<br>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>'); 

		end if;
			
	if ((:prgall > 0) and (:prgcore = 0)) then

	    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Attention:<BR>');
		dbms_output.put_line('The Purge Obsolete Workflow Runtime Data Concurrent request has a parameter called Core Workflow Only which by default is set to Yes. <BR>');
		dbms_output.put_line('This purges only core runtime information associated with work items for performance gain during periods of high activity. <BR><BR>');
		dbms_output.put_line('Suggestion:</b><br>');
		dbms_output.put_line('Run a more comprehensive Purge Obsolete Workflow Runtime Data Concurrent request for ALL item_types by setting the Core Workflow Only value to NO.<br>');
		dbms_output.put_line('This will purge obsolete runtime information associated with work items, including status information, any associated notifications, and it also purges obsolete design information, such as activities that are ');
		dbms_output.put_line('no longer in use and expired ad hoc users and roles, and obsolete runtime information not associated with work items, such as notifications ');
		dbms_output.put_line('that were not handled through a workflow process and, if the ECX: Purge ECX data with WF profile option is set to Y, Oracle XML Gateway ');
		dbms_output.put_line('transactions that were not handled through a workflow process.<br>');
		dbms_output.put_line('Schedule this comprehensive Purge request once a month or every 2 weeks as needed.<br><br>');	
		dbms_output.put_line('For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=144806.1" target="_blank">');
		dbms_output.put_line('Note 144806.1</a> - A Detailed Approach To Purging Oracle Workflow Runtime Data.<br>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	
		end if;
	
end;
/

prompt <table border="1" name="Warning" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td> 
prompt <p>Delivered in 11i.ATG.rup4+ are new Concurrent Programs designed to gather Workflow Statistics after running purge.<BR>
prompt These requests should automatically run every 24hrs by default, however they can be run anytime to refresh the workflow process tables after purging to confirm that the purgeable items were purged.<BR>
prompt <B> - Workflow Agent Activity Statistics (FNDWFAASTATCC)</B> - Gathers statistics for the Agent Activity graph in the Workflow System status page and for the agent activity list in the Agent Activity page.<BR>
prompt <B> - Workflow Mailer Statistics (FNDWFMLRSTATCC)</B> - Gathers statistics for the throughput graph in the Notification Mailer Throughput page.<BR>
prompt <B> - Workflow Work Items Statistics (FNDWFWITSTATCC)</B> - Gathers statistics for the Work Items graph in the Workflow System status page, for 
prompt the Completed Work Items list in the Workflow Purge page, and for the work item lists in the Active Work Items, Deferred Work Items, Suspended Work Items, and Errored Work Items pages.</p>
prompt </p></td></tr></tbody></table><BR><br>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Verify Workflow Control Queue Cleanup Program *******
REM

prompt <a name="wfadv145"></a><B><U>Verify (last 30) Workflow Control Queue Cleanup requests that have completed</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows4sql5(){var row = document.getElementById("s4sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Verify (last 30) Workflow Control Queue Cleanup requests that have completed</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows4sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s4sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="250">
prompt       <blockquote><p align="left">
prompt          select r.REQUEST_ID, u.user_name, p.USER_CONCURRENT_PROGRAM_NAME,<br>
prompt          DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',<br>
prompt          'D','D=Cancelled','E','E=Error','G','G=Warning',<br>
prompt          'H','H=On Hold','I','I=Normal','M','M=No Manager',<br>
prompt          'P','P=Scheduled','Q','Q=Standby','R','R=Normal',<br>
prompt          'S','S=Suspended','T','T=Terminating','U','U=Disabled',<br>
prompt          'W','W=Paused','X','X=Terminated','Z','Z=Waiting'),<br>
prompt          DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running'),<br>
prompt          r.ACTUAL_START_DATE,r.ACTUAL_COMPLETION_DATE,<br>
prompt          ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2),<br>
prompt          FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||<br>
prompt          FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||<br>
prompt          ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-(FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs', <br>
prompt          r.ARGUMENT_TEXT<br>
prompt          FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u <br>
prompt          WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id <br>
prompt          and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID <br>
prompt          and c.CONCURRENT_PROGRAM_NAME = ('FNDWFBES_CONTROL_QUEUE_CLEANUP') <br>
prompt          AND p.language = 'US' <br>
prompt          and r.ACTUAL_COMPLETION_DATE is not null<br>
prompt          order by r.ACTUAL_START_DATE desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>USER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PHASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPLETED</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL_MINS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TIME_TO_RUN</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ARGUMENTS</B></TD> 
exec :n := dbms_utility.get_time;
SELECT * FROM (SELECT 
'<TR><TD>'||r.REQUEST_ID||'</TD>'||chr(10)|| 
'<TD>'||u.user_name||'</TD>'||chr(10)||
'<TD>'||p.USER_CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.STATUS_CODE, 'A','Waiting','B','B=Resuming','C','C=Normal',
'D','D=Cancelled','E','E=Error','G','G=Warning',
'H','H=On Hold','I','I=Normal','M','M=No Manager',
'P','P=Scheduled','Q','Q=Standby','R','R=Normal',
'S','S=Suspended','T','T=Terminating','U','U=Disabled',
'W','W=Paused','X','X=Terminated','Z','Z=Waiting')||'</TD>'||chr(10)|| 
'<TD>'||DECODE(r.PHASE_CODE, 'C','Completed','I','I=Inactive','P','P=Pending','R','R=Running')||'</TD>'||chr(10)|| 
'<TD>'||r.ACTUAL_START_DATE||'</TD>'||chr(10)||
'<TD>'||r.ACTUAL_COMPLETION_DATE||'</TD>'||chr(10)|| 
'<TD>'||ROUND((r.actual_completion_date - r.actual_start_date)*1440, 2)||'</TD>'||chr(10)||
'<TD>'||FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)||':hrs '||
FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)||':Mins '||
ROUND((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600-(FLOOR((((r.actual_completion_date-r.actual_start_date)*24*60*60)-FLOOR(((r.actual_completion_date-r.actual_start_date)*24*60*60)/3600)*3600)/60)*60)))||':Secs'||'</TD>'||chr(10)|| 
'<TD>'||r.ARGUMENT_TEXT||'</TD></TR>'
FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u 
WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id 
and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
and c.CONCURRENT_PROGRAM_NAME = ('FNDWFBES_CONTROL_QUEUE_CLEANUP') 
AND p.language = 'US' 
and r.ACTUAL_COMPLETION_DATE is not null
order by r.ACTUAL_START_DATE desc) 
WHERE ROWNUM < 31;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

	select count(rownum) into :n
	FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c 
	WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID
	and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
	and c.CONCURRENT_PROGRAM_NAME = 'FNDWFBES_CONTROL_QUEUE_CLEANUP' 
	AND p.language = 'US' 
	and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R');

	if (:n = 0) then

	    dbms_output.put_line('<table border="1" name="Warning" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Error:<BR>');
		dbms_output.put_line('There are No Workflow Control Queue Cleanup Concurrent Requests scheduled to run.</B><BR><BR>');
		dbms_output.put_line('<B>Action:<br>');
		dbms_output.put_line('Workflow Development requires the concurrent request "Workflow Control Queue Cleanup" to run every 12 hours.</B><br>');
		dbms_output.put_line('This is a seeded request that is automatically scheduled to be run every 12 hours by default.<BR>');
		dbms_output.put_line('Oracle recommends that this frequency not be changed.<BR><BR>');
		dbms_output.put_line('The Workflow Control Queue Cleanup concurrent program sends an event named oracle.apps.wf.bes.control.ping to check the status of ');
		dbms_output.put_line('each subscriber to the WF_CONTROL queue. If the corresponding middle tier process is still alive, it sends back a response. ');
		dbms_output.put_line('The next time the cleanup program runs, it checks whether responses have been received for each ping event sent during the previous run. ');
		dbms_output.put_line('If no response was received from a particular subscriber, that subscriber is removed.<br>');
		dbms_output.put_line('The recommended frequency for performing cleanup is every twelve hours in order to allow enough time for subscribers to respond to the ping event,');
		dbms_output.put_line('the minimum wait time between two cleanup runs is thirty minutes.<br> ');
		dbms_output.put_line('If you run the procedure again less than thirty minutes after the previous run, it will not perform any processing.<BR><BR>');
		dbms_output.put_line('Please see <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1#wcqc" target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i</p>');
		dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	   
	    elsif (:n > 0) then

		
		dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Good!!<BR>');		
		dbms_output.put_line('The Workflow Control Queue Cleanup concurrent program appears to be scheduled correctly!</B><br><br>');
		dbms_output.put_line('This is a seeded request that is automatically scheduled to be run every 12 hours by default.<BR>');
		dbms_output.put_line('Oracle recommends that this frequency not be changed.<BR><BR>');
		dbms_output.put_line('The Workflow Control Queue Cleanup concurrent program sends an event named oracle.apps.wf.bes.control.ping to check the status of ');
		dbms_output.put_line('each subscriber to the WF_CONTROL queue. If the corresponding middle tier process is still alive, it sends back a response. ');
		dbms_output.put_line('The next time the cleanup program runs, it checks whether responses have been received for each ping event sent during the previous run. ');
		dbms_output.put_line('If no response was received from a particular subscriber, that subscriber is removed.<br>');
		dbms_output.put_line('The recommended frequency for performing cleanup is every twelve hours in order to allow enough time for subscribers to respond to the ping event,');
		dbms_output.put_line('the minimum wait time between two cleanup runs is thirty minutes.<br> ');
		dbms_output.put_line('If you run the procedure again less than thirty minutes after the previous run, it will not perform any processing.');		
		dbms_output.put_line('</p></td></tr></tbody></table><BR>'); 

		end if;
	
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>
prompt </blockquote>

REM **************************************************************************************** 
REM *******                   Section 5 : Workflow Notification Mailer               *******
REM ****************************************************************************************

prompt <a name="section5"></a><B><font size="+2">Workflow Notification Mailer</font></B><BR><BR>
prompt <blockquote>

prompt <a name="wfmlrptch"></a><B><font size="+1">Known 1-Off Java Mailer Patches on top of ATG Rollups</font></B>
prompt <blockquote>


begin

:mlr_runs := 0;

SELECT count(v.PARAMETER_VALUE) into :mlr_runs
FROM FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS SC
WHERE v.COMPONENT_ID=sc.COMPONENT_ID 
and v.parameter_name = 'PROCESSOR_OUT_THREAD_COUNT'
AND sc.COMPONENT_TYPE = 'WF_MAILER';

if (:mlr_runs > 0) then

CASE 
	when (:apps_rel is null) then 

    	dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	    dbms_output.put_line('<tbody><tr><td> ');
	    dbms_output.put_line('<p><B>Warning:</B><BR>');
	    dbms_output.put_line('There is a problem reading the Oracle Apps version (' || :apps_rel || ') for this instance. ');
	    dbms_output.put_line('So unable to determine if any Java Mailer 1-Off Patches exist.<br> ');	       
       	dbms_output.put_line('</p></td></tr></tbody></table><BR>');  	       
	
	when :apps_rel = '11.5.8' then
 
    	dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	    dbms_output.put_line('<tbody><tr><td> ');
	    dbms_output.put_line('<p><B>Attention:<BR>');
	    dbms_output.put_line('The Oracle Apps version is (' || :apps_rel || ') for this instance.<br> ');
	    dbms_output.put_line('There are no Development suggested 1-Off Java Mailer patches available on top of this version.</B><br><br>');
	    dbms_output.put_line('<B>Warning:<BR>');
	    dbms_output.put_line('Oracle Applications 11.5.8 is no longer supported.</B><br>');
	    dbms_output.put_line('The minimum baseline ATG patchset for Extended Support of Oracle E-Business Suite Release 11i is 11i.ATG_PF.H.delta.6 (Patch 5903765).<br>');
	    dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=883202.1"');
	    dbms_output.put_line('target="_blank">Note 883202.1</a> - ');
	    dbms_output.put_line('Patch Requirements for Extended Support of Oracle E-Business Suite Release 11.5.10<br><br>');
       	dbms_output.put_line('</p></td></tr></tbody></table><BR>');  	       	       
	       
	when :apps_rel = '11.5.9' then

		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td> ');
		dbms_output.put_line('<p><B>Attention:<BR>');
		dbms_output.put_line('The Oracle Apps version is (' || :apps_rel || ') for this instance. ');
		dbms_output.put_line('There are no Development suggested 1-Off Java Mailer patches available on top of this version.</B><br><br>');
		dbms_output.put_line('<B>Warning:<BR>');
		dbms_output.put_line('Oracle Applications 11.5.9 is no longer supported.</B><br>');
		dbms_output.put_line('The minimum baseline ATG patchset for Extended Support of Oracle E-Business Suite Release 11i is 11i.ATG_PF.H.delta.6 (Patch 5903765).<br>');
		dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=883202.1"');
		dbms_output.put_line('target="_blank">Note 883202.1</a> - ');
		dbms_output.put_line('Patch Requirements for Extended Support of Oracle E-Business Suite Release 11.5.10<br><br>');	       
		dbms_output.put_line('</p></td></tr></tbody></table><BR>');  	       	       

 	when (:apps_rel > '11.5.10' and :apps_rel < '12.0') then 
	
		select nvl(max(decode(bug_number,
		4676589, 'RUP4',
		5473858, 'RUP5',
		5903765, 'RUP6',
		6241631, 'RUP7',
		bug_number)),'PRERUP4') RUP into :rup
		from AD_BUGS b 
		where b.BUG_NUMBER in ('4676589', '5473858', '5903765', '6241631')
		order by LAST_UPDATE_DATE desc;


	    if (:rup = 'PRERUP4') then 

    		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td> ');
			dbms_output.put_line('<p><B>Attention:<BR>');
			dbms_output.put_line('This ('|| :apps_rel ||') instance does not have 11i.ATG_PF.H RUP6 Applied.</B><br> ');
			dbms_output.put_line('There are no Development suggested 1-Off Java Mailer patches available for this version.<br>');
			dbms_output.put_line('<B>Warning:<BR>');
			dbms_output.put_line('Oracle Applications '|| :apps_rel ||' is no longer supported.</B><br>');
			dbms_output.put_line('The minimum baseline ATG patchset for Extended Support of Oracle E-Business Suite Release 11.5.10 is 11i.ATG_PF.H.delta.6 (Patch 5903765).<br>');
			dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=883202.1"');
			dbms_output.put_line('target="_blank">Note 883202.1</a> - ');
			dbms_output.put_line('Patch Requirements for Extended Support of Oracle E-Business Suite Release 11.5.10<br>');		       
			dbms_output.put_line('</p></td></tr></tbody></table><BR>');  	       		       
			dbms_output.put_line('<BR>');
	       
        elsif (:rup = 'RUP4') then 
                 
			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6720592';

			dbms_output.put_line('<p><b>Workflow Development recommends the following Java Mailer Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Java Mailer Patch</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
			dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6720592</div></td>');
			dbms_output.put_line('<td>11.5.10 ATG.RUP4: NOTIFICATION MAILER TIME OUT MESSAGES, NEEDS RESTART AND MAILER PERFORMANCE ISSUE AFTER RUP5</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('</table><BR>'); 

			dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended Java Mailer patches that are missing.</b><br>');
			dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
			dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '5402087';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '5479427';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '5665230';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '5939442';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6344618';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6520421';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '10114567';

			dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of 11i.ATG_PF.H RUP4 for '|| :apps_rel ||'.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Workflow Java Mailer Patches</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
			dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">5402087</div></td>');
			dbms_output.put_line('<td>11.5.10. ATG.RUP4:5387425:STD PO APPROVAL E-MAIL RESPONSES FROM BLACKBERRY ARE REJECTED AS INVALID RESP (Superseded by 6241631-11i.ATG_PF.H.delta.7)</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">5479427</div></td>');
			dbms_output.put_line('<td>11.5.10 ATG.RUP4:STD PO APPROVAL E-MAIL RESPONSES FROM BLACKBERRY ARE REJECTED AS INVALID RESP (Superseded by 6241631-11i.ATG_PF.H.delta.7)</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">5665230</div></td>');
			dbms_output.put_line('<td>11.5.10 ATG.RUP4: ALERTS ARE NOT PICKING UP USER SPECIFIED REPLYTO ADDRESS (Superseded by 6241631-11i.ATG_PF.H.delta.7)</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
			dbms_output.put_line('</tr>');             
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">5939442</div></td>');
			dbms_output.put_line('<td>11.5.10 ATG.RUP4: NULLPOINTEREXCEPTION, WORKFLOW MAILER DOES NOT START AFTER ATG_PF.H RUP4 (Superseded by 6241631-11i.ATG_PF.H.delta.7)</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch5||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6344618</div></td>');
			dbms_output.put_line('<td>11.5.10 ATG.RUP4: 6242825: ENCODING FOR MAILTO URIs IN HTML E-MAILS REQUIRES CORRECTION</td>');
			dbms_output.put_line('<td div align="center">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch6||'</td>');
			dbms_output.put_line('</tr>'); 
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6520421</div></td>');
			dbms_output.put_line('<td>652042111.5.10 ATG.RUP4: 6049086:USERS WITH SUMHTML PREF NOT RECEIVING MORE INFORMATION NOTIFICATIONS PROPERLY</td>');
			dbms_output.put_line('<td div align="center">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch7||'</td>');
			dbms_output.put_line('</tr>');                  
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">10114567</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.RUP4:7248744:MAILER DOWN WITH :JAVA.LANG.STRINGINDEXOUTOFBOUNDSEXCEPTION</td>');
			dbms_output.put_line('<td div align="center">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch8||'</td>');
			dbms_output.put_line('</tr>'); 		       
			dbms_output.put_line('</table><BR>');  	       		       

		elsif (:rup = 'RUP5') then 

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6412999';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6441940';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6720592';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6802716';

			dbms_output.put_line('<p><b>Workflow Development recommends the following Java Mailer Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Java Mailer Patches</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
			dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6412999</div></td>');
			dbms_output.put_line('<td>11.5.10.ATG.RUP5: 1-OFF: 6375615:JAVA MAILER PERFORMANCE AFTER APPLYING ATG RUP 5</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6441940</div></td>');
			dbms_output.put_line('<td>MAILER WITH NON-NULL CORR ID DOES NOT PROCESS MESSAGES AFTER ATG PF.H RUP 5</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
			dbms_output.put_line('</tr>');                 
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6720592</div></td>');
			dbms_output.put_line('<td>11.5.10.ATG.RUP5: 1-OFF: NOTIFICATION MAILER TIME OUT MESSAGES, NEEDS RESTART AND MAILER PERFORMANCE ISSUE AFTER RUP5</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6802716</div></td>');
			dbms_output.put_line('<td>1OFF:6242825: ENCODING FOR MAILTO URIS IN HTML RESPONSE E-MAILS REQUIRES CORRECTION</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch5||'</td>');
			dbms_output.put_line('</tr>'); 
			dbms_output.put_line('</table><BR>'); 

			dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended Java Mailer patches that are missing.</b><br>');
			dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
			dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6716241';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6836141';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6901563';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6954271';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch9
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '8646317';

			dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of 11i.ATG_PF.H RUP4 for '|| :apps_rel ||'.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Workflow Java Mailer Patches</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
			dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6716241</div></td>');
			dbms_output.put_line('<td>11.5.10.ATG.RUP5: 1-OFF: WF MANAGER UI ALLOWS ADDING 1 CUSTOM TAG ONLY</td>');
			dbms_output.put_line('<td div align="center">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
			dbms_output.put_line('</tr>'); 
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6836141</div></td>');
			dbms_output.put_line('<td>1OFF:6511028: WORKFLOW SERVICE CONTAINER CONSUMING A LOT TEMP LOBs (Superseded by 7268412)</td>');
			dbms_output.put_line('<td div align="center">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch6||'</td>');
			dbms_output.put_line('</tr>');             
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6901563</div></td>');
			dbms_output.put_line('<td>BACKPORT: 6833151: INCONSISTENCY IN CORRID OF WF_NOTIFICATION_OUT AQ (Fix of 6441940 and 6833151)</td>');
			dbms_output.put_line('<td div align="center">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch7||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6954271</div></td>');
			dbms_output.put_line('<td>1OFF:6528142:RUP5:email issue when APPLICATIONS SSO TYPE PROFILE set to PORTAL W/SSO</td>');
			dbms_output.put_line('<td div align="center">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch8||'</td>');
			dbms_output.put_line('</tr>'); 		       
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">8646317</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.5RUP:6613981/6162428: NO DATA FOUND IN WF_MAILER_PARAMETER</td>');
			dbms_output.put_line('<td div align="center">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch9||'</td>');
			dbms_output.put_line('</tr>'); 		       
			dbms_output.put_line('</table><BR>');  	       		       
		       
        elsif (:rup = 'RUP6') then 

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6720592';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '7365544';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '5749648';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6836141';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6802716';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '7268412';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '16482054';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '8746145';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch9
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '17341836';


			dbms_output.put_line('<p><b>Workflow Development recommends the following Java Mailer Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Java Mailer Patches</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
			dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6720592</div></td>');
			dbms_output.put_line('<td>1OFF: NOTIFICATION MAILER TIME OUT MESSAGES, NEEDS RESTART AND MAILER PERFORMANCE ISSUE AFTER RUP5</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">7365544</div></td>');
			dbms_output.put_line('<td>1OFF:7278229:ATG_PF.H RUP6: MAILER DOWN WITH:JAVA.LANG.STRINGINDEXOUTOFBOUNDSEX</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">5749648</div></td>');
			dbms_output.put_line('<td>1OFF: EMAIL NOTIFICATIONS DISPLAY ERROR MESSAGE AS INSUFFICIENT PRIVILEGE</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6836141</div></td>');
			dbms_output.put_line('<td>1OFF:6511028: WORKFLOW SERVICE CONTAINER CONSUMING A LOT TEMP LOBs</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6802716</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.5:6242825:ENCODING FOR MAILTO URIS IN HTML RESPONSE E-MAILS REQUIRES CORRECTION</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch5||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">7268412</div></td>');
			dbms_output.put_line('<td>1OFF:6324545: MORE THAN 10 ATTACHEMENTS IN EMAIL AND CLOB ATTR IN MESSAGE BODY ISSUES</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch6||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">16482054</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.6RUP:10414698:MAILER INBOUND PROCESSOR STOPS WORKING AFTER JAVAX.MAIL.MESSAGEREMOVEDEXCEPTION</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch7||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">8746145</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.6:7829071:ORA-06502 PL/SQL: NUMERIC OR VALUE IN WF_ENGINE</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch8||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">17341836</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.RUP6:16589389: MAILER THROWS JAVAX.MAIL.INTERNET.ADDRESSEXCEPTION, WHEN EMAIL ADDRESS IS LONG FORMAT</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch9||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('</table><BR>'); 

			dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended Java Mailer patches that are missing.</b><br>');
			dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
			dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');


			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '7691035';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '8324328';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '8487454';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '8441656';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '8651188';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '8881538';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '6616500';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '10369643';

			dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Workflow Java Mailer Patches</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
			dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');    
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">7691035</div></td>');
			dbms_output.put_line('<td>BPORT:7641725:11.5.10.RUP6:NOTIFICATIONS STUCK IN WF_NOTIFICATION_OUT AFTER THEY ARE REASSIGNED</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">8324328</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.6:7595341:INVALID ALTER SESSION ERROR ON SCRIPT WFNTFCU2.SQL</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">8487454</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.RUP6:6613981:NO DATA FOUND IN WF_MAILER_PARAMETER.GETVALUEFORCORR</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">8441656</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.6:6993909:MULTIPART/RELATED DISABLES ATTACHMENT ICON IN EMAILS SENT BY MS EXCHANGE SERVER</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">8651188</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.6:8552982:FURTHER TOKEN SUBSTITUTION NOT WORKING IN TEXT RETURNED BY PLSQL DOC ATTRIBUTE</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch5||'</td>');
			dbms_output.put_line('</tr>'); 
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">8881538</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.6:7718246:HEADER TABLE IN E-MAIL BODY APPEARS WITH SOLID BORDER( INCLUDES 1OFFs 8651188, 8441656 and FIX OF BUG 6242825 FOR BLACKBERRY)</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch6||'</td>');
			dbms_output.put_line('</tr>'); 
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">6616500</div></td>');
			dbms_output.put_line('<td>1OFF:5963671:ON11.5.10.2 RUP6: NOTIFICATION MAILER TIME OUT MSGS, NEEDS RESTART</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch7||'</td>');
			dbms_output.put_line('</tr>'); 
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">10369643</div></td>');
			dbms_output.put_line('<td>SYSTEM HANGS BECUASE OF NO SPACE CAUSED BY WF_NOTIFICATION_OUT GROWTH IN APPLSYS</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch8||'</td>');
			dbms_output.put_line('</tr>'); 
			dbms_output.put_line('</table><BR>');
		       
        elsif (:rup = 'RUP7') then 
		       
			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '9383048';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '13029817';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '9149988';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '17504381';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '17581731';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '18369765';

			dbms_output.put_line('<p><b>Workflow Development recommends the following Java Mailer Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Java Mailer Patches</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
			dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">9383048</div></td>');
			dbms_output.put_line('<td>1OFF:9361993:11.5.10.7:INBOUND MAILER GOING DOWN:REPLY BUTTON USED: ORACLE BEEHIVE</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">13029817</div></td>');
			dbms_output.put_line('<td>1OFF:10414698:11I.ATG_PF.H.RUP7:MAILER INBOUND PROCESSOR STOPS WORKING AFTER JAVAX.MAIL.MESSAGEREMOVEDEXCEPTION</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">9149988</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.7:9136998:NOTIFICATION MAILER GOES DOWN DURING RESPONSE PROCESSING</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">17504381</div></td>');
			dbms_output.put_line('<td>1OFF:11i.ATG_PF.H.RUP7:16317773:SMTPSENDFAILEDEXCEPTION CAUSING NOTIFICATION PREFERENCE DISABLED</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">17581731</div></td>');
			dbms_output.put_line('<td>1OFF:11i.ATG_PF.H.RUP7:9506401:12.1.3 TEST: ORA-20002 WHEN ASSIGNING A ROLE HIERARCHY</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch5||'</td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">18369765</div></td>');
			dbms_output.put_line('<td>1OFF:11I.ATG_PF.H.RUP7: process activities are executed multiple times after an event-receiving activity</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch6||'</td>');
			dbms_output.put_line('</tr>');			
			dbms_output.put_line('</table><BR>'); 

			dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended Java Mailer patches that are missing.</b><br>');
			dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
			dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '9278820';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '12698085';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '12927781';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '17446951';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '17477210';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '18061822';

			dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Workflow Java Mailer Patches</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
			dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');    
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">9278820</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.RUP7:9113411:NOTIFICATION FAILS TO BE GENERATED WHEN A DOCX DOCUMENT IS ATTACHED</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">12698085</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.7:10130433 BACKPORT: SHOW ACTUAL ERROR MESSAGE INSTEAD OF [WFMLR_DOCUMENT_ERROR] WHEN BUILDING NOTIFICATION CONTENT</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">12927781</div></td>');
			dbms_output.put_line('<td>1OFF:9174194:11I.ATG_PF.H.RUP7:NULLPOINTEREXCEPTION AFTER 451 TIMEOUT WAITING FOR CLIENT INPUT ERROR</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">17446951</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.RUP7:14041989: MAILER IS THROWING SAXPARSEEXCEPTION IF #WFM_FROM ATTR HAS FULL EMAIL ADDRESS</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
			dbms_output.put_line('</tr>');     
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">17477210</div></td>');
			dbms_output.put_line('<td>1OFF:11I.ATG_PF.H.RUP7:MAILTO LINKS ARE NOT WORKING IN REDIFF MAIL</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch5||'</td>');
			dbms_output.put_line('</tr>'); 
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">18061822</div></td>');
			dbms_output.put_line('<td>1OFF:11.5.10.RUP7:13789492:UNEXPECTED URL PARAMETERS IN THE NOTIFICATION BODY</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
			dbms_output.put_line('<td align="center" bgcolor="#'||:ptch6||'</td>');
			dbms_output.put_line('</tr>'); 
			dbms_output.put_line('</table><BR>');	
		
 	    else
		    dbms_output.put_line('There are no Development suggested 1-Off Workflow Java Mailer patches available for this version.<br><br>');

		end if;


	when :apps_rel = '12.0.4' then	       
	       
		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '7277944';

		dbms_output.put_line('<p><b>Workflow Development recommends the following Java Mailer Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
		dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		dbms_output.put_line('<td><b>Patch #</b></td>');
		dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Java Mailer Patches</b></td>');
		dbms_output.put_line('<td align="center"><b>Type</b></td>');
		dbms_output.put_line('<td align="center"><b>Status</b></td>');
		dbms_output.put_line('</tr>');
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">7277944</div></td>');
		dbms_output.put_line('<td>1OFF:12.0.4, 12.0.3: WORKFLOW MAILER DOWN WITH :JAVA.LANG.STRINGINDEXOUTOFBOUNDSEXCEPTION</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
		dbms_output.put_line('</tr>');
		dbms_output.put_line('</table><BR>'); 

		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td>');
		dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended Java Mailer patches that are missing.</b><br>');
		dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
		dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
		dbms_output.put_line('</td></tr></tbody></table><BR>');

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '8225521';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '8772399';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '6767410';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '9801387';

		dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		dbms_output.put_line('<td><b>Patch #</b></td>');
		dbms_output.put_line('<td align="center"><b>Workflow Java Mailer Patches</b></td>');
		dbms_output.put_line('<td align="center"><b>Type</b></td>');
		dbms_output.put_line('<td align="center"><b>Status</b></td>');
		dbms_output.put_line('</tr>');    
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">8225521</div></td>');
		dbms_output.put_line('<td>1OFF:7007150:12.0.4:WORKFLOW SYSTEM SHOULD BE ACTUAL USER WHEN NOTIFICATION APPROVED BY MANY USERS</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">8772399</div></td>');
		dbms_output.put_line('<td>1OFF:12.0.4:8645704:INVALID RFI EMAILS STOP THE MAILER FROM PROCESSING RESPONSES</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">6767410</div></td>');
		dbms_output.put_line('<td>1-OFF:12.0.4:EMAIL NOTIFICATIONS DISPLAY ERROR MESSAGE AS INSUFFICIENT PRIVILEGE</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">9801387</div></td>');
		dbms_output.put_line('<td>1OFF:12.0.4:9411678:GETTING JAVA.IO.IOEXCEPTION WHILE PARSING FOR NID STRING (Superseded by 10428040:R12.OWF.A)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('</table><BR>');      

	when :apps_rel = '12.0.6' then

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '7630298';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '7709109';				   
				 
			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '7606173';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '9255725';				   

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '9853165';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '10428040';

			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
			FROM AD_BUGS b
			WHERE b.BUG_NUMBER IN '8627180';				   

	                 
				dbms_output.put_line('<p><b>Workflow Development recommends the following Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
				dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
				dbms_output.put_line('<td><b>Patch #</b></td>');
				dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
				dbms_output.put_line('<td align="center"><b>Type</b></td>');
				dbms_output.put_line('<td align="center"><b>Status</b></td>');
				dbms_output.put_line('</tr>');
				dbms_output.put_line('<tr bordercolor="#000066">');
				dbms_output.put_line('<td>');
				dbms_output.put_line('<div align="center">7630298</div></td>');
				dbms_output.put_line('<td>1OFF:7585376:12.0.6:ERROR INVALID ALTER SESSION ON SCRIPT WFNTFCU2.SQL</td>');
				dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
				dbms_output.put_line('</tr>'); 
				dbms_output.put_line('<tr bordercolor="#000066">');
				dbms_output.put_line('<td>');
				dbms_output.put_line('<div align="center">7709109</div></td>');
				dbms_output.put_line('<td>1OFF:12.0.6:6767410:EMAIL NOTIFICATIONS DISPLAY ERROR MESSAGE AS INSUFFICIENT PRIVILEGE</td>');
				dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
				dbms_output.put_line('</tr>'); 
				dbms_output.put_line('<tr bordercolor="#000066">');
				dbms_output.put_line('<td>');
				dbms_output.put_line('<div align="center">7606173</div></td>');
				dbms_output.put_line('<td>1OFF: 12.0.6: 7535451: APPLICATION/PDF IS NOT AN ALLOWED CONTENT_TYPE FOR THE BODYPART</td>');
				dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
				dbms_output.put_line('</tr>'); 
				dbms_output.put_line('<tr bordercolor="#000066">');
				dbms_output.put_line('<td>');
				dbms_output.put_line('<div align="center">9255725</div></td>');
				dbms_output.put_line('<td>1OFF:12.0.6:9169815:NULLPOINTEREXCEPTION WHEN 451 TIMEOUT WAITING FOR CLIENT INP</td>');
				dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
				dbms_output.put_line('</tr>'); 
				dbms_output.put_line('<tr bordercolor="#000066">');
				dbms_output.put_line('<td>');
				dbms_output.put_line('<div align="center">9853165</div></td>');
				dbms_output.put_line('<td>1OFF:12.0.6:9450904:GETINFOFROMMAIL API NEEDS TO IDENTIFY ROLE NAME ACCURATELY</td>');
				dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch5||'</td>');
				dbms_output.put_line('</tr>');
				dbms_output.put_line('<tr bordercolor="#000066">');
				dbms_output.put_line('<td>');
				dbms_output.put_line('<div align="center">10428040</div></td>');
				dbms_output.put_line('<td>1OFF:12.0.6:10012972:MAILER INBOUND PROCESSOR STOPS WORKING AFTER JAVAX.MAIL.MESSAGEREMOVEDEXCEPTION</td>');
				dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch6||'</td>');
				dbms_output.put_line('</tr>'); 
				dbms_output.put_line('<tr bordercolor="#000066">');
				dbms_output.put_line('<td>');
				dbms_output.put_line('<div align="center">8627180</div></td>');
				dbms_output.put_line('<td>1OFF:12.0.6:PERFORMANCE ISSUE WITH WF_NOTIFICATION.SEND()</td>');
				dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch7||'</td>');
				dbms_output.put_line('</tr></table><BR>'); 

				dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
				dbms_output.put_line('<tbody><tr><td>');
				dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended patches that are missing.</b><br>');
				dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
				dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
				dbms_output.put_line('</td></tr></tbody></table><BR>');
	
		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '8813679';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '9616995';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '11767973';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '11875960';

		dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		dbms_output.put_line('<td><b>Patch #</b></td>');
		dbms_output.put_line('<td align="center"><b>Workflow Java Mailer Patches</b></td>');
		dbms_output.put_line('<td align="center"><b>Type</b></td>');
		dbms_output.put_line('<td align="center"><b>Status</b></td>');
		dbms_output.put_line('</tr>');    
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">8813679</div></td>');
		dbms_output.put_line('<td>1OFF:12.0.6:7718246:HEADER TABLE IN E-MAIL BODY APPEARS WITH SOLID BORDER</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">9616995</div></td>');
		dbms_output.put_line('<td>1OFF:12.0.6:8341801:REQUEST MORE INFORMATION TEMPLATE SEEDING RANDOM USERS</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">11767973</div></td>');
		dbms_output.put_line('<td>BACKPORT:10394986:12.0.6:LOBSUBSTITUTE RETURNS INCORRECT RESULT IF THE TEMPLATE CONTAINS NOTIFICATION_ID</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">11875960</div></td>');
		dbms_output.put_line('<td>BACKPORT:12.0.6:9113411:NOTIFICATION FAILS TO BE GENERATED WHEN A DOCX DOCUMENT IS ATTACHED</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('</table><BR>');



	
		
	when :apps_rel = '12.1.1' then

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '9055472';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '9379328';

		dbms_output.put_line('<p><b>Workflow Development recommends the following Java Mailer Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
		dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		dbms_output.put_line('<td><b>Patch #</b></td>');
		dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Java Mailer Patches</b></td>');
		dbms_output.put_line('<td align="center"><b>Type</b></td>');
		dbms_output.put_line('<td align="center"><b>Status</b></td>');
		dbms_output.put_line('</tr>');
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">9055472</div></td>');
		dbms_output.put_line('<td>1OFF:R12.1.1:9084150:INBOUND MAILER GOING DOWN:MORE INFO ISSUE AND RESPONSE ATTACHMENT</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
		dbms_output.put_line('</tr>');             
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">9379328</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.1:9320224:INBOUND MAILER GOING DOWN:REPLY BUTTON USED: ORACLE BEEHIVE</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
		dbms_output.put_line('</tr>');             
		dbms_output.put_line('</table><BR>');

		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td>');
		dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended Java Mailer patches that are missing.</b><br>');
		dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
		dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
		dbms_output.put_line('</td></tr></tbody></table><BR>');

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '8832674';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '8515763';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '9251305';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '9437814';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '9451829';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '9739567';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '10276282';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '12383369';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch9
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '12793695';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch10
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '14699743';

		dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		dbms_output.put_line('<td><b>Patch #</b></td>');
		dbms_output.put_line('<td align="center"><b>Workflow Java Mailer Patches</b></td>');
		dbms_output.put_line('<td align="center"><b>Type</b></td>');
		dbms_output.put_line('<td align="center"><b>Status</b></td>');
		dbms_output.put_line('</tr>');    
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">8832674</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.1:CONSOLIDATE POST 12.1.1 ONE-OFFs FOR OWF (bugs 5676227,8729116,7308460,8638909 ...)</td>');
		dbms_output.put_line('<td div align="center">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
		dbms_output.put_line('</tr>'); 		       
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">8515763</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.1:EXTERNAL IRECRUITMENT REGISTRATION AND PASSWORD RESET DOES NOT WORK FOR HOTMAIL AND YAHOO USERS</td>');
		dbms_output.put_line('<td div align="center">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
		dbms_output.put_line('</tr>'); 		       
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">9251305</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.1:9180569 - CLOSED:  MAIL IS SENT WHEN AN FYI NTF IS CLOSED FROM UI</td>');
		dbms_output.put_line('<td div align="center">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
		dbms_output.put_line('</tr>'); 		       
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">9437814</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.1:9113411:NOTIFICATION FAILS TO BE GENERATED FOR *.DOCX ATTACHMENT</td>');
		dbms_output.put_line('<td div align="center">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
		dbms_output.put_line('</tr>'); 		       
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">9451829</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.1: 8802669:NTF DISAPPEARS AS MORE_INFO_ROLE IS UPDATED WITH EMAIL_ADDRESS</td>');
		dbms_output.put_line('<td div align="center">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch5||'</td>');
		dbms_output.put_line('</tr>'); 		       
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">9739567</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.1:9544115:PO APPROVAL NOTIFICATION DOES NOT REFRESH WITH CHANGE</td>');
		dbms_output.put_line('<td div align="center">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch6||'</td>');
		dbms_output.put_line('</tr>'); 		       
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">10276282</div></td>');
		dbms_output.put_line('<td>NLS: JAPANESE CHARS ARE GARBLED IN MS OUTLLOK 2007 English version for Multilingual User Interface (CUSTOM FIX For this customer, Applicable for R12.1.2/12.1.3)</td>');
		dbms_output.put_line('<td div align="center">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch7||'</td>');
		dbms_output.put_line('</tr>'); 		       
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">12383369</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.1:HTML TAGS APPEARED TOGETHER WITH THE MORE INFO ANSWER IN EMAIL NOTIFICATION</td>');
		dbms_output.put_line('<td div align="center">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch8||'</td>');
		dbms_output.put_line('</tr>'); 		       
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">12793695</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.1:WF_MAIL_UTIL.PARSECONTENTTYPE() API IS FAILING WHEN FILE NAME HAS CHINESE CHARACTERS IN THE CONTENTTYPE FIELD</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch9||'</td>');
		dbms_output.put_line('</tr>'); 		       
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">14699743</div></td>');
		dbms_output.put_line('<td>1OFF:9757926:12.1.1:GETTING JAVA.NET.MALFORMEDURLEXCEPTION FOR AN ABSOLUTE URI WHILE SENDING OA FRAMEWORK BASED NOTIFICATION</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch10||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('</table><BR>');
		
	when :apps_rel = '12.1.2' then
		       
		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '20230836';

		dbms_output.put_line('<p><b>Workflow Development recommends the following Java Mailer Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
		dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		dbms_output.put_line('<td><b>Patch #</b></td>');
		dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Java Mailer Patches</b></td>');
		dbms_output.put_line('<td align="center"><b>Type</b></td>');
		dbms_output.put_line('<td align="center"><b>Status</b></td>');
		dbms_output.put_line('</tr>');
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">20230836</div></td>');
		dbms_output.put_line('<td>OWF:12.1.3+ Recommended Patch Collection DEC-2014</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('</table><BR>');

		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td>');
		dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended Java Mailer patches that are missing.</b><br>');
		dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
		dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
		dbms_output.put_line('</td></tr></tbody></table><BR>');

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '9868639';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '11678104';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '11850834';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '13257382';

		dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		dbms_output.put_line('<td><b>Patch #</b></td>');
		dbms_output.put_line('<td align="center"><b>Workflow Java Mailer Patches</b></td>');
		dbms_output.put_line('<td align="center"><b>Type</b></td>');
		dbms_output.put_line('<td align="center"><b>Status</b></td>');
		dbms_output.put_line('</tr>');    
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">9868639</div></td>');
		dbms_output.put_line('<td>11OFF:12.1.2:9757926:GETTING JAVA.NET.MALFORMEDURLEXCEPTION WHILE SENDING OA FRAMEWORK BASED NOTIFICATION (Superseded by 20230836)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">11678104</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.2:9320224:INBOUND MAILER GOING DOWN:REPLY BUTTON USED: ORACLE BEEHIVE (Superseded by 20230836)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">11850834</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.2:9733998:GETTING ERROR JAVA.IO.IOEXCEPTION WHILE PARSING FOR NID IN THE INPUTSTREAM (Superseded by 20230836)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">13257382</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.2:10413964:MAILER INBOUND PROCESSOR STOPS WORKING AFTER JAVAX.MAIL.MESSAGEREMOVEDEXCEPTION (Superseded by 20230836)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('</table><BR>');	

	when :apps_rel = '12.1.3' then

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '9379328';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '9055472';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '13786156';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '14474358';				   

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '17618508';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '18826085';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '19329720';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '20230836';

		dbms_output.put_line('<p><b>Workflow Development recommends the following Java Mailer Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
		dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		dbms_output.put_line('<td><b>Patch #</b></td>');
		dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Java Mailer Patches</b></td>');
		dbms_output.put_line('<td align="center"><b>Type</b></td>');
		dbms_output.put_line('<td align="center"><b>Status</b></td>');
		dbms_output.put_line('</tr>');
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">9379328</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.1:9320224:INBOUND MAILER GOING DOWN:REPLY BUTTON USED: ORACLE BEEHIVE EXTENSIONS FOR OUTLOOK</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
		dbms_output.put_line('</tr>');             
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">9055472</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.1:9084150:NOTIFICATION MAILER GOES DOWN DURING RESPONSE PROCESSING</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
		dbms_output.put_line('</tr>');
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">13786156</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3: MAILER IS THROWING "SAXPARSEEXCEPTION" ERROR WHEN #WFM_FROM MESSAGE ATTRIBUTE HAS FULL EMAIL ADDRESS</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
		dbms_output.put_line('</tr>'); 		       
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">14474358</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:WF MAILER CAN NOT CONNECT TO MAIL STORE WHEN SPECIFIC MIME TYPE IS RECEIVED</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">17618508</div></td>');
		dbms_output.put_line('<td>Latest Recommended Patch Collection for OWF 12.1.3+ Dec 2013 (Superseded by 20230836)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch5||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">18826085</div></td>');
		dbms_output.put_line('<td>Latest Recommended Patch Collection for OWF 12.1.3+ Jun 2014 (Superseded by 20230836)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch6||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">19329720</div></td>');
		dbms_output.put_line('<td>Latest Recommended Patch Collection for OWF 12.1.3+ JUL 2014 (Superseded by 20230836)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch7||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">20230836</div></td>');
		dbms_output.put_line('<td>OWF:12.1.3+ Recommended Patch Collection DEC-2014</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch8||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('</table><BR>');

		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td>');
		dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended patches that are missing.</b><br>');
		dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
		dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
		dbms_output.put_line('</td></tr></tbody></table><BR>');


		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '11684796';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '12540549';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '12898568';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '13543331';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '13449810';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '11905988';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '13786156';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '13609378';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch9
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '14676206';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch10
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '13903857';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch11
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '14474358';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch12
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '16559330';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch13
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '16397465';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch14
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '16317773';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch15
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '17704236';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch16
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '17987270';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch17
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '17756944';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch18
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '18751696';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch19
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '18770191';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch20
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '18751696';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch21
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '18345086';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch22
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '20428664';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch23
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '20536609';

		dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		dbms_output.put_line('<td><b>Patch #</b></td>');
		dbms_output.put_line('<td align="center"><b>Workflow Java Mailer Patches</b></td>');
		dbms_output.put_line('<td align="center"><b>Type</b></td>');
		dbms_output.put_line('<td align="center"><b>Status</b></td>');
		dbms_output.put_line('</tr>');
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">11684796</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:VALUE OF SENT DATE FIELD IN EMAIL NOTIFICATIONS INTERMITTENTLY POPULATED (Superseded by 12540549)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">12540549</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:QUESTION BY PROXY IS NOT DISPLAYED IN EMAIL (Superseded by 13786156)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center"> 12898568</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:WF MAILER IS THROWING NULLPOINTER AND COM.SUN.MAIL.SMTP.SMTPSENDFAILEDEXCEPTION: [EOF] WHILE SENDING MESSAGES (Superseded by 13979673,13903857)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch3||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">13543331</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:13488289:MAILER IS THROWING PARSEEXCEPTION WHILE PARSING MIME MESSAGES HAVING CONTENT-TYPE PARAMETER VALUES NOT ENCLOSED WITHIN (Superseded by 14474358)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch4||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">13449810</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:10413964:MAILER INBOUND PROCESSOR STOPS WORKING AFTER JAVAX.MAIL.MESSAGEREMOVEDEXCEPTION (Superseded by 20230836)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch5||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center"> 	 11905988</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:NOTIFICATION BODY CONTAINS UNEXPECTED URL PARAMETERS TEXT INSTEAD OF ACTUAL CONTENT (Superseded by 20230836)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch6||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center"> 	 13786156</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3: MAILER IS THROWING "SAXPARSEEXCEPTION" ERROR WHEN #WFM_FROM MESSAGE ATTRIBUTE HAS FULL EMAIL ADDRESS (Superseded by 16397465)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch7||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">13609378</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:MAILER FAILS TO DETECT SMTP AUTHENTICATION FOR SOME SERVERS (Superseded by 14676206)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch8||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">14676206</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:JAVAX.MAIL.SENDFAILEDEXCEPTION: 554 5.7.1 SENDER ADDRESS REJECTED: ACCESS DENIED</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch9||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">13903857</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:SMTPSENDFAILEDEXCEPTION: [EOF] WHEN SENDING EMAIL NOTIFICATIONS (Superseded by 16559330)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch10||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">14474358</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:WF MAILER CAN NOT CONNECT TO MAIL STORE WHEN SPECIFIC MIME TYPE IS RECEIVED</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch11||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">16559330</div></td>');
		dbms_output.put_line('<td>1OFF:15927384:WORKFLOW MAILER - SMTPADDRESSFAILEDEXCEPTION: 550 NOT AUTHENTICATED (Superseded by 16317773)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch12||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">16397465</div></td>');
		dbms_output.put_line('<td>1OFF: 12.1.3:SUMMARY NOTIFICATIONS ARE SENT MORE THAN ONE TIME (Superseded by 17704236)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch13||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">16317773</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:SMTPSENDFAILEDEXCEPTION CAUSING NOTIFICATION PREFERENCE DISABLED (Superseded by 20230836)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch14||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">17704236</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:16868453: JAVAX.MAIL.INTERNET.ADDRESSEXCEPTION, WHEN EMAIL ADDRESS IS LONG FORMAT</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch15||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">17987270</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:17513104:TCH12C:INT1213:WIN64:WORKFLOW BACKGROUND PROCESS IS FAILING WITH ORA-06502</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch16||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">17756944</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:MAILER NOT ABLE TO AUTHENTICATE TO SMTP SERVER NEEDING TLS SESSION FIRST</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch17||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">18751696</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:INCORRECT FROM IN ACTION HISTORY TABLE WHEN NOTIFICATION IS REASSIGNED</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch18||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">18770191</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:18497619:WF_OAM_METRICS DOES NOT POPULATE DATA FOR WF_BPEL_QAGENT IN WF_AGENTS</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch19||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">18751696</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:INCORRECT FROM IN ACTION HISTORY TABLE WHEN NOTIFICATION IS REASSIGNED</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch20||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">18345086</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3: SMTP AUTHENTICATION FAILS WITH SHARED MAIL BOX ACCOUNT CONTAINING DOMAIN IN USERNAME (Superseded by 20428664)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch21||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">20428664</div></td>');
		dbms_output.put_line('<td>11OFF:12.1.3:20137109:MAILER NOT USING CORRECT SMTP CONFIGURATION FOR UNSOLICITED AND INVALID EMAILS (Superseded by 20536609)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch22||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">20536609</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:20277438:SET STARTTLS PROPERTY ONLY WHEN SMTP SERVER SUPPORTS SSL/TL</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch23||'</td>');
		dbms_output.put_line('</tr>');     
		dbms_output.put_line('</table><BR>');


	when :apps_rel = '12.2.3' then

		dbms_output.put_line('<p><b>Workflow Development recommends the following Java Mailer Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
		dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		dbms_output.put_line('<td><b>Patch #</b></td>');
		dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Java Mailer Patches</b></td>');
		dbms_output.put_line('<td align="center"><b>Type</b></td>');
		dbms_output.put_line('<td align="center"><b>Status</b></td>');
		dbms_output.put_line('</tr>');
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center"></div></td>');
		dbms_output.put_line('<td>There are no recommended Java Mailer patches from WF Development for your '|| :apps_rel ||' instance.</td>');
		dbms_output.put_line('<td div align="center"></div></td>');
		dbms_output.put_line('<td align="center" </td>');
		dbms_output.put_line('</tr>');     		       
		dbms_output.put_line('</table><BR>'); 

		dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		dbms_output.put_line('<tbody><tr><td>');
		dbms_output.put_line('There are no Workflow Java Mailer patches currently recommended by Workflow Development for this Oracle Applications '||:apps_rel||' instance.<br>');
		dbms_output.put_line('Nice job!<br><br>');
		dbms_output.put_line('</td></tr></tbody></table><BR>');

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '18842914';

		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
		FROM AD_BUGS b
		WHERE b.BUG_NUMBER IN '19133548';

		dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Java Mailer Patches on top of '|| :apps_rel ||'.</b><br>');
		dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		dbms_output.put_line('<td><b>Patch #</b></td>');
		dbms_output.put_line('<td align="center"><b>Workflow Java Mailer Patches</b></td>');
		dbms_output.put_line('<td align="center"><b>Type</b></td>');
		dbms_output.put_line('<td align="center"><b>Status</b></td>');
		dbms_output.put_line('</tr>');
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">18842914</div></td>');
		dbms_output.put_line('<td>1OFF:12.2.3:18839249 BACKPORT: MAILER NOT ABLE TO AUTHENTICATE TO SMTP SERVER NEEDING TLS SESSION FIRST (Superseded by 19133548)</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch1||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('<tr bordercolor="#000066">');
		dbms_output.put_line('<td>');
		dbms_output.put_line('<div align="center">19133548</div></td>');
		dbms_output.put_line('<td>1OFF:12.1.3:SET OVERRIDE ADDRESS FROM OAM UI THROWING SMTPSENDFAILEDEXCEPTION: 530 5.7.0 MUST ISSUE A STARTTLS</td>');
		dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td>');
		dbms_output.put_line('<td align="center" bgcolor="#'||:ptch2||'</td>');
		dbms_output.put_line('</tr>'); 
		dbms_output.put_line('</table><BR>');

		
	else

       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td>');
       dbms_output.put_line('There are no 1-Off Java Mailer patches suggested by Workflow Development for this Oracle Applications '||:apps_rel||' instance.<br><br>');
       dbms_output.put_line('<p>For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1#ntfmlrs"');
       dbms_output.put_line('target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br><br>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');

       dbms_output.put_line('<A href="#top"><font size="-1">Back to Top</font></A><BR><BR>');

  end CASE;

	dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
	dbms_output.put_line('<tbody><tr><td>');
	dbms_output.put_line('<B>These 1-Off Java Mailer patches are released by Workflow Development to resolve known issues on top of '||:apps_rel||'.</B><br>');
	dbms_output.put_line('<p>Workflow Development suggests reviewing any 1-Offs (General/Superseded) that are missing.<br>');
	dbms_output.put_line('Please review each patch to verify if they should be applied to your instance.<br>');
	dbms_output.put_line('Superseded patches should be included in the patches that supersede them, except in some cases where replacement patches contain the same files, then the superseded patch may be listed also.<br><br>');
	dbms_output.put_line('For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1#ntfmlrs"');
	dbms_output.put_line('target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br>');
	dbms_output.put_line('</p></td></tr></tbody></table><BR>');

	dbms_output.put_line('<A href="#top"><font size="-1">Back to Top</font></A><BR><BR>');

else
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><b>Attention:<br>');    
    dbms_output.put_line('The Java Mailer is an optional feature.</b><br>');
    dbms_output.put_line('Currently, on this instance the Workflow Java Mailer is not running, so skipping this section.');
    dbms_output.put_line('</p></td></tr></tbody></table>');  
end if;

end;
/
prompt </blockquote>


REM
REM ******* Check the Status of Workflow Services *******
REM

prompt <a name="wfadv150"></a><B><font size="+1">Workflow Services Status</font></B>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows5sql1(){var row = document.getElementById("s5sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Check the Status of Workflow Services</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows5sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s5sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="11" height="253">
prompt       <blockquote><p align="left">
prompt          select  fcq.USER_CONCURRENT_QUEUE_NAME, fsc.COMPONENT_NAME,<br>
prompt          DECODE(fcp.OS_PROCESS_ID,NULL,'Not Running',fcp.OS_PROCESS_ID), <br>
prompt          fcq.MAX_PROCESSES, fcq.RUNNING_PROCESSES, v.PARAMETER_VALUE,<br>
prompt          fcq.ENABLED_FLAG, fsc.COMPONENT_ID, fsc.CORRELATION_ID,<br>
prompt          fsc.STARTUP_MODE, fsc.COMPONENT_STATUS<br>
prompt          from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, <br>
prompt          APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v<br>
prompt          where v.COMPONENT_ID=fsc.COMPONENT_ID<br>
prompt          and fcq.MANAGER_TYPE = fcs.SERVICE_ID <br>
prompt          and fcs.SERVICE_HANDLE = 'FNDCPGSC' <br>
prompt          and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)<br>
prompt          and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) <br>
prompt          and fcq.application_id = fcp.queue_application_id(+) <br>
prompt          and fcp.process_status_code(+) = 'A'<br>
prompt          and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'<br>
prompt          order by fcp.OS_PROCESS_ID, fsc.STARTUP_MODE;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CONTAINER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROCID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TARGET</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTUAL</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>#THREADS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ENABLED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CORRELATION_ID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTUP_MODE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||fcq.USER_CONCURRENT_QUEUE_NAME||'</TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_NAME||'</TD>'||chr(10)|| 
'<TD>'||DECODE(fcp.OS_PROCESS_ID,NULL,'Not Running',fcp.OS_PROCESS_ID)||'</TD>'||chr(10)|| 
'<TD><div align="center">'||fcq.MAX_PROCESSES||'</div></TD>'||chr(10)|| 
'<TD><div align="center">'||fcq.RUNNING_PROCESSES||'</div></TD>'||chr(10)|| 
'<TD><div align="center">'||v.PARAMETER_VALUE||'</div></TD>'||chr(10)|| 
'<TD><div align="center">'||fcq.ENABLED_FLAG||'</div></TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_ID||'</TD>'||chr(10)|| 
'<TD>'||fsc.CORRELATION_ID||'</TD>'||chr(10)|| 
'<TD>'||fsc.STARTUP_MODE||'</TD>'||chr(10)|| 
'<TD>'||fsc.COMPONENT_STATUS||'</TD></TR>'
from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
where v.COMPONENT_ID=fsc.COMPONENT_ID
and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
and fcq.application_id = fcp.queue_application_id(+) 
and fcp.process_status_code(+) = 'A'
and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
order by fcp.OS_PROCESS_ID, fsc.STARTUP_MODE;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Check the Concurrent Tier Environment Settings for the Java Mailer *******
REM

prompt <a name="wfadv151"></a><B><font size="+1">Concurrent Tier Environment Settings for the Java Mailer</font></B>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows5sql2(){var row = document.getElementById("s5sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Concurrent Tier</B></font></TD>
prompt     <TD COLSPAN=2 bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows5sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s5sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2 height="253">
prompt       <blockquote><p align="left">
prompt          select  VARIABLE_NAME, VALUE <br>
prompt          from FND_ENV_CONTEXT <br>
prompt          where CONCURRENT_PROCESS_ID in <br>
prompt                (select max(CONCURRENT_PROCESS_ID) from FND_CONCURRENT_PROCESSES<br>
prompt                 where CONCURRENT_QUEUE_ID in (select CONCURRENT_QUEUE_ID from FND_CONCURRENT_QUEUES where CONCURRENT_QUEUE_NAME = 'WFMLRSVC')<br>
prompt                   and QUEUE_APPLICATION_ID in (select APPLICATION_ID from FND_APPLICATION<br>
prompt           where APPLICATION_SHORT_NAME = 'FND'))<br>
prompt            and VARIABLE_NAME in ('APPL_TOP', 'APPLCSF', 'APPLLOG', 'FND_TOP', 'AF_CLASSPATH', 'AFJVAPRG', 'AFJRETOP', 'CLASSPATH', 'PATH', <br>
prompt          'LD_LIBRARY_PATH', 'ORACLE_HOME')<br>
prompt          order by VARIABLE_NAME;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ENV VARIABLE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PATH SETTING</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||VARIABLE_NAME || '</TD>'||chr(10)|| 
'<TD>'||VALUE||'</TD></TR>'
from FND_ENV_CONTEXT
where CONCURRENT_PROCESS_ID in
      (select max(CONCURRENT_PROCESS_ID) from FND_CONCURRENT_PROCESSES
       where CONCURRENT_QUEUE_ID in (select CONCURRENT_QUEUE_ID from FND_CONCURRENT_QUEUES where CONCURRENT_QUEUE_NAME = 'WFMLRSVC')
         and QUEUE_APPLICATION_ID in (select APPLICATION_ID from FND_APPLICATION
 where APPLICATION_SHORT_NAME = 'FND'))
  and VARIABLE_NAME in ('APPL_TOP', 'APPLCSF', 'APPLLOG', 'FND_TOP', 'AF_CLASSPATH', 'AFJVAPRG', 'AFJRETOP', 'CLASSPATH', 'PATH', 
'LD_LIBRARY_PATH', 'ORACLE_HOME')
order by VARIABLE_NAME;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>

REM
REM ******* Verify AutoClose_FYI Setting *******
REM

prompt <a name="wfadv123"></a><B><font size="+1">Verify AutoClose_FYI Setting</font></B>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows2sql2b(){var row = document.getElementById("2sql2b");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Verify AutoClose_FYI Setting</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows2sql2b()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="2sql2b" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="85">
prompt       <blockquote><p align="left">
prompt          select SC.COMPONENT_NAME, v.PARAMETER_DISPLAY_NAME, v.PARAMETER_VALUE<br>
prompt          from FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS SC<br>
prompt          where v.COMPONENT_ID=sc.COMPONENT_ID <br>
prompt          and v.parameter_name = 'AUTOCLOSE_FYI'<br>
prompt          order by sc.COMPONENT_ID;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PARAMETER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||SC.COMPONENT_NAME||'</TD>'||chr(10)|| 
'<TD>'||v.PARAMETER_DISPLAY_NAME||'</TD>'||chr(10)|| 
'<TD><div align="center">'||v.PARAMETER_VALUE||'</div></TD></TR>'
from FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS SC
where v.COMPONENT_ID=sc.COMPONENT_ID 
and v.parameter_name = 'AUTOCLOSE_FYI'
order by sc.COMPONENT_ID;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Check the status of the Workflow Notification Mailer(s) *******
REM

prompt <a name="wfadv152"></a><B><U>Check the status of the Workflow Notification Mailer(s) for this instance</B></U><BR>
prompt <blockquote>

declare

v_comp_id number;

cursor c_mailerIDs IS
	select fsc.COMPONENT_ID
	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
	where v.COMPONENT_ID=fsc.COMPONENT_ID
	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
	and fcq.application_id = fcp.queue_application_id(+) 
	and fcp.process_status_code(+) = 'A'
	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service';

begin

	select nvl(max(rownum), 0) into :mailer_cnt
	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
	where v.COMPONENT_ID=fsc.COMPONENT_ID
	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
	and fcq.application_id = fcp.queue_application_id(+) 
	and fcp.process_status_code(+) = 'A'
	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service';


  if (:mailer_cnt = 0) then

       dbms_output.put_line('There is no Mailer Service defined for this instance.<BR>');
       dbms_output.put_line('Check the setup of GSM to understand why the Mailer Service is not created or running.<BR><BR> ');

  elsif (:mailer_cnt = 1) then
 
       dbms_output.put_line('There is only one Notification mailer found on this instance.<BR>');
       dbms_output.put_line('The Workflow Notification Mailer is the default seeded mailer that comes with EBS. <BR><BR> ');
  
  else 
  
       dbms_output.put_line('There are multiple mailers found on this instance.<BR>');
       dbms_output.put_line('The seperate mailers will be looked at individually. <BR><BR> ');
       
  end if;
  
 
  OPEN c_mailerIDs;
  LOOP
  
    Fetch c_mailerIDs INTO v_comp_id;
  
    EXIT WHEN c_mailerIDs%NOTFOUND;
  
    if (:mailer_enabled = 'DISABLED') then
       
        dbms_output.put_line('The '|| :component_name ||' is currently ' || :mailer_enabled || ', so no email notifications can be sent. <BR>');
       
    elsif (:mailer_enabled = 'ENABLED') then
       
       	select fsc.COMPONENT_STATUS into :mailer_status
       	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
       	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
       	where v.COMPONENT_ID=fsc.COMPONENT_ID
       	and fsc.COMPONENT_ID = v_comp_id
       	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
       	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
       	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
       	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
       	and fcq.application_id = fcp.queue_application_id(+) 
       	and fcp.process_status_code(+) = 'A'
       	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
       	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service';

       	select nvl(fsc.CORRELATION_ID,'NULL') into :corrid
       	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
       	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
       	where v.COMPONENT_ID=fsc.COMPONENT_ID
       	and fsc.COMPONENT_ID = v_comp_id
       	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
       	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
       	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
       	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
       	and fcq.application_id = fcp.queue_application_id(+) 
       	and fcp.process_status_code(+) = 'A'
       	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
       	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service';
       	
       	select fsc.STARTUP_MODE into :startup_mode
       	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
       	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
       	where v.COMPONENT_ID=fsc.COMPONENT_ID
       	and fsc.COMPONENT_ID = v_comp_id
       	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
       	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
       	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
       	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
       	and fcq.application_id = fcp.queue_application_id(+) 
       	and fcp.process_status_code(+) = 'A'
       	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
       	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service';
       	
       	select fcq.USER_CONCURRENT_QUEUE_NAME into :container_name
       	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
       	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
       	where v.COMPONENT_ID=fsc.COMPONENT_ID
       	and fsc.COMPONENT_ID = v_comp_id
       	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
       	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
       	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
       	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
       	and fcq.application_id = fcp.queue_application_id(+) 
       	and fcp.process_status_code(+) = 'A'
       	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
       	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service';
        
	select fsc.COMPONENT_NAME into :component_name
	from APPS.FND_CONCURRENT_QUEUES_VL fcq, APPS.FND_CP_SERVICES fcs, 
	APPS.FND_CONCURRENT_PROCESSES fcp, fnd_svc_components fsc, FND_SVC_COMP_PARAM_VALS_V v
	where v.COMPONENT_ID=fsc.COMPONENT_ID
	and fsc.COMPONENT_ID = v_comp_id
	and fcq.MANAGER_TYPE = fcs.SERVICE_ID 
	and fcs.SERVICE_HANDLE = 'FNDCPGSC' 
	and fsc.concurrent_queue_id = fcq.concurrent_queue_id(+)
	and fcq.concurrent_queue_id = fcp.concurrent_queue_id(+) 
	and fcq.application_id = fcp.queue_application_id(+) 
	and fcp.process_status_code(+) = 'A'
	and v.PARAMETER_NAME = 'PROCESSOR_IN_THREAD_COUNT'
	and fcq.USER_CONCURRENT_QUEUE_NAME = 'Workflow Mailer Service';
       	
       	select v.PARAMETER_VALUE into :email_override 
       	from FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS fsc
       	where v.COMPONENT_ID=fsc.COMPONENT_ID 
       	and fsc.COMPONENT_ID = v_comp_id
       	and v.parameter_name = 'TEST_ADDRESS'
       	order by fsc.COMPONENT_ID, v.parameter_name;
       
       	select v.PARAMETER_VALUE into :expunge 
       	from FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS fsc
       	where v.COMPONENT_ID=fsc.COMPONENT_ID 
       	and fsc.COMPONENT_ID = v_comp_id
       	and v.parameter_name = 'EXPUNGE_ON_CLOSE';
       	
     
      dbms_output.put_line('The mailer called "'|| :component_name ||'" is ' || :mailer_enabled || ' with a component status of '|| :mailer_status ||'. ');
      
      dbms_output.put_line('<br>The mailer parameter called EXPUNGE_ON_CLOSE is set to "'|| :expunge ||'" for this mailer.<br>');
      
	 if (:email_override = 'NONE') then 

	    dbms_output.put_line('<BR>The Email Override (Test Address) feature is DISABLED as ' || :email_override || ' for '|| :component_name ||'. ');
	    dbms_output.put_line('<BR>This means that all emails with correlation_id of '|| :corrid ||' that get sent by '|| :component_name ||' will be sent to their intended recipients as expected when the mailer is running.<BR><BR> ');

	 elsif (:email_override is not null) then  

	    dbms_output.put_line('<BR>The Email Override (Test Address) feature is ENABLED to ' || :email_override || ' for '|| :component_name ||'.');
	    dbms_output.put_line('<BR>This means that all emails that get sent by  '|| :component_name ||' are re-routed and sent to this single Override email address (' || :email_override || ') when the '|| :component_name ||' is running.');
	    dbms_output.put_line('<BR>Please ensure this email address is correct.');
	    dbms_output.put_line('<BR>This is a standard setup for a production cloned (TEST or DEV) instance to avoid duplicate emails being sent to users.<BR><BR> ');

         end if;

    
      if (:mailer_status = 'DEACTIVATED_USER') then

          if (:startup_mode = 'AUTOMATIC') then 

    		 dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	         dbms_output.put_line('<tbody><tr><td> ');
	         dbms_output.put_line('<B>Warning:</B><BR>');
	         dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" is currently not running.<BR>');
	         dbms_output.put_line('<B>Action:</B><BR>');
	         dbms_output.put_line('If using the Java Mailer to send email notifications and alerts, please bounce the container : '|| :container_name ||'.<BR>'); 
	         dbms_output.put_line('via the Oracle Application Manager - Workflow Manager screen to automatically restart the component : '|| :component_name ||'.<BR>');
	         dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1191125.1" target="_blank">Note 1191125.1');
	         dbms_output.put_line('</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
	         dbms_output.put_line('If you need to test the Mailer setup, then please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=748421.1" target="_blank">Note 748421.1');
	         dbms_output.put_line('</a> - Java Mailer Setup Diagnostic Test (ATGSuppJavaMailerSetup12.sh).<BR>');
		 dbms_output.put_line('</p></td></tr></tbody></table><BR>');
		 
          elsif (:startup_mode = 'MANUAL') then

    		 dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		 dbms_output.put_line('<tbody><tr><td> ');
		 dbms_output.put_line('<p><B>Warning:</B><BR>');
		 dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" is currently not running..<BR>');
		 dbms_output.put_line('<B>Action:</B><BR>');
		 dbms_output.put_line('If using the Java Mailer to send email notifications and alerts, please manually start the : '|| :component_name ||'.<BR>');
                 dbms_output.put_line('via the Oracle Application Manager - Workflow Manager screen.');
	         dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1191125.1" target="_blank">Note 1191125.1');
	         dbms_output.put_line('</a> - Troubleshooting Oracle Workflow Java Notification Mailer, for more information.<BR>');
		 dbms_output.put_line('</p></td></tr></tbody></table><BR>');
       
          end if;
           
      elsif (:mailer_status = 'DEACTIVATED_SYSTEM') then
          
                 dbms_output.put_line('<table border="1" name="RedBox" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
	         dbms_output.put_line('<tbody><tr><td> ');
	         dbms_output.put_line('<p><B>Error:</B><BR>');
	         dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" is currently down due to an error detected by the System.<BR><BR>');
	         dbms_output.put_line('<B>Action:<BR>');
	         dbms_output.put_line('Please review the email that was sent to SYSADMIN regarding this error.</B><BR>'); 
	         dbms_output.put_line('The Java Mailer is currently set to startup mode of '|| :startup_mode ||'.<BR>');
	         dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1191125.1" target="_blank">Note 1191125.1');
	         dbms_output.put_line('</a> - Troubleshooting Oracle Workflow Java Notification Mailer,<BR>');
	         dbms_output.put_line('Also review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=748421.1" target="_blank">Note 748421.1');
	         dbms_output.put_line('</a> - Java Mailer Setup Diagnostic Test (ATGSuppJavaMailerSetup12.sh), for more information.<BR>');
		 dbms_output.put_line('</p></td></tr></tbody></table><BR>');
		 
      elsif (:mailer_status = 'NOT_CONFIGURED') then
          
    		 dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	         dbms_output.put_line('<tbody><tr><td> ');
	         dbms_output.put_line('<p><B>Warning:</B><BR>');
	         dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" has been created, but is not configured completely.<BR>');
	         dbms_output.put_line('<B>Action:</B><BR>');
	         dbms_output.put_line('Please complete the configuration of the "'|| :component_name ||'" using the Workflow Manager screens if you plan to use it.<BR>'); 
	         dbms_output.put_line('This Java Mailer is currently set to startup mode of '|| :startup_mode ||'.<BR>');
	         dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1191125.1" target="_blank">Note 1191125.1');
	         dbms_output.put_line('</a> - Troubleshooting Oracle Workflow Java Notification Mailer, <BR>');
	         dbms_output.put_line('Also review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=748421.1" target="_blank">Note 748421.1');
	         dbms_output.put_line('</a> - Java Mailer Setup Diagnostic Test (ATGSuppJavaMailerSetup12.sh), for more information.<BR>');
		 dbms_output.put_line('</p></td></tr></tbody></table><BR>');
		 
      elsif (:mailer_status = 'STOPPED') then 
        
                 dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	         dbms_output.put_line('<tbody><tr><td> ');
	         dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" is currently stopped.<BR>');
		 dbms_output.put_line('</td></tr></tbody></table><BR>');

      elsif (:mailer_status = 'STOPPED_ERROR') then 
        
                 dbms_output.put_line('<table border="1" name="RedBox" cellpadding="10" bordercolor="#CC0033" bgcolor="#CC6666" cellspacing="0">');
	         dbms_output.put_line('<tbody><tr><td> ');
	         dbms_output.put_line('<p><B>Error:</B><BR>');
	         dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" is currently stopped because of an Error.<BR>');
	         dbms_output.put_line('<B>Action:<BR>');
	         dbms_output.put_line('Please review the email that was sent to SYSADMIN regarding this error.</B><BR>'); 
	         dbms_output.put_line('The Java Mailer is currently set to startup mode of '|| :startup_mode ||'.<BR>');
	         dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1191125.1" target="_blank">Note 1191125.1');
	         dbms_output.put_line('</a> - Troubleshooting Oracle Workflow Java Notification Mailer,<BR>');
	         dbms_output.put_line('Also run the Mailer Diagnostic Setup checks found in <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=748421.1" target="_blank">');
	         dbms_output.put_line('Note 748421.1</a> - Java Mailer Setup Diagnostic Test (ATGSuppJavaMailerSetup12.sh), for more information.<BR>');
		 dbms_output.put_line('</td></tr></tbody></table><BR>');
		 
      elsif (:mailer_status = 'RUNNING') then 
                   
                 dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	         dbms_output.put_line('<tbody><tr><td> ');
	         dbms_output.put_line('The Workflow Java Mailer "'|| :component_name ||'" is currently running.<BR>');
		 dbms_output.put_line('</td></tr></tbody></table><BR>');
	       
      end if;	  

   end if;
      
 END LOOP;

 CLOSE c_mailerIDs;

end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>

REM
REM ******* Check Status of WF_NOTIFICATIONS Table *******
REM

prompt <a name="wfadv153"></a><B><U>Check Status of WF_NOTIFICATIONS Table</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows5sql3(){var row = document.getElementById("s5sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Check Status of WF_NOTIFICATIONS Table</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows5sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s5sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="85">
prompt       <blockquote><p align="left">
prompt          select status, nvl(mail_status,'NULL'), count(notification_id)<br>
prompt          from wf_notifications<br>
prompt          group by status, mail_status<br>
prompt          order by status, count(notification_id) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STATUS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MAIL_STATUS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||status||'</TD>'||chr(10)|| 
'<TD>'||nvl(mail_status,'NULL')||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(notification_id),'999,999,999,999')||'</div></TD></TR>'
from wf_notifications  
group by status, mail_status
order by status, count(notification_id) desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Check Status of WF_NOTIFICATION_OUT Table *******
REM

prompt <a name="wfadv154"></a><B><U>Check Status of WF_NOTIFICATION_OUT Table</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows5sql4(){var row = document.getElementById("s5sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=1 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Check Status of WF_NOTIFICATION_OUT Table</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows5sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s5sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="2" height="60">
prompt       <blockquote><p align="left">
prompt          select n.msg_state, count(*)<br>
prompt          from applsys.aq$wf_notification_out n<br>
prompt          group by n.msg_state;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MSG_STATE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||n.msg_state||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(*),'999,999,999,999')||'</div></TD></TR>'
from applsys.aq$wf_notification_out n
group by n.msg_state;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Check for Open Orphaned Notifications *******
REM 

prompt <a name="wfadv155"></a><B><U>Check for Open Orphaned Notifications</B></U><BR>
prompt <blockquote>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td><font size="+1">
prompt <B>Open Orphaned or Unreferenced Notifications:</B></font><BR><BR>
prompt In Oracle Workflow Notification System, there could be Notifications in the wf_notifications table without corresponding Workflow Item Status records in<br> 
prompt wf_item_activity_statuses or wf_item_activity_statuses_h tables.<br>
prompt This could have resulted from a bug or due to sending FYI notifications outside of a Workflow Process.<br>
prompt 
prompt Oracle Workflow provides a script <i><b>$FND_TOP/sql/wfntfprg.sql</b></i> which closes and purges such orphan notifications older than a given number of days.<br>
prompt For earlier releases of 11i, the script is available via patch 3104909, which we check has already been applied.<br>
prompt <p>For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1#clnq" 
prompt target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br>
prompt </td></tr></tbody></table><BR><BR>


prompt <script type="text/javascript">    function displayRows5sql5(){var row = document.getElementById("s5sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Check for Open Orphaned Notifications</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows5sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s5sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="155">
prompt       <blockquote><p align="left">
prompt          select WN.MESSAGE_TYPE, wn.MESSAGE_NAME, wit.persistence_type PERSISTENCE, count(notification_id)<br>
prompt          from WF_NOTIFICATIONS WN, WF_ITEM_TYPES WIT<br>
prompt          where wn.message_type = wit.name <br>
prompt          and not exists (select NULL from WF_ITEM_ACTIVITY_STATUSES WIAS<br>
prompt          where WIAS.NOTIFICATION_ID = WN.GROUP_ID)<br>
prompt          and not exists (select NULL from WF_ITEM_ACTIVITY_STATUSES_H WIAS<br>
prompt          where WIAS.NOTIFICATION_ID = WN.GROUP_ID)<br>
prompt          and wn.end_date is null<br>
prompt          group by wn.message_type, wn.MESSAGE_NAME, wit.persistence_type<br>
prompt          order by wit.persistence_type, count(notification_id) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MESSAGE NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||WN.MESSAGE_TYPE||'</TD>'||chr(10)|| 
'<TD>'||wn.MESSAGE_NAME||'</TD>'||chr(10)|| 
'<TD>'||wit.persistence_type||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(notification_id),'999,999,999,999')||'</div></TD></TR>'
from WF_NOTIFICATIONS WN, WF_ITEM_TYPES WIT
where wn.message_type = wit.name 
and not exists (select NULL from WF_ITEM_ACTIVITY_STATUSES WIAS
where WIAS.NOTIFICATION_ID = WN.GROUP_ID)
and not exists (select NULL from WF_ITEM_ACTIVITY_STATUSES_H WIAS
where WIAS.NOTIFICATION_ID = WN.GROUP_ID)
and wn.end_date is null
group by wn.message_type, wn.MESSAGE_NAME, wit.persistence_type
order by wit.persistence_type, count(notification_id) desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');


declare 

WFNTFPRG_APPLIED number;
UNREFNTF_CNT 	 number;

begin

WFNTFPRG_APPLIED := 0;
UNREFNTF_CNT     := 0;

select count(notification_id) into UNREFNTF_CNT
from WF_NOTIFICATIONS WN
where not exists (select NULL from WF_ITEM_ACTIVITY_STATUSES WIAS
where WIAS.NOTIFICATION_ID = WN.GROUP_ID)
and not exists (select NULL from WF_ITEM_ACTIVITY_STATUSES_H WIAS
where WIAS.NOTIFICATION_ID = WN.GROUP_ID)
and wn.end_date is null;

select count(*) into WFNTFPRG_APPLIED
from AD_BUGS b 
where b.BUG_NUMBER = '3104909';

if (UNREFNTF_CNT > 0) then

	if (WFNTFPRG_APPLIED > 0) then 
	    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
	    dbms_output.put_line('<p><b>Attention:<br>');    
	    dbms_output.put_line('Please run $FND_TOP/sql/wfntfprg.sql to remove unreferenced notifications by following the instructions on the script header.</b><br>'); 
	    dbms_output.put_line('For purging FNDCMMSG, XDPWFSTD, etc (which are PERMANENT) type of notifications, please uncomment the line ');
	    dbms_output.put_line('( Wf_Purge.Persistence_Type := "PERM" ) in the wfntfprg.sql as this type of message is of type PERMANENT persistence.<br>');
	    dbms_output.put_line('This should do the trick.<BR>');
	    dbms_output.put_line('</p></td></tr></tbody></table><BR>');	

	elsif (WFNTFPRG_APPLIED = 0) then  
	    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
	    dbms_output.put_line('<p><b>Attention:<br>');    
	    dbms_output.put_line('Apply Patch 3104909 and run wfntfprg.sql to remove unreferenced notifications by following the instructions on the script header.</b><br>'); 
	    dbms_output.put_line('For purging FNDCMMSG, XDPWFSTD, etc (which are PERMANENT) type of notifications, please uncomment the line ');
	    dbms_output.put_line('( Wf_Purge.Persistence_Type := "PERM" ) in the wfntfprg.sql as this type of message is of type PERMANENT persistence.<br>');
	    dbms_output.put_line('This should do the trick.<BR>');
	    dbms_output.put_line('</p></td></tr></tbody></table><BR>');	

	else
	    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
	    dbms_output.put_line('<p><b>Attention:</b><br>');    
	    dbms_output.put_line('It does not appear that patch 3104909 is applied to this instance, so please download and apply Patch 3104909 and then ');
	    dbms_output.put_line('run wfntfprg.sql to remove unreferenced notifications by following the instructions on the script header.<br>'); 
	    dbms_output.put_line('For purging FNDCMMSG, XDPWFSTD, etc (which are PERMANENT) type of notifications, please uncomment the line ');
	    dbms_output.put_line('( Wf_Purge.Persistence_Type := "PERM" ) in the wfntfprg.sql as this type of message is of type PERMANENT persistence.<br>');
	    dbms_output.put_line('This should do the trick.<BR>');
	    dbms_output.put_line('</p></td></tr></tbody></table><BR>');	

	end if;

else 
       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Well Done !!<BR><BR>');
       dbms_output.put_line('There are ZERO open Orphaned or Unreferenced Workflow Notifications found !</B><br> ');
       dbms_output.put_line('Keep up the good work!!!<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

end if;
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>
prompt </blockquote>

REM **************************************************************************************** 
REM *******                   Section 6 : Workflow Patch Levels                      *******
REM ****************************************************************************************

prompt <a name="section6"></a><B><font size="+2">Current Workflow Patch Levels</font></B><BR><BR>
prompt <blockquote>

REM
REM ******* Applied ATG Patches *******
REM

prompt <script type="text/javascript">    function displayRows6sql1(){var row = document.getElementById("s6sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"><a name="wfadv161"></a>
prompt     <B>Applied ATG/WF Patches</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows6sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s6sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="850">
prompt       <blockquote><p align="left">
prompt       select BUG_NUMBER, CREATION_DATE, decode(bug_number,<br>
prompt       2728236, 'OWF.G INCLUDED IN 11.5.9',<br>
prompt       3031977, 'POST OWF.G ROLLUP 1 - 11.5.9.1',<br>
prompt       3061871, 'POST OWF.G ROLLUP 2 - 11.5.9.2',<br>
prompt       3124460, 'POST OWF.G ROLLUP 3 - 11.5.9.3',<br>
prompt       3126422, '11.5.9 Oracle E-Business Suite Consolidated Update 1',<br>
prompt       3171663, '11.5.9 Oracle E-Business Suite Consolidated Update 2',<br>
prompt       3316333, 'POST OWF.G ROLLUP 4 - 11.5.9.4.1',<br>
prompt       3314376, 'POST OWF.G ROLLUP 5 - 11.5.9.5',<br>
prompt       3409889, 'POST OWF.G ROLLUP 5 Consolidated Fixes For OWF.G RUP 5', <br>
prompt       3492743, 'POST OWF.G ROLLUP 6 - 11.5.9.6',<br>
prompt       3868138, 'POST OWF.G ROLLUP 7 - 11.5.9.7',<br>
prompt       3262919, 'FMWK.H',<br>
prompt       3262159, 'FND.H INCLUDE OWF.H',<br>
prompt       3258819, 'OWF.H INCLUDED IN 11.5.10',<br>
prompt       3438354, '11i.ATG_PF.H INCLUDE OWF.H',<br>
prompt       3140000, 'Oracle Applications Release 11.5.10 Maintenance Pack',<br>
prompt       3240000, '11.5.10 Oracle E-Business Suite Consolidated Update (CU1)',<br>
prompt       3460000, '11.5.10 Oracle E-Business Suite Consolidated Update (CU2)',<br>
prompt       3480000, 'Oracle Applications Release 11.5.10.2 Maintenance Pack',<br>
prompt       4017300 , 'ATG_PF:11.5.10 Consolidated Update (CU1) for ATG Product Family',<br>
prompt       4125550 , 'ATG_PF:11.5.10 Consolidated Update (CU2) for ATG Product Family',<br>
prompt       5121512, 'AOL USER RESPONSIBILITY SECURITY FIXES VERSION 1',<br>
prompt       6008417, 'AOL USER RESPONSIBILITY SECURITY FIXES 2b',<br>
prompt       6047864, 'REHOST JOC FIXES (BASED ON JOC 10.1.2.2) FOR APPS 11i',<br>
prompt       4334965, '11i.ATG_PF.H RUP3',<br>
prompt       4676589, '11i.ATG_PF.H.RUP4',<br>
prompt       5473858, '11i.ATG_PF.H.RUP5',<br>
prompt       5903765, '11i.ATG_PF.H.RUP6',<br>
prompt       6241631, '11i.ATG_PF.H.RUP7',<br>
prompt       4440000, 'Oracle Applications Release 12 Maintenance Pack',<br>
prompt       5082400, '12.0.1 Release Update Pack (RUP1)',<br>
prompt       5484000, '12.0.2 Release Update Pack (RUP2)',<br>
prompt       6141000, '12.0.3 Release Update Pack (RUP3)',<br>
prompt       6435000, '12.0.4 Release Update Pack (RUP4)',<br>
prompt       5907545, 'R12.ATG_PF.A.DELTA.1',<br>
prompt       5917344, 'R12.ATG_PF.A.DELTA.2',<br>
prompt       6077669, 'R12.ATG_PF.A.DELTA.3',<br>
prompt       6272680, 'R12.ATG_PF.A.DELTA.4', <br>
prompt       7237006, 'R12.ATG_PF.A.DELTA.6',<br>
prompt       6728000, 'R12 12.0.6 (RUP6)', <br>
prompt       6430106, 'R12 Oracle E-Business Suite 12.1', <br>
prompt       7303030, '12.1.1 Maintenance Pack',<br>
prompt       7307198, 'R12.ATG_PF.B.DELTA.1',<br>
prompt       7651091, 'R12.ATG_PF.B.DELTA.2',<br>
prompt       7303033, 'R12 Oracle E-Business Suite 12.1.2 (RUP2)',<br>
prompt       8919491, 'R12.ATG_PF.B.DELTA.3',<br>
prompt       9239090, 'R12 Oracle E-Business Suite 12.1.3 (RUP3)',<br>
prompt       16207672, 'ORACLE E-BUSINESS SUITE 12.2.2 RELEASE UPDATE PACK',<br>
prompt       17774755, 'Oracle 12.1.3+ E-Business Suite Recommended Patch Collection 1 [RPC1]',<br>
prompt       17385991, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Sep 2013',<br>
prompt       17618508, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Dec 2013',<br>
prompt       18826085, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Jun 2014',<br>
prompt       19329720, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Jul 2014',<br>
prompt       20230836, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Dec 2014',<br>
prompt       20035289, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Mar 2015',<br>
prompt       bug_number) PATCH, ARU_RELEASE_NAME <br>
prompt       from AD_BUGS b <br>
prompt       where b.BUG_NUMBER in ('2728236', '3031977','3061871','3124460','3126422','3171663','3316333',<br>
prompt       '3314376','3409889', '3492743', '3262159', '3262919', '3868138', '3258819','3438354','3240000',<br>
prompt       '3460000', '3140000','3480000','4017300', '4125550', '6047864', '6008417','5121512', '4334965',<br>
prompt       '4676589', '5473858', '5903765', '6241631', '4440000','5082400','5484000','6141000','6435000',<br>
prompt       '5907545','5917344','6077669','6272680','7237006','6728000','6430106','7303030','7307198',<br>
prompt       '7651091','7303033','8919491', '9239090','16207672','17774755','17385991','17618508','18826085',<br>
prompt       '19329720','20230836','20035289','19030202')<br>
prompt       order by ARU_RELEASE_NAME, CREATION_DATE; </p>
prompt         </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BUG_NUMBER</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CREATION_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PATCH</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RELEASE</B></TD>
exec :n := dbms_utility.get_time;
select 
'<TR><TD>'||BUG_NUMBER||'</TD>'||chr(10)||
'<TD>'||CREATION_DATE||'</TD>'||chr(10)|| 
'<TD>'||decode(b.bug_number,
2728236, 'OWF.G INCLUDED IN 11.5.9',
3031977, 'POST OWF.G ROLLUP 1 - 11.5.9.1',
3061871, 'POST OWF.G ROLLUP 2 - 11.5.9.2',
3124460, 'POST OWF.G ROLLUP 3 - 11.5.9.3',
3126422, '11.5.9 Oracle E-Business Suite Consolidated Update 1',
3171663, '11.5.9 Oracle E-Business Suite Consolidated Update 2',
3316333, 'POST OWF.G ROLLUP 4 - 11.5.9.4.1',
3314376, 'POST OWF.G ROLLUP 5 - 11.5.9.5',
3409889, 'POST OWF.G ROLLUP 5 Consolidated Fixes For OWF.G RUP 5', 
3492743, 'POST OWF.G ROLLUP 6 - 11.5.9.6',
3868138, 'POST OWF.G ROLLUP 7 - 11.5.9.7',
3262919, 'FMWK.H',
3262159, 'FND.H INCLUDE OWF.H',
3258819, 'OWF.H INCLUDED IN 11.5.10',
3438354, '11i.ATG_PF.H INCLUDE OWF.H',
3140000, 'Oracle Applications Release 11.5.10 Maintenance Pack',
3240000, '11.5.10 Oracle E-Business Suite Consolidated Update (CU1)',
3460000, '11.5.10 Oracle E-Business Suite Consolidated Update (CU2)',
3480000, 'Oracle Applications Release 11.5.10.2 Maintenance Pack',
4017300 , 'ATG_PF:11.5.10 Consolidated Update (CU1) for ATG Product Family',
4125550 , 'ATG_PF:11.5.10 Consolidated Update (CU2) for ATG Product Family',
5121512, 'AOL USER RESPONSIBILITY SECURITY FIXES VERSION 1',
6008417, 'AOL USER RESPONSIBILITY SECURITY FIXES 2b',
6047864, 'REHOST JOC FIXES (BASED ON JOC 10.1.2.2) FOR APPS 11i',
4334965, '11i.ATG_PF.H RUP3',
4676589, '11i.ATG_PF.H.RUP4',
5473858, '11i.ATG_PF.H.RUP5',
5903765, '11i.ATG_PF.H.RUP6',
6241631, '11i.ATG_PF.H.RUP7',
4440000, 'Oracle Applications Release 12 Maintenance Pack',
5082400, '12.0.1 Release Update Pack (RUP1)',
5484000, '12.0.2 Release Update Pack (RUP2)',
6141000, '12.0.3 Release Update Pack (RUP3)',
6435000, '12.0.4 Release Update Pack (RUP4)',
5907545, 'R12.ATG_PF.A.DELTA.1',
5917344, 'R12.ATG_PF.A.DELTA.2',
6077669, 'R12.ATG_PF.A.DELTA.3',
6272680, 'R12.ATG_PF.A.DELTA.4', 
7237006, 'R12.ATG_PF.A.DELTA.6',
6728000, 'R12 12.0.6 (RUP6)', 
6430106, 'R12 Oracle E-Business Suite 12.1', 
7303030, '12.1.1 Maintenance Pack',
7307198, 'R12.ATG_PF.B.DELTA.1',
7651091, 'R12.ATG_PF.B.DELTA.2',
7303033, 'R12 Oracle E-Business Suite 12.1.2 (RUP2)',
8919491, 'R12.ATG_PF.B.DELTA.3',
9239090, 'R12 Oracle E-Business Suite 12.1.3 (RUP3)',
16207672, 'ORACLE E-BUSINESS SUITE 12.2.2 RELEASE UPDATE PACK',
17774755, 'Oracle 12.1.3+ E-Business Suite Recommended Patch Collection 1 [RPC1]',
17385991, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Sep 2013',
17618508, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Dec 2013',
18826085, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Jun 2014',
19329720, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Jul 2014',
20230836, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Dec 2014',
20035289, 'Latest Recommended Patch Collection for OWF 12.1.3+ - Mar 2015',
bug_number)||'</TD>'||chr(10)|| 
'<TD>'||ARU_RELEASE_NAME||'</TD></TR>' 
from AD_BUGS b 
where b.BUG_NUMBER in ('2728236', '3031977','3061871','3124460','3126422','3171663','3316333',
'3314376','3409889', '3492743', '3262159', '3262919', '3868138', '3258819','3438354','3240000',
'3460000', '3140000','3480000','4017300', '4125550', '6047864', '6008417','5121512', '4334965',
'4676589', '5473858', '5903765', '6241631', '4440000','5082400','5484000','6141000','6435000',
'5907545','5917344','6077669','6272680','7237006','6728000','6430106','7303030','7307198',
'7651091','7303033','8919491', '9239090','16207672','17774755','17385991','17618508','18826085',
'19329720','20230836','20035289','19030202')
order by ARU_RELEASE_NAME, CREATION_DATE; 
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Known 1-Off Patches on top of ATG Rollups *******
REM

prompt <a name="atgrups"></a><B><U>Known 1-Off Patches on top of ATG Rollups</B></U><BR>
prompt <blockquote>

begin

CASE 
	when (:apps_rel is null) then 

    		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('There is a problem reading the Oracle Apps version (' || :apps_rel || ') for this instance. ');
	       dbms_output.put_line('So unable to determine if any 1-Off Patches exist.<br> ');	       
       	       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       
	       dbms_output.put_line('<BR>');
	
	when :apps_rel = '11.5.8' then

	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> ');
	       dbms_output.put_line('<p><B>Attention:<BR>');
	       dbms_output.put_line('The Oracle Apps version is (' || :apps_rel || ') for this instance.<br> ');
	       dbms_output.put_line('There are no Development suggested 1-Off patches available on top of this version.</B><br><br>');
	       dbms_output.put_line('<B>Warning:<BR>');
	       dbms_output.put_line('Oracle Applications 11.5.8 is no longer supported.</B><br>');
	       dbms_output.put_line('The minimum baseline ATG patchset for Extended Support of Oracle E-Business Suite Release 11i is 11i.ATG_PF.H.delta.6 (Patch 5903765).<br>');
	       dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=883202.1"');
	       dbms_output.put_line('target="_blank">Note 883202.1</a> - ');
	       dbms_output.put_line('Patch Requirements for Extended Support of Oracle E-Business Suite Release 11.5.10<br>');
       	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');  	       	       
	       dbms_output.put_line('<BR>');
	       
	when :apps_rel = '11.5.9' then

	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> ');
	       dbms_output.put_line('<p><B>Attention:<BR>');
	       dbms_output.put_line('The Oracle Apps version is (' || :apps_rel || ') for this instance.<br> ');
	       dbms_output.put_line('There are no Development suggested 1-Off patches available on top of this version.</B><br><br>');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('Oracle Applications 11.5.9 is no longer supported.<br>');
	       dbms_output.put_line('The minimum baseline ATG patchset for Extended Support of Oracle E-Business Suite Release 11i is 11i.ATG_PF.H.delta.6 (Patch 5903765).<br>');
	       dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=883202.1"');
	       dbms_output.put_line('target="_blank">Note 883202.1</a> - ');
	       dbms_output.put_line('Patch Requirements for Extended Support of Oracle E-Business Suite Release 11.5.10<br>');	       
       	   dbms_output.put_line('</p></td></tr></tbody></table><BR>');  	       	       
	       dbms_output.put_line('<BR>');

 	when (:apps_rel > '11.5.10' and :apps_rel < '12.0') then 
	
		select nvl(max(decode(bug_number,
		4676589, 'RUP4',
		5903765, 'RUP6',
		6241631, 'RUP7',
		bug_number)),'PRERUP4') RUP into :rup
		from AD_BUGS b 
		where b.BUG_NUMBER in ('4676589', '5903765', '6241631')
		order by LAST_UPDATE_DATE desc;

	    if (:rup = 'PRERUP4') then 

	       		dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		       dbms_output.put_line('<tbody><tr><td> ');
		       dbms_output.put_line('<p><B>Attention:<BR>');
		       dbms_output.put_line('This ('|| :apps_rel ||') instance does not have 11i.ATG_PF.H RUP6 Applied.<br> ');
		       dbms_output.put_line('There are no Development suggested 1-Off Workflow patches available for this version.</B><br><br>');
		       dbms_output.put_line('<B>Warning:<BR>');
		       dbms_output.put_line('Oracle Applications '|| :apps_rel ||' is no longer supported.</B><br>');
		       dbms_output.put_line('The minimum baseline ATG patchset for Extended Support of Oracle E-Business Suite Release 11.5.10 is 11i.ATG_PF.H.delta.6 (5903765).<br>');
		       dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=883202.1"');
		       dbms_output.put_line('target="_blank">Note 883202.1</a> - ');
		       dbms_output.put_line('Patch Requirements for Extended Support of Oracle E-Business Suite Release 11.5.10<br>');		       
       	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');  	       		       
		       dbms_output.put_line('<BR>');
	       
        elsif (:rup = 'RUP4') then 


		       dbms_output.put_line('<p><b>Workflow Development recommends the following Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('</table><BR>'); 

			dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended patches that are missing.</b><br>');
			dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
			dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');
			
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8557487';
			   
		       dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of 11i.ATG_PF.H RUP4 for '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Oracle Workflow Engine Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">8557487</div></td>');
		       dbms_output.put_line('<td>1OFF:5709442: HIGH BUFFER GETS WHEN SENDING NOTIFICATON</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>'); 		       
		       dbms_output.put_line('</table><BR>');
		       
		       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		       dbms_output.put_line('<tbody><tr><td> ');		       
		       dbms_output.put_line('<B>Warning:</B><BR>');
		       dbms_output.put_line('The minimum baseline ATG patchset for Extended Support of Oracle E-Business Suite Release 11.5.10 is 11i.ATG_PF.H.delta.6 (5903765).<br>');
		       dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=883202.1"');
		       dbms_output.put_line('target="_blank">Note 883202.1</a> - ');
		       dbms_output.put_line('Patch Requirements for Extended Support of Oracle E-Business Suite Release 11.5.10<br><br>');		       
       	       	       dbms_output.put_line('</td></tr></tbody>');

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '5947217';
			   
		       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Business Event System (BES) Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">5947217</div></td>');
		       dbms_output.put_line('<td>External link mark:WF JAVA DEFERRED AGENT LISTENER NOT STARTING (Superseded by 6241631-11i.ATG_PF.H.delta.7)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');        		       
       	       	       dbms_output.put_line('</table><BR>');  	       		       


        elsif (:rup = 'RUP5') then 

	 		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
				 FROM AD_BUGS b
				   WHERE b.BUG_NUMBER IN '6836141';
	                 
			       dbms_output.put_line('<p><b>Workflow Development recommends the following Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
			       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			       dbms_output.put_line('<td><b>Patch #</b></td>');
			       dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
			       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		               dbms_output.put_line('<td align="center"><b>Status</b></td>');
			       dbms_output.put_line('</tr>');
		               dbms_output.put_line('<tr bordercolor="#000066">');
		               dbms_output.put_line('<td>');
		               dbms_output.put_line('<div align="center">6836141</div></td>');
		               dbms_output.put_line('<td>1OFF:6511028: WORKFLOW SERVICE CONTAINER CONSUMING A LOT TEMP LOBs</td>');
		               dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		               dbms_output.put_line('</tr>');
		               dbms_output.put_line('</table><BR>'); 	       		       

			dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended patches that are missing.</b><br>');
			dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
			dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');		       

        elsif (:rup = 'RUP6') then 

	 		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">INSTALLED') into :ptch1
			 FROM AD_BUGS b
			 WHERE b.BUG_NUMBER IN '13990300';
			
			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			 WHERE b.BUG_NUMBER IN '6836141';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9199983';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9803639';
			   
			dbms_output.put_line('<p><b>Workflow Development recommends the following Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
		        dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');
		        dbms_output.put_line('<tr bordercolor="#000066">');
		        dbms_output.put_line('<td>');
		        dbms_output.put_line('<div align="center">13990300</div></td>');
		        dbms_output.put_line('<td>1OFF:11i.ATG_PF.H.RUP6: WORKFLOW PURGE REMOVES WORKFLOWS THAT ARE NOT END DATED</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">6836141</div></td>');
		       dbms_output.put_line('<td>1OFF:6511028: WORKFLOW SERVICE CONTAINER CONSUMING A LOT TEMP LOBs</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>');   
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9199983</div></td>');
		       dbms_output.put_line('<td>1OFF:11.5.10.6RUP:7476877: WORKFLOW PURGE IS CRITICALLY AFFECTING PERFORMANCE</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
		       dbms_output.put_line('</tr>'); 
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9803639</div></td>');
		       dbms_output.put_line('<td>1OFF:11i.ATG_PF.H.RUP6:INDIRECT RESPONSIBILITIES NO LONGER IN TOP-HAT AFTER PATCH</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch5||'</td>');
		       dbms_output.put_line('</tr>'); 		       
		       dbms_output.put_line('</table><BR>');                 

			dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended patches that are missing.</b><br>');
			dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
			dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');             

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '7594112';
			   
		       dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of 11i.ATG_PF.H RUP6 for '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Oracle Workflow Engine Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">7594112</div></td>');
		       dbms_output.put_line('<td>1OFF:6243131:11I.ATG_PF.H.RUP6: APPROVALS GOING INTO DEFFRED MODE</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');     

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '12420326';
		   
		       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Directory Services Patches (WFDS)</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');                
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">12420326</div></td>');
		       dbms_output.put_line('<td>1OFF:11I.ATG_PF.H.RUP6:LOGGING MODE OF SYNCHRONIZE WF LOCAL TABLES NOT LOGGING</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
		       dbms_output.put_line('</tr>'); 

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '7621323';
			   
		       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Business Event System (BES) Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">7621323</div></td>');
		       dbms_output.put_line('<td>External link mark: 11.5.10 RUP5:6112028:WFEVQCLN.SQL TO CLEAN UP DATA FROM WF_JAVA_DEFERRED</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');          	       
		       dbms_output.put_line('</table><BR>');
		       
        elsif (:rup = 'RUP7') then 
                 
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9747572';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9803639';
			   
			dbms_output.put_line('<p><b>Workflow Development recommends the following Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
		        dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9747572</div></td>');
		       dbms_output.put_line('<td>1OFF:11i.ATG_PF.H.RUP7:WFBG DOES NOT EXECUTE SELECTOR FUNCTION WHEN PROCESSING A SUBSEQUENT DEFERRED ACTIVITY OF SAME ITEM TYPE</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>'); 
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9803639</div></td>');
		       dbms_output.put_line('<td>1OFF:11i.ATG_PF.H.RUP6:INDIRECT RESPONSIBILITIES NO LONGER IN TOP-HAT AFTER PATCH</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>');
		       
		        dbms_output.put_line('</table><BR>');			
			
			select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '14020766';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '14339914';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '13457712';
			
		       dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of 11i.ATG_PF.H RUP7 for '|| :apps_rel ||'.</b><br>');                 
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Oracle Workflow Engine Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">14020766</div></td>');
		       dbms_output.put_line('<td>1OFF:11I.ATG_PF.H.RUP7:13721678:ORA-06502: IF ROLE DISPLAY NAME IS LONGER THAN 200 CHARACTERS </td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">14339914</div></td>');
		       dbms_output.put_line('<td>1OFF:12864565:11I.ATG_PF.H.RUP7:REQUEST FOR MORE INFORMATION DATA CACHED FROM PREVIOUS NOTIFICATION</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       dbms_output.put_line('</tr>'); 
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">13457712</div></td>');
		       dbms_output.put_line('<td>1OFF:11I.ATG_PF.H.RUP7:10243065:EMAIL IS SENT TWICE WHEN NOTIFICATION REASSIGNED THROUGH ROUTING RULE</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
		       dbms_output.put_line('</tr>'); 

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9720838';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '14020766';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '17206808';			   

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9266719';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch9
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '12568091';
			   
		       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Directory Services Patches (WFDS)</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');                     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9720838</div></td>');
		       dbms_output.put_line('<td>1OFF:11i.ATG_PF.H.RUP7:9431115:VACATION RULE DEFINED FOR ROLE DOES NOT WORK</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch5||'</td>');
		       dbms_output.put_line('</tr>');             
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">14020766</div></td>');
		       dbms_output.put_line('<td>1OFF:11I.ATG_PF.H.RUP7:13721678:ORA-06502: IF ROLE DISPLAY NAME IS LONGER THAN 200 CHARACTERS</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch6||'</td>');
		       dbms_output.put_line('</tr>');      		       		       
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">17206808</div></td>');
		       dbms_output.put_line('<td>1OFF:11I.ATG_PF.H.RUP7:WF_MAINTENANCE NEW API FOR RECORD COUNT</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch7||'</td>');
		       dbms_output.put_line('</tr>'); 
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9266719</div></td>');
		       dbms_output.put_line('<td>1OFF:9175112:ATG RUP 7:ATG RUP 7:11.5.10.2:FNDLOAD ACTIVATES DELETED RESPONSIBILITY</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch8||'</td>');
		       dbms_output.put_line('</tr>');      		       		       
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">12568091</div></td>');
		       dbms_output.put_line('<td>1OFF:11I.ATG_PF.H.RUP7:ROLES INCORRECTLY GIVEN TO USERS BECAUSE OF PROPAGATION</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch9||'</td>');
		       dbms_output.put_line('</tr>'); 
		       dbms_output.put_line('</table><BR>');			
 	       else
		       dbms_output.put_line('There are no Development suggested 1-Off Workflow patches available for this version.<br><br>');
	       end if;

	when :apps_rel = '12.0.4' then
                 
	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8340612';

	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '7829071';				   
	                 
	         select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '7277944';

	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8201652';	

	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '10428040';			   
	                 
			       dbms_output.put_line('<p><b>Workflow Development recommends the following Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
			       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			       dbms_output.put_line('<td><b>Patch #</b></td>');
			       dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
			       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		           dbms_output.put_line('<td align="center"><b>Status</b></td>');
			       dbms_output.put_line('</tr>');
			    dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">8340612</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.4:7842689:WF_ITEM.SET_END_DATE IS INCORRECTLY DECREMENTING THE #WAITFORDETAIL ATTRIBUTE</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			    dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">7829071</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.4:ORA-06502 PL/SQL: NUMERIC OR VALUE IN WF_ENGINE_UTIL.NOTIFICATION_SEND</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			    dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">7277944</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.4, 12.0.3: WORKFLOW MAILER DOWN WITH :JAVA.LANG.STRINGINDEXOUTOFBOUNDSEXCEPTION</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       	   dbms_output.put_line('</tr>');
		       	dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">8201652</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.4:7538770:FNDWFPR PERFORMANCE IS SLOWER THAN GENERATING SPEED</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
		       	   dbms_output.put_line('</tr>'); 
		       	       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">10428040</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.6:10012972:MAILER INBOUND PROCESSOR STOPS WORKING AFTER JAVAX.MAIL.MESSAGEREMOVEDEXCEPTION</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch5||'</td>');
		       	   dbms_output.put_line('</tr></table><BR>');			

			dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended patches that are missing.</b><br>');
			dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
			dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');
			
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8201652';
                 
		       dbms_output.put_line('<p><b>Workflow Development recommends the following Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Oracle Workflow Engine Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">8201652</div></td>');
		       dbms_output.put_line('<td>1OFF (7538770) ON TOP OF 12.0.4 (R12.ATG_PF.A.DELTA.4)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>'); 

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '7631576';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8944925';

		       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Directory Services Patches (WFDS)</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">7631576</div></td>');
		       dbms_output.put_line('<td>1OFF: 6817561:ATG 12.0.4: RESPONSIBILITY ASSIGNMENTS: LAST UPDATE_DATE AND UPDATE_BY INCORRECT</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">8944925</div></td>');
		       dbms_output.put_line('<td>1OFF:12.0.4:6817561:RESPONSIBILITY ASSIGNMENTS : LAST UPDATE_DATE AND UPDATED_BY INCORRECT</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>'); 

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '7697221';
			   
		       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Business Event System (BES) Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">7697221</div></td>');
		       dbms_output.put_line('<td>1OFF:7671184:NOT ABLE TO MOVE MESSAGES FROM WF_OUT TO EXTERNAL SYSTEM USING BES</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');     	       
		       dbms_output.put_line('</table><BR>');

	when :apps_rel = '12.0.6' then

	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9255725';

	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9853165';				   
	                 
	                 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '18357775';

	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '7606173';				   

	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '7630298';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '7709109';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '10428040';				   

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8330993';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch9
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8627180';
	                 
			       dbms_output.put_line('<p><b>Workflow Development recommends the following Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
			       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			       dbms_output.put_line('<td><b>Patch #</b></td>');
			       dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
			       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		               dbms_output.put_line('<td align="center"><b>Status</b></td>');
			   dbms_output.put_line('</tr>');
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">9255725</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.6:9169815:NULLPOINTEREXCEPTION WHEN 451 TIMEOUT WAITING FOR CLIENT INP</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">9853165</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.6:9450904:GETINFOFROMMAIL API NEEDS TO IDENTIFY ROLE NAME ACCURATELY</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">18357775</div></td>');
			       dbms_output.put_line('<td>BACKPORT:16091678:FND_USER_PREFERENCES IS GETTING UPDATED TO NULL</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       	   dbms_output.put_line('</tr>'); 
		       	       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">7606173</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.6: 7535451: APPLICATION/PDF IS NOT AN ALLOWED CONTENT_TYPE FOR THE BODYPART</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">7630298</div></td>');
			       dbms_output.put_line('<td>1OFF:7585376:12.0.6:ERROR INVALID ALTER SESSION ON SCRIPT WFNTFCU2.SQL</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch5||'</td>');
		       	   dbms_output.put_line('</tr>'); 
		       	       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">7709109</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.6:6767410:EMAIL NOTIFICATIONS DISPLAY ERROR MESSAGE AS INSUFFICIENT PRIVILEGE</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch6||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">10428040</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.6:10012972:MAILER INBOUND PROCESSOR STOPS WORKING AFTER JAVAX.MAIL.MESSAGEREMOVEDEXCEPTION</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch7||'</td>');
		       	   dbms_output.put_line('</tr>');
		       	       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">8330993</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.6:8308654:WF_STANDARD.INITIALIZEEVENTERROR USING ATTRIBUTE ERROR_DETAILS</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch8||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">8627180</div></td>');
			       dbms_output.put_line('<td>1OFF:12.0.6:PERFORMANCE ISSUE WITH WF_NOTIFICATION.SEND()</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch9||'</td>');
			       dbms_output.put_line('</tr></table><BR>'); 
		        
			dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended patches that are missing.</b><br>');
			dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
			dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');
			
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9123412';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '13788587';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '14750553';
			   
		       dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Oracle Workflow Engine Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9123412</div></td>');
		       dbms_output.put_line('<td>1OFF:12.0.6:8509185:NOTIFICATION HISTORY DOES NOT DISPLAY UP TO DATE CONTENT</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');          
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">13788587</div></td>');
		       dbms_output.put_line('<td>1OFF:9290020:R12.ATG_PF.A.DELTA.6:12.0.6:WF_NOTIFICATION.WORKCOUNT DOES NOT CONSIDER</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">14750553</div></td>');
		       dbms_output.put_line('<td>1OFF:12.0.6:WORKFLOWS ARE GETTING STUCK WHEN WF_NOTIFICATION_ATTRIBUTES TABLE GROWS</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       dbms_output.put_line('</tr>'); 	

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9943807';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '13490158';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9106070';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9645869';


		       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Directory Services Patches (WFDS)</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9943807</div></td>');
		       dbms_output.put_line('<td>1OFF:R12.ATG_PF.A.DELTA.6:9506404:ORA-20002 WHEN ASIGNING A ROLE HIERARCHY TO A USER (Superseded by 13490158)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">13490158</div></td>');
		       dbms_output.put_line('<td>1OFF:R12.ATG_PF.A.DELTA.6:DISABLED ROLE RELATIONSHIPS IN LDT REMAIN ENABLED IN TABLE AFTER FNDLOAD RUNS</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9106070</div></td>');
		       dbms_output.put_line('<td>1OFF:12.0.6:5933120:ABILITY TO RESTRICT USERS IN USER LOV EMPLOYEES ARE VISIBLE IN LOV TO SUPPLIERS (Superseded by 9645869)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       dbms_output.put_line('</tr>');             
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9645869</div></td>');
		       dbms_output.put_line('<td>1OFF:12.0.6:WORKFLOW USER LOV FOR SUPPLIER USERS NOT WORKING CORRECTLY</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
		       dbms_output.put_line('</tr>');     
		       
		       dbms_output.put_line('</table><BR>');

	when :apps_rel = '12.1.1' then
	
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8531582';				   
	                 
			dbms_output.put_line('<p><b>Workflow Development recommends the following Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
		    dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');
		    dbms_output.put_line('<tr bordercolor="#000066">');
		    dbms_output.put_line('<td>');
		    dbms_output.put_line('<div align="center">8531582</div></td>');
		    dbms_output.put_line('<td>1OFF:12.1.1:7538770:FNDWFPR PERFORMANCE IS SLOWER THAN GENERATING SPEED (Superseded by 9055472)</td>');
		    dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		    dbms_output.put_line('</tr>'); 
		    dbms_output.put_line('</table><BR>'); 

			dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended patches that are missing.</b><br>');
			dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
			dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');
					
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8603335';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9102969';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9046220';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9227423';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8853694';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9343170';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch10
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '14699743';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch11
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '15889703';
			   
		       dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Oracle Workflow Engine Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');    
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">8603335</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.1:8554209:PERFORMANCE ISSUE WITH WF_NOTIFICATION.SEND()API</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9102969</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.1:8850464:FND USER IS COMING AS WRONG VALUE</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       dbms_output.put_line('</tr>');             
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9046220</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.1:7842689:WF_ITEM.SET_END_DATE WRONGLY DECREMENTS #WAITFORDETAIL ATTRIBUTE</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
		       dbms_output.put_line('</tr>');         
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9227423</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.1:9040136:ACTION HISTORY IS OUT OF SEQUENCE IN A RAC INSTANCE</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch6||'</td>');
		       dbms_output.put_line('</tr>'); 
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">8853694</div></td>');
		       dbms_output.put_line('<td>1OFF:8509185:R12 ORACLE E-BUSINESS SUITE 1:FND.A:12.1.1:NOTIFICATION HISTORY DOES NOT DISPLAY UP TO DATE CONTENT</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch7||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9343170</div></td>');
		       dbms_output.put_line('<td>1OFF:8729116:11.5.10.6:ORA-01422 IN WF_NOTIFICATION.SEND WHEN 2 NTFS SENT FROM AN ACTIVITY</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch8||'</td>');
		       dbms_output.put_line('</tr>');     		
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">14699743</div></td>');
		       dbms_output.put_line('<td>1OFF:9757926:12.1.1:GETTING JAVA.NET.MALFORMEDURLEXCEPTION FOR AN ABSOLUTE URI WHILE SENDING OA FRAMEWORK BASED NOTIFICATION</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch10||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">15889703</div></td>');
		       dbms_output.put_line('<td>PASSWORD IS DISPLAYED ON THE SERVICE PAYLOAD</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch11||'</td>');
		       dbms_output.put_line('</tr>'); 

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8808679';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '8832674';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9585372';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9720970';

		       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Directory Services Patches (WFDS)</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">8808679</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.1:7308460:WORKFLOW ROLE HIERARCHY PROPAGATION UPDATING LAST_UPDATE_DATE UNEXPECTEDLY (Superseded by 8832674)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');         
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">8832674</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.1:CONSOLIDATED POST 12.1.1 ONE-OFFS FOR OWF</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       dbms_output.put_line('</tr>');             
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9585372</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.1:9461373:R.TST1213: ORA-20002 WHEN ASIGNING A ROLE HIERARCHY TO A USE (Superseded by 13498266)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9720970</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.1:9193984:FNDWFLSC FAILS WITH ORA-28665 WHEN WF_USER_ROLE_ASSIGMENTS IS COMPRESSED</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch5||'</td>');
		       dbms_output.put_line('</tr>');     
		       
		       dbms_output.put_line('</table><BR>');

	when :apps_rel = '12.1.2' then
	
	 		select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
				 FROM AD_BUGS b
				   WHERE b.BUG_NUMBER IN '9773716';
	                 
			       dbms_output.put_line('<p><b>Workflow Development recommends the following Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
			       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			       dbms_output.put_line('<td><b>Patch #</b></td>');
			       dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
			       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		           dbms_output.put_line('<td align="center"><b>Status</b></td>');
			       dbms_output.put_line('</tr>');
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">9773716</div></td>');
			       dbms_output.put_line('<td>1OFF:12.1.2:9771657:WFBG DOES NOT EXECUTE SELECTOR FUNCTION WHEN PROCESSING A SUBSEQUENT (Superseded by 17618508)</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       	   dbms_output.put_line('</tr></table><BR>'); 

					dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
					dbms_output.put_line('<tbody><tr><td>');
					dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended patches that are missing.</b><br>');
					dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
					dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
					dbms_output.put_line('</td></tr></tbody></table><BR>');
					
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '15889703';
			   
		       dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Oracle Workflow Engine Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');    
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">15889703</div></td>');
		       dbms_output.put_line('<td>PASSWORD IS DISPLAYED ON THE SERVICE PAYLOAD</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>'); 

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9585372';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '15889703';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '13498266';

		       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Directory Services Patches (WFDS)</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9585372</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.1:9461373:R.TST1213: ORA-20002 WHEN ASIGNING A ROLE HIERARCHY TO A USE (Superseded by 13498266)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">15889703</div></td>');
		       dbms_output.put_line('<td>1OFF:10232921:12.1.2:4016: USER/ROLE WHEN ASSIGNING AN INACTIVE RESPONSIBILITY THROUGH A ROLE</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>'); 
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">13498266</div></td>');
		       dbms_output.put_line('<td>1OFF:10232921:12.1.2:4016: USER/ROLE WHEN ASSIGNING AN INACTIVE RESPONSIBILITY THROUGH A ROLE</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       dbms_output.put_line('</tr>');
		       
		       dbms_output.put_line('</table><BR>');

	when :apps_rel = '12.1.3' then
	

	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '19322157';

	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '19516497';				   
	                 
	                 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '16383560';

	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '18770191';				   

	 		 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch5
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '19474347';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '18598754';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '20051244';				   

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '20230836';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch9
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '20035289';
	                 
			       dbms_output.put_line('<p><b>Workflow Development recommends the following Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
			       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			       dbms_output.put_line('<td><b>Patch #</b></td>');
			       dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
			       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		               dbms_output.put_line('<td align="center"><b>Status</b></td>');
			   dbms_output.put_line('</tr>');
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">19322157</div></td>');
			       dbms_output.put_line('<td>1OFF:12.1.3:19322157:CHILD WORKFLOW LAUNCHED WHEN EVENT IS RAISED INCORRECTLY DECREMENTS COUNTERS</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">19516497</div></td>');
			       dbms_output.put_line('<td>1OFF:5472562:SUMBIT TIME FOR SCHEDULED EVENTS IS NOT SAVED IN OAM ADVANCED MAILER CONFIG</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">16383560</div></td>');
			       dbms_output.put_line('<td>1OFF:ATG_PF.B.DELTA.3:PURGE OBSOLETE WORKFLOW RUNTIME DATA RUNNING TOO LONG</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       	   dbms_output.put_line('</tr>'); 
		       	   dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">18770191</div></td>');
			       dbms_output.put_line('<td>1OFF:12.1.3:18497619:WF_OAM_METRICS DOES NOT POPULATE DATA FOR WF_BPEL_QAGENT IN WF_AGENTS</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">19474347</div></td>');
			       dbms_output.put_line('<td>1OFF:R12.ATG_PF.B.delta.3:JBO-27122: ERROR IN STATUS MONITOR WHEN NOTIFICATION RESPONDED BY E-MAIL</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch5||'</td>');
		       	   dbms_output.put_line('</tr>');
				   dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">18598754</div></td>');
			       dbms_output.put_line('<td>1OFF:18318416:WRONG PERFORMER NAME DISPLAYING IN MONITOR ACTIVITIES HISTORY</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch6||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">20051244</div></td>');
			       dbms_output.put_line('<td>1OFF:16460079:IMPROPER ALIGNMENT OF NOTIFICATION HISTORY SECTION IN THE WORKFLOW</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch7||'</td>');
		       	   dbms_output.put_line('</tr>'); 
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">20230836</div></td>');
			       dbms_output.put_line('<td>OWF:12.1.3+ Recommended Patch Collection DEC-2014</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch8||'</td>');
			       dbms_output.put_line('</tr>'); 
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">20035289</div></td>');
			       dbms_output.put_line('<td>OWF:12.1.3+ Recommended Patch Collection March-2015</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch9||'</td>');
			       dbms_output.put_line('</tr></table><BR>'); 
				   
			dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<b>Workflow Development highly recommends applying any critical or recommended patches that are missing.</b><br>');
			dbms_output.put_line('<i>These recommended workflow patches can also be identified by running the <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976188.1"');
			dbms_output.put_line('target="_blank">Patch Wizard Utility</a></i><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');
						
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '13620594';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '14602624';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch6
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '14676206';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch7
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '15889703';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch8
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '14486429';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch9
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '15910799';
			   
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch10
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '13903857';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch11
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '14474358';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch12
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '15944739';
			   
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch13
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '16054955';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch14
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '16383560';
			   
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch15
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '14769705';
			   
		       dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Oracle Workflow Engine Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');  
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">13620594</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.3:WF ENGINE SLOW PERFORMANCE PROCESSING TIMED-OUT ACTIVITIES (Superseded by 17618508)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">14602624</div></td>');
		       dbms_output.put_line('<td>1OFF:ATG_PF.B.DELTA.3:WF_ENGINE.COMPLETEACTIVITY DOES NOT RAISE EVEN WHEN EXCEPTION IS ENCOUNTERED (Fixed in 17618508)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       dbms_output.put_line('</tr>');                       
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">14676206</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.3:JAVAX.MAIL.SENDFAILEDEXCEPTION: 554 5.7.1 SENDER ADDRESS REJECTED: ACCESS DENIED</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch6||'</td>');
		       dbms_output.put_line('</tr>');  
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">15889703</div></td>');
		       dbms_output.put_line('<td>PASSWORD IS DISPLAYED ON THE SERVICE PAYLOAD</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch7||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">14486429</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.3:CHANGES MADE ON EVENT PL/SQL SUBSCRIPTIONS DO NOT TAKE EFFECTED IMMEDIATELY (Superseded by 17618508)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch8||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">15910799</div></td>');
		       dbms_output.put_line('<td>1OFF:14019692:12.1.3:WORKFLOW FONT/DISPLAY SETTINGS FOR HTML NOTIFICATIONS HAS CHANGED (Superseded by 17618508)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch9||'</td>');
		       dbms_output.put_line('</tr>');  
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">13903857</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.3:SMTPSENDFAILEDEXCEPTION: [EOF] WHEN SENDING EMAIL NOTIFICATIONS (Fixed in 17618508)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch10||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">14474358</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.3:WF MAILER CAN NOT CONNECT TO MAIL STORE WHEN SPECIFIC MIME TYPE IS RECEIVED</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch11||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">15944739</div></td>');
		       dbms_output.put_line('<td>1OFF:13601790:R12.ATG_PF.B.DELTA.3:ERROR NOTIFICATION GIVES EXCEPTION</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch12||'</td>');
		       dbms_output.put_line('</tr>');  
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">16054955</div></td>');
		       dbms_output.put_line('<td>1OFF:ATG_PF.B.DELTA.3:ORA-01555: SNAPSHOT TOO OLD WHEN RUNNING WF_PURGE.DIRECTORY</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch13||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">16383560</div></td>');
		       dbms_output.put_line('<td>1OFFf:ATG_PF.B.DELTA.3:Purge Obsolete Workflow Runtime Data running too long</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch14||'</td>');
		       dbms_output.put_line('</tr>');  
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">14769705</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.3:14750553:WF_NOTIFICATION_ATTRIBUTES growing because duplicate values</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch15||'</td>');
		       dbms_output.put_line('</tr>'); 
		       
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '14266306';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '13498266';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '18247548';
			   
		       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Directory Services Patches (WFDS)</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">14266306</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.3:12568091:ROLES INCORRECTLY GIVEN TO USERS BECAUSE OF PROPAGATION BUG (Superseded by 17618508)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>'); 
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">13498266</div></td>');
		       dbms_output.put_line('<td>1OFF:10232921:12.1.2:4016: USER/ROLE WHEN ASSIGNING AN INACTIVE RESPONSIBILITY THROUGH A ROLE (Superseded by 17618508)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>');		       
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">18247548</div></td>');
		       dbms_output.put_line('<td>1OFF:R12.ATG_PF.B.DELTA.3:16948804:RESPONSIBILITY DISPLAYED ON THE DAY SET TO EFFECTIVE </td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       dbms_output.put_line('</tr>');
		       
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '12627470';
			   
		       dbms_output.put_line('<tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Generic Service Components (GSC)</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">12627470</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.3:11721940:WORKSHIFTS DO NOT WORK WITH JAVA MANAGERS</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">General</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>'); 
		       
		       dbms_output.put_line('</table><BR>');

	when :apps_rel = '12.2.2' then

	 		select decode(Ad_Patch.Is_Patch_Applied('R12',-1,19634693),'EXPLICIT','D7E8B0">APPLIED','CC6666">NOT APPLIED') into :ptch1 From Dual; 

			dbms_output.put_line('<p><b>Workflow Development recommends the following Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
			dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			dbms_output.put_line('<td><b>Patch #</b></td>');
			dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
			dbms_output.put_line('<td align="center"><b>Type</b></td>');
		        dbms_output.put_line('<td align="center"><b>Status</b></td>');
			dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">19634693</div></td>');
			dbms_output.put_line('<td>ORACLE.APPS.FND.WF.BES.WEBSERVICEINVOKERSUBSCRIPTION IS NOT CLOSING THE CURSORS</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('</table><BR>'); 
		       
   
			   dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		       dbms_output.put_line('<tbody><tr><td>');
		       dbms_output.put_line('There are no Workflow patches currently recommended by Workflow Development for this Oracle Applications '||:apps_rel||' instance.<br>');
		       dbms_output.put_line('Nice job!<br><br>');
		       dbms_output.put_line('</td></tr></tbody></table><BR>');

		       dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center"></div></td>');
		       dbms_output.put_line('<td>There are no suggested 1-Off patches for R12.2.2.... yet.</td>');
		       dbms_output.put_line('<td div align="center"></div></td>');
		       dbms_output.put_line('<td align="center" </td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('</table><BR>');		

	when :apps_rel = '12.2.3' then

			select decode(Ad_Patch.Is_Patch_Applied('R12',-1,19047391),'EXPLICIT','D7E8B0">APPLIED','CC6666">NOT APPLIED') into :ptch2 From Dual; 
		   
			select decode(Ad_Patch.Is_Patch_Applied('R12',-1,17765665),'EXPLICIT','D7E8B0">APPLIED','CC6666">NOT APPLIED') into :ptch3 From Dual; 
	                 
			select decode(Ad_Patch.Is_Patch_Applied('R12',-1,18112492),'EXPLICIT','D7E8B0">APPLIED','CC6666">NOT APPLIED') into :ptch4 From Dual; 

			select decode(Ad_Patch.Is_Patch_Applied('R12',-1,19547850),'EXPLICIT','D7E8B0">APPLIED','CC6666">NOT APPLIED') into :ptch5 From Dual; 
		   
		       dbms_output.put_line('<p><b>Workflow Development recommends the following Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">19047391</div></td>');
			dbms_output.put_line('<td>1OFF:12.2.3:19047391:WHILE ENABLING MLS LIGHTWEIGHT FNDNLINS.SQL NEVER ENDS</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       	dbms_output.put_line('</tr>'); 
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">17765665</div></td>');
			dbms_output.put_line('<td>ISG AGENT CONSOLIDATED ONE-OFF PATCH FOR 12.2.3</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       	dbms_output.put_line('</tr>'); 
		       	dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">18112492</div></td>');
			dbms_output.put_line('<td>INVALID ARGUMENT: OAFSLIDEOUTMENU_SKYROS.JS ERROR ON HOME PAGE</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
		       	dbms_output.put_line('</tr>'); 
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">19547850</div></td>');
			dbms_output.put_line('<td>WORKLIST ACCESS - GRANTING - SWITCH USER BUTTON MISSING AFTER UPGRADE</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch5||'</td>');
		       dbms_output.put_line('</tr>');      		       
		       dbms_output.put_line('</table><BR>'); 
			   
		       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		       dbms_output.put_line('<tbody><tr><td>');
		       dbms_output.put_line('There are no Workflow patches currently recommended by Workflow Development for this Oracle Applications '||:apps_rel||' instance.<br>');
		       dbms_output.put_line('Nice job!<br><br>');
		       dbms_output.put_line('</td></tr></tbody></table><BR>');

		       dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Workflow Patches</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center"></div></td>');
		       dbms_output.put_line('<td>There are no suggested 1-Off patches for Oracle EBS R12.2.3.... yet.</td>');
		       dbms_output.put_line('<td div align="center"></div></td>');
		       dbms_output.put_line('<td align="center" </td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('</table><BR>');

	when :apps_rel = '12.2.4' then

			select decode(Ad_Patch.Is_Patch_Applied('R12',-1,20245967),'EXPLICIT','D7E8B0">APPLIED','CC6666">NOT APPLIED') into :ptch6 From Dual; 

			select decode(Ad_Patch.Is_Patch_Applied('R12',-1,120277651),'EXPLICIT','D7E8B0">APPLIED','CC6666">NOT APPLIED') into :ptch7 From Dual;
			
			select decode(Ad_Patch.Is_Patch_Applied('R12',-1,20470720),'EXPLICIT','D7E8B0">APPLIED','CC6666">NOT APPLIED') into :ptch8 From Dual;
			   
		    dbms_output.put_line('<p><b>Workflow Development recommends the following Patches be applied to your '|| :apps_rel ||' instance.</b><br>');
		    dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		    dbms_output.put_line('<td><b>Patch #</b></td>');
		    dbms_output.put_line('<td align="center"><b>Oracle Workflow Recommended Patches</b></td>');
		    dbms_output.put_line('<td align="center"><b>Type</b></td>');
		    dbms_output.put_line('<td align="center"><b>Status</b></td>');
		    dbms_output.put_line('</tr>');
		    dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">20245967</div></td>');
			dbms_output.put_line('<td>1OFF:12.2.4: ADMINISTRATOR MONITOR REASSIGN PAGE ERRORS FOR REASSIGN ACTION</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch6||'</td>');
		    dbms_output.put_line('</tr>'); 
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">20277651</div></td>');
			dbms_output.put_line('<td>JBO-25005: OBJECT NAME GRANTERLISTVO_USER.NAME</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch7||'</td>');
		    dbms_output.put_line('</tr>'); 
			dbms_output.put_line('<tr bordercolor="#000066">');
			dbms_output.put_line('<td>');
			dbms_output.put_line('<div align="center">20470720</div></td>');
			dbms_output.put_line('<td>1OFF:12.2.4:18345086:SMTP AUTHENTICATION FAILS WITH SHARED MAIL BOX ACCOUNT</td>');
			dbms_output.put_line('<td div align="center" bgcolor="#D7E8B0">Recommended</div></td><td align="center" bgcolor="#'||:ptch8||'</td>');
			dbms_output.put_line('</tr></table><BR>');  
			   
		    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		    dbms_output.put_line('<tbody><tr><td>');
		    dbms_output.put_line('There are no Workflow patches currently recommended by Workflow Development for this Oracle Applications '||:apps_rel||' instance.<br>');
		    dbms_output.put_line('Nice job!<br><br>');
		    dbms_output.put_line('</td></tr></tbody></table><BR>');

		    dbms_output.put_line('<p><b>Workflow Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		    dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		    dbms_output.put_line('<td><b>Patch #</b></td>');
		    dbms_output.put_line('<td align="center"><b>Workflow Patches</b></td>');
		    dbms_output.put_line('<td align="center"><b>Type</b></td>');
		    dbms_output.put_line('<td align="center"><b>Status</b></td>');
		    dbms_output.put_line('</tr>');
		    dbms_output.put_line('<tr bordercolor="#000066">');
		    dbms_output.put_line('<td>');
		    dbms_output.put_line('<div align="center"></div></td>');
		    dbms_output.put_line('<td>There are no suggested 1-Off patches for Oracle EBS R12.2.3.... yet.</td>');
		    dbms_output.put_line('<td div align="center"></div></td>');
		    dbms_output.put_line('<td align="center" </td>');
		    dbms_output.put_line('</tr>');     
		    dbms_output.put_line('</table><BR>');
		       
	else 
       
       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td>');
       dbms_output.put_line('There are no 1-Off patches suggested by Workflow Development for this Oracle Applications '||:apps_rel||' instance.<br><br>');
       dbms_output.put_line('<p>For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1"');
       dbms_output.put_line('target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br><br>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');

       dbms_output.put_line('<A href="#top"><font size="-1">Back to Top</font></A><BR><BR>');
       
end CASE;

dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
dbms_output.put_line('<tbody><tr><td>');
dbms_output.put_line('<B>These 1-Off patches are released by Workflow Development to resolve known issues on top of '||:apps_rel||'.</B><br>');
dbms_output.put_line('<p>Please review any suggested 1-Offs (General) that are missing, and verify if they should be applied to your instance.<br>');
dbms_output.put_line('Superseded patches should be included in the patches that supersede them, except in some cases where replacement patches contain the same files, then the superseded patch may be listed also.<br><br>');
dbms_output.put_line('For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1"');
dbms_output.put_line('target="_blank">Note 453137.1</a> - Oracle Workflow Best Practices Release 12 and Release 11i<br><br>');
dbms_output.put_line('</td></tr></tbody></table><BR>');

       
dbms_output.put_line('<A href="#top"><font size="-1">Back to Top</font></A><BR><BR>');

end;
/
prompt </blockquote>


REM
REM ******* Verify Workflow Services Log Levels and Mailer Debug Status *******
REM

prompt <a name="wfadv162"></a><B><U>Workflow Log Levels</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows6sql2(){var row = document.getElementById("s6sql2");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri"></a>
prompt     <B>Check The Status of Workflow Log Levels and Mailer Debug Status</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows6sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s6sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="185">
prompt       <blockquote>
prompt         <p align="left">select SC.COMPONENT_NAME, sc.COMPONENT_TYPE,<br>
prompt 			   v.PARAMETER_DISPLAY_NAME,<br>
prompt 			   decode(v.PARAMETER_VALUE,<br>
prompt 			   '1', '1 = Statement',<br>
prompt 			   '2', '2 = Procedure',<br>
prompt 			   '3', '3 = Event',<br>
prompt 			   '4', '4 = Exception',<br>
prompt 			   '5', '5 = Error',<br>
prompt 			   '6', '6 = Unexpected',<br>
prompt 			   'N', 'N = Not Enabled',<br>
prompt 			   'Y', 'Y = Enabled') VALUE<br>
prompt 			   FROM FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS SC<br>
prompt 			   WHERE v.COMPONENT_ID=sc.COMPONENT_ID <br>
prompt 			   AND v.parameter_name in ('COMPONENT_LOG_LEVEL','DEBUG_MAIL_SESSION')<br>
prompt 			   ORDER BY sc.COMPONENT_TYPE, SC.COMPONENT_NAME, v.PARAMETER_VALUE;</p>
prompt         </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT_NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPONENT_TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PARAMETER</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>VALUE</B></TD>
exec :n := dbms_utility.get_time;
select 
'<TR><TD>'||SC.COMPONENT_NAME||'</TD>'||chr(10)|| 
'<TD>'||sc.COMPONENT_TYPE||'</TD>'||chr(10)|| 
'<TD>'||v.PARAMETER_DISPLAY_NAME||'</TD>'||chr(10)|| 
'<TD>'||decode(v.PARAMETER_VALUE,
'1', '1 = Statement',
'2', '2 = Procedure',
'3', '3 = Event',
'4', '4 = Exception',
'5', '5 = Error',
'6', '6 = Unexpected',	 
'N', 'N = Not Enabled',
'Y', 'Y = Enabled')||'</TD></TR>'
FROM FND_SVC_COMP_PARAM_VALS_V v, FND_SVC_COMPONENTS SC
WHERE v.COMPONENT_ID=sc.COMPONENT_ID 
AND v.parameter_name in ('COMPONENT_LOG_LEVEL','DEBUG_MAIL_SESSION')
ORDER BY sc.COMPONENT_TYPE, SC.COMPONENT_NAME, v.PARAMETER_VALUE;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt If troubleshooting Workflow Agent Listeners or Java Mailer issues, set individual Component Logging Levels to Statement Level logging (Log Level = 1) for the most detail and robust logging level.<BR>
prompt Use $FND_TOP/sql/afsvcpup.sql - AF SVC Parameter UPdate script to change the logging levels.<br>
prompt Remember to reset, or lower the logging level after troubleshooting to not generate excessive log files.
prompt The Mailer Debug parameter (Debug Mail Session) should be ENABLED when troubleshooting issues with any Workflow Notification Mailer.<BR>
prompt <br><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


REM
REM ******* Verify Workflow Services Current Logs *******
REM

prompt <a name="wfadv163"></a><B><U>Current Workflow Services Logs</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows6sql3(){var row = document.getElementById("s6sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt     <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri"> </a>
prompt     <B>Verify Workflow Services Current Logs</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows6sql3()" >SQL Script</button></div>
prompt     </TD>
prompt   </TR>
prompt   <TR id="s6sql3" style="display:none">
prompt     <TD BGCOLOR=#DEE6EF colspan="5" height="150">
prompt       <blockquote>
prompt        <p align="left">select fcq.concurrent_queue_name, fcp.last_update_date,<br>
prompt           fcp.concurrent_process_id,flkup.meaning,fcp.logfile_name<br>
prompt           FROM fnd_concurrent_queues fcq, fnd_concurrent_processes fcp, fnd_lookups
prompt           flkup<br>
prompt           WHERE concurrent_queue_name in ('WFMLRSVC', 'WFALSNRSVC','WFWSSVC')<br>
prompt           AND fcq.concurrent_queue_id = fcp.concurrent_queue_id<br>
prompt           AND fcq.application_id = fcp.queue_application_id<br>
prompt           AND flkup.lookup_code=fcp.process_status_code<br>
prompt           AND lookup_type ='CP_PROCESS_STATUS_CODE'<br>
prompt           AND flkup.meaning='Active';</p>
prompt         </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MANAGER</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LAST_UPDATE_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PID</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MEANING</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LOGFILE_NAME</B></TD>
exec :n := dbms_utility.get_time;
select 
'<TR><TD>'||fcq.concurrent_queue_name||'</TD>'||chr(10)|| 
'<TD>'||fcp.last_update_date||'</TD>'||chr(10)|| 
'<TD>'||fcp.concurrent_process_id||'</TD>'||chr(10)|| 
'<TD>'||flkup.meaning||'</TD>'||chr(10)|| 
'<TD>'||fcp.logfile_name||'</TD></TR>'
FROM fnd_concurrent_queues fcq, fnd_concurrent_processes fcp, fnd_lookups flkup
    WHERE concurrent_queue_name in ('WFMLRSVC', 'WFALSNRSVC','WFWSSVC')
    AND fcq.concurrent_queue_id = fcp.concurrent_queue_id
    AND fcq.application_id = fcp.queue_application_id
    AND flkup.lookup_code=fcp.process_status_code
    AND lookup_type ='CP_PROCESS_STATUS_CODE'
    AND flkup.meaning='Active';
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>
prompt </blockquote>

REM ****************************************************************************************** 
REM *******                   Section 7 : Product Specific Workflows                   *******
REM ******************************************************************************************


prompt <a name="section7"></a><B><font size="+2">Product Specific Workflows</font></B><BR><BR>
prompt <blockquote>

REM
REM ******* ONT - Order Management Workflow Specific Summary *******
REM

prompt <a name="wfprdont"></a><B><font size="+1">ONT - Order Management Workflow Specific Summary</font></B><BR><BR>
prompt <blockquote>

declare 

   run_om_qry 	varchar2(2) :='N';
	
begin

select count(item_key) into :omcnt
from wf_items
where item_type = 'OEOH';

select count(item_key) into :olcnt
from wf_items
where item_type = 'OEOL';

select sum(CNT_TOTAL) into :chart_om_cnt from (
select count(item_key) as "CNT_TOTAL" 
from wf_items wi
where wi.item_type in ('OEOH', 'OEOL', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH')
   or (wi.item_type like '%ERROR%' and wi.parent_item_type in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH'))
   group by item_type);

    
if ((:omcnt > 0) and (:chart_om_cnt > 0)) THEN 

	:run_om_qry := 'Y';
	
	select count(item_key) into :closedomcnt
	from wf_items
	where item_type = 'OEOH'
	and end_date is not null;

	select count(item_key) into :openomcnt
	from wf_items
	where item_type = 'OEOH'
	and end_date is null;

    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><b>Order Management is being used!</b><BR> ');
    dbms_output.put_line('There are ' || to_char(:omcnt,'999,999,999,999') || ' Order Header (OEOH) workflow items found in WF_ITEMS, and ' || to_char(:olcnt,'999,999,999,999') || ' Order Lines (OEOL).<BR>');
    dbms_output.put_line('Currently ' || (round(:openomcnt/:omcnt, 2)*100) || '% (' || to_char(:openomcnt,'999,999,999,999') || ') of OEOHs are OPEN,');
    dbms_output.put_line(' while ' || (round(:closedomcnt/:omcnt, 2)*100) || '% (' || to_char(:closedomcnt,'999,999,999,999') || ') are CLOSED, but still found in the runtime tables.<BR><BR>');
    dbms_output.put_line('The following collection of information is a sample of the more complete Order Management Review that you can get from running OMSuiteDataChk.sql,');
    dbms_output.put_line(' found in <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=353991.1" target="_blank">Note 353991.1</a>.<BR>');
    dbms_output.put_line('The purpose of the OMSuiteDataChk.sql script is to collect information related to data integrity in OM and Shipping products.<BR></p>');
    dbms_output.put_line('</td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');


	select nvl(max(rownum), 0) into :oeoh_cnt
	from wf_items wi
	where wi.item_type in ('OEOH');

	select nvl(max(rownum), 0) into :oeol_cnt
	from wf_items wi
	where wi.item_type in ('OEOL');
	
	select nvl(max(rownum), 0) into :omerror_cnt
	from wf_items wi
	where wi.item_type in ('OMERROR');
	
	select nvl(max(rownum), 0) into :oeoi_cnt
	from wf_items wi
	where wi.item_type in ('OEOI');
	
	select nvl(max(rownum), 0) into :oecogs_cnt
	from wf_items wi
	where wi.item_type in ('OECOGS');

	select nvl(max(rownum), 0) into :oeoa_cnt
	from wf_items wi
	where wi.item_type in ('OEOA');
	
	select nvl(max(rownum), 0) into :oechg_cnt
	from wf_items wi
	where wi.item_type in ('OECHGORD');
	
	select nvl(max(rownum), 0) into :oeon_cnt
	from wf_items wi
	where wi.item_type in ('OEON');
	
	select nvl(max(rownum), 0) into :oebh_cnt
	from wf_items wi
	where wi.item_type in ('OEBH');	
	
	select nvl(max(rownum), 0) into :oewferr_cnt
	from wf_items wi
	where wi.item_type = 'WFERROR' and wi.parent_item_type in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH');
	
	select round(:oeoh_cnt/:chart_om_cnt,2)*100 into :oeohrate from dual;
	select round(:oeol_cnt/:chart_om_cnt,2)*100 into :oeolrate from dual;
	select round(:omerror_cnt/:chart_om_cnt,2)*100 into :omerrorrate from dual;
	select round(:oeoi_cnt/:chart_om_cnt,2)*100 into :oeoirate from dual;
	select round(:oecogs_cnt/:chart_om_cnt,2)*100 into :oecogsrate from dual;
	select round(:oeoa_cnt/:chart_om_cnt,2)*100 into :oeoarate from dual;
	select round(:oechg_cnt/:chart_om_cnt,2)*100 into :oechgrate from dual;
	select round(:oewferr_cnt/:chart_om_cnt,2)*100 into :oewferrrate from dual;
	select round(:oeon_cnt/:chart_om_cnt,2)*100 into :oeonrate from dual;
	select round(:oebh_cnt/:chart_om_cnt,2)*100 into :oebhrate from dual;	

dbms_output.put_line('<BR><B><U>Show the status of the Order Management Workflows for this instance</B></U><BR>');

       
	dbms_output.put('<blockquote><img src="https://chart.googleapis.com/chart?chs=550x270\&chco=3072F3');
	dbms_output.put('\&chd=t:'||:oeohrate||','||:oeolrate||','||:omerrorrate||','||:oeoirate||','||:oecogsrate||','||:oeoarate||','||:oechgrate||','||:oewferrrate||','||:oeonrate||','||:oebhrate||'');
	dbms_output.put_line('\&cht=p3\&chtt=Order+Management+Workflows');
	dbms_output.put_line('\&chl=OEOH|OEOL|OMERROR|OEOI|OECOGS|OEOA|OECHGORD|WFERROR|OEON|OEBH');
	dbms_output.put_line('\&chdl='||:oeoh_cnt||'|'||:oeol_cnt||'|'||:omerror_cnt||'|'||:oeoi_cnt||'|'||:oecogs_cnt||'|'||:oeoa_cnt||'|'||:oechg_cnt||'|'||:oewferr_cnt||'|'||:oeon_cnt||'|'||:oebh_cnt||'"><BR>');
	dbms_output.put_line('Item Types</blockquote>');
	
  	dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
  	dbms_output.put_line('<tbody><tr><td> ');
  	dbms_output.put_line('<p><B>Attention:<BR>');
  	dbms_output.put_line('There are '||to_char(:chart_om_cnt,'999,999,999,999')||' Order Management Workflows found on this instance.</B><BR>');
  	dbms_output.put_line('This includes OEOH, OEOL, OEOI, OECOGS, OEOA, OECHGORD,OEON, OEBH, plus OMERROR and WFERROR belonging to these workflows.');
  	dbms_output.put_line('</p></td></tr></tbody></table><BR>');       
  
       
  elsif ((:omcnt = 0) and (:chart_om_cnt = 0)) THEN 
    
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><B>Attention:<br>');    
    dbms_output.put_line('<p><b>Order Management is not being used!</b><BR> ');
    dbms_output.put_line('There are no Order Header (OEOH) workflow items found in WF_ITEMS, so we will skip this section..<BR><br>');
    dbms_output.put_line('The following Table Headers may still display, however the queries are not run for this section..<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

  else

    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><B>Attention:<br>');    
    dbms_output.put_line('Order Management does not appear to be used on this instance, so we will skip this section.</b><BR><br> ');
    dbms_output.put_line('There are only ' || to_char(:omcnt,'999,999,999,999') || ' Order Header (OEOH) workflow items found in WF_ITEMS.<BR>');
    dbms_output.put_line('The following Table Headers may still display, however the queries are not run for this section..<BR><BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>'); 

 end if;   
end;
/


REM
REM ******* Order Management Types *******
REM

prompt <script type="text/javascript">    function displayRows7sql1(){var row = document.getElementById("s7sql1");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>SUMMARY of Order Management Workflow Processes By Item Type</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows7sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="150">
prompt       <blockquote><p align="left">
prompt          select wi.item_type, wit.display_name, wi.parent-item_type, nvl(to_char(end_date, 'YYYY'),'OPEN') CLOSED, count(item_key) COUNT<br> 
prompt          from wf_items wi, wf_item_types_tl wit<br>
prompt          where wi.item_type = wit.name <br>
prompt          and wit.language = 'US'<br>
prompt          and (item_type in ('OEOH', 'OEOL', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH')<br>
prompt               or (item_type like '%ERROR%' and parent_item_type in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH')))<br>
prompt          group by wi.item_type, wit.display_name, wi.parent-item_type, to_char(end_date, 'YYYY')<br>
prompt          order by 4;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PARENT_ITEM_TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CLOSED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select   
'<TR><TD><div align="left">'||wi.ITEM_TYPE||'</div></TD>'||chr(10)||
'<TD><div align="left">'||wit.DISPLAY_NAME||'</div></TD>'||chr(10)||
'<TD><div align="left">'||wi.PARENT_ITEM_TYPE||'</div></TD>'||chr(10)||
'<TD><div align="center">'||nvl(to_char(wi.end_date, 'YYYY'),'OPEN')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(count(wi.item_key),'999,999,999,999')||'</div></TD></TR>'
from wf_items wi, wf_item_types_tl wit
where wi.item_type = wit.name 
and wit.language = 'US'
and (wi.item_type in ('OEOH', 'OEOL', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH')
     or (wi.item_type like '%ERROR%' and wi.parent_item_type in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH')))
and :run_om_qry = 'Y'
group by wi.item_type, wit.display_name, wi.parent_item_type, to_char(wi.end_date, 'YYYY')
order by to_char(wi.end_date, 'YYYY');
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt <table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">
prompt <tbody><tr><td> 
prompt <p><b>Attention:<br>
prompt Sometimes customizations and modifications can cause exceptions, data corruption or degraded performance.</b><br>
prompt To help identify possible workflow design flaws, we recommend using OM workflow validation program.<br> 
prompt Please validate workflow order types using ‘Validate OM Workflow’ (OEXVWF) concurrent program. <br><br>
prompt Please refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=113492.1" target="_blank">Note 113492.1</a> - Oracle Order Management Suite White Papers for details.</p>
prompt </p></td></tr></tbody></table><BR>

prompt <script type="text/javascript">    function displayRows7sql12(){var row = document.getElementById("s7sql12");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Verify Order Management Workflow Concurrent Programs Scheduled to Run</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows7sql12()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql12" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="185">
prompt       <blockquote><p align="left">
prompt          select r.REQUEST_ID, u.user_name, r.PHASE_CODE, r.ACTUAL_START_DATE,<br>
prompt          c.CONCURRENT_PROGRAM_NAME, p.USER_CONCURRENT_PROGRAM_NAME, r.ARGUMENT_TEXT, <br>
prompt          r.RESUBMIT_INTERVAL, r.RESUBMIT_INTERVAL_UNIT_CODE, r.RESUBMIT_END_DATE<br>
prompt          FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u <br>
prompt          WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id <br>
prompt          and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID <br>
prompt          and c.CONCURRENT_PROGRAM_NAME in ('OEXVWF','OEXEXMBR','OEXPWF') <br>
prompt          AND p.language = 'US' <br>
prompt          and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')<br>
prompt          order by c.CONCURRENT_PROGRAM_NAME;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUEST_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>REQUESTED_BY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PHASE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>STARTED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>INTERNAL NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROGRAM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ARGUMENTS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>EVERY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SO_OFTEN</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RESUBMIT_END_DATE</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||r.REQUEST_ID||'</TD>'||chr(10)|| 
'<TD>'||u.user_name||'</TD>'||chr(10)|| 
'<TD>'||r.PHASE_CODE||'</TD>'||chr(10)|| 
'<TD>'||r.ACTUAL_START_DATE||'</TD>'||chr(10)||
'<TD>'||c.CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)|| 
'<TD>'||p.USER_CONCURRENT_PROGRAM_NAME||'</TD>'||chr(10)||
'<TD>'||r.ARGUMENT_TEXT||'</TD>'||chr(10)|| 
'<TD>'||r.RESUBMIT_INTERVAL||'</TD>'||chr(10)||  
'<TD>'||r.RESUBMIT_INTERVAL_UNIT_CODE||'</TD>'||chr(10)||
'<TD>'||r.RESUBMIT_END_DATE||'</TD></TR>'
FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u 
WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id 
and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
and c.CONCURRENT_PROGRAM_NAME in ('OEXPWF','OEXVWF','OEXEXMBR','FNDWFBG') 
AND p.language = 'US' 
and r.ACTUAL_COMPLETION_DATE is null and r.PHASE_CODE in ('P','R')
and :run_om_qry = 'Y'
order by c.CONCURRENT_PROGRAM_NAME;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

	select count(r.REQUEST_ID) into :omprgcnt
	FROM fnd_concurrent_requests r, FND_CONCURRENT_PROGRAMS_TL p, fnd_concurrent_programs c, fnd_user u 
	WHERE r.CONCURRENT_PROGRAM_ID = p.CONCURRENT_PROGRAM_ID and r.requested_by = u.user_id 
	and p.CONCURRENT_PROGRAM_ID = c.CONCURRENT_PROGRAM_ID 
	and c.CONCURRENT_PROGRAM_NAME = 'OEXPWF'
	AND p.language = 'US';
       
if ((:run_om_qry = 'Y') and (:omprgcnt > 0)) THEN 

    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p>The Order Management Purge Concurrent Request (OEXPWF) is currently being used!<BR><BR> ');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=878032.1" target="_blank">');
    dbms_output.put_line('Note 878032.1</a> - How To Use Concurrent Program :Purge Order Management Workflow.<BR>');
    dbms_output.put_line('Also review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=398822.1" target="_blank">');
    dbms_output.put_line('Note 398822.1</a> - Order Management Suite - Some Data Fix Patches and Scripts.<BR>');
    dbms_output.put_line('These Notes provide information on the use of "Purge Order Management Workflow" concurrent program, to purge closed workflows, specific to Order Management. <BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

  elsif ((:run_om_qry = 'Y') and (:omprgcnt = 0)) THEN 
    
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><B>Attention:<br>');    
    dbms_output.put_line('<p>There are no records showing the Order Management Purge Concurrent Request (OEXPWF) is currently being used!<BR></B> ');
    dbms_output.put_line('This could also be true if Concurrent Manager Data is purged regularly.<BR><br>');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=878032.1" target="_blank">');
    dbms_output.put_line('Note 878032.1</a> - How To Use Concurrent Program :Purge Order Management Workflow.<BR>');
    dbms_output.put_line('Also review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=398822.1" target="_blank">');
    dbms_output.put_line('Note 398822.1</a> - Order Management Suite - Some Data Fix Patches and Scripts.<BR>');
    dbms_output.put_line('These Notes provide information on the use of "Purge Order Management Workflow" concurrent program, to purge closed workflows, specific to Order Management. <BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');


  else
    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');      
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p>Since Order Management does not appear to used in this instance, there is no need to schedule or run the Order Management Purge Concurrent Request (OEXPWF).<BR> ');
    dbms_output.put_line('If Order Management is installed in the future, please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=878032.1" target="_blank">');
    dbms_output.put_line('Note 878032.1</a> - How To Use Concurrent Program :Purge Order Management Workflow.<BR>');
    dbms_output.put_line('This Note provides information on the use of "Purge Order Management Workflow" concurrent program, to purge closed workflows, specific to Order Management. <BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');
    

 end if;
    
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <script type="text/javascript">    function displayRows7sql13(){var row = document.getElementById("s7sql13");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=5 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Deferred Order Management Activities in Workflow Background Engine Table (WF_DEFERRED_TABLE_M)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows7sql13()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql13" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="6" height="185">
prompt       <blockquote><p align="left">
prompt       select a.user_data.itemtype ITEM_TYPE, a.user_data.itemkey, a.ENQ_TIME,<br>
prompt       a.user_data.actid ACTIVITY_ID, a.msg_state,<br>
prompt       wpa.process_name ||'/'||wpa.instance_label PROCESS_NAME_LABEL<br>
prompt         from applsys.aq$wf_deferred_table_m a,wf_process_activities wpa <br>
prompt        where a.user_data.itemtype in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH') <br>
prompt          and a.user_data.itemtype= wpa.process_item_type <br>
prompt          and a.user_data.actid=wpa.instance_id<br>
prompt       order by a.ENQ_TIME;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVITY_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MSG_STATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><div align="right"><B>PROCESS_LABEL</B></div></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVITY_LABEL</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||a.user_data.itemtype||'</TD>'||chr(10)|| 
'<TD>'||a.user_data.actid||'</TD>'||chr(10)|| 
'<TD>'||a.msg_state||'</TD>'||chr(10)|| 
'<TD><div align="right">'||wpa.process_name||'</div></TD>'||chr(10)|| 
'<TD><div align="left">'||wpa.instance_label||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(count(a.user_data.itemkey),'999,999,999,999')||'</div></TD></TR>'
  from applsys.aq$wf_deferred_table_m a,wf_process_activities wpa 
 where a.user_data.itemtype in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH') 
   and a.user_data.itemtype= wpa.process_item_type 
   and a.user_data.actid=wpa.instance_id
   and :run_om_qry = 'Y'
group by a.user_data.itemtype, a.user_data.actid, a.msg_state, wpa.process_name, wpa.instance_label
order by count(a.user_data.itemkey) desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt <script type="text/javascript">    function displayRows7sql14(){var row = document.getElementById("s7sql14");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Deferred Order Management Events in Workflow Deferred Queue Table (WF_DEFERRED)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows7sql14()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql14" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt       select a.CORR_ID, a.msg_state, count(*) <br>
prompt       from APPLSYS.aq$WF_DEFERRED a<br>
prompt       where a.corr_id like 'APPS:oracle.apps.ont.%'<br>
prompt       group by a.CORR_ID, a.msg_state<br>
prompt       order by 3 desc, 1 asc;<br>
prompt       <br>
prompt       To see all the details of the WF_DEFERRED table use :<br>
prompt       <br>
prompt       select * from applsys.aq$wf_deferred wfd;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CORR_ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>MSG_STATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||a.CORR_ID||'</TD>'||chr(10)|| 
'<TD>'||a.msg_state||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(*),'999,999,999,999')||'</div></TD></TR>'
 from APPLSYS.aq$WF_DEFERRED a
 where a.corr_id like 'APPS:oracle.apps.ont.%'
 group by a.CORR_ID, a.msg_state
 order by count(*) desc, a.CORR_ID asc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

begin
	
if ((:apps_rel > '12.0') or (:ATGRUP4 > 0)) then 
	:ATGRUP4 := 1;
else
	:ATGRUP4 := 0;    
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><b>Attention:<br>');    
    dbms_output.put_line('11i.ATG_PF.H.RUP4 (Patch 4676589) is NOT applied, so the following table will fail as expected.</b><br>');
    dbms_output.put_line('This table queries WF_ITEM_TYPES for columns that are added after 11i.ATG_PF.H.RUP4 (Patch 4676589).<BR>');
    dbms_output.put_line('Please ignore this table and error.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table>');	
end if;
end;
/

prompt <script type="text/javascript">    function displayRows7sql3(){var row = document.getElementById("s7sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>SUMMARY of Workflow Processes By Item Type and Status</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows7sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="150">
prompt       <blockquote><p align="left">
prompt          select NUM_ACTIVE, NUM_COMPLETE, NUM_PURGEABLE, WIT.NAME, DISPLAY_NAME, <br>
prompt          PERSISTENCE_TYPE, PERSISTENCE_DAYS, NUM_ERROR, NUM_DEFER, NUM_SUSPEND<br>
prompt          from wf_item_types wit, wf_item_types_tl wtl<br>
prompt          where wit.name in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH')<br>
prompt          AND wtl.name = wit.name<br>
prompt          AND wtl.language = userenv('LANG')<br>
prompt          AND wit.NUM_ACTIVE is not NULL<br>
prompt          AND wit.NUM_ACTIVE <>0 <br>
prompt          order by PERSISTENCE_TYPE, NUM_COMPLETE desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPLETED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PURGEABLE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE_TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE_DAYS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ERRORED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DEFERRED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SUSPENDED</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD><div align="right">'||to_char(NUM_ACTIVE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_COMPLETE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="left">'||to_char(NUM_PURGEABLE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="left">'||WIT.NAME||'</div></TD>'||chr(10)||
'<TD><div align="left">'||DISPLAY_NAME||'</div></TD>'||chr(10)||
'<TD><div align="center">'||PERSISTENCE_TYPE||'</div></TD>'||chr(10)||
'<TD><div align="center">'||PERSISTENCE_DAYS||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_ERROR,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_DEFER,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_SUSPEND,'999,999,999,999')||'</div></TD></TR>'
from wf_item_types wit, wf_item_types_tl wtl
where wit.name in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH')
and :run_om_qry = 'Y'
AND wtl.name = wit.name
AND wtl.language = userenv('LANG')
AND wit.NUM_ACTIVE is not NULL
AND wit.NUM_ACTIVE <>0 
and :run_om_qry = 'Y'
order by PERSISTENCE_TYPE, NUM_COMPLETE desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Top 30 Large Order Management Item Activity Status History Items *******
REM

prompt <table border="1" name="Notebox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td><font size="+1"><B>Order Management Workflow Looping Activities :</B></font><br>
prompt It is normal for Order Management Workflows to use WAITS and other looping activities to process delayed responses and other criteria.<BR>
prompt Each revisit of a node replaces the previous data with the current activities status and stores the old activity information into a activities history table.<BR>
prompt Looking at this history table (WF_ITEM_ACTIVITY_STATUSES_H) can help to identify possible long running workflows that appear to be stuck in a loop over a long time,<br>
prompt or a poorly designed workflow that is looping excessively and can cause performance issues.<BR>
prompt </p></td></tr></tbody></table><BR>

prompt <script type="text/javascript">    function displayRows7sql4(){var row = document.getElementById("s7sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=6 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Top 30 Large Item Activity Status History OM Items</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows7sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="7" height="125">
prompt       <blockquote><p align="left">
prompt       Declare     <br>
prompt          l_act varchar2(1000);<br>
prompt       <br>
prompt       cursor cp is <br>
prompt       SELECT sta.item_type ITEM_TYPE, sta.item_key ITEM_KEY, COUNT(*) COUNT,<br>
prompt       TO_CHAR(wfi.begin_date, 'YYYY-MM-DD') OPENED, TO_CHAR(wfi.end_date, 'YYYY-MM-DD') CLOSED, wfi.user_key DESCRIPTION<br>
prompt       FROM wf_item_activity_statuses_h sta, wf_items wfi <br>
prompt       WHERE sta.item_type = wfi.item_type AND sta.item_key = wfi.item_key <br>
prompt       AND wfi.item_type in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH') <br>
prompt       GROUP BY sta.item_type, sta.item_key, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD'), wfi.user_key<br>
prompt       HAVING COUNT(*) > 500 <br>
prompt       ORDER BY COUNT(*) DESC;<br>
prompt       <br>
prompt       cursor cp2 (p_item_key in varchar2) is   select distinct Activity_name  <br>
prompt         from wf_process_activities<br>
prompt          where instance_id in (select process_activity from wf_item_activity_statuses_h where item_key =p_item_key);<br>
prompt       <br>
prompt       Begin<br>
prompt             dbms_output.put_line("(TABLE border="1" cellspacing="0" cellpadding="2")");<br>
prompt              dbms_output.put_line("(TR bgcolor="#DEE6EF" bordercolor="#DEE6EF")(TD COLSPAN=7 bordercolor="#DEE6EF")(font face="Calibri")");<br>
prompt              dbms_output.put_line("(a name="wfadmins")(/a)<B>Top 30 Large Item Activity Status History OM Items</B>(/font)(/TD)(/TR)");<br>
prompt              dbms_output.put_line("(TR)");<br>
prompt              dbms_output.put_line("(TD BGCOLOR=#DEE6EF)(font face="Calibri")<B>Item_Type</B>(/font)(/TD)");<br>
prompt              dbms_output.put_line("(TD BGCOLOR=#DEE6EF)(font face="Calibri")<B>Item_Key</B>(/font)(/TD)");<br>
prompt              dbms_output.put_line("(TD BGCOLOR=#DEE6EF)(font face="Calibri")<B>Count</B>(/font)(/TD)");<br>
prompt              dbms_output.put_line("(TD BGCOLOR=#DEE6EF)(font face="Calibri")<B>Opened</B>(/font)(/TD)");<br>
prompt              dbms_output.put_line("(TD BGCOLOR=#DEE6EF)(font face="Calibri")<B>Closed</B>(/font)(/TD)");<br>
prompt              dbms_output.put_line("(TD BGCOLOR=#DEE6EF)(font face="Calibri")<B>Description</B>(/font)(/TD)");<br>
prompt              dbms_output.put_line("(TD BGCOLOR=#DEE6EF)(font face="Calibri")<B>Activities in Loop</B>(/font)(/TD)");<br>
prompt       <br>           
prompt       For c1 in cp<br>
prompt       LOOP<br>
prompt       	l_act:=null;<br>
prompt           dbms_output.put_line("(TR)(TD)"||c1.item_type||"(/TD)");<br>                            
prompt           dbms_output.put_line("(TD)"||c1.item_key||"(/TD)"); <br>
prompt           dbms_output.put_line("(TD)"||c1.count||"(/TD)"); <br>
prompt           dbms_output.put_line("(TD)"||c1.opened||"(/TD)"); <br>
prompt           dbms_output.put_line("(TD)"||c1.closed||"(/TD)"); <br>
prompt           dbms_output.put_line("(TD)"||c1.description||"(/TD)"); <br>
prompt           For c2 in cp2(c1.item_key)<br>
prompt           LOOP<br>
prompt           <br>
prompt           l_act := l_act||" | "||c2.activity_name;<br>
prompt           END LOOP;<br>
prompt           l_act := ltrim(l_act," | ");<br>
prompt           dbms_output.put_line("(TD)"||l_act||"(/TD)"); <br>
prompt       END LOOP;<br>
prompt       dbms_output.put_line("(/TABLE><P><P)");<br>
prompt       Exception<br>
prompt       When others then<br>
prompt       dbms_output.put_line("Error at activities count"||sqlerrm);<br>
prompt       <br>
prompt       END;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">ITEM_KEY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">COUNT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">OPENED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">CLOSED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">DESCRIPTION</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">ACTIVITIES_IN_LOOP</B></TD>
exec :n := dbms_utility.get_time;

Declare

l_act varchar2(1000);

cursor cp is 
SELECT * FROM (SELECT sta.item_type ITEM_TYPE, sta.item_key ITEM_KEY, COUNT(*) COUNT,
TO_CHAR(wfi.begin_date, 'YYYY-MM-DD') OPENED, TO_CHAR(wfi.end_date, 'YYYY-MM-DD') CLOSED, wfi.user_key DESCRIPTION
FROM wf_item_activity_statuses_h sta, 
wf_items wfi 
WHERE sta.item_type = wfi.item_type AND sta.item_key = wfi.item_key 
AND wfi.item_type in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH') 
GROUP BY sta.item_type, sta.item_key, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD'), wfi.user_key
HAVING COUNT(*) > 500 
ORDER BY COUNT(*) DESC)
WHERE ROWNUM < 31;

cursor cp2 (p_item_key in varchar2) is   
select distinct Activity_name  
  from wf_process_activities
 where instance_id in (select process_activity from wf_item_activity_statuses_h where item_key =p_item_key);

Begin
       
For c1 in cp
LOOP
	l_act:=null;
    dbms_output.put_line('<TR><TD>'||c1.item_type||'</TD>');                                                                                                     
    dbms_output.put_line('<TD>'||c1.item_key||'</TD>'); 
    dbms_output.put_line('<TD>'||c1.count||'</TD>'); 
    dbms_output.put_line('<TD>'||c1.opened||'</TD>'); 
    dbms_output.put_line('<TD>'||c1.closed||'</TD>'); 
    dbms_output.put_line('<TD>'||c1.description||'</TD>'); 
    For c2 in cp2(c1.item_key)
    LOOP
    
    l_act := l_act||' | '||c2.activity_name;
    END LOOP;
    l_act := ltrim(l_act,' | ');
    dbms_output.put_line('<TD>'||l_act||'</TD>'); 
END LOOP;
dbms_output.put_line('</TABLE><P><P>');
Exception
When others then
dbms_output.put_line('Error at activities count'||sqlerrm);

END;
/

prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');


begin

:hasrows := 0;

SELECT count(*) into :hasrows FROM (SELECT sta.item_type 
FROM wf_item_activity_statuses_h sta, wf_items wfi 
WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key 
AND wfi.item_type in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH') 
and :run_om_qry = 'Y'
GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
HAVING COUNT(*) > 300 
ORDER BY COUNT(*) DESC);

if (:hasrows>0) then

	SELECT * into :hist_item FROM (SELECT sta.item_type 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	select * into :hist_key from (SELECT sta.item_key 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	SELECT * into :hist_end  
	FROM (SELECT end_date from wf_items where item_type = :hist_item and item_key = :hist_key);

	SELECT * into :hist_cnt FROM (SELECT count(sta.item_key) 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	SELECT * into :hist_begin
	FROM (SELECT to_char(begin_date, 'Mon DD, YYYY') from  wf_items where item_type = :hist_item and item_key = :hist_key);

	select * into :hist_days
	from (select round(sysdate-begin_date,0) from wf_items where item_type = :hist_item and item_key = :hist_key);
	
	select * into :hist_recent 
	FROM (SELECT to_char(max(begin_date),'Mon DD, YYYY') from wf_item_activity_statuses_h
	where item_type = :hist_item and item_key = :hist_key);

	select sysdate into :sysdate from dual;


	    if ((:hist_end is null) and (:hist_days=0)) then 
		
		:hist_daily := :hist_cnt;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> ');
	       dbms_output.put_line('Currently, the largest single Order Management activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This workflow process is still open, so this may be a problem. It was started on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>');       

	   elsif ((:hist_end is null) and (:hist_days > 0)) then 

		select ROUND((:hist_cnt/:hist_days),0) into :hist_daily from dual;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single Order Management activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This workflow process is still open. It was started back on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>');
	       dbms_output.put_line('Please review if this is OK to remain in Open status for your business.<br>');

	   elsif ((:hist_end is not null) and (:hist_days = 0)) then 

		select ROUND((:hist_cnt/:hist_days),0) into :hist_daily from dual;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single Order Management activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This process has been closed since ' || :hist_end || ', it was started on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>');
	       
	   else 

		select ROUND((:hist_cnt/:hist_days),2) into :hist_daily from dual;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single Order Management activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This process has been closed since ' || :hist_end || '.<BR>');
	       
	    end if;       

	       dbms_output.put_line('So far this one activity for item_type ' || :hist_item || ' and item_key ' || :hist_key || ' has looped ' || to_char(:hist_cnt,'999,999,999,999') || ' times since it started in ' || :hist_begin || '.<BR>');
	       dbms_output.put_line('<B>Action:</B><BR>');
	       dbms_output.put_line('This is a good place to start, as this single Order Management activity has been looping for ' || to_char(:hist_days,'999,999') || ' days, which is about ' || to_char(:hist_daily,'999,999.99') || ' times a day.<BR>');
	       dbms_output.put_line('Please review the order if this is OK to remain in Open status for your business. Once order is closed you can refer to ');
	       dbms_output.put_line('<a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1358724.1 " target="_blank">');
	       dbms_output.put_line('Note 1358724.1 </a> - Information about Order Management Purge Programs: mechanism, base table, data and OM-specific WF purging program, Purge Order Management Workflow, which is available in 12.1.2 and up.');
	       dbms_output.put_line('Please validate workflow order types using "Validate OM Workflow" concurrent program. <br>');
	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

elsif ((:hasrows=0) and (:run_om_qry = 'Y')) then 

       dbms_output.put_line('<table border="1" name="GoodJob" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Well Done !!</B><BR><BR>');
       dbms_output.put_line('There are NO ROWS found in the HISTORY table (wf_item_activity_statuses_h) for Order Management that have over 300 rows associated to the same item_key.<BR>');
       dbms_output.put_line('This is a good result, which means there is no major looping issues at this time.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

elsif ((:hasrows=0) and (:run_om_qry = 'N')) then 

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
       dbms_output.put_line('<p><B>Attention:<br>');    
       dbms_output.put_line('<b>Order Management does not appear to be used on this instance, so we will skip this section.</b><BR> ');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');
       
end if;
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <B><U>Check for Order Headers Eligible to be Closed but remains in Open Status</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows7sql11(){var row = document.getElementById("s7sql11");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Order Headers Eligible to be Closed but remains in Open Status</B></font></TD>
prompt     <TD bordercolor="#EE6EF">
prompt       <div align="right"><button onclick="displayRows7sql11()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql11" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="185">
prompt       <blockquote><p align="left">
prompt          SELECT P.INSTANCE_LABEL, WAS.ITEM_KEY, H.ORDER_NUMBER, H.ORG_ID<br>
prompt          FROM   WF_ITEM_ACTIVITY_STATUSES WAS,<br>
prompt            WF_PROCESS_ACTIVITIES P, <br>
prompt            OE_ORDER_HEADERS_ALL H<br>
prompt          WHERE TO_NUMBER(WAS.ITEM_KEY) = H.HEADER_ID<br>
prompt          AND   WAS.PROCESS_ACTIVITY = P.INSTANCE_ID<br>
prompt          AND   P.ACTIVITY_ITEM_TYPE = 'OEOH'<br>
prompt          AND   P.ACTIVITY_NAME = 'CLOSE_WAIT_FOR_L'<br>
prompt          AND   WAS.ACTIVITY_STATUS = 'NOTIFIED'<br>
prompt          AND   WAS.ITEM_TYPE = 'OEOH'<br>
prompt          AND   NOT EXISTS ( SELECT /*+ NO_UNNEST */ 1<br>
prompt          	      FROM   OE_ORDER_LINES_ALL<br>
prompt          	      WHERE  HEADER_ID = TO_NUMBER(WAS.ITEM_KEY)<br>
prompt          	      AND    OPEN_FLAG = 'Y');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LABEL</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_KEY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ORDER_NUMBER</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ORG_ID</B></TD>
exec :n := dbms_utility.get_time;
SELECT * FROM (SELECT 
'<TR><TD>'||P.INSTANCE_LABEL||'</TD>'||chr(10)|| 
'<TD>'||WAS.ITEM_KEY||'</TD>'||chr(10)|| 
'<TD>'||H.ORDER_NUMBER||'</TD>'||chr(10)|| 
'<TD>'||H.ORG_ID||'</TD></TR>'
FROM   WF_ITEM_ACTIVITY_STATUSES WAS,
  WF_PROCESS_ACTIVITIES P, 
  OE_ORDER_HEADERS_ALL H
WHERE TO_NUMBER(WAS.ITEM_KEY) = H.HEADER_ID
AND   WAS.PROCESS_ACTIVITY = P.INSTANCE_ID
AND   P.ACTIVITY_ITEM_TYPE = 'OEOH'
AND   P.ACTIVITY_NAME = 'CLOSE_WAIT_FOR_L'
AND   WAS.ACTIVITY_STATUS = 'NOTIFIED'
AND   WAS.ITEM_TYPE = 'OEOH'
AND :run_om_qry = 'Y'
AND   NOT EXISTS ( SELECT /*+ NO_UNNEST */ 1
	      FROM   OE_ORDER_LINES_ALL
	      WHERE  HEADER_ID = TO_NUMBER(WAS.ITEM_KEY)
	      AND    OPEN_FLAG = 'Y'))
where rownum < 31;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">
prompt <tbody><tr><td> 
prompt <p><b>Attention:<br>
prompt Above Order Headers whose workflow are notified at ‘Close- Wait for Line’ activity and have no open order lines.</b><br><br>
prompt Please refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=397548.1" target="_blank">Note 397548.1</a> to fix above records via a patch.
prompt </p></td></tr></tbody></table><BR><BR>


prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>



prompt <B><U>Order Management Workflows in Error</B></U><BR>
prompt <blockquote>

prompt Use bde_wf_err.sql script from <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=255045.1" target="_blank">Note 255045.1</a> to get details of any erroring activities.<BR>
begin
  if (:apps_rel = '11.5.9') then 
	dbms_output.put_line('OM Exception management allows to retry failing OM activities. See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=311579.1" target="_blank">Note 311579.1</a>.<BR><BR>');
  elsif (:apps_rel > '11.5.9') then
	dbms_output.put_line('There are some data fix scripts to clean up data corruption issues.<br>');
	dbms_output.put_line('Please refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=398822.1" target="_blank">Note 398822.1');
	dbms_output.put_line('</a> - Order Management Suite - Some Data Fix Patches and Scripts.<br><br>');
  else
	dbms_output.put_line('<br>');
  end if;
end;
/

prompt <script type="text/javascript">    function displayRows7sql5(){var row = document.getElementById("s7sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Order Management Workflow Errors by Item Type, Result and Activities</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows7sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="185">
prompt       <blockquote><p align="left">
prompt          select STA.ITEM_TYPE ITEM_TYPE,  STA.ACTIVITY_RESULT_CODE RESULT,<br>  
prompt          PRA.PROCESS_NAME ||':'|| PRA.INSTANCE_LABEL PROCESS_ACTIVITY_LABEL,  count(STA.ITEM_KEY) "TOTAL ROWS"<br>
prompt          from  WF_ITEM_ACTIVITY_STATUSES  STA, WF_PROCESS_ACTIVITIES PRA<br>
prompt          where STA.ACTIVITY_STATUS    = 'ERROR'<br>
prompt          and STA.PROCESS_ACTIVITY   = PRA.INSTANCE_ID<br>
prompt          and STA.ITEM_TYPE          in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH')<br>
prompt          group by STA.ITEM_TYPE, STA.ACTIVITY_RESULT_CODE, PRA.PROCESS_NAME ||':'|| PRA.INSTANCE_LABEL<br>
prompt          order by count(STA.ITEM_KEY) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RESULT</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><div align="right"><B>PROCESS_LABEL</B></div></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVITY_LABEL</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL ROWS</B></TD>
exec :n := dbms_utility.get_time;
SELECT * FROM (SELECT  
'<TR><TD>'||STA.ITEM_TYPE||'</TD>'||chr(10)|| 
'<TD>'||STA.ACTIVITY_RESULT_CODE||'</TD>'||chr(10)|| 
'<TD><div align="right">'||PRA.PROCESS_NAME||'</div></TD>'||chr(10)|| 
'<TD><div align="left">'||PRA.INSTANCE_LABEL||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(STA.ITEM_KEY),'999,999,999,999')||'</div></TD></TR>'
 from  WF_ITEM_ACTIVITY_STATUSES  STA, WF_PROCESS_ACTIVITIES PRA
 where STA.ACTIVITY_STATUS = 'ERROR'
   and STA.PROCESS_ACTIVITY = PRA.INSTANCE_ID
   and STA.ITEM_TYPE in ('OEOH', 'OEOL', 'OMERROR', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH')
   and :run_om_qry = 'Y'
 group by STA.ITEM_TYPE, STA.ACTIVITY_RESULT_CODE, PRA.PROCESS_NAME, PRA.INSTANCE_LABEL
 order by count(STA.ITEM_KEY) desc)
where rownum < 31; 
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <script type="text/javascript">    function displayRows7sql6(){var row = document.getElementById("s7sql6");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Order Management Workflow Error processes to cancel (that are no longer needed)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows7sql6()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql6" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt          select  e.item_type, e.parent_item_type, count(1) as "Total rows"<br>
prompt          from wf_items e<br>
prompt          where (e.item_type= 'WFERROR' or e.item_type= 'OMERROR')<br>
prompt          and e.parent_item_type in ('OEOH', 'OEOL', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH')<br>
prompt          and e.end_date is null<br>
prompt          and not exists(<br>
prompt              select 1 from wf_item_activity_statuses s<br>
prompt              where s.item_type =  e.parent_item_type<br>
prompt              and   s.item_key = e.parent_item_key<br>
prompt              and   s.activity_status = 'ERROR')<br>
prompt          group by e.item_type, e.parent_item_type;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PARENT_ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL ROWS</B></TD>
exec :n := dbms_utility.get_time;
SELECT * FROM (SELECT 
'<TR><TD>'||e.item_type||'</TD>'||chr(10)|| 
'<TD>'||e.parent_item_type||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(e.item_type),'999,999,999,999')||'</div></TD></TR>'
   from wf_items e
   where (e.item_type= 'WFERROR' or e.item_type= 'OMERROR')
   and e.parent_item_type in ('OEOH', 'OEOL', 'OEOI', 'OECOGS', 'OEOA', 'OECHGORD','OEON','OEBH')
   and e.end_date is null
   and :run_om_qry = 'Y'
   and not exists(
       select 1 from wf_item_activity_statuses s
       where s.item_type =  e.parent_item_type
       and   s.item_key = e.parent_item_key
       and   s.activity_status = 'ERROR')
   group by e.item_type, e.parent_item_type
   order by count(e.item_type) desc)
where rownum < 31;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <script type="text/javascript">    function displayRows7sql7(){var row = document.getElementById("s7sql7");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Line Open and Workflow Initiated but not Started</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows7sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql7" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt          select count(1), to_char(min(last_update_date), 'DD-MON-RR') "First UpdateDate",<br>
prompt                 to_char(max(last_update_date), 'DD-MON-RR') "Last UpdateDate"<br>
prompt          from wf_items wit, oe_order_lines_all l<br>
prompt          where wit.item_type = 'OEOL'<br>
prompt          and   wit.end_date is null<br>
prompt          and to_number(wit.item_key) = l.line_id<br>
prompt          and l.open_flag = 'Y'<br>
prompt          and nvl(l.cancelled_flag, 'N') = 'N'<br>
prompt          and :query3 = 'Y'<br>
prompt          and not exists(<br>
prompt               select 1 from wf_item_activity_statuses sta<br>
prompt               where sta.item_type  = wit.item_type<br>
prompt               and sta.item_key = wit.item_key);</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FIRST_UPDATE_DATE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LAST_UPDATE_DATE</B></TD>
exec :n := dbms_utility.get_time;
SELECT  
'<TR><TD>'||count(*)||'</TD>'||chr(10)|| 
'<TD>'||to_char(min(last_update_date), 'DD-MON-RR')||'</TD>'||chr(10)|| 
'<TD>'||to_char(max(last_update_date), 'DD-MON-RR')||'</TD></TR>'
    from wf_items wit, oe_order_lines_all l
    where wit.item_type = 'OEOL'
    and   wit.end_date is null
    and to_number(wit.item_key) = l.line_id
    and l.open_flag = 'Y'
    and nvl(l.cancelled_flag, 'N') = 'N'
    and :run_om_qry = 'Y'
    and not exists(
             select 1 from wf_item_activity_statuses sta
             where sta.item_type  = wit.item_type
             and sta.item_key = wit.item_key);
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <script type="text/javascript">    function displayRows7sql8(){var row = document.getElementById("s7sql8");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>OEOL pending workflows for closed order lines</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows7sql8()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql8" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt          SELECT  /*+ INDEX (wit WF_ITEMS_PK) */ count(*),<br>
prompt          to_char(Min(Last_Update_Date), 'DD-MON-RR'),<br>
prompt          to_char(max(last_update_date), 'DD-MON-RR')<br>
prompt          from oe_order_lines_all l, wf_items wi<br>
prompt          where l.open_flag = 'N' <br>
prompt          And l.line_id = to_number(wi.item_key)<br>
prompt          and wi.item_type = 'OEOL'<br>
prompt          and wi.end_date is null;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL_LINES</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FIRST_UPDATE_DATE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LAST_UPDATE_DATE</B></TD>
exec :n := dbms_utility.get_time;
SELECT  /*+ INDEX (wit WF_ITEMS_PK) */
'<TR><TD>'||count(*)||'</TD>'||chr(10)|| 
'<TD>'||to_char(min(last_update_date), 'DD-MON-RR')||'</TD>'||chr(10)|| 
'<TD>'||to_char(max(last_update_date), 'DD-MON-RR')||'</TD></TR>'
from oe_order_lines_all l, wf_items wi
where l.open_flag = 'N' 
and l.line_id = to_number(wi.item_key)
and wi.item_type = 'OEOL'
and wi.end_date is null
and :run_om_qry = 'Y';
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>             
prompt </blockquote>


prompt <B><U>Data Analysis for Sales Order Headers</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows7sql9(){var row = document.getElementById("s7sql9");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=6 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Top 30 Pending Header Flows with no open lines and no children workflows</B></font></TD>
prompt     <TD bordercolor="#EE6EF">
prompt       <div align="right"><button onclick="displayRows7sql9()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql9" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="7" height="185">
prompt       <blockquote><p align="left">
prompt          select h.org_id, h.order_number, was.item_key "Header  ID", h.flow_status_code "HEADER STATUS",<br>
prompt          h.open_flag "HDR_OPEN", h.cancelled_flag "HDR_CANCEL", to_char(h.last_update_date, 'MM/DD/RRRR') LAST_UPDATE<br>
prompt          from wf_item_activity_statuses was, wf_process_activities p, oe_order_headers_all h<br>
prompt          where to_number(was.item_key) = h.header_id<br>
prompt          and was.process_activity = p.instance_id<br>
prompt          and p.activity_item_type = 'OEOH'<br>
prompt          and p.activity_name = 'CLOSE_WAIT_FOR_L'<br>
prompt          and was.activity_status = 'NOTIFIED'<br>
prompt          and was.item_type = 'OEOH'<br>
prompt          and not exists (<br>
prompt             select /*+ NO_INDEX (l oe_order_lines_n15) */1 from oe_order_lines_all<br>
prompt             where  header_id = to_number(was.item_key)<br>
prompt             and    open_flag = 'Y');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ORG ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ORDER #</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>HEADER ID</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>HEADER STATUS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>HEADER OPEN</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>HEADER CANCEL</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LAST_UPDATE</B></TD>
exec :n := dbms_utility.get_time;
SELECT * FROM (SELECT 
'<TR><TD>'||h.org_id||'</TD>'||chr(10)|| 
'<TD>'||h.order_number||'</TD>'||chr(10)|| 
'<TD>'||was.item_key||'</TD>'||chr(10)|| 
'<TD>'||h.flow_status_code||'</TD>'||chr(10)|| 
'<TD><div align="center">'||h.open_flag||'</div></TD>'||chr(10)|| 
'<TD><div align="center">'||h.cancelled_flag||'</div></TD>'||chr(10)|| 
'<TD>'||to_char(h.last_update_date, 'MM/DD/RRRR')||'</TD></TR>'
from wf_item_activity_statuses was, wf_process_activities p, oe_order_headers_all h
where to_number(was.item_key) = h.header_id
and was.process_activity = p.instance_id
and p.activity_item_type = 'OEOH'
and p.activity_name = 'CLOSE_WAIT_FOR_L'
and was.activity_status = 'NOTIFIED'
and was.item_type = 'OEOH'
and :run_om_qry = 'Y'
and not exists (
   select /*+ NO_INDEX (l oe_order_lines_n15) */1 from oe_order_lines_all
   where  header_id = to_number(was.item_key)
   and    open_flag = 'Y')) 
WHERE ROWNUM < 31;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <script type="text/javascript">    function displayRows7sql10(){var row = document.getElementById("s7sql10");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Cancelled or Closed Headers with Open Lines</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows7sql10()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s7sql10" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt          select count(1) "Total rows",<br>
prompt                 to_char(min(h.last_update_date), 'DD-MON-RR') "First UpdateDate",<br>
prompt                 to_char(max(h.last_update_date), 'DD-MON-RR') "Last UpdateDate"<br>
prompt          from oe_order_headers_all h, oe_order_lines_all l<br>
prompt          where h.header_id = l.header_id<br>
prompt          and h.open_flag = 'N' <br>
prompt          and l.open_flag = 'Y';</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL_ROWS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>FIRST_UPDATE_DATE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>LAST_UPDATE_DATE</B></TD>
exec :n := dbms_utility.get_time;
SELECT 
'<TR><TD>'||count(*)||'</TD>'||chr(10)|| 
'<TD>'||to_char(min(h.last_update_date), 'DD-MON-RR')||'</TD>'||chr(10)|| 
'<TD>'||to_char(max(h.last_update_date), 'DD-MON-RR')||'</TD></TR>'
from oe_order_headers_all h
, oe_order_lines_all l
where h.header_id = l.header_id
and h.open_flag = 'N' 
and l.open_flag = 'Y'
and :run_om_qry = 'Y';
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">
prompt <tbody><font face="Calibri"><tr><td>
prompt <p><b>Attention:</b><br> 
prompt There are some data fix scripts to clean up data corruption issues. <br>
prompt Please refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=398822.1" target="_blank">Note 398822.1</a> - Order Management Suite - Some Data Fix Patches and Scripts.<BR>
prompt </p></td></tr></tbody></table>
prompt <br>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR> 
prompt </blockquote>



prompt <B><U>Order Management Orphaned Workflows</B></U><BR>
prompt <blockquote>

begin

	:orphhdr := 0;
	:orphline := 0;
	
	select count(1) into :orphline
	from wf_items wi
	where item_type = 'OEOL'
	and parent_item_type = 'OEOH'
	and end_date is null
	and :run_om_qry = 'Y'
	and not exists (
	select 1 from oe_order_lines_all
	where line_id = to_number(wi.item_key));
	
	select count(1) into :orphhdr
	from wf_items wi
	where item_type = 'OEOH'
	and end_date is null
	and :run_om_qry = 'Y'
	and not exists (
	select 1 from oe_order_headers_all
	where header_id = to_number(wi.item_key));

    
if (:orphhdr = 0) THEN 

    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p>There are no Order Management header ids that exist in WF_items but not found in oe_order_headers_all!!!<BR><BR> ');
    dbms_output.put_line('This is GOOD !! <BR></p>');
    dbms_output.put_line('</td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');

  elsif (:orphhdr > 0) THEN 
  
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><B>Attention:<br>');    
    dbms_output.put_line('There are '||:orphhdr||' Order Management header ids that exist in WF_ITEMS but not found in OE_ORDER_HEADERS_ALL !!!</B><br><BR> ');
    dbms_output.put_line('Please run the following query to isolate these Orphaned Workflows and close them so they can be purged.');
    dbms_output.put_line('<blockquote><i>select item_type, item_key, begin_date, end_date, user_key<br>');
    dbms_output.put_line('from wf_items wi<br>');
    dbms_output.put_line('where item_type = \''OEOH\''<br>');
    dbms_output.put_line('and end_date is null<br>');
    dbms_output.put_line('and not exists (<br>');
    dbms_output.put_line('select 1 from oe_order_headers_all<br>');
    dbms_output.put_line('where header_id = to_number(wi.item_key)); </i></blockquote>');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=398822.1" target="_blank">');
    dbms_output.put_line('Note 398822.1</a> - Order Management Suite - Some Data Fix Patches and Scripts.<BR>');    
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

  else
    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');      
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p>There is a problem reviewing the Order Headers Orphan workflow items, we need to beef this condition up a bit.<BR></p>');
    dbms_output.put_line('</td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');
    
 end if;

if (:orphline = 0) THEN 

    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p>There are no Order Lines that exist in WF_ITEMS but not found in oe_order_lines_all!!!<BR><BR> ');
    dbms_output.put_line('This is GOOD !! <BR></p>');
    dbms_output.put_line('</td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');

  elsif (:orphline > 0) THEN 
  
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><B>Attention:<br>');      
    dbms_output.put_line('There are '||:orphline||' Order Lines that exist in WF_ITEMS but not found in OE_ORDER_LINES_ALL !!!</b><BR><br>');
    dbms_output.put_line('Please run the following query to isolate these Orphaned Workflows and close them so they can be purged.');
    dbms_output.put_line('<blockquote><i>select item_type, item_key, begin_date, end_date, user_key<br>');
    dbms_output.put_line('   from wf_items wi<br>');
    dbms_output.put_line('   where item_type = \''OEOL\''<br>');
    dbms_output.put_line('   and parent_item_type = \''OEOH\''<br>');
    dbms_output.put_line('   and end_date is null<br>');
    dbms_output.put_line('    and not exists (<br>');
    dbms_output.put_line('     select 1 from oe_order_lines_all<br>');
    dbms_output.put_line('     where line_id = to_number(wi.item_key)); </i></blockquote>');
    dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=398822.1" target="_blank">');
    dbms_output.put_line('Note 398822.1</a> - Order Management Suite - Some Data Fix Patches and Scripts.<BR>');      
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

  else
    dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');      
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p>There is a problem reviewing the Order Lines Orphan workflow items, we need to beef this condition up a bit.<BR></p>');
    dbms_output.put_line('</td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');
    
 end if;
 
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>
prompt </blockquote>

REM
REM ******* HCM - HRMS Human Resources Workflow Specific Summary *******
REM

prompt <a name="wfprdhcm"></a><B><font size="+1">HCM - HRMS Human Resources Workflow Specific Summary</font></B><BR><BR>

prompt <blockquote>

declare 

   run_hcm_qry 	varchar2(2) :='N';
	
begin

select count(item_key) into :hrcnt
from wf_items
where item_type = 'HRSSA';

select sum(CNT_TOTAL) into :chart_hr from (
select count(item_key) as "CNT_TOTAL" 
from wf_items wi
where wi.item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')    
     or (wi.item_type like '%ERROR%' and wi.parent_item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL'))
   group by item_type);

if ((:hrcnt > 0) and (:chart_hr > 0)) THEN 

	:run_hcm_qry := 'Y';
	
	select count(item_key) into :chrcnt
	from wf_items
	where item_type = 'HRSSA'
	and end_date is not null;

	select count(item_key) into :ohrcnt
	from wf_items
	where item_type = 'HRSSA'
	and end_date is null;
   
    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><b>Human Resources is being used!</b><BR> ');
    dbms_output.put_line('There are ' || to_char(:hrcnt,'999,999,999,999') || ' HR (HRSSA) workflow items found in WF_ITEMS.<BR>');
    dbms_output.put_line('Currently ' || (round(:ohrcnt/:hrcnt, 2)*100) || '% (' || to_char(:ohrcnt,'999,999,999,999') || ') of HRSSAs are OPEN,');
    dbms_output.put_line(' while ' || (round(:chrcnt/:hrcnt, 2)*100) || '% (' || to_char(:chrcnt,'999,999,999,999') || ') are CLOSED, but still found in the runtime tables.<BR><BR>');
    dbms_output.put_line('The following collection of information is a sample of the more complete Human Resources Review that you can get from');
    dbms_output.put_line(' <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1562530.1" target="_blank">Note 1562530.1</a> - Human Capital Management (HCM) Technical Analyzer script ');
    dbms_output.put_line('(Human Resources, Self Service Human Resources, Payroll, Time and Labor, Benefits, iRecruitment, Learning Management).<BR></p>');
    dbms_output.put_line('</td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');


	select nvl(max(rownum), 0) into :c1
	from wf_items wi
	where wi.item_type in ('BENCWBFY');

	select nvl(max(rownum), 0) into :c2
	from wf_items wi
	where wi.item_type in ('SSBEN');
	
	select nvl(max(rownum), 0) into :c3
	from wf_items wi
	where wi.item_type in ('GHR_SF52');
	
	select nvl(max(rownum), 0) into :c4
	from wf_items wi
	where wi.item_type in ('HXCEMP');
	
	select nvl(max(rownum), 0) into :c5
	from wf_items wi
	where wi.item_type in ('HXCSAW');

	select nvl(max(rownum), 0) into :c6
	from wf_items wi
	where wi.item_type in ('IRC_NTF');
	
	select nvl(max(rownum), 0) into :c7
	from wf_items wi
	where wi.item_type in ('IRCOFFER');

	select nvl(max(rownum), 0) into :c8
	from wf_items wi
	where wi.item_type in ('OTWF');
	
	select nvl(max(rownum), 0) into :c9
	from wf_items wi
	where wi.item_type in ('PYASGWF');
	
	select nvl(max(rownum), 0) into :c10
	from wf_items wi
	where wi.item_type in ('HRCKLTSK');
	
	select nvl(max(rownum), 0) into :hr_cnt
	from wf_items wi
	where wi.item_type in ('HRSSA');

	select nvl(max(rownum), 0) into :c11
	from wf_items wi
	where wi.item_type in ('HRWPM');
	
	select nvl(max(rownum), 0) into :c12
	from wf_items wi
	where wi.item_type in ('HRRIRPRC');
	
	select nvl(max(rownum), 0) into :c13
	from wf_items wi
	where wi.item_type in ('PSPERAVL');
	
	select nvl(max(rownum), 0) into :c14
	from wf_items wi
	where wi.item_type = 'WFERROR' and wi.parent_item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL');
	
 	select round(:c1/:chart_hr,2)*100 into :r1 from dual;
 	select round(:c2/:chart_hr,2)*100 into :r2 from dual;
 	select round(:c3/:chart_hr,2)*100 into :r3 from dual;
 	select round(:c4/:chart_hr,2)*100 into :r4 from dual;
 	select round(:c5/:chart_hr,2)*100 into :r5 from dual;
 	select round(:c6/:chart_hr,2)*100 into :r6 from dual;
 	select round(:c7/:chart_hr,2)*100 into :r7 from dual;
 	select round(:c8/:chart_hr,2)*100 into :r8 from dual;
 	select round(:c9/:chart_hr,2)*100 into :r9 from dual;
 	select round(:c10/:chart_hr,2)*100 into :r10 from dual;
 	select round(:hr_cnt/:chart_hr,2)*100 into :hrsrate from dual;
 	select round(:c11/:chart_hr,2)*100 into :r11 from dual;
 	select round(:c12/:chart_hr,2)*100 into :r12 from dual;
 	select round(:c13/:chart_hr,2)*100 into :r13 from dual;
 	select round(:c14/:chart_hr,2)*100 into :r14 from dual;

dbms_output.put_line('<BR><B><U>Show the status of the Human Resources Workflows for this instance</B></U><BR><BR>');

	dbms_output.put('<blockquote><img src="https://chart.googleapis.com/chart?chs=550x270\&chco=7777CC');
	dbms_output.put('\&chd=t:'||:r1||','||:r2||','||:r3||','||:r4||','||:r5||','||:r6||','||:r7||','||:r8||','||:r9||','||:r10||','||:hrsrate||','||:r11||','||:r12||','||:r13||'');
	dbms_output.put_line('\&cht=p3\&chtt=Human+Resources+Workflows');
	dbms_output.put_line('\&chl=BENCWBFY|SSBEN|GHR_SF52|HXCEMP|HXCSAW|IRC_NTF|IRCOFFER|OTWF|PYASGWF|HRCKLTSK|HRSSA|HRWPM|HRRIRPRC|PSPERAVL');
	dbms_output.put_line('\&chdl='||:c1||'|'||:c2||'|'||:c3||'|'||:c4||'|'||:c5||'|'||:c6||'|'||:c7||'|'||:c8||'|'||:c9||'|'||:c10||'|'||:hr_cnt||'|'||:c11||'|'||:c12||'|'||:c13||'"><BR>');
	dbms_output.put_line('Item Types</blockquote>');


  	dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
  	dbms_output.put_line('<tbody><tr><td> ');
  	dbms_output.put_line('<p><B>Attention:<BR>');
  	dbms_output.put_line('There are '||to_char(:chart_hr,'999,999,999,999')||' Human Resources Workflows found on this instance.</B><BR>');
  	dbms_output.put_line('</p></td></tr></tbody></table><BR>');


  elsif ((:hrcnt = 0) and (:chart_hr = 0)) THEN 
    
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><B>Attention:<br>');    
    dbms_output.put_line('Order Management is not being used!</b><BR> ');
    dbms_output.put_line('There are no Human Resources (HRSSA) workflow items found in WF_ITEMS, so we will skip this section..<BR>');
    dbms_output.put_line('The following Table Headers may still display, however the queries are not run for this section..<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

  else

    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><B>Attention:<br>');    
    dbms_output.put_line('Human Resources does not appear to be used on this instance, so we will skip this section.</b><BR> ');
    dbms_output.put_line('There are only ' || to_char(:hrcnt,'999,999,999,999') || ' Human Resources (HRSSA) workflow items found in WF_ITEMS.<BR>');
    dbms_output.put_line('The following Table Headers may still display, however the queries are not run for this section..<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

 end if;   
end;
/


prompt <script type="text/javascript"> function displayRows8sql1(){var row = document.getElementById("s8sql1");if (row.style.display == '') row.style.display = 'none';	else row.style.display = '';}</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>SUMMARY of All HCM Workflow Processes By Item Type</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows8sql1()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s8sql1" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="185">
prompt       <blockquote><p align="left">
prompt          select wi.item_type, wit.display_name, nvl(to_char(end_date, 'YYYY'),'OPEN') CLOSED, count(item_key) COUNT<br>
prompt          from wf_items wi, wf_item_types_tl wit<br>
prompt          where wi.item_type = wit.name<br> 
prompt          and wit.language = 'US'<br>
prompt          and (item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')<br>
prompt               or (item_type like '%ERROR%' and parent_item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')))<br>
prompt          group by wi.item_type, wit.display_name, to_char(end_date, 'YYYY')<br>
prompt          order by 4;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CLOSED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||wi.item_type||'</TD>'||chr(10)|| 
'<TD>'||wit.display_name||'</TD>'||chr(10)|| 
'<TD>'||nvl(to_char(wi.end_date, 'YYYY'),'OPEN')||'</TD>'||chr(10)|| 
'<TD>'||count(wi.item_key)||'</TD></TR>'
from wf_items wi, wf_item_types_tl wit
where wi.item_type = wit.name 
and wit.language = 'US'
and (wi.item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 
                      'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')    
     or (wi.item_type like '%ERROR%' and wi.parent_item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 
     'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')))
and :run_hcm_qry = 'Y'
group by wi.item_type, wit.display_name, to_char(wi.end_date, 'YYYY')
order by count(wi.item_key);
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

begin
	
if ((:apps_rel > '12.0') or (:ATGRUP4 > 0)) then 
	:ATGRUP4 := 1;
else
	:ATGRUP4 := 0;    
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><b>Attention:<br>');    
    dbms_output.put_line('11i.ATG_PF.H.RUP4 (Patch 4676589) is NOT applied, so the following table will fail as expected.</b><br>');
    dbms_output.put_line('This table queries WF_ITEM_TYPES for columns that are added after 11i.ATG_PF.H.RUP4 (Patch 4676589).<BR>');
    dbms_output.put_line('Please ignore this table and error.<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	
end if;
end;
/

prompt <script type="text/javascript"> function displayRows8sql2(){var row = document.getElementById("s8sql2");if (row.style.display == '') row.style.display = 'none'; else row.style.display = '';}</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=9 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>SUMMARY of HCM Workflow Processes By Item Type</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows8sql2()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s8sql2" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="10" height="150">
prompt       <blockquote><p align="left">
prompt          select NUM_ACTIVE, NUM_COMPLETE, NUM_PURGEABLE, WIT.NAME, DISPLAY_NAME, <br>
prompt          PERSISTENCE_TYPE, PERSISTENCE_DAYS, NUM_ERROR, NUM_DEFER, NUM_SUSPEND<br>
prompt          from wf_item_types wit, wf_item_types_tl wtl<br>
prompt          where wit.name in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF',<br>
prompt          'IRCOFFER','OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')<br>
prompt          AND wtl.name = wit.name<br>
prompt          AND wtl.language = userenv('LANG')<br>
prompt          AND wit.NUM_ACTIVE is not NULL<br>
prompt          AND wit.NUM_ACTIVE <>0 <br>
prompt          order by PERSISTENCE_TYPE, NUM_COMPLETE desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COMPLETED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PURGEABLE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DISPLAY_NAME</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE_TYPE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PERSISTENCE_DAYS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ERRORED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>DEFERRED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>SUSPENDED</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD><div align="right">'||to_char(NUM_ACTIVE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_COMPLETE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="left">'||to_char(NUM_PURGEABLE,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="left">'||WIT.NAME||'</div></TD>'||chr(10)||
'<TD><div align="left">'||DISPLAY_NAME||'</div></TD>'||chr(10)||
'<TD><div align="center">'||PERSISTENCE_TYPE||'</div></TD>'||chr(10)||
'<TD><div align="center">'||PERSISTENCE_DAYS||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_ERROR,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_DEFER,'999,999,999,999')||'</div></TD>'||chr(10)||
'<TD><div align="right">'||to_char(NUM_SUSPEND,'999,999,999,999')||'</div></TD></TR>'
from wf_item_types wit, wf_item_types_tl wtl
where wit.name in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')
and wtl.name = wit.name
and wtl.language = userenv('LANG')
and wit.NUM_ACTIVE is not NULL
and wit.NUM_ACTIVE <>0 
and :run_hcm_qry = 'Y'
order by PERSISTENCE_TYPE, NUM_COMPLETE desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <script type="text/javascript">    function displayRows8sql3(){var row = document.getElementById("s8sql3");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>HCM Errors by Item Type, Result and Activities</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows8sql3()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s8sql3" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="185">
prompt       <blockquote><p align="left">
prompt          select STA.ITEM_TYPE, STA.ACTIVITY_RESULT_CODE, PRA.PROCESS_NAME, <br>
prompt                 PRA.INSTANCE_LABEL, to_char(count(*),'999,999,999,999')<br>
prompt           from  WF_ITEM_ACTIVITY_STATUSES  STA, WF_PROCESS_ACTIVITIES PRA<br>
prompt           where STA.ACTIVITY_STATUS = 'ERROR'<br>
prompt             and STA.PROCESS_ACTIVITY = PRA.INSTANCE_ID<br>
prompt             and STA.ITEM_TYPE in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER',<br>
prompt                                   'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')<br>
prompt           group by STA.ITEM_TYPE, STA.ACTIVITY_RESULT_CODE, PRA.PROCESS_NAME, PRA.INSTANCE_LABEL<br>
prompt           order by STA.ITEM_TYPE, STA.ACTIVITY_RESULT_CODE, PRA.PROCESS_NAME, PRA.INSTANCE_LABEL;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RESULT</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROCESS_LABEL</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVITY_LABEL</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL ROWS</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||STA.ITEM_TYPE||'</TD>'||chr(10)|| 
'<TD>'||STA.ACTIVITY_RESULT_CODE||'</TD>'||chr(10)|| 
'<TD><div align="right">'||PRA.PROCESS_NAME||'</div></TD>'||chr(10)|| 
'<TD><div align="left">'||PRA.INSTANCE_LABEL||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(*),'999,999,999,999')||'</div></TD></TR>'
 from  WF_ITEM_ACTIVITY_STATUSES  STA, WF_PROCESS_ACTIVITIES PRA
 where STA.ACTIVITY_STATUS = 'ERROR'
   and STA.PROCESS_ACTIVITY = PRA.INSTANCE_ID
   and STA.ITEM_TYPE in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')
   and :run_hcm_qry = 'Y'
 group by STA.ITEM_TYPE, STA.ACTIVITY_RESULT_CODE, PRA.PROCESS_NAME, PRA.INSTANCE_LABEL
 order by STA.ITEM_TYPE, STA.ACTIVITY_RESULT_CODE, PRA.PROCESS_NAME, PRA.INSTANCE_LABEL;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <script type="text/javascript">    function displayRows8sql4(){var row = document.getElementById("s8sql4");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>HCM Workflow Error processes to cancel (that are no longer needed)</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows8sql4()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s8sql4" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="185">
prompt       <blockquote><p align="left">
prompt          select e.item_type, e.parent_item_type, count(e.item_key)<br>
prompt          from wf_items e<br>
prompt          where e.item_type like '%ERROR%'<br>
prompt          and e.parent_item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER',  <br>
prompt                                     'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')<br>
prompt          and e.end_date is null<br>
prompt          and not exists(<br>
prompt              select 1 from wf_item_activity_statuses s<br>
prompt              where s.item_type =  e.parent_item_type<br>
prompt              and   s.item_key = e.parent_item_key<br>
prompt              and   s.activity_status = 'ERROR')<br>
prompt          group by e.item_type, e.parent_item_type<br>
prompt          order by count(e.item_key) desc;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PARENT_ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL ROWS</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||e.item_type||'</TD>'||chr(10)|| 
'<TD>'||e.parent_item_type||'</TD>'||chr(10)|| 
'<TD>'||count(e.item_key)||'</TD></TR>'
from wf_items e
where e.item_type like '%ERROR%'
and e.parent_item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')
and e.end_date is null
and :run_hcm_qry = 'Y'
and not exists(
    select 1 from wf_item_activity_statuses s
    where s.item_type =  e.parent_item_type
    and   s.item_key = e.parent_item_key
    and   s.activity_status = 'ERROR')
group by e.item_type, e.parent_item_type
order by count(e.item_key) desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


REM
REM ******* Top 30 Large Human Resources Item Activity Status History Items *******
REM

prompt <table border="1" name="Notebox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td><font size="+1"><B>Human Resources Workflow Looping Activities :</B></font><br>
prompt It is normal for HCM Workflows to use WAITS and other looping acitivities to process delayed responses and other criteria.<BR>
prompt Each revisit of a node replaces the previous data with the current activities status and stores the old activity information into a activities history table.<BR>
prompt Looking at this history table (WF_ITEM_ACTIVITY_STATUSES_H) can help to identify possible long running workflows that appear to be stuck in a loop over a long time,<br>
prompt or a poorly designed workflow that is looping excessively and can cause performance issues.<BR>
prompt </p></td></tr></tbody></table><BR>

prompt <script type="text/javascript">    function displayRows8sql5(){var row = document.getElementById("s8sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=5 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Top 30 Large Item Activity Status History HCM Items</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows8sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s8sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="6" height="125">
prompt       <blockquote><p align="left">
prompt          SELECT sta.item_type ITEM_TYPE, sta.item_key ITEM_KEY, COUNT(*) COUNT,<br>
prompt          TO_CHAR(wfi.begin_date, 'YYYY-MM-DD') OPENED, TO_CHAR(wfi.end_date, 'YYYY-MM-DD') CLOSED, wfi.user_key DESCRIPTION<br>
prompt          FROM wf_item_activity_statuses_h sta, <br>
prompt          wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key <br>
prompt          AND wfi.item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')<br>
prompt          GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), <br>
prompt          TO_CHAR(wfi.end_date, 'YYYY-MM-DD') <br>
prompt          HAVING COUNT(*) > 300 <br>
prompt          ORDER BY COUNT(*) DESC;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">ITEM_KEY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">COUNT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">BEGIN_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">END_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">DESCRIPTION</B></TD>
exec :n := dbms_utility.get_time;
SELECT * FROM (SELECT  
'<TR><TD>'||sta.item_type||'</TD>'||chr(10)|| 
'<TD>'||sta.item_key||'</TD>'||chr(10)|| 
'<TD>'||to_char(COUNT(*),'999,999,999,999')||'</TD>'||chr(10)|| 
'<TD>'||TO_CHAR(wfi.begin_date, 'YYYY-MM-DD')||'</TD>'||chr(10)|| 
'<TD>'||TO_CHAR(wfi.end_date, 'YYYY-MM-DD')||'</TD>'||chr(10)|| 
'<TD>'||wfi.user_key||'</TD></TR>'
FROM wf_item_activity_statuses_h sta, 
wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key 
and :run_hcm_qry = 'Y' AND wfi.item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL') 
GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
HAVING COUNT(*) > 300 
ORDER BY COUNT(*) DESC) 
WHERE ROWNUM < 31;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');


begin

:hasrows := 0;

SELECT count(*) into :hasrows FROM (SELECT sta.item_type 
FROM wf_item_activity_statuses_h sta, 
wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key 
AND wfi.item_type in ('BENCWBFY', 'SSBEN', 'GHR_SF52', 'HXCEMP', 'HXCSAW', 'IRC_NTF', 'IRCOFFER', 'OTWF', 'PYASGWF', 'HRCKLTSK', 'HRSSA', 'HRWPM', 'HRRIRPRC', 'PSPERAVL')
and :run_hcm_qry = 'Y'
GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
HAVING COUNT(*) > 300 
ORDER BY COUNT(*) DESC);

if (:hasrows>0) then

	SELECT * into :hist_item FROM (SELECT sta.item_type 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	select * into :hist_key from (SELECT sta.item_key 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	SELECT * into :hist_end  
	FROM (SELECT end_date from wf_items where item_type = :hist_item and item_key = :hist_key);

	SELECT * into :hist_cnt FROM (SELECT count(sta.item_key) 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type LIKE '%' 
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 500 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	SELECT * into :hist_begin
	FROM (SELECT to_char(begin_date, 'Mon DD, YYYY') from  wf_items where item_type = :hist_item and item_key = :hist_key);

	select * into :hist_days
	from (select round(sysdate-begin_date,0) from wf_items where item_type = :hist_item and item_key = :hist_key);
	
	select * into :hist_recent 
	FROM (SELECT to_char(max(begin_date),'Mon DD, YYYY') from wf_item_activity_statuses_h
	where item_type = :hist_item and item_key = :hist_key);

	select sysdate into :sysdate from dual;


	    if ((:hist_end is null) and (:hist_days=0)) then 
		
		:hist_daily := :hist_cnt;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> ');
	       dbms_output.put_line('Currently, the largest single Human Resources Workflow activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This workflow process is still open, so this may be a problem. It was started on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>');       

	   elsif ((:hist_end is null) and (:hist_days > 0)) then 

		select ROUND((:hist_cnt/:hist_days),0) into :hist_daily from dual;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single Human Resources Workflow activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This workflow process is still open, so this may be a problem. It was started back on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>'); 

	   elsif ((:hist_end is not null) and (:hist_days = 0)) then 

		select ROUND((:hist_cnt/:hist_days),0) into :hist_daily from dual;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single Human Resources Workflow activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This process has been closed since ' || :hist_end || ', it was started on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>');
	       
	   else 

		select ROUND((:hist_cnt/:hist_days),2) into :hist_daily from dual;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single Human Resources Workflow activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This process has been closed since ' || :hist_end || '.<BR>');
	       
	    end if;       

	       dbms_output.put_line('So far this one activity for item_type ' || :hist_item || ' and item_key ' || :hist_key || ' has looped ' || to_char(:hist_cnt,'999,999,999,999') || ' times since it started in ' || :hist_begin || '.<BR>');
	       dbms_output.put_line('<B>Action:</B><BR>');
	       dbms_output.put_line('This is a good place to start, as this single Human Resources Workflow activity has been looping for ' || to_char(:hist_days,'999,999') || ' days, which is about ' || to_char(:hist_daily,'999,999.99') || ' times a day.<BR>');
	       dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=144806.1" target="_blank">');
	       dbms_output.put_line('Note 144806.1</a> - A Detailed Approach To Purging Oracle Workflow Runtime Data on how to drill down and discover how to purge this workflow data.<br>');
	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

elsif ((:hasrows=0) and (:run_hcm_qry = 'Y')) then 

       dbms_output.put_line('<table border="1" name="GoodJob" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Well Done !!</B><BR><BR>');
       dbms_output.put_line('There are NO ROWS found in the HISTORY table (wf_item_activity_statuses_h) for Human Resources that have over 300 rows associated to the same item_key.<BR>');
       dbms_output.put_line('This is a good result, which means there is no major looping issues at this time.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

elsif ((:hasrows=0) and (:run_hcm_qry = 'N')) then 

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
       dbms_output.put_line('<p><B>Attention:<br>');    
       dbms_output.put_line('<b>Human Resources (HCM) does not appear to be used on this instance, so we will skip this section.</b><BR> ');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

end if;
end;
/

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt </blockquote>

REM
REM ******* PO - Purchasing Workflow Specific Summary *******
REM

prompt <a name="wfprdpo"></a><B><font size="+1">PO - Purchasing Workflow Specific Summary</font></B><BR><BR>

prompt <blockquote>

declare 

   run_po_qry 	varchar2(2) :='N';
	
begin

select count(item_key) into :po_cnt
from wf_items
where item_type = 'POAPPRV';

select sum(CNT_TOTAL) into :chart_po from (
select count(item_key) as "CNT_TOTAL" 
from wf_items wi
where wi.item_type in ('POAPPRV','REQAPPRV','POXML','POWFRQAG','PORCPT','APVRMDER','PONPBLSH','POSPOACK','PONAUCT','PORPOCHA','PODSNOTF','POSREGV2','POREQCHA','POWFPOAG','POSCHORD','POSASNNB','PONAPPRV','POSCHPDT','POAUTH','POWFDS','POERROR','POSBPR','CREATEPO')    
     or (wi.item_type like '%ERROR%' and wi.parent_item_type in ('POAPPRV','REQAPPRV','POXML','POWFRQAG','PORCPT','APVRMDER','PONPBLSH','POSPOACK','PONAUCT','PORPOCHA','PODSNOTF','POSREGV2','POREQCHA','POWFPOAG','POSCHORD','POSASNNB','PONAPPRV','POSCHPDT','POAUTH','POWFDS','POERROR','POSBPR','CREATEPO'))
   group by item_type);
 
if ((:po_cnt > 0) and (:chart_po > 0)) THEN 

	:run_po_qry := 'Y';
	
	select count(item_key) into :cpocnt
	from wf_items
	where item_type = 'POAPPRV'
	and end_date is not null;

	select count(item_key) into :opocnt
	from wf_items
	where item_type = 'POAPPRV'
	and end_date is null;

    dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><b>Purchasing is being used!</b><BR> ');
    dbms_output.put_line('There are ' || to_char(:po_cnt,'999,999,999,999') || ' Purchasing Approval (POAPPRV) workflow items found in WF_ITEMS.<BR>');
    dbms_output.put_line('Currently ' || (round(:opocnt/:po_cnt, 2)*100) || '% (' || to_char(:opocnt,'999,999,999,999') || ') of POAPPRVs are OPEN,');
    dbms_output.put_line(' while ' || (round(:cpocnt/:po_cnt, 2)*100) || '% (' || to_char(:cpocnt,'999,999,999,999') || ') are CLOSED, but still found in the runtime tables.<BR>');

    if (:apps_rel >= '12.0') then 
       dbms_output.put_line('<BR>The following collection of information is a sample of the more complete Purchasing Review that you can get from running the PO Approval analyzer');
       dbms_output.put_line('concurrent process or po_apprvl_analyzer.sql script.<br>');
       dbms_output.put_line('In order to install the PO Approval Analyzer, see <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1525670.1" target="_blank">Note 1525670.1</a>.</p>');
    else
	dbms_output.put_line('<br>');
    end if;

    dbms_output.put_line('</td></tr></tbody> ');
    dbms_output.put_line('</table><BR>');


	select nvl(max(rownum), 0) into :c1
	from wf_items wi
	where wi.item_type in ('POAPPRV');

	select nvl(max(rownum), 0) into :c2
	from wf_items wi
	where wi.item_type in ('REQAPPRV');
	
	select nvl(max(rownum), 0) into :c3
	from wf_items wi
	where wi.item_type in ('POXML');
	
	select nvl(max(rownum), 0) into :c4
	from wf_items wi
	where wi.item_type in ('POWFRQAG');
	
	select nvl(max(rownum), 0) into :c5
	from wf_items wi
	where wi.item_type in ('PORCPT');

	select nvl(max(rownum), 0) into :c6
	from wf_items wi
	where wi.item_type in ('APVRMDER');
	
	select nvl(max(rownum), 0) into :c7
	from wf_items wi
	where wi.item_type in ('PONPBLSH');

	select nvl(max(rownum), 0) into :c8
	from wf_items wi
	where wi.item_type in ('POSPOACK');
	
	select nvl(max(rownum), 0) into :c9
	from wf_items wi
	where wi.item_type in ('PONAUCT');
	
	select nvl(max(rownum), 0) into :c10
	from wf_items wi
	where wi.item_type in ('PORPOCHA');
	
	select nvl(max(rownum), 0) into :poerr_cnt
	from wf_items wi
	where wi.item_type in ('POERROR');

	select nvl(max(rownum), 0) into :c11
	from wf_items wi
	where wi.item_type in ('POSREGV2');
	
	select nvl(max(rownum), 0) into :c12
	from wf_items wi
	where wi.item_type in ('POREQCHA');
	
	select nvl(max(rownum), 0) into :c13
	from wf_items wi
	where wi.item_type in ('POWFPOAG');
	
	select nvl(max(rownum), 0) into :c14
	from wf_items wi
	where wi.item_type in ('POSCHORD');
	
	select nvl(max(rownum), 0) into :c15
	from wf_items wi
	where wi.item_type in ('POSASNNB');

	select nvl(max(rownum), 0) into :c16
	from wf_items wi
	where wi.item_type in ('PONAPPRV');
	
	select nvl(max(rownum), 0) into :c17
	from wf_items wi
	where wi.item_type in ('POSCHPDT');
	
	select nvl(max(rownum), 0) into :c18
	from wf_items wi
	where wi.item_type in ('POAUTH');
	
	select nvl(max(rownum), 0) into :c19
	from wf_items wi
	where wi.item_type in ('POWFDS');

	select nvl(max(rownum), 0) into :c20
	from wf_items wi
	where wi.item_type in ('PODSNOTF');
	
	select nvl(max(rownum), 0) into :c21
	from wf_items wi
	where wi.item_type in ('POSBPR');
	
	select nvl(max(rownum), 0) into :c22
	from wf_items wi
	where wi.item_type in ('CREATEPO');

	select nvl(max(rownum), 0) into :c23
	from wf_items wi
	where wi.item_type = 'WFERROR' and wi.parent_item_type in ('POAPPRV','REQAPPRV','POXML','POWFRQAG','PORCPT','APVRMDER','PONPBLSH','POSPOACK','PONAUCT','PORPOCHA','PODSNOTF','POSREGV2','POREQCHA','POWFPOAG','POSCHORD','POSASNNB','PONAPPRV','POSCHPDT','POAUTH','POWFDS','POERROR','POSBPR','CREATEPO');
	
 	select round(:c1/:chart_po,2)*100 into :r1 from dual;
 	select round(:c2/:chart_po,2)*100 into :r2 from dual;
 	select round(:c3/:chart_po,2)*100 into :r3 from dual;
 	select round(:c4/:chart_po,2)*100 into :r4 from dual;
 	select round(:c5/:chart_po,2)*100 into :r5 from dual;
 	select round(:c6/:chart_po,2)*100 into :r6 from dual;
 	select round(:c7/:chart_po,2)*100 into :r7 from dual;
 	select round(:c8/:chart_po,2)*100 into :r8 from dual;
 	select round(:c9/:chart_po,2)*100 into :r9 from dual;
 	select round(:c10/:chart_po,2)*100 into :r10 from dual;
 	select round(:poerr_cnt/:chart_po,2)*100 into :poerrate from dual;
 	select round(:c11/:chart_po,2)*100 into :r11 from dual;
 	select round(:c12/:chart_po,2)*100 into :r12 from dual;
 	select round(:c13/:chart_po,2)*100 into :r13 from dual;
 	select round(:c14/:chart_po,2)*100 into :r14 from dual;
 	select round(:c15/:chart_po,2)*100 into :r15 from dual;
 	select round(:c16/:chart_po,2)*100 into :r16 from dual;
 	select round(:c17/:chart_po,2)*100 into :r17 from dual;
 	select round(:c18/:chart_po,2)*100 into :r18 from dual;
 	select round(:c19/:chart_po,2)*100 into :r19 from dual; 	
 	select round(:c20/:chart_po,2)*100 into :r20 from dual;
 	select round(:c21/:chart_po,2)*100 into :r21 from dual;
 	select round(:c22/:chart_po,2)*100 into :r22 from dual;
 	select round(:c23/:chart_po,2)*100 into :r23 from dual;


dbms_output.put_line('<BR><B><U>Show the status of the Purchasing Workflows for this instance</B></U><BR><BR>');

	dbms_output.put('<blockquote><img src="https://chart.googleapis.com/chart?chs=600x300\&chco=006633');
	dbms_output.put('\&chd=t:'||:r1||','||:r2||','||:r3||','||:r4||','||:r5||','||:r6||','||:r7||','||:r8||','||:r9||','||:r10||','||:poerrate||','||:r11||','||:r12||','||:r13||'');
	dbms_output.put_line('\&cht=p3\&chtt=Oracle+Purchasing+Workflows');
	dbms_output.put_line('\&chl=POAPPRV|REQAPPRV|POXML|POWFRQAG|PORCPT|APVRMDER|PONPBLSH|POSPOACK|PONAUCT|PORPOCHA|PODSNOTF|POSREGV2|POREQCHA|POWFPOAG|POSCHORD|POSASNNB|PONAPPRV|POSCHPDT|POAUTH|POWFDS|POERROR|POSBPR|CREATEPO');
	dbms_output.put_line('\&chdl='||:c1||'|'||:c2||'|'||:c3||'|'||:c4||'|'||:c5||'|'||:c6||'|'||:c7||'|'||:c8||'|'||:c9||'|'||:c10||'|'||:poerr_cnt||'|'||:c11||'|'||:c12||'|'||:c13||'|'||:c14||'|'||:c15||'|'||:c16||'|'||:c17||'|'||:c18||'|'||:c19||'|'||:c20||'|'||:c21||'|'||:c22||'|'||:c23||'"><BR>');
	dbms_output.put_line('Item Types</blockquote>');

  	dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
  	dbms_output.put_line('<tbody><tr><td> ');
  	dbms_output.put_line('<p><B>Attention:<BR>');
  	dbms_output.put_line('There are '||to_char(:chart_po,'999,999,999,999')||' Purchasing Type Workflows found on this instance.</B><BR>');
  	dbms_output.put_line('</p></td></tr></tbody></table><BR>');


  elsif ((:po_cnt = 0) and (:chart_po = 0)) THEN 
    
    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><B>Attention:<br>');    
    dbms_output.put_line('<b>Oracle Purchasing is not being used!</b><BR> ');
    dbms_output.put_line('There are no Purchasing Approval (POAPPRV) workflow items found in WF_ITEMS, so we will skip this section..<BR>');
    dbms_output.put_line('The following Table Headers may still display, however the queries are not run for this section..<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

  else

    dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
    dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
    dbms_output.put_line('<p><B>Attention:<br>');    
    dbms_output.put_line('Oracle Purchasing does not appear to be used on this instance, so we will skip this section.</b><BR> ');
    dbms_output.put_line('There are only ' || to_char(:po_cnt,'999,999,999,999') || ' Purchasing Approval (POAPPRV) workflow items found in WF_ITEMS.<BR>');
    dbms_output.put_line('The following Table Headers may still display, however the queries are not run for this section..<BR>');
    dbms_output.put_line('</p></td></tr></tbody></table><BR>');

 end if;   
end;
/

prompt <a name="prc_pf"></a><B><font size="+1">Known 1-Off Patches on top of Procurement (prc_pf) Rollup Patches</font></B><BR>
prompt       <blockquote>

begin

CASE 
	when (:apps_rel is null) then 

	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> ');
	       dbms_output.put_line('<p><B>Warning:</B><BR>');
	       dbms_output.put_line('There is a problem reading the Oracle Apps version (' || :apps_rel || ') for this instance. ');
	       dbms_output.put_line('So unable to determine if any 1-Off Patches exist for Purchasing.<br> ');	       
       	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');  	       
	       dbms_output.put_line('<BR>');
	
	when :apps_rel = '11.5.8' then

	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> ');
	       dbms_output.put_line('<p><B>Attention:<BR>');
	       dbms_output.put_line('The Oracle Apps version is (' || :apps_rel || ') for this instance.</B><br> ');
	       dbms_output.put_line('There are no Development suggested 1-Off PO patches available on top of this version.<br><br>');
	       dbms_output.put_line('<B>Warning:<BR>');
	       dbms_output.put_line('Oracle Applications 11.5.8 is no longer supported.</B><br>');
	       dbms_output.put_line('The minimum baseline ATG patchset for Extended Support of Oracle E-Business Suite Release 11i is 11i.ATG_PF.H.delta.6 (Patch 5903765).<br><br>');
	       dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=883202.1"');
	       dbms_output.put_line('target="_blank">Note 883202.1</a> - ');
	       dbms_output.put_line('Patch Requirements for Extended Support of Oracle E-Business Suite Release 11.5.10<br>');
       	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');  	       	       
	       
	when :apps_rel = '11.5.9' then

	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> ');
	       dbms_output.put_line('<p><B>Attention:<BR>');
	       dbms_output.put_line('The Oracle Apps version is (' || :apps_rel || ') for this instance.</B><br> ');
	       dbms_output.put_line('There are no Development suggested 1-Off PO patches available on top of this version.<br><br>');
	       dbms_output.put_line('<B>Warning:<BR>');
	       dbms_output.put_line('Oracle Applications 11.5.9 is no longer supported.</B><br>');
	       dbms_output.put_line('The minimum baseline ATG patchset for Extended Support of Oracle E-Business Suite Release 11i is 11i.ATG_PF.H.delta.6 (Patch 5903765).<br><br>');
	       dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=883202.1"');
	       dbms_output.put_line('target="_blank">Note 883202.1</a> - ');
	       dbms_output.put_line('Patch Requirements for Extended Support of Oracle E-Business Suite Release 11.5.10<br><br>');	       
       	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

 	when (:apps_rel > '11.5.10' and :apps_rel < '12.0') then 
	
		select nvl(max(decode(bug_number,
		8791241, '11iPO_Ptch12',
		bug_number)),'PRE11iPO_Ptch12') RUP into :rup
		from AD_BUGS b 
		where b.BUG_NUMBER in ('8791241')
		order by LAST_UPDATE_DATE desc;


	       if (:rup = 'PRE11iPO_Ptch12') then 

		       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
		       dbms_output.put_line('<tbody><tr><td> ');
		       dbms_output.put_line('<p><B>Attention:<BR>');
		       dbms_output.put_line('This ('|| :apps_rel ||') instance does not have Oracle Procurement Family 11.5.10 Rollup Patch 12 (8791241) Applied.</B><br> ');
		       dbms_output.put_line('PO Development recommends applying Oracle Procurement Family 11.5.10 Rollup Patch 12 available for this version.<br>');
		       dbms_output.put_line('For the list of software updates for Oracle Procurement that are included in this Rollup, please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=976631.1"');
		       dbms_output.put_line('target="_blank">Note 976631.1</a> - ');	
		       dbms_output.put_line('Oracle Procurement Software Updates, Rollup Patch 12 for 11.5.10<br><br>');
		       dbms_output.put_line('<B>Note</B><BR>');
		       dbms_output.put_line('This recommended patch is applicable only for 3460000 - 11.5.10.2 (11.5.10 CU2).<br>');
       	       	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');
	       
                 elsif (:rup = '11iPO_Ptch12') then 

		       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		       dbms_output.put_line('<tbody><tr><td> ');
		       dbms_output.put_line('<p><B>Excellent !!<BR><br>');                 
		       dbms_output.put_line('This ('|| :apps_rel ||') instance has recommended Oracle Procurement Family 11.5.10 Rollup Patch 12 (8791241) Applied.</B><br> ');
		       dbms_output.put_line('This is the latest Rollup for PO that Development recommends available for this Apps version.<br><br>');	  	       		       
       	       	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');
		       
  		else
		       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		       dbms_output.put_line('<tbody><tr><td> ');
		       dbms_output.put_line('<p><B>Excellent !!<BR><br>'); 
		       dbms_output.put_line('There are no Development recommended 1-Off Purchasing patches available for this Apps version (' || :apps_rel || ').<br><br>');
       	       	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');
		       
	       end if;
	      

	when (:apps_rel > '12.0' and :apps_rel < '12.1') then
	
		       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
		       dbms_output.put_line('<tbody><tr><td> ');
		       dbms_output.put_line('<B>Excellent !!<BR>'); 
		       dbms_output.put_line('There are no Development recommended Purchasing Rollup patches available for this Apps version (' || :apps_rel || ').<br><br>');	
       	       	       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       		       
		       dbms_output.put_line('<BR>');
		       
	when :apps_rel = '12.1' then
	
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '12625661';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '15971932';
	                 
			       dbms_output.put_line('<p><b>Workflow Development recommends the following Patch be applied to your '|| :apps_rel ||' instance.</b><br>');
			       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
			       dbms_output.put_line('<td><b>Patch #</b></td>');
			       dbms_output.put_line('<td align="center"><b>Oracle Purchasing Recommended Patches</b></td>');
			       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		               dbms_output.put_line('<td align="center"><b>Status</b></td>');
			       dbms_output.put_line('</tr>');
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">12625661</div></td>');
			       dbms_output.put_line('<td>R12.PO.B - Contract Purchase Agreement (CPA) should be defaulted in Standard Purchase Order (SPO) while using advanced pricing and sourcing.</td>');
			       dbms_output.put_line('<td div align="center" bgcolor="#CC6666">Recommended</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
			       dbms_output.put_line('</tr>');     
			       dbms_output.put_line('<tr bordercolor="#000066">');
			       dbms_output.put_line('<td>');
			       dbms_output.put_line('<div align="center">15971932</div></td>');
			       dbms_output.put_line('<td>R12.PO.B - Purchase Order shipment was not allowed to be cancelled when quantity billed is equal to quantity received</td>');
			       dbms_output.put_line('<td div align="center">General</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       	       dbms_output.put_line('</tr></table><BR>'); 

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '13495209';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '11869611';
			   
		       dbms_output.put_line('<p><b>PO Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Abstract</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">13495209</div></td>');
		       dbms_output.put_line('<td>R12.BOM.C - NOT UPGRADING WRITE OFF DETAILS PROPERLY FROM 11I TO R12</td>');
		       dbms_output.put_line('<td div align="center">General</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');       
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">11869611</div></td>');
		       dbms_output.put_line('<td>R12.FND.B - iProcurement charge account gets an error on the company segment even if the company segment is a valid value (Superseded by 12678526)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>'); 		       
		       dbms_output.put_line('</table><BR>');
			dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<B>These 1-Off patches are suggested by PO Development to resolve known issues on top of '||:apps_rel||'.</B><br>');
			dbms_output.put_line('<p>Please review any suggested 1-Offs that are missing, and verify if they should be applied to your instance.<br>');
			dbms_output.put_line('<p>For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1468883.1"');
			dbms_output.put_line('target="_blank">Note 1468883.1</a> - 12.1.3: Procurement Family Update - Current Rollup Patch : 15843459:R12.PRC_PF.B<br><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');

	when :apps_rel = '12.1.1' then

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '11063775';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '12677981';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch4
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9146994';
			   
		       dbms_output.put_line('<p><b>PO Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Abstract</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>'); 
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">11063775</div></td>');
		       dbms_output.put_line('<td>R12.JL.B - AUTOCREATED PO FROM IP REQ - ERROR RELATED TO INVALID TRANSACTION_REASON</td>');
		       dbms_output.put_line('<td div align="center">General</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">12677981</div></td>');
		       dbms_output.put_line('<td>R12.ZX.B - INVOICE VALIDATION ERRORS WHEN IN A BATCH EXISTS TRANSACTIONS BELONGING TO DIFFERENT ORGS</td>');
		       dbms_output.put_line('<td div align="center">General</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       dbms_output.put_line('</tr>');             
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9146994</div></td>');
		       dbms_output.put_line('<td>R12.ITM.C - When attempting to search for items, inactive items appear and when they are added to the cart, error was thrown</td>');
		       dbms_output.put_line('<td div align="center">General</div></td><td align="center" bgcolor="#'||:ptch4||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('</table><BR>');

			dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<B>These 1-Off patches are suggested by PO Development to resolve known issues on top of '||:apps_rel||'.</B><br>');
			dbms_output.put_line('<p>Please review any suggested 1-Offs that are missing, and verify if they should be applied to your instance.<br>');
			dbms_output.put_line('<p>For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1468883.1"');
			dbms_output.put_line('target="_blank">Note 1468883.1</a> - 12.1.3: Procurement Family Update - Current Rollup Patch : 15843459:R12.PRC_PF.B<br><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');

	when :apps_rel = '12.1.2' then
	
			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9868639';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '12587813';			   
			   
		       dbms_output.put_line('<p><b>PO Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Abstract</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9868639</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.2:9757926:GETTING JAVA.NET.MALFORMEDURLEXCEPTION FOR AN ABSOLUTE URI WHILE SENDING OA FRAMEWORK BASED NOTIFICATION (Superseded by 17385991)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">12587813</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.2:11740770:10181321:KFF DATA IS NOT GETTING CLEARED WHILE CLICKING ON CLEAR BUTTON</td>');
		       dbms_output.put_line('<td div align="center">General</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>'); 		       
		       dbms_output.put_line('</table><BR>');

			dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<B>These 1-Off patches are suggested by PO Development to resolve known issues on top of '||:apps_rel||'.</B><br>');
			dbms_output.put_line('<p>Please review any suggested 1-Offs that are missing, and verify if they should be applied to your instance.<br>');
			dbms_output.put_line('<p>For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1468883.1"');
			dbms_output.put_line('target="_blank">Note 1468883.1</a> - 12.1.3: Procurement Family Update - Current Rollup Patch : 15843459:R12.PRC_PF.B<br><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');

	when :apps_rel = '12.1.3' then

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch1
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '9868639';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch2
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '12923944';

			 select decode(count(*), 0, 'CC6666">NOT APPLIED', 'D7E8B0">APPLIED') into :ptch3
			 FROM AD_BUGS b
			   WHERE b.BUG_NUMBER IN '12678526';

		   
		       dbms_output.put_line('<p><b>PO Development suggests the following 1-Off Patches on top of '|| :apps_rel ||'.</b><br>');
		       dbms_output.put_line('<table border="1"><tr bordercolor="#DEE6EF" bgcolor="#DEE6EF" >');
		       dbms_output.put_line('<td><b>Patch #</b></td>');
		       dbms_output.put_line('<td align="center"><b>Abstract</b></td>');
		       dbms_output.put_line('<td align="center"><b>Type</b></td>');
		       dbms_output.put_line('<td align="center"><b>Status</b></td>');
		       dbms_output.put_line('</tr>');
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">9868639</div></td>');
		       dbms_output.put_line('<td>1OFF:12.1.3:9757926:GETTING JAVA.NET.MALFORMEDURLEXCEPTION FOR AN ABSOLUTE URI WHILE SENDING OA FRAMEWORK BASED NOTIFICATION (Superseded by 17385991)</td>');
		       dbms_output.put_line('<td div align="center" bgcolor="#FFCC66">Superseded</div></td><td align="center" bgcolor="#'||:ptch1||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">12923944</div></td>');
		       dbms_output.put_line('<td>1OFF:12399649:12.1.3:12.1.3:11886062 BACKPORT: TST122: TRANSACTION MANAGERS NOT</td>');
		       dbms_output.put_line('<td div align="center">General</div></td><td align="center" bgcolor="#'||:ptch2||'</td>');
		       dbms_output.put_line('</tr>');     
		       dbms_output.put_line('<tr bordercolor="#000066">');
		       dbms_output.put_line('<td>');
		       dbms_output.put_line('<div align="center">12678526</div></td>');
		       dbms_output.put_line('<td>1-OFF:12533040:12.1.3:12.1.3:FND_DATE OUTPUT FORMAT MASK IS NOT CONSISTENT IN</td>');
		       dbms_output.put_line('<td div align="center">General</div></td><td align="center" bgcolor="#'||:ptch3||'</td>');
		       dbms_output.put_line('</tr>');               
		       dbms_output.put_line('</table><BR>');

			dbms_output.put_line('<table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">');
			dbms_output.put_line('<tbody><tr><td>');
			dbms_output.put_line('<B>These 1-Off patches are suggested by PO Development to resolve known issues on top of '||:apps_rel||'.</B><br>');
			dbms_output.put_line('<p>Please review any suggested 1-Offs that are missing, and verify if they should be applied to your instance.<br>');
			dbms_output.put_line('<p>For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1468883.1"');
			dbms_output.put_line('target="_blank">Note 1468883.1</a> - 12.1.3: Procurement Family Update - Current Rollup Patch : 15843459:R12.PRC_PF.B<br><br>');
			dbms_output.put_line('</td></tr></tbody></table><BR>');
		
	else 
      
       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td>');
       dbms_output.put_line('There are no 1-Off patches recommended by PO Development for this Oracle Applications '||:apps_rel||' instance.<br><br>');
       dbms_output.put_line('<p>For more information refer to <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1468883.1"');
       dbms_output.put_line('target="_blank">Note 1468883.1</a> - 12.1.3: Procurement Family Update - Current Rollup Patch : 15843459:R12.PRC_PF.B<br><br>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');

       dbms_output.put_line('<A href="#top"><font size="-1">Back to Top</font></A><BR><BR>');
       
end CASE;

      
dbms_output.put_line('<A href="#top"><font size="-1">Back to Top</font></A><BR><BR>');

end;
/
prompt </blockquote>


REM
REM ******* Top 30 Large Purchasing Item Activity Status History Items *******
REM

prompt <table border="1" name="Notebox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td><font size="+1"><B>Purchasing Workflow Looping Activities :</B></font><br>
prompt It is normal for PO Workflows to use WAITS and other looping acitivities to process delayed responses and other criteria.<BR>
prompt Each revisit of a node replaces the previous data with the current activities status and stores the old activity information into a activities history table.<BR>
prompt Looking at this history table (WF_ITEM_ACTIVITY_STATUSES_H) can help to identify possible long running workflows that appear to be stuck in a loop over a long time,<br>
prompt or a poorly designed workflow that is looping excessively and can cause performance issues.<BR>
prompt </p></td></tr></tbody></table><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows9sql5(){var row = document.getElementById("s9sql5");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=5 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Top 30 Large Item Activity Status History Purchasing Items</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows9sql5()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql5" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="6" height="125">
prompt       <blockquote><p align="left">
prompt          SELECT sta.item_type ITEM_TYPE, sta.item_key ITEM_KEY, COUNT(*) COUNT,<br>
prompt          TO_CHAR(wfi.begin_date, 'YYYY-MM-DD') OPENED, TO_CHAR(wfi.end_date, 'YYYY-MM-DD') CLOSED, wfi.user_key DESCRIPTION<br>
prompt          FROM wf_item_activity_statuses_h sta, <br>
prompt          wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key <br>
prompt          AND wfi.item_type in ('POAPPRV','REQAPPRV','POXML','POWFRQAG','PORCPT','APVRMDER','PONPBLSH','POSPOACK','PONAUCT','PORPOCHA','PODSNOTF','POSREGV2','POREQCHA','POWFPOAG','POSCHORD','POSASNNB','PONAPPRV','POSCHPDT','POAUTH','POWFDS','POERROR','POSBPR','CREATEPO')<br>
prompt          GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), <br>
prompt          TO_CHAR(wfi.end_date, 'YYYY-MM-DD') <br>
prompt          HAVING COUNT(*) > 300 <br>
prompt          ORDER BY COUNT(*) DESC;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">ITEM_KEY</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">COUNT</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">BEGIN_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">END_DATE</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri">DESCRIPTION</B></TD>
exec :n := dbms_utility.get_time;
SELECT * FROM (SELECT  
'<TR><TD>'||sta.item_type||'</TD>'||chr(10)|| 
'<TD>'||sta.item_key||'</TD>'||chr(10)|| 
'<TD>'||to_char(COUNT(*),'999,999,999,999')||'</TD>'||chr(10)|| 
'<TD>'||TO_CHAR(wfi.begin_date, 'YYYY-MM-DD')||'</TD>'||chr(10)|| 
'<TD>'||TO_CHAR(wfi.end_date, 'YYYY-MM-DD')||'</TD>'||chr(10)|| 
'<TD>'||wfi.user_key||'</TD></TR>'
FROM wf_item_activity_statuses_h sta, wf_items wfi 
WHERE sta.item_type = wfi.item_type 
AND sta.item_key  = wfi.item_key 
and :run_po_qry = 'Y' 
AND wfi.item_type in ('POAPPRV','REQAPPRV','POXML','POWFRQAG','PORCPT','APVRMDER','PONPBLSH','POSPOACK','PONAUCT','PORPOCHA','PODSNOTF','POSREGV2','POREQCHA','POWFPOAG','POSCHORD','POSASNNB','PONAPPRV','POSCHPDT','POAUTH','POWFDS','POERROR','POSBPR','CREATEPO') 
GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
HAVING COUNT(*) > 300 
ORDER BY COUNT(*) DESC) 
WHERE ROWNUM < 31;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');


prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

begin

:hasrows := 0;

SELECT count(*) into :hasrows FROM (SELECT sta.item_type 
FROM wf_item_activity_statuses_h sta, 
wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key 
AND wfi.item_type in ('POAPPRV','REQAPPRV','POXML','POWFRQAG','PORCPT','APVRMDER','PONPBLSH','POSPOACK','PONAUCT','PORPOCHA','PODSNOTF','POSREGV2','POREQCHA','POWFPOAG','POSCHORD','POSASNNB','PONAPPRV','POSCHPDT','POAUTH','POWFDS','POERROR','POSBPR','CREATEPO')
and :run_po_qry = 'Y' 
GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
HAVING COUNT(*) > 300 
ORDER BY COUNT(*) DESC);

if (:hasrows>0) then

	SELECT * into :hist_item FROM (SELECT sta.item_type 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type in ('POAPPRV','REQAPPRV','POXML','POWFRQAG','PORCPT','APVRMDER','PONPBLSH','POSPOACK','PONAUCT','PORPOCHA','PODSNOTF','POSREGV2','POREQCHA','POWFPOAG','POSCHORD','POSASNNB','PONAPPRV','POSCHPDT','POAUTH','POWFDS','POERROR','POSBPR','CREATEPO')  
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 300 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	select * into :hist_key from (SELECT sta.item_key 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type in ('POAPPRV','REQAPPRV','POXML','POWFRQAG','PORCPT','APVRMDER','PONPBLSH','POSPOACK','PONAUCT','PORPOCHA','PODSNOTF','POSREGV2','POREQCHA','POWFPOAG','POSCHORD','POSASNNB','PONAPPRV','POSCHPDT','POAUTH','POWFDS','POERROR','POSBPR','CREATEPO')  
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 300 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	SELECT * into :hist_end  
	FROM (SELECT end_date from wf_items where item_type = :hist_item and item_key = :hist_key);
	    	
	SELECT * into :hist_cnt FROM (SELECT count(sta.item_key) 
	FROM wf_item_activity_statuses_h sta, 
	wf_items wfi WHERE sta.item_type = wfi.item_type AND sta.item_key  = wfi.item_key AND wfi.item_type in ('POAPPRV','REQAPPRV','POXML','POWFRQAG','PORCPT','APVRMDER','PONPBLSH','POSPOACK','PONAUCT','PORPOCHA','PODSNOTF','POSREGV2','POREQCHA','POWFPOAG','POSCHORD','POSASNNB','PONAPPRV','POSCHPDT','POAUTH','POWFDS','POERROR','POSBPR','CREATEPO')  
	GROUP BY sta.item_type, sta.item_key, wfi.USER_KEY, TO_CHAR(wfi.begin_date, 'YYYY-MM-DD'), TO_CHAR(wfi.end_date, 'YYYY-MM-DD') 
	HAVING COUNT(*) > 300 
	ORDER BY COUNT(*) DESC)
	WHERE ROWNUM = 1;

	SELECT * into :hist_begin
	FROM (SELECT to_char(begin_date, 'Mon DD, YYYY') from  wf_items where item_type = :hist_item and item_key = :hist_key);

	select * into :hist_days
	from (select round(sysdate-begin_date,0) from wf_items where item_type = :hist_item and item_key = :hist_key);
	
	select * into :hist_recent 
	FROM (SELECT to_char(max(begin_date),'Mon DD, YYYY') from wf_item_activity_statuses_h
	where item_type = :hist_item and item_key = :hist_key);

	select sysdate into :sysdate from dual;

	    if ((:hist_end is null) and (:hist_days=0)) then 
		
		:hist_daily := :hist_cnt;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> ');
	       dbms_output.put_line('Currently, the largest single Purchasing Workflow activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This workflow process is still open, so this may be a problem. It was started on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>');       

	   elsif ((:hist_end is null) and (:hist_days > 0)) then 

		select ROUND((:hist_cnt/:hist_days),0) into :hist_daily from dual;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single Purchasing Workflow activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This workflow process is still open, so this may be a problem. It was started back on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>'); 

	   elsif ((:hist_end is not null) and (:hist_days = 0)) then 

		select ROUND((:hist_cnt/:hist_days),0) into :hist_daily from dual;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single Purchasing Workflow activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This process has been closed since ' || :hist_end || ', it was started on ' || :hist_begin || ', and has ');
	       dbms_output.put_line('most recently looped thru its process on ' || :hist_recent || '.<BR>');
	       
	   else 

		select ROUND((:hist_cnt/:hist_days),2) into :hist_daily from dual;
		
	       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
	       dbms_output.put_line('<tbody><tr><td> '); 
	       dbms_output.put_line('Currently, the largest single Purchasing Workflow activity found in the history table is for <br>item_type : ' || :hist_item || '<br>item_key : ' || :hist_key || '<BR><BR> ');
	       dbms_output.put_line('<B>Warning:</B><BR>');
	       dbms_output.put_line('This process has been closed since ' || :hist_end || '.<BR>');
	       
	    end if;       

	       dbms_output.put_line('So far this one activity for item_type ' || :hist_item || ' and item_key ' || :hist_key || ' has looped ' || to_char(:hist_cnt,'999,999,999,999') || ' times since it started in ' || :hist_begin || '.<BR>');
	       dbms_output.put_line('<B>Action:</B><BR>');
	       dbms_output.put_line('This is a good place to start, as this single Purchasing Workflow activity has been looping for ' || to_char(:hist_days,'999,999') || ' days, which is about ' || to_char(:hist_daily,'999,999.99') || ' times a day.<BR>');
	       dbms_output.put_line('Please review <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=144806.1" target="_blank">');
	       dbms_output.put_line('Note 144806.1</a> - A Detailed Approach To Purging Oracle Workflow Runtime Data on how to drill down and discover how to purge this workflow data.<br>');
	       dbms_output.put_line('</p></td></tr></tbody></table><BR>');


elsif ((:hasrows=0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="GoodJob" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Well Done !!</B><BR><BR>');
       dbms_output.put_line('There are NO ROWS found in the HISTORY table (wf_item_activity_statuses_h) for Purchasing that have over 300 rows associated to the same item_key.<BR>');
       dbms_output.put_line('This is a good result, which means there is no major looping issues at this time.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

elsif ((:hasrows=0) and (:run_po_qry = 'N')) then 

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><font face="Calibri"><tr><td> ');
       dbms_output.put_line('<p><B>Attention:<br>');    
       dbms_output.put_line('<b>Purchasing (PO) does not appear to be used on this instance, so we will skip this section.</b><BR> ');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

end if;
end;
/


prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>



prompt <B><U>Purchasing Workflows in Error</B></U><BR>
prompt <blockquote>

prompt Use bde_wf_err.sql script from <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=255045.1" target="_blank">Note 255045.1</a> to get details of any erroring activities.<BR>
prompt PO Exception management allows to retry failing PO activities. See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458216.1" target="_blank">Note 458216.1</a>.<BR>
prompt How To Retry Multiple Errored Approval Workflow Processes After A Fix Or Patch Has Been Implemented.<br>
prompt Also see <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=947141.1" target="_blank">Note 947141.1</a> - How to Mass Retry Errored Workflows?<br>
prompt <BR>

prompt <script type="text/javascript">    function displayRows9sql6(){var row = document.getElementById("s9sql6");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=4 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Purchasing Workflow Errors by Item Type, Result and Activities</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows9sql6()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql6" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="5" height="185">
prompt       <blockquote><p align="left">
prompt          select STA.ITEM_TYPE ITEM_TYPE,  STA.ACTIVITY_RESULT_CODE RESULT,<br>  
prompt          PRA.PROCESS_NAME ||':'|| PRA.INSTANCE_LABEL PROCESS_ACTIVITY_LABEL,  count(*) "TOTAL ROWS"<br>
prompt          from  WF_ITEM_ACTIVITY_STATUSES  STA, WF_PROCESS_ACTIVITIES PRA<br>
prompt          where STA.ACTIVITY_STATUS    = 'ERROR'<br>
prompt          and STA.PROCESS_ACTIVITY   = PRA.INSTANCE_ID<br>
prompt          and STA.ITEM_TYPE          in ('POAPPRV','REQAPPRV','POXML','POWFRQAG','PORCPT','APVRMDER','PONPBLSH','POSPOACK','PONAUCT','PORPOCHA','PODSNOTF','POSREGV2','POREQCHA','POWFPOAG','POSCHORD','POSASNNB','PONAPPRV','POSCHPDT','POAUTH','POWFDS','POERROR','POSBPR','CREATEPO')<br>
prompt          group by STA.ITEM_TYPE, STA.ACTIVITY_RESULT_CODE, PRA.PROCESS_NAME ||':'|| PRA.INSTANCE_LABEL<br>
prompt          order by STA.ITEM_TYPE, STA.ACTIVITY_RESULT_CODE, PRA.PROCESS_NAME ||':'|| PRA.INSTANCE_LABEL;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>RESULT</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PROCESS_LABEL</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVITY_LABEL</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>TOTAL ROWS</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||STA.ITEM_TYPE||'</TD>'||chr(10)|| 
'<TD>'||STA.ACTIVITY_RESULT_CODE||'</TD>'||chr(10)|| 
'<TD><div align="right">'||PRA.PROCESS_NAME||'</div></TD>'||chr(10)|| 
'<TD><div align="left">'||PRA.INSTANCE_LABEL||'</div></TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(*),'999,999,999,999')||'</div></TD></TR>'
 from  WF_ITEM_ACTIVITY_STATUSES  STA, WF_PROCESS_ACTIVITIES PRA
 where STA.ACTIVITY_STATUS = 'ERROR'
   and STA.PROCESS_ACTIVITY = PRA.INSTANCE_ID
   and STA.ITEM_TYPE in ('POAPPRV','REQAPPRV','POXML','POWFRQAG','PORCPT','APVRMDER','PONPBLSH','POSPOACK','PONAUCT','PORPOCHA','PODSNOTF','POSREGV2','POREQCHA','POWFPOAG','POSCHORD','POSASNNB','PONAPPRV','POSCHPDT','POAUTH','POWFDS','POERROR','POSBPR','CREATEPO')
   and :run_po_qry = 'Y'
 group by STA.ITEM_TYPE, STA.ACTIVITY_RESULT_CODE, PRA.PROCESS_NAME, PRA.INSTANCE_LABEL
 order by STA.ITEM_TYPE, to_char(count(*)) desc;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


prompt <B><U>Incomplete Activities for Purchasing Workflows</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows9sql7(){var row = document.getElementById("s9sql7");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Incomplete WF Activities for Child Processes of Approved POs</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows9sql7()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql7" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt          select i.parent_item_type, i.item_type, count(i.item_key)<br>
prompt            FROM wf_items i,<br>
prompt                 wf_item_activity_statuses ias<br>
prompt            WHERE i.parent_item_type = 'POAPPRV'<br>
prompt            AND   i.item_key = ias.item_key<br>
prompt            AND   i.item_type = ias.item_type<br>
prompt            AND   i.begin_date <= sysdate<br>
prompt            AND   ias.activity_status <> 'COMPLETE'<br>
prompt            AND   parent_item_key IN (<br>
prompt                    SELECT i1.item_key<br>
prompt                    FROM wf_items i1,<br>
prompt                         po_headers_all h<br>
prompt                    WHERE i1.item_key = h.wf_item_key<br>
prompt                    AND   i1.item_type = 'POAPPRV'<br>
prompt                    AND   h.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED')<br>
prompt                    UNION<br>
prompt                    SELECT i1.item_key<br>
prompt                    FROM wf_items i1,<br>
prompt                         po_releases_all r<br>
prompt                    WHERE i1.item_key = r.wf_item_key<br>
prompt                    AND   i1.item_type = 'POAPPRV'<br>
prompt                    AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED'))<br>
prompt            AND   ias.end_date is null<br>
prompt          group by i.parent_item_type, i.item_type;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PARENT_ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||i.parent_item_type||'</TD>'||chr(10)|| 
'<TD>'||i.item_type||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(i.item_key),'999,999,999,999')||'</div></TD></TR>'
  FROM wf_items i,
       wf_item_activity_statuses ias
  WHERE i.parent_item_type = 'POAPPRV'
  AND   i.item_key = ias.item_key
  AND   i.item_type = ias.item_type
  AND   i.begin_date <= sysdate
  AND  :run_po_qry = 'Y'
  AND   ias.activity_status <> 'COMPLETE'
  AND   parent_item_key IN (
          SELECT i1.item_key
          FROM wf_items i1,
               po_headers_all h
          WHERE i1.item_key = h.wf_item_key
          AND   i1.item_type = 'POAPPRV'
          AND   h.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED')
          UNION
          SELECT i1.item_key
          FROM wf_items i1,
               po_releases_all r
          WHERE i1.item_key = r.wf_item_key
          AND   i1.item_type = 'POAPPRV'
          AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED'))
  AND   ias.end_date is null
group by i.parent_item_type, i.item_type;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

:incomplpo := 0;

select count(rownum) into :incomplpo from (
select i.parent_item_type, 
       i.item_type,
       i.item_key
  FROM wf_items i,
       wf_item_activity_statuses ias
  WHERE i.parent_item_type = 'POAPPRV'
  AND   i.item_key = ias.item_key
  AND   i.item_type = ias.item_type
  AND   i.begin_date <= sysdate
  AND  :run_po_qry = 'Y'
  AND   ias.activity_status <> 'COMPLETE'
  AND   parent_item_key IN (
          SELECT i1.item_key
          FROM wf_items i1,
               po_headers_all h
          WHERE i1.item_key = h.wf_item_key
          AND   i1.item_type = 'POAPPRV'
          AND   h.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED')
          UNION
          SELECT i1.item_key
          FROM wf_items i1,
               po_releases_all r
          WHERE i1.item_key = r.wf_item_key
          AND   i1.item_type = 'POAPPRV'
          AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED'))
  AND   ias.end_date is null);

    if ((:incomplpo = 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Excellent !!<BR>'); 
       dbms_output.put_line('There are no Incomplete WF Activities for Child Processes of Approved POs.<BR>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       		       
      
      elsif ((:incomplpo > 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are Incomplete WF Activities for Child Processes of Approved POs<BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Please run the PO Purge Workflow Script purge_wf.sql to identify and abort Purchasing workflows not being processed by the "Purge Obsolete Workflow Runtime Data" concurrent program.<br>');
       dbms_output.put_line('Make running this script part of your Procurement Workflow best practices.<br><br>');
       dbms_output.put_line('See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458886.1#aref_section22" target="_blank">Note 458886.1</a> to download the script and for all the information you need.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    end if;  
end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

     
prompt <script type="text/javascript">    function displayRows9sql8(){var row = document.getElementById("s9sql8");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Incomplete Activities for Child Processes not associated to a PO</B></font></TD>
prompt     <TD bordercolor="#EE6EF">
prompt       <div align="right"><button onclick="displayRows9sql8()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql8" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt          select i.parent_item_type, i.item_type, count(i.item_key)<br>
prompt          FROM wf_items i,<br>
prompt                 wf_item_activity_statuses ias<br>
prompt            WHERE i.parent_item_type = 'POAPPRV'<br>
prompt            AND   i.item_key = ias.item_key<br>
prompt            AND   i.item_type = ias.item_type<br>
prompt            AND   i.begin_date <= sysdate<br>
prompt            AND   ias.activity_status <> 'COMPLETE'<br>
prompt            AND   NOT EXISTS (<br>
prompt                    SELECT 1 FROM po_headers_all h<br>
prompt                    WHERE h.wf_item_key = i.parent_item_key<br>
prompt                    UNION<br>
prompt                    SELECT 1 FROM po_releases_all r<br>
prompt                    WHERE r.wf_item_key = i.parent_item_key)<br>
prompt            AND   ias.end_date is null<br>
prompt            group by i.parent_item_type, i.item_type;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PARENT_ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||i.parent_item_type||'</TD>'||chr(10)|| 
'<TD>'||i.item_type||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(i.item_key),'999,999,999,999')||'</div></TD></TR>'
 FROM wf_items i, wf_item_activity_statuses ias
  WHERE i.parent_item_type = 'POAPPRV'
  AND   i.item_key = ias.item_key
  AND   i.item_type = ias.item_type
  AND   i.begin_date <= sysdate
  AND  :run_po_qry = 'Y'
  AND   ias.activity_status <> 'COMPLETE'
  AND   NOT EXISTS (
          SELECT 1 FROM po_headers_all h
          WHERE h.wf_item_key = i.parent_item_key
          UNION
          SELECT 1 FROM po_releases_all r
          WHERE r.wf_item_key = i.parent_item_key)
  AND   ias.end_date is null
  group by i.parent_item_type, i.item_type; 
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

:incomplpo := 0;

select count(rownum) into :incomplpo from (
select i.parent_item_type, 
       i.item_type,
       i.item_key
 FROM wf_items i, wf_item_activity_statuses ias
  WHERE i.parent_item_type = 'POAPPRV'
  AND   i.item_key = ias.item_key
  AND   i.item_type = ias.item_type
  AND   i.begin_date <= sysdate
  AND  :run_po_qry = 'Y'
  AND   ias.activity_status <> 'COMPLETE'
  AND   NOT EXISTS (
          SELECT 1 FROM po_headers_all h
          WHERE h.wf_item_key = i.parent_item_key
          UNION
          SELECT 1 FROM po_releases_all r
          WHERE r.wf_item_key = i.parent_item_key)
  AND   ias.end_date is null);

    if ((:incomplpo = 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Excellent !!<BR>'); 
       dbms_output.put_line('There are no Incomplete Activities for Child Processes not associated to a PO.<BR>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       		       
      
      elsif ((:incomplpo > 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are Incomplete Activities for Child Processes not associated to a PO<BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Please run the PO Purge Workflow Script purge_wf.sql to identify and abort Purchasing workflows not being processed by the "Purge Obsolete Workflow Runtime Data" concurrent program.<br>');
       dbms_output.put_line('Make running this script part of your Procurement Workflow best practices.<br><br>');
       dbms_output.put_line('See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458886.1#aref_section22" target="_blank">Note 458886.1');
       dbms_output.put_line('</a> to download the script and for all the information you need.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    end if;  
end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <script type="text/javascript">    function displayRows9sql9(){var row = document.getElementById("s9sql9");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Incomplete Activities for Workflows not associated to a PO</B></font></TD>
prompt     <TD bordercolor="#EE6EF">
prompt       <div align="right"><button onclick="displayRows9sql9()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql9" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt          SELECT DISTINCT
prompt                 to_char(ias.begin_date, 'YYYY'), ias.item_type, count(ias.item_key)<br>
prompt            FROM wf_item_activity_statuses ias,<br>
prompt                 wf_items i<br>
prompt            WHERE ias.item_type = 'POAPPRV'<br>
prompt            AND   ias.activity_status <> 'COMPLETE'<br>
prompt            AND   i.item_type = ias.item_type<br>
prompt            AND   i.item_key = ias.item_key<br>
prompt            AND   i.begin_date <= sysdate<br>
prompt            AND   i.end_date is null<br>
prompt            AND   NOT EXISTS (<br>
prompt                    SELECT 1 FROM po_headers_all h<br>
prompt                    WHERE  h.wf_item_key = ias.item_key<br>
prompt                    UNION<br>
prompt                    SELECT 1 from po_releases_all r<br>
prompt                    WHERE  r.wf_item_key = ias.item_key)<br>
prompt          group by ias.item_type, to_char(ias.begin_date, 'YYYY')</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BEGAN</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD> 
exec :n := dbms_utility.get_time;
SELECT DISTINCT
'<TR><TD>'||to_char(ias.begin_date,'YYYY')||'</TD>'||chr(10)|| 
'<TD>'||ias.item_type||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(ias.item_key),'999,999,999,999')||'</div></TD></TR>'
  FROM wf_item_activity_statuses ias,
       wf_items i
  WHERE ias.item_type = 'POAPPRV'
  AND   ias.activity_status <> 'COMPLETE'
  AND   i.item_type = ias.item_type
  AND   i.item_key = ias.item_key
  AND   i.begin_date <= sysdate
  AND  :run_po_qry = 'Y'
  AND   i.end_date is null
  AND   NOT EXISTS (
          SELECT 1 FROM po_headers_all h
          WHERE  h.wf_item_key = ias.item_key
          UNION
          SELECT 1 from po_releases_all r
          WHERE  r.wf_item_key = ias.item_key)
group by to_char(ias.begin_date,'YYYY'), ias.item_type;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

:incomplpo := 0;

select count(rownum) into :incomplpo from (
SELECT ias.item_type,
       ias.item_key
  FROM wf_item_activity_statuses ias,
       wf_items i
  WHERE ias.item_type = 'POAPPRV'
  AND   ias.activity_status <> 'COMPLETE'
  AND   i.item_type = ias.item_type
  AND   i.item_key = ias.item_key
  AND   i.begin_date <= sysdate
  AND  :run_po_qry = 'Y'
  AND   i.end_date is null
  AND   NOT EXISTS (
          SELECT 1 FROM po_headers_all h
          WHERE  h.wf_item_key = ias.item_key
          UNION
          SELECT 1 from po_releases_all r
          WHERE  r.wf_item_key = ias.item_key));

    if ((:incomplpo = 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Excellent !!<BR>'); 
       dbms_output.put_line('There are no Incomplete Activities for Workflows not associated to a PO.<BR>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       		       
      
      elsif ((:incomplpo > 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are Incomplete Activities for Workflows not associated to a PO<BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Please run the PO Purge Workflow Script purge_wf.sql to identify and abort Purchasing workflows not being processed by the "Purge Obsolete Workflow Runtime Data" concurrent program.<br>');
       dbms_output.put_line('Make running this script part of your Procurement Workflow best practices.<br><br>');
       dbms_output.put_line('See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458886.1#aref_section22" target="_blank">Note 458886.1');
       dbms_output.put_line('</a> to download the script and for all the information you need.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    end if;  
end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt <script type="text/javascript">    function displayRows9sql10(){var row = document.getElementById("s9sql10");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Incomplete Activities for Approved POs</B></font></TD>
prompt     <TD bordercolor="#EE6EF">
prompt       <div align="right"><button onclick="displayRows9sql10()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql10" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt          SELECT i.item_type, ias.activity_status, count(i.item_key)<br>
prompt            FROM wf_item_activity_statuses ias, wf_items i<br>
prompt            WHERE ias.item_type = 'POAPPRV'<br>
prompt            AND   ias.activity_status <> 'COMPLETE'<br>
prompt            AND   EXISTS (<br>
prompt                    SELECT 1 FROM po_headers_all h<br>
prompt                    WHERE h.wf_item_key = ias.item_key<br>
prompt                    AND   h.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED')<br>
prompt                    UNION<br>
prompt                    SELECT 1 FROM po_releases_all r<br>
prompt                    WHERE r.wf_item_key = ias.item_key<br>
prompt                    AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED'))<br>
prompt            AND   i.item_type = ias.item_type<br>
prompt            AND   i.item_key = ias.item_key<br>
prompt            AND   i.begin_date <= sysdate<br>
prompt            AND   i.end_date is null<br>
prompt            group by i.item_type, ias.activity_status; </p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVITY_STATUS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD> 
exec :n := dbms_utility.get_time;
SELECT 
'<TR><TD>'||i.item_type||'</TD>'||chr(10)|| 
'<TD>'||ias.activity_status||'</TD>'||chr(10)|| 
'<TD>'||count(i.item_key)||'</TD></TR>'
  FROM wf_item_activity_statuses ias,
       wf_items i
  WHERE ias.item_type = 'POAPPRV'
  AND   ias.activity_status <> 'COMPLETE'
  AND  :run_po_qry = 'Y'
  AND   EXISTS (
          SELECT 1 FROM po_headers_all h
          WHERE h.wf_item_key = ias.item_key
          AND   h.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED')
          UNION
          SELECT 1 FROM po_releases_all r
          WHERE r.wf_item_key = ias.item_key
          AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED'))
  AND   i.item_type = ias.item_type
  AND   i.item_key = ias.item_key
  AND   i.begin_date <= sysdate
  AND   i.end_date is null
  group by i.item_type, ias.activity_status;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

:incomplpo := 0;

select count(rownum) into :incomplpo from (
SELECT i.item_type, 
       ias.activity_status,
       i.item_key
  FROM wf_item_activity_statuses ias,
       wf_items i
  WHERE ias.item_type = 'POAPPRV'
  AND   ias.activity_status <> 'COMPLETE'
  AND  :run_po_qry = 'Y'
  AND   EXISTS (
          SELECT 1 FROM po_headers_all h
          WHERE h.wf_item_key = ias.item_key
          AND   h.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED')
          UNION
          SELECT 1 FROM po_releases_all r
          WHERE r.wf_item_key = ias.item_key
          AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED'))
  AND   i.item_type = ias.item_type
  AND   i.item_key = ias.item_key
  AND   i.begin_date <= sysdate
  AND   i.end_date is null);

    if ((:incomplpo = 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Excellent !!<BR>'); 
       dbms_output.put_line('There are no Incomplete Activities for Approved POs.<BR>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       		       
      
      elsif ((:incomplpo > 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are Incomplete Activities for Approved POs<BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Please run the PO Purge Workflow Script purge_wf.sql to identify and abort Purchasing workflows not being processed by the "Purge Obsolete Workflow Runtime Data" concurrent program.<br>');
       dbms_output.put_line('Make running this script part of your Procurement Workflow best practices.<br><br>');
       dbms_output.put_line('See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458886.1#aref_section22" target="_blank">Note 458886.1');
       dbms_output.put_line('</a> to download the script and for all the information you need.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    end if;  
end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <script type="text/javascript">    function displayRows9sql10a(){var row = document.getElementById("s9sql10a");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>PO Account Generator Workflows</B></font></TD>
prompt     <TD bordercolor="#EE6EF">
prompt       <div align="right"><button onclick="displayRows9sql10a()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql10a" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="185">
prompt       <blockquote><p align="left">
prompt           SELECT i.item_type, to_char(i.begin_date,'YYYY-MM') BEGAN, <br>
prompt           nvl(to_char(i.end_date, 'YYYY'),'OPEN') CLOSED, count(i.item_key) COUNT<br>
prompt             FROM wf_items i<br>
prompt            WHERE i.item_type = 'POWFPOAG'<br>
prompt            AND   i.end_date is null<br>
prompt            AND   i.begin_date <= sysdate<br>
prompt            AND   EXISTS (<br>
prompt                    SELECT null FROM wf_items i2<br>
prompt                    WHERE i2.end_date is null<br>
prompt                    START WITH i2.item_type = i.item_type<br>
prompt                    AND        i2.item_key = i.item_key<br>
prompt                    CONNECT BY PRIOR i2.item_type = i2.parent_item_type<br>
prompt                    AND        PRIOR i2.item_key = i2.parent_item_key<br>
prompt                    UNION ALL<br>
prompt                    SELECT null FROM wf_items i2<br>
prompt                    WHERE i2.end_date is null<br>
prompt                    START WITH i2.item_type = i.item_type<br>
prompt                    AND        i2.item_key = i.item_key<br>
prompt                    CONNECT BY PRIOR i2.parent_item_type = i2.item_type<br>
prompt                    AND        PRIOR i2.parent_item_key = i2.item_key)<br>
prompt            group by i.item_type, to_char(i.begin_date,'YYYY-MM'),nvl(to_char(i.end_date, 'YYYY'),'OPEN')<br>
prompt            ORDER BY to_char(i.begin_date,'YYYY-MM');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BEGAN</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CLOSED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD> 
exec :n := dbms_utility.get_time;
SELECT 
'<TR><TD>'||i.item_type||'</TD>'||chr(10)|| 
'<TD>'||to_char(i.begin_date,'YYYY-MM')||'</TD>'||chr(10)|| 
'<TD>'||nvl(to_char(i.end_date, 'YYYY'),'OPEN')||'</TD>'||chr(10)|| 
'<TD>'||count(i.item_key)||'</TD></TR>'
  FROM wf_items i
  WHERE i.item_type = 'POWFPOAG'
  AND   i.end_date is null
  AND  :run_po_qry = 'Y'  
  AND   i.begin_date <= sysdate
  AND   EXISTS (
          SELECT null FROM wf_items i2
          WHERE i2.end_date is null
          START WITH i2.item_type = i.item_type
          AND        i2.item_key = i.item_key
          CONNECT BY PRIOR i2.item_type = i2.parent_item_type
          AND        PRIOR i2.item_key = i2.parent_item_key
          UNION ALL
          SELECT null FROM wf_items i2
          WHERE i2.end_date is null
          START WITH i2.item_type = i.item_type
          AND        i2.item_key = i.item_key
          CONNECT BY PRIOR i2.parent_item_type = i2.item_type
          AND        PRIOR i2.parent_item_key = i2.item_key)
  group by i.item_type, to_char(i.begin_date,'YYYY-MM'),nvl(to_char(i.end_date, 'YYYY'),'OPEN')
  ORDER BY to_char(i.begin_date,'YYYY-MM');
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

:incomplpo := 0;

select count(rownum) into :incomplpo from (
SELECT i.item_type,
       to_char(i.begin_date,'YYYY-MM'),
       nvl(to_char(i.end_date, 'YYYY'),'OPEN'),
       i.item_key
  FROM wf_items i
  WHERE i.item_type = 'POWFPOAG'
  AND   i.end_date is null
  AND  :run_po_qry = 'Y'  
  AND   i.begin_date <= sysdate
  AND   EXISTS (
          SELECT null FROM wf_items i2
          WHERE i2.end_date is null
          START WITH i2.item_type = i.item_type
          AND        i2.item_key = i.item_key
          CONNECT BY PRIOR i2.item_type = i2.parent_item_type
          AND        PRIOR i2.item_key = i2.parent_item_key
          UNION ALL
          SELECT null FROM wf_items i2
          WHERE i2.end_date is null
          START WITH i2.item_type = i.item_type
          AND        i2.item_key = i.item_key
          CONNECT BY PRIOR i2.parent_item_type = i2.item_type
          AND        PRIOR i2.parent_item_key = i2.item_key));

    if ((:incomplpo = 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Excellent !!<BR>'); 
       dbms_output.put_line('There are no Incomplete WF Activities for PO Account Generator Workflows.<BR>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       		       
      
      elsif ((:incomplpo > 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are Incomplete WF Activities for PO Account Generator Workflows<BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Please run the PO Purge Workflow Script purge_wf.sql to identify and abort Purchasing workflows not being processed by the "Purge Obsolete Workflow Runtime Data" concurrent program.<br>');
       dbms_output.put_line('Make running this script part of your Procurement Workflow best practices.<br><br>');
       dbms_output.put_line('See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458886.1#aref_section22" target="_blank">Note 458886.1');
       dbms_output.put_line('</a> to download the script and for all the information you need.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    end if;  
end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>


prompt <B><U>Incomplete Activities for Requisition Workflows</B></U><BR>
prompt <blockquote>

prompt <script type="text/javascript">    function displayRows9sql11(){var row = document.getElementById("s9sql11");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Incomplete WF Activities for Child Processes of Approved Requisitions</B></font></TD>
prompt     <TD bordercolor="#EE6EF">
prompt       <div align="right"><button onclick="displayRows9sql11()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql11" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt            SELECT i.parent_item_type, i.item_type, count(i.item_key)<br>
prompt            FROM wf_items i,<br>
prompt                 wf_item_activity_statuses ias<br>
prompt            WHERE i.parent_item_type = 'REQAPPRV'<br>
prompt            AND   i.item_key = ias.item_key<br>
prompt            AND   i.item_type = ias.item_type<br>
prompt            AND   i.begin_date <= sysdate<br>
prompt            AND   ias.activity_status <> 'COMPLETE'<br>
prompt            AND   parent_item_key IN (<br>
prompt                    SELECT i1.item_key<br>
prompt                    FROM wf_items i1,<br>
prompt                         po_requisition_headers_all r<br>
prompt                    WHERE i1.item_key = r.wf_item_key(+)<br>
prompt            AND   i1.item_type = 'REQAPPRV'<br>
prompt            AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED'))<br>
prompt            AND   ias.end_date is null<br>
prompt            group by i.parent_item_type, i.item_type;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PARENT_ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||i.parent_item_type||'</TD>'||chr(10)|| 
'<TD>'||i.item_type||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(i.item_key),'999,999,999,999')||'</div></TD></TR>'
  FROM wf_items i,
       wf_item_activity_statuses ias
  WHERE i.parent_item_type = 'REQAPPRV'
  AND   i.item_key = ias.item_key
  AND   i.item_type = ias.item_type
  AND   i.begin_date <= sysdate
  AND  :run_po_qry = 'Y'
  AND   ias.activity_status <> 'COMPLETE'
  AND   parent_item_key IN (
          SELECT i1.item_key
          FROM wf_items i1,
               po_requisition_headers_all r
          WHERE i1.item_key = r.wf_item_key(+)
  AND   i1.item_type = 'REQAPPRV'
  AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED'))
  AND   ias.end_date is null
  group by i.parent_item_type, i.item_type;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

:incomplreq := 0;

select count(rownum) into :incomplreq from (
select i.parent_item_type,
       i.item_type,
       i.item_key
  FROM wf_items i,
       wf_item_activity_statuses ias
  WHERE i.parent_item_type = 'REQAPPRV'
  AND   i.item_key = ias.item_key
  AND   i.item_type = ias.item_type
  AND   i.begin_date <= sysdate
  AND  :run_po_qry = 'Y'
  AND   ias.activity_status <> 'COMPLETE'
  AND   parent_item_key IN (
          SELECT i1.item_key
          FROM wf_items i1,
               po_requisition_headers_all r
          WHERE i1.item_key = r.wf_item_key(+)
  AND   i1.item_type = 'REQAPPRV'
  AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED'))
  AND   ias.end_date is null);

    if ((:incomplreq = 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Excellent !!<BR>'); 
       dbms_output.put_line('There are no Incomplete WF Activities for Child Processes of Approved Requisitions.<BR>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       		       
      
      elsif ((:incomplreq > 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are Incomplete WF Activities for Child Processes of Approved Requisitions<BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Please run the PO Purge Workflow Script purge_wf.sql to identify and abort Purchasing workflows not being processed by the "Purge Obsolete Workflow Runtime Data" concurrent program.<br>');
       dbms_output.put_line('Make running this script part of your Procurement Workflow best practices.<br><br>');
       dbms_output.put_line('See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458886.1#aref_section22" target="_blank">Note 458886.1');
       dbms_output.put_line('</a> to download the script and for all the information you need.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    end if;  
end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <script type="text/javascript">    function displayRows9sql12(){var row = document.getElementById("s9sql12");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Incomplete Activities for Child Processes not associated to a Requisition</B></font></TD>
prompt     <TD bordercolor="#EE6EF">
prompt       <div align="right"><button onclick="displayRows9sql12()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql12" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt            SELECT --DISTINCT
prompt                   i.parent_item_type, i.item_type, count(i.item_key)<br>
prompt            FROM wf_items i,<br>
prompt                 wf_item_activity_statuses ias<br>
prompt            WHERE i.parent_item_type = 'REQAPPRV'<br>
prompt            AND   i.item_key = ias.item_key<br>
prompt            AND   i.item_type = ias.item_type<br>
prompt            AND   i.begin_date <= sysdate<br>
prompt            AND   ias.activity_status <> 'COMPLETE'<br>
prompt            AND   parent_item_key IN (<br>
prompt                    SELECT i1.item_key<br>
prompt                    FROM wf_items i1,<br>
prompt                         po_requisition_headers_all r<br>
prompt                    WHERE i1.item_key = r.wf_item_key(+)<br>
prompt                    AND   i1.item_type = 'REQAPPRV'<br>
prompt                    AND   r.wf_item_key is null<br>
prompt                    AND   r.wf_item_type is null)<br>
prompt            AND   ias.end_date is null<br>
prompt            group by i.parent_item_type, i.item_type;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>PARENT_ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD>
exec :n := dbms_utility.get_time;
select  
'<TR><TD>'||i.parent_item_type||'</TD>'||chr(10)|| 
'<TD>'||i.item_type||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(i.item_key),'999,999,999,999')||'</div></TD></TR>'
  FROM wf_items i,
       wf_item_activity_statuses ias
  WHERE i.parent_item_type = 'REQAPPRV'
  AND   i.item_key = ias.item_key
  AND   i.item_type = ias.item_type
  AND   i.begin_date <= sysdate
  AND  :run_po_qry = 'Y'
  AND   ias.activity_status <> 'COMPLETE'
  AND   parent_item_key IN (
          SELECT i1.item_key
          FROM wf_items i1,
               po_requisition_headers_all r
          WHERE i1.item_key = r.wf_item_key(+)
          AND   i1.item_type = 'REQAPPRV'
          AND   r.wf_item_key is null
          AND   r.wf_item_type is null)
  AND   ias.end_date is null
  group by i.parent_item_type, i.item_type;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

:incomplreq := 0;

select count(rownum) into :incomplreq from (
select i.parent_item_type,
       i.item_type,
       i.item_key
  FROM wf_items i,
       wf_item_activity_statuses ias
  WHERE i.parent_item_type = 'REQAPPRV'
  AND   i.item_key = ias.item_key
  AND   i.item_type = ias.item_type
  AND   i.begin_date <= sysdate
  AND  :run_po_qry = 'Y'
  AND   ias.activity_status <> 'COMPLETE'
  AND   parent_item_key IN (
          SELECT i1.item_key
          FROM wf_items i1,
               po_requisition_headers_all r
          WHERE i1.item_key = r.wf_item_key(+)
          AND   i1.item_type = 'REQAPPRV'
          AND   r.wf_item_key is null
          AND   r.wf_item_type is null)
  AND   ias.end_date is null);

    if ((:incomplreq = 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Excellent !!<BR>'); 
       dbms_output.put_line('There are no Incomplete Activities for Child Processes not associated to a Requisition.<BR>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       		       
     
      elsif ((:incomplreq > 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are Incomplete Activities for Child Processes not associated to a Requisition<BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Please run the PO Purge Workflow Script purge_wf.sql to identify and abort Purchasing workflows not being processed by the "Purge Obsolete Workflow Runtime Data" concurrent program.<br>');
       dbms_output.put_line('Make running this script part of your Procurement Workflow best practices.<br><br>');
       dbms_output.put_line('See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458886.1#aref_section22" target="_blank">Note 458886.1');
       dbms_output.put_line('</a> to download the script and for all the information you need.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    end if;  
end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>



prompt <script type="text/javascript">    function displayRows9sql13(){var row = document.getElementById("s9sql13");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=2 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Incomplete Activities for Workflows not associated to a Requistion</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows9sql13()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql13" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="3" height="185">
prompt       <blockquote><p align="left">
prompt            SELECT DISTINCT<br>
prompt                   to_char(ias.begin_date,'YYYY'), ias.item_type, count(ias.item_key)<br>
prompt            FROM wf_item_activity_statuses ias,<br>
prompt                 wf_items i,<br>
prompt                 po_requisition_headers_all r<br>
prompt            WHERE ias.item_key = r.wf_item_key(+)<br>
prompt            AND   ias.item_type = 'REQAPPRV'<br>
prompt            AND   ias.activity_status <> 'COMPLETE'<br>
prompt            AND   r.wf_item_key is null<br>
prompt            AND   r.wf_item_type is null<br>
prompt            AND   i.item_type = ias.item_type<br>
prompt            AND   i.item_key = ias.item_key<br>
prompt            AND   i.begin_date <= sysdate<br>
prompt            AND   i.end_date is null<br>
prompt            group by to_char(ias.begin_date,'YYYY'), ias.item_type;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BEGAN</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD> 
exec :n := dbms_utility.get_time;
SELECT DISTINCT
'<TR><TD>'||to_char(ias.begin_date,'YYYY')||'</TD>'||chr(10)|| 
'<TD>'||ias.item_type||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(ias.item_key),'999,999,999,999')||'</div></TD></TR>'
  FROM wf_item_activity_statuses ias,
       wf_items i,
       po_requisition_headers_all r
  WHERE ias.item_key = r.wf_item_key(+)
  AND   ias.item_type = 'REQAPPRV'
  AND   ias.activity_status <> 'COMPLETE'
  AND  :run_po_qry = 'Y'
  AND   r.wf_item_key is null
  AND   r.wf_item_type is null
  AND   i.item_type = ias.item_type
  AND   i.item_key = ias.item_key
  AND   i.begin_date <= sysdate
  AND   i.end_date is null
  group by to_char(ias.begin_date,'YYYY'), ias.item_type;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

:incomplreq := 0;

select count(rownum) into :incomplreq from (
SELECT ias.item_type,
       ias.item_key
  FROM wf_item_activity_statuses ias,
       wf_items i,
       po_requisition_headers_all r
  WHERE ias.item_key = r.wf_item_key(+)
  AND   ias.item_type = 'REQAPPRV'
  AND   ias.activity_status <> 'COMPLETE'
  AND  :run_po_qry = 'Y'
  AND   r.wf_item_key is null
  AND   r.wf_item_type is null
  AND   i.item_type = ias.item_type
  AND   i.item_key = ias.item_key
  AND   i.begin_date <= sysdate
  AND   i.end_date is null);

    if ((:incomplreq = 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Excellent !!<BR>'); 
       dbms_output.put_line('There are no Incomplete Activities for Workflows not associated to a Requistion.<BR>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       		       
  
      elsif ((:incomplreq > 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are Incomplete Activities for Workflows not associated to a Requistion<BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Please run the PO Purge Workflow Script purge_wf.sql to identify and abort Purchasing workflows not being processed by the "Purge Obsolete Workflow Runtime Data" concurrent program.<br>');
       dbms_output.put_line('Make running this script part of your Procurement Workflow best practices.<br><br>');
       dbms_output.put_line('See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458886.1#aref_section22" target="_blank">Note 458886.1');
       dbms_output.put_line('</a> to download the script and for all the information you need.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    end if;  
end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt <script type="text/javascript">    function displayRows9sql14(){var row = document.getElementById("s9sql14");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Incomplete Activities for Approved Requisitions</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows9sql14()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql14" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="185">
prompt       <blockquote><p align="left">
prompt              SELECT i.item_type, ias.activity_status, r.authorization_status, count(i.item_key)<br>
prompt              FROM wf_item_activity_statuses ias,<br>
prompt                   wf_items i,<br>
prompt                   po_requisition_headers_all r<br>
prompt              WHERE ias.item_key = r.wf_item_key<br>
prompt              AND   ias.item_type = 'REQAPPRV'<br>
prompt              AND   ias.activity_status <> 'COMPLETE'<br>
prompt              AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED')<br>
prompt              AND   i.item_type = ias.item_type<br>
prompt              AND   i.item_key = ias.item_key<br>
prompt              AND   i.begin_date <= sysdate<br>
prompt              AND   i.end_date is null<br>
prompt              group by i.item_type, ias.activity_status, r.authorization_status<br>
prompt              order by ias.activity_status;</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ACTIVITY_STATUS</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>AUTHORIZATION_STATUS</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD> 
exec :n := dbms_utility.get_time;
SELECT 
'<TR><TD>'||i.item_type||'</TD>'||chr(10)|| 
'<TD>'||ias.activity_status||'</TD>'||chr(10)|| 
'<TD>'||r.authorization_status||'</TD>'||chr(10)|| 
'<TD><div align="right">'||to_char(count(i.item_key),'999,999,999,999')||'</div></TD></TR>'
  FROM wf_item_activity_statuses ias,
       wf_items i,
       po_requisition_headers_all r
  WHERE ias.item_key = r.wf_item_key
  AND   ias.item_type = 'REQAPPRV'
  AND   ias.activity_status <> 'COMPLETE'
  AND  :run_po_qry = 'Y'
  AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED')
  AND   i.item_type = ias.item_type
  AND   i.item_key = ias.item_key
  AND   i.begin_date <= sysdate
  AND   i.end_date is null
  group by i.item_type, ias.activity_status, r.authorization_status
  order by ias.activity_status;
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');

begin

:incomplreq := 0;

select nvl(max(rownum),0) into :incomplreq from (
SELECT i.item_type,
       ias.activity_status,
       r.authorization_status,
       i.item_key
  FROM wf_item_activity_statuses ias,
       wf_items i,
       po_requisition_headers_all r
  WHERE ias.item_key = r.wf_item_key
  AND   ias.item_type = 'REQAPPRV'
  AND   ias.activity_status <> 'COMPLETE'
  AND  :run_po_qry = 'Y'
  AND   r.authorization_status NOT IN ('IN PROCESS','PRE-APPROVED')
  AND   i.item_type = ias.item_type
  AND   i.item_key = ias.item_key
  AND   i.begin_date <= sysdate
  AND   i.end_date is null);

    if ((:incomplreq = 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Excellent !!<BR>'); 
       dbms_output.put_line('There are no Incomplete Activities for Approved Requisitions.<BR>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       		       
 
      elsif ((:incomplreq > 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are Incomplete Activities for Approved Requisitions<BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Please run the PO Purge Workflow Script purge_wf.sql to identify and abort Purchasing workflows not being processed by the "Purge Obsolete Workflow Runtime Data" concurrent program.<br>');
       dbms_output.put_line('Make running this script part of your Procurement Workflow best practices.<br><br>');
       dbms_output.put_line('See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458886.1#aref_section22" target="_blank">Note 458886.1');
       dbms_output.put_line('</a> to download the script and for all the information you need.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    end if;  
end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>


prompt <script type="text/javascript">    function displayRows9sql15(){var row = document.getElementById("s9sql15");if (row.style.display == '')  row.style.display = 'none';	else row.style.display = '';    }</script>
prompt <TABLE border="1" cellspacing="0" cellpadding="2">
prompt <TR bgcolor="#DEE6EF" bordercolor="#DEE6EF">
prompt   <TD COLSPAN=3 bordercolor="#DEE6EF"><font face="Calibri">
prompt     <B>Requisition Account Generator Workflows</B></font></TD>
prompt     <TD bordercolor="#DEE6EF">
prompt       <div align="right"><button onclick="displayRows9sql15()" >SQL Script</button></div>
prompt   </TD>
prompt </TR>
prompt <TR id="s9sql15" style="display:none">
prompt    <TD BGCOLOR=#DEE6EF colspan="4" height="185">
prompt       <blockquote><p align="left">
prompt              SELECT i.item_type, to_char(i.begin_date,'YYYY-MM') BEGAN, <br>
prompt              nvl(to_char(i.end_date, 'YYYY'),'OPEN') CLOSED, count(i.item_key) COUNT<br>
prompt                FROM wf_items i<br>
prompt                WHERE i.item_type = 'POWFRQAG'<br>
prompt                AND   i.end_date is null<br>
prompt                AND   i.begin_date <= sysdate<br>
prompt                AND   (EXISTS (<br>
prompt                        SELECT null FROM wf_items i2<br>
prompt                        WHERE i2.end_date is null<br>
prompt                        START WITH i2.item_type = i.item_type<br>
prompt                        AND        i2.item_key = i.item_key<br>
prompt                        CONNECT BY PRIOR i2.item_type = i2.parent_item_type<br>
prompt                        AND        PRIOR i2.item_key = i2.parent_item_key<br>
prompt                        UNION ALL<br>
prompt                        SELECT null FROM wf_items i2<br>
prompt                        WHERE i2.end_date is null<br>
prompt                        START WITH i2.item_type = i.item_type<br>
prompt                        AND        i2.item_key = i.item_key<br>
prompt                        CONNECT BY PRIOR i2.parent_item_type = i2.item_type<br>
prompt                        AND        PRIOR i2.parent_item_key = i2.item_key))<br>
prompt                group by i.item_type, to_char(i.begin_date,'YYYY-MM'),nvl(to_char(i.end_date, 'YYYY'),'OPEN')<br>
prompt                order by to_char(i.begin_date,'YYYY-MM');</p>
prompt       </blockquote>
prompt     </TD>
prompt   </TR>
prompt <TR>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>ITEM_TYPE</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>BEGAN</B></TD> 
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>CLOSED</B></TD>
prompt <TD BGCOLOR=#DEE6EF><font face="Calibri"><B>COUNT</B></TD> 
exec :n := dbms_utility.get_time;
SELECT 
'<TR><TD>'||i.item_type||'</TD>'||chr(10)|| 
'<TD>'||to_char(i.begin_date,'YYYY-MM')||'</TD>'||chr(10)|| 
'<TD>'||nvl(to_char(i.end_date, 'YYYY'),'OPEN')||'</TD>'||chr(10)|| 
'<TD>'||count(i.item_key)||'</TD></TR>'
  FROM wf_items i
  WHERE i.item_type = 'POWFRQAG'
  AND   i.end_date is null
  AND  :run_po_qry = 'Y'    
  AND   i.begin_date <= sysdate
  AND   (EXISTS (
          SELECT null FROM wf_items i2
          WHERE i2.end_date is null
          START WITH i2.item_type = i.item_type
          AND        i2.item_key = i.item_key
          CONNECT BY PRIOR i2.item_type = i2.parent_item_type
          AND        PRIOR i2.item_key = i2.parent_item_key
          UNION ALL
          SELECT null FROM wf_items i2
          WHERE i2.end_date is null
          START WITH i2.item_type = i.item_type
          AND        i2.item_key = i.item_key
          CONNECT BY PRIOR i2.parent_item_type = i2.item_type
          AND        PRIOR i2.parent_item_key = i2.item_key))
  group by i.item_type, to_char(i.begin_date,'YYYY-MM'),nvl(to_char(i.end_date, 'YYYY'),'OPEN')
  order by to_char(i.begin_date,'YYYY-MM');
prompt </TABLE>
exec :n := (dbms_utility.get_time - :n)/100;
exec dbms_output.put_line('<font size="-1"><i> Elapsed time '||:n|| ' seconds</i></font><P><P>');


begin

:incomplreq := 0;

select nvl(max(rownum),0) into :incomplreq from (
SELECT i.item_type,
       to_char(i.begin_date,'YYYY-MM'),
       nvl(to_char(i.end_date, 'YYYY'),'OPEN'),
       i.item_key
  FROM wf_items i
  WHERE i.item_type = 'POWFRQAG'
  AND   i.end_date is null
  AND  :run_po_qry = 'Y'    
  AND   i.begin_date <= sysdate
  AND   (EXISTS (
          SELECT null FROM wf_items i2
          WHERE i2.end_date is null
          START WITH i2.item_type = i.item_type
          AND        i2.item_key = i.item_key
          CONNECT BY PRIOR i2.item_type = i2.parent_item_type
          AND        PRIOR i2.item_key = i2.parent_item_key
          UNION ALL
          SELECT null FROM wf_items i2
          WHERE i2.end_date is null
          START WITH i2.item_type = i.item_type
          AND        i2.item_key = i.item_key
          CONNECT BY PRIOR i2.parent_item_type = i2.item_type
          AND        PRIOR i2.parent_item_key = i2.item_key)));

    if ((:incomplreq = 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="GreenBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#D7E8B0" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<B>Excellent !!<BR>'); 
       dbms_output.put_line('There are no Incomplete Activities for Requisition Account Generator Workflows.<BR>');
       dbms_output.put_line('</td></tr></tbody></table><BR>');  	       		       
      
      elsif ((:incomplreq > 0) and (:run_po_qry = 'Y')) then

       dbms_output.put_line('<table border="1" name="OrangeBox" cellpadding="10" bordercolor="#FF9900" bgcolor="#FFCC66" cellspacing="0">');
       dbms_output.put_line('<tbody><tr><td> ');
       dbms_output.put_line('<p><B>Warning:</B><BR>');
       dbms_output.put_line('There are Incomplete Activities for Requisition Account Generator Workflows<BR>');
       dbms_output.put_line('<B>Action:</B><BR>');
       dbms_output.put_line('Please run the PO Purge Workflow Script purge_wf.sql to identify and abort Purchasing workflows not being processed by the "Purge Obsolete Workflow Runtime Data" concurrent program.<br>');
       dbms_output.put_line('Make running this script part of your Procurement Workflow best practices.<br><br>');
       dbms_output.put_line('See <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458886.1#aref_section22" target="_blank">Note 458886.1');
       dbms_output.put_line('</a> to download the script and for all the information you need.<BR>');
       dbms_output.put_line('</p></td></tr></tbody></table><BR>');

    end if;  
end;
/
prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>

prompt </blockquote>

REM
REM ******* INV - Inventory Workflow Specific Summary *******
REM


prompt <a name="wfprdinv"></a><B>INV - Inventory Workflow Specific Summary</B><BR><BR>

prompt <blockquote>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td>
prompt <i>Coming Soon...<br>
prompt Have any specific requests you would like to see in this Section, please use the <A href="#section9">Feedback</A> Section below.</i><br><br>
prompt Please review a new tool via <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1499475.1" target="_blank">Note 1499475.1</a> - Inventory Analyzer<br>
prompt A Health Check For Common Inventory Data Issues, Critical Patches, and Setups<br>
prompt </td></tr></tbody></table><BR><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt </blockquote>

REM
REM ******* PA - Payables Workflow Specific Summary *******
REM

prompt <a name="wfprdpa"></a><B>PA - Payables Workflow Specific Summary</B><BR><BR>

prompt <blockquote>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><tr><td>
prompt <i>Coming Soon...<br>
prompt Have any specific requests you would like to see in this Section, please use the <A href="#section9">Feedback</A> Section below.</i><br>
prompt </td></tr></tbody></table><BR><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>

prompt </blockquote>
prompt </blockquote>

REM **************************************************************************************** 
REM *******                   Section 8 : References                                 *******
REM ****************************************************************************************

prompt <a name="section8"></a><B><font size="+2">References</font></B><BR><BR>
prompt <blockquote>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><font size="-1" face="Calibri"><tr><td><p>   

prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1425053.1" target="_blank">
prompt Note 1425053.1 - How to run EBS Workflow Analyzer Tool as a Concurrent Request</a><br>
prompt <br>
prompt <a href="https://community.oracle.com/community/support/oracle_e-business_suite/core_workflow" target="_blank">
prompt My Oracle Support - Core Workflow Community</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1160285.1" target="_blank">
prompt Application Technology Group (ATG) Product Information Center (PIC) (Doc ID 1160285.1)</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1320509.1" target="_blank">
prompt E-Business Workflow Information Center (PIC) (Doc ID 1320509.1)</a><br>
prompt <br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1638535.1" target="_blank">
prompt Note 1638535.1 - Oracle 12.1.3+ E-Business Suite Recommended Patch Collection 1 [RPC1]</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=186361.1" target="_blank">
prompt Note 186361.1 - Workflow Background Process Performance Troubleshooting Guide</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=453137.1" target="_blank">
prompt Note 453137.1 - Oracle Workflow Best Practices Release 12 and Release 11i</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=225165.1" target="_blank">
prompt Note 225165.1 - Patching Best Practices and Reducing Downtime</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=957426.1" target="_blank">
prompt Note 957426.1 - Health Check Alert: Invalid objects exist for one or more of your EBS applications</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=104457.1" target="_blank">
prompt Note 104457.1 - Invalid Objects In Oracle Applications FAQs</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1191125.1" target="_blank">
prompt Note 1191125.1 - Troubleshooting Oracle Workflow Java Notification Mailer</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=748421.1" target="_blank">
prompt Note 748421.1 - Java Mailer Setup Diagnostic Test (ATGSuppJavaMailerSetup12.sh)</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=831982.1" target="_blank">
prompt Note 831982.1 - A guide For Troubleshooting Workflow Notification Emails - Inbound and Outbound</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1448095.1" target="_blank">
prompt Note 1448095.1 - How to handle or reassign System : Error (WFERROR) Notifications that default to SYSADMIN</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=562551.1" target="_blank">
prompt Note 562551.1 - Workflow Java Mailer FAQ</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=760386.1" target="_blank">
prompt Note 760386.1 - How to enable Bulk Notification Response Processing for Workflow in 11i and R12</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=559996.1" target="_blank">
prompt Note 559996.1 - What Tables Does the Workflow Purge Obsolete Data Program (FNDWFPR) Touch?</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=277124.1" target="_blank">
prompt Note 277124.1 - FAQ on Purging Oracle Workflow Data</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=132254.1" target="_blank">
prompt Note 132254.1 - Speeding Up And Purging Workflow</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1587923.1" target="_blank">
prompt Note 1587923.1 - How to Close and Purge excessive WFERROR workflows and DEFAULT_EVENT_ERROR notifications from Workflow.</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=144806.1" target="_blank">
prompt Note 144806.1 - A Detailed Approach To Purging Oracle Workflow Runtime Data</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1378954.1" target="_blank">
prompt Note 1378954.1 - bde_wf_process_tree.sql - For analyzing the Root Parent, Children, Grandchildren Associations of a Single Workflow Process</a><BR>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=375095.1" target="_blank">
prompt Note 375095.1 - How to Purge XDPWFSTD Messages</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=311552.1" target="_blank">
prompt Note 311552.1 - How to Optimize the Purge Process in a High Transaction Applications Environment</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=878032.1" target="_blank">
prompt Note 878032.1 - How To Use Concurrent Program :Purge Order Management Workflow</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=388672.1" target="_blank">
prompt Note 388672.1 - How to Reorganize Workflow Tables</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=733335.1" target="_blank">
prompt Note 733335.1 - How to Start Workflow Components</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=255045.1" target="_blank">
prompt Note 255045.1 - bde_wf_err.sql - Profile of Workflow Activities in Error</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=751026.1" target="_blank">
prompt Note 751026.1 - Purge Obsolete Workflow Runtime Data - OEOH / OEOL Performance issues</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=398822.1" target="_blank">
prompt Note 398822.1 - Order Management Suite - Some Data Fix Patches and Scripts</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=397548.1" target="_blank">
prompt Note 397548.1 - Patch 5885900 Data Fix Closes Eligible Order Headers and Purge Associated OMERROR and WFERROR and Orphan Line Workflows</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1358724.1" target="_blank">
prompt Note 1358724.1 - Information About Order Management Purge Programs</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=113492.1" target="_blank">
prompt Note 113492.1 - Oracle Order Management Suite White Papers</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=947141.1" target="_blank">
prompt Note 947141.1 - How to Mass Retry Errored Workflows</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=458216.1" target="_blank">
prompt Note 458216.1 - How To Retry Multiple Errored Approval Workflow Processes After A Fix Or Patch Has Been Implemented</a><br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1545562.1" target="_blank">
prompt Note 1545562.1 - Get Proactive with Oracle E-Business Suite - Product Support Analyzer Script Index</a><br>
prompt </p></font></td></tr></tbody>
prompt </table><BR><BR>

prompt <A href="#top"><font size="-1">Back to Top</font></A><BR><BR>
prompt </blockquote>

REM **************************************************************************************** 
REM *******                   Section 9 : Feedback                                   *******
REM ****************************************************************************************

prompt <a name="section9"></a><B><font size="+2">Feedback</font></B><BR><BR>
prompt <blockquote>

prompt <table border="1" name="NoteBox" cellpadding="10" bordercolor="#C1A90D" bgcolor="#FEFCEE" cellspacing="0">
prompt <tbody><font size="-1" face="Calibri"><tr><td><p>
prompt <B>Still have questions?</B><BR>
prompt Click <a href="https://community.oracle.com/message/11646974" target="_blank">here</a> to provide FEEDBACK 
prompt for the <font color="#FF0000"><b><font size="+1">Workflow Analyzer Tool</font></b></font>,  
prompt and offer suggestions, improvements, or ideas to make this proactive script more useful.<br>
prompt <font color="#FF0000"><b><font size="+1">- OR -</font></b></font><br>
prompt Click <a href="https://community.oracle.com/community/support/oracle_e-business_suite/core_workflow" target="_blank">here</a> 
prompt to access the <font color="#FF0000"><b><font size="+1">Oracle Core Workflow Community</font></b></font> on My Oracle Support and 
prompt search for solutions or post new questions about Workflow.<br>
prompt As always, you can email the author directly <A HREF="mailto:william.burbage@oracle.com?subject=%20Workflow%20Analyzer%20Feedback
prompt \&body=Please attach a copy of your WF Analyzer output">here</A>.<BR>
prompt Be sure to include the output of the script for review.<BR>
prompt </p></font></td></tr></tbody>
prompt </table><BR><BR>

prompt <BR><A href="#top"><font size="-1">Back to Top</font></A><BR>
prompt </blockquote>

prompt <table width="95%" border="0" name="TimeStamp" cellpadding="10" cellspacing="0">
prompt <tbody>
prompt     <tr>
prompt     <td><p> <br>
begin
select to_char(sysdate,'hh24:mi:ss') into :et_time from dual;

	dbms_output.put_line('<br>PL/SQL Script was started at:'||:st_time);
	dbms_output.put_line('<br>PL/SQL Script is complete at:'||:et_time);
end;
/

exec :n := dbms_utility.get_time;
exec :n := (dbms_utility.get_time - :g)/100;
exec dbms_output.put_line('<br><font size="-1"><i> Elapsed time '||trunc(:n)|| ' seconds</i></font><br><br><br>');
begin
if (:n > 3600) then
	dbms_output.put_line('Total time taken to complete the script: '||trunc(:n/3600)||' hours, '||trunc((:n-((trunc(:n/3600))*3600))/60)||' minutes, '||trunc(:n-((trunc(:n/60))*60))||' seconds</i></font><P><P>');
elsif (:n > 60) then
	dbms_output.put_line('Total time taken to complete the script: '||trunc(:n/60)||' minutes, '||trunc(:n-((trunc(:n/60))*60))||' seconds</i></font><P><P>');
elsif (:n < 60) then
	dbms_output.put_line('Total time taken to complete the script: '||trunc(:n)||' seconds</i></font><P>');
end if;
end;
/
prompt </td>
prompt <td><div align="right">Click
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=1545562.1" target="_blank">here</a> to see a full list of other useful Oracle EBS Proactive Support Analyzers and Tools.<br>
prompt <a href="https://support.oracle.com/epmos/faces/DocumentDisplay?parent=ANALYZER\&sourceId=1369938.1\&id=432.1" target="_blank">
prompt <img src="https://blogs.oracle.com/ebs/resource/Proactive/PSC_Logo.jpg" title="Click here a complete list of Oracle Proactive Services" alt="PSC_Logo" /></a>
prompt </div></td></tr>
prompt     </tbody></table><BR><BR>


spool off
set heading on
set feedback on  
set verify on
exit
;
