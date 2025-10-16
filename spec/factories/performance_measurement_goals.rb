# frozen_string_literal: true

FactoryBot.define do
  factory :performance_measurement_goal, class: 'PerformanceMeasurement::Goal' do
    coc_code { :default }
    people { 1 }
    capacity { 1 }
    time_time { 1 }
    time_time_homeless_and_ph { 1 }
    time_stay { 1 }
    time_move_in { 1 }
    destination { 1 }
    destination_so { 1 }
    destination_homeless_plus { 1 }
    destination_permanent { 1 }
    recidivism_6_months { 1 }
    recidivism_12_months { 1 }
    recidivism_24_months { 1 }
    income { 1 }
    always_run_for_coc { false }
    label { 'Default Goal' }
    active { true }
    equity_analysis_visible { false }
    provider_comparisons_visible { false }
  end
end
