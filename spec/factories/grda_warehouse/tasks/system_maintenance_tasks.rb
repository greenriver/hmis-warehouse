# frozen_string_literal: true

FactoryBot.define do
  factory :system_maintenance_task, class: 'GrdaWarehouse::Tasks::SystemMaintenanceTask' do
    sequence(:name) { |n| "Test Maintenance Task #{n}" }
    completion_alert_minutes { 60 * 36 } # 36 hours default
  end

  factory :system_maintenance_task_run, class: 'GrdaWarehouse::Tasks::SystemMaintenanceTaskRun' do
    association :system_maintenance_task
    started_at { Time.current }
    completed_at { Time.current + 5.minutes }
  end
end
