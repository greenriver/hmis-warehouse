module GrdaWarehouse::Export::HMISSixOneOne
  class Client < GrdaWarehouse::Hud::Client
    include ::Export::HMISSixOneOne::Shared
    include TsqlImport
    
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
        :OtherGender,
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

    self.hud_key = :PersonalID
        
    def self.file_name
      'Client.csv'
    end
  end
end