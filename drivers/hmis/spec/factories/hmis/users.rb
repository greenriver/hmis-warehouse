###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_user, class: 'Hmis::User', parent: :user do
    first_name { 'Test' }
    last_name { 'User' }
    transient do
      data_source { nil }
    end
    after(:create) do |hmis_user, evaluator|
      hmis_user.hmis_data_source_id = evaluator.data_source.id if evaluator.data_source.present?
    end

    trait :randomly_named do
      first_name { Faker::Name.first_name }
      last_name { Faker::Name.last_name }
    end

    factory :hmis_user_with_random_name, traits: [:randomly_named]
  end
end
