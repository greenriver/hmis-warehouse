= Developer Setup
The warehouse application consists of three parts:
1. The Rails Application Code
2. The Rails Application Database
3. THe Warehouse Database

== Setup Your Development Environment
* Clone the git repository
* Run `bin/setup`
* Fill in any appropriate details for the various `.yml` files in `config`
* Run `bin/rake grda_warehouse:seed_data_sources`
* ...
== Anonimized Data
* In your production environment, export a batch of anonimized data
```
bin/rake grda_warehouse:dump_hud_csvs_for_dev[2500]
```
* In your development environment, place the exported files in folders in `var/hmis/<data_source_name>`
* Import the batch
```
bin/rake grda_warehouse:import_dev_hud_csvs
```
* Run through the daily imports, you may want to do this manuall, though it can be done in a single pass with
```
bin/rake grda_warehouse:daily
```