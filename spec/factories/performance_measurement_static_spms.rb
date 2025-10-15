###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :performance_measurement_static_spm, class: 'PerformanceMeasurement::StaticSpm' do
    association :goal, factory: :performance_measurement_goal
    report_start { 1.year.ago.to_date }
    report_end { Time.zone.today }

    trait :with_data do
      after(:build) do |spm|
        PerformanceMeasurement::StaticSpm::KNOWN_SPM_METHODS.each do |_, _, method|
          spm.public_send("#{method}=", rand(100))
        end
      end
    end
  end
end
