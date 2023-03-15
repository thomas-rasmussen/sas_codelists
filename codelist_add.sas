/*******************************************************************************
AUTHOR:     Thomas Bøjer Rasmussen
VERSION:    0.0.1
********************************************************************************
DESCRIPTION:
Add definition to codelist

DETAILS:
Adds a (component of) a definition to a codelist. If the specified
codelist does not exist, it will be created.

Often a series of related definitions share many elements. To help
reduce the amount of typing, the macro will by default reuse unspecified
elements. This behavior can be controlled with the <reuse_vars> parameter.

The macro is intended to be used together with the codelist_modify macro.
For this to work, codes in code variables needs to be unqouted and
space-separated.

Accompanying examples and tests, version notes etc. can be found at:
https://github.com/thomas-rasmussen/sas_codelists
********************************************************************************
PARAMETERS:
*** OPTIONAL ***
data:         (libname.)member-name of codelist. The following process
              happens when the macro is called:
              1) The macro checks if the global macro parameter
              __codelist_name exists. If not, it is initialized.
              2) if <data> and __codelist_name is unspecified, the macro
              return an error. Else, if <data> is specified __codelist_name
              is updated. Else , if <data> is unspecified, it is set to
              the value in __codelist_name.
              4) if the dataset specified in <data> does not exist, it
              is created.
              In practice this means that it is only necessary to specify
              the <data> parameter with the first call to the macro when
              the first definition is added. This will automatically
              initialize the codelist, and all subsequent definitions that
              are added to the same codelist.
var_name:     Definition element. Must be a quoted string.
              Variable name.
var_label:    Definition element. Must be a quoted string.
              Variable label.
var_type:     Definition element. Must be a quoted string.
              Variable type, eg bin/cont/cat.
t0_var:       Definition element. Must be a quoted string.
              Variable in data that hold the "time zero" / index date of
              a patient.
time_start:   Definition element. Must be a quoted string.
              Start of time-period in which data is used in defintion.
              Intended to be specified as a number of days in relation
              to t0_var, eg time_start = "-365" if the time-period starts
              1 years before time zero.
time_end:     Definition element. Must be a quoted string.
              End of time-period in which data is used in defintion.
              Intended to be specified as a number of days in relation
              to t0_var, eg time_end = "365" if the time-period ends
              1 years after time zero.
code_type:    Definition element. Must be a quoted string.
              Type of codes specified <code_include> and <code_exclude>,
              eg "icd10" or "npu".
code_include: Definition element. Must be a quoted string.
              Codes to include in definition.
code_exclude: Definition element. Must be a quoted string.
              Codes to exclude in definition.
notes:        Definition element. Must be a quoted string.
              Notes on definition.
reuse_vars:   Space-separated list of variable names to reuse from previous
              definition in <data>. Defaults to <reuse_vars> = _auto_,
              reusing all variables not specified (<var> = ""). Can also be
              set to <reuse_vars> = _null_ if reusing definition elements
              are not desired.
print_notes:  Print notes in log?
              - Yes: print_notes = y
              - No:  print_notes = n (default)
verbose:      Print info on what is happening during macro execution
              to the log?
              - Yes: verbose = y
              - No:  verbose = n (default)
******************************************************************************/
%macro codelist_add(
  data            = ,
  var_name        = "",
  var_label       = "",
  var_type        = "",
  var_level       = "",
  t0_var          = "",
  time_start      = "",
  time_end        = "",
  code_type       = "",
  code_include    = "",
  code_exclude    = "",
  notes           = "",
  reuse_vars      = _auto_,
  print_notes     = n,
  verbose         = n
) / minoperator mindelimiter = ' ';

/* Save value of notes option, then disable notes */
%local opt_notes;
%let opt_notes = %sysfunc(getoption(notes));
options nonotes;

/* Check if there is a global macro variable "__codelist_name". If not,
initialize it. */
%local tmp;
proc sql noprint;
  select count(*) into :tmp
    from sashelp.vmacro
    where scope = "GLOBAL" and name = "__CODELIST_NAME";
quit;

%if &tmp = 0 %then %do;
  %if &verbose = y %then %do;
    %put Global macro variable __codelist_name does not exist. Initialized it;
  %end;
  %global __codelist_name;
