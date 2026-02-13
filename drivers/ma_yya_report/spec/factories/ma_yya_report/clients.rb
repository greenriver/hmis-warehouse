###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :ma_yya_report_client, class: 'MaYyaReport::Client' do
    sequence(:client_id)
    sequence(:service_history_enrollment_id)
    entry_date { Date.new(2024, 6, 1) }
    age { 16 }
    gender { 0 }
    currently_homeless { false }
    at_risk_of_homelessness { false }
    enrolled_in_street_outreach { false }
    initial_contact { false }
    referral_source { nil }
    latest_non_homeless_cls_in_range { nil }

    # Trait for A1b: Outreach referral + at-risk
    trait :a1b do
      referral_source { 7 }
      at_risk_of_homelessness { true }
    end

    # Trait for A2b: Initial contact + at-risk
    trait :a2b do
      initial_contact { true }
      at_risk_of_homelessness { true }
      enrolled_in_street_outreach { false }
      referral_source { 1 } # Not outreach
    end

    # Trait for A3a: Entry during period + at-risk
    trait :a3a do
      entry_date { Date.new(2024, 6, 1) } # During reporting period
      at_risk_of_homelessness { true }
    end

    # Trait for A3b: Entry before period + CLS during period
    trait :a3b do
      entry_date { Date.new(2023, 6, 1) } # Before reporting period
      latest_non_homeless_cls_in_range { Date.new(2024, 3, 15) } # During reporting period
      at_risk_of_homelessness { false } # Not flagged as at_risk
    end

    # Trait for homeless clients (should not be in prevention)
    trait :homeless do
      currently_homeless { true }
      at_risk_of_homelessness { false }
    end
  end
end
