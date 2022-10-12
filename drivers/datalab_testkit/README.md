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

In addition, as of version 2.0, the test kit comes with two dozen HMIS zip files that need to be imported to run.  To speed up the test process, we merge them with the following command.  Note, you'll need to manually extract all of the zip files into folders in var/csvs/ first.

<pre>
source_dirs = Dir.glob('var/csvs/*')
destination_dir = 'drivers/datalab_testkit/spec/fixtures/inputs/merged/source'
DatalabTestkit::TestkitCsvMerge.new(source_dirs, destination_dir).merge_dirs
</pre>
