/*******************************************************************************
AUTHOR:     Thomas Bøjer Rasmussen
VERSION:    0.0.1
********************************************************************************
DESCRIPTION:
Extract information from codelist

DETAILS:
Utility macro to extract definitions from codelist and save information
in macro variables.

Accompanying examples and tests, version notes etc. can be found at:
https://github.com/thomas-rasmussen/sas_codelists
********************************************************************************
PARAMETERS:
*** REQUIRED ***
data:         (libname.)member-name of codelist to extract definition from.
*** OPTIONAL ***
where:        Expression used in WHERE statement to restrict <data> before
              extracting information. Wrap in expression using a masking
              function, eg where = %str(var = "val").
extract_vars: Space-separated list of variable from <data> to extract.
delim:        Delimiter used to separate variable values in created
              macro variables.
empty_val:    Value used to replace empty values in extracted variables.
print_mv:     Print macro variables that are created in the log?
              - Yes: print_mv = y (default)
              - No:  print_mv = n
******************************************************************************/
%macro codelist_extract(
  data          = ,
  where         = %str(),
  extract_vars  = var_name var_label var_type var_level
                  t0_var time_start time_end
                  code_type code_include code_exclude,
  delim         = #,
  empty_val     = _null_,
  print_mv      = y
) / minoperator mindelimiter = ' ';

%local opt_notes;
%let opt_notes = %sysfunc(getoption(notes));
option nonotes;

%global n_lines &extract_vars;


/*******************************************************************************
INPUT PARAMETER CHECKS 
*******************************************************************************/

/*** <data> ***/

/* Check parameter specified */
%if &data = %then %do;
  %put ERROR: <data> not specified!;
  %goto end_of_macro;
%end;

/* Check dataset exists. */
%if %sysfunc(exist(&data)) = 0 %then %do;
  %put ERROR: Specified <data> dataset "&data" does not exist!;
  %goto end_of_macro;
%end;


/*** <extract_vars> ***/

/* Check parameter specified */
%if &extract_vars = %then %do;
  %put ERROR: <extract_vars> not specified!;
  %goto end_of_macro;
%end;

/* Check specifed variables exists in <data> */
%local ds_id rc i i_var;
%let ds_id = %sysfunc(open(&data));
%do i = 1 %to %sysfunc(countw(&extract_vars, %str( )));
  %let i_var = %scan(&extract_vars, &i, %str( ));
  %if %sysfunc(varnum(&ds_id, &i_var)) = 0 %then %do;
    rc = %sysfunc(close(&ds_id));
    %put ERROR: Variable "&i_var" specified in <extract_vars> does;
    %put ERROR: not exist in <data>!;
    %goto end_of_macro;
  %end;
%end;
%let rc = %sysfunc(close(&ds_id));


/*** <print_mv> ***/

/* Check valid value */
%if &print_mv = %then %do;
  %put ERROR: Macro parameter <print_mv> is not specified!;
  %goto end_of_macro;
%end;
%else %if (&print_mv in y n) = 0 %then %do;
  %put ERROR: <print_mv> does not have a valid value!;
  %put ERROR: Valid values are:;
  %put ERROR: print_mv = y (Yes);
  %put ERROR: print_mv = n (No);
  %goto end_of_macro;  
%end;


/*******************************************************************************
EXTRACT
*******************************************************************************/

%local i i_var;
data __ce_dat01;
  set &data;
  where &where;
  /* Replace any empty values in extracted variables */
  %do i = 1 %to %sysfunc(countw(&extract_vars, %str( )));
    %let i_var = %scan(&extract_vars, &i, %str( ));
    if &i_var = "" then &i_var = "&empty_val";
  %end;
run;

/* If loading the data results in any warning or error, terminate macro */
%if &syserr ne 0 %then %do;
  %put ERROR: An error or warning was thrown when <data> was loaded!;
  %put ERROR: Is the specified <where> condition valid?;
  %goto end_of_macro; 
%end;

proc sql noprint;
  select
    count(*)
    %do i = 1 %to %sysfunc(countw(&extract_vars, %str( )));
      %let i_var = %scan(&extract_vars, &i, %str( ));
      ,trim(left(&i_var))
    %end;
  into
    :n_lines
    %do i = 1 %to %sysfunc(countw(&extract_vars, %str( )));
      %let i_var = %scan(&extract_vars, &i, %str( ));
      ,:&i_var separated by "&delim"
    %end;
  from __ce_dat01;
quit;

%let n_lines = %sysfunc(left(&n_lines));

%if &print_mv = y %then %do;
  %put global macro variables made:;
  %put n_lines: &n_lines;
  %do i = 1 %to %sysfunc(countw(&extract_vars, %str( )));
    %let i_var = %scan(&extract_vars, &i, %str( ));
    %put &i_var: &&&i_var;
  %end;
%end;

%end_of_macro:

proc datasets nolist nodetails;
  delete __ce_dat01;
run;
quit;

options &opt_notes;

%mend codelist_extract;
