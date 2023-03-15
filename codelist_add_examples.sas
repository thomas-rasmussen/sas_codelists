/* Build a codelist from scratch, inspired by a codelist used in a real study. */

/* Note that <data> is only specified in the first call to the macro. After that
it is not needed to specify this parameter, saving a lot of typing. Also note that
similar definitions are grouped to take advantage of <reuse_vars> = _auto, also
saving a lot of typing.

Finally, observe that definitions involving different kinds of codes are
included in steps one defintion component at a time. 

See the "extensive_example.sas" for how the codelist can be used to facilitate
the process of defining variables etc. */

%symdel __codelist_name;
proc datasets nolist nodetails;
  delete codelist;
run;
quit;

/*******************************************************************************
COMORBIDIES
*******************************************************************************/

/* diabetes diagnosis */
%codelist_add(
  data = codelist,
  var_name = "comor_1",
  var_label = "Diabetes diagnosis",
  var_type = "bin",
  var_level = "N/A",
  t0_var = "index_date",
  time_start = "-2*365",
  time_end = "-1",
  notes = "
    Defined using c_diag and d_inddto in DNPR.
    Any code in time window: 1 = yes / 0 = no
  ",
  code_type = "icd8",
  code_include = "250"
);
%codelist_add(code_type = "icd10", code_include = "E10 E11");

/* COPD */
%codelist_add(
  var_name = "comor_2",
  var_label = "COPD",
  code_type = "icd8",
  code_include = "490 491"
);
%codelist_add(code_type = "icd10", code_include = "J40 J41 J42 J43 J44");

/* Prostate biopsy */
%codelist_add(
  var_name = "comor_3",
  var_label = "Prostate biopsy",
  notes = "
    Defined using c_opr and d_odto in DNPR.
    Any code in time window: 1 = yes / 0 = no
  ",
  code_type = "surgery",
  code_include = "KTKE00 KKEB000"
);


/*******************************************************************************
MEDICATION USE
*******************************************************************************/

/* Diabetes medication */
%codelist_add(
  var_name = "med_1",
  var_label = "Diabetes medication",
  time_start = "-90",
  time_end = "-1",
  code_type = "atc",
  code_include = "A10",
  notes = "
    Defined using the atc and expdato variable in LMDB.
    Any code in time window: 1 = yes / 0 = no
  "
);

/* Hypertension medication */
%codelist_add(
  var_name = "med_2",
  var_label = "Hypertension medication",
  code_type = "atc",
  code_include = "C02 C03 C08 C09"
);


/*******************************************************************************
HEALTH CARE UTILIZATION
*******************************************************************************/

/* Number of hospitalizations prior to index date */
%codelist_add(
  reuse_vars = _null_,
  var_name = "hcu_1",
  var_type = "continuous",
  var_label = "Number of hospitalizations",
  var_level = "N/A",
  t0_var = "index_date",
  time_start = "-365",
  time_end = "-1",
  notes = "
    Number of inpatient hospitalizations in period.
    Defined using smoothed inpatient visits in DNPR.
  "
);


/*******************************************************************************
SOCIO-ECONOMIC STATUS (SES)
*******************************************************************************/

/* Living situation */
%codelist_add(
  reuse_vars = _null_,
  var_name = "ses_1",
  var_label = "Living situation",
  var_type = "categorical",
  t0_var = "index_date",
  time_start = "0",
  time_end = "0",
  notes = "
    Living situation on index date. 
    Defined using civst variable in BEF.
    Categorized as (civst values):
    - Living with spouse or registered partner: G/P
    - Living alone: E/F/L/O/U
    Assume persons with missing information are living alone
  ",
  var_level = "living_with_partner",
  code_include = "G P"
);
%codelist_add(var_level = "living_alone", code_include = "E F L O U");

/*******************************************************************************
MISCELLANEOUS
*******************************************************************************/

/* Studyperiod */
%codelist_add(
  reuse_vars = _null_,
  var_name = "studyperiod",
  var_label = "Studyperiod - start and end date",
  time_start = "2000-01-01",
  time_end = "2010-12-31",
  notes = "Start- and end date of studyperiod."
);

/* Index year */
%codelist_add(
  reuse_vars = _null_,
  var_name = "index_year",
  var_label = "Index year",
  notes = "Year of index date"
);

/* Index age */
%codelist_add(
  reuse_vars = _null_,
  var_name = "age",
  var_label = "Age at index date",
  t0_var = "index_date",
  notes = "Defined using birth_date from CRS. Given in years (not rounded)."
);

/* Index age - categorized */
%codelist_add(
  var_name = "age_g",
  var_label = "Age at index date - categorized",
  notes = "
    Defined using date of birth from CRS.
    Categorized as: <40/40-80/>80
  "
);

/*******************************************************************************
OUTCOMES
*******************************************************************************/

/* All-cause mortality */
%codelist_add(
  reuse_vars = _null_,
  var_name = "out_1",
  var_label = "All-cause mortality",
  var_type = "time_to_event",
  t0_var = "index_date",
  notes = "Defined using doddato from the DOD registry."
);




