## DatalabTestkit README

The Datalab Test Kit is a collection of HUD CSVs that describe a standard set
of HMIS inputs and the outputs from running the HUD APR, CAPER, CE-APR, and SPMs.

As of version 2.0, there is not a standardized representation for the SPM results,
and the test kit contains a `.xlsx` containing the test results.
`DatalabTestkit::TestkitSpmXlsxToCsv` is a translator to generate CSVs in the
format used for Warehouse HUD report tests from the Excel file:

<pre>
DatalabTestkit::TestkitSpmXlsxToCsv.new(<i>directory</i>).convert(<i>excel_filename.xlsx</i>)
</pre>