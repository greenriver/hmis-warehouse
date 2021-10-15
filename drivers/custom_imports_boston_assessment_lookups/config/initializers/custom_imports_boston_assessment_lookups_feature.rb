# The core app (or other drivers) can check the presence of the
# CustomImportsBostonAssessmentLookups driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:custom_imports_boston_assessment_lookups)
#
# use with caution!
RailsDrivers.loaded << :custom_imports_boston_assessment_lookups

Rails.application.config.custom_imports << 'CustomImportsBostonAssessmentLookups::ImportFile'
