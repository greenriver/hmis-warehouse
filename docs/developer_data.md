# Developer Data Loading
This document should give you some very basic developer data to work with.  If you haven't already, [follow the developer setup instructions here](developer_setup.md).  There is an assumption that you are running the warehouse in docker, and that it will be accessible via https://hmis-warehouse.dev.test.  You may need to adjust to your environment.

## Multiple databases
The project reads/writes from several different databases. We keep track of these different environments by setting up parallel db configs and structures for each database.  These follow the [standard pattern for multiple databases in rails](https://guides.rubyonrails.org/active_record_multiple_databases.html) and have the following database names:
* `primary` (application, user, and permission data)
* `warehouse` (HMIS and associated data)
* `reporting` (HMIS data reformatted for monthly reporting.  This database is deprecated and will be removed once OP Analytics fully replaces it)
* `health` (Healthcare data specifically used for care coordination or integration with external EHRs)

# HMIS CSV-Structured Tables

Several tables in the warehouse database are modeled after [HMIS CSV Format Specifications (2024 link)](https://files.hudexchange.info/resources/documents/HMIS-CSV-Format-Specifications-2024.pdf). These tables can be identified by their casing, which matches the CSV Spec. For example `Enrollment`, `Client`, `ProjectCoC`, etc.

The HMIS CSV-Structured tables share some common attributes:
* `data_source_id`: identifies which Data Source the HMIS data came from
* `EnrollmentID`: HUD Key referencing Enrollment table
* `PersonalID`: HUD Key referencing Client table
* `ProjectID`: HUD Key referencing Project table
* `UserID`: HUD Key referencing User table

These "HUD Keys" are used to link HMIS records together. We always use [composite keys](https://github.com/greenriver/hmis-warehouse/blob/ca8a5ac066f671acfec417a22102eadbbff4bd7b/drivers/hmis/app/models/hmis/hud/base.rb#L32-L69) for relationships between HMIS CSV tables. This is necessary because HUD Keys are **not unique across data sources.**

## Data Ingestion
1. Start a few delayed job workers.  Depending on your development machine capacity, you may want to start anywhere between one and five.  Having more than one will speed up the initial data load process.  In individual terminals run:
  ```
  docker-compose run --rm shell bin/rake jobs:work
  ```
2. Setup a new data source to hold the data. Visit https://hmis-warehouse.dev.test/data_sources, click **Add Data Source** and give it a Name and Short Name.
3. Manually load an initial test HMIS CSV data set.  You can find a reasonable set of HMIS test data as part of HUD's [LSA Sample Code](https://github.com/HMIS/LSASampleCode).  Visit your new data source and click **Upload HUD HMIS ZIP**. Upload the sample zip file and wait for the delayed job to finish processing.
4. Once the delayed job has finished, run the similarity metric initialization
  ```
  docker-compose run --rm shell bin/rake similarity:initialize
  ```
5. Run the script that is run nightly in production to fully process the uploaded data.  In general, after uploading future data sets, this is what will need to be run to fully process the data.
  ```
  docker-compose run --rm shell bin/rake grda_warehouse:daily
  ```
