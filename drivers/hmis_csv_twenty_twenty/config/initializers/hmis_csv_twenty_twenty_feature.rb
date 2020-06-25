# The core app (or other drivers) can check the presence of the
# HmisCsvTwentyTwenty driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_csv_importer)
#
# use with caution!
RailsDrivers.loaded << :hmis_csv_twenty_twenty
