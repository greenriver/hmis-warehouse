# The core app (or other drivers) can check the presence of the
# IncomeBenefitsReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:income_benefits_report)
#
# use with caution!
RailsDrivers.loaded << :income_benefits_report
