/* Assumes codelist_add_examples has been run to create the codelist dataset */

/* Modify codelist before extracting a definition into macro variables.  */


/* Add quotes to codes */
%codelist_modify(
  data = codelist,
  out = codelist01,
  add_quotes = y
);
