# TL;DR;

run `make.inserts` with AWS credentials in your environment that allow access
to s3 bucket with saved assets referenced below

# Where the data came from

https://www.hudexchange.info/programs/coc/gis-tools/?&filter_tooltype=ShapeFile&filter_year=2019&filter_state=&current_page=2

* Visited this page
* filtered down to most recent yser
* Filtered down to shape files
* copied HTML on two pages of links and hacked it into wget lines.
* result is in get.zips
* make.inserts unzips and converts to postgres inserts

# Upgrading

If a new file is released with updated CoCs, you can:

1. Remove `shape_files/.did-shape-sync` (maybe only needed in development)
2. Add the new file to S3 (ensure roughly the same naming convention)
3. Remove the old file from S3 (and your local `shape_files/CoC` if you have any)
4. Delete the CoC shapes form the database `GrdaWarehouse::Shape::Coc.delete_all`
5. Re-run the installer (with AWS credentials) `GrdaWarehouse::Shape::Installer.new.run!`
