/* A more extensive example showing how the macros can be used to facilitate
a workflow where variables are defined using a codelist. 

Assumes codelist_add_examples has been run to create the codelist dataset */

/*******************************************************************************
SIMULATE DATA
*******************************************************************************/

/* Population */
data population;
  call streaminit(1);
  length id $3;
  format birth_date index_date death_date status_date yymmdd10.;
  do i = 1 to 100;
    id = put(i, z3.);
    birth_date = mdy(1, 1, 1960) + ceil(rand("uniform", -1, 1)*1e4);
    index_date = birth_date + ceil(rand("uniform")*1e4);
    death_date = index_date + ceil(rand("uniform")*1e3);
    if rand("uniform") < 0.8 then death_date = .;
    status_date = min(mdy(12, 31, 2020), death_date);
    output;
  end;
  drop i;
run;

/* MI data */
data diagnoses;
  call streaminit(1);
  length id $3;
  format code_date yymmdd10.;
  do i = 1 to 100;
    id = put(i, z3.);
    do j = 1 to 10;
      code_type = "icd10";
      code_value = "I21";
      code_date = mdy(1, 1, 1990) + ceil(rand("uniform")*1e4);
      output;
    end;
  end;
  drop i j;
run;

/*******************************************************************************
MODIFY CODELIST FOR OUTPUT TABLE
*******************************************************************************/

/* It is often desirable to make a nicer looking version of the codelist to
share with collaborators and/or include in research articles. The
%codelist_modify macro can help with some aspects of this task for example:
- Add periods in ICD-8/ICD-10 codes
- Change delimiter used between codes
*/
%codelist_modify(
  data = codelist,
  out = codelist_modified,
  set_code_delim = "comma",
  add_periods = icd10/3 icd8/3
);

/* It also often desirable to restructure and/or split up the table, but
this falls outside the scope of the macro. */


/*******************************************************************************
DEFINE COVARIATES
*******************************************************************************/

/* TODO: Implement example */
