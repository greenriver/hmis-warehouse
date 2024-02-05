###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# SupplementalEnrollmentData driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:supplemental_enrollment_data)
#
# use with caution!
RailsDrivers.loaded << :supplemental_enrollment_data

Rails.application.reloader.to_prepare do
  GrdaWarehouse::Config.add_supplemental_enrollment_importer(
    'TPC',
    'SupplementalEnrollmentData::Tpc',
  )
end
