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
