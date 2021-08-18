## HmisCsvTwentyTwenty README

### Exporter Module

Exporting logic for HMIS CSV files in the 2020 HUD format.

`HmisCsvTwentyTwenty::Exporter::Base.new(....).export!` will export a specified date range for specified projects

### Importer Modules

Importing and processing logic for HMIS CSV files in the 2020 HUD format.

This will:
1. import and normalize the CSVs into a data lake
2. run necessary ETL to bring them into a structured, validated set of tables
3. bring any changes into the warehouse proper

#### HmisCsvTwentyTwenty::Loader

The loader reads a source directory containing HMIS CSV files and inserts the data into a set of tables
with the HMIS columns as strings.

Class `Loader` is the entry point to this module.

#### HmisCsvTwentyTwenty::Importer

The importer processes the data from the loader to produce a structured, validated input, and incorporate
any new or changed data into the warehouse.

Class `Importer` is the entry point to this module.

##### Row Pre-Processing

Row pre-processing (`pre-process!`) consumes the records stored in the string tables and inserts the data via a
second set of tables with typed HMIS columns by applying model-specific transformations (e.g, converting strings
to dates, de-identifying clients), and applying row level validations to detect inconsistencies such as
missing required fields, or invalid values. If the records cannot be processed individually (e.g, to combine
 enrollments), the rows are inserted into a separate table for aggregated pre-processing.

##### Aggregated Pre-Processing

Aggregated pre-processing (`aggregate!`) consumes the pre-processed rows from the aggregation tables and
inserts the processed data into the the pre-processed tables.

##### Ingestion

Finally, the pre-processed records are merged into the warehouse tables ('ingest!').

#### HmisCsvValidation

CSV validators are configurable rules to check, and potentially enforce, well-formedness properties of imported
data.

Row validation classes:
* `HmisCsvValidation::Validation`: Failed checks are logged for later reference, but do not otherwise
affect row processing.
* `HmisCsvValidation::Error`: Failed checks are logged for later reference, and the row is excluded from the import.