%end;


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
  %put ERROR: <verbose> does not have a valid value!;
  %put ERROR: Valid values are:;
  %put ERROR: verbose = y (Yes);
  %put ERROR: verbose = n (No);
  %goto end_of_macro;  
%end;
%else %if &verbose = y %then %do;
  %put codelist_add: *** Input checks ***;
%end;


/*** <print_notes> ***/

/* Check valid value */
%if &print_notes = %then %do;
  %put ERROR: Macro parameter <print_notes> is not specified!;
  %goto end_of_macro;
%end;
%else %if (&print_notes in y n) = 0 %then %do;
  %put ERROR: <print_notes> does not have a valid value!;
  %put ERROR: Valid values are:;
  %put ERROR: print_notes = y (Yes);
  %put ERROR: print_notes = n (No);
  %goto end_of_macro;  
%end;
%else %if &print_notes = y %then %do;
  options notes;
%end;


/*** <data> / __codelist_name ***/

/* Check that <data> or __codelist_name is specified */
%if &data = and &__codelist_name = %then %do;
  %put ERROR: <data> and global macro variable "__codelist_name" is unspecified!;
  %goto end_of_macro;
%end;

/* If <data> is specified, check that it is a valid (libname).member-name
SAS dataset name, and update __codelist_name */
%if &data ne %then %do;
  /* Regular expression: (lib-name.)member-name, where the libname is
  optional. The libname must start with a letter, followed by 0-7 letters, 
  numbers or underscores and must end with a ".". Member-name part must start
  with a letter or underscore, and is followed by 0-31 letters ,numbers or 
  underscores. The whole regular expression is case-insensitive. */
  %local tmp;
  data _null_;
    tmp = prxmatch('/^([a-z][\w]{0,7}\.)*[a-z_][\w]{0,31}$/i', "&data");
    call symput("tmp", put(tmp, 1.));
  run;

  %if &tmp = 0 %then %do;
    %put ERROR: <data> must be a valid (libname.)member-name SAS dataset name.;
    %goto end_of_macro; 
  %end;

  %let __codelist_name = &data;
%end;

/* If <data> is not specified, check that the dataset in __codelist_name exists,
then update <data> */
%if &data = %then %do;
  %if %sysfunc(exist(&__codelist_name)) = 0 %then %do;
    %put ERROR: <data> is unspeficied, and the codelist referenced in;
    %put ERROR: global macro variable __codelist_name = &__codelist_name;
    %put ERROR: does not exist!;
    %goto end_of_macro;
  %end;
 
  %let data = &__codelist_name;
%end;


/*** Definition elements ***/

%local parms i i_parm;
%let parms = var_name var_label var_type var_level t0_var time_start
             time_end code_type code_include code_exclude notes;

/* Check each parameter specified. */
%do i = 1 %to %sysfunc(countw(&parms, %str( )));
  %let i_parm = %scan(&parms, &i, %str( ));
  %if &i_parm = %then %do;
    %put ERROR: <&i_parm> is unspecified!;
    %goto end_of_macro;
  %end;
%end;


/*** <reuse_vars> ***/

/* Check specified */
%if &reuse_vars = %then %do;
  %put ERROR: <reuse_vars> is unspecified!;
  %goto end_of_macro;
%end;

/* Check that value is _null_ _auto_ or a space-separated list of valid
variable names */
%local all_vars i i_var;
%let all_vars = 
  var_name var_label var_type var_level t0_var time_start time_end
  code_type code_include code_exclude notes;

%if &reuse_vars = _null_ %then %do;
%end;
%else %if &reuse_vars = _auto_ %then %do;
%end;
%else %do;
  %do i = 1 %to %sysfunc(countw(&reuse_vars, %str( )));
    %let i_var = %scan(&reuse_vars, &i, %str( ));
    %if (&i_var in &all_vars) = 0 %then %do;
      %put ERROR: Variable "&i_var" in <reuse_vars> is not a;
      %put ERROR: variable name in the codelist;
      %goto end_of_macro;
    %end;
  %end;
%end;


/*******************************************************************************
INITIALIZE CODELIST
*******************************************************************************/

