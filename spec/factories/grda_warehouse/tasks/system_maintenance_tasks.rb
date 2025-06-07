# frozen_string_literal: true

FactoryBot.define do
  factory :system_maintenance_task, class: 'GrdaWarehouse::Tasks::SystemMaintenanceTask' do
    registration { 'Importing::RunDailyImportsJob' }
    sequence(:name) { |n| "Test Maintenance Task #{n}" }
    alert_threshold_minutes { 60 * 36 } # 36 hours default
    active { true }
  end

  factory :system_maintenance_task_run, class: 'GrdaWarehouse::Tasks::SystemMaintenanceTaskRun' do
    association :system_maintenance_task
    started_at { Time.current }
    completed_at { Time.current + 5.minutes }
  end
end
