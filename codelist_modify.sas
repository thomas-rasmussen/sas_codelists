/*******************************************************************************
AUTHOR:     Thomas Bøjer Rasmussen
VERSION:    0.0.1
********************************************************************************
DESCRIPTION:
Modify codelist.

DETAILS:
Modies a codelist, intended to facilitate changing the format of a codelist
for different uses. Codes in code variables in the codelist is expected to
be unqouted and space-separated.

Accompanying examples and tests, version notes etc. can be found at:
https://github.com/thomas-rasmussen/sas_codelists
********************************************************************************
PARAMETERS:
*** REQUIRED ***
data:             (libname.)member-name of codelist.
out:              (libname.)member-name of output dataset with the modified
                  codelist.
*** OPTIONAL ***
code_var:         Space-separated list of variables in <data> that contains
                  codes. Defaults is
                    code_var = code_include code_exclude
code_type_var:    Variable in <data> that contains code type information.
                  Default is code_type_var = code_type.
set_code_delim:   Set delimiter used in code variables. Can take the value
                  "space" or "comma". Default is set_code_delim = "space".
add_periods:      Space-separated list of <code_type_var> values for which
                  periods are included in <code_var> variable codes. Placement
                  of periods are specified by adding a "/number" suffix to
                  each listed value, eg
                    add_periods = var1/2 var2/3
                  would add periods after the second character when
                  <code_var> = "var1" (and the code is longer than 2 characters)
                  and after the third character when <code_var = "var2"
                  (when the code is longer than 3 characters).
add_prefix:       Space-separated list of <code_type_var> values for which
                  a prefix is added to <code_var> variable codes. The prefix
                  to add is specified by adding a "/prefix" suffix to each
                  listed value, eg
                    add_prefix = var1/A var2/3
                  would add an "A" prefix to <code_var> variable codes when
                  <code_type_var> = "var1", and a "3" prefix to <code_var>
                  variable codes when <code_type_var> = "var2".
add_quotes:       Add quotes around code values in <code_var> variables?
                  - Yes: add_quotes = y (default)
                  - No:  add_quotes = n
clean_whitespace: Replace consecutive whitespace characters in <data>
                  variable values with a single space?
                  - Yes: clean_whitespace = y (default)
                  - No:  clean_whitespace = n
verbose:          Print info on what is happening during macro execution
                  to the log?
                  - Yes: verbose = y
                  - No:  verbose = n (default)
print_notes:      Print notes in log?
                  - Yes: print_notes = y
                  - No:  print_notes = n (default)
******************************************************************************/


%macro codelist_modify(
  data              = ,
  out               = ,
  code_var          = code_include code_exclude,
  code_type_var     = code_type,
  set_code_delim    = "space",
  add_periods       = _null_,
  add_prefix        = _null_,
  add_quotes        = n,
  clean_whitespace  = y,
  verbose           = n,
  print_notes       = n
) / minoperator mindelimiter = ' ';

/* Save value of notes option, then disable notes */
%local opt_notes;
%let opt_notes = %sysfunc(getoption(notes));
options nonotes;


/*******************************************************************************
INPUT PARAMETER CHECKS
*******************************************************************************/

/*** <verbose> ***/

/* Check valid value */
%if &verbose = %then %do;
  %put ERROR: Macro parameter <verbose> is not specified!;
  %goto end_of_macro;  
%end;
%else %if (&verbose in y n) = 0 %then %do;
  %put ERROR: <verbose> = &verbose is not a valid value!;
  %put ERROR: Valid values are:;
  %put ERROR: verbose = y;
  %put ERORR: verbose = n;
  %goto end_of_macro;  
%end;


/*** <print_notes> ***/

/* Check valid value */
%if &print_notes = %then %do;
  %put ERROR: Macro parameter <print_notes> is not specified!;
  %goto end_of_macro;
%end;
%else %if (&print_notes in n y) = 0 %then %do;
  %put ERROR: <print_notes> = &print_notes is not a valid value!;
  %put ERROR: Valid values are:;
  %put ERROR: print_notes = n;
  %put ERROR: print_notes = y;
  %goto end_of_macro;
%end;


/*** <data> ***/

/* Check that <data> is specified */
%if &data = %then %do;
  %put ERROR: Macro parameter <data> not specified!;
  %goto end_of_macro;
%end;

/* Check that <data> exists */
%if %sysfunc(exist(&data)) = 0 %then %do;
  %put ERROR: Specified <data> dataset "&data" does not exist;
  %goto end_of_macro;
%end;


/*** <out> ***/

/* Check that <out> is specified */
%if &out = %then %do;
  %put ERROR: Macro parameter <out> not specified!;
  %goto end_of_macro;
%end;

/* Check valid (libname.)member-name SAS dataset name */

