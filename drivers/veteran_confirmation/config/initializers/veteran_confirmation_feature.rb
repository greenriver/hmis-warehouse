# The core app (or other drivers) can check the presence of the
# VeteranConfirmation driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:veteran_confirmation)
#
# use with caution!
RailsDrivers.loaded << :veteran_confirmation
