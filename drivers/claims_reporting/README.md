## ClaimsReporting README

This driver supports reporting on claims data received back from health insurance companies. It will eventually contain a number of classification, matching and aggregate reporting features.


### Data Setup

Claims data is provided in a Zip file containing CSVs for each table. The CSV format is defined by `def self.schema_def` for each model.

### ClaimsReporting::Importer

- `ClaimsReporting::Importer.clear!` will reset/truncate claims_reporting_* tables in dev/test environments
- `#import_from_zip(zip_file_path_or_io, replace_all: false)` will append/upsert the data into the files. Setting replace_all: true will truncate each table as it goes.
- `#import_from_health_sftp` can be used to download and import from a SFTP site (configured in Health:ImportConfig with kind: 'claims_reporting')
- `#check_sftp` finds potential files matching the expected naming convention on SFTP

- `#import_all_from_health_sftp(root_path: '/prod/Claims Data')` imports any previously un-imported files


`ClaimsReporting::Importer` creates `ClaimsReporting::Import` records in the database as it works

For example, in a development environment we could reset the tables
and then upsert many monthly exports like so:

```ruby
HealthBase.logger.level = Logger::INFO
ClaimsReporting::Importer.clear!
results = {}
['Jul','Aug','Sep','Oct','Nov','Dec'].each do |m|
  results[m] =  ClaimsReporting::Importer.new.import_from_zip("tmp/Claims Data/Export_#{m}_2020.zip", replace_all: false)
end
```
