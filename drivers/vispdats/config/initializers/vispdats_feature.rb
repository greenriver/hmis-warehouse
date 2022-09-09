###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# Vispdats driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:vispdats)
#
# use with caution!
RailsDrivers.loaded << :vispdats

Rails.application.config.synthetic_assessment_types << 'Vispdats::Synthetic::Base'