/* If the codelist does not exist, create it. */
%if %sysfunc(exist(&data)) = 0 %then %do;

  option notes;
  %put NOTE: Dataset "&data" specified in <data> does not exist.;
  %put NOTE: New codelist "&data" will be created.;
  option nonotes;

  proc sql;
    create table &data
      (
      var_name char length = 32,
      var_label char length = 100,
      var_type char length = 20,
      var_level char length = 100,
      t0_var char length = 32,
      time_start char length = 100,
      time_end char length = 100,
      code_type char length = 50,
      code_include char length = 2000,
      code_exclude char length = 2000,
      notes char length = 5000
    );
  quit;

%end;


/*******************************************************************************
DETERMINE VARIABLE VALUES TO REUSE
*******************************************************************************/

%if &reuse_vars = _auto_ %then %do;
  %if &verbose = y %then %do;
    %put <reuse_vars> = _auto_. Determine variables to reuse.;
  %end;

  %local all_vars i i_var;
  %let all_vars = 
    var_name var_label var_type var_level t0_var time_start time_end
    code_type code_include code_exclude notes;

  %let reuse_vars = ;
  %do i = 1 %to %sysfunc(countw(&all_vars, %str( )));
    %let i_var = %sysfunc(compress(%scan(&all_vars, &i, %str( ))));
    %if %bquote(&&&i_var) = "" %then %let reuse_vars = &reuse_vars &i_var;
  %end;
  
  %if &verbose = y %then %do;
    %put Variables to reuse:;
    %put <reuse_vars> = &reuse_vars;
  %end;
%end;


/*******************************************************************************
UPDATE REUSED VARIABLE VALUES 
*******************************************************************************/

%if &reuse_vars ne _null_ %then %do;

  %if &verbose = y %then %do;
    %put Variable values to be updated:;
    %do i = 1 %to %sysfunc(countw(&reuse_vars, %str( )));
      %let i_var = %scan(&reuse_vars, &i, %str( ));
      %put -&i_var = &&&i_var;
    %end;
  %end;

  %local ds_id rc n_rows;
  %let ds_id = %sysfunc(open(&data));
  %let n_rows = %sysfunc(attrn(&ds_id, nobs));
  %let rc = %sysfunc(close(&ds_id));

  /* Only reuse if there is something to reuse */
  %if &n_rows ne 0 %then %do;
    data _null_;
      set &data end = eof;
      if eof then do;
        %do i = 1 %to %sysfunc(countw(&reuse_vars, %str( )));
          %let i_var = %scan(&reuse_vars, &i, %str( ));
          call symput("&i_var", left(trim(&i_var)));
        %end;
      end;
    run;

    /* Quote values */
    %do i = 1 %to %sysfunc(countw(&reuse_vars, %str( )));
      %let i_var = %scan(&reuse_vars, &i, %str( ));
      %let &i_var = "&&&i_var";
      %if &&&i_var = " " %then %let &i_var = "";
    %end;
  %end;

  %if &verbose = y %then %do;
    %put Updated variable values:;
    %do i = 1 %to %sysfunc(countw(&reuse_vars, %str( )));
      %let i_var = %scan(&reuse_vars, &i, %str( ));
      %put -&i_var = &&&i_var;
    %end;
  %end;
%end;


/*******************************************************************************
ADD DEFINITION
*******************************************************************************/

/* Check that specified definition is not already included in the codelist. */
%local same_def;
data _null_;
  set &data;
  same_def = 1;
  %do i = 1 %to %sysfunc(countw(&all_vars, %str( )));
    %let i_var = %scan(&all_vars, &i, %str( ));
    if &i_var ne &&&i_var then do;
      same_def = 0;
    end;
  %end;
  if same_def = 1 then call symput("same_def", put(same_def, 1.));
run;

%if &same_def = 1 %then %do;
  %put WARNING: Specified definition is identical to a definition already in <data>;
  %put WARNING: A copy of the defintion was not added!;
%end;
%else %do;
  proc sql;
    insert into &data
    set var_name      = &var_name,
        var_label     = &var_label,
        var_type      = &var_type,
        var_level     = &var_level,
        t0_var        = &t0_var,
        time_start    = &time_start,
        time_end      = &time_end,
        code_type     = &code_type,
        code_include  = &code_include,
        code_exclude  = &code_exclude,
        notes = &notes;
  quit;

  %if &syserr ne 0 %then %do;
    %put ERROR: Something went wrong while adding the definition to the codelist!;
    %put ERROR: Are all definition element values specified as quoted strings?;
  %end;
%end;


%end_of_macro:


/* Restore value of notes option */
options &opt_notes;

%mend codelist_add;
