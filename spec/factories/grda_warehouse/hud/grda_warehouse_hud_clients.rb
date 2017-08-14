FactoryGirl.define do
  factory :grda_warehouse_hud_client, class: 'GrdaWarehouse::Hud::Client' do
    association :data_source, factory: :grda_warehouse_data_source
    # PersonalID
    FirstName 'Bob'
    # MiddleName
    # LastName
    # NameSuffix
    # NameDataQuality
    # SSN
    # SSNDataQuality
    # DOB
    # DOBDataQuality
    # AmIndAKNative
    # Asian
    # BlackAfAmerican
    # NativeHIOtherPacific
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
end
