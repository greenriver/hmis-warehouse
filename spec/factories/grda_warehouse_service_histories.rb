FactoryBot.define do
  factory :grda_warehouse_service_history, class: 'GrdaWarehouse::ServiceHistoryEnrollment' do
    # client_id
    # data_source_id
    association :data_source, factory: :grda_warehouse_data_source
    # date
    # first_date_in_program
    # last_date_in_program
    # enrollment_group_id
    # age
    # destination
    # head_of_household_id
    # household_id
    # project_id
    # project_name
    # project_type
    # project_tracking_method
    # organization_id
    # record_type
    # housing_status_at_entry
    # housing_status_at_exit
    # service_type
    project_type { 1 }
    # presented_as_individual
  end

  trait :service_history_entry do
    client_id { 0 }
    record_type { 'entry' }
    date { Date.current }
  end

  trait :service_history_exit do
    client_id { 0 }
    record_type { 'exit' }
    date { Date.current }
  end

  trait :with_ph_enrollment do
    enrollment { create :hud_enrollment, data_source_id: 1, MoveInDate: move_in_date }

    project_type { 3 }
    enrollment_group_id { enrollment.EnrollmentID }
    project_id { enrollment.ProjectID }
  end

  trait :with_th_enrollment do
    enrollment { create :hud_enrollment, data_source_id: 1, MoveInDate: move_in_date }

    project_type { 2 }
    enrollment_group_id { enrollment.EnrollmentID }
    project_id { enrollment.ProjectID }
  end
end
