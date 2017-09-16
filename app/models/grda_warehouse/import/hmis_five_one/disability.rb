module GrdaWarehouse::Import::HMISFiveOne
  class Disability < GrdaWarehouse::Hud::Disability
    include ::Import::HMISFiveOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :DisabilitiesID,
        :ProjectEntryID,
        :PersonalID,
        :InformationDate,
        :DisabilityType,
        :DisabilityResponse,
        :IndefiniteAndImpairs,
        :DocumentationOnFile,
        :ReceivingServices,
        :PATHHowConfirmed,
        :PATHSMIInformation,
        :TCellCountAvailable,
        :TCellCount,
        :TCellSource,
        :ViralLoadAvailable,
        :ViralLoad,
        :ViralLoadSource,
        :DataCollectionStage,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :DisabilitiesID

    def self.file_name
      'Disabilities.csv'
    end
    
  end
end