/* Regular expression: (lib-name.)member-name, where the libname is
optional. The libname must start with a letter, followed by 0-7 letters, 
numbers or underscores and must end with a ".". Member-name part must start
with a letter or underscore, and is followed by 0-31 letters ,numbers or 
underscores. The whole regular expression is case-insensitive. */
%if %sysfunc(prxmatch('^([a-zA-Z][\w]{0,7}\.)*[a-zA-Z_][\w]{0,31}$', &out)) = 0 
  %then %do;
  %put ERROR: Specified <out> dataset name "&out" is invalid;
  %put ERROR: <out> must be a valid (libname.)member-name SAS dataset name.;
  %goto end_of_macro; 
%end;


/*** <code_var> ***/

/* Check that <code_var> is specified */
%if &code_var = %then %do;
  %put ERROR: Macro parameter <code_var> not specified!;
  %goto end_of_macro;
%end;

/* Check that <code_var> variables exists in <data> */
%local ds_id rc i i_var;
%do i = 1 %to %sysfunc(countw(&code_var, %str( )));
  %let i_var = %scan(&code_var, &i, %str( ));
  %let ds_id = %sysfunc(open(&data));
  %if %sysfunc(varnum(&ds_id, &i_var)) = 0 %then %do;
    %let rc = %sysfunc(close(&ds_id));
    %put ERROR: Variable "&i_var" specified in <code_var> does;
    %put ERROR: not exist in <data>!;
    %goto end_of_macro;
  %end;
  %let rc = %sysfunc(close(&ds_id));
%end;


/*** <code_type_var> ***/

/* Check that <code_type_var> is specified */
%if &code_type_var = %then %do;
  %put ERROR: Macro parameter <code_type_var> not specified!;
  %goto end_of_macro;
%end;

/*** Check that only one variable has been specified ***/
%if %sysfunc(countw(&code_type_var, %str( ))) > 1 %then %do;
  %put ERROR: More than one variable specified in <code_type_var> = &code_type_var;
  %goto end_of_macro;
%end;

/* Check that <code_type_var> variable exists in <data> */
%let ds_id = %sysfunc(open(&data));
%if %sysfunc(varnum(&ds_id, &code_type_var)) = 0 %then %do;
  %let rc = %sysfunc(close(&ds_id));
  %put ERROR: Variable "&code_type_var" specified in <code_type_var> does;
  %put ERROR: not exist in <data>!;
  %goto end_of_macro;
%end;
%let rc = %sysfunc(close(&ds_id));


/*** <set_code_delim> ***/

/* Check valid value */
%if &set_code_delim = %then %do;
  %put ERROR: Macro parameter <set_code_delim> is not specified!;
  %goto end_of_macro;
%end;
%else %if (&set_code_delim in "space" "comma") = 0 %then %do;
  %put ERROR: <set_code_delim> = &set_code_delim is not a valid value!;
  %put ERROR: Valid values are:;
  %put ERROR: set_code_delim = "space" (default);
  %put ERROR: set_code_delim = "comma";
  %goto end_of_macro;
%end;


/*** <add_periods> ***/

%local period_val period_loc i i_val i_loc i_tmp;
/* Check if valid value */
%if %bquote(&add_periods) = %then %do;
  %put ERROR: Macro parameter <add_periods> not specified!;
  %goto end_of_macro;
%end;
%else %if %bquote(&add_periods) = _null_ %then %do;
  %if &verbose = y %then %do;
    %put <add_periods> = _null_;
    %put Parsing not done; 
  %end;
%end;
%else %do;
  /* Parse values and period specifications from input */
  %do i = 1 %to %sysfunc(countw(%bquote(&add_periods), %str( )));
   %put test;
    %let i_tmp = %scan(%bquote(&add_periods), &i, %str( ));
    %let i_val = %scan(%bquote(&i_tmp), 1, /);
    %let i_loc = %scan(%bquote(&i_tmp), 2, /);

    %if %sysfunc(countw(%bquote(&i_tmp), /)) ne 2 %then %do;
      %put ERROR: <add_periods> = &add_periods;
      %put ERROR: contains "&i_tmp" which is not valid. See documentation.;
      %goto end_of_macro;
    %end;

    %let period_val = &period_val &i_val;
    %let period_loc = &period_loc &i_loc;
  %end;

  %if &verbose = y %then %do;
    %put Parsed <add_periods> input:;
    %put period_val: &period_val;
    %put period_loc: &period_loc;
  %end;
%end;


/*** <add_prefix> ***/

%local i_pf prefix_val prefix_pf;
/* Check if valid value */
%if %bquote(&add_prefix) = %then %do;
  %put ERROR: Macro parameter <add_prefix> not specified!;
  %goto end_of_macro;
%end;
%else %if %bquote(&add_prefix) = _null_ %then %do;
  %if &verbose = y %then %do;
    %put <add_prefix> = _null_;
    %put Parsing not done;
  %end;
