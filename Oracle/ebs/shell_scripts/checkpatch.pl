#!/usr/bin/perl
################################################################################
# 
# This script can help you with patch research.
# Usage:
# perl checkpatch.pl -help
#
################################################################################

use IPC::Open2;
require 5.005;

# system info & variables
################################################################################
$DEBUG = 0;
$VERBOSE = 0;
$VERSION = 0.6;
$STATUS = 'Stable';
$LAST_MODIFIED = '20101208';
$OS = $^O;

# prototype section
################################################################################
sub print_usage ();
sub init_parameters ();
sub init_connection_str ($);    # connection_string
sub init_patch_list ($);        # patch_list_file
sub init_sqlplus_path ();
sub exec_query ($$$);           # sqlplus_executable_path, connection_string, query
sub check_connection ($$);      # sqlplus_executable_path, connection_string
sub check_env ($$);             # sqlplus_executable_path, connection_string
sub read_input ();
sub parse_patch_line ($);       # line_contains_patch_number
sub check_patch ($$$);          # sqlplus_executable_path, connection_string, patch_number
sub get_patches_summary ($$@);  # sqlplus_executable_path, connection_string, patch_list
sub get_instance_info ($$);     # sqlplus_executable_path, connection_string

# variable section
################################################################################
$APPLIED_SIGN = '[+] ';
$MISSED_SIGN = '[-] ';
$SAVE_SPACES = 1;
$DELIMITER = '#' x75;
$SQLPLUS_DIRECTIVES = 'SET ECHO OFF NEWPAGE 0 SPACE 0 PAGESIZE 0 FEEDBACK OFF HEADING OFF TRIMSPOOL ON TAB OFF';
$PATH_SUMMARY_APPLIED_SIGN = '+';
$PATH_SUMMARY_MISSED_SIGN = '-';
$PATH_SUMMARY_COLUMN_WIDTH = 9;

# init
################################################################################
print_usage and exit if ( $ARGV[0] =~ /-h|-help|--help|-version/);
my %parameters = init_parameters();
print "\nInitialization.\n$DELIMITER" if ($VERBOSE);


if ( $OS =~ m/win/i and $OS !~ m/darwin/i ) {
    print "\nWARNING: You mast use it with sqlplus version 9.2.x or greater !!!"
}

if ( defined $parameters{'sqlplus_executable'} ) {
    $sqlplus_path = $parameters{'sqlplus_executable'};     
} else {
    $sqlplus_path = init_sqlplus_path();
}

$connection_string = init_connection_str( $parameters{'connection_str'} );
@patch_list = init_patch_list( $parameters{'patch_list'} );

print "\nChecking environment." if ($VERBOSE);
check_env($sqlplus_path,$connection_string);


# main section
################################################################################
print "\n\t\$patch_list[0] = " . $patch_list[0] if ($DEBUG);
unless ( defined $patch_list[0] ) {
    print "\n\tInput patch sequence.\nTo interrupt input: press Ctrl+D or enter empty string.\n";
    while( my $line = read_input() ){
        print "\n\t" . '$line = ' . $line if ($DEBUG);
        last unless ($line);
        @patch_list = (@patch_list,$line) if ( $line !~ /^\s*$/ );
    }    
}
print "\n\t" . '@patch_list = ' . join '||', @patch_list if ($DEBUG);

my @result_list = ();
my @patch_list_parsed = ();
print  "\n\nProcessing input sequence.\n$DELIMITER" if ($VERBOSE);
foreach $line (@patch_list) {
    print "\n\t\$line = \@$line\@" if ($DEBUG);
    
    # parse spaces
    my $space = '';
    if ($SAVE_SPACES) {
        $space = $line;
        while( $space =~ /\S+\s*$/ ) {
           $space =~ s/\S+\s*$//;
            print "\n\t\$space = \@$space\@" if ($DEBUG);
        }
    };
    
    # parse line
    (my $patch_num, my $patch_desc) = parse_patch_line ($line);
    print "\n\t" . "\$patch_num  = $patch_num" if ($DEBUG);
    print "\n\t" . "\$patch_desc = $patch_desc" if ($DEBUG);
        
    # skip line if no patch number
    next unless ( $patch_num );

    # add parsed patch number to the patch_list_parsed
    @patch_list_parsed = (@patch_list_parsed, $patch_num);
    
    my $new_line = check_patch( $sqlplus_path, $connection_string, $patch_num );
    if ($new_line) {
        my $str = $new_line;
        $new_line = $space . $APPLIED_SIGN . $patch_num . $patch_desc;
        $new_line .= $str if ($VERBOSE);
    } else {
        $new_line = $space . $MISSED_SIGN . $patch_num . $patch_desc;
    }
    @result_list = (@result_list, $new_line) if ( $new_line !~ /^\s*$/ );
}

