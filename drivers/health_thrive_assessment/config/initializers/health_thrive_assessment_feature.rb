# The core app (or other drivers) can check the presence of the
# HealthThriveAssessment driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:health_thrive_assessment)
#
# use with caution!
RailsDrivers.loaded << :health_thrive_assessment