%end;
%else %do;
  /* Parse values and prefixes from input */
  %do i = 1 %to %sysfunc(countw(%bquote(&add_prefix), %str( )));
    %let i_tmp = %scan(%bquote(&add_prefix), &i, %str( ));
    %let i_val = %scan(%bquote(&i_tmp), 1, /);
    %let i_pf = %scan(%bquote(&i_tmp), 2, /);

    %if %sysfunc(countw(%bquote(&i_tmp), /)) ne 2 %then %do;
      %put ERROR: <add_prefix> = &add_prefix;
      %put ERROR: contains "&i_tmp" which is not valid. See documentation.;
    %end;

    %let prefix_val = &prefix_val &i_val;
    %let prefix_pf = &prefix_pf &i_pf;
  %end;

  %if &verbose = y %then %do;
    %put Parsed <add_prefix> input:;
    %put prefix_val: &prefix_val;
    %put prefix_pf: &prefix_pf;
  %end;
%end;


/*** <add_quotes> ***/

/* Check valid value */
%if &add_quotes = %then %do;
  %put ERROR: Macro parameter <add_quotes> is not specified!;
  %goto end_of_macro;  
%end;
%else %if (&add_quotes in y n) = 0 %then %do;
  %put ERROR: <add_quotes> = &add_quotes is not a valid value!;
  %put ERROR: Valid values are:;
  %put ERROR: add_quotes = y;
  %put ERROR: add_quotes = n;
  %goto end_of_macro;  
%end;


/*** <clean_whitespace> ***/

/* Check valid value */
%if &clean_whitespace = %then %do;
  %put ERROR: Macro parameter <clean_whitespace> is not specified!;
  %goto end_of_macro;  
%end;
%else %if (&clean_whitespace in y n) = 0 %then %do;
  %put ERROR: <clean_whitespace> = &clean_whitespace is not a valid value!;
  %put ERROR: Valid values are:;
  %put ERROR: clean_whitespace = y;
  %put ERROR: clean_whitespace = n;
  %goto end_of_macro;  
%end;


/*******************************************************************************
MODIFY CODELIST
*******************************************************************************/


%if &print_notes = y %then %do;
  options notes;
%end;

/* Find all variables in <data> */
%local var_names i i_var ds_id rc j j_val j_loc j_pf;
%let var_names = ;
%let ds_id = %sysfunc(open(&data));
%do i = 1 %to %sysfunc(attrn(&ds_id, nvars));
  %let var_names = &var_names %sysfunc(lowcase(%sysfunc(varname(&ds_id, &i))));
%end;
%let rc = %sysfunc(close(&ds_id));

data &out;
  set &data;

  /* Clean whitespace in all variable values */
  %if &clean_whitespace = y %then %do;
    %do i = 1 %to %sysfunc(countw(&var_names, %str( )));
      %let i_var = %scan(&var_names, &i, %str( ));
      &i_var = prxchange("s/\s+/ /", -1, &i_var);
    %end;
  %end;

  /* Modify code variables */
  %do i = 1 %to %sysfunc(countw(&code_var, %str( )));
    %let i_var = %scan(&code_var, &i, %str( ));

    /* Add periods to codes */
    %if %bquote(&add_periods) ne _null_ %then %do;
      %do j = 1 %to %sysfunc(countw(&period_val, %str( )));
        %let j_val = %scan(&period_val, &j, %str( ));
        %let j_loc = %scan(&period_loc, &j, %str( ));
        if &code_type_var = "&j_val" then do;
          __cm_tmp = &i_var;
          &i_var = "";
          do __cm_i = 1 to countw(__cm_tmp, " ");
            __cm_i_var = scan(__cm_tmp, __cm_i, " ");
            if length(__cm_i_var) > &j_loc then do;
              __cm_i_var = compress(
                substr(__cm_i_var, 1, &j_loc)
                || "."
                || substr(__cm_i_var, &j_loc + 1, length(__cm_i_var) - &j_loc)
              );
            end;
            if __cm_i = 1 then &i_var = compress(__cm_i_var);
            else &i_var = left(trim(&i_var)) || " " || __cm_i_var;
          end;
        end;
        drop __cm_tmp __cm_i __cm_i_var;
      %end;
    %end;

    /* Add prefix */
    %if %bquote(&add_prefix) ne _null_ %then %do;
      %do j = 1 %to %sysfunc(countw(&prefix_val, %str( )));
        %let j_val = %scan(&prefix_val, &j, %str( ));
        %let j_pf = %scan(&prefix_pf, &j, %str( ));
        if &code_type_var = "&j_val" then do;
          &i_var = prxchange("s/([\w\.]+)/&j_pf.$1/", -1, &i_var);
        end;
      %end;
    %end;

    /* Quote codes */
    %if &add_quotes = y %then %do;
      &i_var = prxchange('s/([\w\.]+)/"$1"/', -1, &i_var);
    %end;

    /* Set specified delimiter */
    %if &set_code_delim = "comma" %then %do;
      if compress(&i_var) ne ""
        then &i_var = prxchange('s/\s/, /', -1, left(trim(&i_var)));
    %end;
 
  %end;
run;





%end_of_macro:

/* Restore value of options */
options &opt_notes;

%mend codelist_modify;

