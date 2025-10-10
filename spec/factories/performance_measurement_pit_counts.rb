# frozen_string_literal: true

FactoryBot.define do
  factory :performance_measurement_pit_count, class: 'PerformanceMeasurement::PitCount' do
    association :goal, factory: :performance_measurement_goal
    pit_date { Time.zone.today }
    unsheltered { 1 }
    sheltered { 1 }
  end
end
