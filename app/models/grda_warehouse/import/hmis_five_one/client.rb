module GrdaWarehouse::Import::HMISFiveOne
  class Client < GrdaWarehouse::Hud::Client
    include ::Import::HMISFiveOne::Shared
    
        setup_hud_column_access( 
          [
            :PersonalID,
            :FirstName,
            :MiddleName,
            :LastName,
            :NameSuffix,
            :NameDataQuality,
            :SSN,
            :SSNDataQuality,
            :DOB,
            :DOBDataQuality,
            :AmIndAKNative,
            :Asian,
            :BlackAfAmerican,
            :NativeHIOtherPacific,
            :White,
            :RaceNone,
            :Ethnicity,
            :Gender,
            :VeteranStatus,
            :YearEnteredService,
            :YearSeparated,
            :WorldWarII,
            :KoreanWar,
            :VietnamWar,
            :DesertStorm,
            :AfghanistanOEF,
            :IraqOIF,
            :IraqOND,
            :OtherTheater,
            :MilitaryBranch,
            :DischargeStatus,
            :DateCreated,
            :DateUpdated,
            :UserID,
            :DateDeleted,
            :ExportID
          ]
        )
  end
end