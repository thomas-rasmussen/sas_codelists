/*******************************************************************************
BASIC TESTS
*******************************************************************************/

/*** <data> tests ***/

%symdel __codelist_name;
proc datasets nodetails nolist;
  delete test;
run;
quit;

/* Check that call to macro with no <data> argument throws error if
__codelist_name does not exist */
%codelist_add();

/* Check that call to macro with no <data> argument throws error if dataset
name in __codelist_name does not exist. */
%let __codelist_name = abc;
%codelist_add();

/* Check that if the value of <data> is differnet than the value in
__codelist_name, then a new codelist is initalized and __codelist_name is
updated. */

%symdel __codelist_name;
%codelist_add(data = test1);
%codelist_add(data = test2);
%put &__codelist_name;

/* Check that an invalid SAS dataset name triggers an error */
%symdel __codelist_name;
proc datasets nodetails nolist;
  delete test1 test2;
run;
quit;

%codelist_add(data = 1invalid.valid);
%codelist_add(data = valid.1invalid);
%codelist_add(data = .1invalid);
%codelist_add(data = 1invalid.);


/*** Definition elements ***/

%symdel __codelist_name;
proc datasets nodetails nolist;
  delete test;
run;
quit;

/* Check that informative error message is printed in log if a definition element
is not specified as a quoted string. */

/* If new codelist initialized, an empty dataset should be made */
%codelist_add(data = test, 
var_name = some_name, print_notes = y, del = n, verbose = y);

%symdel __codelist_name;
proc datasets nodetails nolist;
  delete test;
run;
quit;

/* If existing codelist, then <data> should be unchanged. */
%codelist_add(data = test, var_name = "var_name");
%codelist_add(var_name = var_name1);


/*** <reuse_vars> tests ***/

/* Check throws error if invalid value / non-existing variables are specified. */
%symdel __codelist_name;
proc datasets nodetails nolist;
  delete test;
run;
quit;

%codelist_add(data = test, reuse_vars = null);


/*** <print_notes> tests ***/

/* Check empty parameter value triggers error. */
%codelist_add(data = test, print_notes = );

/* Check invalid values trigger an error. */
%codelist_add(data = test, print_notes = abc);
%codelist_add(data = test, print_notes = Y);

/* Check valid values does not trigger an error, and displays notes as
expected irregardless of the value of the notes option */
option nonotes;
%codelist_add(data = test, print_notes = y);
%codelist_add(data = test, print_notes = n);
option notes;
%codelist_add(data = test, print_notes = y);
%codelist_add(data = test, print_notes = n);


/*** <verbose> tests ***/

/* Check empty parameter value triggers error. */
%codelist_add(data = test, verbose = );

/* Check invalid value triggers an error. */
%codelist_add(data = test, verbose = 1);
%codelist_add(data = test, verbose = Y);


/* Check valid values does not trigger error. */
%codelist_add(data = test, verbose = n);
%codelist_add(data = test, verbose = y);
