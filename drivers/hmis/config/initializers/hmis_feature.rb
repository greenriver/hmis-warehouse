###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# Hmis driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hmis)
#
# use with caution!
RailsDrivers.loaded << :hmis

Rails.application.config.queued_tasks[:hmis_check_constraints] = -> do
  Hmis::Tasks::CheckConstraints.check_hud_constraints
end
