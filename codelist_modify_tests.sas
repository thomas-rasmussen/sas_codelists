/* Assumes "codelist_add_examples.sas" has been run to create
codelist dataset */

/*******************************************************************************
BASIC TESTS
*******************************************************************************/

/*** <data> tests ***/

/* Check that if <data> is unspecified, the macro throws an error. */
%codelist_modify();
%codelist_modify(data = );

/* Check that if dataset provided in <data> does not exist, an
error is thrown. */
%codelist_modify(data = 1invalid);
%codelist_modify(data = does_not_exist);


/*** <out> tests ***/

/* Check that if <out> is unspecified, the macro throws an error. */
%codelist_modify(data = codelist);

/* Check that if dataset specified in <out> is an invalid SAS
dataset name, an error is thrown. */
%codelist_modify(data = codelist, out = 1invalid);
%codelist_modify(data = codelist, out = 1invalid.valid);


/*** <code_var> tests ***/

/* Check that if <data> is unspecified, the macro throws an error. */
%codelist_modify(data = codelist, out = out, code_var = );

/* Check that if a variable is specified is not in <data>, the macro
throws an error. */
%codelist_modify(data = codelist, out = out, code_var = not_a_var);
%codelist_modify(data = codelist, out = out, code_var = code_include _null_);


/*** <code_type_var> tests ***/

/* Check that if <code_type_var> is unspecified, the macro throws an error. */
%codelist_modify(data = codelist, out = out, code_type_var = );

/* Check that if more than one variable is specified, the macro
throws an error*/
%codelist_modify(data = codelist, out = out, code_type_var = code_type code_type);

/* Check that if a variable is specified is not in <data>, the macro
throws an error. */
%codelist_modify(data = codelist, out = out, code_type_var = not_a_var);


/*** <set_code_delim> tests ***/

/* Check that if <set_code_delim> is unspecified, the macro throws an error */
%codelist_modify(data = codelist, out = out, set_code_delim = );

/* Check that if <set_code_delim> has an invalid value, the macro throws
an error. */
%codelist_modify(data = codelist, out = out, set_code_delim = comma);
%codelist_modify(data = codelist, out = out, set_code_delim = "hashtag");
%codelist_modify(data = codelist, out = out, set_code_delim = "#");


/* Check that valid values works as intended. */
%codelist_modify(data = codelist, out = out, set_code_delim = "space");
%codelist_modify(data = codelist, out = out, set_code_delim = "comma");


/*** <add_periods> tests ***/

/* Check that if <add_periods> is unspecified, the macro throws an error */
%codelist_modify(data = codelist, out = out, add_periods = );

/* Check invalid input triggers error */
%codelist_modify(data = codelist, out = out, add_periods = icd10/);
%codelist_modify(data = codelist, out = out, add_periods = /2);
%codelist_modify(data = codelist, out = out, add_periods = icd8/2 icd10/);

/* Check valid input works as intended */
%codelist_modify(data = codelist, out = out, add_periods = icd10/1);
%codelist_modify(data = codelist, out = out, add_periods = icd10/3 icd8/2);


/*** <add_prefix> tests ***/

/* Check that if <add_prefix> is unspecified, the macro throws an error */
%codelist_modify(data = codelist, out = out, add_prefix = );

/* Check invalid input triggers error */
%codelist_modify(data = codelist, out = out, add_prefix = icd10/);
%codelist_modify(data = codelist, out = out, add_prefix = /D);
%codelist_modify(data = codelist, out = out, add_prefix = icd8/0 icd10/);

/* Check valid input works as intended */
%codelist_modify(data = codelist, out = out, add_prefix = icd10/D);
%codelist_modify(data = codelist, out = out, add_prefix = icd8/0 icd10/D);


/*** <add_quotes> tests ***/

/* Check that if <add_quotes> is unspecified, the macro throws an error */
%codelist_modify(data = codelist, out = out, add_quotes = );

/* Check invalid value triggers error */
%codelist_modify(data = codelist, out = out, add_quotes = Y);
%codelist_modify(data = codelist, out = out, add_quotes = Yes);

/* Check valid values works as intended */
%codelist_modify(data = codelist, out = out, add_quotes = y);
%codelist_modify(data = codelist, out = out, add_quotes = n);


/*** <clean_whitespace> tests ***/

/* Check that if <clean_whitespace> is unspecified, the macro throws an error */
%codelist_modify(data = codelist, out = out, clean_whitespace = );

/* Check invalid value triggers error */
%codelist_modify(data = codelist, out = out, clean_whitespace = Y);
%codelist_modify(data = codelist, out = out, clean_whitespace = Yes);

/* Check valid values works as intended */
%codelist_modify(data = codelist, out = out, clean_whitespace = y);
%codelist_modify(data = codelist, out = out, clean_whitespace = n);


/*** <verbose> tests ***/

/* Check that if <verbose> is unspecified, the macro throws an error */
%codelist_modify(data = codelist, out = out, verbose = );

/* Check invalid value triggers error */
%codelist_modify(data = codelist, out = out, verbose = Y);
%codelist_modify(data = codelist, out = out, verbose = Yes);

/* Check valid values works as intended */
%codelist_modify(data = codelist, out = out, verbose = y);
%codelist_modify(data = codelist, out = out, verbose = n);


/*** <print_notes> tests ***/

/* Check that if <print_notes> is unspecified, the macro throws an error */
%codelist_modify(data = codelist, out = out, print_notes = );

/* Check invalid value triggers error */
%codelist_modify(data = codelist, out = out, print_notes = Y);
%codelist_modify(data = codelist, out = out, print_notes = Yes);

/* Check valid values works as intended */
%codelist_modify(data = codelist, out = out, print_notes = y);
%codelist_modify(data = codelist, out = out, print_notes = n);
