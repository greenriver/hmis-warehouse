# The core app (or other drivers) can check the presence of the
# HmisCsvImporter driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_csv_importer)
#
# use with caution!
RailsDrivers.loaded << :hmis_csv_importer
