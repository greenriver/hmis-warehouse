# The core app (or other drivers) can check the presence of the
# HmisSupplemental driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis_supplemental)
#
# use with caution!
RailsDrivers.loaded << :hmis_supplemental
