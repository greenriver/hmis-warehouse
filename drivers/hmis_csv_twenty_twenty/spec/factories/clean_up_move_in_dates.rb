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
end
