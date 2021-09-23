###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :importer_cleanup_move_ins_ds, class: 'GrdaWarehouse::DataSource' do
    name { 'Clean Up Move In Dates' }
    short_name { 'Move In' }
    source_type { :sftp }
    import_cleanups do
      {
        'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::MoveInOutsideEnrollment'],
      }
    end
  end

  factory :importer_prepend_project_ids, class: 'GrdaWarehouse::DataSource' do
    name { 'Prepend Project Ids' }
    short_name { 'ProjectID' }
    source_type { :sftp }
    import_cleanups do
      {
        'Project': ['HmisCsvImporter::HmisCsvCleanup::PrependProjectId'],
      }
    end
  end

  factory :importer_prepend_organization_ids, class: 'GrdaWarehouse::DataSource' do
    name { 'Prepend Organization Ids' }
    short_name { 'OrganizationID' }
    source_type { :sftp }
    import_cleanups do
      {
        'Organization': ['HmisCsvImporter::HmisCsvCleanup::PrependOrganizationId'],
      }
    end
  end

  factory :importer_force_valid_enrollment_cocs, class: 'GrdaWarehouse::DataSource' do
    name { 'Force Valid CoCs' }
    short_name { 'CoCCode' }
    source_type { :sftp }
    import_cleanups do
      {
        'EnrollmentCoc': ['HmisCsvImporter::HmisCsvCleanup::ForceValidEnrollmentCoc'],
      }
    end
  end

  factory :importer_delete_empty_enrollments_ds, class: 'GrdaWarehouse::DataSource' do
    name { 'Delete Empty Enrollments' }
    short_name { 'Empty Enrollments' }
    source_type { :sftp }
    import_cleanups do
      {
        'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::DeleteEmptyEnrollments'],
      }
    end
  end

  factory :importer_ensure_relationships_ds, class: 'GrdaWarehouse::DataSource' do
    name { 'Ensure Relationships' }
    short_name { 'Ensure Relationships' }
    source_type { :s3 }
    import_cleanups do
      {
        'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::EnforceRelationshipToHoh'],
      }
    end
  end

  factory :importer_dont_cleanup_ds, class: 'GrdaWarehouse::DataSource' do
    name { 'Dont Clean Up Move In Dates' }
    short_name { 'Move In' }
    source_type { :sftp }
  end
end