if ($VERBOSE) {
    print "\n\nPrinting Instance info:\n$DELIMITER\n";
    print get_instance_info($sqlplus_path,$connection_string);    
}

print "\nResult list:\n$DELIMITER\n" . join( "\n", @result_list) . "\n";

if ( defined $parameters{'patch_table'} ) {
    print "\n\nPrinting Patches summary table:\n$DELIMITER\n";
    print "(Please use it only on 11.5.10 and onward.";
    if ( defined $parameters{'fnd_nodes_only'} ) {
        print " Using nodes mentioned in FND_NODES view."
    }
    print ")\n";
    print get_patches_summary($sqlplus_path, $connection_string, @patch_list_parsed);
}


# functions definitions
#############################################################
sub print_usage () {
    print "
$DELIMITER
Program: checkpatch.pl
Version: $VERSION\.$LAST_MODIFIED $STATUS
Author:  A.Taraskov

Description:
    This script can help you with patch research.
    You can use it on your own risk!

Usage:
    perl checkpatch.pl option1=value1 option2=value2 ...

Options:
    patch_list | file | i           -> path to patch list
    connection_str | connect | c    -> connection string, like apps/apps\@VIS
    debug | d                       -> debug mode, default value is 0
    verbose | v                     -> verbose mode, default value is 1
    patch_table | t                 -> print patch table, default = 0
    patch_table_column_width | tcw  -> column width for appl_top name, default = 9
    patch_table_applied_sign        -> applied sign for patch table, default value is '+'
    patch_table_missed_sign         -> missed sign for patch table, default value is '-'
    fnd_nodes_only                  -> check patches for nodes appeared in fnd_nodes only
    applied_sign                    -> applied sign, default value is '[+] '
    missed_sign                     -> missed sign, default value is '[-] '
    save_spaces                     -> save space in result list, default value 1
    sqlplus_directives              -> sqlplus directives, like 'set head off'
    sqlplus_executable              -> sqlplus executable name, default - 'sqlplus'

 References:
    Perl -> http://perldoc.perl.org, http://perldoc.perl.org/IPC/Open2.html,
            http://yong321.freeshell.org/computer/OracleAndPerl.html
    Oracle -> Metalink Notes: 472820.1, 390864.1, 468521.1
$DELIMITER
";
}

