###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# HealthIpFollowupReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:health_ip_followup_report)
#
# use with caution!
RailsDrivers.loaded << :health_ip_followup_report
