###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# CustomImportsBostonService driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:custom_imports_boston_service)
#
# use with caution!
RailsDrivers.loaded << :custom_imports_boston_service

Rails.application.config.custom_imports << 'CustomImportsBostonService::ImportFile'
Rails.application.config.synthetic_event_types << 'CustomImportsBostonService::Synthetic::Event'
