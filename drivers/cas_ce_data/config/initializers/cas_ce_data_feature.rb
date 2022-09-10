###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# CasCeData driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:cas_ce_data)
#
# use with caution!
RailsDrivers.loaded << :cas_ce_data

Rails.application.config.synthetic_event_types << 'CasCeData::Synthetic::Event'
Rails.application.config.synthetic_assessment_types << 'CasCeData::Synthetic::Assessment'
