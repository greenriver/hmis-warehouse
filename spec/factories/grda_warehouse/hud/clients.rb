FactoryBot.define do
  factory :grda_warehouse_hud_client, class: 'GrdaWarehouse::Hud::Client' do
    association :data_source, factory: :grda_warehouse_data_source
    sequence(:PersonalID, 100)
    FirstName { 'Bob' }
    # MiddleName
    LastName { 'Ross' }
    # NameSuffix
    # NameDataQuality
    # SSN
    # SSNDataQuality
    DOB { '1999-12-01' }
    # DOBDataQuality
    # AmIndAKNative
    # Asian
    # BlackAfAmerican
    # NativeHIPacific
    # White
    # RaceNone
    # Ethnicity
    # Gender
    # OtherGender
    # VeteranStatus
    # YearEnteredService
    # YearSeparated
    # WorldWarII
    # KoreanWar
    # VietnamWar
    # DesertStorm
    # AfghanistanOEF
    # IraqOIF
    # IraqOND
    # OtherTheater
    # MilitaryBranch
    # DischargeStatus
    # DateCreated
    # DateUpdated
    # UserID
    # DateDeleted
    # ExportID
  end

  factory :authoritative_hud_client, class: 'GrdaWarehouse::Hud::Client' do
    association :data_source, factory: :authoritative_data_source

    sequence(:PersonalID, 100)
    FirstName { 'Bob' }
    DOB { '1999-12-01' }
  end

  factory :window_hud_client, class: 'GrdaWarehouse::Hud::Client' do
    association :data_source, factory: :visible_data_source

    sequence(:PersonalID, 100)
    FirstName { 'Bob' }
    DOB { '1999-12-01' }
  end

  factory :fixed_source_client, class: 'GrdaWarehouse::Hud::Client' do
    association :data_source, factory: :source_data_source
    id { 100 }
    sequence(:PersonalID, 100)
    FirstName { 'Bob' }
    DOB { '1999-12-01' }
  end

  factory :fixed_destination_client, class: 'GrdaWarehouse::Hud::Client' do
    association :data_source, factory: :destination_data_source
    id { 101 }
    sequence(:PersonalID, 100)
    FirstName { 'Bob' }
    DOB { '1999-12-01' }
  end
end
