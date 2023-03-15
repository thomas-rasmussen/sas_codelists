/* Assumes "codelist_add_examples.sas" has been run to create
codelist dataset */

/*******************************************************************************
BASIC TESTS
*******************************************************************************/

/*** <data> tests ***/

/* Check that if <data> is unspecified, the macro throws an error. */
%codelist_extract();
%codelist_extract(data = );

/* Check that if dataset provided in <data> does not exist, an
error is thrown. */
%codelist_extract(data = 1invalid);
%codelist_extract(data = does_not_exist);


/*** <where> tests ***/

%codelist_extract(data = codelist, where = invalid);


/*** <extract_vars> tests ***/

/* Check that if <extract_vars> is unspecified, the macro throws an error. */
%codelist_extract(data = codelist, extract_vars = );

/* Check that if a variable not in <data> is specified, the macro
throws an error. */
%codelist_extract(data = codelist, extract_vars = not_in_data);


/*** <print_mv> ***/

/* Check empty parameter value triggers error. */
%codelist_extract(data = codelist, print_mv = );

/* Check invalid value triggers an error. */
%codelist_extract(data = codelist, print_mv = 1);
%codelist_extract(data = codelist, print_mv = Y);


/* Check valid values does not trigger error. */
%codelist_extract(data = codelist, print_mv = n);
%codelist_extract(data = codelist, print_mv = y);

