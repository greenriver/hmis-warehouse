FactoryBot.define do
  factory :hmis_hud_client, class: 'Hmis::Hud::Client' do
    association :data_source, factory: :hmis_data_source
    skip_validations { [:all] }
    sequence(:PersonalID, 100)
    FirstName { 'Bob' }
    LastName { 'Ross' }
    DOB { '1999-12-01' }
  end

  factory :hmis_hud_client_complete, class: 'Hmis::Hud::Client' do
    association :data_source, factory: :hmis_data_source
    sequence(:PersonalID, 100)
    FirstName { 'Bob' }
    LastName { 'Ross' }
    NameDataQuality { 1 }
    SSN { '123456789' }
    SSNDataQuality { 1 }
    DOB { '1999-12-01' }
    DOBDataQuality { 1 }
    AmIndAKNative { 0 }
    Asian { 0 }
    BlackAfAmerican { 0 }
    NativeHIPacific { 0 }
    White { 0 }
    Ethnicity { 0 }
    Female { 0 }
    Male { 0 }
    NoSingleGender { 0 }
    Transgender { 0 }
    Questioning { 0 }
    Gender { 0 }
    VeteranStatus { 0 }
    DateCreated { DateTime.current }
    DateUpdated { DateTime.current }
    UserID { 1 }
  end
end
