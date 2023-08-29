###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'

FactoryBot.define do
  factory :hmis_hud_client, class: 'Hmis::Hud::Client' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    skip_validations { [:all] }
    sequence(:PersonalID, 100)
    FirstName { 'Bob' }
    LastName { 'Ross' }
    DOB { '1999-12-01' }
  end

  factory :hmis_hud_client_complete, class: 'Hmis::Hud::Client' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    sequence(:PersonalID, 100)
    FirstName { Faker::Name.first_name }
    MiddleName { Faker::Name.middle_name }
    LastName { Faker::Name.last_name }
    NameDataQuality { 1 }
    SSN { Faker::IDNumber.valid.gsub(/[^0-9]/, '') }
    SSNDataQuality { 1 }
    DOB { '1999-12-01' }
    DOBDataQuality { 1 }
    VeteranStatus { 0 }
    DateCreated { DateTime.current }
    DateUpdated { DateTime.current }
    after(:build) do |client|
      HudUtility2024.races.except('RaceNone').keys.each { |f| client.send("#{f}=", 0) }
      HudUtility2024.gender_fields.excluding(:GenderNone).each { |f| client.send("#{f}=", 0) }
    end
  end
end
