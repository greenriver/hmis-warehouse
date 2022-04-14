# The core app (or other drivers) can check the presence of the
# HealthIpFollowupReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:health_ip_followup_report)
#
# use with caution!
RailsDrivers.loaded << :health_ip_followup_report
