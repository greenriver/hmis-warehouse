###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :compliance_agreement, class: 'GrdaWarehouse::Compliance::Agreement' do
    association :user
    association :requirement, factory: :compliance_requirement
    revision { 1 }
    agreed_at { Time.current }
    expires_at { nil }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :expiring_soon do
      expires_at { 7.days.from_now }
    end
  end
end
