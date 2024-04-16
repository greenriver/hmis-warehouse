#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#
require_relative '../hmis_data_cleanup/fix_enrollment_dates_20240416'

desc 'Fix entry and exit dates'
# rails driver:hmis:fix_enrollment_dates_20240416[222]
task :fix_enrollment_dates_20240416, [:special_treatment_project_id] => :environment do |_task, args|
  FixEnrollmentDates20240416.new(special_treatment_project_id: args.special_treatment_project_id).perform
end
