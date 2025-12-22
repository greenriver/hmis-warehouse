# frozen_string_literal: true

FactoryBot.define do
  factory :hud_reports_household_context, class: 'HudReports::HouseholdContext' do
    association :report_instance, factory: :hud_reports_report_instance
    association :service_history_enrollment, factory: :she_entry
    source_client_id { service_history_enrollment.client_id }
    sequence(:household_id) { |n| "HH#{n}" }
    household_type { 'adults_only' }
    is_hoh { true }
  end
end
