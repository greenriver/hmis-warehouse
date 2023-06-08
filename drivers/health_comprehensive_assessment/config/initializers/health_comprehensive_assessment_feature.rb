# The core app (or other drivers) can check the presence of the
# HealthComprehensiveAssessment driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:health_comprehensive_assessment)
#
# use with caution!
RailsDrivers.loaded << :health_comprehensive_assessment