sub init_parameters() {
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    print "\n\t" . 'scalar @ARGV = ' . scalar @ARGV if ($DEBUG);
    print "\n\t" . '@ARGV = ' . join('::', @ARGV) if ($DEBUG);
    
    my %hash = ();
    print "\n\t---------------------\n\toption = value\n\t---------------------" if ($DEBUG);
    foreach my $arg (@ARGV) {
        my ($option,$value) = ( $arg =~ s/(^.*?)=(.+$)//, $1, $2 )[1,2];
        $option = 'patch_list' if ( $option =~ m/^(patch_list|file|i)$/ );
        $option = 'connection_str' if ( $option =~ m/^(connection_str|connect|c)$/ );        
        $option = 'debug' if ( $option =~ m/^(debug|d)$/ );
        $option = 'verbose' if ( $option =~ m/^(verbose|v)$/ );
        $option = 'patch_table' if ( $option =~ m/^(patch_table|t)$/ );
        $option = 'patch_table_column_width' if ( $option =~ m/^(patch_table_column_width|tcw)$/ );
        print "\n\t" . $option . ' = ' . $value if ($DEBUG);
        $hash{ lc $option } = $value;
    }

    $DEBUG = $hash{'debug'} if ( defined $hash{'debug'} );
    $VERBOSE = $hash{'verbose'} if ( defined $hash{'verbose'} );
    $APPLIED_SIGN = $hash{'applied_sign'} if ( defined $hash{'applied_sign'} );
    $MISSED_SIGN = $hash{'missed_sign'} if ( defined $hash{'missed_sign'} );
    $SAVE_SPACES = $hash{'save_spaces'} if ( defined $hash{'save_spaces'} );
    $DELIMITER = $hash{'delimiter'} if ( defined $hash{'delimiter'} );
    $SQLPLUS_DIRECTIVES = $hash{'sqlplus_directives'} if ( defined $hash{'sqlplus_directives'} );
    $PATH_SUMMARY_COLUMN_WIDTH = $hash{'patch_table_column_width'} if ( defined $hash{'patch_table_column_width'} );
    $PATH_SUMMARY_APPLIED_SIGN = $hash{'patch_table_applied_sign'} if ( defined $hash{'patch_table_applied_sign'} );
    $PATH_SUMMARY_MISSED_SIGN = $hash{'patch_table_missed_sign'} if ( defined $hash{'patch_table_missed_sign'} );

    print "\nLeave init_parameters(@_):" if ($DEBUG);    
    return %hash;
}


sub init_connection_str ($) {
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    my ($connection_string) = ($_[0]);
    unless ( defined $connection_string ) {
        print "\n\tPlease enter connection string (apps/apps\@VIS):\n";
        my $line = '';
        if ( $line = read_input() and $line !~ /^\s*$/) {
            $connection_string = $line;
        } else {                        # use default value
            $connection_string = 'apps/apps';
        }
    }
    print "\n\t" . '$connection_string = ' . $connection_string if ($DEBUG);
    print "\nLeave ${my_name}(@_)" if ($DEBUG);
    return $connection_string;
}

sub init_patch_list ($) {
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    my ($file) = ($_[0]);        
    if (defined $file) {
        print "\nInit patch list." if ($VERBOSE);
        my @lines = ();
        print "\n\t\$file = $file" if ($DEBUG);
        if (-f $file ) {
            open( FN, "< $file") or print "\n\tERROR: Unable to open $file.\n";
            while ( defined(FN) and $line = <FN>) {
                print "\n\t" . '$line = ' . $line if ($DEBUG);
                chomp $line;            
                @lines = (@lines,$line) if ($line !~ /^\s*$/);
            }
            close FN or print "\n\tERROR: Unable to close $file.\n";
        }
        print "\n\t" . '@lines = ' . join('||', @lines) if ($DEBUG);
        print "\nLeave ${my_name}(@_)" if ($DEBUG);
        return @lines;
    }  else {
        print "\nLeave ${my_name}(@_)" if ($DEBUG);
        return undef;
    }
}

sub init_sqlplus_path () {   
    return 'sqlplus';
}

sub check_env ($$) {
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    my ($sqlplus_path,$connection_string) = ($_[0],$_[1]);        
    print "\nChekcing connection string." if ($VERBOSE);
    print "\n\t" . '$connection_string = ' . $connection_string if ($DEBUG);
    unless ( check_connection ($sqlplus_path, $connection_string) ) {
        die "\nE\tRROR: Can not connect using provided string.\nTry again.\n";
    }
    print "\nLeave ${my_name}(@_)" if ($DEBUG);
    die if ( !check_connection ($sqlplus_path, $connection_string) );
}

sub exec_query($$$) {
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    my ($path,$connection,$query) = ($_[0],$_[1],$_[2]);
    my $output = '';
    
    my $pid = open2(RH, WH, "$path -s $connection");
    print WH "$SQLPLUS_DIRECTIVES \n" . $query . "\n exit \n";
    close WH;       # close WH before read    
    # read output of sqlplus
    while (<RH>){
        $output .= $_ ;
    }    
    # close RH and wait for child process
    close RH;
    waitpid($pid, 0);
    
    print "\n\t\$output = $output" . 'EOF' if($DEBUG);
    print "\nLeave ${my_name}(@_)" if ($DEBUG);
    if($output =~ /ORA-\d{5,}:/) {
        die "\n\tERROR occurred:\n" . $output;
    }
    return $output;
}

sub check_connection ($$) {
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    my ($path,$connection) = ($_[0],$_[1]);

    my $query = "select 'Connection to ' || name || ' succeeded.'from v\$database;";
    my $output = exec_query($path,$connection,$query);

    print "\nLeave check_connection(@_)" if ($DEBUG);    
    return $output =~ /Connection/;
}

sub read_input() {
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    if ( my $input = <STDIN> ) {
        print "\n" . '@input = ' . "$input" if ($DEBUG);
        chomp $input;
        print "\nLeave read_input(@_)" if ($DEBUG);    
        return $input;
    } else {
        print "\n\tYou did not enter anything.\n";
    }
    print "\nLeave ${my_name}(@_)" if ($DEBUG);
    return undef;
}

sub parse_patch_line ($) {
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    my $patch_num = $_[0];
    my $patch_desc = $_[0];
    if ($patch_num =~ s/(^.*?)(\d{7,9})(.*$)/$2/) {
        print "\n" . '$patch_num = ' . $patch_num if ($DEBUG);        
        $patch_desc =~ s/(^.*?)(\d{7,9})(.*$)/$3/;
        print "\n" . '$patch_desc = ' . $patch_desc if ($DEBUG);
    } else {
        print "\nWARNING: Can't parse patch number in following string: $patch_num";
        return undef;
    }
    print "\n" . "Leave parse_patch_line(@_)" if ($DEBUG);
    return ($patch_num,$patch_desc);
}

sub check_patch ($$$) {
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    my ($path,$connection,$patch_num) = ($_[0],$_[1],$_[2]);
    print "\nProcessing patch: $patch_num" if ($VERBOSE);
    my $query = "
        (SELECT DISTINCT ' (patch '||e.patch_name||', applied at '||trim(c.end_date)||')'
        FROM 
        ad_bugs a, 
        ad_patch_run_bugs b, 
        ad_patch_runs c, 
        ad_patch_drivers d , 
        ad_applied_patches e 
        WHERE a.bug_id = b.bug_id AND 
        b.patch_run_id = c.patch_run_id AND 
        c.patch_driver_id = d.patch_driver_id AND 
        d.applied_patch_id = e.applied_patch_id AND 
        a.bug_number like " . $patch_num . " AND
        ROWNUM = 1)
        union
        (SELECT ' (bug '||bug_number||')' as info FROM ad_bugs where bug_number='" . $patch_num . "')
        ;";
    my $output = exec_query($path,$connection,$query);
    chomp $output;

    print "\n" . '$output = ' . $output if ($DEBUG);
    die "\nERROR occurred:\n" . $output if ($output =~ /ORA-\d{5,}:/);

    print "\nLeave ${my_name}(@_)" if ($DEBUG);
    return '' if ($output =~ 'no rows selected');
    return $output if ($output =~ /($patch_num|patch)/);    
}

sub get_patches_summary ($$@) {
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    my $output = "\n\nUsing ad_patch.is_patch_applied (patches + bugs)\n\n";
    $output .= get_patches_summary_1(@_);
    $output .= "\n\nUsing ad_patch_runs (patches ONLY)\n\n";
    $output .= get_patches_summary_2(@_);
    print "\nLeave ${my_name}(@_)" if ($DEBUG);
    return $output;    
}

sub get_patches_summary_1 ($$@) {  # sqlplus_executable_patch, connection_string, patch_list
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    my ($path,$connection,@patch_list) = @_;
    my $output;

    my $get_nodes_sql = "SELECT appl_top_id, name FROM ad_appl_tops where name NOT IN ('GLOBAL', '*PRESEEDED*') order by 1";
    if ( defined $parameters{'fnd_nodes_only'} ) {
        $get_nodes_sql = "SELECT appl_top_id, name name FROM ad_appl_tops
            where upper(name) in (select upper(node_name) from fnd_nodes) and name NOT IN ('GLOBAL', '*PRESEEDED*') order by 1";
    }
    my $query = "
        SET linesize 500;
        SET serveroutput ON size 1000000;
        DECLARE
            TYPE p_patch_array_type IS varray(" . scalar @patch_list . ") OF VARCHAR2(10);
            --
            p_patchlist p_patch_array_type;
            p_appltop_name varchar2(50);
            p_patch_status varchar2(15);
            p_appl_top_id  number;
            l_str varchar2(200);
            --
        BEGIN
           DBMS_OUTPUT.ENABLE(1000000);
           p_patchlist:= p_patch_array_type('" . join("','", @patch_list) . "');
           l_str := rpad('Patch N',8, ' ');
           for l_cur in (" . $get_nodes_sql . ")
           loop
               l_str := l_str||' '||rpad(l_cur.name," . $PATH_SUMMARY_COLUMN_WIDTH . ", ' ');
           end loop;
           dbms_output.put_line(l_str);
           for i IN 1..p_patchlist.count loop
               l_str := rpad(p_patchlist(i),8,' ');
               for l_cur in (" . $get_nodes_sql . ")
               loop
                    l_str := l_str||' '||rpad(case
                        when ad_patch.is_patch_applied('11i',l_cur.appl_top_id,p_patchlist(i))='EXPLICIT'
                        then '" . $PATH_SUMMARY_APPLIED_SIGN . "' 
                        else '" . $PATH_SUMMARY_MISSED_SIGN . "' end,
                        " . $PATH_SUMMARY_COLUMN_WIDTH . ", ' ');
               end loop;
               dbms_output.put_line(l_str);  
           end loop; 
         END;
/       ";
    
    $output = exec_query($path,$connection,$query);    
    if($output =~ /ORA-\d{5,}:/) {
        print "\nERROR occurred:\n" . $output;
    }
    print "\nLeave ${my_name}(@_)" if ($DEBUG);
    return $output;
}

sub get_patches_summary_2 ($$@) {
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    my ($path,$connection,@patch_list) = @_;
    my $output;

    my $get_nodes_sql = "SELECT appl_top_id, name FROM ad_appl_tops where name NOT IN ('GLOBAL', '*PRESEEDED*') order by 1";
    if ( defined $parameters{'fnd_nodes_only'} ) {
        $get_nodes_sql = "SELECT appl_top_id, name name FROM ad_appl_tops
            where upper(name) in (select upper(node_name) from fnd_nodes) and name NOT IN ('GLOBAL', '*PRESEEDED*') order by 1";
    }
    my $query = "  
        SET linesize 500;
        SET serveroutput ON size 1000000;
        DECLARE
            TYPE p_patch_array_type IS varray(" . scalar @patch_list . ") OF VARCHAR2(10);
            --
            p_patchlist p_patch_array_type;
            p_appltop_name varchar2(50);
            p_patch_status varchar2(15);
            p_appl_top_id  number;
            l_str varchar2(200);
            l_count varchar2(15);
            --
        BEGIN
           DBMS_OUTPUT.ENABLE(1000000);
           p_patchlist:= p_patch_array_type('" . join("','", @patch_list) . "');
           l_str := rpad('Patch N',8, ' ');
           for l_cur in (" . $get_nodes_sql . ")
           loop
               l_str := l_str||' '||rpad(l_cur.name," . $PATH_SUMMARY_COLUMN_WIDTH . ", ' ');
           end loop;
           dbms_output.put_line(l_str);
           
           for i IN 1..p_patchlist.count loop
               -- Printing PATCH info
               l_str := rpad(p_patchlist(i),8,' ');
               for l_cur in (" . $get_nodes_sql . ")
               loop
                    select  count(*)
                    into    l_count
                    from    ad_applied_patches aap,
                            ad_patch_drivers apd,
                            ad_patch_runs apr,
                            ad_appl_tops aat
                    where   aap.applied_patch_id = apd.applied_patch_id
                        and apd.patch_driver_id = apr.patch_driver_id
                        and aat.appl_top_id = apr.appl_top_id
                        and aap.patch_name = p_patchlist(i)
                        and aat.appl_top_id = l_cur.appl_top_id;
                    l_str := l_str||' '||rpad(case
                        when l_count = '0'
                        then '" . $PATH_SUMMARY_MISSED_SIGN . "' 
                        else '" . $PATH_SUMMARY_APPLIED_SIGN . "' end,
                        " . $PATH_SUMMARY_COLUMN_WIDTH . ", ' ');
               end loop;
               dbms_output.put_line(l_str); 
               
               -- Printing LANGUAGE info
               for l_cur_lang in (select LANGUAGE_CODE from fnd_languages where INSTALLED_FLAG<>'D')
               loop
                    l_str := rpad(l_cur_lang.language_code,8,' ');
                    for l_cur_node in (" . $get_nodes_sql . ")
                    loop
                        select  count (lang.language)
                        into    l_count
                        from    ad_patch_runs run          ,
                                ad_patch_driver_langs lang ,
                                ad_patch_drivers driver    ,
                                ad_applied_patches applied
                        where   run.patch_driver_id     = driver.patch_driver_id
                            and driver.applied_patch_id = applied.applied_patch_id
                            and lang.patch_driver_id    = driver.patch_driver_id
                            and applied.patch_name = p_patchlist(i)
                            and run.appl_top_id = l_cur_node.appl_top_id
                            and lang.language = l_cur_lang.language_code;
                        l_str := l_str||' '||rpad(case
                            when l_count = '0'
                            then '" . $PATH_SUMMARY_MISSED_SIGN . "' 
                            else '" . $PATH_SUMMARY_APPLIED_SIGN . "' end,
                            " . $PATH_SUMMARY_COLUMN_WIDTH . ", ' ');
                    end loop;
                    dbms_output.put_line(l_str);
               end loop;  
               
           end loop; 
           
        END;
/       ";

    $output = exec_query($path,$connection,$query);    
    if($output =~ /ORA-\d{5,}:/) {
        print "\nERROR occurred:\n" . $output;
    }
    print "\nLeave ${my_name}(@_)" if ($DEBUG);
    return $output;
}

sub get_instance_info($$) {  # sqlplus_executable_patch, connection_string
    my $my_name = ( caller (0) )[3];
    print "\nEnter ${my_name}(@_)" if ($DEBUG);
    my ($path,$connection,$patch_num) = ($_[0],$_[1],$_[2]);
    my $output;
    my $query = "
        set linesize 500
        select 'Instance name: ' || INSTANCE_NAME || ' (status = ' || STATUS || ')'from v\$instance;
        select 'Database release: ' || BANNER from v\$version where rownum = 1;
        select 'Applications release: ' || RELEASE_NAME from fnd_product_groups;
        select 'Number of invalids: ' || count(*) from dba_objects where status <> 'VALID';
        ";
    $output = exec_query($path,$connection,$query);
    
    $query ="
        prompt
        prompt Node configuration:
        select '   ' || NODE_NAME || ' -> ' || decode(SUPPORT_CP,'Y','CP ') || decode(SUPPORT_FORMS,'Y','Forms ') ||
            decode(SUPPORT_WEB,'Y','Web ') || decode(SUPPORT_ADMIN,'Y','Admin ')
        ";
    $query .= "|| decode(SUPPORT_DB,'Y','DB ') " if ( $output =~ /Applications release:.*11\.5\.10/);
    $query .= "from fnd_nodes where node_name <> 'AUTHENTICATION';";
    $output .= exec_query($path,$connection,$query);    
        
    $query ="
        prompt
        prompt Appl top configuration:
        SELECT '   ' || b.node_name || ' -> ' || a.name || ':' || a.path  
        FROM APPLSYS.FND_APPL_TOPS a,apps.fnd_nodes b WHERE a.NODE_ID=b.NODE_ID;
        prompt
        prompt Languages:
        select '   ' || NLS_LANGUAGE || '(' || LANGUAGE_CODE || ')' from fnd_languages where INSTALLED_FLAG<>'D';
        ";
    $output .= exec_query($path,$connection,$query);    
    
    $output = "Operating system = " . $OS . "\n" . $output;
    print "\n" . '$output: ' . $output if ($DEBUG);
    if($output =~ /ORA-\d{5,}:/) {
        print "\nERROR occurred:\n" . $output;
    }
    print "\nLeave ${my_name}(@_)" if ($DEBUG);
    return $output;        
}