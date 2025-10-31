###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_monitoring_metric_definition, class: 'GrdaWarehouse::Monitoring::MetricDefinition' do
    sequence(:name) { |n| "test_metric_#{n}" }
    display_name { 'Test Metric' }
    description { 'A test metric for unit tests' }
    entity_type { 'GrdaWarehouse::Hud::Client' }
    calculator_class { 'GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator' }
    category { 'client_services' }
    count_change_threshold { 10 }
    percent_change_threshold { nil }
    active { true }
  end

  factory :grda_warehouse_monitoring_metric_snapshot, class: 'GrdaWarehouse::Monitoring::MetricSnapshot' do
    association :metric_definition, factory: :grda_warehouse_monitoring_metric_definition
    association :entity, factory: :grda_warehouse_hud_client
    entity_type { 'GrdaWarehouse::Hud::Client' }
    initial_observation_date { Date.current }
    current_observation_date { Date.current }
    initial_value { 100 }
    current_value { 100 }
    calculation_version { 1 }
  end

  factory :grda_warehouse_monitoring_metric_calculation_run, class: 'GrdaWarehouse::Monitoring::MetricCalculationRun' do
    entity_type { 'GrdaWarehouse::Hud::Client' }
    calculation_date { Date.current }
    started_at { Time.current }
    status { 'running' }
    entities_evaluated_count { 0 }
    metrics_calculated_count { 0 }
    snapshots_created_count { 0 }
    snapshots_updated_count { 0 }
    calculation_errors_count { 0 }
  end
end
