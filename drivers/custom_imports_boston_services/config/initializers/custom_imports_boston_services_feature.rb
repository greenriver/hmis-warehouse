###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# CustomImportsBostonServices driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:custom_imports_boston_services)
#
# use with caution!
RailsDrivers.loaded << :custom_imports_boston_services

Rails.application.config.custom_imports << 'CustomImportsBostonServices::ImportFile'
