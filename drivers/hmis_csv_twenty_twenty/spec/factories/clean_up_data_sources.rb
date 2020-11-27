FactoryBot.define do
  factory :cleanup_move_ins_ds, class: 'GrdaWarehouse::DataSource' do
    name { 'Clean Up Move In Dates' }
    short_name { 'Move In' }
    source_type { :sftp }
    import_cleanups do
      {
        'Enrollment': ['HmisCsvTwentyTwenty::HmisCsvCleanup::MoveInOutsideEnrollment'],
      }
    end
  end

  factory :prepend_project_ids, class: 'GrdaWarehouse::DataSource' do
    name { 'Prepend Project Ids' }
    short_name { 'ProjectID' }
    source_type { :sftp }
    import_cleanups do
      {
        'Project': ['HmisCsvTwentyTwenty::HmisCsvCleanup::PrependProjectId'],
      }
    end
  end

  factory :force_valid_enrollment_cocs, class: 'GrdaWarehouse::DataSource' do
    name { 'Force Valid CoCs' }
    short_name { 'CoCCode' }
    source_type { :sftp }
    import_cleanups do
      {
        'EnrollmentCoC': ['HmisCsvTwentyTwenty::HmisCsvCleanup::ForceValidEnrollmentCoc'],
      }
    end
  end

  factory :dont_cleanup_ds, class: 'GrdaWarehouse::DataSource' do
    name { 'Dont Clean Up Move In Dates' }
    short_name { 'Move In' }
    source_type { :sftp }
  end
end
