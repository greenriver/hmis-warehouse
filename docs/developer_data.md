# Developer Data Loading
This document should give you some very basic developer data to work with.  If you haven't already, [follow the developer setup instructions here](developer_setup.md).  There is an assumption that you are running the warehouse in docker, and that it will be accessible via https://hmis-warehouse.dev.test.  You may need to adjust to your environment.

1. Start a few delayed job workers.  Depending on your development machine capacity, you may want to start anywhere between one and five.  Having more than one will speed up the initial data load process.  In individual terminals run:
  ```
  docker-compose run --rm shell bin/rake jobs:work
  ```
2. Setup a new data source to hold the data. Visit https://hmis-warehouse.dev.test/data_sources, click **Add Data Source** and give it a Name and Short Name.
3. Manually load an initial test HMIS CSV data set.  You can find a reasonable zip file to load in `spec/fixtures/files/lsa/fy2019/sample_hmis_export.zip`.  Visit your new data source and click **Upload HUD HMIS ZIP**. Upload the sample zip file and wait for the delayed job to finish processing.
4. Once the delayed job has finished, run the similarity metric initialization
  ```
  docker-compose run --rm shell bin/rake similarity:initialize
  ```
5. Run the script that is run nightly in production to fully process the uploaded data.  In general, after uploading future data sets, this is what will need to be run to fully process the data.
  ```
  docker-compose run --rm shell bin/rake grda_warehouse:daily
  ```
