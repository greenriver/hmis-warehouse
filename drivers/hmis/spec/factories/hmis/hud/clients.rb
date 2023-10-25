###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

FactoryBot.define do
  # clients must share a base class to prevent PersonalID Sequence collision
  factory :hmis_hud_base_client, class: 'Hmis::Hud::Client' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    sequence(:PersonalID, 100)
  end

  factory :hmis_hud_client, parent: :hmis_hud_base_client do
    skip_validations { [:all] }
    FirstName { 'Bob' }
    LastName { 'Ross' }
    DOB { '1999-12-01' }
    transient do
      with_enrollment_at { nil }
    end
    after(:create) do |client, evaluator|
      create(:hmis_hud_enrollment, client: client, data_source: client.data_source, project: evaluator.with_enrollment_at) if evaluator.with_enrollment_at.present?
      client.reload
    end
  end

  factory :hmis_hud_client_complete, parent: :hmis_hud_base_client do
    FirstName { Faker::Name.first_name }
    MiddleName { Faker::Name.middle_name }
    LastName { Faker::Name.last_name }
    NameSuffix { Faker::Name.suffix }
    NameDataQuality { 1 }
    SSN { Faker::IDNumber.valid.gsub(/[^0-9]/, '') }
    SSNDataQuality { 1 }
    DOB { '1999-12-01' }
    DOBDataQuality { 1 }
    VeteranStatus { [0, 1, 8, 9, 99].sample }
    DateCreated { DateTime.current }
    DateUpdated { DateTime.current }
    after(:build) do |client|
      HudUtility2024.races.except('RaceNone').keys.each { |f| client.send("#{f}=", [0, 1].sample) }
      HudUtility2024.gender_fields.excluding(:GenderNone).each { |f| client.send("#{f}=", [0, 1].sample) }
    end
  end

  factory :hmis_warehouse_client, class: 'Hmis::WarehouseClient' do
    data_source { association :hmis_data_source }
    destination { association :hmis_hud_base_client, data_source: data_source }
    source { association :hmis_hud_base_client, data_source: data_source }
    sequence(:id_in_source, 100)
  end

  factory :hmis_hud_client_with_warehouse_client, parent: :hmis_hud_base_client do
    after(:create) do |client|
      create(:hmis_warehouse_client, data_source: client.data_source, source: client)
    end
  end
end
