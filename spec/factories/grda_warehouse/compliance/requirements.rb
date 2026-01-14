###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :compliance_requirement, class: 'GrdaWarehouse::Compliance::Requirement' do
    sequence(:name) { |n| "Requirement #{n}" }
    association :content_page, factory: :content_page
    revision { 1 }
    position { 0 }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_expiration do
      expires_after_days { 365 }
    end

    trait :terms_of_service do
      name { 'Terms of Service Agreement' }
      association :content_page, factory: [:content_page, :terms_of_service]
    end
  end
end
