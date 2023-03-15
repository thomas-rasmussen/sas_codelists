/* Assumes codelist_add_examples.sas has been run to create the
codelist dataset */

/* Extract definitons */
%codelist_extract(
  data = codelist,
  where = %str(var_name = "comor_1")
);
