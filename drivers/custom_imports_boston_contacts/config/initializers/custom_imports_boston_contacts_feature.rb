###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# CustomImportsBostonContacts driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:custom_imports_boston_contacts)
#
# use with caution!
RailsDrivers.loaded << :custom_imports_boston_contacts

Rails.application.config.custom_imports << 'CustomImportsBostonContacts::ImportFile'
