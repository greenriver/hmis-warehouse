###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :combined_enrollments_ds, class: 'GrdaWarehouse::DataSource' do
    name { 'Combined Enrollments' }
    short_name { 'CR' }
    source_type { :sftp }
    import_aggregators do
      {
        'Enrollment': ['HmisCsvTwentyTwenty::Aggregated::CombineEnrollments'],
      }
    end
  end

  factory :combined_enrollment_project, class: 'GrdaWarehouse::Hud::Project' do
    ProjectName { 'Combined Enrollment Project' }
    ProjectID { 'COMBINE' }
    OrganizationID { 'ORG-ID' }
    ProjectType { 1 }
    combine_enrollments { true }
  end
end
