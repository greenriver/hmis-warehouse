###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# The core app (or other drivers) can check the presence of the
# BostonProjectScorecard driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:boston_project_scorecard)
#
# use with caution!
RailsDrivers.loaded << :boston_project_scorecard

Rails.application.reloader.to_prepare do
  require_dependency 'boston_project_scorecard/document_exports/scorecard_export' if Rails.env.development?
end
