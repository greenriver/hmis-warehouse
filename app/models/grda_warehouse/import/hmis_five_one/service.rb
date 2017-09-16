module GrdaWarehouse::Import::HMISFiveOne
  class Service < GrdaWarehouse::Hud::Service
    include ::Import::HMISFiveOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :ServicesID,
        :ProjectEntryID,
        :PersonalID,
        :DateProvided,
        :RecordType,
        :TypeProvided,
        :OtherTypeProvided,
        :SubTypeProvided,
        :FAAmount,
        :ReferralOutcome,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :ServicesID

    def self.file_name
      'Services.csv'
    end
  end
end